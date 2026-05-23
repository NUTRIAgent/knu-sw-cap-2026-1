import json
from typing import List, Dict

class RecipeDataLoader:
    @staticmethod
    def load_json(path: str) -> List[Dict]:
        with open(path, 'r', encoding='utf-8') as f:
            return json.load(f)