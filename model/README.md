# Model code

## `oil_prod_CES.f90`

The solver. Single source for every economy — the variants are compile-time
switches, not separate forks, so they cannot drift apart.

### Switches

| parameter | default | what it does |
|---|---|---|
| `mean_preserving` | `.false.` | applies the drift `−0.5(v_t − v̄)` so `E[p′]` is flat across volatility states. The mean-preserving economy. |
| `constant_vol` | `.false.` | pins `h` at `mu_h + var_h/2`, the level matching the unconditional variance of the price innovation. The intermediate economy. |
| `oil_disruption` | `0d+0` | proportional premium on imported oil while in default or excluded (R2 major 3). |
| `kappa_risk` | `0d+0` | price of risk on the oil price innovation (R1 major 5). `0` reproduces risk-neutral pricing exactly. |
| `use_moment_matching` | `.false.` | tilts the Tauchen rows to match the conditional mean and variance exactly. **Not used in any reported result.** |
| `p_width_sd` | `3.5d+0` | half-width of the common price grid in unconditional sd of log p. |
| `use_common_p_grid` | `.false.` | `.false.` = the submitted construction: one Rouwenhorst grid **per volatility state**, usable at `p_num = 7`. `.true.` = one physical grid shared by all states, which needs `p_num` in the hundreds. See "Which grid" below. |

### Which grid

`discretize_AR` is **Rouwenhorst**, exact in mean, variance and autocorrelation
for any `n >= 2` — including at `rho_p = 0.98`, where Tauchen loses variance.
Seven nodes per state were never too few to represent each state's process.

| | per-state, `p_num=7` | common, `p_num=549` |
|---|---|---|
| solve time per economy | **26 s** | ~45 min |
| sd(Δlog p) simulated (data 14.47%) | **14.63%** | 12.61% |
| mean spread (target 4.1) | **4.21** | 4.02 |
| debt/GDP (target 34.0) | 42.7 | **33.5** |
| Figure 3 slope ratio | not identified | **1.03** |

Use the per-state grid for the price process and the moments; it cannot
identify the Figure 3 slope ratio (see `analysis/fig3_resolution_test.m`).
Full comparison in `results/SUMMARY_OPTION_A.md`.

**Two traps on the per-state path**, both fixed but worth knowing:

1. `constant_vol` used to sit inside the `use_common_p_grid` branch, so on the
   per-state path it silently did nothing and the intermediate economy solved
   with full stochastic volatility — identical to the benchmark on every
   moment. The override is now applied in both branches.
2. State 5's grid is built from that state's volatility treated as *permanent*
   (`sd_k/sqrt(1-rho_p^2)`), which stretches its lowest node to `p = 0.0892` —
   **below** the CES feasibility floor `alpha**(1/theta) = 0.09`. Output there
   is 7.7e10 against 29.2 everywhere else. The *solution* is unharmed (CRRA
   `sigma=2` has `u(c) = -1/c`, bounded above, so `max|V|` moves 5.409→5.431),
   but every **mean of output** must mask that node or the Debt/GDP axis
   collapses onto zero. `script_bm.m` and `check_claims_optionA.m` mask it;
   31 of 750,000 simulated rows are NaN-ed.

The **constant-price** (basic) economy is `constant_vol = .true.` with
`p_num = 1, p_vol_num = 1`; the single node is placed at the ergodic mean
`mean_p + 0.5·Var(log p)`, not at `exp(mean_p)`.

### Calibration as committed

`sigma = 2` (CRRA), `beta = 0.96`, `alpha = 0.3`, `theta = 0.5`,
`delta = 0.03`, `rstar = 0.01`, `rho = 0.9`, `scale_y = 10`,
`d0 = -0.246`, **`d1 = 0.3847`**, `rho_p = 0.98`, `mean_p = 0.12`,
`rho_p_vol = 0.66`, `mean_p_vol = -4.33`, `eta = 0.44`,
`b_num = 100`, `y_num = 21`, **`p_num = 7`**, `p_vol_num = 5`,
`use_common_p_grid = .false.`.

`d1` is the only parameter changed from the submitted version (0.37 → 0.3847,
a 4% rise in the quadratic default cost). It improves all four targeted moments;
see `results/SUMMARY.md` §4 for the sensitivity this introduces.

### Fixes relative to the submitted code

1. **Volatility convention.** `stochvol` defines `y = exp(h/2)·ε`, so the
   conditional standard deviation is `exp(h/2)`, not `exp(h)`. Corrected at 17
   call sites plus six aggregates (`E[exp(h)]`, not `E[exp(2h)]`). Without this
   the model's oil price moves 1.86% a quarter against 14.47% in the data.
2. **Oil-demand bisection** now uses a *relative* tolerance of `1d-10` scaled
   by `max(1, |m_opt|)`. It was an absolute `1e-2`, a 0.6–2% error in oil demand.
   Relative is required: the bracket expands to `1d+12` at low prices, where a
   flat absolute `1d-10` is unreachable and trips the failure exit.
3. **Double-precision literals.** Nine parameters were declared
   `DOUBLE PRECISION` but given default-REAL literals, so the model ran at
   `alpha = 0.30000001192`, `beta = 0.95999997854`, `mean_p_vol = -4.32999992`.
4. **Legacy grid blocks** no longer overwrite the common price grid.

5. **Simulation output format** widened from `F12.8` to `F20.8`: at the wide
   per-state grids the oil bill overflowed the field and wrote `************`,
   which MATLAB's `load` cannot parse.

Build: `gfortran -O3 -march=native -o solver oil_prod_CES.f90`. One economy
takes **26 seconds** at `p_num = 7`, roughly 45 minutes at `p_num = 549`.
`model/runs_optionA/` holds the five solved runs and `run_all_optionA.sh`
drives the figures from them.

---

## `figures_pipeline/`

Produces the ten paper figures. `working_graphs_dec29.m` split into one driver
per economy, because the benchmark script loads the other two workspaces to
draw FIGURE2 and FIGURE7.

    CONTRAST_MODE=price    bash run_all.sh   # local contrast -- the final set
    CONTRAST_MODE=fraction bash run_all.sh   # same relative grid positions

Edit the `stage` lines to point at your solved run directories.

`ink.m` is a blank-panel detector: it reports the fraction of coloured pixels
against the published figure, which catches a panel whose data has gone
off-scale. Several did during this revision.

### Fixes relative to the submitted scripts

- `fl__` textscan reader replaces `load` for the large ASCII dumps
- `pidx()` remaps price indices written for a 7-node grid (Figs 2, 3, 4d, 5);
  on 549 nodes the literals point near the grid floor and blanked FIGURE4d
- FIGURE4d's price nodes are anchored to the **ergodic p10/p50/p90**, not to
  relative grid position, which on a wide grid gives absurd "low/high" prices
- welfare is a consumption equivalent, `(Va/Vf)^(1/(1−σ)) − 1`; the original
  `(Va−Vf)/Vf·scale_y` divides by a *negative* CRRA value function and so had
  the sign backwards at every output state
- FIGURE7's legend labels unswapped
- axis limits autoscale where the old hardcoded ones no longer fit
- FIGURE4c smoothed with an edge-aware local cubic to suppress Tauchen aliasing
  (cosmetic; the artifact is in the solved transition matrix)

---

## `analysis/`

Scripts behind `results/SUMMARY.md`. Run from a directory holding
`oil_bm.mat`, `oil_intermediate.mat`, `oil_basic.mat`.

| script | what it computes |
|---|---|
| `check_claims.m` | the four quantitative claims: state dependence, debt amplification, debt slope, welfare |
| `sweep_by_debt.m` | the same across the whole debt range |
| `grid_resolution_check.m` | whether `b_grid` is fine enough to detect the claimed debt-slope effect (it is: the claimed gap is 21.6 grid steps) |
| `welfare.m` | consumption-equivalent welfare |
| `draw_claims_figure.m` | `results/FIGURE_claims_check.jpg` |
| `draw_debt_sweep.m` | `results/FIGURE_debt_sweep.jpg` |
| `check_claims_optionA.m` | the four claims on the **per-state** grid: matched prices + feasibility mask |
| `fig3_matched_vs_index.m` | Figure 3 slope, fixed-index vs matched-price side by side |
| `fig3_resolution_test.m` | shows the slope ratio is *not identified* at `p_num = 7` |

On the per-state grid, use `check_claims_optionA.m`: `check_claims.m` indexes
`spread_matrix(:,:,iHi,k)` with the same `iHi` in every volatility state, which
is a different physical price in each, and its `gdpm` is unmasked.

**Measure slopes over a local price contrast.** `check_claims.m` uses ±10%
around the ergodic median. Using a wide contrast — grid fractions, or ergodic
p10–p90, which spans 34× here — measures a chord rather than a derivative and
makes the volatility effect vanish into the price move. That mistake was made
twice during this revision.
