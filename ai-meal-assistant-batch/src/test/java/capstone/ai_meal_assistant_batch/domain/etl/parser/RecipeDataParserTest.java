package capstone.ai_meal_assistant_batch.domain.etl.parser;

import static org.assertj.core.api.Assertions.assertThat;

import capstone.ai_meal_assistant_batch.domain.ingredient.dto.IngredientDto;
import java.util.List;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * 육류 부위명 보존 파싱 검증.
 * 기존엔 "소고기 치맛살" → 이름 "소고기" + amount "치맛살" 로 정규화되어
 * 가격이 일반 소고기로 계산되던 문제를 부위 보존으로 교정한다.
 */
class RecipeDataParserTest {

    private static IngredientDto first(String partsDtls) {
        List<IngredientDto> list = RecipeDataParser.parseIngredients(partsDtls, "테스트레시피");
        assertThat(list).isNotEmpty();
        return list.get(0);
    }

    @Test
    @DisplayName("소고기 치맛살 → 이름에 부위 보존")
    void beefChimatsal() {
        IngredientDto d = first("소고기 치맛살 (100g)");
        assertThat(d.getName()).isEqualTo("소고기 치맛살");
        assertThat(d.getParsedWeight()).isEqualTo(100.0);
    }

    @Test
    @DisplayName("쇠고기 등심 → 소고기로 베이스 통일 + 부위 보존")
    void beefSirloinUnify() {
        IngredientDto d = first("쇠고기 등심 240g");
        assertThat(d.getName()).isEqualTo("소고기 등심");
    }

    @Test
    @DisplayName("돼지고기(안심) → 돼지고기 안심")
    void porkTenderloinParen() {
        IngredientDto d = first("돼지고기(안심, 100g)");
        assertThat(d.getName()).isEqualTo("돼지고기 안심");
    }

    @Test
    @DisplayName("다진 돼지고기(등심) → 돼지고기 등심, '다진'은 amount로 분리")
    void mincedPorkSirloin() {
        IngredientDto d = first("다진 돼지고기(등심, 60g)");
        assertThat(d.getName()).isEqualTo("돼지고기 등심");
        assertThat(d.getOriginalAmount()).contains("다진");
    }

    @Test
    @DisplayName("불고기용 부채살 → 소고기 부채살, '불고기용'은 amount로 분리")
    void beefBudaesal() {
        IngredientDto d = first("소고기(불고기용 부채살, 200g)");
        assertThat(d.getName()).isEqualTo("소고기 부채살");
        assertThat(d.getOriginalAmount()).contains("불고기용");
    }

    @Test
    @DisplayName("다진 소고기 → 부위 없으면 베이스만, '다진'은 amount로 분리")
    void mincedBeefNoCut() {
        IngredientDto d = first("다진 소고기 100g");
        assertThat(d.getName()).isEqualTo("소고기");
        assertThat(d.getOriginalAmount()).contains("다진");
    }

    @Test
    @DisplayName("닭고기 가슴살 → 부위 보존")
    void chickenBreast() {
        IngredientDto d = first("닭고기 가슴살 150g");
        assertThat(d.getName()).isEqualTo("닭고기 가슴살");
    }

    @Test
    @DisplayName("돈등심(단독·약칭) → 돼지고기 등심")
    void bareDonDeungsim() {
        IngredientDto d = first("돈등심 80g");
        assertThat(d.getName()).isEqualTo("돼지고기 등심");
    }

    @Test
    @DisplayName("우목심(단독·약칭) → 소고기 목심")
    void bareUmoksim() {
        IngredientDto d = first("우목심(50g)");
        assertThat(d.getName()).isEqualTo("소고기 목심");
    }

    @Test
    @DisplayName("양지육(단독) → 소고기 양지")
    void bareYangjiyuk() {
        IngredientDto d = first("양지육(50g)");
        assertThat(d.getName()).isEqualTo("소고기 양지");
    }

    @Test
    @DisplayName("부챗살(단독) → 소고기 부챗살")
    void bareBudaesal() {
        IngredientDto d = first("부챗살(150g)");
        assertThat(d.getName()).isEqualTo("소고기 부챗살");
    }

    @Test
    @DisplayName("안심(단독·안심스테이크) → 소고기 안심")
    void bareAnsim() {
        IngredientDto d = first("안심 160g");
        assertThat(d.getName()).isEqualTo("소고기 안심");
    }

    @Test
    @DisplayName("돼기고기(오타) → 돼지고기")
    void typoPork() {
        IngredientDto d = first("다진 돼기고기 100g");
        assertThat(d.getName()).isEqualTo("돼지고기");
    }

    @Test
    @DisplayName("육류 외 재료는 영향 없음 (파프리카 색상은 그대로 amount)")
    void nonMeatUnaffected() {
        IngredientDto d = first("파프리카(노랑, 25g)");
        assertThat(d.getName()).isEqualTo("파프리카");
    }
}
