#!/usr/bin/env python3
"""Count the number of electric vehicle models in data/ev-data.json."""
from __future__ import annotations

import json
from pathlib import Path


def main() -> None:
    data_file = Path(__file__).resolve().parent.parent / "data" / "ev-data.json"
    with data_file.open(encoding="utf-8") as f:
        content = json.load(f)
    models = content.get("data", [])
    print(len(models))

if __name__ == "__main__":
    main()
