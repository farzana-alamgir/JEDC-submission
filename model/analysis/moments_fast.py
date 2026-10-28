"""Table 3 moments, replicating sim_prod_oil_dec29.m exactly, in pure Python.

The MATLAB script does NOT report unconditional means. It reports averages over
the `per_before = 100` quarters *preceding* each qualifying default episode
(per_after = -1, so the default quarter itself is excluded). Episodes qualify
only if they are separated by more than sample_size+1 = 101 periods and the
country was not in exclusion 101 quarters earlier. Using an unconditional mean
instead shifts the spread by ~0.3pp, which is enough to miss a calibration
target, so a search must use this convention.

Validated against sim_prod_oil_dec29.m on both the sigma=2 and sigma=0.3
benchmarks.
"""
import sys

RSTAR, DELTA = 0.01, 0.03
COUPON = (RSTAR + DELTA) / (1 + RSTAR)
PER_BEFORE, PER_AFTER = 100, -1
SAMPLE_SIZE = PER_BEFORE + PER_AFTER + 1          # 100


def moments(run):
    with open(f'{run}/graphs_param_dss.txt') as f:
        per_num = int(float(f.readline()))
        n = int(float(f.readline()))
    num = max(1000, n)
    off = per_num - num                            # trim to the last `num`

    q = []; qdf = []; b = []; out = []; oil = []; oily = []; d = []; e = []
    with open(f'{run}/graphs_data_sim_dss.txt') as f:
        for line in f:
            w = line.split()
            def fl(j):
                try:
                    return float(w[j])
                except (ValueError, IndexError):
                    return float('nan')
            q.append(fl(3)); e.append(fl(6)); d.append(fl(7) - 1)
            qdf.append(fl(8)); oil.append(fl(5)); b.append(fl(2))
            oily.append(fl(14)); out.append(fl(15))

    sp = []
    for i in range(len(q)):
        if q[i] > 0 and qdf[i] > 0:
            yl = COUPON / q[i] - DELTA
            yr = COUPON / qdf[i] - DELTA
            sp.append((1 + yl) ** 4 - (1 + yr) ** 4)
        else:
            sp.append(float('nan'))
    bty = [0.25 * b[i] / (out[i] - oil[i]) if (out[i] - oil[i]) else float('nan')
           for i in range(len(b))]

    msp, ssp, mb, mo = [], [], [], []
    for i in range(n):
        base = i * per_num
        # default periods in the FULL sample, 1-based, then trimmed to the last `num`
        dl = [t + 1 - off for t in range(per_num)
              if d[base + t] == 1 and (t + 1) > off]
        if not dl:
            continue
        inter = [dl[0]] + [dl[k] - dl[k - 1] for k in range(1, len(dl))]
        for k, dp in enumerate(dl):
            if inter[k] <= SAMPLE_SIZE + 1:
                continue
            ei = min(max(dp - PER_BEFORE - 1, 1), num)
            if not (e[base + off + ei - 1] < 2):
                continue
            lo, hi = dp - PER_BEFORE, dp + PER_AFTER      # inclusive, 1-based
            idx = [base + off + t - 1 for t in range(lo, hi + 1)]
            win = [sp[j] for j in idx if sp[j] == sp[j]]
            if not win:
                continue
            m = sum(win) / len(win)
            v = sum((x - m) ** 2 for x in win) / max(1, len(win) - 1)
            msp.append(m); ssp.append(v ** 0.5)
            wb = [bty[j] for j in idx if bty[j] == bty[j]]
            wo = [oily[j] for j in idx if oily[j] == oily[j]]
            if wb: mb.append(sum(wb) / len(wb))
            if wo: mo.append(sum(wo) / len(wo))

    av = lambda x: sum(x) / len(x) if x else float('nan')
    # Standard error of the reported mean spread, ACROSS default episodes.
    # Channels are differences of two such means, so a channel is only
    # distinguishable from zero at roughly 2*sqrt(2)*se.
    if len(msp) > 1:
        m = av(msp)
        se = (sum((x - m) ** 2 for x in msp) / (len(msp) - 1) / len(msp)) ** 0.5
    else:
        se = float('nan')
    return dict(spread=100 * av(msp), sd=100 * av(ssp),
                debt_y=100 * av(mb), oil_y=av(mo), nobs=len(msp),
                se=100 * se)


if __name__ == '__main__':
    for r in sys.argv[1:]:
        m = moments(r)
        print(f"{r:<28} spread {m['spread']:8.4f}  sd {m['sd']:7.4f}  "
              f"debt/y {m['debt_y']:8.4f}  oil/y {m['oil_y']:7.4f}  n {m['nobs']}")
