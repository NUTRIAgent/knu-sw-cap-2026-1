package capstone.ai_meal_assistant_batch.domain.etl.parser;

import capstone.ai_meal_assistant_batch.domain.ingredient.dto.IngredientDto;
import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class RecipeDataParser {

    private static final Pattern NUMBER_PATTERN = Pattern.compile("^(.*?)\\s*([0-9½⅓⅔¼¾⅕⅖⅙⅛]+.*)$");
    private static final Pattern FALLBACK_PATTERN = Pattern.compile("^(.*?)\\s*(약간|조금|적당량|약간량|소량|한꼬집|취향껏|필요량|기호에따라|.*?용|각각|각)$");

    public static List<IngredientDto> parseIngredients(String rcpPartsDtls, String recipeName) {
        List<IngredientDto> ingredientList = new ArrayList<>();
        if(rcpPartsDtls == null || rcpPartsDtls.isEmpty()) return ingredientList;

        String cleanRecipeName = recipeName != null ? recipeName.replaceAll("\\s+", "") : "";
        String cleaned = rcpPartsDtls
                .replaceAll("(?i)<br\\s*/?>", "\n")
                .replaceAll("\\[.*?\\]", "")
                .replaceAll("1인분 기준", "")
                .replaceAll("[①-⑳]", "");

        // =========================================================
        // 콤마(,) 누락된 데이터 강제 분리
        // =========================================================
        // 1. 닫는 괄호 ')' 뒤에 바로 한글/영어가 오면 콤마 삽입: "5g) 양배추(10g" -> "5g), 양배추(10g"
        cleaned = cleaned.replaceAll("\\)\\s*(?=[가-힣a-zA-Z])", "), ");

        // 2. 단위 뒤에 점(.)이 찍히고 한글/영어가 오면 콤마 삽입: "2g. 소금 1g" -> "2g, 소금 1g"
        cleaned = cleaned.replaceAll("([a-zA-Z가-힣])\\.\\s*(?=[가-힣a-zA-Z])", "$1, ");

        // 카테고리 분리
        cleaned = cleaned.replaceAll("\\((.*?재료|.*?소스|.*?양념장?|고명|육수)\\)\\s*", "\n$1 : ");
        cleaned = cleaned.replaceAll("(^|\\n|,)\\s*(재료|주재료|부재료|양념장?|소스|고명)\\s+(?=[가-힣])", "$1\n$2 : ");
        cleaned = cleaned.replace("\n", ",").replace("\r", ",");

        // 괄호 안 쉼표 보호
        StringBuilder sb = new StringBuilder();
        int depth = 0;
        for (char c : cleaned.toCharArray()) {
            if (c == '(' || c == '{') depth++;
            else if (c == ')' || c == '}') depth--;

            if (c == ',' && depth > 0) sb.append("^");
            else sb.append(c);
        }
        cleaned = sb.toString().replaceAll(",+", ",");
        String[] parts = cleaned.split(",");

        String currentSubCategory = "메인";

        for (int i = 0; i < parts.length; i++) {
            String part = parts[i].replace("^", ", ").trim();
            part = part.replaceAll("^[\\s\\-●■▶*.・·•]+", "");

            if (part.isEmpty()) continue;
            if (!cleanRecipeName.isEmpty() && part.replaceAll("\\s+", "").equals(cleanRecipeName)) continue;

            // 서브카테고리 판별
            if (part.contains(":")) {
                int colonIndex = part.indexOf(":");
                String categoryPart = part.substring(0, colonIndex).trim();
                if (categoryPart.contains("(")) categoryPart = categoryPart.substring(0, categoryPart.indexOf("(")).trim();
                categoryPart = categoryPart.replaceAll("^[^a-zA-Z가-힣0-9]+", "").replaceAll("[^a-zA-Z가-힣0-9]+$", "");
                if (!categoryPart.isEmpty()) currentSubCategory = categoryPart;
                part = part.substring(colonIndex + 1).trim();
                part = part.replaceAll("^[\\s\\-●■▶*.・]+", "");
                if (part.isEmpty()) continue;
            } else if (!part.matches(".*[0-9]+.*") && !part.contains(" ") && part.length() > 1 && part.length() < 10) {
                if (part.matches(".*(재료|소스|양념|고명|육수|드레싱|물)$")) {
                    currentSubCategory = part.replaceAll("^[^a-zA-Z가-힣0-9]+", "").replaceAll("[^a-zA-Z가-힣0-9]+$", "");
                    continue;
                }
            }

            // 특수 재료 가로채기 (육수, 물녹말 등)
            String name = "";
            String amount = "";
            boolean isAbsolute = false;

            String[] absoluteBases = {"물녹말", "녹말물", "채소 육수", "다시마 육수", "멸치 육수", "닭 육수", "고기 육수", "사골 육수", "육수"};
            for (String base : absoluteBases) {
                if (part.equals(base) || part.startsWith(base + " ") || part.startsWith(base + "(")) {
                    name = base;
                    amount = part.substring(base.length()).trim();
                    isAbsolute = true;
                    break;
                }
            }

            if (!isAbsolute) {
                part = part.replaceAll("\\((.*?)\\)[\\s.・]*$", " $1").trim();

                Matcher matcher = NUMBER_PATTERN.matcher(part);
                if (matcher.find()) {
                    name = matcher.group(1).trim();
                    amount = matcher.group(2).trim();
                    if (i == 0 && recipeName != null) name = name.replace(recipeName, "").trim();
                } else {
                    Matcher fallbackMatcher = FALLBACK_PATTERN.matcher(part);
                    if (fallbackMatcher.find()) {
                        name = fallbackMatcher.group(1).trim();
                        amount = fallbackMatcher.group(2).trim();
                    } else {
                        name = part;
                        amount = "적당량";
                    }
                }
            }

            // 이름 정규화 및 수식어 이동
            StringBuilder extracted = new StringBuilder();
            String[] modifiers = {
                    "얇게 썬", "얇게썬", "어슷 썬", "어슷썬", "송송 썬", "송송썬", "채 썬", "채썬", "채친",
                    "데쳐서 다진", "데쳐서", "다진것", "다진 것", "다진", "갈은것", "갈은 것", "갈은", "손질된",
                    "데친", "삶은", "볶은", "부순",
                    "마른것", "마른 것", "마른", "말린", "불린것", "불린 것", "불린",
                    "따뜻한", "미지근한",
                    "생것", "생 것", "생", "갠것", "갠 것", "갠", "중간 크기", "중간크기", "큰", "작은"
            };

            for (String mod : modifiers) {
                if (name.contains(mod)) {
                    String formattedMod = mod.replace("썬", " 썬").replace("  ", " ")
                            .replace("마른것", "마른").replace("마른 것", "마른")
                            .replace("생것", "생").replace("생 것", "생")
                            .replace("갠것", "갠").replace("갠 것", "갠")
                            .replace("불린것", "불린").replace("불린 것", "불린")
                            .replace("갈은것", "갈은").replace("갈은 것", "갈은")
                            .replace("다진것", "다진").replace("다진 것", "다진")
                            .replace("중간크기", "중간 크기")
                            .trim();
                    extracted.append(formattedMod).append(" ");
                    name = name.replace(mod, "").trim();
                }
            }

            String[] purposes = {"쓴맛 제거용", "데치는용", "양념장용", "반죽용", "기호에따라", "필요량", "제거용", "장식용"};
            for (String purp : purposes) {
                if (name.contains(purp)) {
                    extracted.append(purp).append(" ");
                    name = name.replace(purp, "").trim();
                }
            }

            String[] specialBases = {"두 가지 묵", "두가지 묵", "달걀지단", "달걀", "오리고기", "돼지고기", "닭고기", "소고기", "쇠고기", "양고기", "파프리카", "피망", "식용 꽃", "대파", "당근", "연어", "메밀면", "연두부"};
            for (String base : specialBases) {
                if (name.contains(base) && !name.contains("가루")) {
                    int idx = name.indexOf(base);
                    String prefix = name.substring(0, idx).trim();
                    String tail = name.substring(idx + base.length()).trim();

                    prefix = prefix.replaceAll("^[.,(]+", "").replaceAll("[.,)]+$", "").trim();
                    tail = tail.replaceAll("^[.,(]+", "").replaceAll("[.,)]+$", "").trim();

                    if (!prefix.isEmpty()) extracted.append(prefix).append(" ");
                    if (!tail.isEmpty()) extracted.append(tail).append(" ");

                    name = base;
                    break;
                }
            }

            if (name.contains("두 가지 색") || name.contains("두가지 색") || name.contains("두가지색")) {
                extracted.append("두 가지 색 ");
                name = name.replaceAll("두\\s*가\\s*지\\s*색", "").trim();
            }
            if (name.endsWith("각각")) {
                extracted.append("각각 ");
                name = name.replaceAll("각각$", "").trim();
            } else if (name.endsWith("각")) {
                extracted.append("각 ");
                name = name.replaceAll("각$", "").trim();
            }

            name = name.replace("(", " ").replace(")", "");
            name = name.replaceAll("[,]+$", "").trim();
            name = name.replaceAll("것$", "").replaceAll(" 것$", "").trim();
            name = name.replaceAll("\\s+", " ").trim();
            if (name.isEmpty()) name = "재료";

            if (extracted.length() > 0) {
                String prefix = extracted.toString().trim();
                prefix = prefix.replaceAll("[,]+$", "").trim();
                amount = prefix + " " + amount;
            }
            amount = amount.replace("0적당량", "적당량");

            // =========================================================
            // Amount 텍스트 괄호 및 띄어쓰기 정밀 청소
            // =========================================================
            // 1. 역순 괄호 ")(", ") (" 복구 -> "(10g)(20g)" 같은 걸 "(10g 20g)"으로 예쁘게 묶어줍니다.
            amount = amount.replace(")(", " ").replace(") (", " ");

            // 2. 전체가 괄호로 감싸진 경우 껍데기 벗기기: "(200g)" -> "200g"
            if (amount.startsWith("(") && amount.endsWith(")")) {
                amount = amount.substring(1, amount.length() - 1).trim();
            }

            // 3. 단위와 숫자 사이 띄어쓰기 복구: "1캔130g" -> "1캔 130g" (문자 뒤에 숫자가 오면 띄어쓰기)
            amount = amount.replaceAll("([가-힣a-zA-Z])([0-9])", "$1 $2");

            // 4. 괄호 짝이 안 맞는 경우 괄호 완전 삭제 (훨씬 더 견고한 로직)
            int openCount = amount.length() - amount.replace("(", "").length();
            int closeCount = amount.length() - amount.replace(")", "").length();
            // 짝이 안 맞거나, 닫는 괄호가 여는 괄호보다 먼저 등장하는 경우 싹 다 지웁니다.
            if (openCount != closeCount || (amount.indexOf(")") < amount.indexOf("(") && amount.indexOf(")") != -1)) {
                amount = amount.replace("(", "").replace(")", "");
            }

            // 5. g뒤에 점(.)이 붙은 경우 앞뒤 불필요한 점, 콤마 제거 및 공백 압축 ("20g." -> "20g")
            amount = amount.replaceAll("^[.,]+", "").replaceAll("[.,]+$", "").trim();
            amount = amount.replaceAll("\\s+", " ").trim();

            Double parsedWeight = extractWeight(amount);
            ingredientList.add(new IngredientDto(name, amount, parsedWeight, currentSubCategory));
        }
        return ingredientList;
    }

    public static Double extractWeight(String amountStr) {
        if(amountStr == null || amountStr.isBlank()) return 0.0;
        String replacedStr = amountStr.replace("½", "0.5").replace("⅓", "0.33").replace("⅔", "0.66")
                .replace("¼", "0.25").replace("¾", "0.75")
                .replace("⅕", "0.2").replace("⅖", "0.4")
                .replace("⅙", "0.16").replace("⅛", "0.125");

        Pattern pattern = Pattern.compile("([0-9]+\\.?[0-9]*)");
        Matcher matcher = pattern.matcher(replacedStr);

        if(matcher.find()){
            try{
                double value = Double.parseDouble(matcher.group(1));
                String lower = amountStr.toLowerCase();
                if (lower.contains("kg") || (lower.contains("l") && !lower.contains("ml"))) return value * 1000.0;
                return value;
            } catch (Exception e) { return 0.0; }
        }
        return 0.0;
    }
}