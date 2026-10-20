"""Sweep the CES substitution elasticity against the validated oil-price grid.

Answers one question: for which elasticities can the sovereign model actually be
solved on the candidate price process, and what does each imply for the oil
import share and for repayment capacity?

Never runs the submitted solver. Requires numpy; reuses the validated kernel from
validate.py so the price support is the real one, not an assumption.

Background
----------
With x = [(1-a)A^t + a m^t]^(1/t) and oil bought at price p, writing
sigma = 1/(1-t) for the elasticity of substitution, the optimal-oil-demand
conditions give a closed form for the oil import share:

    s(p) = a^sigma * p^(1-sigma)                              (sigma != 1)
    s(p) = a                                                  (sigma == 1, Cobb-Douglas)

so a is pinned by a target share at a reference price:

    a = ( s* * p_ref^(sigma-1) )^(1/sigma)

The interior optimum exists iff s(p) < 1 -- the intermediate algebra is
1 - a*k^t > 0 with k = m/x, and that expression equals 1 - s(p) exactly. Since
s is monotone in p, that single condition becomes

    sigma > 1 :  p > a^( sigma/(sigma-1))   lower floor; below it oil demand
                                            is unbounded and the model's
                                            bisection cannot converge
    sigma < 1 :  p < a^(-sigma/(1-sigma))   upper ceiling; above it the oil
                                            bill exceeds output
    sigma = 1 :  feasible for every p

The submitted calibration (sigma = 2, a = 0.3) has a floor of 0.09, which the
candidate price grid violates at its low end.
"""
from pathlib import Path
import csv
import json

import numpy as np

from validate import CENTER, Z_SD, kernel, stationary

ROOT = Path(__file__).resolve().parent

# Endowment scale and the oil import share target. ENDOWMENT matches scale_y in
# the Fortran. SHARE_TARGET is the share implied by the SUBMITTED calibration,
# used here so the sweep holds the benchmark's own behaviour fixed; it is NOT a
# measured target. The measured counterpart is 3.74% -- see
# empirical/estimate_substitution_elasticity.py, which also estimates sigma.
ENDOWMENT = 10.0
SHARE_TARGET = 0.0799
# Measured alternative: 0.0374, the mean oil import share of the paper's own
# 34-country importer sample (empirical/estimate_substitution_elasticity.py).
# The default above is kept so the sweep holds the SUBMITTED model's behaviour
# fixed and the comparison stays like-for-like; set SHARE_TARGET = 0.0374 to
# recalibrate alpha to the data instead.

SIGMAS = (0.2, 0.3, 0.4, 0.5, 0.6, 0.75, 0.9, 1.0, 1.25, 1.5, 1.75, 2.0)


def alpha_for(sigma, share_target, p_ref):
    """Share parameter that delivers `share_target` at `p_ref`."""
    if np.isclose(sigma, 1.0):
        return share_target
    return (share_target * p_ref**(sigma-1))**(1/sigma)


def share(sigma, alpha, p):
    """Oil import share p*m/x at price p under the optimal oil choice."""
    if np.isclose(sigma, 1.0):
        return np.full_like(np.asarray(p, dtype=float), alpha)
    return alpha**sigma * np.asarray(p, dtype=float)**(1-sigma)


def feasible_band(sigma, alpha):
    """Open interval of prices admitting an interior optimum (share < 1)."""
    if np.isclose(sigma, 1.0):
        return (0.0, np.inf) if alpha < 1 else (np.inf, np.inf)
    bound = alpha**(-sigma/(1-sigma))
    return (bound, np.inf) if sigma > 1 else (0.0, bound)


def allocation(sigma, alpha, p, endowment=ENDOWMENT):
    """Output, oil bill and net resources x - p*m. NaN where infeasible."""
    p = np.asarray(p, dtype=float)
    s = share(sigma, alpha, p)
    feasible = s < 1
    if np.isclose(sigma, 1.0):
        x = np.where(feasible, endowment * (alpha/p)**(alpha/(1-alpha)), np.nan)
    else:
        theta = 1 - 1/sigma
        with np.errstate(invalid='ignore', divide='ignore'):
            x = np.where(feasible,
                         endowment * ((1-alpha)/np.where(feasible, 1-s, np.nan))**(1/theta),
                         np.nan)
    return x, x*s, x*(1-s)


def max_price_half_width_sd(sigma, alpha):
    """Widest price grid, in SDs of log price, that keeps every node feasible.

    The grid is CENTER +/- w*Z_SD in logs, so the binding bound converts directly
    into a width. This is the number that decides whether an elasticity is usable:
    an elasticity whose floor sits inside the grid can be rescued by narrowing the
    grid instead of being discarded.
    """
    lo, hi = feasible_band(sigma, alpha)
    if np.isclose(sigma, 1.0):
        return float('inf')
    bound = lo if sigma > 1 else hi
    if bound <= 0:
        return float('inf')
    return float(abs(np.log(bound)-CENTER)/Z_SD)


def sweep(price_grid, ergodic_price_weights, share_target=SHARE_TARGET):
    p_ref = float(ergodic_price_weights @ price_grid)       # mean price level E[p]
    p_lo, p_hi = float(price_grid.min()), float(price_grid.max())
    rows = []
    for sigma in SIGMAS:
        alpha = alpha_for(sigma, share_target, p_ref)
        lo, hi = feasible_band(sigma, alpha)
        s_grid = share(sigma, alpha, price_grid)
        infeasible = s_grid >= 1
        x, bill, net = allocation(sigma, alpha, price_grid)
        # Response to doubling the price from the reference point.
        x1, _, n1 = allocation(sigma, alpha, np.array([p_ref]))
        x2, _, n2 = allocation(sigma, alpha, np.array([2*p_ref]))
        good = ~infeasible
        rows.append(dict(
            sigma=sigma,
            theta=0.0 if np.isclose(sigma, 1.0) else 1-1/sigma,
            alpha=float(alpha),
            band_low=float(lo), band_high=float(hi),
            grid_covered=bool(p_lo > lo and p_hi < hi),
            max_price_half_width_sd=max_price_half_width_sd(sigma, alpha),
            share_at_grid_min=float(s_grid[price_grid.argmin()]),
            share_at_grid_max=float(s_grid[price_grid.argmax()]),
            ergodic_mean_share=float(ergodic_price_weights[good] @ s_grid[good]
                                     / ergodic_price_weights[good].sum()),
            infeasible_nodes=int(infeasible.sum()),
            infeasible_ergodic_mass=float(ergodic_price_weights[infeasible].sum()),
            output_pct_change_on_doubling=float(100*(x2[0]/x1[0]-1)),
            net_resources_pct_change_on_doubling=float(100*(n2[0]/n1[0]-1)),
            share_price_elasticity=float(0.0 if np.isclose(sigma, 1.0) else 1-sigma),
        ))
    return p_ref, p_lo, p_hi, rows


def main():
    # Reuse the validated kernel so the price support is the real one.
    z, h, s, p = kernel(201, 21)
    d, _ = stationary(s, p)
    price_grid = np.exp(z)
    weights = d.sum(0)                       # ergodic distribution over price nodes
    assert abs(weights.sum()-1) < 1e-10

    p_ref, p_lo, p_hi, rows = sweep(price_grid, weights)

    # The formula must reproduce the submitted calibration.
    submitted = alpha_for(2.0, SHARE_TARGET, p_ref)
    assert abs(submitted-0.3) < 0.02, submitted
    # ...and the submitted elasticity must be the one that fails at the low end.
    assert not next(r for r in rows if r['sigma'] == 2.0)['grid_covered']
    # Cobb-Douglas is always feasible and has a constant share.
    cd = next(r for r in rows if r['sigma'] == 1.0)
    assert cd['grid_covered'] and abs(cd['ergodic_mean_share']-SHARE_TARGET) < 1e-12
    # Feasibility must be an interval in sigma, not scattered.
    covered = [r['sigma'] for r in rows if r['grid_covered']]
    assert covered == sorted(covered) and len(covered) == \
        (SIGMAS.index(covered[-1])-SIGMAS.index(covered[0])+1)

    results = dict(
        endowment=ENDOWMENT,
        share_target=SHARE_TARGET,
        share_target_is_measured=False,
        reference_price=p_ref,
        grid_price_min=p_lo, grid_price_max=p_hi,
        submitted_alpha_check=float(submitted),
        feasible_sigmas=covered,
        sweep=rows,
        checks_passed=True,
    )
    (ROOT/'elasticity_sweep.json').write_text(json.dumps(results, indent=2)+'\n')
    with (ROOT/'elasticity_sweep.csv').open('w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=list(rows[0]))
        writer.writeheader(); writer.writerows(rows)

    print(f'reference price E[p] = {p_ref:.4f}   grid prices [{p_lo:.4f}, {p_hi:.3f}]')
    print(f'oil share target     = {SHARE_TARGET:.4f}  (NOT measured -- see module docstring)')
    print()
    hdr = ('sigma', 'theta', 'alpha', 'feasible band', 'grid', 'maxW', 's(pmin)',
           's(pmax)', 'E[s]', 'bad mass', 'd%out', 'd%net')
    print('{:>5} {:>7} {:>9}  {:<20} {:>5} {:>6} {:>8} {:>8} {:>7} {:>9} {:>7} {:>7}'.format(*hdr))
    for r in rows:
        band = (f"({r['band_low']:.4g}, inf)" if r['sigma'] > 1
                else '(0, inf)' if r['sigma'] == 1 else f"(0, {r['band_high']:.4g})")
        w = r['max_price_half_width_sd']
        print('{sigma:5.2f} {theta:+7.3f} {alpha:9.5f}  {band:<20} {ok:>5} {w:>6} '
              '{smin:8.3f} {smax:8.3f} {es:7.4f} {bad:9.2e} {dx:+7.2f} {dn:+7.2f}'.format(
                  sigma=r['sigma'], theta=r['theta'], alpha=r['alpha'], band=band,
                  ok='yes' if r['grid_covered'] else 'NO',
                  w='inf' if w == float('inf') else f'{w:.2f}',
                  smin=r['share_at_grid_min'], smax=r['share_at_grid_max'],
                  es=r['ergodic_mean_share'], bad=r['infeasible_ergodic_mass'],
                  dx=r['output_pct_change_on_doubling'],
                  dn=r['net_resources_pct_change_on_doubling']))
    print()
    print(f'feasible at the validated +/-6 sd width: sigma in {covered}')
    print('maxW = widest price grid (in SDs of log price) keeping every node feasible.')
    print('  An elasticity with maxW below 6 is NOT ruled out: narrowing the grid to')
    print('  within maxW rescues it. validate.py already checks +/-4 sd, where')
    print('  sd_log_price moves 0.27% -- inside its own 1% tolerance.')
    print('d%out / d%net = change in output / in net resources (x - p*m) when p doubles.')
    print('share price elasticity dln s/dln p = 1 - sigma, directly estimable from the')
    print("import_gdp sheet: a POSITIVE coefficient refutes sigma = 2, which implies -1.")


if __name__ == '__main__':
    main()
