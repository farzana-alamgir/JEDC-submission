#!/bin/bash
# R1 Major 5: lender-side risk pricing at the ADOPTED sigma_oil = 0.25.
#
#   ./kappasweep.sh KAPPA
#
# Patches only kappa_risk in the economy of record and leaves every other
# literal alone, so the only difference from ../benchmark is the price of risk.
# The kernel is normalised numerically on the grid (Z), so E[m'] = exp(-rstar)
# holds exactly at any kappa -- see results/RISK_PREMIUM_AND_FIGURE3.md for the
# bug this replaced. kappa_risk = 0 reproduces ../benchmark.
#
# The run directory is deleted as soon as its moments are out.
set -u
cd "$(dirname "$0")"

K=$1
SRC=../benchmark/oil_prod_CES_benchmark.f90
OUT=sweep; mkdir -p $OUT
LOG=$OUT/k${K}.log
D=$OUT/k${K}_run

say() { echo "[$(date +%H:%M:%S) k$K] $*" | tee -a "$LOG"; }

free_gb() { df -g /Users/farzanaalamgir | awk 'NR==2{print $4}'; }
if [ "$(free_gb)" -lt 3 ]; then say "ABORT: only $(free_gb) GB free"; exit 1; fi

: > "$LOG"
say "start  kappa_risk=$K  (free $(free_gb) GB)"

rm -rf "$D"; mkdir -p "$D"
cp "$SRC" "$D/src.f90"
perl -i -pe "s/parameter \(kappa_risk = 0d\+0\)/parameter (kappa_risk = ${K}d+0)/" "$D/src.f90"

# verify the patch landed and nothing else moved
ok=1
# va_default_cost is not a parameter in this source -- the value-added default
# cost is hard-wired and the name survives only in comments -- so the guard is
# the ten numeric literals that define the adopted calibration.
for want in "parameter (kappa_risk = ${K}d+0)" \
            'alpha=5.779464d-5' 'theta=-3.0d+0' 'beta=0.971528d+0' \
            'd0 = -0.246d+0' 'd1 = 0.468175d+0' 'mean_p = 0.12d+0' \
            'rho_p = 0.9475d+0' 'mean_p_vol = -4.012d+0' \
            'rho_p_vol = 0.7382d+0' 'eta = 0.2889d+0'; do
  grep -qF "$want" "$D/src.f90" || { say "FATAL: not set -- $want"; ok=0; }
done
[ "$ok" = 1 ] || { rm -rf "$D"; exit 1; }

( cd "$D" && gfortran -O3 -march=native -o solverP src.f90 2>build.log \
    && ./solverP > fort.6 2>&1 ) || { say "FAILED to solve"; exit 1; }

# the kernel normalisation is printed at startup; keep it, it is the check
grep -iE "Z *(range|min|max)|E\[m\]" "$D/fort.6" | head -3 | tee -a "$LOG"

awk -v K="$K" -f extract_kappa.awk "$D/graphs_data_sim_dss.txt" >> $OUT/kappa.csv \
    || { say "FATAL: extraction failed"; exit 1; }
say "extracted: $(tail -1 $OUT/kappa.csv)"

cp "$D/src.f90" "$OUT/src_k${K}.f90"
tail -40 "$D/fort.6" > "$OUT/fort6_tail_k${K}.txt"
rm -rf "$D"
say "DONE  (free $(free_gb) GB)"
