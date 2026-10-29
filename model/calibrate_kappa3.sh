#!/bin/bash
# Joint (beta, d1) calibration at kappa_risk = 3 with the value-added default
# cost, sigma_oil = 0.30.
#
# Reads "beta d1" pairs from a FILE given as $3 (stdin only when run in the
# foreground -- nohup supplies its own stdin and would silently drop a
# redirect, see calibrate_sigma03.sh). Scores with analysis/moments_fast.py,
# appends a CSV row, then deletes the run's bulk output (~190MB each).
#
# Usage: ./calibrate_kappa3.sh out.csv [jobs] grid.txt
set -u
cd "$(dirname "$0")"
CSV="${1:-calib_kappa3.csv}"
JOBS="${2:-4}"
GRID="${3:-}"
ALPHA=0.00022269        # set so the oil share returns to ~9% at kappa = 3
THETA=-2.33333333
D0=-0.246
WORK=runs_calib_k3; mkdir -p $WORK
[ -f "$CSV" ] || echo "beta,d1,spread,sd,debt_y,oil_y,nobs,status" > "$CSV"

one () {
  local beta=$1 d1=$2
  local d=$WORK/b${beta}_d${d1}
  rm -rf $d; mkdir -p $d; cp oil_prod_CES.f90 $d/src.f90
  perl -i -pe "s/alpha=0\.3d\+0/alpha=${ALPHA}d+0/"   $d/src.f90
  perl -i -pe "s/theta=0\.5d\+0/theta=${THETA}d+0/"   $d/src.f90
  perl -i -pe "s/beta=0\.96d\+0/beta=${beta}d+0/"     $d/src.f90
  perl -i -pe "s/d0 = -0\.246d\+0/d0 = ${D0}d+0/"     $d/src.f90
  perl -i -pe "s/d1 = 0\.3847d\+0/d1 = ${d1}d+0/"     $d/src.f90
  perl -i -pe 's/parameter \(va_default_cost = \.false\.\)/parameter (va_default_cost = .true.)/' $d/src.f90
  perl -i -pe 's/parameter \(kappa_risk = 0d\+0\)/parameter (kappa_risk = 3.0d+0)/'               $d/src.f90
  ( cd $d && gfortran -O3 -march=native -o solver src.f90 2>build.log && ./solver > fort.6 2>&1 )
  local st=$? row
  if [ $st -ne 0 ] || [ ! -s $d/graphs_data_sim_dss.txt ]; then
    row="$beta,$d1,,,,,,solve_fail"
  else
    perl -i -pe 's/\*{3,}/NaN/g' $d/graphs_data_sim_dss.txt
    row=$(python3 - "$d" "$beta" "$d1" <<'PY'
import sys; sys.path.insert(0,'analysis')
from moments_fast import moments
d,b,c = sys.argv[1:4]
try:
    m = moments(d)
    print(f"{b},{c},{m['spread']:.4f},{m['sd']:.4f},{m['debt_y']:.4f},"
          f"{m['oil_y']:.4f},{m['nobs']},ok")
except Exception as ex:
    print(f"{b},{c},,,,,,score_fail:{type(ex).__name__}")
PY
    )
  fi
  echo "$row" >> "$CSV"; echo "  $row"
  rm -rf $d
}

running=0
while read -r beta d1; do
  [ -z "${beta:-}" ] && continue
  one "$beta" "$d1" &
  running=$((running+1))
  if [ $running -ge $JOBS ]; then wait -n 2>/dev/null || wait; running=$((running-1)); fi
done < <(if [ -n "$GRID" ]; then cat "$GRID"; else cat; fi)
wait
echo "=== done -> $CSV ==="
