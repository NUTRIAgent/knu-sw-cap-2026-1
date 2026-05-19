package capstone.ai_meal_assistant_batch.job.kamis;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.regex.Pattern;

/**
 * KAMIS 품목명과 내부 재료명을 자동 매칭하기 위한 경량 문자열 매처.
 *
 * 목표:
 * - 완전 자동 100% 정답보단, 사람이 JSON을 최종 검수/수정할 수 있게 "후보"를 잘 뽑아준다.
 */
final class KamisNameMatcher {

	private static final Pattern WS = Pattern.compile("\\s+");

	private KamisNameMatcher() {
	}

	static String normalize(String s) {
		if (s == null) {
			return "";
		}
		String x = s.trim();
		// 괄호/옵션 제거 (예: "감자(수미)" -> "감자")
		x = x.replaceAll("\\(.*?\\)", "");
		// 구분자/특수문자 정리
		x = x.replaceAll("[·•ㆍ]", " ");
		x = x.replaceAll("[_/\\-]", " ");
		x = WS.matcher(x).replaceAll(" ");
		return x.toLowerCase(Locale.KOREA).trim();
	}

	/**
	 * 0~1.0 사이 점수. 1.0이면 같음.
	 *
	 * - 빠르고 구현이 쉬운 Bigram Dice coefficient를 사용.
	 */
	static double similarity(String aRaw, String bRaw) {
		String a = normalize(aRaw);
		String b = normalize(bRaw);
		if (a.isBlank() || b.isBlank()) {
			return 0.0;
		}
		if (a.equals(b)) {
			return 1.0;
		}
		// 포함 관계 보너스
		if (a.contains(b) || b.contains(a)) {
			return 0.92;
		}

		List<String> aBigrams = bigrams(a);
		List<String> bBigrams = bigrams(b);
		if (aBigrams.isEmpty() || bBigrams.isEmpty()) {
			return 0.0;
		}

		int overlap = 0;
		boolean[] used = new boolean[bBigrams.size()];
		for (String x : aBigrams) {
			for (int i = 0; i < bBigrams.size(); i++) {
				if (used[i]) {
					continue;
				}
				if (x.equals(bBigrams.get(i))) {
					overlap++;
					used[i] = true;
					break;
				}
			}
		}

		return (2.0 * overlap) / (aBigrams.size() + bBigrams.size());
	}

	static MatchResult bestMatch(String sourceName, List<String> candidates, int topK) {
		List<Scored> scored = new ArrayList<>(candidates.size());
		for (String c : candidates) {
			double score = similarity(sourceName, c);
			scored.add(new Scored(c, score));
		}
		scored.sort(Comparator.comparingDouble(Scored::score).reversed());
		int k = Math.min(topK, scored.size());
		List<Scored> top = scored.subList(0, k);
		return new MatchResult(sourceName, top);
	}

	private static List<String> bigrams(String s) {
		String x = s.replace(" ", "");
		if (x.length() < 2) {
			return List.of();
		}
		List<String> out = new ArrayList<>(x.length() - 1);
		for (int i = 0; i < x.length() - 1; i++) {
			out.add(x.substring(i, i + 2));
		}
		return out;
	}

	record Scored(String candidate, double score) {
	}

	record MatchResult(String sourceName, List<Scored> topCandidates) {
	}
}
