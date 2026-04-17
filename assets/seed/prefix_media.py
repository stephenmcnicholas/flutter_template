#!/usr/bin/env python3
import json
from pathlib import Path

INPUT_JSON = "exercises.json"
OUTPUT_JSON = "exercises_prefixed.json"


def prefix_path(path: str, code: str) -> str:
    """
    Prefix the filename in a path with '{code}_'
    """
    p = Path(path)
    return str(p.parent / f"{code}_{p.name}")


def process_entry(entry: dict) -> dict:
    code = entry.get("id")
    if not code:
        return entry  # leave unchanged if no id

    # Copy to avoid mutating original structure
    updated = dict(entry)

    if "mediaPath" in updated and updated["mediaPath"]:
        updated["mediaPath"] = prefix_path(updated["mediaPath"], code)

    if "thumbnailPath" in updated and updated["thumbnailPath"]:
        updated["thumbnailPath"] = prefix_path(updated["thumbnailPath"], code)

    return updated


def main():
    input_path = Path(INPUT_JSON)
    if not input_path.exists():
        raise FileNotFoundError(f"Input JSON not found: {INPUT_JSON}")

    with input_path.open("r", encoding="utf-8") as f:
        data = json.load(f)

    # Handle either a list or a single object
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