package capstone.ai_meal_assistant_backend.domain.user.service;

import capstone.ai_meal_assistant_backend.domain.user.dto.*;
import capstone.ai_meal_assistant_backend.domain.user.entity.Role;
import capstone.ai_meal_assistant_backend.domain.user.entity.User;
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

    @Transactional(readOnly = true)
    public AuthResponse login(LoginRequest request) {
        try {
            // 이메일로 사용자 조회
            User user = userRepository.findByEmail(request.getEmail())
                    .orElse(null);
            
            if (user == null) {
                return AuthResponse.failure("이메일 또는 비밀번호가 일치하지 않습니다");
            }
            
            // 비밀번호 검증
            if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
                return AuthResponse.failure("이메일 또는 비밀번호가 일치하지 않습니다");
            }
            
            // JWT 토큰 생성
            String accessToken = jwtUtil.generateAccessToken(user.getEmail());
            String refreshToken = jwtUtil.generateRefreshToken(user.getEmail());
            
            // UserInfo 생성
            UserInfo userInfo = new UserInfo(user.getEmail(), user.getNickname());
            
            // AuthData 생성
            AuthData authData = new AuthData(accessToken, refreshToken, userInfo);
            
            return AuthResponse.success(authData);
            
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

            // 새 토큰 발급 (리프레시 토큰도 함께 갱신하여 만료 시점 연장)
            String accessToken = jwtUtil.generateAccessToken(user.getEmail());
            String newRefreshToken = jwtUtil.generateRefreshToken(user.getEmail());

            // UserInfo 생성
            UserInfo userInfo = new UserInfo(user.getEmail(), user.getNickname());

            // AuthData 생성
            AuthData authData = new AuthData(accessToken, newRefreshToken, userInfo);

            return AuthResponse.success(authData);

        } catch (Exception e) {
            log.error("토큰 갱신 중 오류 발생", e);
            return AuthResponse.failure("토큰 갱신 중 알 수 없는 오류가 발생했습니다");
        }
    }
}
