import json
from typing import List, Dict, Any


class RecipeDataLoader:
    @staticmethod
    def load_json(path: str) -> Any:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
