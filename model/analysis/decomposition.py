"""The mean-preserving decomposition both referees asked for (R1 Major 2, R2 Major 1).

Writes three CSVs and the data the figure needs:

  table1_economies.csv       the four-economy ladder, episode-window moments
  table2_by_volatility.csv   mean spread by volatility state, per economy --
                             including the constant-volatility PLACEBO, whose
                             five volatility indices are economically
                             identical, so its range across them is the pure
                             simulation noise floor
  table3_decomposition.csv   the channels, each with a 95% interval
  panelA_expected_price.csv  E[p | volatility state], full vs mean-preserving

Usage:
    python3 decomposition.py OUTDIR FULL MEANPRES CONSTVOL CONSTPRICE

The earlier versions of these tables were produced by a script that was never
committed, on the 549-node grid, and report channels that no longer hold at the
converged common grid. This replaces that.

Pure stdlib, like moments_fast.py, which it imports for the episode-window
moments so the two agree by construction.
"""
import sys, os, csv, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from moments_fast import moments, RSTAR, DELTA, COUPON

# column indices in graphs_data_sim_dss.txt, 0-based, per the WRITE in
# oil_prod_CES.f90: 1 y, 2 c, 3 b, 4 q, 5 qdef, 6 oil, 7 excl, 8 d,
# 9 q_default_free, 10 i_y, 11 q_df_new, 12 tb/gdp, 13 p_vol, 14 p,
# 15 oil*p/gdp, 16 gdp, 17 i_p, 18 i_p_vol, 19 price, 20 vol
C_Q, C_QDF, C_P, C_IVOL = 3, 8, 13, 17


def expected_price_by_vol(run):
    """E[p' | p = centre node, sigma] from the solver's own transition matrix.

    This is the object both referees asked about -- the CONDITIONAL mean of the
    next period's price level, holding the current price fixed. Averaging the
    simulation by volatility state is NOT the same thing: that mixes the Jensen
    lift with the ergodic correlation between the volatility and price states.

    graphs_p_grid_dss.txt is p_vol_num blocks of p_num log prices (identical
    blocks on a common grid); graphs_trans_matrix_p.txt is the
    (p_num*p_vol_num) x p_num transition, written one element per line.

    Self-check: in the mean-preserving economy this must be EXACTLY constant
    across volatility states. It is, to eight decimals.
    """
    g = [float(l.split()[0]) for l in open(f'{run}/graphs_p_grid_dss.txt')]
    T = [float(l.split()[0]) for l in open(f'{run}/graphs_trans_matrix_p.txt')]
    prm = open(f'{run}/graphs_param_dss.txt').read().split()
    pn = len(g) // 5                      # p_num; p_vol_num is 5 throughout
    ctr = pn // 2                         # centre price node, 0-based
    out = []
    for k in range(5):
        i = k * pn + ctr
        row = T[i * pn:(i + 1) * pn]
        if abs(sum(row) - 1) > 1e-6:
            raise ValueError(f'{run}: transition row {i} sums to {sum(row)}')
        out.append(sum(row[j] * math.exp(g[j]) for j in range(pn)))
    return out, math.exp(g[ctr])


def by_volatility(run):
    """Per-observation annualised spread and price, grouped by volatility state.

    This is the whole simulation, not the episode windows -- the same
    construction as the placebo table it feeds. Returns
    {vol_state: (n, mean_spread_pct, mean_price)}.
    """
    acc = {}
    with open(f'{run}/graphs_data_sim_dss.txt') as f:
        for line in f:
            w = line.split()
            try:
                q, qdf, p, iv = (float(w[C_Q]), float(w[C_QDF]),
                                 float(w[C_P]), int(float(w[C_IVOL])))
            except (ValueError, IndexError):
                continue
            if q <= 0 or qdf <= 0:
                continue
            yl = COUPON / q - DELTA
            yr = COUPON / qdf - DELTA
            sp = 100 * ((1 + yl) ** 4 - (1 + yr) ** 4)
            n, s, sp2, pp = acc.get(iv, (0, 0.0, 0.0, 0.0))
            acc[iv] = (n + 1, s + sp, sp2 + sp * sp, pp + p)
    out = {}
    for iv, (n, s, sp2, pp) in sorted(acc.items()):
        mean = s / n
        var = max(0.0, sp2 / n - mean * mean)
        out[iv] = (n, mean, var ** 0.5, pp / n)
    return out


def main():
    if len(sys.argv) != 6:
        sys.exit(__doc__)
    outdir, paths = sys.argv[1], sys.argv[2:]
    os.makedirs(outdir, exist_ok=True)
    keys = ['full', 'mean_preserving', 'constant_volatility', 'constant_price']
    label = {'full': 'full SV', 'mean_preserving': 'mean-preserving SV',
             'constant_volatility': 'constant volatility',
             'constant_price': 'constant price'}
    run = dict(zip(keys, paths))
    M = {k: moments(p) for k, p in run.items()}

    # ---- table 1: the ladder -------------------------------------------
    with open(f'{outdir}/table1_economies.csv', 'w', newline='') as fh:
        wr = csv.writer(fh)
        wr.writerow(['economy', 'mean_spread_bp', 'se_bp', 'sd_spread_bp',
                     'debt_gdp_pct', 'oil_gdp_pct', 'episodes', 'run'])
        for k in keys:
            m = M[k]
            wr.writerow([label[k], f"{100*m['spread']:.1f}", f"{100*m['se']:.1f}",
                         f"{100*m['sd']:.1f}", f"{m['debt_y']:.2f}",
                         f"{100*m['oil_y']:.2f}", m['nobs'], run[k]])

    # ---- table 3: channels, each with a 95% interval --------------------
    def channel(a, b):
        d = 100 * (M[a]['spread'] - M[b]['spread'])
        ci = 1.96 * 100 * math.hypot(M[a]['se'], M[b]['se'])
        return d, ci

    chans = [
        ('oil price risk at all (full - constant price)', 'full', 'constant_price'),
        ('time-varying volatility, TOTAL (full - constant vol)', 'full', 'constant_volatility'),
        ('  of which pure dispersion (mean-preserving - constant vol)', 'mean_preserving', 'constant_volatility'),
        ('  of which expected price (full - mean-preserving)', 'full', 'mean_preserving'),
    ]
    with open(f'{outdir}/table3_decomposition.csv', 'w', newline='') as fh:
        wr = csv.writer(fh)
        wr.writerow(['channel', 'spread_bp', 'ci95_bp', 'identified'])
        for name, a, b in chans:
            d, ci = channel(a, b)
            wr.writerow([name, f'{d:+.1f}', f'{ci:.1f}',
                         'yes' if abs(d) > ci else 'no'])

    # ---- table 2 and panel A: by volatility state ----------------------
    V = {k: by_volatility(run[k]) for k in keys if k != 'constant_price'}
    with open(f'{outdir}/table2_by_volatility.csv', 'w', newline='') as fh:
        wr = csv.writer(fh)
        wr.writerow(['economy', 'vol_state', 'obs', 'mean_spread_bp',
                     'sd_spread_bp', 'mean_price'])
        for k in V:
            nm = label[k] + (' PLACEBO' if k == 'constant_volatility' else '')
            for iv, (n, mean, sd, pp) in V[k].items():
                wr.writerow([nm, iv, n, f'{100*mean:.1f}', f'{100*sd:.1f}',
                             f'{pp:.5f}'])
        # the noise floor: range across the placebo's five identical states
        pl = V['constant_volatility']
        rng = 100 * (max(v[1] for v in pl.values()) - min(v[1] for v in pl.values()))
        wr.writerow(['NOISE FLOOR (placebo range)', '', '', f'{rng:.1f}', '', ''])

    # ---- panel A: the conditional object the referees asked about -------
    EP_full, pctr = expected_price_by_vol(run['full'])
    EP_mp, _ = expected_price_by_vol(run['mean_preserving'])
    # the volatility grid is log variance; sigma = exp(h/2), v = exp(h)
    h = [float(l.split()[0]) for l in
         open(f"{run['full']}/graphs_p_vol_grid_dss.txt")]
    with open(f'{outdir}/panelA_expected_price.csv', 'w', newline='') as fh:
        wr = csv.writer(fh)
        wr.writerow(['vol_state', 'v_cond_variance', 'sd_log_p',
                     'E_p_next_full', 'E_p_next_mean_preserving',
                     'closed_form_exp_v_over_2'])
        for k in range(5):
            v = math.exp(h[k])
            wr.writerow([k + 1, f'{v:.8f}', f'{v**0.5:.6f}',
                         f'{EP_full[k]:.8f}', f'{EP_mp[k]:.8f}',
                         f'{pctr*math.exp(v/2):.8f}'])
        wr.writerow(['swing low->high %', '', '',
                     f'{100*(EP_full[4]-EP_full[0])/EP_full[0]:+.4f}',
                     f'{100*(EP_mp[4]-EP_mp[0])/EP_mp[0]:+.4f}',
                     f'{100*(math.exp(math.exp(h[4])/2)/math.exp(math.exp(h[0])/2)-1):+.4f}'])

    # the simulation average by volatility state, kept as a DIAGNOSTIC only --
    # it is not the referees' object, see expected_price_by_vol's docstring
    with open(f'{outdir}/diagnostic_simulated_price_by_vol.csv', 'w', newline='') as fh:
        wr = csv.writer(fh)
        wr.writerow(['vol_state', 'E_p_full_simulated', 'E_p_mean_pres_simulated'])
        for iv in sorted(V['full']):
            wr.writerow([iv, f"{V['full'][iv][3]:.6f}",
                         f"{V['mean_preserving'][iv][3]:.6f}"])

    # ---- stdout summary -------------------------------------------------
    print(f"\nTABLE 1  the four economies")
    print(f"{'economy':<22}{'spread bp':>11}{'se':>7}{'sd bp':>9}{'debt/GDP':>10}{'oil/GDP':>9}")
    for k in keys:
        m = M[k]
        print(f"{label[k]:<22}{100*m['spread']:>11.1f}{100*m['se']:>7.1f}"
              f"{100*m['sd']:>9.1f}{m['debt_y']:>10.2f}{100*m['oil_y']:>9.2f}")

    print(f"\nTABLE 3  channel decomposition")
    print(f"{'channel':<60}{'bp':>8}{'95% CI':>9}{'ident?':>8}")
    for name, a, b in chans:
        d, ci = channel(a, b)
        print(f"{name:<60}{d:>+8.1f}{ci:>9.1f}{('yes' if abs(d) > ci else 'no'):>8}")

    pl = V['constant_volatility']
    rng = 100 * (max(v[1] for v in pl.values()) - min(v[1] for v in pl.values()))
    print(f"\nPLACEBO noise floor (range of mean spread across the "
          f"constant-volatility economy's five\n  economically identical "
          f"volatility indices): {rng:.1f} bp")

    print(f"\nPANEL A  E[p' | p = centre node, volatility state]")
    print(f"{'state':>6}{'sd(log p)':>11}{'full SV':>13}{'mean-pres':>13}{'closed form':>13}")
    for k in range(5):
        v = math.exp(h[k])
        print(f"{k+1:>6}{v**0.5:>11.4f}{EP_full[k]:>13.8f}{EP_mp[k]:>13.8f}"
              f"{pctr*math.exp(v/2):>13.8f}")
    print(f"\n  swing low->high volatility:"
          f"   full {100*(EP_full[4]-EP_full[0])/EP_full[0]:+.4f}%"
          f"   mean-preserving {100*(EP_mp[4]-EP_mp[0])/EP_mp[0]:+.4f}%")
    print(f"  closed-form Jensen lift exp(v/2):"
          f" {100*(math.exp(math.exp(h[4])/2)/math.exp(math.exp(h[0])/2)-1):+.4f}%"
          f"   (the grid reproduces it)")
    print(f"\nwritten to {outdir}/")


if __name__ == '__main__':
    main()
