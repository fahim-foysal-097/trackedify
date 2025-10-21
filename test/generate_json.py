# for testing prediction chart

import json
from datetime import datetime, timedelta
import math
import os

START = datetime(2025, 8, 7)
DAYS = 60
DATES = [(START + timedelta(days=i)).strftime("%Y-%m-%d") for i in range(DAYS)]
EXPORT_TS = "2025-10-05T12:00:00.000Z"

def write_file(name, data):
    with open(name, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)
    print(f"Wrote {name} ({len(data['expenses'])} records)")

def uptrend_linear():
    expenses = []
    for i, d in enumerate(DATES):
        amt = 5 + i * (95.0 / (DAYS - 1))
        expenses.append({"id": i+1, "category": "Misc", "amount": round(amt,2), "date": d, "note": "Uptrend daily"})
    return {"exported_at": EXPORT_TS, "expenses": expenses}

def downtrend_linear():
    expenses = []
    for i, d in enumerate(DATES):
        amt = 100 - i * (95.0 / (DAYS - 1))
        expenses.append({"id": i+1, "category": "Misc", "amount": round(amt,2), "date": d, "note": "Downtrend daily"})
    return {"exported_at": EXPORT_TS, "expenses": expenses}

def weekly_seasonal():
    expenses = []
    for i, d in enumerate(DATES):
        base = 40.0
        seasonal = 20.0 * math.sin(2 * math.pi * ((i % 7) / 7.0))
        amt = base + seasonal
        expenses.append({"id": i+1, "category": "Food", "amount": round(amt,2), "date": d, "note": "Weekly seasonality"})
    return {"exported_at": EXPORT_TS, "expenses": expenses}

def weekend_spike():
    expenses = []
    for i, d in enumerate(DATES):
        dt = datetime.strptime(d, "%Y-%m-%d")
        if dt.weekday() in (5, 6):
            amt = 80 + (i % 3) * 5
        else:
            amt = 20 + (i % 4) * 2
        expenses.append({"id": i+1, "category": "Leisure", "amount": round(amt,2), "date": d, "note": "Weekend spike"})
    return {"exported_at": EXPORT_TS, "expenses": expenses}

def multiplicative_growth():
    expenses = []
    for i, d in enumerate(DATES):
        amt = 5.0 * (1.03 ** i)
        expenses.append({"id": i+1, "category": "Investment", "amount": round(amt,2), "date": d, "note": "Multiplicative growth"})
    return {"exported_at": EXPORT_TS, "expenses": expenses}

def outliers_spike():
    expenses = []
    for i, d in enumerate(DATES):
        base = 25 + (i % 7)
        if i % 15 == 0:
            amt = base + 300
            note = "Big one-off"
        else:
            amt = base
            note = "Normal"
        expenses.append({"id": i+1, "category": "Shopping", "amount": round(amt,2), "date": d, "note": note})
    return {"exported_at": EXPORT_TS, "expenses": expenses}

def main():
    outdir = "./data"
    datasets = {
        "uptrend_linear.json": uptrend_linear(),
        "downtrend_linear.json": downtrend_linear(),
        "weekly_seasonal.json": weekly_seasonal(),
        "weekend_spike.json": weekend_spike(),
        "multiplicative_growth.json": multiplicative_growth(),
        "outliers_spike.json": outliers_spike(),
    }
    for fname, data in datasets.items():
        path = os.path.join(outdir, fname)
        write_file(path, data)

if __name__ == "__main__":
    main()
