# One pass over graphs_data_sim_dss.txt. Columns, from the WRITE(23,...) in
# oil_prod_CES_benchmark.f90:
#   4  q          9  q_default_free      14 p (price level)
#   6  oil        7  excl (1 = good)     15 oil*p/gdp
#   8  d (2 = default quarter)           16 gdp
#
# Everything here is a WHOLE-SIMULATION mean, including the spread, so the
# columns are all on one convention. The episode-window spread that the
# calibration table reports is a different statistic and is carried separately.
BEGIN { COUPON = (0.01 + 0.03) / 1.01; DELTA = 0.03 }
{
    n++
    m    += $6                     # oil import quantity
    val  += $6 * $14               # value of oil imports, output units
    shr  += $15                    # value of oil imports / GDP
    gdp  += $16
    p    += $14
    if ($8 == 2) ev++
    if ($7 == 1) good++
    if ($4 > 0 && $9 > 0) {
        yl = COUPON / $4  - DELTA
        yr = COUPON / $9  - DELTA
        sp += (1+yl)^4 - (1+yr)^4
        ns++
    }
}
END {
    q  = (good > 0) ? ev / good : "nan"
    dr = (good > 0) ? 100 * (1 - (1-q)^4) : "nan"
    se = (good > 0) ? 100 * 4 * (1-q)^3 * sqrt(ev) / good : "nan"
    msp = (ns > 0) ? 100 * sp / ns : "nan"
    printf "%s,%d,%.6f,%.6f,%.6f,%.6f,%.6f,%.4f,%.4f,%.4f,%d,%d\n", \
           SIG, n, m/n, val/n, 100*shr/n, gdp/n, p/n, msp, dr, se, ev, good
}
