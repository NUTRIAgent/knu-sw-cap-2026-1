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

import java.util.Optional;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {
    
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;
    private final LoginAttemptService loginAttemptService;
    private final RefreshTokenService refreshTokenService;
    
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

            // 휴대폰 번호 중복 체크 (아이디 찾기 키로 사용되므로 계정당 하나)
            String phoneNumber = request.getPhoneNumber().trim();
            if (userRepository.existsByPhoneNumber(phoneNumber)) {
                return AuthResponse.failure("이미 등록된 휴대폰 번호입니다");
            }

            // User 엔티티 생성
            User user = User.builder()
                    .email(email)
                    .password(passwordEncoder.encode(request.getPassword()))
                    .nickname(nickname)
                    .phoneNumber(phoneNumber)
                    .gender(request.getGender())
                    .role(Role.USER) // 기본값 USER
                    .provider("local") // 직접 회원가입
                    .build();
            
            // 저장 — unique 제약 위반을 이 메서드 안에서 잡을 수 있도록 즉시 flush
            userRepository.saveAndFlush(user);

            // JWT 토큰 생성 — refresh token은 서버(Redis)에도 저장 (회전/로그아웃 무효화용)
            String accessToken = jwtUtil.generateAccessToken(user.getEmail());
            String refreshToken = jwtUtil.generateRefreshToken(user.getEmail());
            refreshTokenService.store(user.getEmail(), refreshToken);

            // UserInfo 생성
            UserInfo userInfo = new UserInfo(user.getEmail(), user.getNickname(),
                    user.getGender() != null ? user.getGender().name() : null);

            // AuthData 생성
            AuthData authData = new AuthData(accessToken, refreshToken, userInfo);

            return AuthResponse.success(authData);

        } catch (DataIntegrityViolationException e) {
            // 사전 중복 체크 이후 ~ 저장 사이에 동시 가입이 끼어든 경우(TOCTOU) DB unique 제약이 잡아준다
            log.warn("회원가입 unique 제약 위반 (동시 가입 추정): {}", e.getMessage());
            return AuthResponse.failure("이미 사용 중인 이메일/닉네임/휴대폰 번호입니다");
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

    @Transactional(readOnly = true)
    public boolean isPhoneNumberTaken(String phoneNumber) {
        return userRepository.existsByPhoneNumber(phoneNumber.trim());
    }

    // 아이디(이메일) 찾기 — 휴대폰 번호로 조회 후 마스킹된 이메일 반환
    @Transactional(readOnly = true)
    public Optional<String> findMaskedEmailByPhoneNumber(String phoneNumber) {
        return userRepository.findByPhoneNumber(phoneNumber.trim())
                .map(user -> maskEmail(user.getEmail()));
    }

    // 이메일 로컬 파트 마스킹 (예: mhy@smail.kongju.ac.kr → mh***@smail.kongju.ac.kr)
    // 로컬 파트가 2글자 이상이면 앞 2글자, 1글자면 1글자만 노출 ("***"가 실제 길이를 가리므로 전체 노출은 아님)
    static String maskEmail(String email) {
        int atIndex = email.indexOf('@');
        String local = email.substring(0, atIndex);
        String domain = email.substring(atIndex);
        String visible = local.length() < 2 ? local.substring(0, 1) : local.substring(0, 2);
        return visible + "***" + domain;
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

            // JWT 토큰 생성 — refresh token은 서버(Redis)에도 저장 (회전/로그아웃 무효화용)
            String accessToken = jwtUtil.generateAccessToken(user.getEmail());
            String refreshToken = jwtUtil.generateRefreshToken(user.getEmail());
            refreshTokenService.store(user.getEmail(), refreshToken);

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

            // 서버(Redis)에 저장된 최신 토큰과 일치해야 함 — 회전된 구 토큰/로그아웃된 토큰 차단
            if (!refreshTokenService.matches(email, refreshToken)) {
                return AuthResponse.failure("유효하지 않은 리프레시 토큰입니다");
            }

            // 새 토큰 발급 후 저장소 갱신 — 구 refresh token은 이 시점부터 즉시 무효 (진짜 회전)
            String accessToken = jwtUtil.generateAccessToken(user.getEmail());
            String newRefreshToken = jwtUtil.generateRefreshToken(user.getEmail());
            refreshTokenService.store(user.getEmail(), newRefreshToken);

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

    // 로그아웃 — 서버에 저장된 refresh token 무효화.
    // 토큰이 이미 만료/무효여도 성공으로 처리(멱등) — 클라이언트는 항상 로컬 토큰을 비우면 된다.
    public AuthResponse logout(RefreshRequest request) {
        try {
            String refreshToken = request.getRefreshToken();
            if (jwtUtil.validateToken(refreshToken)) {
                String email = jwtUtil.getEmailFromToken(refreshToken);
                refreshTokenService.invalidate(email);
            }
            return AuthResponse.success(null);
        } catch (Exception e) {
            log.error("로그아웃 처리 중 오류 발생", e);
            return AuthResponse.success(null); // 멱등 — 서버 오류여도 클라이언트 로그아웃은 진행
        }
    }
}
