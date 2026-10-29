# Amplification and precautionary-borrowing checks

Date: 2026-10-26. These are new analyses of archived solved policies. The sovereign
model, calibrations, and saved solutions were not changed or re-solved. Nothing
in this folder should be described as a newly converged equilibrium.

## Answer in plain language

The archived solutions do not establish the paper's headline threefold
amplification or a broad increase in borrowing under high volatility. Some states
show these behaviors, but the effects are state dependent and sensitive to
calibration and policy discontinuities. Important convergence limitations make
the results provisional.

In the most recent archived calibration (`fin2`, d1=0.3847), at the central
endowment state and an approximately 10% increase in the oil price:

| Economy | Initial debt / annual gross output | Spread increase, low volatility | Spread increase, high volatility | High / low | Additional next debt under high volatility |
|---|---:|---:|---:|---:|---:|
| Full SV | 25.66% | 2.430 bp | 2.429 bp | 1.000 | 0 |
| Full SV | 35.40% | 6.299 bp | 4.847 bp | 0.769 | 0 |
| Mean-preserving SV | 25.66% | 2.413 bp | 2.563 bp | 1.062 | 0 |
| Mean-preserving SV | 35.40% | 6.050 bp | 5.378 bp | 0.889 | 0 |

Additional debt is zero at both price endpoints for these four comparisons.
At the representative 56.63% debt ratio, the country defaults in both volatility
states, so no ordinary borrowing/spread response is reported.

These entries use the SAME actual current debt, endowment, and physical price
endpoints across volatility states and the full/mean-preserving models. They
avoid moving-grid and changing-debt-denominator comparisons.

## Design

- Main calibration: `fin2`, d1=0.3847; sensitivity calibration: `fin`, d1=0.37.
  Both use alpha=0.3, theta=0.5, beta=0.96, corrected log-variance convention,
  relative 1e-10 oil-demand tolerance, a shared 549-node physical price grid,
  21 endowment states, 100 debt states and five volatility states.
- Both archived configurations use plain Tauchen (`use_moment_matching=.false.`),
  whereas the current repository source has moment matching enabled. The archived
  sources have kappa_risk=0; the differing risk-kernel code is therefore inactive.
  This is not an evaluation of the current source's enabled moment-matching switch.
- Primary volatility contrast: stored states 1 and 5 (approximately minus/plus
  two stationary log-volatility-state standard deviations). A smaller contrast,
  states 2 and 4, is also checked.
- Initial prices: nearest common nodes to exp(0.12) times 0.8, 1.0, or 1.2.
  Price increases: nearest common nodes to 5%, 10%, or 20% increases. The actual
  main contrast is 1.12749685 to 1.24148031, a 10.1094% increase. There is no
  extrapolation, smoothing, or interpolation of discrete borrowing policies.
- In every contrast, current debt and endowment are held fixed. Debt/GDP labels
  use initial annual gross production, 4*x(y,p0), solely to select/report the
  physical debt state; the denominator is NOT recomputed to measure borrowing.
- Broad grid domain: initial debt / annual gross output between 10% and 70%,
  and log endowment between -0.15 and +0.15. The primary contrast contains 748
  initial states, of which 479 repay at both price endpoints and both volatility
  extremes in the full fin2 model; the MP model has 477. Default coverage is
  reported separately instead of treating default as zero borrowing/spreads.
- Net issuance is b'-(1-delta)*b. Since b is fixed, high-minus-low differences
  in issuance and next-period debt are identical. Both levels are reported.
- Spread is annualized in basis points using the source's coupon/decay
  convention: 10000*[(1+coupon/q-delta)^4-(1+coupon/q_rf-delta)^4]. q is taken at
  the chosen next-period debt. A second calculation fixes proposed issuance at
  the mean-volatility policy at p0 to distinguish lending-schedule changes from
  changes in the government's chosen debt.

## Broader state checks

For the central-price, approximately 10% shock and extreme volatility contrast:

| Calibration / economy | Median amplification ratio | States with more next debt under high volatility | States with unchanged next debt |
|---|---:|---:|---:|
| fin2 full SV | 1.003 | 4.57% | 93.97% |
| fin2 mean-preserving SV | 1.048 | 12.27% | 86.90% |
| fin full SV | 1.104 | 6.78% | 91.53% |
| fin mean-preserving SV | 1.120 | 9.95% | 89.08% |

These are **equal-weight grid coverage statistics**, not simulated frequencies,
population probabilities, or significance tests. Ratio calculations require
repayment in all four states and a low-volatility spread response above 0.1 bp,
to avoid dividing by near-zero responses. Borrowing coverage requires repayment
at the initial price under both volatility states. Thus the denominators differ.

The all-state mean response is sensitive to large changes in debt choices near
default. For example, in fin2 full SV the mean high-minus-low response is -12.21
bp while 53.03% of common-repayment states show a larger high-volatility response.
The median ratio is much more representative of the typical grid comparison.
The fixed-issuance mean amplification is +4.35 bp in that same configuration,
showing that lending-schedule and endogenous-debt responses are distinct.

The full-model increase in debt is not widespread and disappears at the four
representative states above. Positive changes survive mean preservation in some
other states. This does NOT identify their motive as insurance against future
financing costs; additional mechanism evidence would be required for that label.

## Numerical checks and limitations

1. All physical grids match across the four solutions. Chosen-debt prices
   reconstruct the saved paid-price arrays to less than 1e-9 (observed zero).
2. The MP kernel's next-price conditional mean is flat across volatility at the
   tested prices to about 1e-15 relative precision. This is a one-period statement,
   not proof that all future expected price paths are identical.
3. Archived value-function iteration changes satisfy the original 1e-3 stopping
   criterion, with 138-143 iterations. **Bond prices do not satisfy an equivalent
   global stopping test:** maximum last-iteration paid-price changes range from
   about 0.68 to 0.93 across the four solutions. These can include default flips,
   but must not be ignored when asserting a converged economic equilibrium.
4. An independent one-step zero-profit calculation, using final default and
   borrowing policies, checks the saved prices. At the two representative full
   fin2 states it changes the low/high responses from 2.430/2.429 to 2.375/2.397
   bp, and from 6.299/4.847 to 6.026/4.812 bp. This does not restore threefold
   amplification. It is a residual diagnostic, not a re-solved equilibrium.
5. The debt grid spacing is about 0.20484 model units. Identical choices on that
   grid do not prove that an arbitrarily small continuous borrowing effect is
   zero. Debt-grid refinement is needed before making such a statement.
6. No stationary-distribution weighting, sampling standard errors, or empirical
   tests are used. No claim about the welfare effects is made here.

## Files and reproduction

- `summary.csv`: 72 contrast summaries (two calibrations x two economies x three
  starting prices x three price increases x two volatility contrasts).
- `representative_states.csv`: detailed comparisons at three endowment levels
  and the three debt ratios discussed in the paper.
- `state_details.csv`: each primary-comparison state, including repayment status.
- `default_transitions.csv`: default coverage for every contrast.
- `distribution_summary.csv`: ratio distributions and borrowing coverage.
- `provenance.json`: archived source/solution paths, SHA-256 hashes, parameters,
  iteration diagnostics and consistency checks. The archive lives under /tmp;
  preserve those solution files before cleaning temporary directories. This
  repository contains the derived results and audit hashes, not the multi-GB
  archived solver outputs.

Run with a NumPy-enabled Python:

```
python3 model/claim_tests/test_claims.py --archive /path/to/scratchpad
```

The archive must contain fin/src_bm.f90, fin/src_mp.f90 and their run_bm/run_mp
outputs, and the corresponding fin2 files. The script only reads those inputs
and writes derived results into this folder.

## What is established, and the next required work

The controlled comparisons do not reproduce broad threefold amplification or
broad precautionary borrowing in the archived candidate calibrations. They do
not prove that either behavior is impossible in this model class.

Before adopting or rejecting the mechanisms definitively, re-solve an isolated
baseline with explicit value, bond-price, default-policy and borrowing-policy
convergence checks, then repeat on finer debt grids. Compare full and MP models
at fixed structural parameters and identical physical states. Do not recalibrate
to recover the original headline multipliers.
