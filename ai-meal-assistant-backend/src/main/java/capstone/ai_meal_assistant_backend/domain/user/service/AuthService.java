package capstone.ai_meal_assistant_backend.domain.user.service;

import capstone.ai_meal_assistant_backend.domain.user.dto.*;
import capstone.ai_meal_assistant_backend.domain.user.entity.Role;
import capstone.ai_meal_assistant_backend.domain.user.entity.User;
import capstone.ai_meal_assistant_backend.domain.user.exception.AccountLockedException;
import capstone.ai_meal_assistant_backend.domain.user.repository.UserRepository;
import capstone.ai_meal_assistant_backend.global.security.JwtUtil;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {
    
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;
    private final LoginAttemptService loginAttemptService;
    
    @Transactional
    public AuthResponse signup(SignupRequest request) {
        try {
            // 이메일은 대소문자 구분 없이 동일 계정으로 취급 (DB collation에 의존하지 않음)
            String email = request.getEmail().trim().toLowerCase();
            String nickname = request.getNickname().trim();

            // 이메일 중복 체크 (사전 중복확인과 별개로 가입 시점에 최종 확인)
            if (userRepository.existsByEmail(email)) {
                return AuthResponse.failure("이미 사용 중인 이메일입니다");
            }

            // 닉네임 중복 체크
            if (userRepository.existsByNickname(nickname)) {
                return AuthResponse.failure("이미 사용 중인 닉네임입니다");
            }

            // User 엔티티 생성
            User user = User.builder()
                    .email(email)
                    .password(passwordEncoder.encode(request.getPassword()))
                    .nickname(nickname)
                    .gender(request.getGender())
                    .role(Role.USER) // 기본값 USER
                    .provider("local") // 직접 회원가입
                    .build();
            
            // 저장 — unique 제약 위반을 이 메서드 안에서 잡을 수 있도록 즉시 flush
            userRepository.saveAndFlush(user);

            // JWT 토큰 생성
            String accessToken = jwtUtil.generateAccessToken(user.getEmail());
            String refreshToken = jwtUtil.generateRefreshToken(user.getEmail());

            // UserInfo 생성
            UserInfo userInfo = new UserInfo(user.getEmail(), user.getNickname(),
                    user.getGender() != null ? user.getGender().name() : null);

            // AuthData 생성
            AuthData authData = new AuthData(accessToken, refreshToken, userInfo);

            return AuthResponse.success(authData);

        } catch (DataIntegrityViolationException e) {
            // 사전 중복 체크 이후 ~ 저장 사이에 동시 가입이 끼어든 경우(TOCTOU) DB unique 제약이 잡아준다
            log.warn("회원가입 unique 제약 위반 (동시 가입 추정): {}", e.getMessage());
            return AuthResponse.failure("이미 사용 중인 이메일 또는 닉네임입니다");
        } catch (Exception e) {
            log.error("회원가입 중 오류 발생", e);
            return AuthResponse.failure("회원가입 중 알 수 없는 오류가 발생했습니다");
        }
    }
    
    @Transactional(readOnly = true)
    public boolean isEmailTaken(String email) {
        return userRepository.existsByEmail(email.trim().toLowerCase());
    }

    @Transactional(readOnly = true)
    public boolean isNicknameTaken(String nickname) {
        return userRepository.existsByNickname(nickname.trim());
    }

    // 실패 횟수/잠금 상태를 기록해야 하므로 쓰기 트랜잭션 사용.
    // AccountLockedException 발생 시에도 실패 누적은 저장되도록 noRollbackFor 지정.
    @Transactional(noRollbackFor = AccountLockedException.class)
    public AuthResponse login(LoginRequest request) {
        try {
            // 이메일로 사용자 조회 (가입 시와 동일하게 소문자 정규화)
            String email = request.getEmail().trim().toLowerCase();
            User user = userRepository.findByEmail(email)
                    .orElse(null);

            if (user == null) {
                return AuthResponse.failure("이메일 또는 비밀번호가 일치하지 않습니다");
            }

            // 계정 잠금 상태 확인 (잠겨 있으면 비밀번호 검증 없이 차단)
            long remainingLockSeconds = loginAttemptService.getRemainingLockSeconds(user);
            if (remainingLockSeconds > 0) {
                throw new AccountLockedException(remainingLockSeconds, false);
            }

            // 비밀번호 검증 (실패 시 횟수 누적, 최대치 도달 시 계정 잠금)
            if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
                boolean lockedNow = loginAttemptService.onLoginFailure(user);
                if (lockedNow) {
                    throw new AccountLockedException(LoginAttemptService.LOCK_DURATION.getSeconds(), true);
                }
                return AuthResponse.failure("이메일 또는 비밀번호가 일치하지 않습니다");
            }

            // 로그인 성공 — 실패 기록 초기화
            loginAttemptService.onLoginSuccess(user);

            // JWT 토큰 생성
            String accessToken = jwtUtil.generateAccessToken(user.getEmail());
            String refreshToken = jwtUtil.generateRefreshToken(user.getEmail());
            
            // UserInfo 생성
            UserInfo userInfo = new UserInfo(user.getEmail(), user.getNickname(),
                    user.getGender() != null ? user.getGender().name() : null);

            // AuthData 생성
            AuthData authData = new AuthData(accessToken, refreshToken, userInfo);

            return AuthResponse.success(authData);

        } catch (AccountLockedException e) {
            throw e; // 423 응답은 AuthExceptionHandler에서 처리
        } catch (Exception e) {
            log.error("로그인 중 오류 발생", e);
            return AuthResponse.failure("로그인 중 알 수 없는 오류가 발생했습니다");
        }
    }

    @Transactional(readOnly = true)
    public AuthResponse refresh(RefreshRequest request) {
        try {
            String refreshToken = request.getRefreshToken();

            // 리프레시 토큰 유효성 검증 (서명/만료)
            if (!jwtUtil.validateToken(refreshToken)) {
                return AuthResponse.failure("유효하지 않은 리프레시 토큰입니다");
            }

            // 토큰에서 이메일 추출 후 사용자 조회
            String email = jwtUtil.getEmailFromToken(refreshToken);
            User user = userRepository.findByEmail(email)
                    .orElse(null);

            if (user == null) {
                return AuthResponse.failure("존재하지 않는 사용자입니다");
            }

            // 새 토큰 발급
            // ⚠️ 한계: JWT는 stateless라 기존 refreshToken을 서버에서 무효화(revoke)할 수 없음.
            //    새 토큰을 발급해도 구 토큰은 만료(7일) 전까지 계속 유효하다.
            //    진짜 회전(rotation)은 서버 측 토큰 저장소 도입 시 가능 — Redis 도입(#176)에서 처리 예정.
            String accessToken = jwtUtil.generateAccessToken(user.getEmail());
            String newRefreshToken = jwtUtil.generateRefreshToken(user.getEmail());

            // UserInfo 생성
            UserInfo userInfo = new UserInfo(user.getEmail(), user.getNickname(),
                    user.getGender() != null ? user.getGender().name() : null);

            // AuthData 생성
            AuthData authData = new AuthData(accessToken, newRefreshToken, userInfo);

            return AuthResponse.success(authData);

        } catch (Exception e) {
            log.error("토큰 갱신 중 오류 발생", e);
            return AuthResponse.failure("토큰 갱신 중 알 수 없는 오류가 발생했습니다");
        }
    }
}
