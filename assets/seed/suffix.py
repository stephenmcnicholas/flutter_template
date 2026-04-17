#!/usr/bin/env python3
import json
from pathlib import Path

INPUT_JSON = "exercises_prefixed.json"
OUTPUT_JSON = "exercise_updated.json"


def add_thumb_suffix(path: str) -> str:
    """
    Insert '_thumb' before the file extension.
    """
    p = Path(path)
    return str(p.parent / f"{p.stem}_thumb{p.suffix}")


def process_entry(entry: dict) -> dict:
    updated = dict(entry)

    if "thumbnailPath" in updated and updated["thumbnailPath"]:
        updated["thumbnailPath"] = add_thumb_suffix(updated["thumbnailPath"])

    return updated


def main():
    input_path = Path(INPUT_JSON)
    if not input_path.exists():
        raise FileNotFoundError(f"Input JSON not found: {INPUT_JSON}")

    with input_path.open("r", encoding="utf-8") as f:
        data = json.load(f)

    if isinstance(data, list):
        updated_data = [process_entry(item) for item in data]
    elif isinstance(data, dict):
        updated_data = process_entry(data)
    else:
        raise ValueError("Unsupported JSON structure")

    with Path(OUTPUT_JSON).open("w", encoding="utf-8") as f:
        json.dump(updated_data, f, indent=2, ensure_ascii=False)

    print(f"Updated JSON written to {OUTPUT_JSON}")


if __name__ == "__main__":
    main()