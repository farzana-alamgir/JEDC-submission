#!/bin/bash
# Solve the point the Jacobian predicts hits the calibration targets, to test
# the extrapolation directly instead of trusting it.
#
# WHERE THE POINT COMES FROM
#   Baseline runs_common_v6/bm277 gives (spread, sd, debt/y) = (4.9336, 4.0252,
#   33.3888) at beta=0.972, d0=-0.246, d1=0.46. The runs_cal/ probe gives the
#   Jacobian (d0 by central difference from hi_d0 and lo_d0). Solving the 3x3
#   system against the targets (4.1, 2.0, 34.0) gives:
#
#     beta  0.972000 + -0.005233 = 0.966767     1.3x the probed range
#     d0   -0.246000 + +0.259453 = 0.013453     2.6x   "       "
#     d1    0.460000 + -0.317675 = 0.142325     7.9x   "       "
#
#   By construction the linearization says this point delivers the targets
#   exactly. The question is whether the model agrees.
#
# WHY IT PROBABLY WILL NOT
#   d1 moves 7.9x beyond the probed range, and the linearization is already
#   bending badly at baseline: the two one-sided d0 derivatives disagree by 28%
#   on spread and 43% on sd over a span of only 0.1. Also, across every run
#   solved at p=277 so far, sd never falls below 3.2844 against a target of
#   2.00. A result near sd 4 rather than 2 means the gradient step is an
#   artifact of extrapolation and the three parameters cannot reach the target.
#
# CAVEAT  d0 = +0.013453 is POSITIVE, inverting the sign of the default-cost
#   intercept. max(0, d0*yt + d1*yt**2) is then positive everywhere rather than
#   kinked, so this point may be economically meaningless even if it fits. This
#   run is a test of the gradient, not a proposed calibration.
#
# Everything else matches bm277: va_default_cost=.true., kappa_risk=0, common
# grid at p_num=277, alpha=0.000307, theta=-2.33333333.
#
# COST  1 run, ~40 min, ~1.7 GB. runs_pred/ is gitignored.
#
# READ THE RESULT
#   python3 analysis/moments_fast.py runs_common_v6/bm277 runs_pred/gradstep
#   Compare against the predicted (4.100, 2.000, 34.000).
set -u
cd "$(dirname "$0")"

OUT=runs_pred
B=0.966767
D0=0.013453
D1=0.142325

d=$OUT/gradstep
rm -rf "$d"; mkdir -p "$d"
cp oil_prod_CES.f90 "$d/src.f90"

perl -i -pe 's/alpha=0\.3d\+0/alpha=0.000307d+0/'                    "$d/src.f90"
perl -i -pe 's/theta=0\.5d\+0/theta=-2.33333333d+0/'                 "$d/src.f90"
perl -i -pe "s/beta=0\.96d\+0/beta=${B}d+0/"                         "$d/src.f90"
perl -i -pe "s/d0 = -0\.246d\+0/d0 = ${D0}d+0/"                      "$d/src.f90"
perl -i -pe "s/d1 = 0\.3847d\+0/d1 = ${D1}d+0/"                      "$d/src.f90"
perl -i -pe 's/parameter \(va_default_cost = \.false\.\)/parameter (va_default_cost = .true.)/' "$d/src.f90"
perl -i -pe 's/parameter \(use_common_p_grid = \.false\./parameter (use_common_p_grid = .true./' "$d/src.f90"
perl -i -pe 's/p_num=7, p_vol_num=5/p_num=277, p_vol_num=5/'         "$d/src.f90"

for want in 'alpha=0.000307d+0' 'theta=-2.33333333d+0' "beta=${B}d+0" \
            "d0 = ${D0}d+0" "d1 = ${D1}d+0" \
            'parameter (va_default_cost = .true.)' \
            'parameter (kappa_risk = 0d+0)' \
            'parameter (use_common_p_grid = .true.' \
            'p_num=277, p_vol_num=5'; do
  grep -qF "$want" "$d/src.f90" || { echo "FATAL: not set -- $want" >&2; exit 1; }
done

( cd "$d" && gfortran -O3 -march=native -o solverP src.f90 2>build.log && ./solverP > fort.6 2>&1 ) \
  && echo "done   gradstep (beta=$B d0=$D0 d1=$D1)" \
  || { echo "FAILED gradstep -- see $d/build.log" >&2; exit 1; }

echo
echo "next: python3 analysis/moments_fast.py runs_common_v6/bm277 $OUT/gradstep"
echo "      predicted (4.100, 2.000, 34.000)"
