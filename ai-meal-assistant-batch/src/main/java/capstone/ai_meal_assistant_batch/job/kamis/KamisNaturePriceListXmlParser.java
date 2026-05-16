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

			String errorCode = textContentOfFirst(doc.getDocumentElement(), "error_code");
			List<KamisNaturePriceItem> items = new ArrayList<>();

			NodeList itemNodes = doc.getElementsByTagName("item");
			for (int i = 0; i < itemNodes.getLength(); i++) {
				Node n = itemNodes.item(i);
				if (n.getNodeType() != Node.ELEMENT_NODE) {
					continue;
				}

				Element el = (Element) n;
				// condition.item도 "item"이라서, 가격 필드(price)가 없으면 스킵
				String price = textContent(el, "price");
				String unit = textContent(el, "unit");
				String regday = textContent(el, "regday");
				String marketname = textContent(el, "marketname");
				String countyname = textContent(el, "countyname");

				if ((price == null || price.isBlank()) && (unit == null || unit.isBlank())
						&& (regday == null || regday.isBlank())
						&& (marketname == null || marketname.isBlank())
						&& (countyname == null || countyname.isBlank())) {
					continue;
				}

				// 통계성(평균/null market) 데이터는 제외(필요하면 설정으로 열어둘 수 있음)
				if ("평균".equals(countyname)) {
					continue;
				}

				items.add(new KamisNaturePriceItem(
						textContent(el, "seqnum"),
						countyname,
						marketname,
						unit,
						regday,
						price));
			}

			return new ParsedKamisResponse(errorCode, items);
		} catch (Exception e) {
			throw new IllegalArgumentException("Failed to parse KAMIS XML", e);
		}
	}

	private static String textContentOfFirst(Element root, String tag) {
		NodeList list = root.getElementsByTagName(tag);
		if (list.getLength() == 0) {
			return null;
		}
		Node n = list.item(0);
		return n == null ? null : n.getTextContent();
	}

	private static String textContent(Element root, String tag) {
		NodeList list = root.getElementsByTagName(tag);
		if (list.getLength() == 0) {
			return null;
		}
		Node n = list.item(0);
		return n == null ? null : n.getTextContent();
	}

	public record ParsedKamisResponse(String errorCode, List<KamisNaturePriceItem> items) {
	}

	public record KamisNaturePriceItem(
			String seqnum,
			String countyname,
			String marketname,
			String unit,
			String regday,
			String price) {
	}
}
