"""Country-by-country substitution elasticities, for R1 Major 3.

The referee asks what it means to impose a single CES substitution elasticity on
35 heterogeneous economies. The share equation identifies sigma country by
country, so the question can be answered with the same data that disciplines the
pooled estimate:

    ln s_ct = a_c + (1 - sigma_c) ln p_t + e_ct

estimated separately for each importer. This file reports the distribution of
the implied sigma_c, how much of its spread is real rather than sampling noise,
and whether it lines up with oil dependence -- the dimension along which the
model's conclusion would actually be distorted.

Loaders are reused from estimate_substitution_elasticity.py so the sample, the
price series and the importer cutoff are identical to the pooled estimates.

Pure standard library.
"""
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

from estimate_substitution_elasticity import (        # noqa: E402
    annual_oil_price, import_shares, importer_sample)

# the range of elasticities the model was actually solved over
SWEEP_LO, SWEEP_HI = 0.20, 0.50
ADOPTED = 0.25


def ols1(x, y):
    """Simple regression of y on x with a constant.

    Returns (slope, se, n, r2). The se is the textbook homoskedastic one: with
    about twenty annual observations per country there is no useful degree of
    freedom for a HAC correction, and the point of the exercise is the SPREAD of
    the slopes across countries, not a test on any one of them.
    """
    n = len(x)
    mx = sum(x)/n
    my = sum(y)/n
    sxx = sum((xi-mx)**2 for xi in x)
    sxy = sum((xi-mx)*(yi-my) for xi, yi in zip(x, y))
    b = sxy/sxx
    a = my - b*mx
    res = [yi - a - b*xi for xi, yi in zip(x, y)]
    sse = sum(r*r for r in res)
    syy = sum((yi-my)**2 for yi in y)
    se = math.sqrt(sse/(n-2)/sxx) if n > 2 else float('nan')
    return b, se, n, (1 - sse/syy if syy > 0 else float('nan'))


def quantile(v, q):
    """Linear-interpolated quantile of a sorted copy of v."""
    s = sorted(v)
    if len(s) == 1:
        return s[0]
    h = (len(s)-1)*q
    lo = int(math.floor(h))
    hi = min(lo+1, len(s)-1)
    return s[lo] + (h-lo)*(s[hi]-s[lo])


def main():
    price, sh, keep = annual_oil_price(), import_shares(), importer_sample()
    sample = sorted(set(sh) & keep)

    rows = []
    for c in sample:
        ys = sorted(y for y in sh[c] if y in price)
        if len(ys) < 5:                      # too short to carry a slope
            continue
        x = [math.log(price[y]) for y in ys]
        y_ = [math.log(sh[c][y]) for y in ys]
        b, se, n, r2 = ols1(x, y_)
        dep = sum(sh[c][y] for y in ys)/len(ys)     # mean oil import share, %
        rows.append(dict(country=c, b=b, se=se, n=n, r2=r2,
                         sigma=1-b, se_sigma=se, dep=dep))

    rows.sort(key=lambda r: r['sigma'])

    print(f'countries with at least 5 usable years: {len(rows)} of {len(sample)}')
    print()
    print(f'  {"country":<22}{"years":>6}{"coef":>9}{"se":>8}{"sigma":>9}'
          f'{"oil/GDP %":>11}')
    for r in rows:
        print(f'  {r["country"]:<22}{r["n"]:6d}{r["b"]:+9.3f}{r["se"]:8.3f}'
              f'{r["sigma"]:9.3f}{r["dep"]:11.2f}')

    sig = [r['sigma'] for r in rows]
    se2 = [r['se']**2 for r in rows]
    n = len(sig)
    mean = sum(sig)/n
    var_hat = sum((s-mean)**2 for s in sig)/(n-1)
    noise = sum(se2)/n
    signal = var_hat - noise                 # var(true) = var(estimated) - E[se^2]

    print()
    print('DISTRIBUTION OF THE IMPLIED SIGMA')
    print(f'  mean {mean:.3f}   median {quantile(sig,0.50):.3f}   '
          f'sd {math.sqrt(var_hat):.3f}')
    print(f'  p10 {quantile(sig,0.10):.3f}   p25 {quantile(sig,0.25):.3f}   '
          f'p75 {quantile(sig,0.75):.3f}   p90 {quantile(sig,0.90):.3f}')
    print(f'  min {min(sig):.3f} ({rows[0]["country"]})   '
          f'max {max(sig):.3f} ({rows[-1]["country"]})')
    print()
    print('HOW MUCH OF THAT SPREAD IS REAL')
    print(f'  var of the estimates          {var_hat:.4f}')
    print(f'  average sampling variance     {noise:.4f}')
    print(f'  implied variance of true sigma {signal:+.4f}'
          f'   -> sd {math.sqrt(signal):.3f}' if signal > 0 else
          f'  implied variance of true sigma {signal:+.4f}'
          '   -> indistinguishable from a common sigma')
    print()
    print('WHERE THE COUNTRIES SIT RELATIVE TO THE MODEL')
    below1 = sum(1 for s in sig if s < 1)
    inrange = sum(1 for s in sig if SWEEP_LO <= s <= SWEEP_HI)
    below_lo = sum(1 for s in sig if s < SWEEP_LO)
    above_hi = sum(1 for s in sig if s > SWEEP_HI)
    print(f'  complements, sigma < 1                     {below1:3d} of {n}')
    print(f'  inside the solved range [{SWEEP_LO:.2f}, {SWEEP_HI:.2f}]        '
          f'{inrange:3d} of {n}')
    print(f'  below it (even less substitutable)         {below_lo:3d} of {n}')
    print(f'  above it                                   {above_hi:3d} of {n}')
    print(f'  within one own-se of the adopted {ADOPTED:.2f}         '
          f'{sum(1 for r in rows if abs(r["sigma"]-ADOPTED) <= r["se"]):3d} of {n}')

    # does the elasticity line up with dependence? that is the dimension on
    # which a common sigma would misprice the countries the paper is about
    dep = [r['dep'] for r in rows]
    bd, sed, _, r2d = ols1([math.log(d) for d in dep], sig)
    print()
    print('IS THE ELASTICITY RELATED TO OIL DEPENDENCE')
    print(f'  sigma on ln(mean oil import share): {bd:+.3f} (se {sed:.3f}), '
          f'R2 {r2d:.3f}')
    heavy = [r for r in rows if r['dep'] >= quantile(dep, 0.667)]
    light = [r for r in rows if r['dep'] <= quantile(dep, 0.333)]
    print(f'  most dependent third  (n {len(heavy):2d}): mean sigma '
          f'{sum(r["sigma"] for r in heavy)/len(heavy):.3f}')
    print(f'  least dependent third (n {len(light):2d}): mean sigma '
          f'{sum(r["sigma"] for r in light)/len(light):.3f}')

    out = os.path.join(HERE, 'analysis', 'elasticity_by_country.csv')
    with open(out, 'w', newline='') as f:
        f.write('country,years,coef,se,sigma,mean_oil_import_share_pct,r2\n')
        for r in rows:
            f.write(f'{r["country"]},{r["n"]},{r["b"]:.6f},{r["se"]:.6f},'
                    f'{r["sigma"]:.6f},{r["dep"]:.6f},{r["r2"]:.6f}\n')
    print()
    print(f'written: {out}')


if __name__ == '__main__':
    main()
