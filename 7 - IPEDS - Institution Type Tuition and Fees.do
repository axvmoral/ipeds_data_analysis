use "${ipeds_path}/datasets/produced/panel_data.dta"

keep if ((MASTER_CONTROL_FILLED == 0 | MASTER_CONTROL_FILLED == 1 | MASTER_CONTROL_FILLED == 2) & (YEAR >= 1989))

// Create one variable for full-time undergraduate/graduate tuition and fees in/out-state
egen IN_STATE_FTUG_TUITION_FEES = rowtotal(AVG_IN_STATE_TUITION_FT_UG IN_STATE_FEES_FT_UG IN_STATE_TUITION_FEES_FT_UG), missing
egen OUT_STATE_FTUG_TUITION_FEES = rowtotal(AVG_OUT_STATE_TUITION_FT_UG OUT_STATE_FEES_FT_UG OUT_STATE_TUITION_FEES_FT_UG), missing

egen IN_STATE_FTG_TUITION_FEES = rowtotal(AVG_IN_STATE_TUITION_FT_G IN_STATE_FEES_FT_G IN_STATE_TUITION_FEES_FT_G), missing
egen OUT_STATE_FTG_TUITION_FEES = rowtotal(AVG_OUT_STATE_TUITION_FT_G OUT_STATE_FEES_FT_G OUT_STATE_TUITION_FEES_FT_G), missing

// Create weighted arithmetic average of tuition and fees for full-time, first-year undergraduates, in/out-state
egen WEIGHTS_TOTAL = rowtotal(PERC_FTFY_UG_IN_STATE PERC_FTFY_UG_OUT_STATE), missing
gen FTFYUG_W_OVERALL_TUITION_FEES = (PERC_FTFY_UG_IN_STATE * IN_STATE_TAF_FTFY_UG + PERC_FTFY_UG_OUT_STATE * OUT_STATE_TAF_FTFY_UG) / WEIGHTS_TOTAL

// weight proportional to size of institution
// for every institution compute total FTFT, w = this variable / total by control type total
collapse (mean) IN_STATE_FTUG_TUITION_FEES OUT_STATE_FTUG_TUITION_FEES IN_STATE_FTG_TUITION_FEES OUT_STATE_FTG_TUITION_FEES FTFYUG_W_OVERALL_TUITION_FEES, by(MASTER_CONTROL_FILLED YEAR)

gen NO_DISTINCT_FTUG_TAF = .
replace NO_DISTINCT_FTUG_TAF = IN_STATE_FTUG_TUITION_FEES if (MASTER_CONTROL_FILLED == 1 | MASTER_CONTROL_FILLED == 2)

gen NO_DISTINCT_FTG_TAF = .
replace NO_DISTINCT_FTG_TAF = IN_STATE_FTG_TUITION_FEES if (MASTER_CONTROL_FILLED == 1 | MASTER_CONTROL_FILLED == 2)

replace IN_STATE_FTUG_TUITION_FEES = . if (MASTER_CONTROL_FILLED == 1 | MASTER_CONTROL_FILLED == 2)
replace OUT_STATE_FTUG_TUITION_FEES = . if (MASTER_CONTROL_FILLED == 1 | MASTER_CONTROL_FILLED == 2)

replace IN_STATE_FTG_TUITION_FEES = . if (MASTER_CONTROL_FILLED == 1 | MASTER_CONTROL_FILLED == 2)
replace OUT_STATE_FTG_TUITION_FEES = . if (MASTER_CONTROL_FILLED == 1 | MASTER_CONTROL_FILLED == 2)

graph twoway line IN_STATE_FTUG_TUITION_FEES OUT_STATE_FTUG_TUITION_FEES NO_DISTINCT_FTUG_TAF FTFYUG_W_OVERALL_TUITION_FEES YEAR, by(MASTER_CONTROL_FILLED, yrescale title("Average Headline Undergraduate Tuition and Fees" "per Enrollment Type") note("Graphs By: Institution Type")) xtitle("Year") xlabel(1989(3)2022, angle(45)) ytitle("Tuition and Fees ($)") ylabel(#5, format(%15.0fc)) legend(label(1 "Full-Time, In-State") label(2 "Full-Time, Out-Of-State") label(3 "Full-Time, No Distinction") label(4 "Full-Time, First-Year Overall") cols(2) colfirst)


graph twoway line AVG_TAF_FT_UG_ID AVG_TAF_FT_UG_IS AVG_TAF_FT_UG_OS W_AVG_TAF_FTFY_UG YEAR, sort by(MASTER_CONTROL_FILLED, yrescale title("Average Headline Undergraduate Tuition and Fees" "per Enrollment Type") note("Graphs By: Institution Type")) xtitle("Year") ytitle("Tuition and Fees ($)") ylabel(#5, format(%15.0fc)) legend(label(1 "Full-Time In-District") label(2 "Full-Time In-State") label(3 "Full-Time Out-Of-State") label(4 "Full-Time First-Year Overall") cols(2)) xlabel(1989(3)2022, angle(45))

graph export "${ipeds_path}/outputs/memo_5/tuition_cost_per_fte_undergraduates.png", replace

graph twoway line AVG_TAF_FT_G_ID AVG_TAF_FT_G_IS AVG_TAF_FT_G_OS YEAR, sort by(MASTER_CONTROL_FILLED, title("Average Headline Graduate Tuition and Fees" "per Enrollment Type") note("Graphs By: Institution Type")) xtitle("Year") ytitle("Tuition and Fees ($)") ylabel(#5, format(%15.0fc)) legend(label(1 "Full-Time In-District") label(2 "Full-Time In-State") label(3 "Full-Time Out-Of-State") cols(2)) xlabel(1989(3)2022, angle(45))

graph export "${ipeds_path}/outputs/memo_5/tuition_cost_per_fte_graduates.png", replace

clear
