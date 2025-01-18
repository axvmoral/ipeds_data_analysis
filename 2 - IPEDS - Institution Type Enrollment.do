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

egen GRAD_DPP_HEADCOUNT = rowtotal(GRADUATE_HEADCOUNT DOCTORS_PRACT_HEADCOUNT), missing
egen SUM_UNDERGRADUATE_HEADCOUNT = sum(UNDERGRADUATE_HEADCOUNT), missing by(YEAR MASTER_CONTROL_FILLED)
egen SUM_GRAD_DPP_HEADCOUNT = sum(GRAD_DPP_HEADCOUNT), missing by(YEAR MASTER_CONTROL_FILLED)
gen PLOT_SUM_UNDERGRADUATE_HEADCOUNT = SUM_UNDERGRADUATE_HEADCOUNT / 1000000
gen PLOT_SUM_GRAD_DPP_HEADCOUNT = SUM_GRAD_DPP_HEADCOUNT / 1000000

egen GRAD_DPP_FTE = rowtotal(GRADUATE_FTE DOCTORS_PRACT_FTE), missing
egen SUM_UNDERGRADUATE_FTE = sum(UNDERGRADUATE_FTE), missing by(YEAR MASTER_CONTROL_FILLED)
egen SUM_GRAD_DPP_FTE = sum(GRAD_DPP_FTE), missing by(YEAR MASTER_CONTROL_FILLED)
gen PLOT_SUM_UNDERGRADUATE_FTE = SUM_UNDERGRADUATE_FTE / 1000000
gen PLOT_SUM_GRAD_DPP_FTE = SUM_GRAD_DPP_FTE / 1000000

twoway line PLOT_SUM_UNDERGRADUATE_FTE PLOT_SUM_UNDERGRADUATE_HEADCOUNT YEAR, sort by(MASTER_CONTROL_FILLED, yrescale title("Total Undergraduate Headcount and Full-Time Enrollment") note("Graphs By: Institution Type")) xtitle("Year") xlabel(1997(5)2022) ytitle("Count (millions)") ylabel(#5, format(%15.0fc)) legend(label(1 "Total Undergraduate Full-Time Enrollment") label(2 "Total Undergraduate Headcount") cols(2))

graph export "${ipeds_path}/outputs/Enrollment By Institution Type/ug_enrollment_by_ins_type.png", replace

twoway line PLOT_SUM_GRAD_DPP_FTE PLOT_SUM_GRAD_DPP_HEADCOUNT YEAR, sort by(MASTER_CONTROL_FILLED, yrescale title("Total Graduate Headcount and Full-Time Enrollment") note("Graphs By: Institution Type")) xtitle("Year") xlabel(1997(5)2022) ytitle("Count (millions)") ylabel(#5, format(%15.1fc)) legend(label(1 "Total Graduate Full-Time Enrollment") label(2 "Total Graduate Headcount") cols(2))

graph export "${ipeds_path}/outputs/Enrollment By Institution Type/grad_enrollment_by_ins_type.png", replace

clear
