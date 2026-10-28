# Every model version tried in this revision

Seven versions. All on the per-state Rouwenhorst grid (`p_num = 7`, the
submitted construction) except version 2.

## 1. The versions

| # | version | theta / sigma_oil | alpha | beta | d1 | other | where |
|---|---|---|---|---|---|---|---|
| 1 | **Submitted** | 0.5 / 2.0 | 0.3 | 0.96 | 0.37 | `exp(h)` volatility bug | `c24560d` |
| 2 | Corrected vol, **common grid** | 0.5 / 2.0 | 0.3 | 0.96 | 0.3847 | `p_num = 549` | `results/SUMMARY.md` |
| 3 | **Option A** (per-state grid) | 0.5 / 2.0 | 0.3 | 0.96 | 0.3847 | — | `SUMMARY_OPTION_A.md` |
| 4 | sigma_oil = 0.30, uncalibrated | −2.333 / 0.30 | 1.89e−4 | 0.96 | 0.3847 | — | `SIGMA03_RESULTS.md` |
| 5 | sigma_oil = 0.30, **calibrated** | −2.333 / 0.30 | 1.89e−4 | 0.964 | 0.37 | — | `FINAL_CALIBRATION.md` |
| 6 | **Value-added default cost** | −2.333 / 0.30 | 3.07e−4 | 0.972 | 0.46 | `va_default_cost` | `VALUE_ADDED_DEFAULT_COST.md` |
| 7 | Value-added + **risk premium** | −2.333 / 0.30 | 3.07e−4 | 0.972 | 0.46 | `kappa_risk = 3` | `RISK_PREMIUM_AND_FIGURE3.md` |

Also tested but not carried forward as full versions: an oil-price-dependent
default cost (`oil_disruption`, wrong sign — `OIL_DEPENDENT_DEFAULT_COST.md`)
and a low-persistence diagnostic (`rho_p = 0.90` — `WHY_OPPOSITE.md`).

## 2. Table 3 fit

| # | version | spread (4.1) | sd (2.0) | debt/GDP (34.0) | oil/GDP (9.0) |
|---|---|---|---|---|---|
| 1 | Submitted | 4.1 | 2.0 | 34.0 | 9.0 |
| 2 | Common grid | **4.02** | **2.25** | 33.5 | 9.9 |
| 3 | Option A | 4.21 | 2.33 | 42.74 | 9.95 |
| 4 | sigma 0.30 uncal. | 4.72 | 2.43 | 39.59 | 8.67 |
| 5 | sigma 0.30 cal. | **3.99** | **2.25** | **33.41** | 8.73 |
| 6 | **Value added** | 4.41 | 2.91 | **33.69** | 8.73 |
| 7 | VA + kappa = 3 | 6.48 | 3.14 | 18.06 | 11.84 |

Version 1's column is the paper's target, not an independent result. Its
oil price volatility was 1.86% a quarter against 14.47% in the data — the
`exp(h)` bug. Every later version reproduces 14.63%.

## 3. Headline channels

| # | oil price risk (level-matched) | welfare, remove all oil risk | FIGURE3 ratio | debt amplification |
|---|---|---|---|---|
| 1 | — | +0.2% to +1.1% claimed | 3.0 claimed | qualitative |
| 2 | +51.7 bp | **−3.240%** | **1.03** | 13.7 → 203.9 bp |
| 3 | +7.1 bp | **−3.030%** | 0.62 | 19 → 198 bp |
| 4 | +25.2 bp | +0.489% | 0.82 | — |
| 5 | −8.4 bp | **+0.516%** | 0.79 | 14.6 → 43.7 bp |
| 6 | **+206.5 bp** | **+0.732%** | 0.62 | **112 → 286 bp** |
| 7 | — | — | 0.83 | — |

## 4. Which figures work, by version

Only four versions had the full ten drawn and inspected. Legend: **Y** supports
the paper, **N** contradicts or carries no message, **A** is a measurement
artifact independent of the economics.

| figure | what it must show | 3 — Option A | 4 — sigma 0.30 | 5 — sigma 0.30 cal. | 6 — **value added** |
|---|---|---|---|---|---|
| **2** | Basic below Full/Intermediate | **Y** | N (overlap) | N (±8 bp, sign flips) | **Y** (0.5–1 pp gap) |
| **3** | high-vol slope 3x steeper | N (0.62) | N (0.82) | N (0.79) | N (0.62) |
| **4a** | oil imports fall in price | Y | Y | Y | Y |
| **4b** | output falls in price | Y | Y | Y | Y |
| **4c** | spread rises in price | Y | Y | Y | Y (needed a NaN fix) |
| **4d** | E[p'] vs volatility | **A** | **A** | **A** | **A** |
| **5** | steeper slope at high debt | Y | Y | Y | **Y** (strong) |
| **6a** | default threshold falls with price | Y | Y | Y | **Y** (2.0 → 1.1) |
| **6b** | same, high volatility | Y | Y | Y | **Y** |
| **7** | welfare gain from removing risk | **N (wrong sign)** | Y (+0.19%) | Y (+0.52%) | **Y** (+0.73%) |
| | **supporting** | 7 of 10 | 7 of 10 | 7 of 10 | **8 of 10** |

Figure sets: `results/figures_optionA/`, `figures_sigma03/`,
`figures_final_matched/`, `figures_valueadded/`.

## 5. What each version bought and cost

- **2 → 3 (common grid to per-state).** Per-state Rouwenhorst reproduces the
  oil process almost exactly (14.63% vs 14.47% in the data; the common grid
  gives 12.61%) and solves in 26 s instead of 45 min. Costs debt/GDP (42.7)
  and makes the FIGURE3 ratio unidentifiable.
- **3 → 5 (elasticity 2.0 to 0.30).** Flips the welfare sign from −3.03% to
  +0.52%, putting FIGURE7 inside the paper's claimed range. Costs FIGURE2,
  whose schedules collapse onto each other.
- **5 → 6 (value-added default cost).** The big one. Oil price risk goes from
  −8 bp to +206 bp, a 20% price move from 4 bp to 43 bp of spread, debt
  amplification up an order of magnitude. Recovers FIGURE2 *and* keeps
  FIGURE7. Costs sd(spread), 2.91 against a 2.0 target.
- **6 → 7 (risk premium).** Moves the FIGURE3 ratio 0.62 → 0.83, the only
  mechanism that moved it meaningfully the right way. Does not reach 1 at any
  usable `kappa`: crossing needs `kappa ≈ 4`, where debt/GDP falls to 18% and
  then 8%.

## 6. The one claim no version recovers

FIGURE3. Four mechanisms were tried — lower `rho_p`, an oil-price-dependent
default cost, the value-added default cost, and a risk premium. The first
three pushed the ratio *further* below 1; the fourth moved it toward 1 but
cannot cross without destroying the debt moment.

Worth stating plainly: **the published 3.0 was itself a grid artifact.** On
per-state grids the node2→node6 price interval runs 1.2371 (state 1) to 5.9112
(state 5), and the submitted code divided every state by state 3's interval —
a 2.13x distortion between states 2 and 4. Measured correctly the ratio is
about 1.0 on the common grid (1.03) and 0.6–0.8 on the per-state grid. There
was never a true 3x to reproduce.

## 7. Recommendation

Take **version 6**. It fits three of four Table 3 moments, supports eight of
ten figures, and carries the paper's central mechanism an order of magnitude
more strongly than the submitted model. Report the FIGURE3 correction as a
finding rather than defending the original number.
