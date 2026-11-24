# The non-oil price volatility controls for R1 Major 4.
#
#   cd model/economies_common_check/oil_dependence
#   Rscript build_control_volatilities.R
#
# Every control is built the same way as the paper's own oil volatility, so the
# coefficients can be compared: deflate the nominal index by the SAME CPI that
# deflates the real oil price, average to quarters (a quarter needs all three
# months), then fit svsample(log(real), designmatrix = "ar1") with seed 123 and
# keep 100x the posterior mean standard deviation. That is the procedure in
# oil_empirical_quarterly_claude.R lines 1-42 and in the author's food-price
# project, applied unchanged to other prices.
#
# OUTPUT  generic_vol.csv, one row per quarter, one column per control.
#         JEDC_dependence.m reads it by column name and silently skips any
#         column that is absent.
#
# SOURCES
#   fred/*.csv      downloaded from fred.stlouisfed.org; re-downloaded only if
#                   the file is missing, so the series are fixed for replication
#   external/       the author's own two files, copied in so the package does not
#                   depend on paths outside the repository
#   ../../../empirical/oil_qtrly.xlsx       the CPI deflator, and cpi_vol itself
#   ../../../empirical/global_monthly.xlsx  the T-bill, for tbill_vol

suppressMessages({library(stochvol); library(readxl); library(openxlsx); library(zoo)})

EMP <- normalizePath(file.path("..", "..", "..", "empirical"))

FRED <- c(WPUID61     = "PPI, processed goods for intermediate demand",
          WPUSOP2000  = "PPI, intermediate materials, supplies and components",
          PMETAINDEXM = "IMF global metals price index",
          PNFUELINDEXM= "IMF global non-fuel commodity index")
NAMES <- c(WPUID61 = "ippi_vol", WPUSOP2000 = "imat_vol",
           PMETAINDEXM = "met_vol", PNFUELINDEXM = "nfuel_vol")

dir.create("fred", showWarnings = FALSE)
for (id in names(FRED)) {
  f <- file.path("fred", paste0(id, ".csv"))
  if (!file.exists(f)) {
    cat(sprintf("downloading %s\n", id))
    utils::download.file(
      sprintf("https://fred.stlouisfed.org/graph/fredgraph.csv?id=%s", id),
      f, quiet = TRUE)
  }
}

oq  <- read_excel(file.path(EMP, "oil_qtrly.xlsx"))
oq$qd <- as.character(oq$qdate)
cpi <- oq[, c("qd", "CPI")]

# monthly series -> quarterly, deflated, SV-fitted
from_monthly <- function(dates, x, nm) {
  d <- data.frame(qd = as.character(as.yearqtr(as.Date(dates))), x = x)
  d <- d[!is.na(d$x) & !is.na(d$qd), ]
  cnt <- aggregate(x ~ qd, d, length); q <- aggregate(x ~ qd, d, mean)
  q <- q[q$qd %in% cnt$qd[cnt$x == 3], ]
  q <- merge(q, cpi, by = "qd"); q <- q[order(as.yearqtr(q$qd)), ]
  q$real <- 100 * q$x / q$CPI
  set.seed(123)
  sv  <- svsample(log(q$real), designmatrix = "ar1")
  out <- data.frame(qd = q$qd[-1], v = 100 * sv$summary$sd[, "mean"],
                    stringsAsFactors = FALSE)
  names(out)[2] <- nm
  cat(sprintf("  %-10s %3d quarters, %s to %s   min %.3f median %.3f max %.3f\n",
              nm, nrow(out), out$qd[1], out$qd[nrow(out)],
              min(out[[2]]), median(out[[2]]), max(out[[2]])))
  out
}

# already-quarterly series: no deflation, used for the CPI itself and the T-bill
from_quarterly <- function(qd, x, nm, deflate = FALSE) {
  q <- data.frame(qd = qd, x = x, stringsAsFactors = FALSE)
  q <- q[!is.na(q$x), ]
  if (deflate) { q <- merge(q, cpi, by = "qd"); q$x <- 100 * q$x / q$CPI }
  q <- q[order(as.yearqtr(q$qd)), ]
  set.seed(123)
  sv  <- svsample(log(q$x), designmatrix = "ar1")
  out <- data.frame(qd = q$qd[-1], v = 100 * sv$summary$sd[, "mean"],
                    stringsAsFactors = FALSE)
  names(out)[2] <- nm
  cat(sprintf("  %-10s %3d quarters, %s to %s   min %.3f median %.3f max %.3f\n",
              nm, nrow(out), out$qd[1], out$qd[nrow(out)],
              min(out[[2]]), median(out[[2]]), max(out[[2]])))
  out
}

cat("fitting the controls:\n")
G <- from_quarterly(oq$qd, oq$CPI, "cpi_vol")

gm <- read.xlsx(file.path(EMP, "global_monthly.xlsx"), sheet = "global",
                detectDates = TRUE)
gm$date <- as.Date(gm$date, origin = "1899-12-30")
gm$qd   <- as.character(as.yearqtr(gm$date))
tb <- aggregate(tbill ~ qd, gm, function(z) mean(z, na.rm = TRUE))
tb <- tb[order(as.yearqtr(tb$qd)), ]
G  <- merge(G, from_quarterly(tb$qd, tb$tbill, "tbill_vol"), by = "qd", all = TRUE)

# the author's own two indices, copied into external/
f <- suppressMessages(read_excel("external/FPI_data.xlsx", sheet = "FPI"))
f <- f[!is.na(f$real_fpi), ]
fq <- sprintf("%d Q%d", as.integer(f$year), (as.integer(f$month) - 1) %/% 3 + 1)
fd <- data.frame(qd = fq, x = f$real_fpi, stringsAsFactors = FALSE)
cnt <- aggregate(x ~ qd, fd, length); q <- aggregate(x ~ qd, fd, mean)
q <- q[q$qd %in% cnt$qd[cnt$x == 3], ]; q <- q[order(as.yearqtr(q$qd)), ]
# real_fpi is already CPI-deflated in the source, so it is not deflated again
G <- merge(G, from_quarterly(q$qd, q$x, "fpi_vol"), by = "qd", all = TRUE)

p <- suppressMessages(read_excel("external/PPI_monthly.xls", sheet = "Sheet2",
                                 col_names = FALSE,
                                 col_types = c("date", "numeric")))
G <- merge(G, from_monthly(p[[1]], p[[2]], "ppi_vol"), by = "qd", all = TRUE)

for (id in names(FRED)) {
  d <- read.csv(file.path("fred", paste0(id, ".csv")), stringsAsFactors = FALSE)
  G <- merge(G, from_monthly(d[[1]], suppressWarnings(as.numeric(d[[2]])),
                             NAMES[[id]]), by = "qd", all = TRUE)
}

G <- G[order(as.yearqtr(G$qd)), ]
write.csv(G, "generic_vol.csv", row.names = FALSE)
cat(sprintf("\ngeneric_vol.csv: %d rows, columns %s\n",
            nrow(G), paste(colnames(G), collapse = ", ")))
