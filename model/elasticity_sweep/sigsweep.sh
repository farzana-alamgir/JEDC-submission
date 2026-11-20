#!/bin/bash
# Oil substitution elasticity sweep at the ADOPTED setup:
# common grid + the price process estimated on 1995Q1-2019Q4.
#
# alpha is NOT free. Under CES the oil share is s(p) = alpha^sigma * p^(1-sigma),
# so holding alpha fixed while changing sigma would silently move the share,
# which is a calibration target. Each sigma gets the alpha that holds
# alpha^sigma * E[p^(1-sigma)] at the value the ADOPTED calibration implies
# (0.100790), computed under the adopted benchmark's own simulated price
# distribution. By construction this reproduces alpha = 0.000307 at sigma = 0.30.
#
# beta and d1 are held at the adopted values, so spread and debt drift off
# target as sigma moves. Welfare comparisons are still read within a sigma;
# SPREAD CHANNELS ARE NOT READABLE FROM THIS SWEEP.
#
# THETA and ALPHA are FULL Fortran literals, e.g. -4.0d+0 and 4.709332d-6.
# Nothing is appended to them: an earlier version appended "d+0" and silently
# produced alpha=4.709332d-6d+0, which the guard then matched because it was
# built from the same string. The guards below check the literal's FORM, so a
# malformed one is rejected before anything is compiled.
#
# Usage: ./sigsweep.sh SIGMA THETA_LIT ALPHA_LIT ECON [ECON ...]
set -u
cd "$(dirname "$0")"

SIG=$1; THETA=$2; ALPHA=$3; shift 3
SRC=/Users/farzanaalamgir/code/JEDC_submission/model/src_spdebt
BETA=0.970654; D1=0.468505

for econ in "$@"; do
  d=sweep/sig${SIG}_${econ}
  rm -rf "$d"; mkdir -p "$d"
  cp "$SRC/oil_prod_CES_${econ}.f90" "$d/src.f90"

  # reject a malformed Fortran literal before touching anything
  for lit in "$ALPHA" "$THETA"; do
    case "$lit" in
      *d+[0-9]|*d-[0-9]|*d+[0-9][0-9]|*d-[0-9][0-9]) ;;
      *) echo "FATAL sig${SIG}/${econ}: not a Fortran literal -- $lit" >&2; exit 1 ;;
    esac
  done

  # the elasticity and its matching share weight
  perl -i -pe "s/alpha=0\.000307d\+0/alpha=${ALPHA}/"        "$d/src.f90"
  perl -i -pe "s/theta=-2\.33333333d\+0/theta=${THETA}/"     "$d/src.f90"

  ok=1
  for want in "alpha=${ALPHA}," "theta=${THETA}," \
              'rho_p = 0.9475d+0' 'mean_p_vol = -4.012d+0' 'rho_p_vol = 0.7382d+0' \
              'eta = 0.2889d+0' 'mean_p = 0.12d+0' \
              "beta=${BETA}d+0" "d1 = ${D1}d+0" 'd0 = -0.246d+0' \
              'parameter (va_default_cost = .true.)' \
              'parameter (kappa_risk = 0d+0)' \
              'parameter (use_common_p_grid = .true., mean_preserving'; do
    grep -qF "$want" "$d/src.f90" || { echo "FATAL sig${SIG}/${econ}: not set -- $want" >&2; ok=0; }
  done
  for gone in 'alpha=0.000307d+0' 'theta=-2.33333333d+0' 'p_grid = 0.316427d+0'; do
    grep -qF "$gone" "$d/src.f90" && { echo "FATAL sig${SIG}/${econ}: stale -- $gone" >&2; ok=0; }
  done
  [ "$ok" = 1 ] || exit 1

  # cheap syntax check before committing to a 30-minute solve
  gfortran -fsyntax-only "$d/src.f90" -J "$d" 2>"$d/syntax.log" \
    || { echo "FATAL sig${SIG}/${econ}: does not compile -- see $d/syntax.log" >&2; exit 1; }

  ( cd "$d" && gfortran -O3 -march=native -o solverP src.f90 2>build.log \
      && ./solverP > fort.6 2>&1 ) \
    && { grep -q 'interior oil optimum' "$d/fort.6" \
           && echo "WARN   sig${SIG} ${econ}: interior-optimum failure in fort.6" >&2; \
         echo "done   sig${SIG} ${econ} (alpha=${ALPHA} theta=${THETA})"; } \
    || { echo "FAILED sig${SIG}/${econ} -- see $d/build.log" >&2; exit 1; }
done
