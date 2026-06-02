package capstone.ai_meal_assistant_backend.domain.user.service;

import capstone.ai_meal_assistant_backend.domain.user.dto.*;
import capstone.ai_meal_assistant_backend.domain.user.entity.Role;
import capstone.ai_meal_assistant_backend.domain.user.entity.User;
import capstone.ai_meal_assistant_backend.domain.user.exception.AccountLockedException;
import capstone.ai_meal_assistant_backend.domain.user.repository.UserRepository;
import capstone.ai_meal_assistant_backend.global.security.JwtUtil;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
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
            String email = request.getEmail().trim();
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
            
            // 저장
            userRepository.save(user);
            
            // JWT 토큰 생성
            String accessToken = jwtUtil.generateAccessToken(user.getEmail());
            String refreshToken = jwtUtil.generateRefreshToken(user.getEmail());
            
            // UserInfo 생성
            UserInfo userInfo = new UserInfo(user.getEmail(), user.getNickname());
            
            // AuthData 생성
            AuthData authData = new AuthData(accessToken, refreshToken, userInfo);
            
            return AuthResponse.success(authData);
            
        } catch (Exception e) {
            log.error("회원가입 중 오류 발생", e);
            return AuthResponse.failure("회원가입 중 알 수 없는 오류가 발생했습니다");
        }
    }
    
    @Transactional(readOnly = true)
    public boolean isEmailTaken(String email) {
        return userRepository.existsByEmail(email.trim());
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
            // 이메일로 사용자 조회
            User user = userRepository.findByEmail(request.getEmail())
                    .orElse(null);

            if (user == null) {
                return AuthResponse.failure("이메일 또는 비밀번호가 일치하지 않습니다");
            }

            // 계정 잠금 상태 확인 (잠겨 있으면 비밀번호 검증 없이 차단)
            long remainingLockSeconds = loginAttemptService.getRemainingLockSeconds(user);
            if (remainingLockSeconds > 0) {
                throw new AccountLockedException(remainingLockSeconds);
            }

            // 비밀번호 검증 (실패 시 횟수 누적, 최대치 도달 시 계정 잠금)
            if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
                boolean lockedNow = loginAttemptService.onLoginFailure(user);
                if (lockedNow) {
                    throw new AccountLockedException(LoginAttemptService.LOCK_DURATION.getSeconds());
                }
                return AuthResponse.failure("이메일 또는 비밀번호가 일치하지 않습니다");
            }

            // 로그인 성공 — 실패 기록 초기화
            loginAttemptService.onLoginSuccess(user);

            // JWT 토큰 생성
            String accessToken = jwtUtil.generateAccessToken(user.getEmail());
            String refreshToken = jwtUtil.generateRefreshToken(user.getEmail());
            
            // UserInfo 생성
            UserInfo userInfo = new UserInfo(user.getEmail(), user.getNickname());
            
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
}
