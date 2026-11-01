"""How far does the one-step mean-preserving correction hold at longer horizons?

The correction subtracts half the deviation of the conditional variance from its
average, so E[p_{t+1} | p, sigma] is flat across volatility states by
construction. With rho_p < 1 that is exact only at one step: conditional
variance accumulates at rho^2 while the drift correction accumulates at rho, so
exact cancellation at every horizon would need rho_p = 1.

This matters because delta = 0.03 implies a bond duration near 25 quarters, so
it is long horizons that price the bond. This script quantifies the residual by
iterating the solver's own joint (price, volatility) transition forward from the
central price node in each volatility state.

Usage:
    python3 horizon_check.py FULL_RUN MEANPRES_RUN [OUT.csv]

Pure stdlib. The joint transition is 1385 x 1385 written one element per line,
row-major, where state = vol_block*277 + price_index.
"""
import sys, csv, math

HORIZONS = [1, 2, 4, 8, 12, 20, 30, 40]


def load(run):
    g = [float(l.split()[0]) for l in open(f'{run}/graphs_p_grid_dss.txt')]
    T = [float(l.split()[0]) for l in open(f'{run}/graphs_trans_matrix_joint.txt')]
    n = len(g)
    if len(T) != n * n:
        raise ValueError(f'{run}: joint transition is {len(T)}, expected {n*n}')
    return g, T, n


def expected_path(g, T, n, start):
    """E[p_{t+h}] for h in HORIZONS, starting from a point mass at `start`."""
    price = [math.exp(x) for x in g]
    d = [0.0] * n
    d[start] = 1.0
    out = {}
    for h in range(1, max(HORIZONS) + 1):
        new = [0.0] * n
        for i in range(n):
            di = d[i]
            if di > 1e-16:
                base = i * n
                for j in range(n):
                    t = T[base + j]
                    if t:
                        new[j] += di * t
        d = new
        if h in HORIZONS:
            out[h] = sum(d[j] * price[j] for j in range(n))
    return out


def main():
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    runs = {'full': sys.argv[1], 'mean_preserving': sys.argv[2]}
    out_csv = sys.argv[3] if len(sys.argv) > 3 else None

    res = {}
    for lab, run in runs.items():
        g, T, n = load(run)
        pn = n // 5
        ctr = pn // 2
        res[lab] = {}
        for k in range(5):
            res[lab][k] = expected_path(g, T, n, k * pn + ctr)
        print(f'{lab}: done ({run})', flush=True)

    print(f"\nE[p_(t+h) | p = centre node, sigma], by starting volatility state\n")
    print(f"{'horizon':>8}" + ''.join(f"{'vol '+str(k+1):>12}" for k in range(5))
          + f"{'swing %':>11}")
    rows = []
    for lab in ('full', 'mean_preserving'):
        print(f"\n  {lab}")
        for h in HORIZONS:
            v = [res[lab][k][h] for k in range(5)]
            swing = 100 * (v[4] - v[0]) / v[0]
            print(f"{h:>8}" + ''.join(f"{x:>12.6f}" for x in v) + f"{swing:>+11.4f}")
            rows.append([lab, h] + [f'{x:.8f}' for x in v] + [f'{swing:+.4f}'])

    print(f"\n{'horizon':>8}{'full swing %':>15}{'mean-pres residual %':>23}"
          f"{'residual / full':>18}")
    for h in HORIZONS:
        f = [res['full'][k][h] for k in range(5)]
        m = [res['mean_preserving'][k][h] for k in range(5)]
        fs = 100 * (f[4] - f[0]) / f[0]
        ms = 100 * (m[4] - m[0]) / m[0]
        ratio = ms / fs if fs else float('nan')
        print(f"{h:>8}{fs:>+15.4f}{ms:>+23.4f}{ratio:>+18.3f}")

    if out_csv:
        with open(out_csv, 'w', newline='') as fh:
            wr = csv.writer(fh)
            wr.writerow(['economy', 'horizon_quarters'] +
                        [f'E_p_vol{k+1}' for k in range(5)] + ['swing_pct'])
            wr.writerows(rows)
        print(f"\nwritten to {out_csv}")


if __name__ == '__main__':
    main()
