# R1 Major 3 — the elasticity sweep

Everything for this comment is here: the code that solved the six economies, the
record of those solves, and the tables the response letter quotes.

```
run_respsweep.sh         the driver: five solves, two at a time
respsweep.sh             one economy: patch, verify, compile, solve, extract, delete
extract_responses.awk    one pass over a simulation panel -> one table row
sweep_resp/              the run record (see below)
table1_elasticity_specs.csv   the oil share's price response, four ways   (letter, §2)
table2_response.csv           oil imports, oil bill, output, default, spreads (§3)
table3_by_country.csv         the 34 country-level elasticities            (§5)
table4_heterogeneity.csv      distribution, signal/noise, oil dependence   (§5)
table5_alpha_schedule.csv     the α pin at each elasticity                 (§1)
response_table.tex            the LaTeX body of table 2, to paste into the letter
```

## Rebuilding the tables

```
cd model/economies_common_check
matlab -batch "JEDC_elasticity"
```

`JEDC_elasticity.m` sits one level up, beside `JEDC_decomposition.m`, and every
path it defaults to is relative to that folder, so it writes into this one. Base
MATLAB, no toolboxes — the regressions are written out by hand in the file. It
takes about a minute, almost all of it reading the 250 MB simulation panel.

## Re-solving the six economies

```
./run_respsweep.sh
```

About 1 hour 20 minutes: three batches of roughly 33 minutes, two solves at a
time, then the last one alone. Five solves, not six — σ = 0.25 is the adopted
calibration and already exists as `../benchmark`, so it is extracted rather than
re-solved.

Each economy is `model/src_spdebt/oil_prod_CES_benchmark.f90` with four literals
patched: α, θ, β and d₁. Everything else is held fixed, and `respsweep.sh` greps
twelve literals back out of the patched source before it will compile —
including the ones that must *not* have moved (`rho_p`, `rho_p_vol`,
`mean_p_vol`, `eta`, `d0`, `va_default_cost`, `kappa_risk`, the common price
grid). A failed grep is fatal, so a mis-patch aborts rather than quietly
producing the wrong economy.

The (β, d₁) pairs are the points `../../elasticity_sweep/recalsweep.sh` landed,
recorded in `../../elasticity_sweep/results.txt`. They are hard-coded in
`run_respsweep.sh`, so nothing is re-searched here.

**Disk.** A run directory is 1.7 GB and the volume has a few GB free, so each is
deleted as soon as its moments are extracted. `respsweep.sh` refuses to start
under 3 GB free. Peak usage is about 3.4 GB with two solves running.

## sweep_resp — the run record

What survived each deleted run directory:

| | |
|---|---|
| `responses.csv` | the extracted moments, one row per elasticity |
| `src_sig0.20.f90` … | the full patched source actually compiled, per elasticity |
| `fort6_tail_sig*.txt` | the last 40 lines of each solver log |
| `sig0.20.log` … | the per-run script log |
| `runner.log` | the whole sweep, with timings |

So each economy is reproducible from its saved source without re-deriving the
patch:

```
cd sweep_resp && gfortran -O3 -march=native -o solverP src_sig0.50.f90 && ./solverP
```

## What is recomputed and what is not

**Recomputed every run:** all the empirical work, from
`empirical/spread_data.xlsx` and `empirical/oil_qtrly.xlsx`.

**Not recomputed:** the six Fortran solves. `sweep_resp/responses.csv` is their
record.

**The check that makes the rest trustworthy:** the adopted elasticity's run
folder still exists, because it is the economy of record (`../benchmark`). The
MATLAB rebuilds that row from the simulation panel and compares it with the
recorded one. It agrees to 7e-5, which is the recording precision of the CSV, so
the other five rows can be read with the same confidence. If that check ever
fails, the table should not be used until the failure is explained.

## Two things worth knowing about the numbers

**Rounding.** Three figures in table 2 sit on an exact decimal half (the 0.25
standard error at 0.0435, the 0.35 default rate at 3.3255, the 0.35 spread at
3.6645). MATLAB resolves these by the stored binary value, so they print as
0.043, 3.325 and 3.664. The rebuilt 0.25 row settles its own case — the standard
error is 0.043497 — so the printed value is right, and the letter was corrected
to match the generated table rather than the other way round.

**The oil-dependence thirds.** Reported two ways, because the group means move by
about 0.04 depending on whether the boundary country falls inside or outside each
third. The gap between the groups is 0.07 either way and the regression does not
move at all, so the finding does not depend on the cutoff; only the levels
quoted in the letter do, and the letter quotes the 0.333/0.667 pair.

## The sample: 35 importers, 34 used

Two things about the sample are worth stating plainly, because both change the
numbers.

**A name typo cost one country.** The `import_gdp` sheet spells El Salvador
`EL SAVADOR`, without the second L, while `exp_imp_data` spells it correctly.
Matching the two sheets on raw strings silently drops it, which is why an earlier
version of this analysis ran on 34 importers against the paper's 35. The repair
is a one-entry alias in the code, not an edit to the spreadsheet, which is left
as received.

**El Salvador is then excluded on purpose.** Its own elasticity is 2.924 with a
standard error of **2.185** and an R² of **0.039** — over 21 years the oil price
explains 4% of its oil share. The pooled within regression weights those 21
uninformative years as heavily as Poland's, whose standard error is 0.059, so
including it moves the baseline elasticity from 0.394 to 0.474 and the lower end
of the confidence interval from 0.232 to 0.252, which is enough to put the
adopted 0.25 outside it. It is excluded as an influential uninformative
observation.

Nothing is concealed by the exclusion:

- `table3_by_country.csv` lists all 35 countries with a `used` column, so El
  Salvador's estimate and its standard error stay in the record;
- the stdout prints the full-sample baseline beside the reported one, labelled
  `within country, all importers`;
- the exclusion is one named constant, `EXCLUDE`, at the top of
  `JEDC_elasticity.m`, with the reason beside it.

If the exclusion is ever reversed, every number in §2 and §5 of the letter moves
and the justification for 0.25 has to be rewritten, so change `EXCLUDE` only
together with the letter.

## Relation to the Python

Ported from `empirical/estimate_substitution_elasticity.py` and
`empirical/elasticity_heterogeneity.py`, which stay in the repository as the
cross-check. Both apply the same name repair and the same exclusion, and the
country-level estimates agree to 5e-6 across all 34 used countries and all five
reported columns. One deliberate difference: the Python printed a
one-standard-error band around the adopted elasticity (12 of 34), while the
letter claims a two-sided 95% test (19 of 34). The MATLAB computes the test the
letter describes.
