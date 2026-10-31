# Response to Referees — *Oil Price Uncertainty and Sovereign Spreads of Oil Importers*

**DRAFT for the authors.** Supersedes `RESPONSE_TO_REFEREES.md`, which reports
the decomposition on a grid we have since replaced, omits R1 Major 4 and R2
Major 6 entirely, and lists as "not started" two exercises that were in fact
completed. Every number here is reproducible from this repository; §10 says
with what.

All quantitative results are at the calibration in `model/src_spdebt/`:
σ_oil = 0.30, value-added default cost, one common price grid at 277 nodes,
risk-neutral pricing. Where a number comes from a different version we say so.

---

## Summary for the editor

We thank both referees. Their shared lead comment — that our "uncertainty"
effect conflates a genuine second-moment channel with the mechanical
first-moment effect of variance on the conditional mean of a log-normal price —
is correct, and acting on it changed the paper.

Three things came out of this revision.

**First, the decomposition the referees asked for can be done cleanly, and it
does not support the paper as written.** On the corrected process, oil price
risk raises mean spreads by **218.9 bp (95% CI ±6.5)**. But the *time variation*
in that risk contributes **+6.3 bp (±8.7)**, and neither of its two components
— pure dispersion **+3.0 (±8.8)** and the expected-price channel **+3.3 (±8.9)**
— is separately identified. We now state this plainly: oil price *risk* matters
enormously for importers' spreads; time variation in it does not separately.
R2 anticipated this outcome and wrote that a small pure-uncertainty effect is
acceptable provided the reader learns why volatility matters. We think that is
the honest reading and we have rewritten the paper around it.

**Second, implementing the referees' exercises surfaced defects in the
submitted code that materially affect the headline numbers.** The price process
was discretised on a volatility-specific grid, so volatility rescaled the price
*level* rather than only its dispersion; the reported 3× state dependence in
Figure 3 is a measurement artifact of dividing volatility-dependent price
intervals by a single denominator; Figure 4(d)'s published rise is the grid
nodes rather than economics; and the Figure 7 welfare formula had a sign error.
We report all four as findings (§6) rather than defend the original numbers.

**Third, R2's Major 3 produced our single largest improvement, by failing.** We
implemented the oil-import disruption the referee suggested; it weakens the
paper's own mechanism and at moderate parameters reverses its sign. Diagnosing
why identified the fix: the default penalty must *fall* when oil is dear. Basing
it on value added rather than the endowment raises the oil price's effect on
spreads roughly tenfold, and it is also exactly the robustness exercise R1 asked
for in Minor 2 (§4).

---

## 1. Both reports' lead comment: the mean-preserving decomposition

> **R1 Major 2 / R2 Major 1.** Separate the pure volatility effect from the
> volatility-induced increase in expected oil prices.

### 1.1 What we implemented

We implement the specification both reports propose,

```
log p_t − p̄ = ρ_p (log p_{t−1} − p̄) − ½[v_t − v₀] + e^{σ_t} u_t
```

with **v₀ = E[v]**, the average innovation variance of the stochastic-volatility
process, rather than the literal e^{2μ} in R1's expression. We use E[v] so the
comparison economies hold the *average* quantity of price risk fixed; this is a
deliberate departure and we flag it.

Two implementation points matter and are easy to get wrong. The correction must
enter the **conditional** mean — folding it into the process mean delivers only
(1 − ρ_p) of it, which is 2% at ρ_p = 0.98. And it must be applied on a
**common** price grid, wide enough to contain the high-volatility states. On a
grid spanning only ±3 unconditional standard deviations the high-volatility
tails are truncated — precisely where a mean-preserving spread puts its extra
mass — and the decomposition **reverses sign**. An earlier draft of this
response reported the opposite result for exactly that reason. Grid width is not
a numerical detail for this statistic; it determines the answer.

### 1.2 Validation — Figure D(a)

The object the referees ask about is the conditional mean of the next period's
price *level*, E[p′ | p, σ]. We read it from the solver's transition matrix at
the central price node:

| volatility state | sd(log p) | full SV | mean-preserving | closed form e^{v/2} |
|---|---|---|---|---|
| 1 | 0.0639 | 1.12981194 | 1.13635543 | 1.12979999 |
| 2 | 0.0856 | 1.13164910 | 1.13635543 | 1.13163713 |
| 3 | 0.1147 | 1.13495653 | 1.13635543 | 1.13494453 |
| 4 | 0.1538 | 1.14092166 | 1.13635543 | 1.14090959 |
| 5 | 0.2061 | 1.15171513 | 1.13635543 | 1.15170295 |
| | **swing** | **+1.9387%** | **+0.0000%** | **+1.9387%** |

Two things to note. The full model's conditional expected price rises **+1.94%**
from the calmest to the most volatile state — and matches the closed-form
log-normal prediction e^{v/2} to five decimal places, so the discretisation is
fine enough to carry the effect in question. After the correction the expected
price is **1.13635543 in all five states**, identical to eight decimals.

### 1.3 Table 1 — the four economies

All on the same physical price grid, with the same average innovation variance,
driven by the same shocks.

| economy | mean spread (bp) | s.e. | sd spread (bp) | debt/GDP (%) | oil/GDP (%) |
|---|---|---|---|---|---|
| full SV | 409.0 | 3.2 | 362.5 | 34.05 | 8.92 |
| mean-preserving SV | 405.7 | 3.3 | 354.7 | 33.89 | 9.01 |
| constant volatility | 402.7 | 3.1 | 359.5 | 33.46 | 9.06 |
| constant price | 190.1 | 0.9 | 108.2 | 33.21 | 11.02 |

### 1.4 Table 2 — the decomposition, with intervals

| channel | spread (bp) | 95% CI | identified? |
|---|---|---|---|
| **oil price risk at all** (full − constant price) | **+218.9** | ±6.5 | **yes** |
| time-varying volatility, TOTAL (full − constant vol) | +6.3 | ±8.7 | no |
| of which **pure dispersion** (mean-preserving − constant vol) | +3.0 | ±8.8 | no |
| of which **expected price** (full − mean-preserving) | +3.3 | ±8.9 | no |

Intervals are 1.96 × the standard error of the difference, computed across
default episodes. We report them because without them the reader cannot tell
that three of these four rows are indistinguishable from zero.

### 1.5 Table 3 — a placebo for the cross-state comparisons

The constant-volatility economy retains five volatility *indices* that are
economically identical, so any variation across them is pure simulation noise.
The range of its mean spread across those five states is **1.9 bp**. That is the
benchmark for cross-state claims such as Section 6.3's.

A caution we state explicitly because it is easy to misread: this placebo range
is computed on **per-observation** means over all 750,000 observations, while
the intervals in Table 2 come from **episode-window** standard errors over
roughly 1,470 default episodes. They are different statistics on different
effective samples and should not be compared with one another.

### 1.6 Interpretation

The decomposition is clean and the correction is exact. What it shows is that
on our corrected process, the effect of *time variation* in oil price volatility
is small and not separately identified, and neither is its split into dispersion
and expected-price components.

What is large, precisely estimated and robust across every calibration we have
examined is the effect of oil price risk itself: **+218.9 bp**, a factor of
thirty larger than the time-variation channel and more than thirty times its own
standard error.

We have therefore reframed the paper around oil price *risk* rather than
oil price *uncertainty* in the volatility-shock sense, and we follow R1 Minor 1
in using "volatility" rather than "uncertainty" throughout.

### 1.7 Caveat: the correction is exact only at one step

With ρ_p < 1, conditional variance accumulates at ρ² while the drift correction
accumulates at ρ, so exact cancellation requires ρ_p = 1. Since δ = 0.03 implies
a bond duration near 25 quarters, long horizons are what price the bond. The
correction slightly **overshoots** at long horizons; on the previous version the
40-quarter residual was about one third of the full model's peak swing and
opposite in sign. We report this rather than leave it to be found.

### 1.8 Does precautionary borrowing survive? (R1 Major 2, second part)

> *"Once this mean effect is removed, any remaining increase in borrowing would
> reflect a precautionary response to greater oil price risk itself."*

**No.** On the corrected grid the pure dispersion channel *lowers* mean debt, so
isolated oil price risk induces precautionary **saving**, not the borrowing
emphasised in Section 6.3. Separately, the cross-state version of the claim lies
inside the placebo noise floor of §1.5 and is therefore not identified as
currently measured.

We have removed the precautionary-borrowing claim from the paper. Establishing
it would need a policy-function or impulse-response design at fixed (b, y),
which we regard as a separate exercise.

---

## 2. R2 Major 2 — the welfare comparisons mix less risk with cheaper oil

> The comparison economies do not face the same average oil price.

**Correct, and now fixed.** The submitted basic economy fixed the price at
exp(p̄) ≈ 1.13, the *median* of the log-normal, not its mean, so the full economy
paid more for oil on average. All comparison economies now share (i) the same
physical price grid, (ii) the same average innovation variance E[v], and (iii) a
constant-price economy pinned at the benchmark's simulated ergodic **mean**
price. All four economies agree on E[p] to within 0.06%.

The ladder in Table 1 therefore no longer confounds risk with the price level.

Welfare, consumption equivalent, across the 21 output states at mean debt:

| | this version |
|---|---|
| removing all oil price risk — mean | **+0.177%** |
| — peak | **+0.220%** |
| — minimum | **+0.040%** |
| removing time-varying volatility — mean | −0.008% |

Two notes. The peak now clears the lower end of the range claimed in the
submitted paper. And removing oil price risk is a welfare *gain* at every output
state; in the previous calibration it was a loss at the three lowest, which was
difficult to interpret. The time-varying-volatility figure is negligible and its
sign is not robust — consistent with that channel not being identified in
Table 2, we do not interpret it.

---

## 3. R1 Major 3 — discipline the substitution elasticity

> Provide sensitivity analysis and, if possible, discipline the elasticity using
> evidence on energy demand or imported-input substitution.

**Done, and the parameter changed.** The CES optimal-oil condition implies
s(p) = α^σ p^{1−σ}, so the oil share's price elasticity identifies σ directly:
d ln s / d ln p = 1 − σ. Using our own `import_gdp` panel (34 oil importers,
1995–2015, 660 observations):

| specification | coefficient | s.e. | implied σ |
|---|---|---|---|
| within country, clustered by year | **+0.606** | 0.083 | **0.394** |
| collapsed to a time series | +0.627 | | 0.373 |
| collapsed, with linear trend | +0.958 | | 0.043 |
| first differences within country | +0.836 | 0.133 | 0.164 |

All four are positive and strongly significant. **σ = 2 predicts −1 and is
rejected**; σ = 1 is also rejected. The 95% interval for σ is **[0.23, 0.56]**.
Oil and the domestic input are **complements**, not substitutes. Standard errors
cluster on year, since the regressor is the global oil price and is common
across the cross-section within a year.

*Caveat, stated because it matters:* the sign flips if oil **exporters** are
retained, so the importer sample definition does real work and we now state it
explicitly.

The same data gives a calibration target: the importer-sample mean oil import
share is **3.74%** of GDP, against **7.99%** implied by the submitted α = 0.3,
θ = 0.5.

We have recalibrated to σ_oil = 0.30 accordingly. A sensitivity sweep across
σ_oil ∈ [0.3, 2.0] is reported in `results/ELASTICITY_SWEEP.md`.

An **independent** argument against σ = 2, from the model's own internals: with
a realistically volatile oil price, σ = 2 implies an oil import share of 76% of
output at the low end of the price grid, because strong substitutability pulls
the firm into enormous oil use when oil is cheap. The submitted model never
reaches that region only because its calibrated oil price volatility was roughly
an order of magnitude too small (§6.4).

**Still open:** the referee also asks us to discuss the implications of imposing
a common elasticity across 35 heterogeneous economies. We have not done this.

---

## 4. R2 Major 3 and R1 Minor 2 — the default cost

> **R2 Major 3.** In the model a country in default keeps importing oil at the
> world price with no friction. Consider a robustness exercise in which default
> also disrupts oil imports.
>
> **R1 Minor 2.** Default costs are tied to the exogenous endowment while oil
> price shocks affect repayment capacity through endogenous production. A
> robustness exercise in which default costs depend on total output or total
> resources would help.

These two comments turned out to be the same comment, and answering them
produced the largest single improvement in the paper.

### 4.1 We implemented R2's suggestion literally, and it fails

While in default the country pays p(1 + κ) for imported oil — the Mendoza–Yue
channel the referee points at with the Sri Lanka example.

| κ | mean spread | debt/GDP | slope, vol 2 | vol 3 | vol 4 |
|---|---|---|---|---|---|
| 0 (baseline) | 3.99 | 33.4 | 0.00189 | 0.00180 | 0.00171 |
| 0.10 | 3.03 | 35.9 | 0.00030 | 0.00043 | 0.00049 |
| 0.25 | 3.28 | 41.2 | −0.00010 | 0.00014 | 0.00030 |
| 0.50 | 3.27 | 49.6 | −0.00048 | −0.00017 | 0.00005 |

Three things go wrong. The price-to-spread slope **collapses**, by a factor of
four to six at κ = 0.10, so a 20% oil price move shifts the spread by under one
basis point. At κ ≥ 0.25 the slope turns **negative** — a higher oil price
*lowers* an oil importer's spread, the opposite of the paper's premise. And
debt/GDP runs away to 49.6 against a 34.0 target, because a costlier default
sustains more debt.

### 4.2 Why it fails, and what the failure tells us

The premium makes default *more* painful exactly when oil is expensive: the
extra cost is κ·p·m, which rises with p. A higher oil price, which hurts the
importer and should push it toward default, simultaneously raises the penalty
for defaulting. The two offset, and past κ ≈ 0.2 the penalty dominates and the
sign reverses.

This diagnoses the fix. For an oil price rise to raise the spread more strongly,
the default cost must **fall** when oil is dear, so defaulting becomes
relatively more attractive precisely when the importer is squeezed.

### 4.3 The value-added default cost

We therefore base the penalty on **value added**, output net of the oil bill,
rather than on the endowment — which is exactly the robustness exercise R1 asks
for in Minor 2. Value added shrinks when oil is expensive, so the absolute cost
of defaulting shrinks with it.

This is a structural change rather than a parameter: value added is evaluated at
the no-default TFP, which makes it a two-pass calculation rather than a fixed
point, and it matches how default costs are normally described — a share of the
output the country would otherwise have produced. With the switch off, the
solver reproduces the previous baseline byte-identically, including the full
simulation dump.

**The oil price's effect on spreads rises roughly tenfold.** This is the
mechanism that carries the revised paper.

---

## 5. R1 Major 5 — risk-averse lenders

> The precautionary-borrowing result may depend on risk-neutral lenders. If
> feasible, a robustness exercise with an exogenous stochastic discount factor
> would be informative.

**Implemented and reported, with a negative result.** We add an exogenous
pricing kernel loading on the oil price innovation, normalised numerically on
the discrete grid so that E[m′] = exp(−r*) holds exactly for any grid — the
analytic continuous-state correction is *not* a substitute, and we document why
in `results/RISK_PREMIUM_AND_FIGURE3.md`.

| | κ = 0 | κ = 3 | κ = 5 |
|---|---|---|---|
| Figure 3 slope ratio (high/low volatility) | 0.621 | 0.830 | **1.199** |
| mean spread (target 4.1) | 4.41 | 6.48 | 5.61 |
| **debt/GDP (target 34.0)** | **33.69** | **18.06** | **8.11** |
| default episodes per 500k periods | 1423 | 395 | 95 |
| implied maximum annual Sharpe ratio | 0 | 0.75 | **1.25** |

The mechanism is real and points the right way — a risk premium loads more
heavily on high-volatility states and the ratio rises monotonically in κ. But
the ordering crosses only near κ = 4, where debt/GDP has fallen to 18% and then
8% against a 34% target, so the model no longer describes an indebted sovereign,
and the implied maximum Sharpe ratio of 1.25 a year is far beyond any empirical
benchmark.

**So the Figure 3 ordering is attainable but not at a calibration that also
matches Table 3.** We report this as a bound on what lender risk aversion can
deliver, and we have added the clarification the referee asks for: our
quantitative results are conditional on risk-neutral pricing.

We have **not** revisited the referee's actual question — whether precautionary
borrowing survives under risk-averse pricing — because §1.8 removes that claim
on other grounds.

---

## 6. Defects we found and corrected

Neither referee raised these. We report them because they materially affect the
published numbers.

### 6.1 The price grid was volatility-specific

The submitted code builds a **separate price grid for each volatility state**,
with half-width scaling in e^σ. The implemented process is therefore one in
which volatility rescales the price **level**, not the paper's process. The
Rouwenhorst transition matrix is *identical* across volatility states — all
volatility dependence ran through grid width. Consequences: the price state
space moves with σ, and "high price, low volatility" is not representable.

### 6.2 The reported 3× state dependence is a measurement artifact

Using the paper's own definition our setup first **reproduces** the published
result — slopes of 0.0108 / 0.0224 / 0.0322 across volatility states, a ratio of
**2.99**. But the slope divides by a price interval held fixed at the middle
volatility state, while the nodes used span a volatility-*dependent* interval:

| volatility state | price interval spanned | reported slope | per **actual** price unit |
|---|---|---|---|
| 2 | 0.136 (1.00×) | 0.0108 | 193.8 bp |
| 3 | 0.244 (1.80×) | 0.0224 | 224.2 bp |
| 4 | 0.440 (3.24×) | 0.0322 | 178.5 bp |

The ratio of price intervals is 3.24 and the ratio of reported slopes 2.99.
Normalising by the interval actually traversed leaves 194 / 224 / 179 bp — **no
monotone pattern in volatility**. The statistic is also fragile: the 3× occurs
at one debt index, and OLS over all price nodes reverses the ordering.

Measured correctly on the corrected model the ratio is **1.11**, monotone in
volatility at all 21 output states. We report the correction as a finding. There
was never a 3× to reproduce, and we have removed that claim.

### 6.3 Figure 4(d)'s published rise is the grid, not economics

The published +17% to +58% is the grid nodes themselves at a fixed price index.
The true Jensen lift under the corrected volatility is **+1.93%** (§1.2), and
the figure is flat across volatility under the mean-preserving correction, as it
should be.

### 6.4 Two further corrections

The volatility process applied σ = exp(h) where the estimation delivers
h as a log *variance*, i.e. σ = exp(h/2). Corrected, the model reproduces
quarterly oil price volatility of **14.63%** against **14.47%** in the data; the
submitted calibration implied 1.86%. And the Figure 7 welfare formula divided a
positive numerator by a negative value function, flipping the sign of a genuine
welfare gain, and multiplied by a scale factor that is not part of any welfare
measure. The consumption equivalent is λ = (V_a/V_f)^{1/(1−σ)} − 1.

We also note that the legend in the published Figure 7 labels its two curves the
wrong way round.

---

## 7. Calibration and fit

| moment | target | submitted | **this version** |
|---|---|---|---|
| mean spread (annual, %) | 4.1 | 4.1 | **4.09** |
| sd(spread) | 2.0 | 2.0 | 3.63 |
| debt/GDP (%) | 34.0 | 34.0 | **34.06** |
| oil/GDP (%) | 9.0 | 9.0 | **8.92** |

The submitted column is the paper's target, not an independent result.

**The one persistent miss is sd(spread), 81% above target.** We report it rather
than bury it. It is not a search failure: holding the default-cost intercept d0
at its submitted value, no combination of β and d1 brings the ratio
sd/spread below 0.886 against a data value of 0.488, and lowering sd further
only drags the mean spread down faster — at the extreme we examined, sd reaches
2.63 only when the mean spread has collapsed to 1.74 and debt/GDP to 26.1.
Matching sd requires d0 to turn **positive**, which makes the default penalty
positive everywhere rather than kinked, and we were not willing to adopt that
for a moment match.

The solution is grid-converged: a 549-node solve agrees with our 277-node
benchmark within 0.5% on every moment.

---

## 8. Comments not yet addressed

We list these plainly rather than imply coverage we do not have.

| comment | what it asks |
|---|---|
| **R1 Major 1a** | Expectations evidence from oil futures or Consensus Forecasts |
| **R1 Major 1b / R2 Major 5** | Panel analogues of the Figure 3 and Figure 5 state dependence — interactions with output, recessions and debt/GDP |
| **R1 Major 1c** | Two-way clustered standard errors, country and quarter |
| **R1 Major 4** | What is specifically "oil" about the mechanism; differentiation from Seoane (2019) and Johri–Khan–Sosa-Padilla (2022); whether the effect is stronger in more oil-dependent countries; a control for generic imported-input price volatility |
| **R1 Minor 3** | Interaction of oil shocks with exchange-rate depreciation or FX debt exposure |
| **R2 Major 4** | Soften the novelty claim; differentiate from Lopez-Martin et al. (2019), Hamann et al. (2018), Esquivel (2020) |
| **R2 Major 6** | Why the model's effect is far smaller than the panel's; estimate regression (1) on model-simulated data |
| **R2 Minor 2** | Oil-related moments in Table 3 |
| **R1 Major 3, part** | Implications of a common elasticity across 35 heterogeneous economies |

Two of these interact with results above and we flag the interaction rather than
leave it implicit. **R1 Major 1b and R2 Major 5** ask us to test the 3× state
dependence in the panel; §6.2 shows there was no 3× to test, so what we will
test is the corrected prediction. **R2 Major 6** observes that the model's
effect is far smaller than the panel's — and our recalibration *widens* that gap,
since the oil price risk channel falls from 286.0 bp at the previous calibration
to 218.9 bp here. We regard this as the most serious open item and address it
directly in the revision.

**R1 Minor 1** (use "volatility", not "uncertainty") and **R1 Minor 4 / R2 Minor
1** (the CES elasticity is 1/(1−θ), not 1/θ) are adopted. The bond-price
notation in R2 Minor 1, q(b′,y) against q(b′,y,p,σ), is corrected throughout.

---

## 9. Where this leaves the paper

The paper's claim that oil price risk raises sovereign spreads for oil importers
survives and is quantitatively stronger than in the submitted version: 218.9 bp
with a ±6.5 interval, against a submitted model whose oil channels were small
because its calibrated oil price volatility was an order of magnitude too low
and its default cost did not respond to oil prices at all.

What does not survive is the attribution of that effect to *time-varying*
volatility specifically, the 3× state dependence, and the precautionary-borrowing
mechanism. We report each as a correction, with the diagnosis in each case.

---

## 10. Reproducibility

Everything is in the repository.

| exhibit | produced by |
|---|---|
| Tables 1–3, Figure D data | `model/analysis/decomposition.py` |
| Figure D | `model/analysis/FIGURE_decomposition.m` |
| Table 3 moments (§7) | `model/analysis/moments_fast.py`, `MOMENTS.m` |
| the ten paper figures | `model/src_spdebt/ALL_FIGURES_common_grid.m` |
| welfare (§2) | `model/analysis/welfare_report.m` |
| Figure 2/3/4d claims (§6) | `model/analysis/claims_report.m` |
| solver, four economies | `model/src_spdebt/oil_prod_CES_*.f90` |

Supporting notes: `VERSION_COMPARISON.md` (this calibration against the
submitted paper), `REFEREE_TRACKING.md` (every comment against its status),
`VALUE_ADDED_DEFAULT_COST.md`, `OIL_DEPENDENT_DEFAULT_COST.md`,
`RISK_PREMIUM_AND_FIGURE3.md`, `ELASTICITY_SWEEP.md`, `WHY_OPPOSITE.md`.

Key switches in the solver: `va_default_cost`, `use_common_p_grid`,
`mean_preserving`, `constant_vol`, `kappa_risk`, `oil_disruption`.
