#!/bin/bash
# Re-solve the three FIGURE2 economies at sigma = 0.25, UNPRUNED, so the
# figure can actually be drawn. recalsweep.sh deletes graphs_output_dss.txt
# (the debt/GDP axis) and graphs_data_sim_dss.txt the moment it has the
# moments, so nothing in sweep_recal/sig0.25_* can draw a figure.
#
# Calibration is the one the sweep landed on at sigma = 0.25:
#   theta = -3.0        sigma_oil = 1/(1-theta) = 0.25
#   alpha = 5.779464d-5
#   beta  = 0.971528    d1 = 0.468175   (spread 4.0793, debt 34.2992)
set -u
cd "$(dirname "$0")"

SRC=/Users/farzanaalamgir/code/JEDC_submission/model/src_spdebt
OUT=fig2_sig025
THETA=-3.0d+0
ALPHA=5.779464d-5
BETA=0.971528
D1=0.468175

mkdir -p "$OUT"
cp "$SRC/ALL_FIGURES_common_grid.m" "$OUT/" || exit 1

for econ in benchmark intermediate basic; do
  d=$OUT/run_${econ}
  rm -rf "$d"; mkdir -p "$d"
  cp "$SRC/oil_prod_CES_${econ}.f90" "$d/src.f90"
  perl -i -pe "s/alpha=0\.000307d\+0/alpha=${ALPHA}/"    "$d/src.f90"
  perl -i -pe "s/theta=-2\.33333333d\+0/theta=${THETA}/" "$d/src.f90"
  perl -i -pe "s/beta=0\.970654d\+0/beta=${BETA}d+0/"    "$d/src.f90"
  perl -i -pe "s/d1 = 0\.468505d\+0/d1 = ${D1}d+0/"      "$d/src.f90"

  ok=1
  for want in "alpha=${ALPHA}," "theta=${THETA}," "beta=${BETA}d+0" "d1 = ${D1}d+0" \
              'rho_p = 0.9475d+0' 'mean_p_vol = -4.012d+0' 'rho_p_vol = 0.7382d+0' \
              'eta = 0.2889d+0' 'd0 = -0.246d+0' \
              'parameter (va_default_cost = .true.)' 'parameter (kappa_risk = 0d+0)' \
              'parameter (use_common_p_grid = .true., mean_preserving'; do
    grep -qF "$want" "$d/src.f90" || { echo "FATAL $econ: not set -- $want" >&2; ok=0; }
  done
  [ "$ok" = 1 ] || exit 1

  gfortran -fsyntax-only "$d/src.f90" -J "$d" 2>"$d/syntax.log" \
    || { echo "FATAL $econ: will not compile -- see $d/syntax.log" >&2; exit 1; }
done

echo "all three patched and compile-clean; solving"
for econ in benchmark intermediate basic; do
  d=$OUT/run_${econ}
  ( cd "$d" && gfortran -O3 -march=native -o solverP src.f90 2>build.log \
      && ./solverP > fort.6 2>&1 \
      && echo "done $econ" || echo "FAILED $econ" ) &
done
wait
echo "=== solves finished ==="
for econ in benchmark intermediate basic; do
  printf "%-14s " "$econ"
  python3 -I /Users/farzanaalamgir/code/JEDC_submission/model/analysis/moments_fast.py \
    "$OUT/run_${econ}" 2>&1 | tail -1
done
