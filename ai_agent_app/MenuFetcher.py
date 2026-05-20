import requests
from typing import List, Optional


class MenuFetcher:
    """Spring 백엔드에서 사용자 맞춤 메뉴 후보를 가져오는 클래스."""

    def __init__(self, backend_url: str):
        self.backend_url = backend_url.rstrip("/")

    def fetch_candidates_full(self, jwt_token: Optional[str]) -> List[dict]:
        """
        Spring GET /api/menus/candidates 호출 후
        AI 내부 포맷(RCP_NM, INFO_ENG, ...) 의 dict 리스트 반환.
        실패 시 빈 리스트 반환.
        """
        url = f"{self.backend_url}/api/menus/candidates"
        headers = {}
        if jwt_token:
            headers["Authorization"] = f"Bearer {jwt_token}"

        try:
            resp = requests.get(url, headers=headers, timeout=10)
            resp.raise_for_status()
            body = resp.json()
            if body.get("success") and body.get("data"):
                return [self._to_ai_format(m) for m in body["data"]]
        except requests.exceptions.ConnectionError:
            print("[MenuFetcher] Spring 백엔드에 연결할 수 없습니다.")
        except requests.exceptions.Timeout:
            print("[MenuFetcher] Spring 백엔드 응답 시간 초과.")
        except Exception as e:
            print(f"[MenuFetcher] 후보 조회 실패: {e}")

        return []

    def _to_ai_format(self, dto: dict) -> dict:
        """Spring MenuCandidateDto → AI 내부 JSON 포맷 변환."""
        recipe = {
            "RCP_NM":         dto.get("name", ""),
            "RCP_PARTS_DTLS": dto.get("ingredientsText", ""),
            "INFO_ENG":        str(dto.get("calories") or 0),
            "INFO_PRO":        str(dto.get("protein") or 0),
            "INFO_FAT":        str(dto.get("fat") or 0),
            "INFO_CAR":        str(dto.get("carbs") or 0),
            "INFO_NA":         str(dto.get("sodium") or 0),
            "ATT_FILE_NO_MAIN": dto.get("mainImageUrl", ""),
            "RCP_NA_TIP":      dto.get("healthTip", ""),
        }
        # 조리 단계 (steps 테이블 연결 후 채워짐)
        for step in dto.get("steps", []):
            num = str(step.get("stepNo", 0)).zfill(2)
            recipe[f"MANUAL{num}"]     = step.get("content", "")
            recipe[f"MANUAL_IMG{num}"] = step.get("imageUrl", "")
        return recipe
