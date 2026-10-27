"""Build the quarterly country panel used for the referee's empirical tests.

Pure stdlib: numpy/pandas are not available in this environment.

Sources, all from empirical/:
  spread_data.xlsx sheet 'spread'      monthly EMBI spreads, 67 countries, 1994m1-2019m9
  spread_data.xlsx sheet 'import_gdp'  country-level oil import / GDP, the oil-dependence measure
  oil_qtrly.xlsx                       quarterly WTI, nominal and CPI-deflated real price

Output: analysis_panel.csv with one row per country-quarter.
"""
import zipfile, re, csv, math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
EMP  = ROOT / "empirical"


def read_sheet(path, idx=0):
    z = zipfile.ZipFile(path)
    shared = []
    if "xl/sharedStrings.xml" in z.namelist():
        s = z.read("xl/sharedStrings.xml").decode("utf8")
        shared = [re.sub(r"<[^>]+>", "", m) for m in re.findall(r"<si>(.*?)</si>", s, re.S)]
    names = sorted(n for n in z.namelist() if re.match(r"xl/worksheets/sheet\d+\.xml$", n))
    x = z.read(names[idx]).decode("utf8")
    rows = []
    for r in re.findall(r"<row[^>]*>(.*?)</row>", x, re.S):
        cells = []
        for attr, body in re.findall(r"<c([^>]*)>(.*?)</c>", r, re.S):
            v = re.search(r"<v>(.*?)</v>", body)
            val = v.group(1) if v else ""
            if 't="s"' in attr and val != "":
                val = shared[int(val)]
            cells.append(val)
        rows.append(cells)
    return rows


def num(x):
    try:
        v = float(x)
        return v if v == v else None
    except (TypeError, ValueError):
        return None


def main():
    # ---- monthly spreads -> quarterly means -------------------------------
    rows = read_sheet(EMP / "spread_data.xlsx", 0)
    monthly = {}                       # (country, (year, q)) -> [spreads]
    for r in rows[1:]:
        if len(r) < 6:
            continue
        country, period, spread = r[1], r[2], num(r[5])
        m = re.match(r"(\d{4})m(\d{1,2})$", period or "")
        if not m or spread is None:
            continue
        y, mo = int(m.group(1)), int(m.group(2))
        monthly.setdefault((country, (y, (mo - 1) // 3 + 1)), []).append(spread)
    # require at least 2 of the 3 months so a quarter is not one stray reading
    spread_q = {k: sum(v) / len(v) for k, v in monthly.items() if len(v) >= 2}

    # ---- oil dependence ---------------------------------------------------
    dep = {}
    for r in read_sheet(EMP / "spread_data.xlsx", 3)[1:]:
        if len(r) >= 2 and num(r[1]) is not None:
            dep[r[0].strip().upper()] = num(r[1])

    # ---- quarterly oil ----------------------------------------------------
    oil = {}
    for r in read_sheet(EMP / "oil_qtrly.xlsx", 0)[1:]:
        m = re.match(r"(\d{4})\s*Q(\d)", (r[0] or "").strip())
        if not m:
            continue
        rp = num(r[3]) if len(r) > 3 else None
        if rp and rp > 0:
            oil[(int(m.group(1)), int(m.group(2)))] = rp

    qs = sorted(oil)
    dlogp = {qs[i]: math.log(oil[qs[i]] / oil[qs[i - 1]]) for i in range(1, len(qs))}

    # Realised volatility: rolling sd of the last 4 quarterly oil log-returns,
    # using only information available at t. The paper's own measure is the
    # fitted stochastic-volatility series, which is not in the repo; this is the
    # standard observable proxy and is what a referee could reproduce.
    vol = {}
    for i in range(1, len(qs)):
        win = [dlogp[qs[j]] for j in range(max(1, i - 3), i + 1)]
        if len(win) == 4:
            mu = sum(win) / len(win)
            vol[qs[i]] = math.sqrt(sum((x - mu) ** 2 for x in win) / (len(win) - 1))

    def qprev(q):
        y, k = q
        return (y - 1, 4) if k == 1 else (y, k - 1)

    out = []
    for (country, q), s in sorted(spread_q.items()):
        p = qprev(q)
        s_lag = spread_q.get((country, p))
        if s_lag is None or q not in dlogp or q not in vol:
            continue
        d = dep.get(country.strip().upper())
        if d is None or d <= 0:          # keep net oil importers only
            continue
        out.append(dict(country=country, year=q[0], quarter=q[1],
                        spread=s, d_spread=s - s_lag, d_log_oil=dlogp[q],
                        oil_vol=vol[q], oil_dep=d))

    with open(Path(__file__).parent / "analysis_panel.csv", "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(out[0]))
        w.writeheader()
        w.writerows(out)

    cs = sorted({r["country"] for r in out})
    yrs = sorted({r["year"] for r in out})
    print(f"panel: {len(out)} country-quarter observations")
    print(f"  countries {len(cs)}   years {yrs[0]}-{yrs[-1]}")
    print(f"  oil volatility: min {min(r['oil_vol'] for r in out):.4f} "
          f"median {sorted(r['oil_vol'] for r in out)[len(out)//2]:.4f} "
          f"max {max(r['oil_vol'] for r in out):.4f}")
    print(f"  oil dependence: min {min(dep.values()):.3f} max {max(dep.values()):.3f}")


if __name__ == "__main__":
    main()
