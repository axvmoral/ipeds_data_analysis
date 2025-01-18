use "${ipeds_path}/datasets/produced/panel_data.dta"

keep if (MASTER_CONTROL_FILLED == 0 & YEAR >= 1989)

egen IN_DISTRICT_UG_TUITION_FEES = rowtotal(AVG_IN_DISTRICT_TUITION_FT_UG IN_DISTRICT_FEES_FT_UG IN_DISTRICT_TUITION_FEES_FT_UG), missing
egen IN_STATE_UG_TUITION_FEES = rowtotal(AVG_IN_STATE_TUITION_FT_UG IN_STATE_FEES_FT_UG IN_STATE_TUITION_FEES_FT_UG), missing
egen OUT_STATE_UG_TUITION_FEES = rowtotal(AVG_OUT_STATE_TUITION_FT_UG OUT_STATE_FEES_FT_UG OUT_STATE_TUITION_FEES_FT_UG), missing

egen AVG_TAF_FT_UG_ID = mean(IN_DISTRICT_UG_TUITION_FEES), by(YEAR)
egen AVG_TAF_FT_UG_IS = mean(IN_STATE_UG_TUITION_FEES), by(YEAR)
egen AVG_TAF_FT_UG_OS = mean(OUT_STATE_UG_TUITION_FEES), by(YEAR)

gen W_IN_DISTRICT_TAF_FTFY_UG = PERC_FTFY_UG_IN_DISTRICT * IN_DISTRICT_TAF_FTFY_UG
gen W_IN_STATE_TAF_FTFY_UG = PERC_FTFY_UG_IN_STATE * IN_STATE_TAF_FTFY_UG
gen W_OUT_STATE_TAF_FTFY_UG = PERC_FTFY_UG_OUT_STATE * OUT_STATE_TAF_FTFY_UG

egen W_TOTAL_TAF_FTFY_UG = rowtotal(W_IN_DISTRICT_TAF_FTFY_UG W_IN_STATE_TAF_FTFY_UG W_OUT_STATE_TAF_FTFY_UG), missing
egen WEIGHTS_TOTAL = rowtotal(PERC_FTFY_UG_IN_DISTRICT PERC_FTFY_UG_IN_STATE PERC_FTFY_UG_OUT_STATE)

gen W_ROW_AVG_TAF_FTFY_UG = W_TOTAL_TAF_FTFY_UG / WEIGHTS_TOTAL

egen W_AVG_TAF_FTFY_UG = mean(W_ROW_AVG_TAF_FTFY_UG), by(YEAR)

egen IN_DISTRICT_G_TUITION_FEES = rowtotal(AVG_IN_DISTRICT_TUITION_FT_G IN_DISTRICT_FEES_FT_G IN_DISTRICT_TUITION_FEES_FT_G), missing
egen IN_STATE_G_TUITION_FEES = rowtotal(AVG_IN_STATE_TUITION_FT_G IN_STATE_FEES_FT_G IN_STATE_TUITION_FEES_FT_G), missing
egen OUT_STATE_G_TUITION_FEES = rowtotal(AVG_OUT_STATE_TUITION_FT_G OUT_STATE_FEES_FT_G OUT_STATE_TUITION_FEES_FT_G), missing

egen AVG_TAF_FT_G_ID = mean(IN_DISTRICT_G_TUITION_FEES), by(YEAR)
egen AVG_TAF_FT_G_IS = mean(IN_STATE_G_TUITION_FEES), by(YEAR)
egen AVG_TAF_FT_G_OS = mean(OUT_STATE_G_TUITION_FEES), by(YEAR)

graph twoway line AVG_TAF_FT_UG_ID AVG_TAF_FT_UG_IS AVG_TAF_FT_UG_OS W_AVG_TAF_FTFY_UG YEAR, sort title("Average Headline Undergraduate Tuition and Fees" "by Enrollment Type at Public Institutions") xtitle("Year") ytitle("Tuition and Fees ($)") ylabel(#10, format(%15.0fc)) legend(label(1 "Full-Time In-District") label(2 "Full-Time In-State") label(3 "Full-Time Out-Of-State") label(4 "Full-Time First-Year Overall")) xlabel(1989(3)2022, angle(45))

graph export "${ipeds_path}/grant_proposal/outputs/tuition_cost_per_fte_undergraduates_publics.png", replace

graph twoway line AVG_TAF_FT_G_ID AVG_TAF_FT_G_IS AVG_TAF_FT_G_OS YEAR, sort title("Average Headline Graduate Tuition and Fees" "by Enrollment Type at Public Institutions") xtitle("Year") ytitle("Tuition and Fees ($)") ylabel(0(2000)20000, format(%15.0fc)) legend(label(1 "Full-Time In-District") label(2 "Full-Time In-State") label(3 "Full-Time Out-Of-State")) xlabel(1989(3)2022, angle(45))

graph export "${ipeds_path}/grant_proposal/outputs/tuition_cost_per_fte_graduates_publics.png", replace

clear