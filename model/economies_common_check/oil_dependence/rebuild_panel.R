# Regenerate the paper's own regression panel, for R1 Major 1c and R1 Major 4.
#
#   cd model/economies_common_check/oil_dependence && Rscript rebuild_panel.R
#
# WHAT IT DOES
#   Runs the DATA half of the author's own empirical/oil_empirical_quarterly_
#   claude.R -- lines 1 to 590, stopping before the first regression -- and
#   writes the finished panel here as panel_full.csv. Along the way that script
#   fits the stochastic-volatility model to the log real oil price and writes
#   volatilities.csv, which is the volatility measure Table 1 uses.
#
#   The author's code reads its inputs by bare filename, so the evaluation runs
#   with empirical/ as the working directory. Everything it leaves behind is then
#   moved in here, into workings/, so empirical/ is left as it was found and this
#   folder holds the whole chain.
#
# WHAT IT VERIFIES
#   The four Table 1 specifications are re-estimated and their oil price
#   coefficients checked against 0.188, 0.184, 0.142 and 0.142 -- the 0.14 to
#   0.19 range Referee 2 quotes from Table 1. If that fails, the rebuild has
#   drifted from the paper and nothing downstream should be used.
#
# REQUIRES  stochvol, readxl, openxlsx, zoo, dplyr, tidyverse

HERE <- normalizePath(".")
EMP  <- normalizePath(file.path("..", "..", "..", "empirical"))
WORK <- file.path(HERE, "workings")
dir.create(WORK, showWarnings = FALSE)

SRC    <- file.path(EMP, "oil_empirical_quarterly_claude.R")
CUTOFF <- 590        # the last line before the first lm() call

stopifnot(file.exists(SRC))
src <- readLines(SRC, warn = FALSE)
stopifnot(length(src) > CUTOFF)
if (!grepl("^reg1", src[CUTOFF + 1])) {
  stop(sprintf(paste("line %d of the author's script is no longer the first",
                     "regression -- it is:\n  %s\nFind the new boundary and",
                     "update CUTOFF."), CUTOFF + 1, src[CUTOFF + 1]))
}

suppressMessages({library(openxlsx); library(zoo); library(dplyr); library(readxl)})
owd <- setwd(EMP)
before <- list.files(EMP)
eval(parse(text = paste(src[1:CUTOFF], collapse = "\n")), envir = globalenv())
after <- list.files(EMP)
setwd(owd)

# op_diff, as the author's script builds it, is the price change of the PREVIOUS
# quarter: lag_price = lag(log_real_price, 1) and then op_diff = diff(lag_price),
# so op_diff(t) = log p(t-1) - log p(t-2). The contemporaneous change is added
# here as op_diff_now, because R2 Major 6's magnitude comparison turns on which
# of the two is used and the paper's text should say which it means.
oq <- read_excel(file.path(EMP, "oil_qtrly.xlsx"))
oq$qd  <- as.character(oq$qdate)
oq$lrp <- log(oq$real_price)
oq <- oq[order(as.yearqtr(oq$qd)), ]
oq$op_diff_now <- c(NA, diff(oq$lrp))
all_data_qtrly$op_diff_now <-
  oq$op_diff_now[match(as.character(all_data_qtrly$qdate), oq$qd)]

chk <- with(all_data_qtrly, max(abs(op_diff - c(NA, head(op_diff_now, -1))),
                                na.rm = TRUE))
cat(sprintf("\nop_diff is the lagged change (max |op_diff - lag(op_diff_now)| = %.1e)\n",
            chk))

keep <- c("country","qdate","spread","log_spread","log_spread_diff","vol",
          "op_diff","op_diff_now","dy_diff","tbill_diff","res_diff",
          "rer_avg_diff","VIX","vol_dummy")
have <- keep[keep %in% names(all_data_qtrly)]
if (length(setdiff(keep, have))) {
  warning("absent from the panel, not exported: ",
          paste(setdiff(keep, have), collapse = ", "))
}
write.csv(all_data_qtrly[, have], file.path(HERE, "panel_full.csv"),
          row.names = FALSE)
cat(sprintf("\npanel_full.csv: %d rows, %d countries, %d quarters\n",
            nrow(all_data_qtrly), length(unique(all_data_qtrly$country)),
            length(unique(all_data_qtrly$qdate))))

# volatilities.csv is the one byproduct that belongs beside the panel rather
# than in workings/, because JEDC_dependence.m's documentation refers to it
new <- setdiff(after, before)
if ("volatilities.csv" %in% new) {
  file.rename(file.path(EMP, "volatilities.csv"), file.path(HERE, "volatilities.csv"))
  new <- setdiff(new, "volatilities.csv")
}
for (f in new) file.rename(file.path(EMP, f), file.path(WORK, f))
if (length(new)) {
  cat(sprintf("moved into workings/: %s\n", paste(new, collapse = ", ")))
}

cat("\nCHECK  the Table 1 oil price coefficients\n")
f <- list(
  "no controls, no FE" = log_spread_diff ~ vol + op_diff,
  "no controls, FE"    = log_spread_diff ~ vol + op_diff + factor(country),
  "controls, no FE"    = log_spread_diff ~ vol + op_diff + dy_diff +
                         tbill_diff + res_diff + rer_avg_diff + VIX,
  "controls and FE"    = log_spread_diff ~ vol + op_diff + dy_diff +
                         tbill_diff + res_diff + rer_avg_diff + VIX +
                         factor(country))
want <- c(0.188, 0.184, 0.142, 0.142)
cat(sprintf("  %-20s %9s %9s %7s %6s\n", "specification", "op_diff",
            "expected", "vol", "n"))
ok <- TRUE
for (i in seq_along(f)) {
  m <- lm(f[[i]], data = all_data_qtrly)
  s <- summary(m)$coefficients
  b <- s["op_diff", "Estimate"]
  if (abs(b - want[i]) > 0.002) ok <- FALSE
  cat(sprintf("  %-20s %+9.4f %9.3f %+7.4f %6d\n", names(f)[i], b, want[i],
              s["vol", "Estimate"], length(m$residuals)))
}
cat(if (ok) "  matches the published range\n" else
            "  DOES NOT MATCH -- do not use the panel until this is explained\n")
