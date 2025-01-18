use "${ipeds_path}/datasets/produced/panel_data.dta"

keep if ((MASTER_CONTROL_FILLED == 0 | MASTER_CONTROL_FILLED == 1 | MASTER_CONTROL_FILLED == 2) & YEAR >= 2001)

egen AVG_PROGRAMS_COUNT = mean(PROGRAMS_COUNT), by(YEAR MASTER_CONTROL_FILLED)
egen AVG_TOTAL_AWARDS_MEN_WOMEN = mean(TOTAL_AWARDS_MEN_WOMEN), by(YEAR MASTER_CONTROL_FILLED)

graph twoway line AVG_PROGRAMS_COUNT YEAR, sort by(MASTER_CONTROL_FILLED, title("Average Number of Masters Programs Offered") note("Graphs By: Institution Type")) xtitle("Year") ytitle("Average") ylabel(#5) xlabel(2001(7)2022)

graph export "${ipeds_path}/outputs/Masters Degrees/masters_programs_offered.png", replace

graph twoway line AVG_TOTAL_AWARDS_MEN_WOMEN YEAR, sort by(MASTER_CONTROL_FILLED, title("Average Number of Masters Degrees Conferred") note("Graphs By: Institution Type")) xtitle("Year") ytitle("Average") ylabel(#5) xlabel(2001(7)2022)

graph export "${ipeds_path}/outputs/Masters Degrees/masters_degrees_conferred.png", replace

clear
