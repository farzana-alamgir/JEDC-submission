"""Simulated moments from a run directory's graphs_data_sim_dss.txt.

Replicates the spread definition of sim_prod_oil_dec29.m:
    coupon            = (rstar+delta)/(1+rstar)
    yield             = coupon/q - delta
    annual spread     = (1+yield)^4 - (1+yield_rf)^4
averaged over periods in good standing, after the same 500-period burn-in
(per_num 1500, num = max(1000,n) = 1000).

Columns (1-indexed, from the WRITE(23,...) in oil_prod_CES.f90):
    4 q   7 exclusion   8 default+1   9 q_def_free   14 p   15 oil bill/gdp
"""
import sys, math

RSTAR, DELTA = 0.01, 0.03
COUPON = (RSTAR + DELTA) / (1 + RSTAR)
PER, BURN = 1500, 500


def moments(run):
    sp, oy, pr, ndef, ngood, ntot = [], [], [], 0, 0, 0
    with open(f'{run}/graphs_data_sim_dss.txt') as f:
        for i, line in enumerate(f):
            if (i % PER) < BURN:
                continue
            w = line.split()
            ntot += 1
            try:
                q, excl, d = float(w[3]), float(w[6]), float(w[7]) - 1
                qdf, p, oilshare = float(w[8]), float(w[13]), float(w[14])
            except ValueError:
                continue                      # NaN-patched infeasible row
            if d != 0:
                ndef += 1
            if excl > 1 or d != 0 or q <= 0 or qdf <= 0:
                continue
            yl = COUPON / q - DELTA
            yr = COUPON / qdf - DELTA
            sp.append(100 * ((1 + yl) ** 4 - (1 + yr) ** 4))
            if oilshare == oilshare:
                oy.append(oilshare)
            pr.append(p)
            ngood += 1

    def ms(x):
        if not x:
            return float('nan'), float('nan')
        m = sum(x) / len(x)
        v = sum((t - m) ** 2 for t in x) / max(1, len(x) - 1)
        return m, v ** 0.5

    msp, ssp = ms(sp)
    moy, _ = ms(oy)
    mp, _ = ms(pr)
    return dict(spread=msp, sd=ssp, oil_y=moy, mean_p=mp,
                defrate=ndef / max(1, ntot), ngood=ngood)


if __name__ == '__main__':
    for run in sys.argv[1:]:
        m = moments(run)
        print(f"{run:<34} spread {m['spread']:7.4f}  sd {m['sd']:6.4f}  "
              f"oil/y {m['oil_y']:7.4f}  E[p] {m['mean_p']:6.4f}  "
              f"def {m['defrate']:.4f}  n {m['ngood']}")
