#!/usr/bin/env python3
"""Generate scripts/lockers.json — the physical locker layout for every zone.

Numbering rule: zones are numbered in the order defined in ZONES, never
resetting between zones. Inside a zone, numbers fill column-first (top to
bottom within a column, then move to the next column to the right).

Some cells are reserved (e.g. B206's last two columns are 학생회 사물함,
not rentable) — see RESERVED_COLUMNS. Those cells get `lockerNumber: null`
and are skipped by the counter entirely, so the next zone picks up
numbering exactly where the last *numbered* cell left off.

This is layout-only data (zoneId/row/col/lockerNumber) — it has no
`status` field. Real-time locker status comes from the server
(`LockerAPIService`) and is matched onto numbered cells by `lockerNumber`
at runtime, not baked in here.
"""

import json
from pathlib import Path

ROWS = 6

# (zoneId, columns) — order matters, this is the numbering order.
ZONES = [
    ("B201", 6),
    ("B202", 16),
    ("B203(1)", 8),
    ("B203(2)", 8),
    ("B203(3)", 2),
    ("B204", 14),
    ("B208(2)", 9),
    ("B208(1)", 4),
    ("B207(2)", 4),
    ("B207(1)", 4),
    ("B206", 6),
    ("B205", 4),
]

# zoneId -> 0-indexed columns that are 학생회 사물함 (no rental number).
RESERVED_COLUMNS = {
    "B206": {4, 5},
}

OUTPUT_PATH = Path(__file__).parent / "lockers.json"


def generate_lockers():
    lockers = []
    next_number = 1

    for zone_id, cols in ZONES:
        reserved_cols = RESERVED_COLUMNS.get(zone_id, set())
        zone_start = next_number
        reserved_count = 0

        for col in range(cols):
            for row in range(ROWS):
                if col in reserved_cols:
                    lockers.append({
                        "zoneId": zone_id,
                        "row": row,
                        "col": col,
                        "lockerNumber": None,
                    })
                    reserved_count += 1
                else:
                    lockers.append({
                        "zoneId": zone_id,
                        "row": row,
                        "col": col,
                        "lockerNumber": next_number,
                    })
                    next_number += 1

        zone_end = next_number - 1
        note = f", 학생회 사물함 {reserved_count}칸 제외" if reserved_count else ""
        print(f"{zone_id}: {zone_start} ~ {zone_end} ({cols * ROWS}칸{note})")

    return lockers


def main():
    lockers = generate_lockers()
    OUTPUT_PATH.write_text(
        json.dumps(lockers, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    numbered = sum(1 for locker in lockers if locker["lockerNumber"] is not None)
    print(f"\n총 {len(lockers)}칸 (번호 있는 칸 {numbered}개) -> {OUTPUT_PATH}")


if __name__ == "__main__":
    main()
