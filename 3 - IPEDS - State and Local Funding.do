use "${ipeds_path}/datasets/produced/panel_data.dta"

keep if ((MASTER_CONTROL_FILLED == 0 | MASTER_CONTROL_FILLED == 1 | MASTER_CONTROL_FILLED == 2) & (YEAR >= 1997))

// Replace outlier institution values with interpolated values
replace UNDERGRADUATE_HEADCOUNT = . if UNITID == "431309" & YEAR == 2000
ipolate UNDERGRADUATE_HEADCOUNT YEAR, gen(IPOLATED_UNDERGRADUATE_HEADCOUNT)
replace UNDERGRADUATE_HEADCOUNT = IPOLATED_UNDERGRADUATE_HEADCOUNT if UNITID == "431309" & YEAR == 2000

replace GRADUATE_HEADCOUNT = . if UNITID == "132471" & YEAR == 2000
ipolate GRADUATE_HEADCOUNT YEAR, gen(IPOLATED_GRADUATE_HEADCOUNT)
replace GRADUATE_HEADCOUNT = IPOLATED_GRADUATE_HEADCOUNT if UNITID == "132471" & YEAR == 2000

replace DOCTORS_PRACT_HEADCOUNT = . if UNITID == "132471" & YEAR == 2000
ipolate DOCTORS_PRACT_HEADCOUNT YEAR, gen(IPOLATED_DOCTORS_PRACT_HEADCOUNT)
replace DOCTORS_PRACT_HEADCOUNT = IPOLATED_DOCTORS_PRACT_HEADCOUNT if UNITID == "132471" & YEAR == 2000

replace UNDERGRADUATE_FTE = . if UNITID == "118277" & (YEAR == 2004 | YEAR == 2005)
replace UNDERGRADUATE_FTE = . if UNITID == "443748" & YEAR == 2004 
ipolate UNDERGRADUATE_FTE YEAR, gen(IPOLATED_UNDERGRADUATE_FTE)
replace UNDERGRADUATE_FTE = IPOLATED_UNDERGRADUATE_FTE if UNITID == "118277" & (YEAR == 2004 | YEAR == 2005)
replace UNDERGRADUATE_FTE = IPOLATED_UNDERGRADUATE_FTE if UNITID == "443748" & YEAR == 2004

egen STATE_LOCAL_FUND = rowtotal(STOGC STAPP STNOG LOCOGC LOCAPP LOCNOG LOCPOGC STGC LOCGC ST_AND_LOCAL_AGC LOCGC_UR LOCGC_R STGC_UR STGC_R), missing
egen TOTAL_HEADCOUNT = rowtotal(UNDERGRADUATE_HEADCOUNT GRADUATE_HEADCOUNT DOCTORS_PRACT_HEADCOUNT), missing
egen TOTAL_FTE = rowtotal(UNDERGRADUATE_FTE GRADUATE_FTE DOCTORS_PRACT_FTE), missing

egen SUM_SLF = sum(STATE_LOCAL_FUND), missing by(YEAR MASTER_CONTROL_FILLED)
egen SUM_TOTAL_HEADCOUNT = sum(TOTAL_HEADCOUNT), missing by(YEAR MASTER_CONTROL_FILLED)
egen SUM_TOTAL_FTE = sum(TOTAL_FTE), missing by(YEAR MASTER_CONTROL_FILLED)

gen SLF_PER_TOTAL_HEADCOUNT = SUM_SLF / SUM_TOTAL_HEADCOUNT
gen SLF_PER_TOTAL_FTE = SUM_SLF / SUM_TOTAL_FTE

gen PLOT_SUM_SLF = SUM_SLF / 1000000000

graph twoway line PLOT_SUM_SLF YEAR, sort by(MASTER_CONTROL_FILLED, yrescale title("Total State and Local Funding") note("Graphs By: Institution Type")) xtitle("Year") ytitle("Total Funding (billions $)") ylabel(#5) xlabel(1997(4)2021)

graph export "${ipeds_path}/outputs/State and Local Funding/total_state_and_local_funding_by_ins_type.png", replace

graph twoway line SLF_PER_TOTAL_FTE SLF_PER_TOTAL_HEADCOUNT YEAR, sort by(MASTER_CONTROL_FILLED, yrescale title("State and Local Funding per Enrollment Type") note("Graphs By: Institution Type")) xtitle("Year") ytitle("Ratio ($)") ylabel(#5, format(%15.0fc)) legend(label(1 "Funding per Full-Time Enrollment") label(2 "Funding per Headcount") cols(2)) xlabel(1997(4)2021)

graph export "${ipeds_path}/outputs/State and Local Funding/state_and_local_funding_per_enrollment_ratio_by_ins_type.png", replace

clear