package capstone.ai_meal_assistant_backend.global.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

/**
 * 공통 응답 래퍼.
 * 컨트롤러마다 인너 클래스로 중복 정의하지 않도록 공용 DTO로 제공한다.
 * (기존 컨트롤러들의 자체 ApiResponse는 점진적으로 이 클래스로 교체)
 */
@Getter
@AllArgsConstructor
public class ApiResponse<T> {
    private boolean success;
    private T data;
    private String error;

    public static <T> ApiResponse<T> ok(T data) {
        return new ApiResponse<>(true, data, null);
    }

    public static <T> ApiResponse<T> fail(String error) {
        return new ApiResponse<>(false, null, error);
    }
}
