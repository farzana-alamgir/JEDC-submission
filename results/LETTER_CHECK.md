# Does the R2 M1 / R1 M2 letter survive the re-estimated price process?

> **STATUS (2026-11-19): acted on.** The paper adopted sigma_oil = 0.25 after
> this check was written, so the numbers below — measured at sigma = 0.30 — are
> superseded. `results/response_R2M1_R1M2.md` has been rewritten against the
> sigma = 0.25 runs. Of the four edits prescribed at the end, all four were made,
> plus a fifth this check did not anticipate: the claim that volatility-induced
> debt reductions *vanish* under the correction is false at sigma = 0.25 (they
> fall from 9 to 3 at the baseline price, not to 0) and has been corrected.
>
> What carried over unchanged: the overshoot. It is a property of
> rho_p = 0.9475, not of the elasticity, so residual/full is still -1.35 at 20
> quarters and the caveat is still load-bearing.
>
> What reversed: at sigma = 0.25 the TOTAL time-varying channel is +13.4 +/- 6.0
> and *excludes* zero, where at sigma = 0.30 it was -2.4 and did not. The split
> is +12.1 expected price (excludes zero) and +1.3 dispersion (does not).

Checked `results/response_R2M1_R1M2.md` claim by claim against
`newproc/common_cal_*`. The letter uses the common grid throughout
(`src_spdebt`, `use_common_p_grid = .true.`), so the per-state +38.3 bp
Jensen term is **not** a threat to it — I overstated that yesterday. The
letter never claims a non-zero mean-preserving effect; it claims the opposite,
and on the common grid that is still true.

`decomposition.py` and `horizon_check.py` reproduce the letter's published
numbers exactly on the old runs, so this is apples to apples.

| letter's claim | as published | estimated process, common grid | verdict |
|---|---|---|---|
| one-step correction exact, matches closed form | +1.94% swing | +1.7620%, matches e^(v/2) to 5 dp; corrected flat to -0.0000 | **holds** |
| total TV effect | +6.3 [-2.4, 15.0] | -2.4 +/- 6.4 | **holds** (still zero) |
| of which dispersion | +3.0 [-5.8, 11.8] | +6.0 +/- 6.4 | **holds** (still zero) |
| of which expected price | +3.3 [-5.6, 12.2] | **-8.4 +/- 6.5** | **FAILS** — sign flips, excludes zero |
| level effect | +219 +/- 6.5 bp | +188.4 +/- 5.1 bp | number moves, claim holds |
| "thirty times the time-variation channel" | 219 / 6.3 | TV channel is negative | **phrasing breaks** |
| dispersion raises conditional spreads 37-51 bp | 36.98, 50.71 | **+50.1 bp**, monotone across all five states | **holds, slightly stronger** |
| overshoot "does not change any conclusion" | residual/full -0.41 at 20q | **-1.35 at 20q** | **FAILS** — residual exceeds the effect |
| debt reductions vanish under the correction | full 4 more/10 less; mp 7 more/0 less | full 2/10; mp 4/0 | **holds** |

## The two failures are one fact

With rho_p = 0.9475 instead of 0.98 the price mean-reverts faster, so the
one-step drift correction overshoots sooner and harder:

| horizon | full swing | mean-pres residual | residual / full |
|---|---|---|---|
| 1 q | +1.76% | -0.00% | 0.00 |
| 4 q | +3.67% | -0.37% | -0.10 |
| 8 q | +3.32% | -0.96% | -0.29 |
| **20 q** | **+1.04%** | **-1.41%** | **-1.35** |
| 40 q | +0.12% | -0.72% | -6.21 |

A coupon of 0.03 implies a duration near 25 quarters, so 20 q is where the
bond is priced. There the correction's residual is **larger than the effect it
is meant to isolate**, and pulling the other way. That is why the
expected-price component comes out at -8.4 bp: the corrected economy's
expected prices fall with volatility faster than the full economy's rise, so
the "corrected" economy prices *worse* than the full one (426.4 vs 418.0 bp).

The letter already flags this mechanism and says "at the magnitudes involved
this does not change any conclusion." At rho_p = 0.9475 that sentence is no
longer true. The one-step decomposition is not usable at the estimated
persistence.

## What survives, and it is the better half

The conditional result is unaffected and is cleaner than the letter's
fixed-state version. In the mean-preserving economy, where expected prices are
flat by construction at one step, mean spreads by volatility state are:

| vol state | sd(log p) | mean spread | mean price |
|---|---|---|---|
| 1 (calmest) | 0.0877 | 351.2 bp | 1.24746 |
| 2 | 0.1086 | 360.4 | 1.24812 |
| 3 | 0.1345 | 373.2 | 1.24122 |
| 4 | 0.1666 | 386.7 | 1.23859 |
| 5 (most volatile) | 0.2064 | **401.3** | 1.22809 |

Monotone, +50.1 bp calmest to most volatile, against a placebo noise floor of
1.5 bp — and the mean *price* is falling across those states, so this cannot
be an expected-price effect. Dispersion raises the conditional price of risk.
That is the letter's one positive claim and it is stronger here than as
published.

## What this means for sending it

**If the paper keeps the calibrated process**, the letter stands exactly as
written. Nothing found here touches it.

**If the paper adopts the estimated process**, four edits are needed:

1. All numbers regenerated (6.3 / 3.0 / 3.3 -> -2.4 / +6.0 / -8.4; 219 -> 188).
2. The overshoot caveat rewritten: at rho_p = 0.9475 the residual exceeds the
   effect at pricing horizons, so the dispersion / expected-price split should
   be dropped or reported as uninterpretable rather than reported as small.
3. The "thirty times the time-variation channel" comparison removed — the TV
   channel is negative.
4. The conditional 50.1 bp result promoted to carry the section, since it is
   the part that does identify something.

Edit 2 is the awkward one: it means conceding that the fourth economy the
referees asked for does not deliver a clean split at the estimated
persistence. The honest framing is that the exercise identifies a conditional
dispersion effect but cannot apportion average spreads, which is close to what
the letter already says — just with the caveat load-bearing instead of
incidental.

## Reproducing

    python3 decomposition.py  OUT newproc/common_cal_{benchmark,mean_preserving,intermediate,basic}
    python3 horizon_check.py      newproc/common_cal_{benchmark,mean_preserving}

Output in `newproc/decomp_common_est/`.
