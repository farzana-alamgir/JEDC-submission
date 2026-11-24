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
The short version: the referees are right about the direction, and on average
spreads the expected-price channel accounts for most of what we had attributed
to uncertainty. But the exercise also shows, conditionally and unambiguously,
that dispersion by itself raises the price of risk.

R1 asks specifically for default probabilities, spreads and borrowing. We now
report all three for every economy, and we report them both unconditionally and
by volatility state, because the two give different answers and the difference
is informative rather than awkward.

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
All four economies share the same price grid, the same preferences and
technology, the same default-cost parameters, and the same shocks.

## Does the correction do what it should?

At one step, exactly. Evaluated at a common current price, the full model's
expected next-period price climbs 1.76% as we move from the calmest volatility
state to the most volatile. That figure is worth pausing on: it matches the
closed-form log-normal prediction e^{v/2} to four decimal places, which tells us
the discretisation is fine enough to carry the very effect under discussion.
Once the correction is applied, the expected price is identical in all five
states to eight decimal places.

| | calmest state | most volatile | swing |
|---|---|---|---|
| full model | 1.13184 | 1.15179 | **+1.76%** |
| mean-preserving | 1.13874 | 1.13874 | **0.00%** |
| closed form e^{v/2} | 1.13184 | 1.15178 | +1.76% |

Figure 1(a) shows this: the full model's line sits exactly on the closed-form
curve, and the corrected one is flat.

**Beyond one step the correction does not merely lose exactness — it reverses
sign and overshoots.** We report this prominently because it governs how much
weight the decomposition below can carry. Because ρ_p is 0.9475 rather than
close to one, the conditional variance accumulates faster than the drift
correction, and the two stop cancelling:

| horizon | full model | mean-preserving | residual / effect |
|---|---|---|---|
| 1 quarter | +1.76% | −0.00% | 0.00 |
| 4 quarters | +3.67% | −0.37% | −0.10 |
| 8 quarters | +3.32% | −0.96% | −0.29 |
| 12 quarters | +2.39% | −1.31% | −0.55 |
| **20 quarters** | **+1.04%** | **−1.41%** | **−1.35** |
| 40 quarters | +0.12% | −0.72% | −6.21 |

A coupon rate of 0.03 implies a duration near twenty-five quarters, so twenty
quarters is where the bond is actually priced. At that horizon the corrected
economy's expected prices are falling with volatility by *more* than the full
economy's are rising. The correction is not a small approximation there; it is
larger than the thing it is meant to remove, and pointing the other way.

This has a definite consequence for the decomposition, and in a known
direction. The corrected economy faces systematically *cheaper* oil in
high-volatility states than a correctly mean-preserving economy would, which
lowers its spreads in those states. That inflates the measured difference
between the full and corrected economies, and deflates the measured difference
between the corrected and constant-volatility economies. So in the table below,
**the expected-price component is an upper bound and the dispersion component a
lower bound.** We can sign the bias; we cannot size it.

## What the decomposition shows

Comparing the four economies gives the split the referees asked for. The
difference between the full and constant-volatility economies is the total
effect of time-varying volatility; the mean-preserving economy divides it into a
dispersion part and an expected-price part.

| | mean spread | 95% int. | ≠0? | default prob. | 95% int. | ≠0? |
|---|---|---|---|---|---|---|
| oil price risk at all (full − constant price) | **+200.7 bp** | ±4.8 | yes | **+1.679 pp** | ±0.104 | yes |
| total effect of time-varying volatility | **+13.4 bp** | ±6.0 | yes | +0.113 pp | ±0.119 | no |
| of which dispersion (upper-bounded above) | +1.3 bp | ±6.0 | no | +0.025 pp | ±0.119 | no |
| of which expected price (lower-bounded above) | +12.1 bp | ±5.9 | yes | +0.087 pp | ±0.120 | no |

The two columns agree on the thing that matters. The level channel dominates
both and does so to the same degree: it is 49.2% of the mean spread and 50.2%
of the mean default probability. That two statistics as different as a
continuous price and a count of rare events put the level channel at the same
share is a check on the decomposition rather than a restatement of it. We
deliberately do not form the ratio of the level channel to the time-variation
channel in either column, for the reason given below.

They differ on the time-variation total: +13.4 bp is outside its interval,
+0.113 pp is not. This is a difference in power, not a contradiction. The
spread is observed every quarter; the default rate rests on roughly 5,700
events across the four economies, so its Poisson interval is ±0.12 pp on a
difference and a channel this small cannot clear it. We report the null rather
than suppress it.

The constant-volatility economy's five volatility indices are economically
identical, so the range of its statistics across them measures the simulation
noise floor directly: 0.8 basis points on the mean spread, and 0.135 percentage
points on the annual default probability.

The total effect of time-varying volatility is measurable and positive. Its
apportionment is where we must be careful. Taken at face value the table says
almost all of it is the expected-price channel — which is precisely R2's
objection, confirmed. But the horizon table above says this particular split is
biased toward exactly that conclusion, so we do not want to lean on the
arithmetic either way. What we can say without qualification is that the total
is +13.4 bp and that the dispersion component, measured this way, is not
distinguishable from zero.

We previously described the large level effect as "thirty times the
time-variation channel." We have removed that comparison. It invited the reader
to treat the small number as a measured channel of the same standing as the
large one, which the overshoot above does not support.

What is not in doubt is the level. Comparing the full economy with one facing a
constant oil price, the difference in mean spreads is **200.7 basis points**,
with an interval of ±4.8 — more than forty times its own sampling error, and
49% of the mean spread. Oil price risk matters a great deal to these borrowers.
It is the time *variation* in that risk which we cannot cleanly apportion, and
we have been careful in the revision not to let the large number stand in for
the small one, or to present it as a response to a 10% oil price move.

## Does dispersion do anything on its own?

Yes, and this is the part of the exercise that identifies something. The
average-spread decomposition is compromised by the overshoot; the conditional
comparison is not, because it reads the corrected economy against itself across
volatility states rather than against another economy.

In the mean-preserving economy — where one-step expected prices are flat by
construction — mean spreads by volatility state are:

| volatility state | sd(log p) | mean spread | mean price |
|---|---|---|---|
| 1 (calmest) | 0.0877 | 330.2 bp | 1.24746 |
| 2 | 0.1086 | 337.2 | 1.24812 |
| 3 | 0.1345 | 349.6 | 1.24122 |
| 4 | 0.1666 | 363.1 | 1.23859 |
| 5 (most volatile) | 0.2064 | **377.2** | 1.22809 |

Monotone, **+47.0 basis points** from calmest to most volatile, against a
placebo noise floor of 0.8 bp. And the decisive detail is the last column: the
mean *price* is **falling** across those states. Spreads rise while oil gets
cheaper, so this cannot be an expected-price effect. Dispersion raises the
conditional price of risk.

For contrast, the same table in the full economy runs 327.4 to 404.8 bp, a
swing of +77.4 bp, with the mean price *rising* from 1.22185 to 1.26817 — the
two channels working together, which is what the referees asked us to take
apart.

### The same test in default probabilities

R1 asks for default probabilities, and this is where they are most
informative. The annual default probability, computed over quarters in good
standing, behaves exactly as the spread does. Figure 1(e) plots it against the
same horizontal axis as Figure 1(a), so the two panels can be read together:

| volatility state | sd(log p) | mean-preserving | full | placebo |
|---|---|---|---|---|
| 1 (calmest) | 0.0877 | **2.191%** | 1.996% | 3.163% |
| 2 | 0.1086 | 2.675 | 2.406 | 3.274 |
| 3 | 0.1345 | 3.073 | 3.107 | 3.201 |
| 4 | 0.1666 | 3.885 | 4.224 | 3.226 |
| 5 (most volatile) | 0.2064 | **5.125** | 6.141 | 3.298 |
| | **swing** | **+2.934 pp** | +4.145 pp | 0.135 pp |

In the mean-preserving economy the annual default probability rises
monotonically from 2.19% to 5.13% — it **more than doubles** — while the mean
oil price in those same states is *falling*. The standard error on that
difference is 0.239 percentage points, so it is twelve standard errors from
zero, against a placebo range of 0.135 pp.

This is the sharpest single result in the exercise, and it is worth being
explicit about why it survives when the unconditional default decomposition
does not. The unconditional comparison asks the data to resolve a 0.11 pp
difference between two economies that visit different states; the conditional
comparison asks it to resolve a 2.93 pp difference *within one economy* across
states that differ only in dispersion, with expected prices flat by
construction. The second question is both larger and cleaner. Dispersion by
itself does not merely raise the price of risk — it raises the quantity of
default.

## Does precautionary borrowing survive?

R1 asks the sharper follow-up: once the expected-price effect is removed, does
any remaining increase in borrowing reflect a precautionary response to risk
itself? Averages across the simulated economies cannot answer this, because they
confound the policy response with the different states each economy visits. So
we compared the policies directly, holding endowment and debt fixed and varying
only volatility.

| | more debt | unchanged | less debt | states |
|---|---|---|---|---|
| full, baseline price | 1 | 59 | **9** | 69 |
| full, price +10.6% | 3 | 53 | **10** | 66 |
| mean-preserving, baseline | 2 | 64 | **3** | 69 |
| mean-preserving, price +10.6% | 3 | 61 | **2** | 66 |

In the full economy, higher volatility *reduces* next-period debt at nine of
sixty-nine states at the baseline price and ten of sixty-six after a price rise.
Under the correction those reductions fall to three and two. **They do not
vanish, and we have corrected the earlier draft of this response, which said
they did.** At the previous calibration they did vanish entirely; at this one
they do not. What survives is a clear asymmetry — deleveraging is roughly three
to five times less common once the expected-price channel is removed — rather
than the clean disappearance we previously reported.

So the honest reading is that the deleveraging seen under the full
specification is *largely* the expected-price channel: when oil is expected to
be dearer, the country pays down. What remains after the correction is a small
residue in both directions, at a handful of states out of nearly seventy. We
would not call that a general precautionary response in either direction.

Figure 1(c) and 1(d) show the same thing state by state. The policy moves in
whole grid nodes, so every resolved response is exactly one node up or down —
about 0.59 percentage points of annual value added.

One honest caveat on reading this: "unchanged" means the saved policy does not
resolve a movement smaller than one grid node, not that the response is exactly
zero. The large majority of states are in that category, which is why we do not
lean on the counts beyond the asymmetry in their signs.

![**Figure 1.** (a) Expected next-period oil price by volatility state, at a common current price, for the full and mean-preserving economies, with the closed-form log-normal prediction overlaid. (b) The channel decomposition of the mean spread, with 95% simulation intervals. (c, d) High-minus-low volatility change in next-period debt across the debt grid at median endowment, at the baseline oil price and after a 10% rise; one grid node is about 0.59 percentage points of annual value added, and only states repaying at both volatility extremes are shown. (e) Annual default probability by volatility state, on the same horizontal axis as panel (a), with 95% Poisson intervals. Panels (a) and (e) are the exercise in one line: expected prices are flat across the mean-preserving economy's volatility states by construction, and its default probability still more than doubles, while the constant-volatility placebo stays flat throughout.](economies_common_check/decomposition/FIGURE_decomposition.jpg)

## Where this leaves the section

We have rewritten Section 6.3 accordingly, and the revision concedes more than
the first draft of this response did.

The aggregate effect of oil price risk is large and precisely measured: 200.7
basis points, about half the mean spread. The effect of *time variation* in that
risk is small but measurable at 13.4 basis points, and the referees are right
that most of it operates through expected prices rather than through dispersion.
We cannot put a reliable number on the split, because the one-step correction
the exercise relies on overshoots at the horizons where the bond is priced.

What we can show, and now lead with, is the conditional result: holding
expected prices flat by construction, spreads still rise 47 basis points and
the annual default probability more than doubles, from 2.19% to 5.13%, from the
calmest to the most volatile state — while the oil price itself falls, and
against placebo noise floors of 0.8 bp and 0.135 pp. Dispersion raises both the
price of risk and the incidence of default. It does not, at this calibration,
produce a general precautionary borrowing response.

R2 writes that a small pure-uncertainty effect would be a fine answer provided
the reader learns why volatility matters. We think that is where we have landed.

We are grateful for the comment. It cost us a headline claim and improved the
paper.

---

### Suggested manuscript wording

> We separate the dispersion and expected-price components of time-varying
> oil-price volatility using a one-step mean-preserving adjustment. The total
> effect of time-varying volatility on average spreads is 13.4 basis points
> (95% interval ±6.0), of which the decomposition attributes 12.1 to the
> expected-price channel and 1.3 to dispersion. Because the adjustment is exact
> only at one step and overshoots at the horizons relevant for pricing
> long-term debt, we treat the first figure as an upper bound and the second as
> a lower bound rather than as a measured split. The same decomposition in
> annual default probabilities gives +1.68 percentage points for the level
> channel and +0.11 for time-varying volatility, the latter inside its Poisson
> interval. The conditional evidence is sharper: in the mean-preserving
> economy, where expected prices are flat by construction, mean spreads rise
> monotonically by 47 basis points and the annual default probability rises
> from 2.19% to 5.13% from the calmest to the most volatile state while the
> mean oil price falls, against placebo noise floors of 0.8 basis points and
> 0.135 percentage points. Borrowing responses are
> heterogeneous: volatility-induced debt reductions are three to five times
> less common once the expected-price channel is removed, but they do not
> disappear.

### Technical notes

The four economies — full SV, mean-preserving SV, constant volatility and
constant price — give mean spreads of 407.9, 395.9, 394.6 and 207.3 bp
(standard errors 2.2, 2.1, 2.2, 1.1) and annual default probabilities of 3.345,
3.258, 3.232 and 1.666% (standard errors 0.043, 0.043, 0.043, 0.030) on
debt/GDP of 34.30, 34.10, 33.94 and 36.81%, over 1529, 1549, 1548 and 1226
qualifying episodes. Spread and debt figures use the Table 3 convention of
averaging over hundred-quarter pre-default windows. Default probabilities are
computed over the whole simulation rather than those windows: the numerator
counts default quarters, the denominator quarters in good standing, since a
country already excluded cannot default. The quarterly rate is annualised as
1 − (1 − q)⁴ and the interval is Poisson.

The by-volatility tables pool the whole simulation by realised volatility
state, not by episode window, and are therefore a different statistic from the
economy means above; the constant-volatility economy appears in them as a
placebo, and its 0.8 bp and 0.135 pp ranges across five economically identical
states are the noise floors quoted in the text. The spread table is
`table2_by_volatility.csv` and the default table
`table4_default_by_volatility.csv`. The latter rests on 245 to 1,984 default
events per cell in the full economy and 269 to 1,967 in the mean-preserving
one, so the conditional result is not a small-sample artifact.

The debt-grid counts cover nodes between 10.06% and 50.28% of reference annual
value added at median endowment, keeping only states that repay at both volatility
extremes, and are equal-weight counts rather than stationary probabilities. The
second price is 1.1058× the baseline.

Calibration: σ_oil = 0.25 (`theta = −3.0`, `alpha = 5.779464e-5`), `beta =
0.971528`, `d1 = 0.468175`, `d0 = −0.246`, on the common 277-node price grid
with the oil price process estimated on 1995Q1–2019Q4. The choice of elasticity
is a judgement call: `beta` and `d1` are recalibrated to hit the spread and
debt targets at each elasticity, so the targets do not select it. A sensitivity
table across six elasticities is in `model/src_spdebt/README.md`. The
dispersion component is not stable across them — it ranges from +8.6 to
−22.1 bp — and at σ_oil = 0.40 the dispersion and expected-price components
are −22.1 and +23.3 bp, cancelling to a total of +1.2. That instability is the
same overshoot described above, and is a further reason we report the total
rather than the split.

Every number in this response comes from `model/economies_common_check/`, the
four-economy set of record: one standalone Fortran source per economy, with no
configuration switches, solved independently on the common 277-node price
grid. The four sources differ from one another by two lines each at most
(`std_u_p`, `std_u_vol`, `p_num`, `p_vol_num`), and the mean-preserving economy
differs from the benchmark by exactly one, the drift written inline. That set
was solved from scratch as a replication of an earlier run, and all 140 solver
output files — 35 per economy — are byte-identical to it, so the solve is
deterministic and reproduces exactly.

The tables are produced by `model/analysis/decomposition.py` and are archived
in `model/economies_common_check/decomposition/`; the horizon profile by
`model/analysis/JEDC_decomposition.m`; the figure by the same file. No solver settings or convergence
criteria were changed in preparing this response.

**Not re-measured at this calibration:** the fixed-state spread comparison that
an earlier draft reported (37 and 51 bp at a representative debt and endowment
node). The script that produces it requires numpy, which is not installed in
the current environment. The by-volatility table above answers the same
question with a larger sample and is what the text now relies on.
