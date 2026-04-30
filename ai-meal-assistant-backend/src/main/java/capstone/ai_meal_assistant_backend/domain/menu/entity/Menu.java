package capstone.ai_meal_assistant_backend.domain.menu.entity;

import capstone.ai_meal_assistant_backend.global.entity.BaseEntity;
import jakarta.persistence.*;
import lombok.*;

import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "menus", indexes = {
        @Index(name = "idx_menu_category", columnList = "category")
})
@Getter
@Builder
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@AllArgsConstructor(access = AccessLevel.PRIVATE)
public class Menu extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String foodCode; // 매핑: RCP_SEQ (예: "28")

    @Column(nullable = false)
    private String name; // 매핑: RCP_NM (예: "새우 두부 계란찜")

    private String category;     // 매핑: RCP_PAT2 (예: "반찬")
    private String cookingMethod;// 매핑: RCP_WAY2 (예: "찌기")

    // 프론트엔드(Flutter) 화면 구성용 부가 정보
    @Column(length = 500)
    private String mainImageUrl; // 매핑: ATT_FILE_NO_MAIN (메인 음식 완성 사진 URL)

    @Column(length = 1000)
    private String healthTip;    // 매핑: RCP_NA_TIP (예: "나트륨 배출을 도와주는...")

    // --- 핵심 영양 성분 (1회 제공량 기준) ---
    private Double calories;     // 매핑: INFO_ENG (열량)
    private Double protein;      // 매핑: INFO_PRO (단백질)
    private Double fat;          // 매핑: INFO_FAT (지방)
    private Double carbs;        // 매핑: INFO_CAR (탄수화물)
    private Double sodium;       // 매핑: INFO_NA (나트륨)

    // 메뉴 삭제 시 레시피(MenuIngredient)도 한 번에 날아가도록 Cascade 걸기 (벌크성 작업 최적화)
    @Builder.Default // 해당 어노테이션이 없으면 빌더 패턴으로 객체를 생성할 때 해당 리스트가 빈 배열이 아니라 null로 덮어씌워짐 -> add 시 NullPointerEx
    @OneToMany(mappedBy = "menu", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<MenuIngredient> recipes = new ArrayList<>();
}
