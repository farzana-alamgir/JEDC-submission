# A risk premium on oil price risk: what it can and cannot do for FIGURE3

**This file replaces an earlier version whose numbers were wrong.** The
original reported that `kappa_risk = 3` flipped the FIGURE3 ordering (ratio
1.235). That result came from a defective stochastic discount factor and does
not survive the fix. The corrected finding is below.

---

## The bug

The risk kernel was

    log m' = -rstar + kappa*eps' - 0.5*kappa^2*sigma^2

where `-0.5*kappa^2*sigma^2` is the **lognormal** Jensen correction, which
makes `E[m'] = exp(-rstar)` only for a *continuous normal* innovation. On the
7-node Rouwenhorst grid `exp(kappa*eps)` spans orders of magnitude at
`kappa = 3`, and the discrete expectation misses badly. Measured on the
benchmark grid:

    E[m]/exp(-rstar) across (p, sigma) cells:  0.0000 to 2559      (should be 1)

So `kappa_risk` was not pricing risk; it was applying an arbitrary,
state-varying distortion to the discount factor.

The clearest symptom was the constant-price economy. With `p_num = 1` the
innovation is identically zero while the correction still applied, leaving
`E[m] = exp(-rstar - 0.5*kappa^2*sigma^2)` — a pure shift in the discount
rate with no risk in it at all. That economy reported a **22% spread with
ZERO defaults in 500,000 periods**.

## The fix

The kernel is now normalised numerically on the actual grid:

    m' = exp(-rstar) * exp(kappa*eps') / Z(p, sigma'),
    Z  = sum_j  pi(p -> p_j | sigma') * exp(kappa*eps_j)

so `E[m'] = exp(-rstar)` holds exactly by construction, for any grid including
the degenerate `p_num = 1` case. `Z` is computed once in `compute_grid` and
shared by all three use sites (`precompute_expectations`, `q_fun`,
`q_def_free_fun`), so they cannot drift apart.

Verified: at `kappa_risk = 0`, `Z = 1.000000` exactly and the solver
reproduces the previous baseline to **2.7e-15** (the residual is
`EXP(a)*EXP(b)/1` rounding differently from `EXP(a+b)`).

## Corrected result

Slope ratio (high/low volatility) at i_b = 44, value-added default cost,
`sigma_oil = 0.30`:

| kappa | buggy kernel | **corrected kernel** |
|---|---|---|
| 0 | 0.621 | 0.621 |
| 1 | 0.698 | 0.682 |
| 2 | 0.774 | 0.722 |
| 3 | **1.235** | **0.830** |
| 5 | — | **1.199** |

The mechanism is real and points the right way — a risk premium loads more
heavily on high-volatility states, and the ratio rises monotonically in
`kappa`. But it rises about three times more slowly than the buggy version
suggested, and at `kappa = 3` the ratio is **0.68 to 0.86 across the entire
debt grid**, never above 1.

## Where it crosses, and what that costs

The ordering does flip, at roughly `kappa = 4`:

| | kappa = 0 | kappa = 3 | kappa = 5 |
|---|---|---|---|
| slope ratio (i_b = 44) | 0.621 | 0.830 | **1.199** |
| mean spread (target 4.1) | 4.41 | 6.48 | 5.61 |
| **debt/GDP (target 34.0)** | **33.69** | **18.06** | **8.11** |
| oil/GDP (target 9.0) | 8.73 | 11.84 | 15.07 |
| default episodes in 500k periods | 1423 | 395 | **95** |
| implied max Sharpe, annualised | 0 | 0.75 | **1.25** |

At `kappa = 5` the country barely borrows — debt/GDP 8.1% against a 34%
target — so the model no longer describes an indebted sovereign, which is the
object the paper is about. The implied maximum Sharpe ratio of 1.25 a year is
also well beyond any empirical benchmark (equities are about 0.4).

**So the FIGURE3 ordering is attainable, but not at a calibration that also
matches Table 3.** Raising `kappa` buys the ratio by destroying the debt
moment. That is a different statement from "structurally impossible", and a
weaker one than the earlier draft claimed — but it is not a result the paper
can use.

## What this does not change

Everything in `VALUE_ADDED_DEFAULT_COST.md` stands, since it was computed at
`kappa_risk = 0` where the bug is inert (`Z = 1`):

- oil price risk raises spreads **+206.5 bp**
- a 20% oil price move shifts the spread **43 bp**, ten times the endowment-cost model
- debt amplification **112 -> 286 bp**
- welfare of removing oil price risk **+0.73%**, inside the claimed +0.2% to +1.1%
- FIGURE2, FIGURE5, FIGURE6a/6b and FIGURE7 all support the paper

## Lesson for the code

Any SDF added to this model must be checked for `E[m] = exp(-rstar)` **on the
discrete grid** before its results are used. The analytic continuous-state
correction is not a substitute, and the error is invisible at `kappa = 0`
where everything is tested by default. `compute_grid` now prints the range of
`Z` at startup so a broken kernel is visible immediately.
