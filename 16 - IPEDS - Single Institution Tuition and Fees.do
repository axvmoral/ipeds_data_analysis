use "${ipeds_path}/datasets/produced/panel_data.dta"

// uc berkeley = 110635
// ucla = 110662
// uci = 110653
// ucr = 110671

keep if (YEAR >= 1989 & MASTER_CONTROL_FILLED == 0 & UNITID == "110653") // publics only

scalar name = INSTITUTION_NAME[_N]

// Create one variable for full-time undergraduate/graduate tuition and fees in/out-state
egen IN_STATE_FTUG_TUITION_FEES = rowtotal(AVG_IN_STATE_TUITION_FT_UG IN_STATE_FEES_FT_UG IN_STATE_TUITION_FEES_FT_UG), missing
egen OUT_STATE_FTUG_TUITION_FEES = rowtotal(AVG_OUT_STATE_TUITION_FT_UG OUT_STATE_FEES_FT_UG OUT_STATE_TUITION_FEES_FT_UG), missing

egen IN_STATE_FTG_TUITION_FEES = rowtotal(AVG_IN_STATE_TUITION_FT_G IN_STATE_FEES_FT_G IN_STATE_TUITION_FEES_FT_G), missing
egen OUT_STATE_FTG_TUITION_FEES = rowtotal(AVG_OUT_STATE_TUITION_FT_G OUT_STATE_FEES_FT_G OUT_STATE_TUITION_FEES_FT_G), missing

// In district as in state

// Create weighted arithmetic average of tuition and fees for full-time, first-year undergraduates, in/out-state
egen WEIGHTS_TOTAL = rowtotal(PERC_FTFY_UG_IN_STATE PERC_FTFY_UG_OUT_STATE), missing
gen FTFYUG_W_OVERALL_TUITION_FEES = (PERC_FTFY_UG_IN_STATE * IN_STATE_TAF_FTFY_UG + PERC_FTFY_UG_OUT_STATE * OUT_STATE_TAF_FTFY_UG) / WEIGHTS_TOTAL

gen PERC_FTFY_UG_IN_DIST_STATE = PERC_FTFY_UG_IN_DISTRICT + PERC_FTFY_UG_IN_STATE

scalar directory = "${ipeds_path}/outputs/Single Institutions/`=name'"

mata : st_numscalar("OK", direxists("`=directory'"))
	
if (!scalar(OK)) {
	mkdir "`=directory'"
}

graph twoway line IN_STATE_FTUG_TUITION_FEES OUT_STATE_FTUG_TUITION_FEES FTFYUG_W_OVERALL_TUITION_FEES YEAR, sort title("`=name'" "Average Headline Undergraduate Tuition and Fees by Enrollment Type") xtitle("Year") xlabel(1989(3)2022, angle(45)) ytitle("Tuition and Fees ($)") ylabel(#5, format(%15.0fc)) legend(label(1 "Full-Time, In-State") label(2 "Full-Time, Out-Of-State") label(3 "Full-Time, First-Year Overall") position(6) rows(1))

graph export "`=directory'/tuition_and_fees.png", replace

graph twoway line PERC_FTFY_UG_IN_DIST_STATE PERC_FTFY_UG_OUT_STATE YEAR if (YEAR >= 2009), sort title("`=name'" "% of Full-Time, First-Time Graduates In-State/District vs Out-Of-State") xtitle("Year") xlabel(2009(1)2022, angle(45)) ytitle("%") ylabel(#5, format(%15.0fc)) legend(label(1 "In-State/District") label(2 "Out-of-State") position(6) rows(1))

graph export "`=directory'/perc_in_out_state.png", replace

clear
