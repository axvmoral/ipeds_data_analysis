use "${ipeds_path}/datasets/produced/panel_data.dta"

keep if (YEAR >= 2010 & MASTER_CONTROL_FILLED == 0) // publics only

egen GR_SUM_PUB_UG_COUNT_0_30 = sum(PUB_UG_COUNT_0_30), missing by(STATE MASTER_STATE YEAR)
egen GR_SUM_PUB_UG_COUNT_30_48 = sum(PUB_UG_COUNT_30_48), missing by(STATE MASTER_STATE YEAR)
egen GR_SUM_PUB_UG_COUNT_48_75 = sum(PUB_UG_COUNT_48_75), missing by(STATE MASTER_STATE YEAR)
egen GR_SUM_PUB_UG_COUNT_75_110 = sum(PUB_UG_COUNT_75_110), missing by(STATE MASTER_STATE YEAR)
egen GR_SUM_PUB_UG_COUNT_OVER_110 = sum(PUB_UG_COUNT_OVER_110), missing by(STATE MASTER_STATE YEAR)

// These are the analytical weights
gen W_PUB_UG_COUNT_0_30 = PUB_UG_COUNT_0_30 / GR_SUM_PUB_UG_COUNT_0_30
gen W_PUB_UG_COUNT_30_48 = PUB_UG_COUNT_30_48 / GR_SUM_PUB_UG_COUNT_30_48
gen W_PUB_UG_COUNT_48_75 = PUB_UG_COUNT_48_75 / GR_SUM_PUB_UG_COUNT_48_75
gen W_PUB_UG_COUNT_75_110 = PUB_UG_COUNT_75_110 / GR_SUM_PUB_UG_COUNT_75_110
gen W_PUB_UG_COUNT_OVER_110 = PUB_UG_COUNT_OVER_110 / GR_SUM_PUB_UG_COUNT_OVER_110

// Weigthed net price variable
gen W_PUB_UG_AVG_NET_PRICE_0_30 = W_PUB_UG_COUNT_0_30 * PUB_UG_AVG_NET_PRICE_0_30
gen W_PUB_UG_AVG_NET_PRICE_30_48 = W_PUB_UG_COUNT_30_48 * PUB_UG_AVG_NET_PRICE_30_48
gen W_PUB_UG_AVG_NET_PRICE_48_75 = W_PUB_UG_COUNT_48_75 * PUB_UG_AVG_NET_PRICE_48_75
gen W_PUB_UG_AVG_NET_PRICE_75_110 = W_PUB_UG_COUNT_75_110 * PUB_UG_AVG_NET_PRICE_75_110
gen W_PUB_UG_AVG_NET_PRICE_OVER_110 = W_PUB_UG_COUNT_OVER_110 * PUB_UG_AVG_NET_PRICE_OVER_110

collapse (mean) PUB_UG_COUNT_0_30 PUB_UG_COUNT_30_48 PUB_UG_COUNT_48_75 PUB_UG_COUNT_75_110 PUB_UG_COUNT_OVER_110 TOTAL_FTFT_UG (sum) W_PUB_UG_AVG_NET_PRICE_0_30 W_PUB_UG_AVG_NET_PRICE_30_48 W_PUB_UG_AVG_NET_PRICE_48_75 W_PUB_UG_AVG_NET_PRICE_75_110 W_PUB_UG_AVG_NET_PRICE_OVER_110, by(STATE MASTER_STATE YEAR)

// direct rowtotal because data already organized by previous by command
egen TOTAL_FTFT_AID = rowtotal(PUB_UG_COUNT_0_30 PUB_UG_COUNT_30_48 PUB_UG_COUNT_48_75 PUB_UG_COUNT_75_110 PUB_UG_COUNT_OVER_110), missing

gen SHARE_FTFT_AID = (TOTAL_FTFT_AID / TOTAL_FTFT_UG) * 100

// generate shares by income bucket (of total FTFT eligable for IV aid)
gen UG_COUNT_0_30_SHARE = PUB_UG_COUNT_0_30 / TOTAL_FTFT_AID * 100
gen UG_COUNT_30_48_SHARE = PUB_UG_COUNT_30_48 / TOTAL_FTFT_AID * 100
gen UG_COUNT_48_75_SHARE = PUB_UG_COUNT_48_75 / TOTAL_FTFT_AID * 100
gen UG_COUNT_75_110_SHARE = PUB_UG_COUNT_75_110 / TOTAL_FTFT_AID * 100
gen UG_COUNT_OVER_110_SHARE = PUB_UG_COUNT_OVER_110 / TOTAL_FTFT_AID * 100

// rename for ease of use in reshape
rename W_PUB_UG_AVG_NET_PRICE_0_30 a1
rename W_PUB_UG_AVG_NET_PRICE_30_48 a2
rename W_PUB_UG_AVG_NET_PRICE_48_75 a3
rename W_PUB_UG_AVG_NET_PRICE_75_110 a4
rename W_PUB_UG_AVG_NET_PRICE_OVER_110 a5

rename PUB_UG_COUNT_0_30 b1
rename PUB_UG_COUNT_30_48 b2
rename PUB_UG_COUNT_48_75 b3
rename PUB_UG_COUNT_75_110 b4
rename PUB_UG_COUNT_OVER_110 b5

rename UG_COUNT_0_30_SHARE c1
rename UG_COUNT_30_48_SHARE c2
rename UG_COUNT_48_75_SHARE c3
rename UG_COUNT_75_110_SHARE c4
rename UG_COUNT_OVER_110_SHARE c5

levelsof STATE, local(STATE_LIST)

foreach state of local STATE_LIST {
	preserve
	
	keep if (STATE == "`state'")

	scalar title = MASTER_STATE[_N]
	scalar state_directory = "${ipeds_path}/outputs/memo_7/states/`=title'"
	scalar type_directory = "`=state_directory'/publics_only"

	mata : st_numscalar("OK1", direxists("`=state_directory'"))
	mata : st_numscalar("OK2", direxists("`=type_directory'"))
	
	if (!scalar(OK1)) {
		mkdir "`=state_directory'"
	}
	if (!scalar(OK2)) {
		mkdir "`=type_directory'"
	}
	
	scalar share2010 = round(SHARE_FTFT_AID[_n], 0.01)
	scalar share2022 = round(SHARE_FTFT_AID[_N], 0.01)
	
	keep (YEAR a1 a2 a3 a4 a5 b1 b2 b3 b4 b5 c1 c2 c3 c4 c5)

	graph twoway line a1 a2 a3 a4 a5 YEAR, sort title("`=title' Public Institutions Average Net Price for Full-Time," "First-Time Undergraduates Eligible for Title IV Aid" "by Family Income Bracket") ytitle("Net Price ($)") xtitle("Year") legend(label(1 "$0-30k Income") label(2 "$30-48k Income") label(3 "$48-75k Income") label(4 "$75-110k Income") label(5 "$110k+ Income") cols(3) position(6)) ylabel(#5, format(%15.0fc)) xlabel(2010(1)2022, angle(45))
	
	graph export "`=type_directory'/net_price_by_income_bucket_time_series.png", replace

	reshape long a b c, i(YEAR) j(FAMILY_BUCKET)

	label define ls 1 `" "$0-30k" "Income" "' 2  `" "$30-48k" "Income" "' 3 `" "$48-75k" "Income" "'  4 `" "$75-110k" "Income" "'  5 `" "$110k+" "Income" "'
	label values FAMILY_BUCKET ls

	reshape wide a b c, i(FAMILY_BUCKET) j(YEAR)

	// automatically select max y scale
	egen ROW_MAX_NET_PRICE = rowmax(a2010 a2022)
	egen MAX_NET_PRICE_VAR = max(ROW_MAX_NET_PRICE)
	scalar max_net_price = MAX_NET_PRICE_VAR[_N]
	scalar max_y_scale = max_net_price + (1000 - mod(max_net_price, 1000))
	scalar r = floor(max_y_scale / 5)

	graph twoway line a2010 a2022 FAMILY_BUCKET, sort ytitle("Net Price ($)") legend(label(1 "2009-10 School Year") label(2 "2021-22 School Year") position(6) rows(1)) xtitle(" ") title("`=title' Public Institutions Average Net Price for Full-Time," "First-Time Undergraduates Eligible for Title IV Aid" "by Family Income Bracket") xscale(range(0.5,5.5)) xscale(noline) xlabel(, valuelabel noticks nogrid) ylabel(0(`=r')`=max_y_scale', format(%15.0fc)) xmtick(0.5(1)5.5, grid noticks)

	graph export "`=type_directory'/net_price_by_income_bracket_two_years.png", replace

	graph bar b2010 b2022, over(FAMILY_BUCKET) legend(label(1 "2009-10 School Year") label(2 "2021-22 School Year") position(6) rows(1)) title("`=title' Public Institutions Average # of Full-Time," "First-Time Undergraduates Eligible for Title IV Aid Enrolled" "by Family Income Bracket") ylabel(, format(%15.0fc)) blabel(bar, format(%15.01fc)) note("`=share2010'% of full-time, first-time degree seeking undergraduates at `=title' received Title IV aid" "in 2009-10. `=share2022'% received aid in 2021-22.")

	graph export "`=type_directory'/enrollment_count_by_income_bracket_two_years.png", replace

	graph bar c2010 c2022, over(FAMILY_BUCKET) legend(label(1 "2009-10 School Year") label(2 "2021-22 School Year") position(6) rows(1)) title("`=title' Public Institutions Average % of Full-Time," "First-Time Undergraduates Eligible for Title IV Aid Enrolled" "by Family Income Bracket") ylabel(#5, format(%15.0fc)) blabel(bar, format(%15.2fc)) note("`=share2010'% of full-time, first-time degree seeking undergraduates at `=title' received Title IV aid" "in 2009-10. `=share2022'% received aid in 2021-22.")

	graph export "`=type_directory'/share_enrollment_count_by_income_bracket_two_years.png", replace

	restore
}

clear