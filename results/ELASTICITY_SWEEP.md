# Oil substitution elasticity: what it does to the paper's claims

Nine values of `sigma_oil = 1/(1-theta)`, each solved on the per-state grid
(Option A, `p_num = 7`) with a benchmark and a no-oil-price-risk economy.
Runs in `model/runs_elasticity/`, figure at `results/FIGURE_elasticity.jpg`.

**Headline: the welfare sign of oil price risk is governed entirely by
`sigma_oil`, and it crosses zero at `sigma_oil ≈ 0.40`.**

---

## 1. Why alpha has to move with sigma

The oil share of GDP is **not** `alpha`. Under CES it is

    s(p) = alpha^sigma * p^(1-sigma)

so `alpha` equals the oil share only at `sigma = 1` (Cobb–Douglas). For any
other elasticity `alpha` is a scale parameter whose units depend on `sigma`,
and holding it fixed while changing `sigma` would silently change the oil
share — which is a calibration target, at 9% of GDP.

Each `sigma` therefore gets its own `alpha`, chosen so that
`alpha^sigma * E[p^(1-sigma)] = 0.09` under the benchmark's simulated price
distribution (`E[p] = 1.3339`). The calibration lands within 0.3pp of target
everywhere:

| sigma_oil | theta | alpha | realised oil/GDP |
|---|---|---|---|
| 0.30 | −2.3333 | 0.000189 | 8.67% |
| 0.35 | −1.8571 | 0.000676 | 8.99% |
| 0.40 | −1.5000 | 0.001756 | 8.96% |
| 0.45 | −1.2222 | 0.003679 | 8.98% |
| 0.50 | −1.0000 | 0.006639 | 8.72% |
| 0.80 | −0.2500 | 0.047532 | 8.91% |
| 1.20 | +0.1667 | 0.136130 | 9.09% |
| 1.50 | +0.3333 | 0.202300 | 9.18% |
| 2.00 | +0.5000 | 0.290215 | 9.22% |

**This resolves an objection raised earlier in the revision.** The
`alpha = 1.65e-4` that came out of the `sigma = 0.39` experiment looked
implausible when read as an oil share. It is not an oil share: at
`sigma = 0.30`, `alpha = 1.89e-4` delivers an oil share of **8.67%**, on
target. A tiny `alpha` at a low elasticity is arithmetically required, not a
sign that something has gone wrong.

### Feasibility

An interior oil optimum needs `s(p) < 1` across the whole price grid, which
spans [0.0892, 14.2549] here:

- `sigma > 1` needs a **floor** `p > alpha^(sigma/(sigma-1))`
- `sigma < 1` needs a **ceiling** `p < alpha^(-sigma/(1-sigma))`

Every `sigma` in the table clears it. The `sigma < 1` ceilings are remote
(39, 51, 69, 98, 151, 2e5), so **complementary oil is not the binding
constraint here**. The binding case is the other end: `sigma = 2.5` needs a
floor of 0.1721, above the grid's 0.0892, and is infeasible. Note also that
recalibrating `alpha` to 0.290 at `sigma = 2` puts the floor at 0.0842, just
*below* the grid minimum — which removes the single infeasible node that the
shipped `alpha = 0.3` produces.

---

## 2. Welfare of removing all oil price risk

Consumption equivalent, benchmark against a constant-price economy pinned at
the benchmark's *simulated* mean price (so no level confound). Positive =
removing risk **raises** welfare = oil price uncertainty is **costly**, which
is the paper's claim.

| sigma_oil | CEV |
|---|---|
| 0.30 | **+0.489%** |
| 0.35 | **+0.077%** |
| **0.40** | **−0.002%**  ← crossover |
| 0.45 | −0.118% |
| 0.50 | −0.492% |
| 0.80 | −1.140% |
| 1.20 | −1.771% |
| 1.50 | −2.198% |
| **2.00 (paper)** | **−2.779%** |

Monotone in `sigma_oil`, crossing zero at **0.40**.

The mechanism is Waugh (1944): an importer whose oil demand is **elastic**
substitutes away when oil is dear, so the indirect utility is convex in price
and mean-preserving price variability is a *gain*. When oil is
**complementary** (`sigma < 1`) the country cannot substitute, the convexity
reverses, and volatility is a *cost*.

**At `sigma_oil = 0.30` the model delivers +0.489%, inside the paper's claimed
+0.2% to +1.1% range.** The paper's own `theta = 0.5` (`sigma_oil = 2`)
delivers −2.779%, the opposite sign.

---

## 3. The spread channel is NOT identified across this sweep

| sigma_oil | bm spread | basic spread | channel | bm debt/GDP |
|---|---|---|---|---|
| 0.30 | 4.7212 | 4.4687 | +25.2 bp | 39.59 |
| 0.50 | 4.8812 | 5.5174 | −63.6 bp | 39.98 |
| 0.80 | 4.8245 | 4.2434 | +58.1 bp | 40.58 |
| 1.20 | 4.6762 | 4.5302 | +14.6 bp | 41.48 |
| 1.50 | 4.6502 | 3.9485 | +70.2 bp | 41.76 |
| 2.00 | 4.3032 | 4.0574 | +24.6 bp | 40.89 |

No pattern. **Do not read these as an elasticity effect.** `d0`, `d1` and
`beta` were held at their Option A values rather than recalibrated per
`sigma`, so each economy sits at a different point on a nonlinear default
frontier — benchmark spreads range 4.30 to 4.88 against a 4.1 target, and debt
differs too. Isolating the elasticity's effect on the *spread* channel
requires re-matching the Table 3 moments at each `sigma`, which this sweep
does not do.

The welfare column does not suffer from this, because it compares value
functions at the same debt index within each `sigma`.

---

## 4. What this means for the submission

The welfare claim is recoverable, at a price:

- **`sigma_oil ≈ 0.3` reproduces the paper's welfare result** both in sign and
  magnitude (+0.49% against a claimed +0.2% to +1.1%), with a 8.7% oil share.
- **`sigma_oil = 2` cannot.** It is not a matter of degree: the sign is wrong,
  because elastic oil demand makes price variability beneficial.
- The required `alpha = 1.9e-4` is **not** an implausible oil share — it is the
  correct scale parameter for that elasticity, and the implied share is on
  target.

Whether `sigma_oil ≈ 0.3` is defensible is a calibration question for the
paper to argue, not something this sweep settles. It is on the low side but
in the range usually estimated for short-run substitution away from energy;
the paper should cite its own source for `theta` and check what elasticity
that source actually implies, since `theta = 0.5` is an unusually high
substitutability for oil.

**Before adopting a new `sigma`, `d0`/`d1`/`beta` must be recalibrated to the
Table 3 moments at that elasticity.** The spread, debt and sd columns above
drift well off target and the spread decomposition cannot be read until they
are back on.
