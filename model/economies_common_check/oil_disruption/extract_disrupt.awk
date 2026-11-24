# One pass over a simulation panel -> one row for the R2 Major 3 table.
# Columns, 1-based, from the WRITE(23,...) in the Fortran:
#   3 b   4 q   7 standing (1 good)   8 default flag (2 = default)
#   9 q default-free   14 p   15 oil*p/gdp   16 gdp   18 volatility state index
BEGIN { COUPON = (0.01 + 0.03) / 1.01; DELTA = 0.03 }
{
    n++
    gdp += $16; shr += $15; b += $3
    bg  += $3 / (4 * $16)                 # debt over ANNUAL output
    if ($8 == 2) ev++
    if ($7 == 1) good++
    if ($4 > 0 && $9 > 0) {
        yl = COUPON / $4 - DELTA
        yr = COUPON / $9 - DELTA
        s  = (1+yl)^4 - (1+yr)^4
        sp += s; ns++
        # by volatility state, for the precautionary-borrowing margin
        iv = $18 + 0
        vsp[iv] += s; vbg[iv] += $3 / (4 * $16); vn[iv]++
    }
}
END {
    q  = (good > 0) ? ev / good : "nan"
    dr = (good > 0) ? 100 * (1 - (1-q)^4) : "nan"
    se = (good > 0) ? 100 * 4 * (1-q)^3 * sqrt(ev) / good : "nan"
    printf "%s,%d,%.4f,%.4f,%.4f,%.4f,%.4f,%d,%d", \
           K, n, 100*sp/ns, 100*bg/n, 100*shr/n, dr, se, ev, good
    # the lowest and highest volatility states that actually occur
    lo = 99; hi = -1
    for (i in vn) { if (i+0 < lo) lo = i+0; if (i+0 > hi) hi = i+0 }
    printf ",%.4f,%.4f,%.4f,%.4f\n", \
           100*vsp[lo]/vn[lo], 100*vbg[lo]/vn[lo], \
           100*vsp[hi]/vn[hi], 100*vbg[hi]/vn[hi]
}
