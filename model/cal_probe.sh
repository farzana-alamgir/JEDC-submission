#!/bin/bash
set -u; cd "$(dirname "$0")"
run () { local tag=$1 b=$2 d0=$3 d1=$4
  local d=runs_cal/$tag; rm -rf $d; mkdir -p $d; cp oil_prod_CES.f90 $d/src.f90
  perl -i -pe 's/alpha=0\.3d\+0/alpha=0.000307d+0/'    $d/src.f90
  perl -i -pe 's/theta=0\.5d\+0/theta=-2.33333333d+0/'  $d/src.f90
  perl -i -pe "s/beta=0\.96d\+0/beta=${b}d+0/"          $d/src.f90
  perl -i -pe "s/d0 = -0\.246d\+0/d0 = ${d0}d+0/"       $d/src.f90
  perl -i -pe "s/d1 = 0\.3847d\+0/d1 = ${d1}d+0/"       $d/src.f90
  perl -i -pe 's/parameter \(va_default_cost = \.false\.\)/parameter (va_default_cost = .true.)/' $d/src.f90
  perl -i -pe 's/use_common_p_grid = \.false\./use_common_p_grid = .true./' $d/src.f90
  perl -i -pe 's/p_num=7, p_vol_num=5/p_num=277, p_vol_num=5/' $d/src.f90
  ( cd $d && gfortran -O3 -march=native -o solverP src.f90 2>build.log && ./solverP > fort.6 2>&1 ); }
run hi_beta 0.976 -0.246 0.46 &
run hi_d1   0.972 -0.246 0.50 &
run hi_d0   0.972 -0.20  0.46 &
run lo_d0   0.972 -0.30  0.46 &
wait
