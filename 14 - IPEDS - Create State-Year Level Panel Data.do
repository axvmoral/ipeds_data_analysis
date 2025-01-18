use "${ipeds_path}/datasets/produced/panel_data.dta"

keep if (YEAR >= 2010)

// generate net price variable for all institution types
// fill according to institution type
gen UG_AVG_NET_PRICE_0_30 = PR_UG_AVG_NET_PRICE_0_30
gen UG_AVG_NET_PRICE_30_48 = PR_UG_AVG_NET_PRICE_30_48
gen UG_AVG_NET_PRICE_48_75 = PR_UG_AVG_NET_PRICE_48_75
gen UG_AVG_NET_PRICE_75_110 = PR_UG_AVG_NET_PRICE_75_110
gen UG_AVG_NET_PRICE_OVER_110 = PR_UG_AVG_NET_PRICE_OVER_110

replace UG_AVG_NET_PRICE_0_30 = PUB_UG_AVG_NET_PRICE_0_30 if MASTER_CONTROL_FILLED == 0
replace UG_AVG_NET_PRICE_30_48 = PUB_UG_AVG_NET_PRICE_30_48 if MASTER_CONTROL_FILLED == 0
replace UG_AVG_NET_PRICE_48_75 = PUB_UG_AVG_NET_PRICE_48_75 if MASTER_CONTROL_FILLED == 0
replace UG_AVG_NET_PRICE_75_110 = PUB_UG_AVG_NET_PRICE_75_110 if MASTER_CONTROL_FILLED == 0
replace UG_AVG_NET_PRICE_OVER_110 = PUB_UG_AVG_NET_PRICE_OVER_110 if MASTER_CONTROL_FILLED == 0

// generate count variable for all institution types
// fill according to institution type
gen UG_COUNT_0_30 = PR_UG_COUNT_0_30
gen UG_COUNT_30_48 = PR_UG_COUNT_30_48
gen UG_COUNT_48_75 = PR_UG_COUNT_48_75
gen UG_COUNT_75_110 = PR_UG_COUNT_75_110
gen UG_COUNT_OVER_110 = PR_UG_COUNT_OVER_110

replace UG_COUNT_0_30 = PUB_UG_COUNT_0_30 if MASTER_CONTROL_FILLED == 0
replace UG_COUNT_30_48 = PUB_UG_COUNT_30_48 if MASTER_CONTROL_FILLED == 0
replace UG_COUNT_48_75 = PUB_UG_COUNT_48_75 if MASTER_CONTROL_FILLED == 0
replace UG_COUNT_75_110 = PUB_UG_COUNT_75_110 if MASTER_CONTROL_FILLED == 0
replace UG_COUNT_OVER_110 = PUB_UG_COUNT_OVER_110 if MASTER_CONTROL_FILLED == 0

// Enrollment sum by group for analytical weights
egen GR_SUM_UG_COUNT_0_30 = sum(UG_COUNT_0_30), missing by(STATE MASTER_STATE YEAR)
egen GR_SUM_UG_COUNT_30_48 = sum(UG_COUNT_30_48), missing by(STATE MASTER_STATE YEAR)
egen GR_SUM_UG_COUNT_48_75 = sum(UG_COUNT_48_75), missing by(STATE MASTER_STATE YEAR)
egen GR_SUM_UG_COUNT_75_110 = sum(UG_COUNT_75_110), missing by(STATE MASTER_STATE YEAR)
egen GR_SUM_UG_COUNT_OVER_110 = sum(UG_COUNT_OVER_110), missing by(STATE MASTER_STATE YEAR)

// These are the analytical weights
gen W_UG_COUNT_0_30 = UG_COUNT_0_30 / GR_SUM_UG_COUNT_0_30
gen W_UG_COUNT_30_48 = UG_COUNT_30_48 / GR_SUM_UG_COUNT_30_48
gen W_UG_COUNT_48_75 = UG_COUNT_48_75 / GR_SUM_UG_COUNT_48_75
gen W_UG_COUNT_75_110 = UG_COUNT_75_110 / GR_SUM_UG_COUNT_75_110
gen W_UG_COUNT_OVER_110 = UG_COUNT_OVER_110 / GR_SUM_UG_COUNT_OVER_110

// Weigthed net price variable
gen W_UG_AVG_NET_PRICE_0_30 = W_UG_COUNT_0_30 * UG_AVG_NET_PRICE_0_30
gen W_UG_AVG_NET_PRICE_30_48 = W_UG_COUNT_30_48 * UG_AVG_NET_PRICE_30_48
gen W_UG_AVG_NET_PRICE_48_75 = W_UG_COUNT_48_75 * UG_AVG_NET_PRICE_48_75
gen W_UG_AVG_NET_PRICE_75_110 = W_UG_COUNT_75_110 * UG_AVG_NET_PRICE_75_110
gen W_UG_AVG_NET_PRICE_OVER_110 = W_UG_COUNT_OVER_110 * UG_AVG_NET_PRICE_OVER_110

collapse (mean) UG_COUNT_0_30 UG_COUNT_30_48 UG_COUNT_48_75 UG_COUNT_75_110 UG_COUNT_OVER_110 (sum) W_UG_AVG_NET_PRICE_0_30 W_UG_AVG_NET_PRICE_30_48 W_UG_AVG_NET_PRICE_48_75 W_UG_AVG_NET_PRICE_75_110 W_UG_AVG_NET_PRICE_OVER_110, by(STATE MASTER_STATE YEAR)

label variable W_UG_AVG_NET_PRICE_0_30 "Weighted average net-price for the $0-30k income bracket."
label variable W_UG_AVG_NET_PRICE_30_48 "Weighted average net-price for the $30-48k income bracket."
label variable W_UG_AVG_NET_PRICE_48_75 "Weighted average net-price for the $48-75k income bracket."
label variable W_UG_AVG_NET_PRICE_75_110 "Weighted average net-price for the $75-110k income bracket."
label variable W_UG_AVG_NET_PRICE_OVER_110 "Weighted average net-price for the $110k+ income bracket."

label variable UG_COUNT_0_30 "Average enrollment count for the $0-30k income bracket."
label variable UG_COUNT_30_48 "Average enrollment count for the $30-48k income bracket."
label variable UG_COUNT_48_75 "Average enrollment count for the $48-75k income bracket."
label variable UG_COUNT_75_110 "Average enrollment count for the $75-110k income bracket."
label variable UG_COUNT_OVER_110 "Average enrollment count for the $110k+ income bracket."

save "${ipeds_path}/datasets/produced/panel_data_state_year_level.dta", replace

clear
