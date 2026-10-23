# Response to Referees — *Oil Price Uncertainty and Sovereign Spreads of Oil Importers*

**Status: DRAFT for the authors.** Everything below is reproducible from this repository.
Items are marked ✅ addressed, ◐ partially addressed, ○ not yet started. Several results
**change the paper's conclusions**; those are flagged explicitly rather than smoothed over.

---

## Summary for the editor

We thank both referees. Their lead comment — that our "uncertainty" effect conflates a
genuine second-moment channel with the mechanical first-moment effect of variance on the
conditional mean of a log-normal price — is correct, and acting on it turned out to be
more consequential than we expected.

In implementing the decomposition we discovered that our price process was **discretised
on a volatility-specific grid**, so a given price index corresponded to a *different*
physical price in each volatility state. A volatility shock therefore rescaled the price
*level*, not only its dispersion. This was not the process written in the paper. Correcting
it, and then performing the decomposition the referees requested, we find:

> **Time-varying oil price volatility raises mean spreads by 22.6 bp (+5.8%). Of this,
> +26.1 bp is the pure dispersion channel and −3.5 bp the expected-price (Jensen)
> channel. The genuine uncertainty channel accounts for essentially the whole effect; the
> mechanical Jensen term is negligible.**

This *supports* the paper's mechanism. Report 2 asked whether the effect is uncertainty or
arithmetic; on the corrected process it is uncertainty.

---

## Part A — Both reports' lead comment: the mean-preserving decomposition

> **R1 Major 2 / R2 Major 1.** Separate the pure volatility effect from the
> volatility-induced increase in expected oil prices.

### ✅ A.1 Implementation

We implement exactly the specification both reports propose,

```
log p_t − p̄ = ρ_p (log p_{t−1} − p̄) − ½[v_t − v₀] + e^{σ_t} u_t
```

with `v₀ = E[v]`, the **average** innovation variance of the stochastic-volatility process
(not `e^{2μ}`). We use E[v] so that the comparison economies hold the average quantity of
price risk fixed; this differs from the literal expression in R1 Major 2 and we flag it.

Two implementation points matter and are easy to get wrong:

1. The correction must enter the **conditional** mean. Folding it into the process mean
   delivers only `(1 − ρ_p)` of it — **2%** at ρ_p = 0.98.
2. It must be applied on a **common** price grid, or it corrects a term worth 0.089% while
   leaving a grid artifact worth tens of percent untouched (Part B). The grid must also be
   **wide enough**: a grid spanning only ±3 SDs truncates the high-volatility states and
   reverses the sign of the decomposition (see A.3).

**Validation** (Table 4, Figure D panel a): `E[p_{t+1} | p, σ]` swings **+0.0894%** across
volatility states in the full model and **−0.0000%** after the correction.

### ✅ A.2 The decomposition

Four economies, all on the **same** physical price grid (549 nodes, ±6 sd, prices
[0.644, 1.973]), all with the **same** average innovation variance, all driven by the
**same** shocks:

| economy | mean spread (bp) | sd spread | default rate (%) | mean debt |
|---|---|---|---|---|
| full SV | 411.2 | 219.3 | 3.420 | 6.381 |
| mean-preserving SV | 414.7 | 223.6 | 3.382 | 6.392 |
| constant volatility | 388.6 | 200.5 | 3.197 | 6.425 |
| constant price | 391.4 | 256.8 | 3.114 | 6.545 |

*(Table 1. The constant-price economy fixes p at **E[p] = 1.1324**, the mean, not the
median `exp(p̄) = 1.1275` — this is R2 Major 2, addressed in Part C.)*

**Decomposition (Table 3, Figure D panel c):**

| channel | spread (bp) | default (pp) | mean debt |
|---|---|---|---|
| **TOTAL** — time-varying volatility (full − constant vol) | **+22.6** | +0.222 | −0.044 |
| of which **pure dispersion** (mean-preserving − constant vol) | **+26.1** | +0.185 | −0.033 |
| of which **expected-price (mean)** (full − mean-preserving) | **−3.5** | +0.037 | −0.011 |
| oil price variation at all (constant vol − constant price) | −2.8 | +0.084 | — |

Base spread in the constant-volatility economy is 388.6 bp, so the total effect is **+5.8%**.

### A.3 Interpretation

The pure dispersion channel accounts for **more than the whole** total effect, and the
mechanical Jensen term is small and slightly negative. So the draft's central claim —
that *uncertainty* about oil prices, not merely their expected level, raises sovereign
spreads — survives the decomposition the referees asked for.

**An earlier version of this response reported the opposite** (mean channel +43.8, dispersion
−31.2). That was computed on a price grid spanning only ±3 unconditional SDs, which
truncated the high-volatility states — precisely the states whose price distributions
extend furthest, and therefore precisely where the dispersion channel operates. On a grid
spanning ±6 SDs, matching the reach of the submitted per-state grids, the sign reverses.
The lesson is that the grid width is not a numerical detail here: it determines which
channel the decomposition attributes the effect to.

### ✅ A.4 Does precautionary borrowing survive? (R1 Major 2, second part)

> *"Once this mean effect is removed, any remaining increase in borrowing would reflect a
> precautionary response to greater oil price risk itself."*

**No — the sign reverses.** On the corrected grid the pure dispersion channel *lowers*
mean debt by **−0.0334**, and the mean channel lowers it by a further −0.0107. Isolated
oil-price risk therefore induces precautionary **saving**, not the precautionary borrowing
emphasised in Section 6.3.

Two caveats, both pointing the same way. First, Part B.3 shows the *cross-state* version
of the borrowing claim is inside the simulation noise floor. Second, these are
cross-economy differences in ergodic means, which are far better identified than the
cross-state comparison but are still small relative to the level of debt (≈0.5%).
Section 6.3 needs a policy-function or impulse-response design at fixed (b, y) before any
version of the claim can be sustained.

### ◐ A.5 Caveat: the correction is exact only at one step

With ρ_p < 1, conditional variance accumulates at ρ² while the drift correction accumulates
at ρ, so exact cancellation requires ρ_p = 1. Since δ = 0.03 implies a bond duration near
25 quarters, long horizons are what price the bond (Table 5, Figure D panel d):

| horizon (quarters) | full SV swing | mean-preserving residual |
|---|---|---|
| 1 | +0.048% | **−0.0000%** |
| 4 | +0.098% | −0.004% |
| 20 | +0.062% | −0.027% |
| 40 | +0.026% | −0.033% |

The correction slightly **overshoots** at long horizons. The residual is about one third of
the full model's peak swing, and opposite in sign. We report this rather than leave it to
be discovered.

---

## Part B — A discretisation defect that affects the headline result

This was not raised by either referee. We report it because it materially affects
Figure 3 and the paper's central quantitative claim.

### ✅ B.1 The defect

The submitted code builds a **separate price grid for each volatility state**, with
half-width scaling in `e^{σ}`. The implemented process is therefore

```
log p_t = p̄ + ψ(σ_t)·z_t ,   ψ(σ) = √(n−1)·e^{σ}/√(1−ρ_p²)
```

not the paper's `log p_t − p̄ = ρ_p(log p_{t−1} − p̄) + e^{σ_t}u_t`. Volatility rescales the
price **level**. Verified: the Rouwenhorst transition matrix is **identical** across
volatility states (max difference 0.0) — all volatility dependence runs through grid width.

Consequences: the price state space moves with σ (in the submitted calibration a price of
1.90 exists only in the highest volatility state), and "high price, low volatility" is not
representable.

### ✅ B.2 The reported 3× state-dependence is a measurement artifact

Our setup first **reproduces** the published result: using the paper's own definition
(i_b = 44, nodes 2 and 6, median endowment), slopes are 0.0108 / 0.0224 / 0.0322 across
volatility states 2/3/4 — a **ratio of 2.99**.

But the slope divides by a `dprice` held fixed at the **vol-3** grid, while nodes 2 and 6
span a volatility-*dependent* price interval:

| vol state | price interval spanned | reported slope | per **actual** price unit |
|---|---|---|---|
| 2 | 0.136 (1.00×) | 0.0108 | 193.8 bp |
| 3 | 0.244 (1.80×) | 0.0224 | 224.2 bp |
| 4 | 0.440 (3.24×) | 0.0322 | 178.5 bp |

**Ratio of price intervals 3.24; ratio of reported slopes 2.99.** Normalising by the
interval actually traversed leaves 194 / 224 / 179 bp — no monotone pattern in volatility.

The statistic is also fragile. The 3× occurs at one debt index (neighbours give 0.47,
−0.05, −0.84, 0.09), and OLS over all seven price nodes reverses the ordering
(0.067 / 0.036 / 0.025). On a balanced non-default sample the vol-5/vol-1 ratio is negative
or near zero at every debt index under both estimators.

### ✅ B.3 A placebo for the cross-state results

The constant-volatility economy retains five volatility *indices* that are economically
identical, so any variation across them is pure simulation noise. This gives a noise floor
(Table 2):

| range across the 5 states | placebo (noise) | full SV (signal) |
|---|---|---|
| mean spread | 2.3 bp | 7.7 bp, and **falling** in volatility |
| default rate | 0.199 pp | 0.210 pp |
| mean debt | 0.034 | **0.024** |

**The default-rate and mean-debt patterns across volatility states lie inside the noise
floor.** Section 6.3's precautionary-borrowing result, as currently measured, is not
identified; it needs a policy-function or impulse-response design at fixed (b, y). The
decomposition in Part A is unaffected — it differences ergodic means across economies
driven by the same 750,000 shocks, so common sampling error cancels.

---

## Part C — Remaining comments

### ✅ C.1 R2 Major 2 — welfare comparisons mix less risk with cheaper oil

Correct. The submitted basic economy fixes the price at `exp(p̄) = 1.1275`, the **median**
of the log-normal. All comparison economies now share (i) the same physical price grid,
(ii) the same average innovation variance E[v], and (iii) a constant-price economy set at
**E[p] = 1.1324**, the mean. The ladder no longer confounds risk with the price level.

### ✅ C.2 R1 Major 3 — discipline the substitution elasticity

We estimate it from our own panel. The CES optimal-oil conditions imply
`s(p) = α^σ p^{1−σ}`, so the share's price elasticity identifies σ directly:
`d ln s / d ln p = 1 − σ`. Using the `import_gdp` panel (34 oil importers, 1995–2015,
660 observations):

| specification | coefficient | s.e. | implied σ |
|---|---|---|---|
| within country, clustered by year | **+0.606** | 0.083 | **0.394** |
| collapsed to a time series | +0.627 | | 0.373 |
| collapsed, with linear trend | +0.958 | | 0.043 |
| first differences within country | +0.836 | 0.133 | 0.164 |

All four are positive and strongly significant. **σ = 2 predicts −1 and is rejected**;
σ = 1 is also rejected. 95% CI for σ: **[0.23, 0.56]**. Oil and the domestic input are
**complements**, not substitutes. Standard errors cluster on **year**, since the regressor
is the global oil price, common across the cross-section within a year.

*Caveat:* the sign flips to −0.33 if oil **exporters** are retained, so the importer sample
definition is doing real work and must be stated explicitly.

The same data gives a calibration target: the importer-sample mean oil import share is
**3.74%** of GDP (median 2.59%), against **7.99%** implied by α = 0.3, θ = 0.5.

An **independent** argument against σ = 2, from the model's own internals: with a
realistically volatile oil price, σ = 2 implies an oil import share of **76% of output** at
the low end of the price grid, because strong substitutability pulls the firm into enormous
oil use when oil is cheap. The submitted model never reaches that region only because its
calibrated oil price volatility is roughly an order of magnitude too small (Part C.3).

### ◐ C.3 Volatility calibration — a convention check we could not close

Re-running our own `svsample(log real price, designmatrix="ar1")` reproduces the Table 2
parameters and identifies their provenance:

| Fortran | value | matches | status |
|---|---|---|---|
| `rho_p` | 0.98 | `beta_1 = 0.9763` | ✅ |
| `mean_p` | 0.12 | `beta_0 = 0.1176` | ⚠️ that is the **intercept**, not the unconditional mean |
| `mean_p_vol` | −4.33 | `mu = −4.3317` | ⚠️ `mu` is the mean of log **variance** |
| `rho_p_vol` | 0.66 | `phi = 0.6779` | ✅ |
| `eta` | 0.44 | `sigma = 0.4460` **under the commented-out priors** | ❌ different estimation |

`stochvol` parameterises `y_t = exp(h_t/2)·ε_t`, so `h` is the log *variance* and
σ = exp(h/2). If the code applies σ = exp(h), implied quarterly innovation volatility is
1.3% rather than 11.5%, and the unconditional sd of log p is 6.6% against **48.5%** in the
data. We flag this for verification against the authors' own estimation output; it is the
single most consequential open item, because the Jensen term dominating Part A is a direct
consequence of σ being small.

### ○ C.4 Not yet addressed

- R1 Major 1a — expectations evidence from futures / Consensus Forecasts
- R1 Major 1b, R2 Major 5 — state-dependence tests in the panel (interactions)
- R1 Major 1c — two-way clustering by country **and** quarter
- R1 Major 5 — risk-averse lenders / exogenous SDF
- R2 Major 3 — oil import disruption during default
- R2 Major 4 — novelty framing vs Lopez-Martin et al. (2019)
- R2 Minor 2 — oil moments in Table 3
- R1 Minor 1, 2, 3; R2 Minor 1 — terminology, y vs x, exchange rate, notation
- R1 Minor 4 / R2 Minor 1 — **confirmed**: the elasticity is 1/(1−θ), not 1/θ. Text fix.

---

## Figures and tables

| file | contents |
|---|---|
| `FIGURE_decomposition.jpg` | **new.** (a) mean channel and its removal; (b) spread by economy; (c) channel decomposition; (d) mean preservation by horizon |
| `table1_economies.csv` | four economies: spread, sd, default rate, debt, price |
| `table2_by_volatility_state.csv` | the same by volatility state, including the placebo |
| `table3_decomposition.csv` | the channel decomposition |
| `table4_expected_price_by_volatility.csv` | E[p'|σ], full vs mean-preserving |
| `table5_horizon_mean_preservation.csv` | 40-quarter horizon check |
| `table6_configuration.csv` | grid and calibration provenance |

**Figures 2–7 on the corrected model are not yet regenerated.** The plotting pipeline is
validated — run on the submitted outputs it reproduces all ten published figures
**pixel-identically** — but at 277 price nodes a single economy has not completed. Two
causes were found and fixed (ASCII `load` replaced by `textscan`; eight arrays in the
4-deep fill loop were never preallocated, making it O(n²)), both verified output-neutral
against the published figures. A third bottleneck remains under investigation.

---

## Reproducibility

Everything is in the repository. The submitted version is tagged `submitted-baseline`.
`REVISION_NOTES.md` records the full working history, including defects found in the
submitted code and their verification. Key switches in `model/oil_prod_CES.f90`:
`use_common_p_grid`, `mean_preserving`, `p_width_sd`, `p_vol_width_sd`.
