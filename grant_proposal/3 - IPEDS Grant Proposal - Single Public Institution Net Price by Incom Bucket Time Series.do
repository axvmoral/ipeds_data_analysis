use "${ipeds_path}/datasets/produced/panel_data.dta"

// uc berkeley = 110635
// ucla = 110662
// uci = 110653
// ucr = 110671

keep if (YEAR >= 2009 & UNITID == "110671")

scalar title = INSTITUTION_NAME[_N]

graph twoway line PUB_UG_AVG_NET_PRICE_0_30 PUB_UG_AVG_NET_PRICE_30_48 PUB_UG_AVG_NET_PRICE_48_75 PUB_UG_AVG_NET_PRICE_75_110 PUB_UG_AVG_NET_PRICE_OVER_110 YEAR, sort title("`=title'" "Net Prices by Family Income Bracket") ytitle("Net Price ($)") xtitle("Year") legend(label(1 "$0-30k Income") label(2 "$30-48k Income") label(3 "$48-75k Income") label(4 "$75-110k Income") label(5 "$110k+ Income")) ylabel(0(5000)35000, format(%15.0fc)) xlabel(2009(2)2021, angle(45)) xmlabel(2010(2)2022, angle(45) labsize(small) tlength(1.5))

graph export "${ipeds_path}/grant_proposal/outputs/`=title'/`=title'_net_price_time_series.png", replace

clear