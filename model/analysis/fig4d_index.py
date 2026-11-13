"""Data for a readable Figure 4d: expected oil price against volatility.

The published panel plots three price levels on one axis. Because the levels
differ by a factor of twelve, the axis has to span roughly 0.5 to 2.5 and the
genuine effect -- about 1.9% -- is around 1% of the panel height, so the lines
read as horizontal.

That 1.9% is the whole effect, and it is correct. The steep slopes in the
submitted version came from hardcoded price NODES on per-volatility-state
grids, where node 7 meant p = 2.48 in the calmest state and p = 14.25 in the
most volatile; most of that rise was the conditioning price moving, not
volatility. On the common grid a node is the same price in every state.

This writes both the levels and the same series indexed to the calmest state,
alongside the closed-form log-normal prediction exp((v_k - v_1)/2), which the
indexed series should sit on: for a log-normal the lift multiplies expected
price, so it is the SAME percentage at every current price.

Usage:
    python3 fig4d_index.py RUNDIR [OUT.csv]

Pure stdlib. The joint transition is (p_num*p_vol_num)^2, one element per
line, row-major, state = vol_block*p_num + price_index.
"""
import sys, csv, math

QUANTILES = [0.10, 0.50, 0.90]          # low / mean / high price, ergodic


def load(run):
    g = [float(l.split()[0]) for l in open(f'{run}/graphs_p_grid_dss.txt')]
    T = [float(l.split()[0]) for l in open(f'{run}/graphs_trans_matrix_joint.txt')]
    h = [float(l.split()[0]) for l in open(f'{run}/graphs_p_vol_grid_dss.txt')]
    pdf = [float(l.split()[0]) for l in open(f'{run}/graphs_pdf_p.txt')]
    n = len(g)
    if len(T) != n * n:
        raise ValueError(f'{run}: joint transition is {len(T)}, expected {n*n}')
    return g, T, h, pdf, n


def ergodic_nodes(pdf, pn, nvol):
    """Marginal price distribution, summed over volatility blocks."""
    marg = [sum(pdf[v * pn + i] for v in range(nvol)) for i in range(pn)]
    tot = sum(marg)
    marg = [x / tot for x in marg]
    out, c, k = [], 0.0, 0
    cum = []
    for x in marg:
        c += x
        cum.append(c)
    for q in QUANTILES:
        out.append(next(i for i, c in enumerate(cum) if c >= q))
    return out


def expected_next(g, T, n, i):
    price = [math.exp(x) for x in g]
    base = i * n
    return sum(T[base + j] * price[j] for j in range(n))


def main():
    if len(sys.argv) < 2:
        sys.exit(__doc__)
    run = sys.argv[1]
    out_csv = sys.argv[2] if len(sys.argv) > 2 else None

    g, T, h, pdf, n = load(run)
    nvol = len(h)
    pn = n // nvol
    nodes = ergodic_nodes(pdf, pn, nvol)
    labels = ['low', 'mean', 'high']

    sd = [math.exp(x / 2) for x in h]                 # conditional sd of log p
    var = [math.exp(x) for x in h]                    # conditional variance
    closed = [math.exp((v - var[0]) / 2) for v in var]

    print(f'{run}:  p_num={pn}  p_vol_num={nvol}')
    print(f'price nodes (ergodic p10/p50/p90): ' +
          ' '.join(f'{math.exp(g[(nvol//2)*pn + k]):.4f}' for k in nodes))
    print()
    print(f'{"":>6}{"cond sd":>10}' + ''.join(f'{l+" E[p1]":>13}' for l in labels)
          + ''.join(f'{l+" index":>13}' for l in labels) + f'{"closed form":>14}')

    rows = []
    series = {}
    for li, k in enumerate(nodes):
        series[labels[li]] = [expected_next(g, T, n, v * pn + k) for v in range(nvol)]

    for v in range(nvol):
        lv = [series[l][v] for l in labels]
        ix = [100 * series[l][v] / series[l][0] for l in labels]
        print(f'{"vol"+str(v+1):>6}{sd[v]:>10.4f}'
              + ''.join(f'{x:>13.5f}' for x in lv)
              + ''.join(f'{x:>13.4f}' for x in ix)
              + f'{100*closed[v]:>14.4f}')
        rows.append([v + 1, f'{sd[v]:.8f}']
                    + [f'{x:.8f}' for x in lv]
                    + [f'{x:.6f}' for x in ix]
                    + [f'{100*closed[v]:.6f}'])

    print()
    for l in labels:
        s = series[l]
        print(f'  {l:>5} price: swing {100*(s[-1]-s[0])/s[0]:+.4f}%')
    print(f'  closed form : swing {100*(closed[-1]-1):+.4f}%')

    if out_csv:
        with open(out_csv, 'w', newline='') as fh:
            wr = csv.writer(fh)
            wr.writerow(['vol_state', 'cond_sd_log_p']
                        + [f'E_p_next_{l}' for l in labels]
                        + [f'index_{l}' for l in labels]
                        + ['closed_form_index'])
            wr.writerows(rows)
        print(f'\nwritten to {out_csv}')


if __name__ == '__main__':
    main()
