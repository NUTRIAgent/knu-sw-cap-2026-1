package capstone.ai_meal_assistant_batch.job.kamis;

import java.io.StringReader;
import java.util.ArrayList;
import java.util.List;

import javax.xml.parsers.DocumentBuilderFactory;

import org.springframework.stereotype.Component;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.xml.sax.InputSource;

import lombok.RequiredArgsConstructor;

@Component
@RequiredArgsConstructor
public class KamisNaturePriceListXmlParser {

	public ParsedKamisResponse parse(String xml) {
		if (xml == null || xml.isBlank()) {
			throw new IllegalArgumentException("Empty KAMIS XML response");
		}

		try {
			var dbf = DocumentBuilderFactory.newInstance();
			dbf.setNamespaceAware(false);
			var builder = dbf.newDocumentBuilder();
			var doc = builder.parse(new InputSource(new StringReader(xml)));
			doc.getDocumentElement().normalize();

			String errorCode = firstNonBlank(
					textContentOfFirst(doc.getDocumentElement(), "error_code"),
					textContentOfFirst(doc.getDocumentElement(), "result_code")
			);
			String errorMsg = firstNonBlank(
					textContentOfFirst(doc.getDocumentElement(), "error_msg"),
					textContentOfFirst(doc.getDocumentElement(), "result_msg")
			);
			List<KamisDailySalesItem> items = new ArrayList<>();

			NodeList itemNodes = doc.getElementsByTagName("item");
			for (int i = 0; i < itemNodes.getLength(); i++) {
				Node n = itemNodes.item(i);
				if (n.getNodeType() != Node.ELEMENT_NODE) {
					continue;
				}

				Element el = (Element) n;
				String productClsName = textContent(el, "product_cls_name"); // 도매/소매 구분
				String categoryName = textContent(el, "category_name"); // 부류명
				String productno = textContent(el, "productno"); // 품목코드
				String itemName = textContent(el, "item_name"); // 품목명
				String unit = textContent(el, "unit"); // 단위
				String lastestDay = textContent(el, "lastest_day"); // 실제 조사 날짜 (yyyy-MM-dd)
				String dpr1 = textContent(el, "dpr1"); // 당일 가격

				// 가격이나 코드가 없으면(또는 "-" 처리되어 있으면) 스킵
				if ((dpr1 == null || dpr1.isBlank() || "-".equals(dpr1)) || productno == null) {
					continue;
				}

				items.add(new KamisDailySalesItem(
						productClsName,
						categoryName,
						productno,
						itemName,
						unit,
						lastestDay,
						dpr1));
			}

			return new ParsedKamisResponse(errorCode, errorMsg, items);
		} catch (Exception e) {
			throw new IllegalArgumentException("Failed to parse KAMIS XML", e);
		}
	}

	private static String firstNonBlank(String... candidates) {
		if (candidates == null) return null;
		for (String c : candidates) {
			if (c != null && !c.isBlank()) return c;
		}
		return null;
	}

	private static String textContentOfFirst(Element root, String tag) {
		NodeList list = root.getElementsByTagName(tag);
		if (list.getLength() == 0) return null;
		Node n = list.item(0);
		return n == null ? null : n.getTextContent();
	}

	private static String textContent(Element root, String tag) {
		NodeList list = root.getElementsByTagName(tag);
		if (list.getLength() == 0) return null;
		Node n = list.item(0);
		return n == null ? null : n.getTextContent();
	}

	public record ParsedKamisResponse(String errorCode, String errorMsg, List<KamisDailySalesItem> items) {}

	public record KamisDailySalesItem(
			String productClsName,
			String categoryName,
			String productno,
			String itemName,
			String unit,
			String lastestDay,
			String dpr1) {}
}