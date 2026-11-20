#!/bin/bash
# Recalibrated elasticity sweep: beta and d1 re-matched to spread 4.10 /
# debt 34.0 at EACH sigma, then all four economies solved there, so the
# channels and the welfare curve are comparable across elasticities.
#
# Disk is the binding constraint (a benchmark run is 1.7 GB and there are four
# economies per sigma), so each run is pruned to a whitelist the moment its
# numbers are extracted. Peak is about 2.6 GB per sigma.
#
# Usage: ./recalsweep.sh SIGMA THETA_LIT ALPHA_LIT BETA0 D1_0
set -u
cd "$(dirname "$0")"

SIG=$1; THETA=$2; ALPHA=$3; BETA=$4; D1=$5
SRC=/Users/farzanaalamgir/code/JEDC_submission/model/src_spdebt
AN=/Users/farzanaalamgir/code/JEDC_submission/model/analysis
OUT=sweep_recal; mkdir -p $OUT
LOG=$OUT/sig${SIG}.log
: > "$LOG"

say() { echo "[sig$SIG] $*" | tee -a "$LOG" >&2; }   # stderr: solve() returns its dir on stdout

# files any later step needs; everything else in a run dir is removable
KEEP="graphs_data_sim_dss.txt graphs_param_dss.txt graphs_v_dss.txt \
graphs_output_dss.txt graphs_pdf_p.txt graphs_pdf_p_vol.txt \
graphs_b_grid_dss.txt graphs_p_grid_dss.txt graphs_p_vol_grid_dss.txt \
fort.6 src.f90"

prune() {   # prune DIR [extra files to drop]
  local d=$1; shift
  local f keep
  for f in "$d"/*; do
    keep=0
    for k in $KEEP; do [ "$(basename "$f")" = "$k" ] && keep=1; done
    for x in "$@";  do [ "$(basename "$f")" = "$x" ] && keep=0; done
    [ $keep = 0 ] && rm -rf "$f"
  done
}

solve() {   # solve ECON BETA D1 -> run dir on stdout, or exit 1
  local econ=$1 b=$2 dd=$3
  local d=$OUT/sig${SIG}_${econ}
  rm -rf "$d"; mkdir -p "$d"
  cp "$SRC/oil_prod_CES_${econ}.f90" "$d/src.f90"
  perl -i -pe "s/alpha=0\.000307d\+0/alpha=${ALPHA}/"      "$d/src.f90"
  perl -i -pe "s/theta=-2\.33333333d\+0/theta=${THETA}/"   "$d/src.f90"
  perl -i -pe "s/beta=0\.970654d\+0/beta=${b}d+0/"         "$d/src.f90"
  perl -i -pe "s/d1 = 0\.468505d\+0/d1 = ${dd}d+0/"        "$d/src.f90"
  local ok=1
  for want in "alpha=${ALPHA}," "theta=${THETA}," "beta=${b}d+0" "d1 = ${dd}d+0" \
              'rho_p = 0.9475d+0' 'mean_p_vol = -4.012d+0' 'rho_p_vol = 0.7382d+0' \
              'eta = 0.2889d+0' 'd0 = -0.246d+0' \
              'parameter (va_default_cost = .true.)' 'parameter (kappa_risk = 0d+0)' \
              'parameter (use_common_p_grid = .true., mean_preserving'; do
    grep -qF "$want" "$d/src.f90" || { say "FATAL $econ: not set -- $want"; ok=0; }
  done
  [ "$ok" = 1 ] || exit 1
  gfortran -fsyntax-only "$d/src.f90" -J "$d" 2>"$d/syntax.log" \
    || { say "FATAL $econ: will not compile"; exit 1; }
  ( cd "$d" && gfortran -O3 -march=native -o solverP src.f90 2>build.log \
      && ./solverP > fort.6 2>&1 ) || { say "FAILED $econ"; exit 1; }
  grep -q 'interior oil optimum' "$d/fort.6" && say "WARN $econ: interior-optimum failure"
  echo "$d"
}

mom() { python3 -I "$AN/moments_fast.py" "$1" 2>/dev/null | awk '{print $3, $5, $7}'; }

# ---- phase 1: land the calibration -------------------------------------
say "start  alpha=$ALPHA theta=$THETA  newton point beta=$BETA d1=$D1"
for attempt in 1 2 3; do
  BM=$(solve benchmark "$BETA" "$D1") || exit 1
  read SP SD DEBT < <(mom "$BM")
  say "attempt $attempt: beta=$BETA d1=$D1 -> spread $SP  sd $SD  debt $DEBT"
  okspread=$(awk -v s="$SP"   'BEGIN{print (s-4.10<0.10 && 4.10-s<0.10)?1:0}')
  okdebt=$(  awk -v q="$DEBT" 'BEGIN{print (q-34.0<0.60 && 34.0-q<0.60)?1:0}')
  [ "$okspread" = 1 ] && [ "$okdebt" = 1 ] && { say "ON TARGET"; break; }
  [ "$attempt" = 3 ] && { say "GAVE UP after 3 attempts -- reporting off-target"; break; }
  read BETA D1 < <(python3 -I newton.py "$BETA" "$D1" "$SP" "$DEBT")
  say "re-stepping to beta=$BETA d1=$D1"
done
echo "CAL sigma=$SIG beta=$BETA d1=$D1 spread=$SP sd=$SD debt=$DEBT" >> "$OUT/results.txt"
prune "$BM"

# ---- phase 2: basic, then welfare --------------------------------------
BA=$(solve basic "$BETA" "$D1") || exit 1
read SP2 SD2 DEBT2 < <(mom "$BA")
say "basic: spread $SP2 sd $SD2 debt $DEBT2"
echo "ECON sigma=$SIG basic spread=$SP2 sd=$SD2 debt=$DEBT2" >> "$OUT/results.txt"
prune "$BA"
CEV=$(python3 -I "$AN/welfare_raw.py" "$BM" 277 5 "$BA" 2>&1 | grep -o 'CEV *[-+][0-9.]*%' | head -1)
say "welfare benchmark->basic: $CEV"
echo "CEV sigma=$SIG $CEV" >> "$OUT/results.txt"
# value functions no longer needed
prune "$BM" graphs_v_dss.txt graphs_output_dss.txt
prune "$BA" graphs_v_dss.txt graphs_output_dss.txt

# ---- phase 3: the other two economies ----------------------------------
for econ in intermediate mean_preserving; do
  D=$(solve "$econ" "$BETA" "$D1") || exit 1
  read S3 SD3 Q3 < <(mom "$D")
  say "$econ: spread $S3 sd $SD3 debt $Q3"
  echo "ECON sigma=$SIG $econ spread=$S3 sd=$SD3 debt=$Q3" >> "$OUT/results.txt"
  prune "$D" graphs_v_dss.txt graphs_output_dss.txt graphs_data_sim_dss.txt
done
say "DONE"
