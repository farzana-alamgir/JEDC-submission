## Estimating the volatilities

set.seed(123)
library(stochvol)
library(readxl)

oil_qtrly <- read_excel("oil_qtrly.xlsx")

oil_qtrly$log_real_op <- log(oil_qtrly$real_price)



sv_model_oil <- svsample(oil_qtrly$log_real_op,designmatrix = "ar1") 
summary(sv_model_oil, showlatent = FALSE)
predvol <- predict(sv_model_oil, forecast = NULL, dates = oil_qtrly$date[-1])



predvol_oil <- predvol$vol;
predvol_oil_matrix <- matrix(unlist(predvol_oil), ncol = 100, byrow = TRUE)


num_draws_predvol_oil <- dim(predvol_oil_matrix)[1]
num_quarters_predvol_oil <- dim(predvol_oil_matrix)[2]

export_predvol_oil <- matrix(ncol = 4, nrow = num_quarters_predvol_oil)

for (i in 1:num_quarters_predvol_oil) {
  qq_predvol_oil = quantile(100*(predvol_oil_matrix[,i]),  probs = c(0.05, 0.5,0.95))
  export_predvol_oil[i,1:3]<- qq_predvol_oil
  export_predvol_oil[i,4] <- mean(100*predvol_oil_matrix[,i])
}
export_predvol_oil<-data.frame(export_predvol_oil)



volplot(sv_model_oil, forecast = NULL, dates = oil_qtrly$date[-1])

## This one produces the estimated volatilites (not the forecasts)
volatilities<-sv_model_oil$summary$sd
volatilities<-data.frame(volatilities)
write.csv(volatilities, file = "volatilities.csv")


## Calculating volatilites for oil price growth (AR1)
oil_qtrly_g <- read_excel("oil_qtrly.xlsx", sheet='op_growth')


# sv_model_oil <- svsample(oil_qtrly$log_real_op, priormu = c(-10, 1), priorphi = c(20, 1.1),
#                          priorsigma = 0.1,designmatrix = "ar1")

oil_qtrly_g$op_growth <- as.numeric(as.character(oil_qtrly_g$op_growth))
sv_model_oil_g <- svsample(oil_qtrly_g$op_growth,designmatrix = "ar1") 
summary(sv_model_oil_g, showlatent = FALSE)
predvol_g <- predict(sv_model_oil_g, forecast = NULL, dates = oil_qtrly$date[-1])




## This one produces the estimated volatilites (not the forecasts)
volatilities_g<-sv_model_oil_g$summary$sd
volatilities_g<-data.frame(volatilities_g)
write.csv(volatilities_g, file = "volatilities_g.csv")


## Calculating volatilites for oil price growth (AR0)
oil_qtrly_g <- read_excel("oil_qtrly.xlsx", sheet='op_growth')


# sv_model_oil <- svsample(oil_qtrly$log_real_op, priormu = c(-10, 1), priorphi = c(20, 1.1),
#                          priorsigma = 0.1,designmatrix = "ar1")

oil_qtrly_g$op_growth <- as.numeric(as.character(oil_qtrly_g$op_growth))
sv_model_oil_g0 <- svsample(oil_qtrly_g$op_growth,designmatrix = "ar0") 
summary(sv_model_oil_g0, showlatent = FALSE)
predvol_g0 <- predict(sv_model_oil_g0, forecast = NULL, dates = oil_qtrly$date[-1])




## This one produces the estimated volatilites (not the forecasts)
volatilities_g0<-sv_model_oil_g0$summary$sd
volatilities_g0<-data.frame(volatilities_g0)
write.csv(volatilities_g0, file = "volatilities_g0.csv")
###############################
## Converting EMBIG spread data into quarterly from 1995 to 2019 sep
library(tidyverse)
library(zoo)

spread_data <- read.xlsx("spread_data.xlsx",sheet='spread',detectDates = TRUE)
spread_data$date=as.Date(spread_data$date, format="%m/%d/%y")
#spread_data<- arrange(spread_data, date)
spread_data$qdate<- as.yearqtr(spread_data$date)
spread_data$Year<- format(spread_data$date, format="%Y")


spread_qtrly<- spread_data %>%
  group_by(qdate,country) %>%
  summarise_all(mean, na.rm=TRUE)

spread_qtrly<- arrange(spread_qtrly, country)

spread_qtrly_sd<- spread_data %>%
  group_by(qdate,country) %>%
  summarise_all(sd, na.rm=TRUE)

spread_qtrly_sd<- arrange(spread_qtrly_sd, country)

## Save spread_qtrly for later use
write.xlsx(spread_qtrly, file = "spread_qtrly.xlsx")

spread_countries <- unique(spread_qtrly[2])
spread_countries <- unlist(spread_countries, recursive = TRUE, use.names = FALSE)
#spread_countries <- levels(droplevels(spread_countries))
spread_countries
length(spread_countries)

spread_qtrly_avg <- data.frame(matrix(NA, nrow = (length(spread_countries)), ncol = 3))
colnames(spread_qtrly_avg)[1] <- "country"
colnames(spread_qtrly_avg)[2] <- "spread"
colnames(spread_qtrly_avg)[3] <- "spread_sd"

for (i in 1:length(spread_countries)){
  spread_qtrly_avg [i,1] = spread_countries[i]
  temp <- subset(spread_qtrly, spread_qtrly$country == spread_countries[i])
  spread_qtrly_avg [i,2] = mean(temp$spread, na.rm=TRUE)
  spread_qtrly_avg [i,3] = sd(temp$spread, na.rm=TRUE)
}


spread_qtrly_avg[18,1] <- "EGYPT"
spread_qtrly_avg[34,1] <- "KOREA"
spread_qtrly_avg[52,1] <- "RUSSIA"
spread_qtrly_avg[60,1] <- "TRINIDAD"
spread_qtrly_avg[65,1] <- "VENEZUELA"

save(spread_qtrly_avg, file = "spread_qtrly_avg.RData")

## Oil import data

import_gdp_data<- read.xlsx("spread_data.xlsx",sheet='import_gdp')
import_gdp_data <- subset(import_gdp_data, import_gdp_data$`import/gdp`>1)
colnames(import_gdp_data)[1] <- "country"

oil_countries <- unique(import_gdp_data[1])
oil_countries <- unlist(oil_countries, recursive = TRUE, use.names = FALSE)

oil_countries
length(oil_countries)
oil_countries[28] <- "EL SALVADOR"
oil_countries[7] <- "KOREA, REP."
oil_countries[3] <- "TRINIDAD AND TOBAGO"

#save(import_gdp_data, file = "import_gdp_data.RData")



## All domestic data transformed into quarterly

domestics_qtrly <- read.xlsx("monthly_domestics.xlsx",sheet='monthly_all',detectDates = TRUE)

domestics_qtrly$date=as.Date(domestics_qtrly$date, format="%m/%d/%y")
#spread_data<- arrange(spread_data, date)
domestics_qtrly$qdate<- as.yearqtr(domestics_qtrly$date)
domestics_qtrly$Year<- format(domestics_qtrly$date, format="%Y")



domestics_qtrly<- domestics_qtrly %>%
  group_by(qdate,country) %>%
  summarise_all(mean, na.rm=TRUE)

domestics_qtrly<- arrange(domestics_qtrly, country)

write.csv(domestics_qtrly, file = "domestics_qtrly.csv")

## Adding global variables

global_qtrly <- read.xlsx("global_monthly.xlsx",sheet='global',detectDates = TRUE)

global_qtrly$date=as.Date(global_qtrly$date, format="%m/%d/%y")
#spread_data<- arrange(spread_data, date)
global_qtrly$qdate<- as.yearqtr(global_qtrly$date)
global_qtrly$Year<- format(global_qtrly$date, format="%Y")



global_qtrly<- global_qtrly %>%
  group_by(qdate) %>%
  summarise_all(mean, na.rm=TRUE)

global_qtrly<- arrange(global_qtrly, qdate)

write.csv(global_qtrly, file = "global_qtrly.csv")

## Creating main database for quarterly frequency

## Assigning id numbers to countries
spread_qtrly<- read.xlsx("spread_qtrly.xlsx")

spread_qtrly<-spread_qtrly %>%
  # arrange the data in growing order for column you want to build sequential group ID from/for
  dplyr::arrange(country) %>%
  # build the groupings
  dplyr::group_by(country) %>%
  # add new column : sequenctial group id
  dplyr::mutate(ID = dplyr::cur_group_id()) %>%
  # always ungroup to prevent unwanted behaviour down stream
  dplyr::ungroup()

## Subsetting to importers of oil only


# all_data_qtrly <- subset(spread_qtrly, spread_qtrly$country == oil_countries[1] | spread_qtrly$country == oil_countries[2] | spread_qtrly$country == oil_countries[3] | spread_qtrly$country == oil_countries[4] | spread_qtrly$country == oil_countries[5] | 
#                               spread_qtrly$country == oil_countries[6]  | spread_qtrly$country == oil_countries[7]  | spread_qtrly$country == oil_countries[8]  | spread_qtrly$country == oil_countries[9] | spread_qtrly$country == oil_countries[10] | 
#                               spread_qtrly$country == oil_countries[11] | spread_qtrly$country == oil_countries[12] | spread_qtrly$country == oil_countries[13] | spread_qtrly$country == oil_countries[14] | spread_qtrly$country == oil_countries[15] | 
#                               spread_qtrly$country == oil_countries[16] | spread_qtrly$country == oil_countries[17] | spread_qtrly$country == oil_countries[18] | spread_qtrly$country == oil_countries[19] | spread_qtrly$country == oil_countries[20] | 
#                               spread_qtrly$country == oil_countries[21] | spread_qtrly$country == oil_countries[22] | spread_qtrly$country == oil_countries[23] | spread_qtrly$country == oil_countries[24] | spread_qtrly$country == oil_countries[25] | 
#                               spread_qtrly$country == oil_countries[26] | spread_qtrly$country == oil_countries[27] | spread_qtrly$country == oil_countries[28] | spread_qtrly$country == oil_countries[29] | spread_qtrly$country == oil_countries[30] |
#                               spread_qtrly$country == oil_countries[31] | spread_qtrly$country == oil_countries[32] | spread_qtrly$country == oil_countries[33] | spread_qtrly$country == oil_countries[34] | spread_qtrly$country == oil_countries[35])



# Keep only oil-importing countries (35 countries)
all_data_qtrly <- subset(spread_qtrly, country %in% oil_countries)

#write.csv(all_data_qtrly, file = "all_data_qtrly.csv")

################################################################################
## SECTION 8: Create Main Analysis Dataset by Merging All Sources
################################################################################

## Step 1: Start with spread_qtrly (already created earlier)
# This is our base - country-quarter panel with spreads

## Step 2: Add oil price data (merge by quarter)
# First, identify the date column name in oil_qtrly
oil_date_col <- NULL
for (possible_name in c("date", "Date", "DATE", "qdate", "quarter")) {
  if (possible_name %in% colnames(oil_qtrly)) {
    oil_date_col <- possible_name
    break
  }
}

if (is.null(oil_date_col)) {
  stop("Cannot find date column in oil_qtrly. Available columns: ",
       paste(colnames(oil_qtrly), collapse = ", "))
}

cat("\nUsing date column:", oil_date_col, "from oil_qtrly\n")

# Load oil data and create log price and growth variables
oil_merge <- oil_qtrly %>%
  mutate(
    qdate = as.yearqtr(.data[[oil_date_col]]),
    log_real_price = log(real_price)
  )

# Add oil price growth if it exists, otherwise create it
if ("op_growth" %in% colnames(oil_merge)) {
  # Select only columns that exist
  cols_to_keep <- c("qdate", "real_price", "log_real_price", "op_growth")
  if ("oil_price" %in% colnames(oil_merge)) cols_to_keep <- c(cols_to_keep, "oil_price")
  oil_merge <- oil_merge %>% dplyr::select(all_of(cols_to_keep))
} else {
  # Create growth rate as percentage change
  oil_merge <- oil_merge %>%
    mutate(op_growth = c(NA, diff(log(real_price)) * 100))
  # Select only columns that exist
  cols_to_keep <- c("qdate", "real_price", "log_real_price", "op_growth")
  if ("oil_price" %in% colnames(oil_merge)) cols_to_keep <- c(cols_to_keep, "oil_price")
  oil_merge <- oil_merge %>% dplyr::select(all_of(cols_to_keep))
}

# Ensure spread_qtrly$qdate is in yearqtr format for merging
spread_qtrly <- spread_qtrly %>%
  mutate(qdate = as.yearqtr(qdate))

# Merge spread data with oil data
# Use inner_join to keep only quarters where BOTH spread AND oil data exist
all_data_qtrly <- spread_qtrly %>%
  inner_join(oil_merge, by = "qdate")

## Step 3: Add domestic variables (merge by country-quarter)
# Ensure qdate is in yearqtr format
if ("qdate" %in% colnames(domestics_qtrly)) {
  domestics_qtrly <- domestics_qtrly %>%
    mutate(qdate = as.yearqtr(qdate))
}

all_data_qtrly <- all_data_qtrly %>%
  left_join(domestics_qtrly, by = c("qdate", "country"))

## Step 4: Add global variables (merge by quarter)
# Ensure qdate is in yearqtr format
if ("qdate" %in% colnames(global_qtrly)) {
  global_qtrly <- global_qtrly %>%
    mutate(qdate = as.yearqtr(qdate))
}

all_data_qtrly <- all_data_qtrly %>%
  left_join(global_qtrly, by = "qdate")

## Step 5: Filter data
# a) Keep only data from 1995 Q1 onwards (when oil volatility data begins)
# b) Subset to oil-importing countries only
all_data_qtrly <- all_data_qtrly %>%
  filter(qdate >= as.yearqtr("1995 Q1")) %>%
  filter(country %in% oil_countries)

## Step 6: Clean up duplicate columns from merging
# Remove columns with .x or .y suffixes (merge artifacts)
all_data_qtrly <- all_data_qtrly %>%
  dplyr::select(-matches("\\.x$|\\.y$"))

## Save the merged dataset for reference
write.xlsx(all_data_qtrly, "all_data_qtrly.xlsx")
write.csv(all_data_qtrly, "all_data_qtrly.csv", row.names = FALSE)

cat("\nMerged dataset created with", nrow(all_data_qtrly), "observations\n")
cat("Countries:", length(unique(all_data_qtrly$country)), "\n")
cat("Time periods:", length(unique(all_data_qtrly$qdate)), "\n")

## Ensure all numeric columns are properly formatted
numeric_cols <- c("spread", "real_price", "log_real_price", "op_growth",
                  "dy3", "GDP", "ex_rate_avg", "ex_rate_end", "res_y",
                  "tbill", "VIX", "ID")

for (col in numeric_cols) {
  if (col %in% colnames(all_data_qtrly)) {
    all_data_qtrly[[col]] <- as.numeric(as.character(all_data_qtrly[[col]]))
  }
}

## Merge volatility data if not already present
if (!"vol" %in% colnames(all_data_qtrly)) {
  # Load volatilities if not in memory
  if (!exists("volatilities")) {
    volatilities <- read.csv("volatilities.csv", row.names = 1)
  }
  # Load oil_qtrly if not in memory (for dates)
  if (!exists("oil_qtrly")) {
    oil_qtrly <- read_excel("oil_qtrly.xlsx")
  }

  # Check for date column (could be "date", "Date", or "DATE")
  date_col <- NULL
  for (possible_name in c("date", "Date", "DATE", "qdate", "quarter")) {
    if (possible_name %in% colnames(oil_qtrly)) {
      date_col <- possible_name
      break
    }
  }

  if (is.null(date_col)) {
    stop("Cannot find date column in oil_qtrly. Available columns: ",
         paste(colnames(oil_qtrly), collapse = ", "))
  }

  # Create a volatility data frame with dates
  # volatilities has 99 obs corresponding to oil_qtrly dates (drops first quarter)
  library(zoo)
  vol_data <- data.frame(
    qdate = as.yearqtr(oil_qtrly[[date_col]][-1]),  # Convert to yearqtr format
    vol = volatilities$mean  # Use posterior mean volatility (not sd which is standard error!)
  )

  # Ensure all_data_qtrly has qdate in yearqtr format
  if ("qdate" %in% colnames(all_data_qtrly)) {
    all_data_qtrly$qdate <- as.yearqtr(all_data_qtrly$qdate)
  } else {
    # If no qdate column, create it from date column
    all_data_qtrly$qdate <- as.yearqtr(all_data_qtrly$date)
  }

  # Merge by quarter - this handles unbalanced panels correctly
  library(dplyr)
  all_data_qtrly <- all_data_qtrly %>%
    left_join(vol_data, by = "qdate")
}

## Merge vol_g (growth volatility AR1) if not already present
if (!"vol_g" %in% colnames(all_data_qtrly)) {
  if (file.exists("volatilities_g.csv")) {
    volatilities_g <- read.csv("volatilities_g.csv", row.names = 1)
    if (!exists("oil_qtrly")) {
      oil_qtrly <- read_excel("oil_qtrly.xlsx")
    }
    # Get date column name
    date_col <- NULL
    for (possible_name in c("date", "Date", "DATE", "qdate", "quarter")) {
      if (possible_name %in% colnames(oil_qtrly)) {
        date_col <- possible_name
        break
      }
    }
    # Growth volatility has one fewer observation (98) due to differencing
    # Use the last N dates where N = length of volatilities_g
    n_obs <- nrow(volatilities_g)
    n_total <- length(oil_qtrly[[date_col]])
    dates_to_use <- oil_qtrly[[date_col]][(n_total - n_obs + 1):n_total]

    vol_g_data <- data.frame(
      qdate = as.yearqtr(dates_to_use),
      vol_g = volatilities_g$mean  # Use posterior mean volatility (not sd!)
    )
    all_data_qtrly <- all_data_qtrly %>%
      left_join(vol_g_data, by = "qdate")
  }
}

## Merge vol_g0 (growth volatility AR0) if not already present
if (!"vol_g0" %in% colnames(all_data_qtrly)) {
  if (file.exists("volatilities_g0.csv")) {
    volatilities_g0 <- read.csv("volatilities_g0.csv", row.names = 1)
    if (!exists("oil_qtrly")) {
      oil_qtrly <- read_excel("oil_qtrly.xlsx")
    }
    # Get date column name
    date_col <- NULL
    for (possible_name in c("date", "Date", "DATE", "qdate", "quarter")) {
      if (possible_name %in% colnames(oil_qtrly)) {
        date_col <- possible_name
        break
      }
    }
    # Growth volatility has one fewer observation (98) due to differencing
    # Use the last N dates where N = length of volatilities_g0
    n_obs <- nrow(volatilities_g0)
    n_total <- length(oil_qtrly[[date_col]])
    dates_to_use <- oil_qtrly[[date_col]][(n_total - n_obs + 1):n_total]

    vol_g0_data <- data.frame(
      qdate = as.yearqtr(dates_to_use),
      vol_g0 = volatilities_g0$mean  # Use posterior mean volatility (not sd!)
    )
    all_data_qtrly <- all_data_qtrly %>%
      left_join(vol_g0_data, by = "qdate")
  }
}

## Scale volatility variables
# Scale by 100 to express volatility in "percentages" (as paper's footnote states)
all_data_qtrly$vol <- all_data_qtrly$vol * 100

# Scale vol_g and vol_g0 similarly if they exist
if ("vol_g" %in% colnames(all_data_qtrly)) {
  all_data_qtrly$vol_g <- all_data_qtrly$vol_g * 100
}
if ("vol_g0" %in% colnames(all_data_qtrly)) {
  all_data_qtrly$vol_g0 <- all_data_qtrly$vol_g0 * 100
}

# creating dummy variables for price level and volatility
# Create binary indicators using sample statistics
vol_mean <- mean(all_data_qtrly$vol, na.rm = TRUE)
price_mean <- mean(all_data_qtrly$log_real_price, na.rm = TRUE)
growth_mean <- mean(all_data_qtrly$op_growth, na.rm = TRUE)

all_data_qtrly$vol_dummy <- ifelse(all_data_qtrly$vol > vol_mean, 1, 0)
all_data_qtrly$p_dummy <- ifelse(all_data_qtrly$log_real_price > price_mean, 1, 0)
all_data_qtrly$p_dummy_g <- ifelse(all_data_qtrly$op_growth > growth_mean, 1, 0)

# Create subsamples using median splits
vol_median <- median(all_data_qtrly$vol, na.rm = TRUE)
price_median <- median(all_data_qtrly$real_price, na.rm = TRUE)

data_high_vol <- subset(all_data_qtrly, vol > vol_median)
data_low_vol <- subset(all_data_qtrly, vol <= vol_median)
data_high_price <- subset(all_data_qtrly, real_price > price_median)
data_low_price <- subset(all_data_qtrly, real_price <= price_median)



mean(data_high_price$spread, na.rm=TRUE)
mean(data_low_price$spread, na.rm=TRUE)


#==============================================================================
# Subsample Analysis: Volatility-Price Regimes
#==============================================================================

# Define thresholds based on sample medians
vol_median <- median(all_data_qtrly$vol, na.rm = TRUE)
price_median <- median(all_data_qtrly$real_price, na.rm = TRUE)
log_price_median <- median(all_data_qtrly$log_real_price, na.rm = TRUE)

# Create high/low volatility subsamples
data_high_vol <- subset(all_data_qtrly, vol > vol_median)
data_low_vol <- subset(all_data_qtrly, vol <= vol_median)

# Create high/low price subsamples
data_high_price <- subset(all_data_qtrly, real_price > price_median)
data_low_price <- subset(all_data_qtrly, real_price <= price_median)

# 2x2 splits: Volatility × Price regimes
data_high_vol_high_price <- subset(data_high_vol, log_real_price > log_price_median)
data_high_vol_low_price <- subset(data_high_vol, log_real_price <= log_price_median)
data_low_vol_high_price <- subset(data_low_vol, log_real_price > log_price_median)
data_low_vol_low_price <- subset(data_low_vol, log_real_price <= log_price_median)





#data_mean_vol <- subset(all_data_qtrly,  all_data_qtrly$vol==13)


mean(data_high_vol$spread, na.rm=TRUE)
# 459.0225
mean(data_low_vol$spread, na.rm=TRUE)
# 392.6281
library(plm)
library(tidyverse)
library(modelsummary)

all_data_qtrly<-all_data_qtrly%>%
  group_by(country)%>%
  mutate(lagged= plm::lag(log_real_price, 1))

all_data_qtrly<-all_data_qtrly %>%
  group_by(country) %>%
  mutate(lag_price=dplyr::lag(log_real_price,1))%>%
  ungroup()




all_data_qtrly<-all_data_qtrly %>%
  group_by(country) %>%
  mutate(spread_diff=c(NA, diff(spread))) %>%
  ungroup()
  
all_data_qtrly$log_spread <- log(all_data_qtrly$spread)
all_data_qtrly<-all_data_qtrly %>%
  group_by(country) %>%
  mutate(log_spread_diff=c(NA, diff(log_spread)))%>%
           ungroup()

all_data_qtrly<-all_data_qtrly %>%
  group_by(country) %>%
  mutate(vol_diff=c(NA, diff(vol)))%>%
  ungroup()
all_data_qtrly<-all_data_qtrly %>%
  group_by(country) %>%
  mutate(dy_diff=c(NA, diff(dy3)))%>%
  ungroup()
all_data_qtrly<-all_data_qtrly %>%
  group_by(country) %>%
  mutate(gdp_diff=c(NA, diff(GDP)))%>%
  ungroup()

all_data_qtrly<-all_data_qtrly %>%
  group_by(country) %>%
  mutate(op_diff=c(NA, diff(lag_price)))%>%
  ungroup()

all_data_qtrly<-all_data_qtrly %>%
  group_by(country) %>%
  mutate(rer_avg_diff=c(NA, diff(ex_rate_avg)))%>%
  ungroup()
all_data_qtrly<-all_data_qtrly %>%
  group_by(country) %>%
  mutate(rer_end_diff=c(NA, diff(ex_rate_end)))%>%
  ungroup()
all_data_qtrly<-all_data_qtrly %>%
  group_by(country) %>%
  mutate(res_diff=c(NA, diff(res_y)))%>%
  ungroup()



all_data_qtrly<-all_data_qtrly %>%
  group_by(country) %>%
  mutate(tbill_diff=c(NA, diff(tbill)))%>%
  ungroup()




# Check complete cases for reg1
reg1_complete <- complete.cases(all_data_qtrly[, c("log_spread_diff", "vol", "op_diff")])
cat("\nComplete cases for reg1 (log_spread_diff, vol, op_diff):", sum(reg1_complete), "\n")

# Check if vol column exists and has the right values
cat("\nVol summary:\n")
print(summary(all_data_qtrly$vol))
cat("\n")

reg1	<- lm(log_spread_diff ~ vol+op_diff, data=all_data_qtrly)
summary(reg1)

reg2	<- lm(log_spread_diff ~ vol+op_diff+factor(country), data=all_data_qtrly)
summary(reg2)

## Diagnostic for reg3
cat("\n=== DIAGNOSTIC for reg3 ===\n")
cat("p_dummy values:\n")
print(table(all_data_qtrly$p_dummy, useNA = "ifany"))
cat("Complete cases for reg3 (log_spread_diff, vol, p_dummy):",
    sum(complete.cases(all_data_qtrly[, c("log_spread_diff", "vol", "p_dummy")])), "\n\n")

reg3	<- lm(log_spread_diff ~ vol+p_dummy:vol, data=all_data_qtrly)
summary(reg3)


reg	<- lm(log_spread_diff ~ op_diff+op_diff:vol_dummy, data=all_data_qtrly)
summary(reg)

reg4	<- lm(log_spread_diff ~ vol+op_diff+dy_diff+tbill_diff+res_diff+rer_avg_diff+VIX, data=all_data_qtrly)
summary(reg4)


reg5	<- lm(log_spread_diff ~ vol+op_diff+dy_diff+tbill_diff+res_diff+rer_avg_diff+VIX+factor(country), data=all_data_qtrly)
summary(reg5)



library(stargazer)

cse	=	function(reg)	{
  rob	=	sqrt(diag(vcovHC(reg,	type	=	"HC1")))
  return(rob)
}


stargazer(reg1, reg2, reg3, reg4,reg5, 
          se=list(cse(reg1),cse(reg2),cse(reg3),cse(reg4),cse(reg5)), 
          #se=list(cse(reg1), cse(reg2), cse(reg3), cse(reg4)),
          #se=list(NULL, NULL, NULL,NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL), #This is to have the 'usual SEs'
          omit=c("country","year"), #This "omit" option is really helpful when reporting the FEs (to hide them)
          title="Oil price volatility and Spread: quarterly Regressions", type="text", 
          #add.lines = list(c("Number of countries", lengths(reg0$xlevels[1]), lengths(reg1$xlevels[1]),lengths(reg2$xlevels[1]), lengths(reg3$xlevels[1]), lengths(reg4$xlevels[1]), lengths(reg5$xlevels[1]), lengths(reg6$xlevels[1]))),
          df=FALSE, digits=2,
          out="spread_reg_qtrly.tex", out.header=FALSE)

models.spread <- list(reg1, reg2, reg3, reg4, reg5)
modelsummary(models.spread, stars = TRUE, vcov = c("HC1","HC1","HC1","HC1","HC1"), fmt=2)








