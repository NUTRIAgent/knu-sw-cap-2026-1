package capstone.ai_meal_assistant_batch.domain.etl;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;

import java.io.File;

public class JsonDataCleaner {

    public static void main(String[] args) {
        try {
            ObjectMapper mapper = new ObjectMapper();

            // 1. 원본 파일 위치 (resources 폴더에 있다고 가정)
            File inputFile = new File("src/main/resources/cleaned_recipe_data.json");

            // 2. 새롭게 저장될 깨끗한 파일 이름
            File outputFile = new File("src/main/resources/cleaned_recipe_data.json");

            // JSON 읽기
            JsonNode rootNode = mapper.readTree(inputFile);

            // 배열 형태인 경우 순회하면서 수정
            if (rootNode.isArray()) {
                for (JsonNode node : rootNode) {
                    ObjectNode objNode = (ObjectNode) node;
                    String originalText = objNode.path("RCP_PARTS_DTLS").asText();

                    if (!originalText.isEmpty()) {
                        // 🧹 여기서 악질적인 오타들을 일괄 치환합니다!
                        String cleanedText = originalText
                                .replaceAll("(?i)<br\\s*/?>", "\n") // br 태그 줄바꿈으로
                                .replaceAll("\\[.*?\\]", "")        // [소스소개], [1인분] 등 제거
                                .replaceAll("1인분 기준", "")
                                .replaceAll("[①-⑳]", "")
                                .replaceAll("•", "")
                                .replaceAll("●", "")
                                .replace("방아잎 ⅓줌=", "방아잎(10g)")
                                .replace("미나리(⅓줌=50g)", "미나리(50g)")
                                .replaceAll("→", "")
                                .replaceAll("\"", "")
                                .replaceAll("=", "")
                                .replaceAll(" > ", ":")
                                .replace("5×5cm, ", "")
                                .replace("1팩=100g", "100g")
                                .replace("가지(½개+20g)+", "가지(20g)")
                                .replace("바지락(모시조개( 200g(30개)", "바지락(200g)")
                                .replace("(2*4cm)", "")
                                .replace("물녹말(녹말가루", "물녹말 적당량(녹말가루")
                                .replace("녹말물(녹말가루", "녹말물 적당량(녹말가루")
                                .replace("8컵(표고버섯", "8컵[표고버섯")
                                .replace("대파뿌리, 양파)", "대파뿌리, 양파]")
                                .replace("물녹말(녹말가루", "물녹말 0적당량(녹말가루")
                                .replace("녹말물(녹말가루", "녹말물 0적당량(녹말가루")
                                .replace("삼색분말(각 10g)", "삼색분말 각 10g")
                                .replace("두 가지 색 파프리카(각 15g씩)", "파프리카 두 가지 색 각 15g")
                                .replace("달걀지단(흰자", "달걀지단 흰자");

                        // 깨끗해진 텍스트로 덮어쓰기
                        objNode.put("RCP_PARTS_DTLS", cleanedText);
                    }
                }
            }

            // 3. 예쁜 형태(Pretty Printer)로 새 파일 저장
            mapper.writerWithDefaultPrettyPrinter().writeValue(outputFile, rootNode);

            System.out.println("JSON 데이터 정제가 완벽하게 끝났습니다! cleaned_recipe_data.json을 확인하세요.");

        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
