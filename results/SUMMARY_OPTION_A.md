# Option A — results on the submitted (per-state) price grid

All four economies re-solved with `use_common_p_grid = .false.`, `p_num = 7`:
the grid construction of the submitted paper. Every other correction from this
revision is retained — the `exp(h/2)` volatility convention, the relative
bisection tolerance, double-precision literals, `d1 = 0.3847`, `alpha = 0.3`,
`theta = 0.5`, CRRA `sigma = 2`.

Runs are in `model/runs_optionA/{bm,mp,intermediate,basic,basic_matched}`,
figures in `results/figures_optionA/`, raw claim output in
`results/OPTION_A_claims_output.txt`. One economy solves in **26 seconds**
(against ~45 minutes at `p_num = 549`).

---

## 1. Why the grid matters, and what it is

`discretize_AR` is **Rouwenhorst**, which matches an AR(1)'s mean, variance and
autocorrelation *exactly for any n ≥ 2*, including at `rho_p = 0.98` where
Tauchen loses variance. Seven nodes per state were never too few to represent
each state's process. That is the central reason Option A is viable.

Each volatility state gets its own grid, symmetric in logs about `mean_p` with
half-width `sqrt(p_num-1) * sd_k / sqrt(1-rho_p^2)`. All five share only the
central node, `exp(0.12) = 1.1275`:

| vol state | cond. sd | min node | max node | node2→node6 interval |
|---|---|---|---|---|
| 1 | 0.0639 | 0.5136 | 2.4753 | 1.2371 |
| 2 | 0.0857 | 0.3930 | 3.2346 | 1.7180 |
| 3 | 0.1147 | 0.2746 | 4.6296 | 2.4514 |
| 4 | 0.1537 | 0.1698 | 7.4860 | 3.6638 |
| 5 | 0.2059 | 0.0892 | 14.2549 | 5.9112 |

Note the construction treats each state's volatility as **permanent** (it
divides by `1-rho_p^2`), even though volatility is transitory at
`rho_p_vol = 0.66`. That is what stretches state 5 out to a price of 14.25.

---

## 2. Where Option A beats the common grid

**The oil price process is reproduced almost exactly.** Rouwenhorst's exactness
at `rho_p = 0.98` is worth real accuracy:

| | sd(Δlog p), simulated |
|---|---|
| **Option A (per-state, 7 nodes)** | **14.63%** |
| common grid (549 nodes, Tauchen) | 12.61% |
| **data, 1995–2019** | **14.47%** |

**Table 3 moments** (benchmark economy):

| moment | target | Option A | common grid |
|---|---|---|---|
| mean spread (annual, %) | 4.1 | **4.21** | 4.02 |
| sd(spread) | 2.0 | 2.33 | **2.25** |
| debt/GDP (%) | 34.0 | 42.74 | **33.5** |
| oil share of GDP (%) | 9.0 | **9.95** | 9.9 |

Option A wins on the price process and the mean spread; it loses clearly on
debt/GDP (42.7 against a target of 34.0).

All four economies:

| economy | spread | sd | debt/y | oil/y | default rate |
|---|---|---|---|---|---|
| full (bm) | 4.2056 | 2.3267 | 42.74 | 0.0995 | 0.0163 |
| mean-preserving | 4.2206 | 2.2672 | 43.01 | 0.1002 | 0.0158 |
| intermediate | 4.4589 | 2.4100 | 41.82 | 0.1016 | 0.0166 |
| basic | 3.9722 | 2.5206 | 39.70 | 0.0655 | 0.0153 |
| basic, matched E[p] | 4.1342 | 1.8222 | 40.13 | 0.0675 | — |

---

## 3. A bug this exposed: `constant_vol` never fired

The `constant_vol` override sat **inside** the `if (use_common_p_grid)` branch,
so with the per-state grid the intermediate economy silently solved with full
stochastic volatility — identical to the benchmark on every moment, to four
decimals. Fixed by adding the override to the per-state branch
(`oil_prod_CES.f90`, after the `discretize_AR` call for `p_vol_grid`); the
common-grid path is untouched. `h` is now pinned at
`mu_h + var_h/2 = -4.1585`, a conditional sd of 12.50%.

This bug would have made the "time-varying volatility" channel exactly zero by
construction on any per-state run.

---

## 4. A real constraint this exposed: the CES feasibility floor

With `theta = 0.5`, `sigma_oil = 1/(1-theta) = 2`, and the interior-oil-optimum
floor is `alpha^(1/theta) = 0.3^2 = 0.09` — a constraint the solver's own
header documents. Volatility state 5's lowest node is **0.0892**, just below it.
There output diverges: **7.7e10** against a maximum of **29.2** at every other
node in the model.

Two consequences, which differ sharply:

- **The solution is fine.** CRRA at `sigma = 2` gives `u(c) = -1/c`, bounded
  above by zero, so unbounded consumption contributes essentially nothing:
  `max|V|` moves only 5.409 → 5.431 across volatility states. Value and policy
  functions are uncontaminated.
- **Means of output are destroyed.** Unmasked mean output is `2.21e9` instead
  of `6.75`. This collapsed the Debt/GDP axis of FIGURE2 onto zero and is
  exactly why the Full Model line was invisible there.

Handled by masking that one node of 35 (`script_bm.m`,
`check_claims_optionA.m`) and by NaN-ing the 31 simulated rows of 750,000
(0.004%) that visit it. The common grid never hit this because `p_width_sd=3.5`
keeps its floor at 0.125.

---

## 5. The decomposition, with a level confound removed

The basic economy pins log p at `mean_p + 0.5*Var(log p)`, targeting the
*theoretical* `E[p] = 1.3735`. But the benchmark's *simulated* mean price is
**1.3339** — Rouwenhorst matches log-moments, not level moments. So the basic
economy was facing oil 3.0% dearer than the full model, and the gap was being
attributed to risk. `basic_matched` re-pins at `log(1.3339)`.

| channel | unmatched | **matched E[p]** |
|---|---|---|
| oil price risk (full − basic) | +23.3 bp | **+7.1 bp** |
| time-varying volatility (full − intermediate) | **−25.3 bp** | — |
| mean-preserving (full − mp) | −1.5 bp | — |

**Two-thirds of the apparent oil-price-risk channel was a price level effect.**
The pure risk channel is +7.1 bp.

The time-varying-volatility channel is **negative**: the constant-volatility
economy carries a *higher* mean spread (4.4589) than the full model (4.2056).
On the common grid this channel was +0.1 bp. It is not robust across grids.

---

## 6. The four claims

Raw output: `results/OPTION_A_claims_output.txt`.

### [1] Spread-slope state dependence — **not identified on this grid**

| method | vol 2 | vol 3 | vol 4 | ratio 4/2 |
|---|---|---|---|---|
| fixed-index (as submitted) | 0.00297 | 0.00412 | 0.00489 | **1.65** |
| matched-price | 0.00830 | 0.00662 | 0.00524 | **0.63** |

The paper claims ≈3.0. The two methods disagree in *sign*, and neither is
trustworthy:

- The **fixed-index** method differences each state's own nodes but divides
  every state by state 3's interval. Since the intervals run 1.24 → 5.91,
  wider-grid states get a larger numerator over an unchanged denominator. The
  state4/state2 interval ratio alone is 2.13 — most of the claimed 3×.
- The **matched-price** method is contaminated in the opposite direction. The
  slope is *identical* at ±5%, ±10% and ±20% contrasts, because every contrast
  falls between the same two bracketing nodes — it is one fixed chord whose
  span is set by that state's spacing, not a derivative. Only 1 interior node
  (the shared centre) lies inside ±10% in any state.

Widening the contrast until it spans several nodes drives the ratio to
**1.02**, matching the common grid's **1.03**. That is the defensible number:
**there is no meaningful state dependence in the spread slope.**
Evidence: `model/analysis/fig3_resolution_test.m`.

### [2] Debt amplification — **CONFIRMED**

| debt/GDP | slope (bp per unit price) |
|---|---|
| 0.144 | 19.2 |
| 0.220 | 27.5 |
| 0.296 | 51.3 |
| 0.326 | 66.2 |
| 0.372 | 62.6 |
| 0.448 | 198.2 |

Monotone apart from one dip, and an order of magnitude across the range. This
is the paper's most robust quantitative claim and it survives on both grids.

### [3] Debt slope by volatility state — **cannot be measured**

The ±10% price contrast falls **inside a single grid cell** in all three
states, so `b_next` does not change and the derivative is undefined. This is
the direct cost of 7 nodes. On the common grid the slope was 0.020–0.067 and
*identical* across volatility states, against the paper's claimed
0.16 / 0.25 / 0.70.

### [4] Welfare (consumption equivalent, at mean debt)

| comparison | CEV |
|---|---|
| full → intermediate (remove time-varying vol) | **+0.148%** |
| full → basic (remove all oil price risk) | **−3.183%** |
| full → basic, matched E[p] | **−3.030%** |

Unlike the spread, this is **not** a level confound — correcting E[p] moves it
only 0.15pp. Removing oil price risk genuinely *lowers* welfare by ~3%.

That is economically coherent, not a bug: at `theta = 0.5` the oil elasticity
is `sigma_oil = 2`, i.e. **elastic**. An importer with elastic demand gains
from price variability by substituting away when oil is dear — the Waugh
(1944) result. The sign of this welfare channel is therefore a direct
consequence of the calibrated `theta`, and would flip for `theta < 0`
(`sigma_oil < 1`, complementary oil).

---

## 7. What this means for the submission

Standing on Option A:

- **Keep:** the price process is now excellent (14.63% vs 14.47%), the mean
  spread is on target (4.21 vs 4.1), the oil share is on target, and debt
  amplification — the paper's central mechanism — is confirmed and strong.
- **Must be restated:** the 3× spread-slope state dependence (Figure 3). It is
  a grid artifact in the submitted construction, and the honest estimate is
  ≈1.0 on both grids. The corrected Figure 3 orders the curves *opposite* to
  the submitted one.
- **Must be restated:** the welfare sign. Oil price risk raises welfare here
  because oil demand is elastic at `theta = 0.5`.
- **Weak:** the oil-price-risk spread channel is +7.1 bp once the price level
  is matched, and the time-varying-volatility channel is −25.3 bp here against
  +0.1 bp on the common grid — not robust.
- **Worse than the common grid:** debt/GDP, 42.7 against a target of 34.0.

The one claim that is clean, large and grid-robust is **debt amplification**.
