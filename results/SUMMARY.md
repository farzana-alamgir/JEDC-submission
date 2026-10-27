# Revision summary

Everything found and produced in the revision of *Oil Price Uncertainty and
Sovereign Spreads of Oil Importers*. Written for drafting the response letter.

The detailed working record is `REVISION_NOTES.md` (Parts 6–29). Figures are in
`results/figures_*`, tables in `results/tables_*`.

---

## 1. The headline, in one paragraph

The model's **calibration is unchanged** — α, θ, β, CRRA, ρ_p, ρ_σ, η, mean_p,
mean_p_vol are all numerically identical to the submitted version. What changed
is the **numerics**: five defects were found and fixed, three of them in the
submitted code. After fixing them the model matches the oil price data far
better than before and fits three of four targeted moments more closely, but
two of the paper's quantitative claims do not survive and one reverses sign.

---

## 2. Defects found

### In the submitted code

| # | defect | evidence | effect |
|---|---|---|---|
| 1 | **Volatility convention.** `stochvol` defines `y = exp(h/2)·ε`, so `h` is log *variance*. The code used `exp(h)` as the standard deviation. | Model oil volatility **1.86%/quarter** against **14.47%** in `empirical/oil_qtrly.xlsx` (real price, 1995–2019). Under `exp(h/2)`: 12.61%. | Oil price ~8× too smooth. Explains every weak channel. |
| 2 | **Figure 3's 3×.** Slopes were differenced across indices 2→6 of a *per-state* price grid but divided by the single vol-3 denominator. | Price intervals at those indices: vol2 = 0.1357, vol3 = 0.2441, vol4 = 0.4404. Ratio **3.245**. | The published 3× is a measurement artifact. |
| 3 | **Figure 4d.** Plots `E[p′]` at a fixed price *index* across per-state grids. With ρ_p = 0.98, `E[p′|p] ≈ p`, so the plotted values are essentially the grid nodes. | At `i_p = 7`: plotted 1.1844/1.2318/1.3217/1.5002/1.8839 vs nodes 1.1856/1.2340/1.3259/1.5085/1.9021. | The published +17% to +58% is "node 7 of a wider grid is a higher price". |
| 4 | **Oil-demand bisection** solved to an *absolute* 1e-2. Oil demand is order 0.5–1.6, i.e. a 0.6–2% error, propagating to output, consumption and every spread. | Visible as a staircase in FIGURE4a/4b once the scale exposes it. | Flipped the sign of three ±20 bp results. |
| 5 | **Single-precision literals.** α, β, d0, d1 declared `DOUBLE PRECISION` but given default-REAL literals. | Model runs at α = 0.30000001192, β = 0.95999997854. | See §5: this sets the model's noise floor. |
| 6 | **Figure 7 welfare sign.** `100*((Va−Vf)/Vf)*scale_y` divides by a *negative* CRRA value function. | Disagreed with the correct consumption-equivalent at **21 of 21** output states. | Welfare gains printed as losses. |
| 7 | **Figure 7 legend** labels swapped (`h1` plots `full_to_base`, labelled "Full to Intermediate"). | `script:937–946` at commit c24560d. | Published Figure 7 is mislabelled. |

### Introduced during this revision, then fixed

Legacy grid-overwrite blocks; hardcoded price indices written for a 7-node grid
(Figs 2, 3, 4d, 5) that blanked FIGURE4d at `p_num = 549`; Tauchen aliasing at
ρ_p = 0.98 (an 11-cycle ripple, predicted exactly: `p_num·(1−ρ) = 11.0`).

### Also: `model/FIGURE*.jpg` is not the submitted figure set

It is stale for FIGURE3, 4a–4d and 5 (mean greyscale difference 2.3–6.9 against
the paper). Rebuilding commit c24560d reproduces **the paper** pixel-identically
(d = 0.000) on all eight figures it generates. The paper's own figures are
archived at `results/figures_submitted_from_paper/`.

---

## 3. Current results

Calibration: your parameters, with **`d1`: 0.37 → 0.3847** (a 4% change in the
quadratic default-cost coefficient — see §4). `exp(h/2)` volatility, relative
1e-10 oil-demand bisection, common ±3.5 sd price grid, `p_num = 549`.

### Table 3 fit — improved on three of four

| moment | submitted model | **this model** | DATA |
|---|---|---|---|
| Mean spread % | 4.0 | **4.02** | 4.1 |
| Mean debt/GDP % | 34.7 | **33.5** | 34.0 |
| SD of spread | 2.3 | **2.25** | 2.0 |
| Mean oil import/GDP % | 8.0 | **9.9** | 9.0 |
| corr(spread, GDP) | −0.6816 | **−0.4188** | −0.4332 |

Simulated oil price volatility is **12.61%/quarter** against **14.47%** in the
data; the submitted model produced 1.86%.

### The four economies

| economy | spread | sd | default %/yr | GDP |
|---|---|---|---|---|
| constant price | 349.8 | 2.28 | 3.054 | 5.6649 |
| constant volatility | 401.4 | 2.21 | 3.172 | 6.2522 |
| mean-preserving | 398.6 | 2.27 | 3.134 | 6.2822 |
| full SV | 401.6 | 2.25 | 3.160 | 6.2612 |

### Channels

| channel | bp | t |
|---|---|---|
| **oil price risk** (constant vol − constant price) | **+51.7** | 64.4 |
| time-varying volatility (full − constant vol) | +0.1 | 0.2 |
| of which dispersion | −2.8 | −5.9 |
| of which mean / Jensen | +2.9 | 8.3 |

### 3a. The four quantitative claims, measured

Recalibrated model, local contrast of a 20% price move around the ergodic
median (1.0158 -> 1.2415), `i_b = 44`, `results/FIGURE_claims_check.jpg`.

| claim | paper | this model | verdict |
|---|---|---|---|
| spread responds 3x more sharply in high volatility | 3.00 | median ratio **1.03** (max 1.21, >1 at 10 of 14 output states) | direction right, magnitude absent |
| more indebted economies see larger spread increases | qualitative | **13.7 bp at debt/GDP 0.11 rising to 203.9 at 0.33** | **CONFIRMED, strongly** |
| debt slope 0.16 / 0.25 / 0.70 by volatility | 0.16/0.25/0.70 | **+0.020 / +0.020 / −0.001** | ~10x too small, no ordering |
| welfare gain 0.2% to 1.1% | +0.2 / +1.1 | **+0.064%** (remove time-varying vol) / **−3.240%** (remove all oil price risk) | first right in sign, second reversed |

The **debt amplification result is strong and clean** — a 15x rise in the spread
slope across the debt range. It is the one quantitative claim in the paper that
the corrected model reproduces convincingly.

---

## 4. The calibration sensitivity — read this before quoting any number

`d1` was raised 4% because it improves **all four** targeted moments (total
absolute relative error −56%). But:

| channel | d1 = 0.37 | d1 = 0.3847 |
|---|---|---|
| oil price risk | **+154.9 bp** | **+51.7 bp** |
| time-varying volatility | +1.9 | +0.1 |

**A 4% change in one default-cost parameter cuts the central result by
two-thirds.** Both calibrations are defensible; the second fits better. The
honest presentation is a range, not a point estimate.

---

## 5. The model's noise floor

Changing α by **1.19e-8** (the single- vs double-precision literal) moves the
mean spread by **+1.34 bp**, t = 4.9. The discrete default decision amplifies
tiny perturbations: a few marginal states flip, the bond schedule moves, and it
propagates.

| quantity | size | vs the 1.3 bp floor |
|---|---|---|
| oil price risk | +51.7 bp | **40× the floor** — solid |
| decomposition sub-channels | ±3 bp | ~2×, and they flipped sign with the bisection fix |
| time-varying volatility | +0.1 bp | **below the floor** — zero |
| risk premium (κ = 0.5, 1.0) | −1.2, −2.2 bp | at the floor |

**No channel below a couple of basis points should be reported with a sign.**

---

## 6. What survives, what doesn't

### Survives

- **Your Table 1 ordering is confirmed**: full > intermediate > basic in mean
  spread, spread variability *and* default rate — exactly as the paper states.
- **Oil price risk raises spreads substantially**: +51.7 bp (+15%) at the new
  calibration, +154.9 bp (+56%) at yours. Large, precise, robust to grid,
  discretisation and tolerance.
- **The Jensen channel is real and now visible**: `E[p′]` swings **+1.94%**
  across volatility states, exactly flat under the mean-preserving correction.
  This is the cleanest answer to both referees' lead comment.
- **The empirical panel fact** — untouched by any of this.
- **R2 major 3 (oil disrupted in default)**: +29.9 bp spread, **+16.6% debt**.
  Strengthens the model; the submitted version understates the cost of default.
- **The model now matches oil price volatility**, which it did not before.

### Does not survive

- **The 3× state-dependence** (Fig 3). On a common grid the ordering holds but
  the gap is ~1.0. The published 3× is defect #2.
- **The welfare gain of +1.1%**. Removing oil price risk *costs* 3.2% of
  consumption, because output is **convex** in the oil price at θ = 0.5.
  Verified analytically: +9.57% output gain from dispersion, against +10.59% in
  the simulation.
- **The volatility-timing channel**. +0.1 bp, below the noise floor.
- **The debt slope 0.16 / 0.25 / 0.70**. Measured on the recalibrated model over
  a local 20% price move: **+0.020 (low vol), +0.020 (mean), −0.001 (high)** —
  about 10x too small, and with no volatility ordering. The claimed "factor of
  more than four" amplification is absent.

---

## 7. The elasticity is the pivotal parameter

θ = 0.5 makes the oil–domestic elasticity `1/(1−θ) = 2`: oil a **substitute**.
That is what makes output convex in price, which drives *both* the welfare
reversal and the weak volatility channel.

The natural alternative is closed:

- α = 0.00056 (matching the 6.5% oil share at σ_oil = 0.39): oil becomes
  irrelevant to production — output ≈ the endowment — and every channel is zero.
- α = 0.02 (oil essential, 26% share): **the model does not converge.** The
  value function error oscillates around 0.5 with no trend after 189 iterations.
- α = 0.3 at σ_oil = 0.39: **infeasible** — the oil bill exceeds output above
  p = 2.159, and the grid reaches 10.17.

**A trilemma:** oil essential + complementarity + realistic oil price volatility
cannot hold together in this model.

Note R2 minor 1 is correct and should be fixed: the elasticity is `1/(1−θ)`,
not `1/θ`. At θ = 0.5 both equal 2 — as does the CRRA coefficient — so three
distinct quantities all equal 2 in the paper. Worth distinct symbols.

---

## 8. Suggested framing

The volatility channel did not "disappear". Three specific, documentable
measurement errors produced the published magnitudes, and each can be pointed
at in your own source:

1. Figure 3's 3× — per-state intervals over a common denominator (ratio 3.245)
2. Figure 4d's +58% — grid nodes at a fixed index
3. The volatility convention — `exp(h)` for `exp(h/2)`, making oil 8× too smooth

Finding these yourself is a strength. The defensible paper is:

> Oil price uncertainty raises sovereign spreads substantially. The *level* of
> oil price risk is what matters; its *time-variation* contributes little.

That distinction — risk vs. time-varying risk vs. the first-moment effect of
volatility — is exactly what R2's lead comment asks you to separate, and the
mean-preserving economy is the instrument that does it.

The welfare reversal should be reported as a finding, not buried: spreads and
welfare move in opposite directions, and the elasticity of substitution decides
which dominates.

---

## 9. Open items

**Model**
- Debt slope 0.16 / 0.25 / 0.70 (Figs 6a/6b) — the abstract's second headline,
  never checked in this revision
- Figure 5's debt amplification — not verified on a clean build
- R1 major 5 — implemented, but the premium is at the noise floor and negative;
  needs either a different kernel or treatment as a discussion point
- The dispersion/Jensen split cannot be resolved at ±3 bp against a 1.3 bp floor

**Empirical — none started.** Four of eight referee items:
- R1 major 1a (expectations evidence), 1b (panel interactions), 1c (two-way
  clustering), R2 major 5 (test state-dependence directly in the data)

R2 major 5 is now the most valuable single thing you could do: the model says
there is no state-dependence at any calibration tried. Testing it in your panel
decides whether the model is wrong or the original claim was the artifact.

**Writing**
- R2 minor 1 (elasticity formula), R2 major 4 (novelty framing vs
  López-Martín et al. 2019)

---

## 10. Provenance

| tag | what |
|---|---|
| `submitted-baseline` | as submitted |
| `figures-corrected-v1` | figure pipeline fixed, submitted figures archived |
| `corrected-volatility-v1` | `exp(h/2)` + bisection fix |
| `model-final-v1` | both defects removed, α = 0.3 / θ = 0.5 |

Figure sets: `figures_submitted_from_paper/` (the reference),
`figures_clean/` (old calibration), `figures_recalibrated/` (d1 = 0.3847,
current best fit). Tables: `tables_final/`, `tables_corrected_volatility/`.
Predictions scorecard: `PAPER_PREDICTIONS.md`.
