# R2, Major 1 and R1, Major 2

*Separating dispersion from the volatility-induced rise in expected oil prices*

Both reports raise the same objection, and it is the right one. In our
specification a rise in volatility does two things at once. It widens the
distribution of next period's oil price, which is the uncertainty effect we
meant to study. But because the price is log-normal, it also lifts the
*expected level* of that price, even though the mean of the log is untouched.
We had been calling the combination "uncertainty." As R2 puts it, part of what
the model calls an effect of uncertainty is really the effect of a higher
expected oil price.

We have run the experiment both reports ask for. It changed what we claim, and
we would rather set out the result plainly than defend the original wording.

## What we did

We add a third economy in which the conditional mean of the price level is held
fixed while its dispersion still varies with volatility. Writing z for log p and
h for the log innovation variance,

```
z' = (1 − ρ_p) z̄ + ρ_p z − (exp(h') − v₀)/2 + exp(h'/2) u'
```

with v₀ = E[exp(h)]. One choice here is ours rather than the referees': we
subtract half the deviation of the conditional variance from its *average*
rather than half the variance itself, so that the corrected economy lines up
with the variance-matched constant-volatility economy we are comparing it to.
All three economies share the same price grid, the same preferences and
technology, the same default-cost parameters, and the same shocks.

## Does the correction do what it should?

At one step, exactly. Evaluated at a common current price, the full model's
expected next-period price climbs 1.94% as we move from the calmest volatility
state to the most volatile. That figure is worth pausing on: it matches the
closed-form log-normal prediction e^{v/2} to five decimal places, which tells us
the discretisation is fine enough to carry the very effect under discussion.
Once the correction is applied, the expected price is the same in all five
states to eight decimal places.

| | calmest state | most volatile | swing |
|---|---|---|---|
| full model | 1.12981 | 1.15172 | **+1.94%** |
| mean-preserving | 1.13636 | 1.13636 | **0.00%** |

Figure 1(a) shows this: the full model's line sits exactly on the closed-form
curve, and the corrected one is flat.

Beyond one step it is not exact, and we would rather report that than have it
found. Because ρ_p is below one, the conditional variance accumulates faster
than the drift correction, so the two stop cancelling. Iterating the price and
volatility transitions forward:

| horizon | full model | mean-preserving |
|---|---|---|
| 1 quarter | +1.94% | 0.00% |
| 8 quarters | +4.04% | −0.46% |
| 20 quarters | +2.56% | −1.04% |
| 40 quarters | +1.12% | −1.26% |

Two things are visible here. The full model's effect peaks at around two years
rather than at one quarter, as the lift compounds before mean reversion pulls it
back. And the correction overshoots: by forty quarters the corrected economy's
expected prices are *falling* with volatility by about as much as the full
model's are rising. Since a coupon rate of 0.03 implies a duration near
twenty-five quarters, these are the horizons at which the bond is actually
priced. So the comparison is clean at one step and only approximate over the
life of the debt, and the dispersion channel we report below is to that extent
contaminated by a residual price effect pulling the other way. At the
magnitudes involved this does not change any conclusion, but it does mean the
decomposition should not be pushed harder than we push it.

## What the decomposition shows

Comparing the three economies gives the split the referees asked for. The
difference between the full and constant-volatility economies is the total
effect of time-varying volatility; the mean-preserving economy divides it into a
dispersion part and an expected-price part.

| | difference | simulation interval |
|---|---|---|
| total effect of time-varying volatility | +6.3 bp | [−2.4, 15.0] |
| of which dispersion | +3.0 bp | [−5.8, 11.8] |
| of which expected price | +3.3 bp | [−5.6, 12.2] |

We will not dress this up. Each component is about half the total, and each
interval is roughly three times the size of the number it brackets. All three
contain zero. Figure 1(b) makes the contrast plain: one bar clears its interval
comfortably and three do not. These are Monte Carlo intervals rather than standard errors on
estimated parameters, but the reading is the same: on average spreads, we cannot
separate the two channels, and we do not claim the effect belongs to either one.
R2 writes that a small pure-uncertainty effect would be a fine answer provided
the reader learns why volatility matters. We think that is where we have landed.

What is not in doubt is the level. Comparing the full economy with one facing a
constant oil price, the difference in mean spreads is **219 basis points**, with
an interval of ±6.5 — thirty times the time-variation channel and more than
thirty times its own sampling error. Oil price risk matters a great deal to
these borrowers. It is the time *variation* in that risk which we cannot pin
down separately, and we have been careful in the revision not to let the large
number stand in for the small one, or to present it as a response to a 10% oil
price move.

## Does precautionary borrowing survive?

R1 asks the sharper follow-up: once the expected-price effect is removed, does
any remaining increase in borrowing reflect a precautionary response to risk
itself? Averages across the simulated economies cannot answer this, because they
confound the policy response with the different states each economy visits. So
we compared the policies directly, holding endowment, debt and the oil price
fixed and varying only volatility.

At a representative state — debt at 34% of annual value added, endowment at its
median — next-period debt is identical across volatility states in both the full
and the corrected economy. Removing the expected-price effect reveals no extra
borrowing there. But spreads and next-period default probabilities still rise
with volatility in the corrected economy, by 37 basis points at the baseline
price and 51 after a 10% increase. Dispersion can raise the price of risk
without changing how much the country borrows at that state.

Across the debt grid the picture is more interesting than a single state
suggests:

| | more debt | unchanged | less debt |
|---|---|---|---|
| full model | 4 | 53 | **10** |
| mean-preserving | 7 | 59 | **0** |

In the full economy, higher volatility *reduces* next-period debt at ten of
sixty-seven states and raises it at four. Under the correction the reductions
vanish altogether: seven states borrow more and none borrow less. The
deleveraging, in other words, was the expected-price channel — when oil is
expected to be dearer, the country pays down. What remains once that is removed
leans gently toward borrowing, which is the precautionary motive the paper
describes, but at seven states out of sixty-six we would not call it a general
response.

Figure 1(c) and 1(d) show the same thing state by state. The policy moves in
whole grid nodes, so every resolved response is exactly one node up or down —
about 0.6 percentage points of annual value added. In the full economy a row of
points sits at −1 across the whole debt range; under the correction that row is
empty at the baseline price and nearly empty after a 10% rise.

One honest caveat on reading this: "unchanged" means the saved policy does not
resolve a movement smaller than one grid node, not that the response is exactly
zero. Most states are in that category, which is why we do not lean on the
counts beyond the asymmetry in their signs.

![**Figure 1.** (a) Expected next-period oil price by volatility state, at a common current price, for the full and mean-preserving economies, with the closed-form log-normal prediction overlaid. (b) The channel decomposition with 95% simulation intervals. (c, d) High-minus-low volatility change in next-period debt across the debt grid at median endowment, at the baseline oil price and after a 10% rise; one grid node is about 0.6 percentage points of annual value added, and only states repaying at both volatility extremes are shown.](decomposition_spdebt/FIGURE_decomposition.jpg)

## Where this leaves the section

We have rewritten Section 6.3 accordingly. The experiment supports neither a
general precautionary-borrowing claim nor its opposite, and the earlier version
of this response, which concluded that isolated oil risk induces precautionary
*saving*, went further than the evidence allows — that reading rested on
differences in average debt across economies, which cannot identify a
conditional response. What we now say is that dispersion raises the conditional
price of risk, that borrowing responses are state dependent and often too small
for the grid to resolve, and that the aggregate effect of oil price risk is
large and precisely measured while its decomposition is not.

We are grateful for the comment. It cost us a headline claim and improved the
paper.

---

### Suggested manuscript wording

> We separate the dispersion and expected-price components of time-varying
> oil-price volatility using a one-step mean-preserving adjustment. The
> decomposition of average spreads is small relative to simulation variation:
> the total difference is 6.3 basis points, of which 3.0 corresponds to
> dispersion and 3.3 to the expected-price channel, and each interval includes
> zero. At matched states, dispersion still raises spreads and future default
> risk by 37 to 51 basis points. Borrowing responses are heterogeneous: the
> debt reductions seen under the full specification are attributable to the
> expected-price channel and disappear once it is removed, while the remaining
> responses lean weakly toward greater borrowing without constituting a general
> pattern.

### Technical notes

The economies: full SV, mean-preserving SV and constant volatility give mean
spreads of 409.0, 405.7 and 402.7 bp on debt/GDP of 34.05, 33.89 and 33.46%,
with default entries of 0.7768, 0.7657 and 0.7724 per hundred quarters (5,826 /
5,743 / 5,793 entries over 750,000 simulated quarters; per hundred *eligible*
quarters, 0.8558 / 0.8425 / 0.8501). Spread and debt figures use the Table 3
convention of averaging over hundred-quarter pre-default windows; the entry
rates use the whole simulation and are not the same statistic.

The fixed-state comparison holds log endowment at zero and debt at 11.67582,
which is 33.72% of reference annual value added, and evaluates at prices of
1.12750 and 1.24061. Spread changes are 49.11 and 69.10 bp in the full economy
and 36.98 and 50.71 in the corrected one, with next-period default probabilities
rising 0.024 and 0.098 percentage points, and 0.016 and 0.068. The
constant-volatility economy returns exactly zero in every column, which is the
check we want: its five volatility indices are economically identical, so
anything other than zero would mean the comparison itself was generating
differences. The debt-grid counts cover nodes between 10% and 55% of reference
annual value added at median endowment, keeping only states that repay at both
volatility extremes, and are equal-weight counts rather than stationary
probabilities.

Everything here comes from the committed source set `model/src_spdebt` and the
saved runs `model/runs_bd1/spdebt` and
`model/runs_spdebt/{mean_preserving,intermediate}`. The tables are produced by
`model/analysis/decomposition.py`, the horizon profile by
`model/analysis/horizon_check.py`, and the figure by
`model/analysis/FIGURE_decomposition.m`. No solver settings, parameters or
convergence criteria were changed in preparing this response.
