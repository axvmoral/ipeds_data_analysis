use "${ipeds_path}/datasets/produced/panel_data.dta"

keep if (YEAR >= 2010 & (MASTER_CONTROL_FILLED == 0 | MASTER_CONTROL_FILLED == 1 | MASTER_CONTROL_FILLED == 2))

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
egen GR_SUM_UG_COUNT_0_30 = sum(UG_COUNT_0_30), missing by(MASTER_CONTROL_FILLED YEAR)
egen GR_SUM_UG_COUNT_30_48 = sum(UG_COUNT_30_48), missing by(MASTER_CONTROL_FILLED YEAR)
egen GR_SUM_UG_COUNT_48_75 = sum(UG_COUNT_48_75), missing by(MASTER_CONTROL_FILLED YEAR)
egen GR_SUM_UG_COUNT_75_110 = sum(UG_COUNT_75_110), missing by(MASTER_CONTROL_FILLED YEAR)
egen GR_SUM_UG_COUNT_OVER_110 = sum(UG_COUNT_OVER_110), missing by(MASTER_CONTROL_FILLED YEAR)

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

collapse (mean) UG_COUNT_0_30 UG_COUNT_30_48 UG_COUNT_48_75 UG_COUNT_75_110 UG_COUNT_OVER_110 TOTAL_FTFT_UG (sum) W_UG_AVG_NET_PRICE_0_30 W_UG_AVG_NET_PRICE_30_48 W_UG_AVG_NET_PRICE_48_75 W_UG_AVG_NET_PRICE_75_110 W_UG_AVG_NET_PRICE_OVER_110, by(MASTER_CONTROL_FILLED YEAR)

// direct rowtotal because data already organized by previous by command
egen TOTAL_FTFT_AID = rowtotal(UG_COUNT_0_30 UG_COUNT_30_48 UG_COUNT_48_75 UG_COUNT_75_110 UG_COUNT_OVER_110), missing

gen SHARE_FTFT_AID = (TOTAL_FTFT_AID / TOTAL_FTFT_UG) * 100

// Get shares for each institution type
preserve

keep if (MASTER_CONTROL_FILLED == 0)

scalar pubshare2010 = round(SHARE_FTFT_AID[_n], 0.01)
scalar pubshare2022 = round(SHARE_FTFT_AID[_N], 0.01)

restore

preserve

keep if (MASTER_CONTROL_FILLED == 1)

scalar prnfpshare2010 = round(SHARE_FTFT_AID[_n], 0.01)
scalar prnfpshare2022 = round(SHARE_FTFT_AID[_N], 0.01)

restore

preserve

keep if (MASTER_CONTROL_FILLED == 2)

scalar prfpshare2010 = round(SHARE_FTFT_AID[_n], 0.01)
scalar prfpshare2022 = round(SHARE_FTFT_AID[_N], 0.01)

restore

// generate shares by income bucket (of total FTFT eligable for IV aid)
gen UG_COUNT_0_30_SHARE = UG_COUNT_0_30 / TOTAL_FTFT_AID
gen UG_COUNT_30_48_SHARE = UG_COUNT_30_48 / TOTAL_FTFT_AID
gen UG_COUNT_48_75_SHARE = UG_COUNT_48_75 / TOTAL_FTFT_AID
gen UG_COUNT_75_110_SHARE = UG_COUNT_75_110 / TOTAL_FTFT_AID
gen UG_COUNT_OVER_110_SHARE = UG_COUNT_OVER_110 / TOTAL_FTFT_AID

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

rename UG_COUNT_0_30_SHARE c1
rename UG_COUNT_30_48_SHARE c2
rename UG_COUNT_48_75_SHARE c3
rename UG_COUNT_75_110_SHARE c4
rename UG_COUNT_OVER_110_SHARE c5

scalar directory = "${ipeds_path}/outputs/memo_7/by_institution"

mata : st_numscalar("OK", direxists("`=directory'"))

if (!scalar(OK)) {
	mkdir "`=directory'"
}

keep (MASTER_CONTROL_FILLED YEAR a1 a2 a3 a4 a5 b1 b2 b3 b4 b5 c1 c2 c3 c4 c5)

graph twoway line a1 a2 a3 a4 a5 YEAR, sort by(MASTER_CONTROL_FILLED, yrescale title("Average Net Price per Family Income Bracket") note("Graphs By: Institution Type")) ytitle("Net Price ($)") xtitle("Year") legend(label(1 "$0-30k Income") label(2 "$30-48k Income") label(3 "$48-75k Income") label(4 "$75-110k Income") label(5 "$110k+ Income") cols(3) position(6)) ylabel(#5, format(%15.0fc)) xlabel(2010(1)2022, angle(45))
	
graph export "`=directory'/net_price_by_income_bucket_time_series.png", replace

reshape long a b c, i(MASTER_CONTROL_FILLED YEAR) j(FAMILY_BUCKET)

label define ls 1 `" "$0-30k" "Income" "' 2  `" "$30-48k" "Income" "' 3 `" "$48-75k" "Income" "'  4 `" "$75-110k" "Income" "'  5 `" "$110k+" "Income" "'
label values FAMILY_BUCKET ls

reshape wide a b c, i(MASTER_CONTROL_FILLED FAMILY_BUCKET) j(YEAR)

// automatically select max y scale
egen ROW_MAX_NET_PRICE = rowmax(a2010 a2022)
egen MAX_NET_PRICE_VAR = max(ROW_MAX_NET_PRICE)
scalar max_net_price = MAX_NET_PRICE_VAR[_N]
scalar max_y_scale = max_net_price + (1000 - mod(max_net_price, 1000))
scalar r = floor(max_y_scale / 5)

graph twoway line a2010 a2022 FAMILY_BUCKET, sort by(MASTER_CONTROL_FILLED, title("Average Net Price per Family Income Bracket") note("Graphs By: Institution Type")) ytitle("Net Price ($)") legend(label(1 "2009-10 School Year") label(2 "2021-22 School Year") cols(2)) xtitle("") xscale(noline) xlabel(, valuelabel) ylabel(0(`=r')`=max_y_scale', format(%15.0fc))

graph export "`=directory'/net_price_by_income_bracket_two_years.png", replace
	
graph bar b2010 b2022, over(FAMILY_BUCKET) by(MASTER_CONTROL_FILLED, yrescale title("Average # of First-Time, Full-Time Students Enrolled per" "Family Income Bracket") note("Graphs By: Institution Type")) legend(label(1 "2009-10 School Year") label(2 "2021-22 School Year") position(6) rows(1)) ylabel(, format(%15.0fc)) blabel(bar, format(%15.01fc) size(2.4))
	
graph export "`=directory'/enrollment_count_by_income_bracket_two_years.png", replace

graph bar c2010 c2022, over(FAMILY_BUCKET) by(MASTER_CONTROL_FILLED, title("Average Share of First-Time, Full-Time Students Enrolled per" "Family Income Bracket") note("Graphs By: Institution Type")) legend(label(1 "2009-10 School Year") label(2 "2021-22 School Year") position(6) rows(1)) ylabel(#5, format(%15.1fc)) blabel(bar, format(%15.3fc) size(2))

graph export "`=directory'/share_enrollment_count_by_income_bracket_two_years.png", replace

clear
