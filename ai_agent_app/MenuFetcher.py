import requests
from typing import List, Dict


class MenuFetcher:
    """Spring 백엔드에서 사용자 맞춤 메뉴 후보를 가져오는 클래스."""

    def __init__(self, backend_url: str):
        self.backend_url = backend_url.rstrip("/")

    def fetch_candidate_names(self, jwt_token: str) -> set:
        """
        Spring GET /api/menus/candidates 호출 후 메뉴명 집합 반환.
        실패 시 빈 set 반환 (호출자가 fallback 처리).
        """
        url = f"{self.backend_url}/api/menus/candidates"
        headers = {"Authorization": f"Bearer {jwt_token}"}

        try:
            resp = requests.get(url, headers=headers, timeout=10)
            resp.raise_for_status()
            body = resp.json()
            if body.get("success") and body.get("data"):
                return {menu["name"] for menu in body["data"]}
        except requests.exceptions.ConnectionError:
            print("[MenuFetcher] Spring 백엔드에 연결할 수 없습니다.")
        except requests.exceptions.Timeout:
            print("[MenuFetcher] Spring 백엔드 응답 시간 초과.")
        except Exception as e:
            print(f"[MenuFetcher] 후보 조회 실패: {e}")

        return set()
