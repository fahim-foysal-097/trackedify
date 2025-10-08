#!/usr/bin/env python3
"""
Generate random expense data (JSON) for a given number of days.

Usage:
  python gen_expenses.py --days 30 --out sample.json --dart-file path/to/icon_categories.dart
"""

import argparse
import json
import random
import re
from collections import defaultdict
from datetime import date, timedelta
from pathlib import Path
from typing import Dict, List, Optional, Tuple

# ---------- Configuration / sensible defaults ----------
DEFAULT_CATEGORIES = [
    # Expanded to 116+ categories based on common personal finance expense categories
    # (id, name, color) - colors are random ARGB integers for variety
    (1, "Mortgage/Rent", 4285621195),
    (2, "Property Taxes", 4280370935),
    (3, "Household Repairs", 4293100636),
    (4, "Home Improvement", 4286965164),
    (5, "House Insurance", 4287373591),
    (6, "HOA Fees", 4293398378),
    (7, "Household Maintenance", 4285744824),
    (8, "Car Payment", 4290655436),
    (9, "Car Warranty", 4284429947),
    (10, "Car Repairs", 4292310529),
    (11, "Gas/Fuel", 4288283190),
    (12, "Car Insurance", 4284770116),
    (13, "Public Transport", 4282158503),
    (14, "Car Supplies", 4288872890),
    (15, "Parking Fees", 4283339898),
    (16, "Tolls", 4286044350),
    (17, "Car Registration", 4286953505),
    (18, "Electricity", 4279959086),
    (19, "Water", 4291602331),
    (20, "Trash/Recycling", 4293261358),
    (21, "Gas Utility", 4289614956),
    (22, "Sewer", 4287035065),
    (23, "Phone Bill", 4294087151),
    (24, "Internet Bill", 4292220174),
    (25, "Alarm System", 4278606117),
    (26, "Health Insurance", 4290592052),
    (27, "Dental Insurance", 4288302892),
    (28, "Vision Insurance", 4285157062),
    (29, "Life Insurance", 4291898449),
    (30, "Long-Term Care Insurance", 4281962134),
    (31, "Disability Insurance", 4289887110),
    (32, "Malpractice Insurance", 4280892191),
    (33, "Liability Insurance", 4283727620),
    (34, "Prescriptions", 4294020540),
    (35, "Doctor Visits", 4279626861),
    (36, "Dentist Visits", 4285557277),
    (37, "Eye Doctor", 4287743685),
    (38, "Other Doctor Visits", 4294906509),
    (39, "Credit Cards", 4290007025),
    (40, "Student Loans", 4291386637),
    (41, "Car Loans", 4292986904),
    (42, "Personal Loans", 4279449782),
    (43, "Medical Bills", 4287558894),
    (44, "Extra House Loans", 4291719430),
    (45, "Emergency Fund", 4280055375),
    (46, "Retirement Savings", 4288678433),
    (47, "College Savings", 4287318239),
    (48, "Other Savings", 4283990436),
    (49, "Additional Investing", 4285923663),
    (50, "Groceries", 4284534818),
    (51, "Restaurants", 4288577676),
    (52, "Holiday Food", 4293646965),
    (53, "Convenience Meals", 4287746307),
    (54, "Delivery Fees", 4293198152),
    (55, "Paper Towels", 4283680703),
    (56, "Diapers", 4293516978),
    (57, "Baby Formula", 4293128503),
    (58, "Cleaning Supplies", 4285037287),
    (59, "Dishwasher Soap", 4288657568),
    (60, "Laundry Detergent", 4286619611),
    (61, "Kleenex", 4283331626),
    (62, "Paper Plates", 4281673002),
    (63, "Basic Tools", 4288730104),
    (64, "Childcare", 4279773815),
    (65, "Office Supplies", 4280328153),
    (66, "Work Subscriptions", 4286445551),
    (67, "Extra Travel", 4283435770),
    (68, "Continuing Education", 4285324372),
    (69, "Work Uniform", 4285688106),
    (70, "Gym Membership", 4292379526),
    (71, "Hair Care", 4285337650),
    (72, "Alcohol", 4288242380),
    (73, "Makeup", 4281246307),
    (74, "Clothing", 4287031659),
    (75, "Vitamins", 4282543359),
    (76, "Movies", 4284528265),
    (77, "Concerts", 4285818433),
    (78, "Books", 4286224694),
    (79, "Bars", 4290483972),
    (80, "Outings", 4288912298),
    (81, "Cable", 4290069189),
    (82, "Hobby Supplies", 4293167751),
    (83, "Streaming", 4291395711),
    (84, "Other Subscriptions", 4288750166),
    (85, "Vacations", 4290356652),
    (86, "Casinos", 4282015701),
    (87, "Amusement Parks", 4287956327),
    (88, "Gifts", 4287719005),
    (89, "Holidays", 4287281098),
    (90, "Donations", 4288132221),
    (91, "Babysitters", 4289282207),
    (92, "Extracurricular", 4286575822),
    (93, "Activity Supplies", 4284424531),
    (94, "School Supplies", 4293413118),
    (95, "Kids Healthcare", 4281114142),
    (96, "Kids Haircuts", 4294273423),
    (97, "Teacher Gifts", 4286584582),
    (98, "School Pictures", 4294349975),
    (99, "Birthday Gifts", 4293960975),
    (100, "Allowance", 4278741177),
    (101, "Kids Clothes", 4281034466),
    (102, "Lunch Money", 4284484634),
    (103, "Summer Camps", 4284083977),
    (104, "Pet Food", 4280480802),
    (105, "Pet Meds", 4287263824),
    (106, "Kenneling", 4282599220),
    (107, "Vet Bills", 4291799942),
    (108, "Grooming", 4294168985),
    (109, "Pet Sitter", 4284261006),
    (110, "Pet Training", 4290521007),
    (111, "Household Replacements", 4283405644),
    (112, "Parking Tickets", 4278330236),
    (113, "Postage", 4280149528),
    (114, "Special Occasions", 4278667258),
    (115, "Party Expenses", 4286338092),
    (116, "ATM Fees", 4294513637),
]

# category -> (min_amount, max_amount, relative frequency weight)
# Keeping original, new categories use fallback (5, 200, 1)
CATEGORY_AMOUNTS = {
    "Food": (5, 60, 20),
    "Transport": (10, 150, 20),
    "Shopping": (20, 400, 8),
    "Entertainment": (5, 120, 6),
    "Game": (50, 500, 2),
    "Bills": (100, 5000, 3),
    "Health": (10, 200, 2),
    "Education": (50, 3000, 1),
    "Groceries": (20, 300, 10),
    "Travel": (50, 2000, 1),
    "Fuel": (20, 200, 4),
    "Subscriptions": (1, 50, 4),
    "Pets": (5, 200, 1),
    "Rent": (300, 5000, 1),
    "Investment": (10, 2000, 1),
    "Course": (100, 3000, 1),
    "Mobile": (5, 100, 4),
    "Mortgage/Rent": (800, 3000, 2),
    "Car Payment": (200, 800, 2),
    "Restaurants": (10, 100, 15),
    "Clothing": (20, 300, 5),
    "Gym Membership": (20, 100, 1),
    "Vacations": (500, 5000, 1),
    "Gifts": (10, 200, 3),
    "Donations": (5, 500, 1),
    "Pet Food": (10, 100, 2),
    "Vet Bills": (50, 1000, 1),
}

SAMPLE_NOTES = [
    None,
    "",
    "Lunch",
    "Taxi",
    "Uber",
    "Groceries",
    "Steam sale",
    "Zero Escape",
    "Portal & Portal 2",
    "Half-Life 2 & Ep 1,2",
    "Witcher 3",
    "Cactus",
    "Subscription renewal",
    "Medicine",
    "Coffee",
    "Dinner",
    "Gas fill-up",
    "Movie ticket",
    "Gym session",
    "Haircut",
    "Vet visit",
    "School supplies",
]

# ---------- Helper functions ----------
def parse_icon_categories_from_dart(dart_path: Path) -> Dict[str, List[str]]:
    """
    Parse a Dart file and extract the iconCategories map:
    returns a mapping of category-key-in-dart -> list of icon names (strings like "Icons.fastfood")
    This is a heuristic parser using regex; it doesn't fully parse Dart.
    """
    if not dart_path.exists():
        return {}

    text = dart_path.read_text(encoding="utf-8")

    # Find the start of the iconCategories map literal
    # look for "final Map<String, List<IconData>> iconCategories = { ... };"
    m = re.search(r"iconCategories\s*=\s*{", text)
    if not m:
        return {}

    # Extract the braces block for the map (very simple brace matching)
    start = m.end() - 1
    brace_level = 0
    end = None
    for i in range(start, len(text)):
        ch = text[i]
        if ch == "{":
            brace_level += 1
        elif ch == "}":
            brace_level -= 1
            if brace_level == 0:
                end = i
                break
    if end is None:
        return {}

    map_block = text[start:end + 1]

    # Find entries like '  'Food & Drink': [ Icons.fastfood, Icons.restaurant, ... ],'
    entries = re.finditer(r"(['\"])(?P<key>.+?)\1\s*:\s*\[(?P<list>.*?)\]", map_block, flags=re.S)
    parsed = {}
    for ent in entries:
        key = ent.group("key").strip()
        list_block = ent.group("list")
        # find Icons.something occurrences
        icons = re.findall(r"Icons\.[a-zA-Z0-9_]+", list_block)
        # dedupe while preserving order
        seen = set()
        icons_unique = []
        for ic in icons:
            if ic not in seen:
                icons_unique.append(ic)
                seen.add(ic)
        parsed[key] = icons_unique
    return parsed


def best_match_dart_key(category_name: str, dart_keys: List[str]) -> Optional[str]:
    """
    Find a best matching key in dart_keys for category_name using simple heuristics:
    - exact match (case-insensitive)
    - substring
    - words overlap
    """
    cat = category_name.lower()
    # exact match
    for k in dart_keys:
        if k.lower() == cat:
            return k
    # substring
    for k in dart_keys:
        if cat in k.lower() or k.lower() in cat:
            return k
    # overlap of words
    cat_words = set(re.findall(r"\w+", cat))
    best = None
    best_score = 0
    for k in dart_keys:
        k_words = set(re.findall(r"\w+", k.lower()))
        score = len(cat_words & k_words)
        if score > best_score:
            best_score = score
            best = k
    return best if best_score > 0 else None


def stable_fallback_icon_code(icon_name: str) -> int:
    """
    Produce a deterministic integer to use as an icon_code fallback.
    The range is chosen to look like typical codePoints (roughly 0xE000 - 0xF8FF),
    but keep it positive and repeatable.
    """
    # simple multiplicative hash -> 0xE000 .. 0xF8FF range
    h = abs(hash(icon_name)) % 0x1FFF  # 8191 range
    return 0xE000 + h


def choose_category_by_weights(categories: List[str]) -> str:
    """Choose a category based on the configured CATEGORY_AMOUNTS weights."""
    weights = []
    for c in categories:
        w = CATEGORY_AMOUNTS.get(c, (1, 10, 1))[2]
        weights.append(w)
    return random.choices(categories, weights=weights, k=1)[0]


def rand_amount_for_category(cat: str) -> float:
    mn, mx, _ = CATEGORY_AMOUNTS.get(cat, (5, 200, 1))
    # produce amounts with cents ending .0 or .5 for readability
    amt = round(random.uniform(mn, mx), 2)
    # Optionally snap to nearest 0.5 to look nicer:
    amt = round(amt * 2) / 2.0
    return float(amt)


# ---------- Main generation logic ----------
def generate_data(
    days: int = 30,
    end_date: Optional[date] = None,
    dart_file: Optional[Path] = None,
    seed: Optional[int] = None,
) -> Dict:
    """
    Generate JSON-like dict with keys "expenses" and "categories".
    - days: number of days to generate (ending at end_date, inclusive)
    - end_date: date object; if None, defaults to today
    - dart_file: path to dart file to extract icon names from
    - seed: optional RNG seed for reproducibility
    """
    if seed is not None:
        random.seed(seed)

    if end_date is None:
        end_date = date.today()

    start_date = end_date - timedelta(days=days - 1)
    date_list = [start_date + timedelta(days=i) for i in range(days)]

    # Parse dart iconCategories
    dart_icons_map = parse_icon_categories_from_dart(dart_file) if dart_file else {}
    dart_keys = list(dart_icons_map.keys())

    # Prepare categories output
    categories_out = []
    for cid, cname, color in DEFAULT_CATEGORIES:
        # try to find best matching key from dart file
        icon_name = None
        icon_code = None
        if dart_keys:
            matched_key = best_match_dart_key(cname, dart_keys)
            if matched_key:
                icons_for_key = dart_icons_map.get(matched_key, [])
                if icons_for_key:
                    icon_name = icons_for_key[0]  # pick first available icon
                    # cannot get the true codePoint from Python; produce stable fallback
                    icon_code = stable_fallback_icon_code(icon_name)
        # fallback if still None
        if icon_name is None:
            icon_name = f"Icons.default_{cname.lower().replace(' ', '_').replace('/', '_')}"
            icon_code = stable_fallback_icon_code(icon_name)

        categories_out.append(
            {"id": cid, "name": cname, "color": color, "icon_code": icon_code, "icon_name": icon_name}
        )

    # Build expense entries
    expenses = []
    next_id = 1
    category_names = [c["name"] for c in categories_out]

    # Create a random number of transactions per day (0..3) with weighted categories
    for d in date_list:
        num_transactions = random.choices([0, 1, 2, 3], weights=[10, 40, 30, 20], k=1)[0]
        for _ in range(num_transactions):
            cat = choose_category_by_weights(category_names)
            amt = rand_amount_for_category(cat)
            note = random.choice(SAMPLE_NOTES)
            expenses.append(
                {
                    "id": next_id,
                    "category": cat,
                    "amount": amt,
                    "date": d.isoformat(),
                    "note": note,
                }
            )
            next_id += 1

    # Shuffle expenses a bit to make dates appear unordered
    random.shuffle(expenses)

    return {"expenses": expenses, "categories": categories_out}


# ---------- CLI ----------
def main():
    p = argparse.ArgumentParser(description="Generate random expense JSON for N days.")
    p.add_argument("--days", type=int, default=30, help="Number of days to generate (default 30).")
    p.add_argument("--end-date", type=str, default=None, help="End date YYYY-MM-DD (default today).")
    p.add_argument("--dart-file", type=str, default=None, help="Path to Dart file containing iconCategories map.")
    p.add_argument("--out", type=str, default="expenses.json", help="Output JSON filename.")
    p.add_argument("--seed", type=int, default=42, help="RNG seed for reproducible data.")
    args = p.parse_args()

    end = None
    if args.end_date:
        y, m, d = map(int, args.end_date.split("-"))
        end = date(y, m, d)

    dart_path = Path(args.dart_file) if args.dart_file else None

    data = generate_data(days=args.days, end_date=end, dart_file=dart_path, seed=args.seed)

    # Write JSON with indentation
    out_path = Path(args.out)
    out_path.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"Wrote {len(data['expenses'])} expenses and {len(data['categories'])} categories to {out_path}")


if __name__ == "__main__":
    main()