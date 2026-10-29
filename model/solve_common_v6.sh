#!/bin/bash
set -u; cd "$(dirname "$0")"
OUT=runs_common_v6
build () {
  local d=$OUT/$1; shift; rm -rf $d; mkdir -p $d; cp oil_prod_CES.f90 $d/src.f90
  perl -i -pe 's/alpha=0\.3d\+0/alpha=0.000307d+0/'    $d/src.f90
  perl -i -pe 's/theta=0\.5d\+0/theta=-2.33333333d+0/'  $d/src.f90
  perl -i -pe 's/beta=0\.96d\+0/beta=0.972d+0/'         $d/src.f90
  perl -i -pe 's/d1 = 0\.3847d\+0/d1 = 0.46d+0/'        $d/src.f90
  perl -i -pe 's/parameter \(va_default_cost = \.false\.\)/parameter (va_default_cost = .true.)/' $d/src.f90
  perl -i -pe 's/use_common_p_grid = \.false\./use_common_p_grid = .true./' $d/src.f90
  perl -i -pe 's/p_num=7, p_vol_num=5/p_num=277, p_vol_num=5/' $d/src.f90
  for e in "$@"; do perl -0pi -e "$e" $d/src.f90; done
  ( cd $d && gfortran -O3 -march=native -o solverC src.f90 2>build.log && ./solverC > fort.6 2>&1; echo $? > exit.code )
}
build mp_c         's/mean_preserving = \.false\./mean_preserving = .true./' &
build basic_c      's/constant_vol = \.false\./constant_vol = .true./' \
                   's/p_num=277, p_vol_num=5/p_num=1, p_vol_num=1/' \
                   's/p_grid = mean_p \+ 0\.5d\+0\*mean_innov_var\/\(1d\+0 - rho_p\*\*\(2d\+0\)\)/p_grid = 0.288107d+0/' &
wait
for d in mp_c basic_c; do
  n=$(grep -c '\*\*\*' $OUT/$d/graphs_data_sim_dss.txt 2>/dev/null || echo 0)
  [ "${n:-0}" -gt 0 ] 2>/dev/null && perl -i -pe 's/\*{3,}/NaN/g' $OUT/$d/graphs_data_sim_dss.txt
  echo "$d exit=$(cat $OUT/$d/exit.code) overflow=${n:-0}"
done
