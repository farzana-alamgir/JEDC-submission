#!/bin/bash
# R1 Major 3, the part the letter could not report: how oil imports, the value
# of oil imports, output, the default probability and the spread respond across
# the elasticity range.
#
# The calibration at each sigma is NOT re-searched -- (beta, d1) are the points
# recalsweep.sh already landed, recorded in results.txt -- so this solves the
# benchmark once per sigma and measures it. The run directory is deleted as soon
# as its numbers are out, because the disk has about 7 GB free and a run is 1.7.
#
# Usage: ./respsweep.sh SIGMA THETA_LIT ALPHA_LIT BETA D1
set -u
cd "$(dirname "$0")"

SIG=$1; THETA=$2; ALPHA=$3; BETA=$4; D1=$5
SRC=/Users/farzanaalamgir/code/JEDC_submission/model/src_spdebt
OUT=sweep_resp; mkdir -p $OUT
LOG=$OUT/sig${SIG}.log
D=$OUT/sig${SIG}_benchmark

say() { echo "[$(date +%H:%M:%S) sig$SIG] $*" | tee -a "$LOG"; }

# disk guard: a run needs 1.7 GB and the volume is nearly full
free_gb() { df -g /Users/farzanaalamgir | awk 'NR==2{print $4}'; }
if [ "$(free_gb)" -lt 3 ]; then
  say "ABORT: only $(free_gb) GB free, need 3"
  exit 1
fi

: > "$LOG"
say "start  theta=$THETA alpha=$ALPHA beta=$BETA d1=$D1  (${_:-}free $(free_gb) GB)"

rm -rf "$D"; mkdir -p "$D"
cp "$SRC/oil_prod_CES_benchmark.f90" "$D/src.f90"
# the current source is the adopted sigma = 0.25 point
perl -i -pe "s/alpha=5\.779464d-5/alpha=${ALPHA}/"      "$D/src.f90"
perl -i -pe "s/theta=-3\.0d\+0/theta=${THETA}/"         "$D/src.f90"
perl -i -pe "s/beta=0\.971528d\+0/beta=${BETA}d+0/"     "$D/src.f90"
perl -i -pe "s/d1 = 0\.468175d\+0/d1 = ${D1}d+0/"       "$D/src.f90"

ok=1
for want in "alpha=${ALPHA}," "theta=${THETA}," "beta=${BETA}d+0" "d1 = ${D1}d+0" \
            'rho_p = 0.9475d+0' 'mean_p_vol = -4.012d+0' 'rho_p_vol = 0.7382d+0' \
            'eta = 0.2889d+0' 'd0 = -0.246d+0' \
            'parameter (va_default_cost = .true.)' 'parameter (kappa_risk = 0d+0)' \
            'parameter (use_common_p_grid = .true., mean_preserving'; do
  grep -qF "$want" "$D/src.f90" || { say "FATAL: not set -- $want"; ok=0; }
done
[ "$ok" = 1 ] || { rm -rf "$D"; exit 1; }

( cd "$D" && gfortran -O3 -march=native -o solverP src.f90 2>build.log \
    && ./solverP > fort.6 2>&1 ) || { say "FAILED to solve"; exit 1; }
grep -q 'interior oil optimum' "$D/fort.6" && say "WARN: interior-optimum failure"

awk -v SIG="$SIG" -f extract_responses.awk "$D/graphs_data_sim_dss.txt" \
    >> $OUT/responses.csv || { say "FATAL: extraction failed"; exit 1; }
say "extracted: $(tail -1 $OUT/responses.csv)"

cp "$D/src.f90" "$OUT/src_sig${SIG}.f90"
tail -40 "$D/fort.6" > "$OUT/fort6_tail_sig${SIG}.txt"
rm -rf "$D"
say "DONE  (free $(free_gb) GB)"
