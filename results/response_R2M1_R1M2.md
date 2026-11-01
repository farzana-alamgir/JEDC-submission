# Response to R2 Major 1 and R1 Major 2

**Mean-preserving oil-price volatility: dispersion, expected prices, default and borrowing**

Finalised version. Every number below was recomputed from the saved runs
before this draft was written; §7 says with what.

---

We thank both referees for pointing out that stochastic volatility in log oil
prices changes both the dispersion and the conditional mean of the price level.
We agree that the full-versus-constant-volatility comparison alone cannot
separate these channels. We therefore report a mean-preserving specification and
compare it with both the full stochastic-volatility and constant-volatility
economies.

## 1. Specification

Let z = log p and let h denote log innovation variance; the conditional standard
deviation is exp(h/2). The mean-preserving price law is

```
z' = (1 − ρ_p) z̄ + ρ_p z − (exp(h') − v₀)/2 + exp(h'/2) u',     v₀ = E[exp(h)]
```

For the continuous law, E[p′ | z, h′] = exp((1 − ρ_p) z̄ + ρ_p z + v₀/2),
independent of h′. The correction subtracts half the deviation from the
*average* innovation variance rather than half the variance itself, so that its
mean aligns with the variance-matched constant-volatility reference. Future
volatility is drawn before the price innovation; expectations conditional on
current volatility integrate over that transition.

All three economies use the same physical oil-price grid and the same
preferences, technology and default-cost parameters: β = 0.9746, d0 = −0.246,
d1 = 0.4731, oil substitution elasticity 0.30.

### 1.1 The correction is exact at one step

Evaluated at an identical current price, p = 1.12750, using the solver's own
transition matrices:

| volatility state | sd(log p) | full SV | mean-preserving | closed form e^{v/2} |
|---|---|---|---|---|
| 1 | 0.0639 | 1.12981194 | 1.13635543 | 1.12979999 |
| 2 | 0.0856 | 1.13164910 | 1.13635543 | 1.13163713 |
| 3 | 0.1147 | 1.13495653 | 1.13635543 | 1.13494453 |
| 4 | 0.1538 | 1.14092166 | 1.13635543 | 1.14090959 |
| 5 | 0.2061 | 1.15171513 | 1.13635543 | 1.15170295 |
| | **swing** | **+1.9387%** | **+0.0000%** | **+1.9387%** |

The full model's one-step conditional expected price rises 1.94% from the
calmest to the most volatile state and matches the closed-form log-normal
prediction to five decimals, so the discretisation carries the effect in
question. Under the correction it is identical across all five states to eight
decimals.

### 1.2 It is not exact at longer horizons, and we quantify the residual

With ρ_p < 1 the conditional variance accumulates at ρ² while the drift
correction accumulates at ρ, so exact cancellation at every horizon would
require ρ_p = 1. Iterating the joint (price, volatility) transition forward from
the same state:

| horizon (quarters) | full SV swing | mean-preserving residual |
|---|---|---|
| 1 | +1.94% | **+0.00%** |
| 2 | +3.04% | −0.04% |
| 4 | +3.99% | −0.16% |
| 8 | **+4.04%** | −0.46% |
| 12 | +3.54% | −0.71% |
| 20 | +2.56% | −1.04% |
| 30 | +1.69% | −1.23% |
| 40 | +1.12% | **−1.26%** |

Two features matter. The full model's swing **peaks at about eight quarters**
(+4.04%) rather than at one, as the Jensen lift compounds before mean reversion
pulls it back. And the correction **overshoots monotonically**: the residual is
negative at every horizon beyond the first and reaches −1.26% at forty quarters,
which is 31% of the full model's peak swing and, at that horizon, larger in
magnitude than the full model's own remaining swing of +1.12%.

Since δ = 0.03 implies a bond duration near 25 quarters, the horizons that price
the bond are those where the residual is −1.0% to −1.2%. We therefore describe
this as a **one-step** mean-preserving adjustment and state plainly that the
comparison economy has expected prices that *fall* mildly with volatility at
long horizons, where the full economy's rise. The dispersion comparison in §3 is
accordingly contaminated at long horizons by a residual expected-price effect of
the opposite sign. Given the magnitudes in §3 this does not change any
conclusion, but it bounds how hard the decomposition can be pushed and we prefer
to report it than to let it be discovered.

The finite grid also does not deliver global mean preservation at every boundary
node.

## 2. Spreads, default and borrowing across economies

| economy | spread (bp) | debt/GDP (%) | default entries / 100 quarters | entries / 100 eligible quarters |
|---|---|---|---|---|
| full SV | 409.0 | 34.05 | 0.7768 | 0.8558 |
| mean-preserving SV | 405.7 | 33.89 | 0.7657 | 0.8425 |
| constant volatility | 402.7 | 33.46 | 0.7724 | 0.8501 |

Spread and debt/GDP use the existing Table 3 convention: averages over
100-quarter pre-default windows around qualifying episodes. Default-entry rates
use all 750,000 simulated quarters per economy; eligible quarters are those
whose preceding quarter was outside exclusion. Counts are 5,826 / 5,743 / 5,793
entries. These are not the counts of qualifying pre-default windows.

## 3. The decomposition

The three comparisons form an accounting decomposition: the total time-varying
volatility effect is (full − constant volatility); the dispersion component is
(mean-preserving − constant volatility); the expected-price component is
(full − mean-preserving). The two components sum to the total. Each comparison
incorporates the endogenous adjustment of the economy.

| comparison | difference (bp) | 95% simulation interval |
|---|---|---|
| full − constant volatility: **total** | +6.3 | [−2.4, 15.0] |
| mean-preserving − constant volatility: **dispersion** | +3.0 | [−5.8, 11.8] |
| full − mean-preserving: **expected price** | +3.3 | [−5.6, 12.2] |

These intervals are the existing episode-based Monte Carlo summaries, not
confidence intervals for estimated structural parameters. **All three include
zero.** We therefore do not claim that either component of time-varying
volatility is precisely distinguished from simulation variation by these
average-spread comparisons, and in particular we do not attribute the whole
+6.3 bp to pure dispersion. Each component is roughly half the total while its
interval is some three times its own magnitude, so the split is uninformative
rather than merely imprecise. A small average component does not rule out a
conditional response at a particular debt and oil-price state, which §4
examines directly.

The default-entry differences are likewise small descriptively: full minus
constant volatility is +0.0044 percentage points per quarter, mean-preserving
minus constant volatility −0.0067, and full minus mean-preserving +0.0111. We
assign no inference interval to these newly computed frequency differences.

**The aggregate level of oil-price risk is a different comparison.** The
full-minus-constant-price spread difference is **+218.9 bp**, with a reported
interval of ±6.5 bp. It should not be presented as the effect of time-varying
volatility, nor as a marginal spread response to a 10% oil-price shock.

## 4. Precautionary borrowing at identical states

R1 asks whether, once the mean effect is removed, any remaining increase in
borrowing reflects a precautionary response to oil price risk itself. Averages
across simulated economies cannot answer this: they confound the policy response
with the different ergodic distributions the economies visit. We therefore
compare policies at **identical states**, holding log endowment at zero and the
current oil price fixed, and varying only volatility.

### 4.1 Across the debt grid

Debt-grid nodes between 10% and 55% of reference annual value added, at log
endowment zero, retaining only states that repay at both volatility extremes:

| economy | current price | more debt | unchanged | less debt | states |
|---|---|---|---|---|---|
| full SV | baseline | 4 | 53 | **10** | 67 |
| full SV | oil +10.03% | 3 | 50 | 10 | 63 |
| mean-preserving SV | baseline | 7 | 59 | **0** | 66 |
| mean-preserving SV | oil +10.03% | 5 | 56 | 2 | 63 |

One debt-grid step is 0.20484 model units, so "unchanged" means the saved policy
does not resolve a change within that step, not that the response is zero. These
are equal-weight grid counts, not stationary probabilities, and the set of
repaying states differs slightly between economies.

The informative feature is the **asymmetry in the sign of the resolved
responses**. In the full economy, higher volatility lowers next-period debt at
10 of 67 nodes and raises it at 4. Under the mean-preserving correction the
declines **disappear entirely** — 7 nodes rise, none fall. The debt reductions in
the full economy are therefore attributable to the expected-price channel, not to
dispersion: when oil is expected to be dearer, the country deleverages. What
survives once that channel is removed leans weakly toward *more* borrowing,
consistent with a precautionary motive, but at 7 of 66 nodes it is not a general
response.

### 4.2 At one representative state

Holding current debt at 11.67582, equivalent to 33.72% of reference annual value
added, and comparing low against high volatility at the same oil price:

| economy | current price | change in next debt | spread change (bp) | next default prob. change (pp) |
|---|---|---|---|---|
| full SV | baseline | 0.00000 | 49.11 | 0.02384 |
| full SV | oil +10.03% | 0.00000 | 69.10 | 0.09776 |
| mean-preserving SV | baseline | 0.00000 | 36.98 | 0.01555 |
| mean-preserving SV | oil +10.03% | 0.00000 | 50.71 | 0.06808 |
| **constant volatility** | baseline | **0.00000** | **0.00** | **0.00000** |
| **constant volatility** | oil +10.03% | **0.00000** | **0.00** | **0.00000** |

**The constant-volatility rows are a placebo.** That economy retains five
volatility indices that are economically identical, so a correctly specified
comparison must return exactly zero across them. It does, to every digit
reported, which confirms that the machinery is not manufacturing differences out
of indexing or interpolation.

The default probability here is one-period-ahead default conditional on today's
chosen repayment debt, computed from the saved default policy and the same
future-volatility transition law used in pricing. It is neither today's
deterministic default decision nor a long-run default frequency.

## 5. Interpretation

Next-period debt at this representative state is unchanged across volatility
states in both specifications. Removing the expected-price effect does not
reveal additional borrowing *there*. But higher volatility still raises spreads
and next-period default probabilities in the mean-preserving economy — 36.98 bp
at the baseline price and 50.71 bp after a 10% increase. Dispersion can
therefore matter for conditional sovereign risk without generating more
borrowing at a given state.

Taken with §4.1, the position we can defend is:

- the **average-spread decomposition is uninformative**: both components are
  within simulation variation;
- **dispersion does raise conditional spreads and default risk** at matched
  states, by an economically visible 37 to 51 bp;
- **borrowing responses are state dependent**, frequently unresolved on the
  saved debt grid, and the resolved declines in the full economy are attributable
  to the expected-price channel rather than to dispersion;
- the evidence supports **neither** a general precautionary-borrowing **nor** a
  general precautionary-saving claim. Differences in average debt/GDP across
  simulated economies cannot establish a conditional mechanism in either
  direction.

## 6. Suggested manuscript wording

> We separate the dispersion and expected-price components of time-varying
> oil-price volatility using a one-step mean-preserving adjustment. The
> average-spread decomposition is small relative to simulation variation: the
> total difference is 6.3 basis points, of which 3.0 corresponds to the
> dispersion comparison and 3.3 to the expected-price comparison, and each
> reported interval includes zero. At matched current states, dispersion still
> raises spreads and future default risk by 37 to 51 basis points. Borrowing
> responses are heterogeneous: the debt reductions observed under the full
> specification are attributable to the expected-price channel and disappear
> once it is removed, while the remaining responses lean weakly toward greater
> borrowing without constituting a general pattern. The policy functions
> therefore support neither a general precautionary-borrowing nor a general
> precautionary-saving claim.

## 7. Source and scope

Committed common-grid-final source set `model/src_spdebt`. Saved runs:
`model/runs_bd1/spdebt` and `model/runs_spdebt/{mean_preserving,intermediate}`.

| exhibit | produced by |
|---|---|
| §1.1, §2, §3 | `model/analysis/decomposition.py` |
| §1.2 | `model/analysis/horizon_check.py` |
| §4 | the saved policy arrays, indexed as the solver writes them |
| figure | `model/analysis/FIGURE_decomposition.m` |

No solver settings, economic parameters or numerical convergence criteria were
changed. All figures in §1.1 and §2–§4 were independently recomputed from the
saved runs before this draft was finalised.
