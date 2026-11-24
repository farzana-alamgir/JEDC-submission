#!/bin/bash
# R2 Major 3: oil imports disrupted during default at the ADOPTED sigma_oil = 0.25.
#
#   ./disruptsweep.sh DISRUPTION
#
# Patches only oil_disruption in the economy of record and leaves every other
# literal alone, so the only difference from ../benchmark is the price of risk.
# While in default or excluded the country pays p*(1+oil_disruption) for oil:
# the Mendoza-Yue (2012) channel the referee points at. oil_disruption = 0
# reproduces ../benchmark. The prior attempt at sigma_oil = 0.30 is in
# results/OIL_DEPENDENT_DEFAULT_COST.md; this re-runs it at the adopted 0.25.
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
say "start  oil_disruption=$K  (free $(free_gb) GB)"

rm -rf "$D"; mkdir -p "$D"
cp "$SRC" "$D/src.f90"
perl -i -pe "s/parameter \(oil_disruption = 0d\+0\)/parameter (oil_disruption = ${K}d+0)/" "$D/src.f90"

# verify the patch landed and nothing else moved
ok=1
# va_default_cost is not a parameter in this source -- the value-added default
# cost is hard-wired and the name survives only in comments -- so the guard is
# the ten numeric literals that define the adopted calibration.
for want in "parameter (oil_disruption = ${K}d+0)" \
            'alpha=5.779464d-5' 'theta=-3.0d+0' 'beta=0.971528d+0' \
            'd0 = -0.246d+0' 'd1 = 0.468175d+0' 'mean_p = 0.12d+0' \
            'rho_p = 0.9475d+0' 'mean_p_vol = -4.012d+0' \
            'rho_p_vol = 0.7382d+0' 'eta = 0.2889d+0'; do
  grep -qF "$want" "$D/src.f90" || { say "FATAL: not set -- $want"; ok=0; }
done
[ "$ok" = 1 ] || { rm -rf "$D"; exit 1; }

( cd "$D" && gfortran -O3 -march=native -o solverP src.f90 2>build.log \
    && ./solverP > fort.6 2>&1 ) || { say "FAILED to solve"; exit 1; }

# p_eff should exceed p only while excluded; the solver prints the grids
grep -iE "interior oil optimum|p_eff" "$D/fort.6" | head -3 | tee -a "$LOG"

awk -v K="$K" -f extract_disrupt.awk "$D/graphs_data_sim_dss.txt" >> $OUT/disrupt.csv \
    || { say "FATAL: extraction failed"; exit 1; }
say "extracted: $(tail -1 $OUT/disrupt.csv)"

cp "$D/src.f90" "$OUT/src_k${K}.f90"
tail -40 "$D/fort.6" > "$OUT/fort6_tail_k${K}.txt"
rm -rf "$D"
say "DONE  (free $(free_gb) GB)"
