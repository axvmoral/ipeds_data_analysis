use "${ipeds_path}/datasets/produced/panel_data.dta"

// uc berkeley = 110635
// ucla = 110662
// uci = 110653
// ucr = 110671

keep if ((YEAR == 2009 | YEAR == 2019) & UNITID == "110671")

scalar title = INSTITUTION_NAME[_N]

rename PUB_UG_AVG_NET_PRICE_0_30 a1
rename PUB_UG_AVG_NET_PRICE_30_48 a2
rename PUB_UG_AVG_NET_PRICE_48_75 a3
rename PUB_UG_AVG_NET_PRICE_75_110 a4
rename PUB_UG_AVG_NET_PRICE_OVER_110 a5

rename PUB_UG_COUNT_0_30 b1
rename PUB_UG_COUNT_30_48 b2
rename PUB_UG_COUNT_48_75 b3
rename PUB_UG_COUNT_75_110 b4
rename PUB_UG_COUNT_OVER_110 b5

reshape long a b, i(YEAR) j(FAMILY_BUCKET)

keep (YEAR FAMILY_BUCKET a b)

reshape wide a b, i(FAMILY_BUCKET) j(YEAR)

label define ls 1 `" "$0-30k" "Income" "' 2  `" "$30-48k" "Income" "' 3 `" "$48-75k" "Income" "'  4 `" "$75-110k" "Income" "'  5 `" "$110k+" "Income" "'
label values FAMILY_BUCKET ls

graph twoway line a2009 a2019 FAMILY_BUCKET, sort ytitle("Net Price ($)") legend(label(1 "2008-09 School Year") label(2 "2018-19 School Year")) xtitle("") title("`=title'" "Net Price by Family Income Bracket") xscale(range(0.5,5.5)) xscale(noline) xlabel(, valuelabel noticks nogrid) ylabel(0(5000)35000, format(%15.0fc)) xmtick(0.5(1)5.5, grid noticks)

graph export "${ipeds_path}/grant_proposal/outputs/`=title'/`=title'_net_price_two_years.png", replace

graph bar b2009 b2019, over(FAMILY_BUCKET) legend(label(1 "2008-09 School Year") label(2 "2018-19 School Year") position(6) rows(1)) title("`=title'" "# of First-Time Full-Year Students Enrolled by" "Family Income Bracket") ylabel(, format(%15.0fc)) blabel(bar)

graph export "${ipeds_path}/grant_proposal/outputs/`=title'/`=title'_count_two_years.png", replace

clear