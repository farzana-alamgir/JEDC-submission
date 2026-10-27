# Nested-solver diagnostic results

**Neither model converged. No final amplification or precautionary-borrowing
result can be certified from these runs.** Calibration, equilibrium equations,
and grids were held fixed at corrected-volatility commit 0f27ce0. All changes
were confined to isolated solver copies and diagnostic scripts.

| Diagnostic | Full stochastic volatility | Mean-preserving stochastic volatility |
|---|---:|---:|
| Bellman sweeps | 600 | 600 |
| Price-schedule updates | 5 | 5 |
| Final value change | 1.61e-9 | 1.18e-9 |
| Final paid-price change | 0.01530 | 0 |
| Final default switches | 0 | 0 |
| Final borrowing-choice switches | 1 | 0 |
| Independent maximum pricing residual | 0.04223 | 0.03852 |
| Independent median pricing residual | 3.54e-6 | 2.99e-6 |
| Independent 99th-percentile pricing residual | 0.001875 | 0.001605 |
| Fraction of schedule entries above 1e-6 | 62.98% | 60.96% |
| Status | Iteration limit; not converged | Iteration limit; not converged |

All residuals are in model units, not basis points. The independent pricing
calculation uses the final saved defaults and continuation prices, recomputes
expected lender payoffs over all future states, and compares them with every
saved issuance price. Its maximum agrees with the Fortran diagnostic to about
5e-12, consistent with the precision of text output.

## What this establishes

At a fixed issuance-price schedule, the borrower problem settled below 1e-9 in
each of the first four price steps. The fifth step was interrupted by the total
600-sweep cap. This isolates a distinction the original value-only stopping rule
misses: values and decisions can settle while lender prices still violate their
zero-profit equation. MP has no final policy changes and zero final paid-price
change, yet its pricing residual is approximately 0.0385.

The sampled switching states have median absolute repayment-minus-default value
gaps of about 1.21e-7 (full) and 5.54e-8 (MP). Small differences near the default
boundary can therefore induce discontinuous payoff changes. Sampling did not
capture every transition, so these medians describe captured examples only.
They do not prove the cause of all pricing errors.

Both models' worst independent pricing residual occurs at the upper price grid
boundary: price 10.1650, log endowment zero, volatility index 4, proposed debt
10.24195. The full model stores price 0.25480 versus the equation's 0.29703;
the MP model stores 0.25501 versus 0.29353. This makes boundary treatment a
specific target for investigation. Errors also occur elsewhere; the maximum
cannot be dismissed as the only inaccurate entry.

## Limits and next steps

Five price updates are not enough to establish that nested iteration cannot
converge. The pricing residual rose after the third update, then fell over the
fourth and fifth. This run establishes nonconvergence within the stated budget,
not a mathematical cycle or nonexistence of equilibrium.

Before using these solutions in the paper, test longer outer iteration with a
cheaper adaptive inner tolerance, verify the oil-price boundary treatment, and
check sensitivity to a finer debt grid or continuous interpolated debt choices.
The latter is a numerical discretization check; any resulting policy and price
must still satisfy the same borrower and lender equations. None of these tests
has been completed here. Do not change preferences, default costs or oil-process
parameters merely to restore the desired claims.

The earlier provisional mechanism comparisons remain provisional. No new
headline economic estimates were generated from these failed solves. Original
model source is unchanged; nothing was committed or pushed. All solve processes
have finished.

See summary.json, *_outer_steps.csv, *_independent_pricing_check.json, complete
compact histories, generated-source diffs, and provenance manifests here. The
large complete numerical outputs are retained in ignored raw/ directories.
