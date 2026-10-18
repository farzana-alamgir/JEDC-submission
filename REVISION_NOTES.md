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

### 3.3 Finding C — probable factor-of-two in the volatility calibration (**needs verification**)

Flagged as inference, not a confirmed defect: the paper PDF could not be read on this machine
(no `pdftotext`/poppler) and `volatilities.csv` is not in the repo.

The code sets `σ_t = exp(p_vol_grid)` with `mean_p_vol = -4.33`:

| | σ (quarterly innovation sd) | uncond. sd of log p | one-step `½σ²` | uncond. `½Var(log p)` |
|---|---|---|---|---|
| (A) code as written, σ = exp(h) | 0.0132 (1.3%) | 6.6% | 0.0087% | 0.22% |
| (B) stochvol convention, σ = exp(h/2) | 0.1147 (11.5%) | 57.7% | 0.658% | 16.6% |

```
exp(−4.33) = 0.01316 = (0.1147)² = [exp(−4.33/2)]²
```

`stochvol`'s `svsample` parameterizes `y_t = exp(h_t/2)·ε_t`, so `h` is the log **variance** and
σ = exp(h/2). If the AR(1) was fit to `h` (mean −4.33) and the Fortran then applied σ = exp(h),
**the model is using the variance where the standard deviation belongs.** The same logic applies
to `eta = 0.44`, which would need halving to 0.22.

Two corroborations:

1. Report 2 asserts "quarterly log price innovations above 10%" — consistent with (B), not (A).
   This suggests the paper's text reports a number the code does not use.
2. Report 2's Major 6 (model 0.5–1.5bp vs data 6–8bp per 10% oil move) is what an oil price
   ~9× too stable would produce.

Empirically the sd of the log real oil price over 1995–2019 is roughly 0.40–0.55, consistent with
(B) = 0.58 and not with (A) = 0.066.

**This is a clean fork.** Either the paper reports σ > 10% and the code is wrong, or the paper
reports σ ≈ 1.3% and Referee 2's premise is wrong and should be rebutted in the response letter.

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

- Finding C, the σ vs σ² convention. Needs Table 2 of the paper and the R-side AR(1) fit on the
  `stochvol` volatility series (neither is in this repo).
