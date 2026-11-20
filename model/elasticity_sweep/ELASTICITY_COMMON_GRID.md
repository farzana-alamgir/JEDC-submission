# Oil substitution elasticity, redone on the adopted setup

Common grid (`p_num = 277`), oil price process estimated on 1995Q1–2019Q4,
`beta = 0.970654`, `d1 = 0.468505`. Benchmark and constant-price economy at
each elasticity. Runs in `sweep/sig*_{benchmark,basic}`.

This supersedes `results/ELASTICITY_SWEEP.md`, which was solved on the
**per-state** grid (`p_num = 7`) — the discretisation that reverses Figure 3
and reproduces only 73% of the Jensen lift.

## alpha is pinned to sigma, not free

The oil share is `s(p) = alpha^sigma * p^(1-sigma)`, so alpha has to move with
sigma or the share drifts off its 9% target. Each alpha here holds
`alpha^sigma * E[p^(1-sigma)]` at the value the adopted calibration implies
(0.100790), computed under the adopted benchmark's own simulated price
distribution. By construction the rule returns `alpha = 0.000307` at
`sigma = 0.30`, so the sweep passes exactly through the adopted point.

| sigma | theta | alpha | realised oil/GDP |
|---|---|---|---|
| 0.20 | −4.0000 | 4.709e−06 | 9.10% |
| 0.25 | −3.0000 | 5.779e−05 | 9.23% |
| **0.30** | **−2.3333** | **3.070e−04** | **9.27%** |
| 0.35 | −1.8571 | 1.011e−03 | 9.35% |
| 0.40 | −1.5000 | 2.467e−03 | 9.42% |
| 0.50 | −1.0000 | 8.579e−03 | 9.57% |

The share holds to within 0.5pp across a 2.5x range of elasticity.

## 1. Debt/GDP identifies the elasticity

| sigma | spread (t 4.10) | sd (t 2.00) | **debt/GDP (t 34.0)** | oil/GDP (t 9.0) |
|---|---|---|---|---|
| 0.20 | 4.263 | 3.132 | **36.22** | 9.10 |
| 0.25 | 4.288 | 3.057 | **34.83** | 9.23 |
| **0.30** | 4.180 | 3.115 | **33.25** | 9.27 |
| 0.35 | 4.098 | 3.025 | **31.53** | 9.35 |
| 0.40 | 4.130 | 3.067 | **29.86** | 9.42 |
| 0.50 | 4.180 | 3.098 | **26.03** | 9.57 |

Spread sits near target at every elasticity (4.10–4.29) and the oil share
barely moves, so neither pins sigma. **Debt/GDP does**: it falls monotonically
from 36.2 to 26.0, and the 34.0 target is met at **sigma ≈ 0.28**. At
sigma = 0.50 the moment misses by 8 points of GDP.

That is the defensible answer to "why sigma = 0.30": it is not a free choice,
it is the value at which the debt moment is matched. Worth stating explicitly
in the calibration section.

`sd(spread)` is 3.03–3.13 everywhere. **No elasticity fixes it.** That miss is
not about the production structure.

`sd(dlog oil price)` is 14.323 at every sigma, as it must be — alpha and theta
do not enter the price process. A useful check that the sweep changed only
what it was supposed to.

## 2. Welfare of removing oil price risk

Consumption-equivalent, benchmark → constant price, at debt node 44
(8.8081 model units; the debt grid is identical across all six runs).

| sigma | CEV |
|---|---|
| 0.20 | +0.4041% |
| 0.25 | +0.3926% |
| **0.30** | **+0.1170%** |
| 0.35 | +0.2116% |
| 0.40 | +0.1224% |
| 0.50 | **−0.0716%** |

**The sign still flips, but later than previously reported.** The per-state
sweep put the crossing at `sigma ≈ 0.40`; on the common grid it is between
0.40 and 0.50, around **0.47**. The adopted 0.30 is further from the boundary
than it looked.

**But the level at the adopted point is well below what the paper claims.**
The per-state sweep reported +0.49% at sigma = 0.30 and the paper claims a
range of +0.2% to +1.1%. Here the adopted calibration gives **+0.117%**, which
is outside that range. The claim needs restating, not just renumbering.

### The curve is not monotone, and that is a warning

0.25 → +0.393, 0.30 → +0.117, 0.35 → +0.212, 0.40 → +0.122. A welfare measure
that is genuinely a function of the elasticity should not zigzag like this. The
likeliest cause is that `beta` and `d1` are held fixed across the sweep, so
ergodic debt runs from 36.2% to 26.0% of GDP while the CEV is read at one fixed
absolute debt node — node 44 sits at a different point in each economy's own
distribution, and nearer the default region it is worth more to shed risk.

I am not able to verify that from these runs, and the ordering at 0.25 cuts
against it. **Do not quote the shape of this curve.** The two things it does
support are the sign flip near 0.47 and the level at the adopted point, both of
which are read within a single sigma.

Resolving it needs `beta` and `d1` recalibrated at each elasticity so every
economy sits at the same ergodic debt — about 10–12 hours of compute, and the
same exercise would make the spread channels readable.

## 3. The spread channel is still not identified

| sigma | bm spread | basic spread | gap | bm debt | basic debt |
|---|---|---|---|---|---|
| 0.20 | 4.263 | 2.226 | +203.8 ± 5.0 | 36.22 | 38.63 |
| 0.25 | 4.288 | 2.324 | +196.4 ± 5.2 | 34.83 | 37.25 |
| **0.30** | 4.180 | 2.296 | **+188.4 ± 5.1** | 33.25 | 35.26 |
| 0.35 | 4.098 | 1.986 | +211.2 ± 4.8 | 31.53 | 33.36 |
| 0.40 | 4.130 | 2.083 | +204.8 ± 4.8 | 29.86 | 31.47 |
| 0.50 | 4.180 | 2.489 | +169.1 ± 5.1 | 26.03 | 27.46 |

Same caveat as the old sweep: `beta` and `d1` are not recalibrated, so each
economy sits at a different point on a nonlinear default frontier and the gaps
are not comparable across rows.

What can be said is weaker but not nothing: the level channel is **large at
every elasticity tried**, 169–211 bp over a range where ergodic debt moves by
10 points of GDP. It does not vanish anywhere in the plausible range. That is a
robustness statement about the surviving channel, not an estimate of how it
varies with sigma.
