#!/bin/bash
# The SUBMITTED model (va_default_cost = .false.) on the converged common grid.
#
# WHY THIS EXISTS
#   At p_num=277 the model produces sd(spread) ~= 4.0 against a data target of
#   2.00, and no parameter closes it: across beta, d0, d1 and kappa_risk the
#   lowest sd anywhere is 3.2844 (runs_cal/hi_d0). The submitted model gave
#   sd = 2.2465 -- but only at p_num=7, which understates sd by ~38%:
#
#     runs_va_final/bm      p=7     spread 4.4061  sd 2.9141
#     runs_common_v6/bm277  p=277   spread 4.9336  sd 4.0252
#     runs_common_v6/bm     p=549   spread 4.9229  sd 4.0063   (277 is converged)
#
#   So: was the submitted calibration validated on an under-resolved solve? If
#   sub/ comes back near sd 4 rather than 2.2, the data target was never
#   attainable at converged resolution and the target needs revisiting, not the
#   parameters. If it comes back near 2.2, the value-added default cost is what
#   raised sd, and that is a specification choice to defend or drop.
#
# THE TWO RUNS
#   sub   the submitted calibration exactly: beta=0.964, alpha=0.000188992,
#         d1=0.37 (as in runs_final/bm), va OFF. Re-solved at 277.
#   base  the CURRENT baseline parameters with va OFF: beta=0.972,
#         alpha=0.000307, d1=0.46. Differs from runs_common_v6/bm277 in
#         va_default_cost ALONE, so it isolates that switch.
#
#   Both use the common price grid at p_num=277. d0 = -0.246 in both, which is
#   the source default and common to the submitted and current calibrations.
#
# COST  2 runs in parallel, ~40 min, ~1.7 GB each. runs_vaoff/ is gitignored.
#
# READ THE RESULT
#   python3 analysis/moments_fast.py runs_final/bm runs_common_v6/bm277 runs_vaoff/*
set -u
cd "$(dirname "$0")"

OUT=runs_vaoff

run () {
  local tag=$1 b=$2 a=$3 d1=$4
  local d=$OUT/$tag
  rm -rf "$d"; mkdir -p "$d"
  cp oil_prod_CES.f90 "$d/src.f90"

  perl -i -pe "s/alpha=0\.3d\+0/alpha=${a}d+0/"                        "$d/src.f90"
  perl -i -pe 's/theta=0\.5d\+0/theta=-2.33333333d+0/'                 "$d/src.f90"
  perl -i -pe "s/beta=0\.96d\+0/beta=${b}d+0/"                         "$d/src.f90"
  perl -i -pe "s/d1 = 0\.3847d\+0/d1 = ${d1}d+0/"                      "$d/src.f90"
  perl -i -pe 's/parameter \(use_common_p_grid = \.false\./parameter (use_common_p_grid = .true./' "$d/src.f90"
  perl -i -pe 's/p_num=7, p_vol_num=5/p_num=277, p_vol_num=5/'         "$d/src.f90"
  # va_default_cost is LEFT at the source default .false. -- that is the point
  # of this probe, and the source says .false. reproduces the submitted model
  # exactly. kappa_risk likewise stays at its default 0.

  local want
  for want in "alpha=${a}d+0" 'theta=-2.33333333d+0' "beta=${b}d+0" \
              'd0 = -0.246d+0' "d1 = ${d1}d+0" \
              'parameter (va_default_cost = .false.)' \
              'parameter (kappa_risk = 0d+0)' \
              'parameter (use_common_p_grid = .true.' \
              'p_num=277, p_vol_num=5'; do
    grep -qF "$want" "$d/src.f90" || { echo "FATAL $tag: not set -- $want" >&2; return 1; }
  done

  ( cd "$d" && gfortran -O3 -march=native -o solverP src.f90 2>build.log && ./solverP > fort.6 2>&1 ) \
    && echo "done   $tag (beta=$b alpha=$a d1=$d1, va OFF)" \
    || { echo "FAILED $tag -- see $d/build.log" >&2; return 1; }
}

run sub  0.964 0.000188992 0.37 &
run base 0.972 0.000307    0.46 &
wait

echo
echo "next: python3 analysis/moments_fast.py runs_final/bm runs_common_v6/bm277 $OUT/*"
