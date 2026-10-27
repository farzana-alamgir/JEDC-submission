# Outcome of the current-branch solves

**No run passed the strengthened convergence checks. These are diagnostic
results, not final equilibria or final paper results.**

The exact calibration and moment-matching switch of `corrected-volatility`
commit `0f27ce0` were used in isolated copies. The MP copy changes only the
mean-preserving switch. No original model file was edited and no calibration
was adjusted to recover the paper's headline results.

## Convergence results

The undamped runs were initialized from archived policies, but recomputed the
current branch's kernels. The relaxed runs started independently from the final
undamped states. Relaxation changes only the numerical update, not the pricing
equation being solved. All runs used a 1e-6 value/price tolerance and required
unchanged default and borrowing policies. Relaxed runs also checked the raw,
undamped price-schedule residual.

| Method | Economy | Iterations | Last value change | Last paid-price change | Default switches | Debt-choice switches | Raw price-schedule residual | Status |
|---|---|---:|---:|---:|---:|---:|---:|---|
| Original updates | Full SV | 160 | 5.35e-4 | 0.6256 | 851 | 238,949 | not separately recorded | Not converged |
| Original updates | MP SV | 160 | 6.71e-4 | 0.5561 | 817 | 224,589 | not separately recorded | Not converged |
| Price relaxation 0.20 | Full SV | 300 | 3.35e-5 | 0.4971 | 11 | 19,085 | 0.02191 | Not converged |
| Price relaxation 0.20 | MP SV | 300 | 4.19e-5 | 0.5043 | 7 | 15,130 | 0.02795 | Not converged |
| Price relaxation 0.05 | Full SV | 300 | 7.06e-6 | 0.4942 | 2 | 10,279 | 0.02799 | Not converged |
| Price relaxation 0.05 | MP SV | 300 | 9.90e-6 | 0.3110 | 1 | 9,455 | 0.01432 | Not converged |

Changes are in model value/price units, not basis points. A few marginal default
switches can make the maximum paid-price change large because the reported
price switches between a positive number and zero. The raw pricing residual
is separately recorded for the relaxed runs and also remains above tolerance.

The original source's 1e-3 value-only stopping criterion would accept these
values. That is not evidence that its pricing and policies have converged.
Conversely, these failures do not prove that an equilibrium does not exist or
that either economic mechanism is impossible.

## Provisional mechanism checks

The conditional comparisons were recalculated from each set of terminal
iterates, with explicit permission to inspect nonconverged outputs. The normal
analysis entry point rejects such runs unless `--allow-provisional` is supplied.

For illustration only, below are the terminal 0.05-relaxation results at log
endowment zero, initial debt equal to 35.40% of initial annual gross output, and
an oil-price increase from 1.12750 to 1.24148 (10.109%). Identical current debt,
endowment, and physical price endpoints are used across volatility states.

| Economy | Spread response at low volatility | At high volatility | High / low | Additional debt at high volatility, before / after the price increase |
|---|---:|---:|---:|---:|
| Full SV | 6.445 bp | 5.276 bp | 0.819 | 0 / 0 |
| Mean-preserving SV | 5.827 bp | 5.644 bp | 0.969 | 0 / 0 |

These particular comparisons do not reproduce threefold amplification or more
borrowing under high volatility. They are not final verdicts: the policies and
prices are terminal iterates, and a 100-node debt grid can conceal small
continuous responses. Broad grid summaries and default coverage are provided
in each `provisional/` folder, but they are not stationary-weighted probabilities
or statistical significance tests.

The average amplification statistic changes across numerical updates, which
is further reason not to present a particular sign as a final economic result.
Nothing here assesses empirical coefficients or welfare.

## What is delivered

- Complete compact convergence histories and `solve_diagnostics.csv`.
- Source snapshots, SHA-256 provenance, compiler settings, and every numerical
  instrumentation/acceleration diff.
- Full and MP conditional-comparison tables for original, 0.20-relaxed, and
  0.05-relaxed terminal iterates, all explicitly provisional.
- A direct original-versus-accelerated calculation check: the first seven
  iterations have identical default/debt change counts; value/price
  discrepancies are at most about 4.4e-16.

See `README.md` for parameters and reproduction. Large executable/output files
remain in ignored `raw/` folders; no solve processes are left running.

## Required next work

Investigate the coupled value/default/long-bond pricing iteration before changing
calibration or interpreting the headline mechanisms. Suitable next diagnostics
are locating the cycling default states, checking the associated value gaps and
zero-profit residuals, and testing a nested price/Bellman iteration or debt-grid
refinement. Any method must retain the original equilibrium conditions and
demonstrate numerical accuracy. Do not smooth default behavior or alter
parameters simply to recover the desired claims.

## Follow-up nested solver test

The fixed-price borrower test and five outer price updates (600 sweeps per model)
also did not converge. Independent full-schedule pricing checks confirm final
maximum residuals 0.04223 (full) and 0.03852 (MP). See [nested/RESULTS.md](nested/RESULTS.md)
for boundary locations, switching examples, limits and next numerical checks.
