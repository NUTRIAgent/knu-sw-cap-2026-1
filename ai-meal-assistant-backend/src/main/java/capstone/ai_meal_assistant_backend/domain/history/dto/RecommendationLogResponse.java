package capstone.ai_meal_assistant_backend.domain.history.dto;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.Builder;
import lombok.Getter;

import java.time.LocalDateTime;

@Getter
@Builder
public class RecommendationLogResponse {
    private Long id;
    private Long menuId;
    private String menuName;
    private String menuImageUrl;
    private Integer feedbackScore;
    private Integer starRating;
    private String feedbackReason;
    private String aiResultJson;

    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime createdAt;
}
