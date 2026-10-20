"""Estimate the CES substitution elasticity from the oil import share.

The model's optimal-oil conditions imply a closed form for the oil import share,

    s(p) = alpha**sigma * p**(1 - sigma)        sigma = 1/(1 - theta)

so the share's price elasticity identifies sigma directly:

    d ln s / d ln p = 1 - sigma

The submitted calibration sets theta = 0.5, i.e. sigma = 2, which predicts a
coefficient of -1: oil import bills should FALL as a share of GDP when oil gets
more expensive. Any positive coefficient implies sigma < 1 (complements).

This answers Referee 1's Major 3, which asks that the elasticity be disciplined
with evidence rather than assumed, and it uses data already in the repository.

Inputs (both in this directory):
  spread_data.xlsx  sheet exp_imp_data  -- country x year oil import/GDP, %, 1995-2015
  spread_data.xlsx  sheet import_gdp    -- cross-section average, used for sample selection
  oil_qtrly.xlsx                        -- quarterly real oil price, averaged to annual

Pure standard library: no numpy, pandas or R required.
"""
import zipfile, xml.etree.ElementTree as ET

NS = '{http://schemas.openxmlformats.org/spreadsheetml/2006/main}'
RNS = '{http://schemas.openxmlformats.org/officeDocument/2006/relationships}'


def _col(ref):
    n = 0
    for ch in ref:
        if ch.isalpha():
            n = n*26 + (ord(ch.upper())-64)
        else:
            break
    return n-1


def read_sheet(path, name):
    z = zipfile.ZipFile(path)
    wb = ET.fromstring(z.read('xl/workbook.xml'))
    rels = ET.fromstring(z.read('xl/_rels/workbook.xml.rels'))
    rmap = {r.get('Id'): r.get('Target') for r in rels}
    target = None
    for s in wb.iter(NS+'sheet'):
        if s.get('name') == name:
            target = rmap[s.get(RNS+'id')]
    if target is None:
        raise KeyError(f'no sheet {name!r}; have '
                       f'{[s.get("name") for s in wb.iter(NS+"sheet")]}')
    if not target.startswith('xl/'):
        target = 'xl/'+target.lstrip('/')
    shared = []
    try:
        for si in ET.fromstring(z.read('xl/sharedStrings.xml')).iter(NS+'si'):
            shared.append(''.join(t.text or '' for t in si.iter(NS+'t')))
    except KeyError:
        pass
    rows = []
    for row in ET.fromstring(z.read(target)).iter(NS+'row'):
        cells = {}
        for c in row.iter(NS+'c'):
            v = c.find(NS+'v')
            if v is None or v.text is None:
                continue
            t = c.get('t')
            if t == 's':
                cells[_col(c.get('r'))] = shared[int(v.text)]
            elif t == 'inlineStr':
                cells[_col(c.get('r'))] = ''.join(x.text or '' for x in c.iter(NS+'t'))
            else:
                cells[_col(c.get('r'))] = v.text
        if cells:
            rows.append([cells.get(i, '') for i in range(max(cells)+1)])
    return rows


# ----------------------------------------------------------------------
# Data
# ----------------------------------------------------------------------
import math
import os

HERE = os.path.dirname(os.path.abspath(__file__))


def annual_oil_price():
    """Quarterly real oil price averaged to calendar years."""
    rows = read_sheet(os.path.join(HERE, 'oil_qtrly.xlsx'), 'Sheet 1')
    head = rows[0]
    iq, ip = head.index('qdate'), head.index('real_price')
    acc = {}
    for r in rows[1:]:
        if len(r) <= max(iq, ip) or not r[ip]:
            continue
        acc.setdefault(int(str(r[iq]).split()[0]), []).append(float(r[ip]))
    return {y: sum(v)/len(v) for y, v in acc.items()}


def import_shares():
    """country -> {year: oil import share of GDP, percent}. Zeros are missing."""
    rows = read_sheet(os.path.join(HERE, 'spread_data.xlsx'), 'exp_imp_data')
    years = [int(y) for y in rows[0][1:] if str(y).isdigit()]
    out = {}
    for r in rows[1:]:
        name = r[0].replace('_import/gdp', '').strip().upper()
        vals = {y: float(r[1+k]) for k, y in enumerate(years)
                if len(r) > 1+k and r[1+k] != '' and float(r[1+k]) > 0}
        if vals:
            out[name] = vals
    return out


def importer_sample():
    """The paper's oil-importer sample: average import/GDP above the 1% cutoff."""
    rows = read_sheet(os.path.join(HERE, 'spread_data.xlsx'), 'import_gdp')
    return {r[0].strip().upper() for r in rows[1:]
            if len(r) > 1 and r[1] != '' and float(r[1]) > 1}


# ----------------------------------------------------------------------
# Estimators
# ----------------------------------------------------------------------
def within_ols(obs):
    """Country-demeaned OLS of y on x, SEs clustered by year.

    The regressor is the global oil price, common to all countries within a
    year, so the residuals are correlated across the cross-section. Clustering
    on year is the relevant adjustment; clustering on country is not.
    """
    bycty = {}
    for c, t, x, y in obs:
        bycty.setdefault(c, []).append((t, x, y))
    dm = []
    for rec in bycty.values():
        if len(rec) < 2:
            continue
        mx = sum(r[1] for r in rec)/len(rec)
        my = sum(r[2] for r in rec)/len(rec)
        dm += [(t, x-mx, y-my) for t, x, y in rec]
    sxx = sum(x*x for _, x, _ in dm)
    b = sum(x*y for _, x, y in dm)/sxx
    g = {}
    for t, x, y in dm:
        g[t] = g.get(t, 0.0) + x*(y - b*x)
    return b, math.sqrt(sum(v*v for v in g.values()))/sxx, len(dm), len(bycty)


def first_difference(sh, price, sample):
    """Within-country first differences: removes country-specific trends."""
    d = []
    for c in sample:
        ys = sorted(y for y in sh[c] if y in price)
        for a, b_ in zip(ys, ys[1:]):
            if b_ - a == 1:
                d.append((b_, math.log(price[b_])-math.log(price[a]),
                          math.log(sh[c][b_])-math.log(sh[c][a])))
    sxx = sum(x*x for _, x, _ in d)
    b = sum(x*y for _, x, y in d)/sxx
    g = {}
    for t, x, y in d:
        g[t] = g.get(t, 0.0) + x*(y - b*x)
    return b, math.sqrt(sum(v*v for v in g.values()))/sxx, len(d)


def ols(X, Y):
    k = len(X[0])
    M = [[sum(X[i][a]*X[i][b] for i in range(len(X))) for b in range(k)]
         + [sum(X[i][a]*Y[i] for i in range(len(X)))] for a in range(k)]
    for i in range(k):
        p = max(range(i, k), key=lambda r: abs(M[r][i]))
        M[i], M[p] = M[p], M[i]
        for r in range(k):
            if r != i:
                f = M[r][i]/M[i][i]
                for c in range(i, k+1):
                    M[r][c] -= f*M[i][c]
    return [M[i][k]/M[i][i] for i in range(k)]


def main():
    price, sh, keep = annual_oil_price(), import_shares(), importer_sample()
    sample = sorted(set(sh) & keep)
    obs = [(c, y, math.log(price[y]), math.log(s))
           for c in sample for y, s in sh[c].items() if y in price]
    years = sorted({o[1] for o in obs})

    print(f'oil importers matched: {len(sample)}   years {min(years)}-{max(years)}'
          f'   observations {len(obs)}')
    print()
    print('  d ln(oil import share) / d ln(real oil price) = 1 - sigma')
    print('  sigma = 2 (submitted calibration) predicts -1.000')
    print()
    print(f'  {"specification":<42}{"coef":>9}{"se":>9}{"sigma":>9}')

    rows = []
    b, se, n, nc = within_ols(obs)
    rows.append(('within country, clustered by year', b, se))
    print(f'  {"within country, clustered by year":<42}{b:+9.4f}{se:9.4f}{1-b:9.3f}')

    m = {y: sum(o[3] for o in obs if o[1] == y)/sum(1 for o in obs if o[1] == y)
         for y in years}
    c = ols([[1.0, math.log(price[y])] for y in years], [m[y] for y in years])
    rows.append(('collapsed to a time series', c[1], None))
    print(f'  {"collapsed to a time series":<42}{c[1]:+9.4f}{"":>9}{1-c[1]:9.3f}')

    c2 = ols([[1.0, math.log(price[y]), float(y-years[0])] for y in years],
             [m[y] for y in years])
    rows.append(('collapsed, with linear time trend', c2[1], None))
    print(f'  {"collapsed, with linear time trend":<42}{c2[1]:+9.4f}{"":>9}{1-c2[1]:9.3f}')

    bd, sed, nd = first_difference(sh, price, sample)
    rows.append(('first differences within country', bd, sed))
    print(f'  {"first differences within country":<42}{bd:+9.4f}{sed:9.4f}{1-bd:9.3f}')

    lo, hi = b-1.96*se, b+1.96*se
    print()
    print(f'  baseline 95% CI for the coefficient: [{lo:+.4f}, {hi:+.4f}]')
    print(f'  baseline 95% CI for sigma          : [{1-hi:.3f}, {1-lo:.3f}]')
    print(f'  sigma = 2 (coefficient -1): {"REJECTED" if lo > -1 else "not rejected"}')
    print(f'  sigma = 1 (coefficient  0): '
          f'{"REJECTED" if lo > 0 or hi < 0 else "not rejected"}')

    vals = sorted(s for c_ in sample for y, s in sh[c_].items() if y in price)
    mean = sum(vals)/len(vals)
    print()
    print(f'  oil import share, importer sample: mean {mean:.3f}%  '
          f'median {vals[len(vals)//2]:.3f}%')
    print(f'  => share target s* = {mean/100:.4f}, against the 0.0799 implied by the')
    print(f'     submitted calibration (alpha = 0.3, theta = 0.5).')
    print()
    print('  Feed sigma and s* into oil_price_validation/elasticity_sweep.py to get')
    print('  alpha and the admissible price-grid width.')


if __name__ == '__main__':
    main()
