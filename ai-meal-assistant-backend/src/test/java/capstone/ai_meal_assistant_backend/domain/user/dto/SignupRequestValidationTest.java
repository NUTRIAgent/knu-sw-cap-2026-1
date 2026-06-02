package capstone.ai_meal_assistant_backend.domain.user.dto;

import capstone.ai_meal_assistant_backend.domain.user.entity.Gender;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.Validation;
import jakarta.validation.Validator;
import jakarta.validation.ValidatorFactory;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;

class SignupRequestValidationTest {

    private static ValidatorFactory validatorFactory;
    private static Validator validator;

    @BeforeAll
    static void setUp() {
        validatorFactory = Validation.buildDefaultValidatorFactory();
        validator = validatorFactory.getValidator();
    }

    @AfterAll
    static void tearDown() {
        validatorFactory.close();
    }

    private SignupRequest createRequest(String email, String password, String nickname, Gender gender) {
        SignupRequest request = new SignupRequest();
        ReflectionTestUtils.setField(request, "email", email);
        ReflectionTestUtils.setField(request, "password", password);
        ReflectionTestUtils.setField(request, "nickname", nickname);
        ReflectionTestUtils.setField(request, "gender", gender);
        return request;
    }

    @Test
    @DisplayName("영문+숫자+특수문자 포함 8자 이상 비밀번호는 통과한다")
    void validPassword() {
        SignupRequest request = createRequest("test@example.com", "abcd1234!", "닉네임", Gender.MALE);

        Set<ConstraintViolation<SignupRequest>> violations = validator.validate(request);

        assertThat(violations).isEmpty();
    }

    @Test
    @DisplayName("특수문자가 없는 비밀번호는 거부된다")
    void passwordWithoutSpecialCharacter() {
        SignupRequest request = createRequest("test@example.com", "abcd1234", "닉네임", Gender.MALE);

        Set<ConstraintViolation<SignupRequest>> violations = validator.validate(request);

        assertThat(violations)
                .extracting(ConstraintViolation::getMessage)
                .contains("비밀번호는 영문, 숫자, 특수문자를 각각 1자 이상 포함해야 합니다");
    }

    @Test
    @DisplayName("숫자가 없는 비밀번호는 거부된다")
    void passwordWithoutDigit() {
        SignupRequest request = createRequest("test@example.com", "abcdefgh!", "닉네임", Gender.MALE);

        Set<ConstraintViolation<SignupRequest>> violations = validator.validate(request);

        assertThat(violations).isNotEmpty();
    }

    @Test
    @DisplayName("영문이 없는 비밀번호는 거부된다")
    void passwordWithoutLetter() {
        SignupRequest request = createRequest("test@example.com", "12345678!", "닉네임", Gender.MALE);

        Set<ConstraintViolation<SignupRequest>> violations = validator.validate(request);

        assertThat(violations).isNotEmpty();
    }

    @Test
    @DisplayName("8자 미만 비밀번호는 거부된다")
    void passwordTooShort() {
        SignupRequest request = createRequest("test@example.com", "ab12!", "닉네임", Gender.MALE);

        Set<ConstraintViolation<SignupRequest>> violations = validator.validate(request);

        assertThat(violations)
                .extracting(ConstraintViolation::getMessage)
                .contains("비밀번호는 8자 이상 64자 이하여야 합니다");
    }

    @Test
    @DisplayName("공백이 포함된 비밀번호는 거부된다")
    void passwordWithWhitespace() {
        SignupRequest request = createRequest("test@example.com", "abcd 1234!", "닉네임", Gender.MALE);

        Set<ConstraintViolation<SignupRequest>> violations = validator.validate(request);

        assertThat(violations).isNotEmpty();
    }

    @Test
    @DisplayName("닉네임이 1자면 거부된다")
    void nicknameTooShort() {
        SignupRequest request = createRequest("test@example.com", "abcd1234!", "a", Gender.MALE);

        Set<ConstraintViolation<SignupRequest>> violations = validator.validate(request);

        assertThat(violations)
                .extracting(ConstraintViolation::getMessage)
                .contains("닉네임은 2자 이상 20자 이하여야 합니다");
    }

    @Test
    @DisplayName("닉네임이 20자를 초과하면 거부된다")
    void nicknameTooLong() {
        SignupRequest request = createRequest("test@example.com", "abcd1234!", "가".repeat(21), Gender.MALE);

        Set<ConstraintViolation<SignupRequest>> violations = validator.validate(request);

        assertThat(violations).isNotEmpty();
    }

    @Test
    @DisplayName("잘못된 이메일 형식은 거부된다")
    void invalidEmailFormat() {
        SignupRequest request = createRequest("not-an-email", "abcd1234!", "닉네임", Gender.MALE);

        Set<ConstraintViolation<SignupRequest>> violations = validator.validate(request);

        assertThat(violations)
                .extracting(ConstraintViolation::getMessage)
                .contains("올바른 이메일 형식이 아닙니다");
    }
}
