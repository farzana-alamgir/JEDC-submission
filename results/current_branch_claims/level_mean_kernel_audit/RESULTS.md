# Exact finite-grid mean-preserving-spread candidate

**The candidate MP kernel passes both equal conditional means and convex order
on the entire finite grid. It is not yet a solved economic equilibrium.**

For each (current price, future volatility) row, probabilities are tilted by
exp(lambda*(p'-target)/target), choosing lambda so E[p'] equals the intended
continuous-process conditional level mean. Support and economic parameters are
unchanged. The MP target is the same for all future volatility states:

    target(z) = exp((1-rho_p)*mean_p + rho_p*z + E[innovation variance]/2).

The full-SV candidate instead uses its own variance-specific continuous-law
level mean. This provides a common numerical moment-selection rule for the two
candidate economies. Original model source is untouched.

| Diagnostic | Full SV candidate | MP SV candidate |
|---|---:|---:|
| Maximum relative conditional level-mean error | 2.03e-14 | 2.02e-14 |
| Maximum central-region total variation from original row | 8.91e-12 | 8.91e-12 |
| Old-stationary weighted row total variation | 2.57e-5 | 2.36e-5 |
| Worst relative conditional log-variance error | 82.8% | 74.6% |
| Old-stationary weighted absolute relative log-variance error | 0.0410% | 0.0433% |

These are discrete-kernel comparisons, not posterior uncertainty intervals or
welfare bounds. Small weighted transition differences do not bound the effect
on default incentives or the nonlinear equilibrium.

## Stronger check than equal means and increasing variance

For distributions on identical finite support, convex order is checked by equal
means and all stop-loss payoffs E[(p'-K)+] at every support strike K. This is
stronger than merely checking that variance increases.

The corrected MP kernel passes for every adjacent volatility pair at every
current price, both before and after integrating over next volatility with the
solver's timing. The smallest normalized stop-loss difference is about -4e-14,
consistent with rounding. No comparison violates the 1e-10 tolerance. The
original MP kernel fails globally: after volatility integration, 490 of 2196
adjacent-state comparisons have a stop-loss violation and conditional means
are not equal near boundaries.

The corrected MP kernel also has increasing level-price variance at every
current price across future-volatility states. The full-SV candidate has six
local variance-order violations at edges; it is not labeled a mean-preserving
spread and this is a separate approximation limitation.

## What changed and the tradeoff

The original routine targets conditional log mean and log variance; the new
correction prioritizes the economically relevant conditional level mean. All
three moments cannot generally be reproduced on bounded support near its
endpoints. The log-variance errors therefore become large in some rare tail
rows. This must be disclosed and tested through equilibrium and grid-sensitivity
checks before choosing this discretization for the paper. It should not be
presented as unchanged Gaussian dynamics everywhere.

The compressed candidate kernels, audits, and convex-order checks are saved
here. `test_level_mean_correction.py` and `check_convex_order.py` reproduce them.
