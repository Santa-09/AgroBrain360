import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
LANG_DIR = ROOT / "mobile_app" / "assets" / "languages"
BASE_FILE = LANG_DIR / "en.json"
LOCALES = ["hi.json", "od.json", "ta.json", "te.json"]


def load_json(path: Path) -> dict[str, str]:
    with open(path, encoding="utf-8-sig") as f:
        data = json.load(f)
    return {str(k): str(v) for k, v in data.items()}


def write_json(path: Path, data: dict[str, str]) -> None:
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")


def main() -> int:
    english = load_json(BASE_FILE)

    for name in LOCALES:
        path = LANG_DIR / name
        current = load_json(path)
        merged = dict(english)
        merged.update(current)
        write_json(path, merged)
        print(f"{name}: added {len(set(english) - set(current))} missing keys")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
