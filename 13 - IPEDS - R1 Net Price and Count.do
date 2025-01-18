use "${ipeds_path}/datasets/produced/panel_data.dta"

keep if (YEAR >= 2010 & (MASTER_CONTROL_FILLED == 0 | MASTER_CONTROL_FILLED == 1 | MASTER_CONTROL_FILLED == 2) & MASTER_CARNEGIE_BASIC == 15) // R1 Universities only

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
egen GR_SUM_UG_COUNT_0_30 = sum(UG_COUNT_0_30), missing by(YEAR)
egen GR_SUM_UG_COUNT_30_48 = sum(UG_COUNT_30_48), missing by(YEAR)
egen GR_SUM_UG_COUNT_48_75 = sum(UG_COUNT_48_75), missing by(YEAR)
egen GR_SUM_UG_COUNT_75_110 = sum(UG_COUNT_75_110), missing by(YEAR)
egen GR_SUM_UG_COUNT_OVER_110 = sum(UG_COUNT_OVER_110), missing by(YEAR)

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

collapse (mean) UG_COUNT_0_30 UG_COUNT_30_48 UG_COUNT_48_75 UG_COUNT_75_110 UG_COUNT_OVER_110 (sum) W_UG_AVG_NET_PRICE_0_30 W_UG_AVG_NET_PRICE_30_48 W_UG_AVG_NET_PRICE_48_75 W_UG_AVG_NET_PRICE_75_110 W_UG_AVG_NET_PRICE_OVER_110, by(YEAR)

// rename for ease of use in reshape
rename W_UG_AVG_NET_PRICE_0_30 a1
rename W_UG_AVG_NET_PRICE_30_48 a2
rename W_UG_AVG_NET_PRICE_48_75 a3
rename W_UG_AVG_NET_PRICE_75_110 a4
rename W_UG_AVG_NET_PRICE_OVER_110 a5

rename UG_COUNT_0_30 b1
rename UG_COUNT_30_48 b2
rename UG_COUNT_48_75 b3
rename UG_COUNT_75_110 b4
rename UG_COUNT_OVER_110 b5

scalar directory = "${ipeds_path}/outputs/memo_7/r1_only"

mata : st_numscalar("OK", direxists("`=directory'"))

if (!scalar(OK)) {
	mkdir "`=directory'"
}

graph twoway line a1 a2 a3 a4 a5 YEAR, sort title("R1 Institutions" "Average Net Price by Family Income Bracket") ytitle("Net Price ($)") xtitle("Year") legend(label(1 "$0-30k Income") label(2 "$30-48k Income") label(3 "$48-75k Income") label(4 "$75-110k Income") label(5 "$110k+ Income") cols(3) position(6)) ylabel(#5, format(%15.0fc)) xlabel(2010(1)2022, angle(45))
	
graph export "`=directory'/net_price_by_income_bucket_time_series.png", replace

reshape long a b, i(YEAR) j(FAMILY_BUCKET)

label define ls 1 `" "$0-30k" "Income" "' 2  `" "$30-48k" "Income" "' 3 `" "$48-75k" "Income" "'  4 `" "$75-110k" "Income" "'  5 `" "$110k+" "Income" "'
label values FAMILY_BUCKET ls

reshape wide a b, i(FAMILY_BUCKET) j(YEAR)
	
graph twoway line a2010 a2022 FAMILY_BUCKET, sort ytitle("Net Price ($)") legend(label(1 "2009-10 School Year") label(2 "2021-22 School Year")) xtitle("") title("R1 Institutions" "Average Net Price by Family Income Bracket") xscale(range(0.5,5.5)) xscale(noline) xlabel(, valuelabel noticks nogrid) ylabel(#5, format(%15.0fc)) xmtick(0.5(1)5.5, grid noticks)
	
graph export "`=directory'/net_price_by_income_bracket_two_years.png", replace
	
graph bar b2010 b2022, over(FAMILY_BUCKET) legend(label(1 "2009-10 School Year") label(2 "2021-22 School Year") position(6) rows(1)) title("R1 Institutions" "Average # of First-Time Full-Year Students Enrolled by" "Family Income Bracket") ylabel(, format(%15.0fc)) blabel(bar, format(%15.01fc))
	
graph export "`=directory'/enrollment_count_by_income_bracket_two_years.png", replace

clear
