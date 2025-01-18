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

gen IS_CA = 0
replace IS_CA = 1 if (STATE == "CA")
label define ls 0 "Other States and Territories" 1 "California"
label values IS_CA ls

collapse (mean) W_PUB_UG_AVG_NET_PRICE_0_30 W_PUB_UG_AVG_NET_PRICE_30_48 W_PUB_UG_AVG_NET_PRICE_48_75 W_PUB_UG_AVG_NET_PRICE_75_110 W_PUB_UG_AVG_NET_PRICE_OVER_110, by(IS_CA YEAR)

//graph twoway line W_PUB_UG_AVG_NET_PRICE_0_30 W_PUB_UG_AVG_NET_PRICE_30_48 W_PUB_UG_AVG_NET_PRICE_48_75 W_PUB_UG_AVG_NET_PRICE_75_110 W_PUB_UG_AVG_NET_PRICE_OVER_110 YEAR if (IS_CA == 1), sort title("California Public Institutions Average Net Price for Full-Time," "First-Time Undergraduates Eligible for Title IV Aid" "by Family Income Bracket") ytitle("Net Price ($)") xtitle("Year") legend(label(1 "$0-30k Income") label(2 "$30-48k Income") label(3 "$48-75k Income") label(4 "$75-110k Income") label(5 "$110k+ Income") cols(3) position(6)) ylabel(#5, format(%15.0fc)) xlabel(2010(1)2022, angle(45))

//graph export "${ipeds_path}/outputs/pub_CA_avg_net_price_income_bracket.png", replace

//graph twoway line W_PUB_UG_AVG_NET_PRICE_0_30 W_PUB_UG_AVG_NET_PRICE_30_48 W_PUB_UG_AVG_NET_PRICE_48_75 W_PUB_UG_AVG_NET_PRICE_75_110 W_PUB_UG_AVG_NET_PRICE_OVER_110 YEAR if (IS_CA == 0), sort title("Other States and Territories Public Institutions Average Net Price for Full-Time, First-Time Undergraduates Eligible for Title IV Aid" "by Family Income Bracket") ytitle("Net Price ($)") xtitle("Year") legend(label(1 "$0-30k Income") label(2 "$30-48k Income") label(3 "$48-75k Income") label(4 "$75-110k Income") label(5 "$110k+ Income") cols(3) position(6)) ylabel(#5, format(%15.0fc)) xlabel(2010(1)2022, angle(45))

//graph export "${ipeds_path}/outputs/pub_others_avg_net_price_income_bracket.png", replace

graph twoway line W_PUB_UG_AVG_NET_PRICE_0_30 W_PUB_UG_AVG_NET_PRICE_30_48 W_PUB_UG_AVG_NET_PRICE_48_75 W_PUB_UG_AVG_NET_PRICE_75_110 W_PUB_UG_AVG_NET_PRICE_OVER_110 YEAR, sort by(IS_CA, colfirst title("Public Institutions Average Net Price for Full-Time, First-Time" "Undergraduates Eligible for Title IV Aid per Family Income Bracket") note("Graphs By: Region")) xtitle("Year") ytitle("Net Price ($)") xlabel(2010(1)2022, angle(45)) ylabel(#5, format(%15.0fc)) legend(label(1 "$0-30k Income") label(2 "$30-48k Income") label(3 "$48-75k Income") label(4 "$75-110k Income") label(5 "$110k+ Income") cols(3) position(6))

graph export "${ipeds_path}/outputs/pub_CA_and_others_avg_net_price_income_bracket.png", replace

//reshape wide W_PUB_UG_AVG_NET_PRICE_0_30 W_PUB_UG_AVG_NET_PRICE_30_48 W_PUB_UG_AVG_NET_PRICE_48_75 W_PUB_UG_AVG_NET_PRICE_75_110 W_PUB_UG_AVG_NET_PRICE_OVER_110, i(YEAR) j(IS_CA)

//graph twoway line W_PUB_UG_AVG_NET_PRICE_0_301 W_PUB_UG_AVG_NET_PRICE_0_300 W_PUB_UG_AVG_NET_PRICE_30_481 W_PUB_UG_AVG_NET_PRICE_30_480 W_PUB_UG_AVG_NET_PRICE_48_751 W_PUB_UG_AVG_NET_PRICE_48_750 W_PUB_UG_AVG_NET_PRICE_75_1101 W_PUB_UG_AVG_NET_PRICE_75_1100 W_PUB_UG_AVG_NET_PRICE_OVER_1101 W_PUB_UG_AVG_NET_PRICE_OVER_1100 YEAR, sort title("California VS Other States and Territories Average Net Price" "for Full-Time, First-Time Undergraduates Eligible for Title IV Aid" "by Family Income Bracket") xtitle("Year") ytitle("Net Price ($)") ylabel(#5, format(%15.0fc)) xlabel(2010(1)2022, angle(45)) lcolor(red orange_red blue dknavy green lime yellow sandb black gs6) legend(label(1 "$0-30K CA") label(2 "$0-30K Others") label(3 "$30-48K CA") label(4 "$30-48K Others") label(5 "$48-75K CA") label(6 "$48-75K Others") label(7 "$75-110K CA") label(8 "$75-110K Others") label(9 "$110K+ CA") label(10 "$110K+ Others") position(6) cols(4))

//graph export "${ipeds_path}/outputs/pub_CA_and_others_one_graph_avg_net_price_income_bracket.png", replace

clear
