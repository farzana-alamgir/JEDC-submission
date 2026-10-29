#!/bin/bash
# Joint (beta, d0, d1) calibration at sigma_oil = 0.30.
#
# Reads "beta d0 d1" triples on stdin, one per line. For each: build, solve,
# score with analysis/moments_fast.py (which reproduces sim_prod_oil_dec29.m
# exactly), append a CSV row, then DELETE the run's bulk output -- a full run
# is ~190MB and a grid of a few hundred would not fit on disk.
#
# Usage:  printf '0.96 -0.246 0.3847\n' | ./calibrate_sigma03.sh out.csv [jobs]
set -u
cd "$(dirname "$0")"
CSV="${1:-calib_sigma03.csv}"
JOBS="${2:-4}"
WORK=runs_calib; mkdir -p $WORK
[ -f "$CSV" ] || echo "beta,d0,d1,spread,sd,debt_y,oil_y,nobs,status" > "$CSV"

one () {
  local beta=$1 d0=$2 d1=$3
  local tag="b${beta}_d0${d0}_d1${d1}"
  local d=$WORK/$tag
  rm -rf $d; mkdir -p $d
  cp oil_prod_CES.f90 $d/src.f90
  perl -0pi -e 's/alpha=0\.3d\+0/alpha=0.000188992d+0/'       $d/src.f90
  perl -0pi -e 's/theta=0\.5d\+0/theta=-2.33333333d+0/'        $d/src.f90
  perl -0pi -e "s/beta=0\.96d\+0/beta=${beta}d+0/"             $d/src.f90
  perl -0pi -e "s/d0 = -0\.246d\+0/d0 = ${d0}d+0/"             $d/src.f90
  perl -0pi -e "s/d1 = 0\.3847d\+0/d1 = ${d1}d+0/"             $d/src.f90
  ( cd $d && gfortran -O3 -march=native -o solver src.f90 2>build.log \
       && ./solver > fort.6 2>&1 )
  local st=$?
  local row
  if [ $st -ne 0 ] || [ ! -s $d/graphs_data_sim_dss.txt ]; then
    row="$beta,$d0,$d1,,,,,,solve_fail"
  else
    perl -i -pe 's/\*{3,}/NaN/g' $d/graphs_data_sim_dss.txt
    row=$(python3 - "$d" "$beta" "$d0" "$d1" <<'PY'
import sys; sys.path.insert(0, 'analysis')
from moments_fast import moments
d, b, a, c = sys.argv[1:5]
try:
    m = moments(d)
    print(f"{b},{a},{c},{m['spread']:.4f},{m['sd']:.4f},"
          f"{m['debt_y']:.4f},{m['oil_y']:.4f},{m['nobs']},ok")
except Exception as ex:
    print(f"{b},{a},{c},,,,,,score_fail:{type(ex).__name__}")
PY
    )
  fi
  echo "$row" >> "$CSV"
  echo "  $row"
  rm -rf $d                      # reclaim ~190MB immediately
}

# Read triples from a FILE when given as $3, else stdin. A file is required
# when running under nohup/background, which supplies its own stdin and would
# silently drop a `< grid.txt` redirect -- the loop then reads nothing and the
# driver exits 0 having done no work.
GRID="${3:-}"
running=0
while read -r beta d0 d1; do
  [ -z "${beta:-}" ] && continue
  one "$beta" "$d0" "$d1" &
  running=$((running+1))
  if [ $running -ge $JOBS ]; then wait -n 2>/dev/null || wait; running=$((running-1)); fi
done < <(if [ -n "$GRID" ]; then cat "$GRID"; else cat; fi)
wait
echo "=== done -> $CSV ==="
