#!/bin/bash
# beta x d1 grid on the common_grid_final configuration, with d0 HELD at its
# submitted value -0.246.
#
# BASELINE  runs_common_v6/bm277/src.f90, which is byte-identical to
#   JEDC_common_grid_final/oil_prod_CES_benchmark.f90: beta=0.972, d0=-0.246,
#   d1=0.46, alpha=0.000307, theta=-2.33333333, va_default_cost=.true.,
#   kappa_risk=0, use_common_p_grid=.true., p_num=277. Moments (4.9336,
#   4.0252, 33.3888) against targets (4.10, 2.00, 34.0).
#
# WHY  gradstep reached sd 2.2907 but needed d0 = +0.013453, inverting the sign
#   of the default-cost intercept. The question here is whether beta and d1
#   alone can approach the targets with d0 left at -0.246.
#
#   Linearly they cannot -- with d0 fixed, any two targets are reachable and
#   the third diverges:
#     spread+sd exactly -> debt 137.8     (beta 0.9592, d1 0.8720)
#     sd+debt   exactly -> spread 0.94    (beta 0.9847, d1 0.5139)
#     spread+debt       -> sd 3.59        (beta 0.9746, d1 0.4731)
#   But gradstep's 7.9x extrapolation landed within 15% on sd, so the linear
#   predictions are not reliable enough to conclude from. Hence a grid.
#
# THE FOUR POINTS
#   inter   (0.9760, 0.5000)  completes a 2x2 factorial with bm277,
#                             runs_cal/hi_beta and runs_cal/hi_d1, giving the
#                             beta x d1 interaction the linear model omits.
#   ray50   (0.9785, 0.4870)  halfway along the ray that linearly hits sd+debt
#   ray100  (0.9847, 0.5139)  the full linear sd+debt point (predicts spread
#                             0.94 -- if the real spread holds up, that is the
#                             calibration; if it collapses, d0 is required)
#   spdebt  (0.9746, 0.4731)  the linear spread+debt point (predicts sd 3.59)
#
# COST  4 runs in parallel on 10 cores, ~40 min, ~1.7 GB each. runs_bd1/ is
#   gitignored.
#
# READ THE RESULT
#   python3 analysis/moments_fast.py runs_common_v6/bm277 runs_bd1/*
set -u
cd "$(dirname "$0")"

OUT=runs_bd1
D0=-0.246          # held fixed, the submitted value

run () {
  local tag=$1 b=$2 d1=$3
  local d=$OUT/$tag
  rm -rf "$d"; mkdir -p "$d"
  cp oil_prod_CES.f90 "$d/src.f90"

  perl -i -pe 's/alpha=0\.3d\+0/alpha=0.000307d+0/'                    "$d/src.f90"
  perl -i -pe 's/theta=0\.5d\+0/theta=-2.33333333d+0/'                 "$d/src.f90"
  perl -i -pe "s/beta=0\.96d\+0/beta=${b}d+0/"                         "$d/src.f90"
  perl -i -pe "s/d1 = 0\.3847d\+0/d1 = ${d1}d+0/"                      "$d/src.f90"
  perl -i -pe 's/parameter \(va_default_cost = \.false\.\)/parameter (va_default_cost = .true.)/' "$d/src.f90"
  perl -i -pe 's/parameter \(use_common_p_grid = \.false\./parameter (use_common_p_grid = .true./' "$d/src.f90"
  perl -i -pe 's/p_num=7, p_vol_num=5/p_num=277, p_vol_num=5/'         "$d/src.f90"
  # d0 is NOT substituted: the source default -0.246 is already the value we
  # want held fixed. The guard below asserts it.

  local want
  for want in 'alpha=0.000307d+0' 'theta=-2.33333333d+0' "beta=${b}d+0" \
              "d0 = ${D0}d+0" "d1 = ${d1}d+0" \
              'parameter (va_default_cost = .true.)' \
              'parameter (kappa_risk = 0d+0)' \
              'parameter (use_common_p_grid = .true.' \
              'p_num=277, p_vol_num=5'; do
    grep -qF "$want" "$d/src.f90" || { echo "FATAL $tag: not set -- $want" >&2; return 1; }
  done

  ( cd "$d" && gfortran -O3 -march=native -o solverP src.f90 2>build.log && ./solverP > fort.6 2>&1 ) \
    && echo "done   $tag (beta=$b d0=$D0 d1=$d1)" \
    || { echo "FAILED $tag -- see $d/build.log" >&2; return 1; }
}

run inter  0.9760 0.5000 &
run ray50  0.9785 0.4870 &
run ray100 0.9847 0.5139 &
run spdebt 0.9746 0.4731 &
wait

echo
echo "next: python3 analysis/moments_fast.py runs_common_v6/bm277 $OUT/*"
