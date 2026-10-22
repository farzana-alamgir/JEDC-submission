# Revision Notes — *Oil Price Uncertainty and Sovereign Spreads of Oil Importers*

Working document tracking (1) what the two referees asked for, (2) what a review of this
repository turned up, and (3) the results of a deep analysis of the mean-preserving
decomposition request, which is the lead major comment in both reports.

Last updated: 2026-10-18

---

## Part 1 — Referee requirements

Two reports. They converge on the same core concern, which makes it the top revision priority.

### 1.1 Where both referees agree (must address)

| # | Requirement | Report 1 | Report 2 |
|---|---|---|---|
| A | **Separate the pure volatility (dispersion) effect from the volatility-induced rise in expected oil prices.** Under an AR(1)-in-logs with stochastic volatility, `E[p'] = exp(m + ½v)`, so a rise in conditional volatility mechanically raises the conditional *mean of the level*. Both propose the same fix: subtract `½Var(log p' \| σ)` from the conditional mean so `E[p'\|p,σ]` no longer varies with σ. | Major 2 | Major 1 |
| B | **Test the model's own state-dependent predictions in the panel.** Interact oil price changes with output conditions, debt-to-GDP, and country oil-import dependence. Report 2 adds: estimate the empirical specification on model-simulated data so coefficients are directly comparable. | Major 1b | Major 5, 6 |
| C | **Sharpen what is specifically "oil" about the mechanism.** Relative to Seoane (2019), Johri–Khan–Sosa-Padilla (2022), Lopez-Martin et al. (2019). Report 2 flags the novelty claim as overstated. | Major 4 | Major 4 |
| D | **CES elasticity notation error.** For `x = [(1−α)y^θ + αm^θ]^{1/θ}` the elasticity of substitution is `1/(1−θ)`, not `1/θ`. Both found this independently. Numerically invisible at θ = 0.5 (both equal 2), but the text and Table 2 need correcting. | Minor 4 | Minor 1 |

### 1.2 Report 1 only

- **Inference:** oil price change and volatility are common across countries within a quarter, but SEs are clustered by country only. Report two-way clustering by country **and** quarter (Major 1c).
- **Expectations evidence:** use oil futures or Consensus Forecasts to show higher volatility is associated with higher expected future oil prices (Major 1a).
- **Substitution elasticity:** central to the real-side transmission; provide sensitivity analysis over a plausible range and discipline it with evidence on energy demand / imported-input substitution. Discuss imposing a common elasticity across 35 heterogeneous economies (Major 3).
- **Risk-neutral lenders:** the precautionary-borrowing result in Section 6.3 is conditional on risk-neutral pricing. Discuss, or add an exogenous SDF / reduced-form global risk premium (Major 5).
- **Terminology:** use "oil price volatility" consistently, not "uncertainty" (Minor 1).
- **`y` vs `x`:** clarify exogenous endowment vs endogenous final output; default costs attach to `y` while oil shocks operate through `x`. Robustness with default costs on total output (Minor 2).
- **Exchange rate:** interact oil shocks with depreciation or FX-debt exposure (Minor 3).

### 1.3 Report 2 only

- **Default does not disrupt oil imports.** A country in default keeps buying oil at the world price frictionlessly; the only cost is `h(y)`. This sits badly against the paper's own Sri Lanka motivation and Mendoza–Yue (2012). Add a price wedge or partial exclusion during autarky (Major 3).
- **Welfare comparisons mix less risk with cheaper oil.** The basic model fixes price at `exp(p̄) ≈ 1.13`, the *median* of the log-normal, not the mean. Every rung of the full/intermediate/basic ladder changes the average price level alongside the risk. Part of the 4.0 / 3.1 / 2.5% spread ladder and the 1.1% welfare gain may be a price-level difference (Major 2).
- **Magnitude gap.** Model spread slopes imply 0.5–1.5bp per 10% oil price move; the Table 1 regressions imply 6–8bp at the mean spread. Discuss what governs the magnitude (Major 6).
- **Table 3 has no oil-related moment.** Add spread–oil correlation, oil import share volatility, model vs data default frequency (Minor 2).
- **Notation:** bond price written `q(b',y)` in eq. (4) and below eq. (8), but `q(b',y,p,σ)` in eq. (11) (Minor 1).

---

## Part 2 — Repository review

State at review time: single commit, clean tree, no README, no build script.

| Severity | Finding |
|---|---|
| High | **Missing input data.** `empirical/oil_empirical_quarterly_claude.R` reads `spread_data.xlsx`, `monthly_domestics.xlsx`, `global_monthly.xlsx` — none are in the repo. Only `oil_qtrly.xlsx` is present. The script fails at line 90; roughly the back half of the empirical analysis is not reproducible as shipped. |
| High | **Committed binary, no build script.** `model/oil_prod_CES` is a Mach-O arm64 executable. The only build guidance is a source comment (`gfortran -O3 -march=native oil_prod_CES.f90 -o oil_prod_CES`). Not runnable on Linux/x86 and no guarantee the binary matches the current source. |
| Medium | **Compiler artifacts tracked:** `param.mod`, `shared_types.mod`, `fort.6`. |
| Medium | **~209MB of regenerable output committed**, including `graphs_data_sim_dss.txt` at 153MB — over GitHub's 100MB limit, which blocked the initial push. Now gitignored and untracked; it exists only locally. |
| Medium | **No README.** Pipeline order (compile+run Fortran → `working_graphs_dec29.m` → R script), software versions, and required R packages (`stochvol`, `readxl`, `openxlsx`) are undocumented. |
| Low | Leftover Windows path in a source comment (`oil_prod_CES.f90:3`). |
| Low | Superseded parameter block left commented out (`oil_prod_CES.f90:27–30`). |
| Low | `working_graphs_dec29.m` uses legacy `load file.txt` command syntax for ~30 files with no path guard; requires being run from `model/`. |

---

## Part 3 — Deep analysis of the mean-preserving decomposition

All of this is read-only analysis of `model/oil_prod_CES.f90` and the solved grids it wrote
(`p_grid.txt`, `p_vol_grid.txt`, `graphs_trans_matrix_p.txt`, `graphs_trans_matrix_p_vol.txt`,
`graphs_pdf_p.txt`). No model code was modified.

**Bottom line: the decomposition cannot be run meaningfully on the current code.** Two issues
change what it would measure.

### 3.1 Finding A — the implemented price process is not the one in the paper

`discretize_AR` builds transitions with Rouwenhorst (`oil_prod_CES.f90:102`), and
`rouwenhorst_matrix(rho_ar, pi)` takes **only** `rho_ar`. The innovation variance never enters
the probabilities — it acts solely through the grid half-width at line 105,
`psi = sqrt(n-1)*sqrt(sigma_eta)`.

Verified numerically against the solved output:

```
max |T[k] - T[0]| across the five volatility states = 0.0
```

The transition matrix is **identical** in every volatility state. What the code implements is

```
log p_t = p̄ + ψ(σ_t)·z_t ,   ψ(σ_t) = √6·e^{σ_t}/√(1−ρ_p²)
```

with `z_t` a fixed, volatility-independent Rouwenhorst chain. Recursively:

```
log p_t − p̄ = ρ_p·(ψ(σ_t)/ψ(σ_{t−1}))·(log p_{t−1} − p̄) + ψ(σ_t)·ε_t
```

against the paper's `log p_t − p̄ = ρ_p(log p_{t−1} − p̄) + e^{σ_t}u_t`. The extra factor
`e^{σ_t − σ_{t−1}}` multiplies the **entire persistent component**, not just the innovation.
Volatility rescales the price *level*.

Grid half-widths and reachable price ranges (from `p_grid.txt`):

| vol state | σ | e^σ | ψ(σ) | reachable price range |
|---|---|---|---|---|
| 1 | −5.501 | 0.00408 | 0.0502 | [1.072, 1.186] |
| 2 | −4.916 | 0.00733 | 0.0902 | [1.030, 1.234] |
| 3 | −4.330 | 0.01317 | 0.1621 | [0.959, 1.326] |
| 4 | −3.744 | 0.02365 | 0.2911 | [0.843, 1.509] |
| 5 | −3.159 | 0.04248 | 0.5229 | [0.668, 1.902] |

Consequences:

- **The price state space moves with σ.** A price of 1.90 exists only in volatility state 5.
  "High oil price, low volatility" is not a representable state.
- **A pure volatility shock moves the price level.** Holding the price index fixed and moving σ
  from state 3 to state 5 multiplies the deviation by `e^{Δσ} = 3.23` — a 43% price jump in one
  quarter with no price innovation at all.
- The model therefore hard-wires "high oil price ⟺ high volatility," which is the comovement the
  paper interprets causally.

Conditional expected price, `E[p_{t+1} | price index, σ_t = k]` — the object behind Figure 4(d):

| price index | k=1 | k=3 | k=5 | change 1→5 |
|---|---|---|---|---|
| 1 | 1.0443 | 0.9580 | 0.7949 | −23.9% |
| 4 (mean) | 1.1275 | 1.1276 | 1.1280 | +0.05% |
| 7 | 1.2179 | 1.3297 | 1.6194 | +33.0% |

The simulation inherits this: `oil_prod_CES.f90:1568` draws the next price index from
`cdf_matrix_p(·,·,i_p_vol_current)` — built from the vol-independent Rouwenhorst matrix — and
`:1572` maps the index to a price through the *current* volatility state's grid.

### 3.2 Finding B — the term the referees asked to subtract is numerically negligible

Both referees prescribed subtracting `½[e^{2σ_t} − e^{2μ}]`. That is the right correction for the
process **as written in the paper**. Under the **current calibration** it is worth almost nothing:

| vol state | `½·e^{2σ}` (log points) |
|---|---|
| 1 | 0.0008% |
| 3 | 0.0087% |
| 5 | 0.0902% |

The entire one-step Jensen wedge from the lowest to the highest volatility state is **0.045%**,
against a grid-rescaling channel worth **tens of percent**.

> **Implication.** Implementing the referees' correction literally on the current code removes
> 0.045% and leaves the ~30–60% artifact in place. The exercise would report "the pure dispersion
> effect is essentially the whole effect" — a conclusion driven by a specification the referees
> never saw. Report 2 explicitly invites the answer "if the pure effect is small, that is fine";
> we would be returning the opposite answer for the wrong reason, and it would likely survive review.

### 3.3 Finding C — the volatility calibration (**re-estimated; provenance established**)

An earlier version of this section presented
`exp(−4.33) = (0.1147)² = [exp(−4.33/2)]²` as evidence for a convention error. **That was a
mistake and has been removed:** `exp(a) = [exp(a/2)]²` holds for any `a`, so it carries no
evidential weight. The section below replaces it with a direct re-estimation.

Re-running the script's own active specification — `svsample(log real price,
designmatrix="ar1")`, `set.seed(123)`, on `empirical/oil_qtrly.xlsx` (n=100, 1995Q1–2019Q4) —
reproduces the Fortran parameters closely enough to establish where each came from:

| Fortran | Value | Estimate it matches | Verdict |
|---|---|---|---|
| `rho_p` | 0.98 | `beta_1 = 0.9763` | ✅ correct |
| `mean_p` | 0.12 | `beta_0 = 0.1176` | ⚠️ that is the AR(1) **intercept**, not the unconditional mean |
| `mean_p_vol` | −4.33 | `mu = −4.3317` | ⚠️ `mu` is the mean of log **variance** `h` |
| `rho_p_vol` | 0.66 | `phi = 0.6779` | ✅ correct (persistence is scale-free) |
| `eta` | 0.44 | `sigma = 0.4460`, but **only under the commented-out priors** | ❌ different estimation |

Two distinct problems:

1. **Convention.** `stochvol` parameterizes `y_t = exp(h_t/2)·ε_t`, so `h` is the log *variance*
   and σ = exp(h/2). The Fortran applies σ = exp(h), i.e. it uses the variance where the
   standard deviation belongs. Implied quarterly innovation sd is 0.0132 (1.3%) instead of
   0.1147 (11.5%), and unconditional sd of log p is 6.6% instead of 57.7% — against 48.5% in
   the data.
2. **Incoherent mixing.** `eta = 0.44` matches `sigma` from the *commented-out* prior
   specification at `oil_empirical_quarterly_claude.R:49-50`
   (`priormu=c(-10,1), priorphi=c(20,1.1), priorsigma=0.1`). But that run returns
   `mu = −9.36` and `phi = 0.993`, nothing like −4.33 and 0.66. Under the default priors
   `sigma = 0.6647`. So the three volatility parameters appear to come from two different
   posteriors with incompatible priors.

`pprime = 3.97` is declared at line 23 and **never used anywhere**; 3.97 is the sample mean of
log real oil price (3.9689).

**Recommended values**, all from one estimation. Two equivalent options:

| | ρ_p | μ | ρ_σ | η | code change |
|---|---|---|---|---|---|
| A — keep `σ = exp(x)` | 0.976 | **−2.166** | 0.678 | **0.3323** | none (pure parameter swap) |
| B — use `σ = exp(h/2)` | 0.976 | −4.332 | 0.678 | 0.665 | change the exponent in 3 places |

p̄ is a *normalization*, not an estimate, and must be documented as such in Table 2.

Implied moments at the corrected calibration: E[σ] = 0.127 (data: 0.144 OLS residual sd);
unconditional sd of log p = 0.650 with ρ_p = 0.976, or 0.440 with the OLS ρ_p = 0.9475
(data: 0.485). For the constant-volatility economy, `v0 = E[v] = 0.0198` versus the
referee-literal `e^{2μ} = 0.0131` — a ratio of 1.51, so the choice of `v0` must be stated.

### 3.3a Consequence — the corrected calibration breaks the model (**confirmed by running it**)

Feeding the Option A values into the unmodified code fails at
`oil_prod_CES.f90:381`: `iterations exceeded at bisection`, `d_bi = 224.6`.

This is an **economic** boundary, not a numerical one. The oil-demand FOC solved at `:364`
admits an interior optimum only if

```
p > α^(1/θ)  =  0.3² = 0.09      (for θ > 0)
```

The corrected grid's lowest price is `e^{−3.0646} = 0.0466`, below the floor, where oil demand
is unbounded. Raising `mmax_global` cannot fix it. The old calibration's floor price was 0.668,
which is why it ran. The *high* end is harmless: as p → ∞, m → 0 and output tends to
`(1−α)^{1/θ}·A`.

| p | optimal m | oil bill p·m | vs `mmax_global = 100` |
|---|---|---|---|
| 0.047 | unbounded | — | no solution |
| 0.100 | 4410 | 441 | exceeds bracket |
| 0.129 | 290 | 37.4 | exceeds bracket |
| 0.200 | 36.5 | 7.3 | ok |
| 0.670 | 1.3 | 0.9 | ok |

With endowment `A ≈ 10`, p = 0.129 implies an oil bill of 3.7× GDP — so ρ_p = 0.9475 clears the
floor but is not economically credible.

Note also that Rouwenhorst sets the half-width as `psi = sqrt(n−1)·sd` (`:105`), so **adding
price nodes widens the grid**: n=7 spans ±2.45 sd, n=25 spans ±4.90. Refining `p_num` pushes the
lowest price further below the floor. Accuracy and feasibility cannot both be improved under
Rouwenhorst — an independent argument for a fixed common grid with Tauchen.

**This connects to Referee 1's Major 3.** θ = 0.5 implies an elasticity of substitution of
`1/(1−θ) = 2`, i.e. oil and the domestic input as strong *substitutes*; short-run evidence puts
it well below 1, i.e. θ < 0. With θ < 0 the pathology disappears entirely: `α·m^θ → 0` as
m → ∞, the bracket converges to `(1−α)^{1/θ}·A`, and `F(m) → +∞`, so a root always exists
(verified numerically at p = 0.047). A more realistic oil elasticity removes the numerical
failure and answers a referee at the same time.

### 3.4 Recommended order of operations

1. **Resolve Finding C.** Check Table 2 against `mean_p_vol = -4.33` and the R script's AR(1) fit
   on the `stochvol` output. Grid widths, the size of the Jensen term, and the model-vs-data
   magnitude gap are all conditional on this.
2. **Fix the grid representation.** Build one **common** log-price grid spanning
   `±m·√(E[e^{2σ}]/(1−ρ_p²))`, then compute σ-specific transition matrices *on that fixed grid*.
   Both `tauchen` (`:159`) and `discretize_AR` (`:61`) emit their own grid (`Z`/`z` are
   `intent(out)`); this needs a variant that accepts the grid as input. `p_num` must rise well
   above 7 — one grid now covers what five grids covered.
3. **Then** run the mean-preserving exercise, applying `−½[e^{2σ_l} − e^{2μ}]` inside the
   conditional mean. **Do not** implement it by passing an adjusted `mean_p` into `discretize_AR`:
   at line 109 (`z = z + mu`) that re-centers the whole grid and reintroduces the
   state-space-moves-with-σ problem.
4. Re-solve and compare against the benchmark. Expect the mean channel to be small once the grid
   artifact is removed — a fine and publishable answer.
5. While here, address Report 2 Major 2 by setting the basic economy's fixed price to the full
   model's unconditional *mean* level, not `exp(p̄)`.

### 3.5 Risk

Steps 1–2 are not robustness exercises; they will move the headline numbers. The 3× spread slope,
the 0.70-vs-0.16 debt slope, and the 1.1% welfare gain all lean on a vol→price-level channel that
is substantially a grid artifact, and Figure 4(d) may largely disappear.

The upside: if Finding C is confirmed, a correctly calibrated oil price volatility should generate
materially larger spread responses — which would *close* the magnitude gap in Report 2's Major 6
and turn a criticism into a result.

---

## Appendix — verified vs inferred

**Verified directly from code and solved output:**

- Rouwenhorst transitions are volatility-independent (`:102`; `max|T[k]−T[0]| = 0.0`).
- Price grids are σ-specific and centred on `mean_p = 0.12` (`p_grid.txt`).
- The implemented process is `log p = p̄ + ψ(σ_t)·z_t`.
- The price state space varies with σ; high-price/low-volatility is unrepresentable.
- One-step Jensen wedge is 0.0087% at the mean volatility state under the current calibration.
- σ = exp(−4.33) = 0.0132; unconditional sd of log p = 0.066.
- The simulation reproduces the same index→grid mapping (`:1568`, `:1572`).

**Inferred, requires the author to confirm:**

- Finding C's **provenance** is now established by re-estimation (§3.3), but confirmation against
  the paper's Table 2 is still outstanding — the manuscript PDF could not be read on this machine.
  The `eta = 0.44` attribution rests on a numerical match to the commented-out prior
  specification; confirm against whatever estimation output was actually used before changing
  Table 2. MCMC sampling noise means small differences from the original run are expected.

---

## Part 4 — Simulation bugs found and fixed

Found by an automated review of the untracked forks, then verified directly against the model's
own output. Both were present in the **benchmark**, not only the forks. Fixed in commit
`3c4460d`; the pre-fix state is preserved at tag `submitted-baseline`.

### 4.1 All simulated panels shared one oil-price path

`random_matrix_rw` was dimensioned `(period_num, 2)` with no sample index, while the endowment
draws in `random_matrix` were correctly `(period_num, sample_num, 2)`. Drawn at `(i,·)` inside
the `do j=1,sample_num` loop, every one of the 500 panels followed an identical oil-price and
volatility path. Cross-sample averaging therefore did nothing to reduce price-shock sampling
error: the effective sample size for every price-related moment was **one path**, understating
standard errors by roughly √500 ≈ 22×.

Fixed by giving the array a sample dimension and drawing per sample. Per-sample initial
conditions (`i_p_previous`, `i_p_vol_previous`) were already reset at the top of the `j` loop.

**Verified:** samples 1 and 2 now differ on 1275 of 1500 periods; 17 and 18 distinct prices
respectively. Previously identical.

### 4.2 Allocations read at the wrong debt index

`c_matrix`, `oil_matrix` and `output_matrix` are indexed by the debt the country **enters** the
period with — `c0_matrix` is defined from `b_initial = b_grid(i_b)` at line 1035 — but `simulate`
reassigned `i_b_next` *before* using it as that index.

The correct fix differs by branch:

| branch | fix |
|---|---|
| repay, default, exclusion-ends | `i_b_current` |
| exclusion-continues | `output1_matrix` / `oil1_matrix` / `c1_matrix` |

In the default branch `i_b_current` suffices because `c_matrix` at a state where default is
optimal already holds `c1_matrix` (line 1047). During *continued* exclusion neither debt index
works: the country is in autarky, and `c_matrix` at zero debt returns the repay allocation
including fresh bond proceeds. Those branches now read the autarky arrays directly, which
required promoting `c1_matrix`, `output1_matrix`, `oil1_matrix` and `TFP1_matrix` from locals of
`iterate` to module scope. `q_fun(i_b_next, …)` is left unchanged — the bond price correctly
depends on the amount issued.

**Verified** at state (i_y=10, i_p=4, i_p_vol=3), original parameters:

| | n | c | gdp | y |
|---|---|---|---|---|
| excl=1 (repay) | 20218 | 5.118 | 5.628 | 9.728 |
| excl=2 (autarky) | 1407 | 4.590 | 4.982 | 8.620 |

`gdp` now falls 11.5% at default, tracking the 11.4% fall in `y`; before the fix it was
bit-identical across `excl=1` and `excl=2`, omitting the `d0`/`d1` default output cost.
Consumption in exclusion now takes 393 distinct values across 64,611 observations; before the
fix it was a single constant. The consumption drop at default is 10.3%.

Both bugs affect consumption volatility, the consumption and output drop at default, `tb/gdp`,
and any welfare moment built on them.

### 4.3 The intermediate model's oil price was frozen

With `p_vol_num=1` the code takes the `p_vol_num < 2` branch, where `tauchen` filled **both**
`p_grid(:,1)` and `trans_matrix_p(:,:,1)`, after which `discretize_AR` overwrote the *grid* — its
`z` argument is `intent(out)` — with Rouwenhorst nodes (±0.1924), leaving Tauchen's transition
matrix, built for its own wider ±0.3141 grid, in place. `discretize_AR`'s own matrix went to
`trans_matrix_p_AR`, which is never read.

The mismatched pair had diagonal **0.9995** instead of **0.9423**, freezing the price: the price
column of its 750,000-row simulation took exactly one value, 1.05745457. **The intermediate
economy was numerically the basic (constant-price) economy**, so the full-vs-intermediate
comparison in Section 6.2 did not isolate the volatility channel at all.

Fixed by using `discretize_AR` for both grid and matrix, as the `p_vol_num >= 2` branch already
does. The same latent bug is fixed in the benchmark, where it is dead code at `p_vol_num=5` but
is the branch any `p_vol_num=1` run would take.

**Verified** by re-running the corrected intermediate model to completion:

| | before | after |
|---|---|---|
| transition diagonal | 0.9995 | **0.942345** (matches benchmark exactly) |
| distinct simulated prices | 1 | **7** |
| price-state indices visited | {3} | **{1,…,7}** |
| sample 1 vs sample 2 paths | identical | **differ on 1174 / 1500 periods** |

The last row reflects §4.1 and §4.3 together: distinct prices *and* independent paths per panel.

### 4.4 Common price grid ported into the Fortran

`use_common_p_grid = .true.` (module `param`) switches the price discretization to **one
physical log-price grid shared by every volatility state**, with volatility entering only the
transition kernel. This is the structural fix for §3.1. Setting the flag to `.false.` restores
the submitted behaviour exactly, so the two are comparable.

New routines in module `param`: `normal_cell` (ERFC-based, cancellation-safe, identical in form
to `normal_cell` in `oil_price_validation/price_kernel.f90`) and `tauchen_fixed`, which takes the
grid as an **input** rather than generating it. Grid half-width is `p_width_sd` unconditional SDs,
where sd(log p) = sqrt(E[v]/(1−ρ_p²)) and E[v] = exp(2·mean_p_vol + 2·Var(x)).

The existing `Ncdf` is a Polya-type closed form with absolute error ~3e-3 — fine for its original
use but far too coarse for a kernel that must reproduce conditional moments, hence the separate
ERFC path. **`Ncdf` is still used for the endowment process `y`**, which inherits that error; not
changed here because it would move the benchmark.

**Verified** against an independent Python implementation of the same formulas, using
full-precision parameters:

| check | result |
|---|---|
| grid identical across volatility states | max diff **0** |
| price kernel vs reference | **1.1e-16** |
| volatility kernel vs reference | **5.6e-17** |

(An earlier 1.09e-10 discrepancy was an artifact of the test reading `p_vol_grid.txt`, which is
written with only 8 decimals — not a code defect.)

### 4.4a A second live grid/kernel mismatch, in the volatility process

Tracing those grid values exposed the **same defect as §4.3, live in the benchmark**, for the
volatility chain: `tauchen` fills `p_vol_grid` (±m·sd, spacing 0.586) *and* `trans_matrix_p_vol`,
then `discretize_AR` overwrites the **grid** with Rouwenhorst nodes (±√(n−1)·sd, spacing 0.293)
while its own matrix goes to `trans_matrix_p_vol_AR`, which is never read. The surviving Tauchen
matrix was built for cells twice as wide as the grid actually has.

At the submitted parameters (η=0.44, ρ_σ=0.66), on the same ±2 sd grid:

| | sd(log σ) | persistence |
|---|---|---|
| target | 0.5857 | 0.660 |
| **submitted kernel** | **0.3568 (−39.1%)** | 0.673 |
| matched kernel (fixed) | 0.5970 (+1.9%) | 0.641 |

**The submitted model's volatility process has 39% less dispersion than calibrated.** Persistence
is roughly right; it is the *size* of volatility shocks that is wrong. This compounds §3.3 — the
volatility level is understated by the convention error, and its variation is understated again
here.

### 4.4b Known limitation: `p_num` must rise sharply

A common grid must span the unconditional range while still resolving a one-period move, whose sd
is `exp(p_vol_grid(k))` and is smallest in the lowest volatility state. At `p_num = 7` the model
now prints a warning, because it fails badly:

| p_num | spacing | cond sd / spacing (lowest vol) | states (b·y·p·v) |
|---|---|---|---|
| 7 | 0.861 | **0.05** | 73,500 |
| 101 | 0.052 | 0.90 | 1,060,500 |
| **201** | 0.026 | 1.80 | 2,110,500 |
| 401 | 0.013 | 3.59 | 4,210,500 |

Roughly **224 nodes** are needed for the lowest-volatility state to move at all — consistent with
the 201 used in the standalone validation. This is the same freezing pathology as §4.3, reached
from the opposite direction: there the kernel was too persistent, here the grid is too coarse.

The cost is severe. The expectation loops over next-period `(y, p, σ)`, so VFI work scales
roughly with `p_num²`: 7 → 201 is about **800×**. The efficiency fix in §4.5 (hoisting `func_m`)
becomes a prerequisite, not an optimisation, and `b_num`/`y_num` may need revisiting.

### 4.4c Performance: `func_m` memo cache

`optimize` scans `b_num = 100` debt choices, calling `objective_function` for each, and that
calls `func_m` — a bisection — even though `y_initial`, `p_initial` and `i_excl_global` are module
globals that do not change inside the loop. 99 of every 100 bisections repeated work already done.

`func_m` is a pure function of those three, so caching the last result is exact, not approximate.
Measured on the original calibration and the submitted grid path:

| | wall time | outputs |
|---|---|---|
| before | 240.3 s | — |
| after | **50.5 s** | **all 40 files bit-identical**, incl. the 160MB simulation (same md5) |

**4.8×.** Less than the "removes essentially the whole runtime" estimate in the review, because
the bisection converges in roughly 14 iterations, not the 5000 cap — it was most of the runtime,
not nearly all of it.

### 4.4d The real barrier at large `p_num`: the expectation loop

With `func_m` handled, the binding constraint is the expectation in `iterate`:

```
do i_b_prime = 1,b_num
   do i_p_vol_next, i_p_next, i_y_next      ! p_vol_num * p_num * y_num
      exp_v_next += P_sigma * P_p * P_y * v_matrix(...)
```

nested inside the loops over `(i_y, i_p, i_p_vol)`. Cost per sweep is
`b_num · (y_num·p_num·p_vol_num)²`, i.e. **quadratic in `p_num`**:

| p_num | ops/sweep | vs now |
|---|---|---|
| 7 | 5.4e7 | 1× |
| 201 | 4.5e10 | **~800×** |

At 201 nodes that is days per solve. The sum factorizes, because the kernel is a product:

```
A(b',y,p',s') = sum_y'  P_y(y,y')     V(b',y',p',s')     ! independent of (p,s)
B(b',y,p,s')  = sum_p'  P_p(p,p'|s')  A(b',y,p',s')
E(b',y,p,s)   = sum_s'  P_s(s,s')     B(b',y,p,s')
```

Cost becomes `b·y·p²·s` (the middle step dominates) instead of `b·y²·p²·s²` — a factor of
`y_num·p_num·p_vol_num / p_num = y_num·p_vol_num` = **105×**. That brings 201 nodes back to
roughly the current cost per sweep. Memory for the intermediates is about 17MB each at
`b=100, y=21, p=201, s=5`.

Two further easy wins in the same loop: `exp_v_excl` reads `v1_matrix`, which has **no debt
index**, so it is recomputed identically `b_num` times; and `expectation` is assigned but never
used.

**Implemented** as `precompute_expectations`, called once per sweep. Measured on the original
calibration and the submitted grid path:

| | wall time |
|---|---|
| uncached | 240.3 s |
| + `func_m` cache | 50.5 s |
| + factorized expectation | **43.5 s** |

Only 14% at `p_num = 7`, which is the honest number — the expectation loop is a modest share of
runtime at seven price nodes. The saving scales with `y_num·p_vol_num`, so it is what makes
`p_num = 201` tractable rather than what speeds up the current configuration.

Because the summation is reordered and floating-point addition is not associative, this is **not**
bit-identical by construction. What was verified:

| quantity | result |
|---|---|
| default decisions | **identical** |
| debt policy actually used (`b_next_matrix`) | **identical** |
| simulation output, 160MB | **identical (same md5)** |
| value function | differs ≤ 1.4e-14 relative |
| consumption | differs ≤ 9.8e-13 relative |
| `b0_next_matrix_indice` | 4348 of 73,500 index flips |

The policy flips look alarming but are benign: **all 4348 are in states where default is chosen**,
so the repay policy is computed and then discarded. In every state where it is used it is
unchanged — which is why the used policy and the simulation are untouched. The flips occur where
the objective is flat in `b'` to within 1e-14, so `maxloc` picks a different tied index.

### 4.4e Making the corrected calibration solvable

With sigma = 0.4 from the data (REVISION_NOTES 4.6), theta = -1.5 and
alpha = 1.652632e-4 calibrated to the measured 3.74% share, **the model solves on the
corrected process** -- no bisection failure, because sigma < 1 removes the lower price
floor entirely. `p_num = 225` gives sd/spacing >= 2.0 in every volatility state.

Three things had to be removed first, all of them pure waste:

| what | why it blocked | fix |
|---|---|---|
| `SDF_matrix`, rank 6 | `argument = rstar`, so every element was the same number; **5.6 GB** at p_num = 225 | replaced by the scalar it always was |
| `expected_SDF_matrix` loop | constant SDF times rows summing to one, i.e. identically `sdf_value`; 5.6e8 terms | direct assignment |
| `q_nodef` fixed point | state-independent by construction; (y*p*s)^2 terms per sweep for one scalar | scalar recursion, same stopping rule |

The `expected_SDF_matrix` initialisation was also an out-of-bounds write using loop
indices left past their bounds -- the defect the review flagged -- now a whole-array zero.

Verified at p_num = 7 against the previous build: **38 of 40 files identical**, the two
that differ being exactly `q_nodef` and `expected_SDF` themselves, at 1e-15. Those two
previously showed 41 and 28 "distinct" values that were one number plus summation noise;
they are now exactly constant.

### 4.4f `q_fun`, and a convergence-tolerance problem it exposed

`q_fun` was then the binding cost: a 23,625-term triple sum, called `b_num` times per
state, **5.6e10 inner iterations per sweep** at p_num = 225 -- over eleven minutes for a
single sweep. It factorizes exactly like the value expectation and is now precomputed.

**This changes the update scheme.** `q_fun` read `default_decision` and `q_paid_matrix`
as they stood mid-sweep, and both are written during the sweep, so the original is
Gauss-Seidel in those objects; precomputing makes it Jacobi. Same fixed point, different
path.

At the shipped tolerance that matters more than it should:

| `criteria` | scheme | simulated default freq | mean q |
|---|---|---|---|
| 1e-3 (shipped) | Gauss-Seidel | 0.007276 | 0.816440 |
| 1e-3 | Jacobi | 0.007653 | 0.815234 |
| 1e-7 | Gauss-Seidel | **0.007689** | 0.817960 |
| 1e-7 | Jacobi | **0.007668** | 0.818740 |

Converged, the two schemes agree to **0.27%**; at 1e-3 they differ by **5.2%**. The
shipped Gauss-Seidel run is the furthest from its own converged answer. So this is not a
modelling choice between schemes -- **the benchmark is under-converged**, and a reported
moment moves ~5% because of it.

Note both 1e-7 runs stopped at the 1500-sweep cap rather than on tolerance, so even that
is an upper bound on accuracy. Tightening `criteria` (line 1363) and raising the cap
belongs in step 4, re-establishing the benchmark, and should be documented as a change.

### 4.4g First full solve on the corrected process

Completed: 45 minutes wall clock, VFI converged at sweep 126 (deviation 9.3e-4 against
`criteria` 1e-3), full 750,000-observation simulation written. Configuration:
sigma = 0.4, theta = -1.5, alpha = 1.652632e-4, p_num = 225, p_width_sd = 4,
p_vol_width_sd = 2, common price grid.

**Process reproduction** -- the point of the whole exercise:

| moment | model | target |
|---|---|---|
| sd(log oil price) | **0.6462** | 0.646 (analytical) |
| mean oil import share | **3.54%** of GDP | 3.74% (measured) |
| corr(oil share, oil price) | **+0.98** | positive; data slope 1-sigma = +0.61 |

The sign of that last row is the one the submitted calibration got backwards: sigma = 2
implies oil bills *fall* as a share of GDP when oil gets dearer.

**Spreads and defaults:**

| moment | model | data |
|---|---|---|
| mean spread, annualised | **492 bp** | ~410 bp |
| sd spread | 251 bp | |
| annual default rate | 3.61% | |

The magnitude is now the right order. This speaks to Report 2's Major 6: the submitted
model delivered 0.5-1.5 bp per 10% oil price move against 6-8 bp in the data; this
configuration gives **2.7-3.4 bp**, roughly 40-50% of the empirical response rather than
10-20%.

**The headline state-dependence shrinks sharply:**

| volatility state | d(spread, bp) / d(log oil price) |
|---|---|
| low (below median) | +28.5 |
| high (at or above median) | +35.5 |
| **ratio** | **1.25x** |

The submitted model reports **~3x** (slopes of 0.15 against 0.05). On the corrected
process that becomes 1.25x -- consistent with section 3.1, which predicted the 3x was
substantially an artifact of the volatility-dependent price grid rather than a volatility
channel.

**Do not over-read this.** Four caveats:

1. The calibration changed at the same time as the grid (sigma 2 -> 0.4, alpha
   recalibrated, share target 7.99% -> 3.74%), so 3x -> 1.25x is a **joint** effect and
   cannot yet be attributed to the grid fix alone. Isolating it needs the grid fix at the
   submitted calibration, which is only feasible on a narrowed grid (section 4.4b).
2. Only five volatility nodes at +/-2 sd, so the volatility process has limited range;
   `p_vol_num` and `p_vol_width_sd` are unexplored.
3. The low/high split here is at the median realised volatility, which need not match the
   paper's definition.
4. `criteria` is still 1e-3, which section 4.4f shows is loose enough to move the default
   frequency by ~5%.

### 4.6 The headline 3x state-dependence is a measurement artifact

The `mean_preserving` switch implements both reports' lead comment on the **submitted**
grid and calibration: `discretize_AR` is called with
`mean_p - 0.5*(v_k - v0)`, v0 = E[v], so the conditional mean of the level stops moving
with volatility. It is one line, and the economy solves in under a minute.

Running it exposed something more fundamental than the correction itself.

**First, the setup reproduces the paper.** Using the definition in
`working_graphs_dec29.m` (i_b3 = 44, nodes 2 and 6, median endowment), the benchmark gives
slopes of 0.0108 / 0.0224 / 0.0322 across volatility states 2/3/4 -- a **ratio of 2.99**,
i.e. the reported ~3x. So the pipeline is faithful.

**Second, that 3x is the ratio of two price intervals, not an economic response.** The
slope is `(s6 - s2)/dprice` with `dprice` held fixed at the **vol-3** grid, while nodes 2
and 6 span a volatility-*dependent* interval because every volatility state has its own
grid:

| vol | price interval spanned | reported slope | per ACTUAL price unit |
|---|---|---|---|
| 2 | 0.136 (1.00x) | 0.0108 | 193.8 bp |
| 3 | 0.244 (1.80x) | 0.0224 | 224.2 bp |
| 4 | 0.440 (3.24x) | 0.0322 | 178.5 bp |

**Ratio of price intervals 3.24; ratio of reported slopes 2.99.** Dividing by the interval
actually traversed leaves 194 / 224 / 179 bp -- no monotone pattern in volatility.

**Third, the statistic is not robust.** The 3x appears at one debt index only:

| i_b | 38 | 40 | 42 | **44** | 46 |
|---|---|---|---|---|---|
| ratio | 0.47 | -0.05 | -0.84 | **2.99** | 0.09 |

and OLS on all seven nodes reverses the ordering (0.067 / 0.036 / 0.025, *decreasing*).

**Fourth, fixing the normalisation does not rescue it.** On a balanced sample (endowment
states non-default at every price node and volatility state, so composition cannot shift),
the ratio of vol-5 to vol-1 sensitivity is:

| i_b | 38 | 40 | 42 | 44 | 46 |
|---|---|---|---|---|---|
| 2-point, normalised | -0.26 | -0.13 | -0.11 | -0.44 | -0.01 |
| OLS, all nodes | 0.56 | -2.36 | -0.65 | 0.26 | -0.07 |

Sign and direction both flip across debt indices and estimators. There is no stable
state-dependence to measure in this configuration.

**Why.** With seven nodes whose spacing differs ~10x across volatility states, and a
denominator taken from one state's grid, the slope is not identified. This is the
`p_grid` defect of section 3.1 surfacing as the headline number rather than as an
abstraction.

**Consequence for the decomposition.** The mean-preserving correction moves each grid
centre by at most 1.1e-4 in log price, yet the reported statistic swings from +2.99 to
+0.08. That is not an economic effect -- it is a broken statistic responding to a
relocation of two sample points. The decomposition cannot be interpreted until the price
index means the same price in every volatility state, which is the common-grid fix.

### 4.5 Still outstanding

- **The forks carry the pre-revision calibration** while the benchmark has been updated — a
  price-innovation sd of 0.0156 against 0.127, a factor of 8.1. Any cross-economy comparison run
  now would attribute that level gap to the volatility channel. Nothing records the difference:
  all three variants write identically-named `graphs_*.txt`, and `param_calib.txt` dumps only
  `beta`/`d0`/`d1`/`delta`.
- **Not independently verified** (reported by the review, consistent with observed behaviour but
  not re-checked here): an out-of-bounds write to `expected_SDF_matrix` at line 1208;
  `graphs_pdf_y.txt` written from the never-assigned `prob_vector`, containing a literal `NaN`;
  and `p_grid_1..5` dumped as all-zeros in the intermediate run, which makes
  `working_graphs_dec29.m` divide by zero.
- **Efficiency (now a prerequisite, see 4.4b).** `func_m` — a 5000-iteration bisection — is called inside `objective_function`,
  which `optimize` evaluates 100× per call, but its result depends only on `(y, p, excl)`, all
  constant across the b-loop. That is roughly 1.5M bisections per VFI sweep to produce 294
  distinct values. Hoisting it into a precomputed table would remove most of the runtime.
