from __future__ import annotations

import json
import sys
from pathlib import Path


API_ROOT = Path(__file__).resolve().parents[1]
PROJECT_ROOT = API_ROOT.parents[1]
sys.path.insert(0, str(API_ROOT / "src"))
sys.path.insert(0, str(PROJECT_ROOT / "packages" / "financial_core_python" / "src"))

from money_pilot_api.main import create_app  # noqa: E402


def main() -> None:
    output_path = API_ROOT / "openapi.json"
    schema = create_app().openapi()
    output_path.write_text(
        json.dumps(schema, indent=2, sort_keys=True, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print(f"Wrote {output_path}")


if __name__ == "__main__":
    main()
