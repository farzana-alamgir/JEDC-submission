# Small-price-grid feasibility audit

This is a process-only audit at the current branch oil-process parameters. It does not solve the sovereign model, validate economic claims, or edit the original model. Source hash and all parameters are in audit.json. Reproduce with `python model/claim_tests/audit_small_price_grids.py`.

## What was tested

1. Reconstructed the original seven-point Rouwenhorst grid construction, using the corrected conditional standard deviation exp(h/2). Verified analytically and numerically that each standalone, constant-volatility Rouwenhorst chain matches its conditional log mean and variance. Seven-point Rouwenhorst is not intrinsically defective.
2. Checked switching between these grids using the same index transition matrix. With current volatility k and future volatility l, the implied conditional log mean is mu + rho*(sd_l/sd_k)*(z-mu), rather than mu + rho*(z-mu). The extra scale factor changes the stated stochastic process. This check assumes future volatility is drawn first, as in the current solver.
3. Built candidate transitions directly from each actual current oil price into the future-volatility grid using Gaussian cell probabilities. Tested common and volatility-specific supports at 7, 15, 31, 61, 121, 241, and 549 points. Held the support bounds fixed as point counts increased, to isolate resolution. Tests used the identical physical prices exp(mu)*[0.8,1,1.2] and all five future volatility states, for both full and mean-preserving processes.
4. Applied a probability-method-independent feasibility bound. If adjacent log-price points L,U enclose a desired conditional mean m, any distribution supported on the grid with that mean must have variance at least (m-L)*(U-m). When this exceeds the intended variance, no adjustment to transition probabilities can exactly match both log moments on that support.

## Findings

For the mean-preserving process, out of 15 tested price/future-volatility combinations:

| Nodes per volatility | Impossible log-mean/variance targets: common support | Impossible targets: original volatility-specific supports |
|---|---:|---:|
| 7 | 11 | 10 |
| 15 | 7 | 0 |
| 31 | 2 | 0 |
| 61 | 0 | 0 |
| 121 | 0 | 0 |
| 241 | 0 | 0 |
| 549 | 0 | 0 |

Zero impossible targets is a necessary condition in these tests, not proof of global process accuracy, convex order, or economic grid convergence.

The seven-point Gaussian-cell candidates also fail to preserve the level mean across future volatility: maximum relative ranges are 16.11% on the common support and 12.82% on the regime-specific supports at the tested prices. These numbers describe the NEW uncorrected Gaussian-cell candidates, not the solver's moment-matched/level-tilted kernels, and not the original Rouwenhorst kernel. Do not use them to claim the current 549-point mean-preserving candidate has failed.

The reconstructed highest-volatility original support starts at price 0.089180. With alpha=0.3 and theta=0.5, the CES finite-oil-input condition is price > 0.09. Thus restoring that support under corrected volatility introduces one economically inadmissible endpoint. Merely adding points while retaining the same endpoint does not repair it. The current common support begins at 0.125061, above this threshold. No technology or support was silently changed in this audit.

## Implication

Do not restore the original seven-state transition scheme unchanged. Correct physical transitions and common-price comparisons are necessary; these particular seven-point supports still cannot reproduce the intended moments at the tested prices. This does not rule out all numerical methods with seven value-function nodes: continuous quadrature with interpolation is a different method requiring its own accuracy checks.

549 has not been shown necessary. For the current admissible common support, 61 and 121 points are reasonable NEXT resolution experiments; process moments, exact level-mean preservation, convex order, and converged borrowing/spread comparisons must be checked before selecting either. Volatility-specific grids remain possible, but require a current/future-volatility transition kernel, consistent physical interpolation, and an admissible support. The Gaussian-cell numbers alone do not justify choosing the final grid or endorsing amplification/precautionary borrowing.

Artifacts: audit.json (source provenance, analytical index-switch examples, all results), resolution_comparison.csv (comparison table). The full model has not been solved on these candidate grids.
