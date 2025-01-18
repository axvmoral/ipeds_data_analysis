use "${ipeds_path}/datasets/produced/panel_data.dta"

keep if (YEAR >= 1986 & UNITID == "110714")

scalar title = INSTITUTION_NAME[_N]

scalar directory = "${ipeds_path}/outputs/Single Institutions/`=title'"

mata : st_numscalar("OK", direxists("`=directory'"))

if (!scalar(OK)) {
	mkdir "`=directory'"
}

egen STATE_LOCAL_FUND = rowtotal(STOGC STAPP STNOG LOCOGC LOCAPP LOCNOG LOCPOGC STGC LOCGC ST_AND_LOCAL_AGC LOCGC_UR LOCGC_R STGC_UR STGC_R), missing
egen FED_RESEARCH_GRANTS_CONTRACTS = rowtotal(FEDOGC FEDNOG FEDGC FEDOTHG FEDGC_UR FEDGC_R), missing
egen PHILL_SUPPORT = rowtotal(GIFTS CAPGG PRGGC CONAF PSUPPORT PRGC PRG_UR PRG_R ENDOW_UR ENDOW_R ENDOW), missing
egen TOTAL = rowtotal(STATE_LOCAL_FUND FED_RESEARCH_GRANTS_CONTRACTS PHILL_SUPPORT TUITION PELL), missing

egen SLF_SUM = sum(STATE_LOCAL_FUND), missing by(YEAR)
egen FRGG_SUM = sum(FED_RESEARCH_GRANTS_CONTRACTS), missing by(YEAR)
egen PS_SUM = sum(PHILL_SUPPORT), missing by(YEAR)
egen TUITION_SUM = sum(TUITION), missing by(YEAR)
egen PELL_SUM = sum(PELL), missing by(YEAR)
egen TOTAL_SUM = sum(TOTAL), missing by(YEAR)

gen PLOT_SLF_SUM = SLF_SUM / 1000000000
gen PLOT_FRGG_SUM = FRGG_SUM / 1000000000
gen PLOT_PS_SUM = PS_SUM / 1000000000
gen PLOT_TUITION_SUM = TUITION_SUM / 1000000000
gen PLOT_PELL_SUM = PELL_SUM / 1000000000

gen sum2 = PLOT_PS_SUM + PLOT_PELL_SUM
gen sum3 = sum2 + PLOT_FRGG_SUM
gen sum4 = sum3 + PLOT_SLF_SUM
gen sum5 = sum4 + PLOT_TUITION_SUM

gen PLOT_SLF_PERC = SLF_SUM / TOTAL_SUM
gen PLOT_FRGG_PERC = FRGG_SUM / TOTAL_SUM
gen PLOT_PS_PERC = PS_SUM / TOTAL_SUM
gen PLOT_TUITION_PERC = TUITION_SUM / TOTAL_SUM
gen PLOT_PELL_PERC = PELL_SUM / TOTAL_SUM

gen perc2 = PLOT_PS_PERC + PLOT_PELL_PERC
gen perc3 = perc2 + PLOT_FRGG_PERC
gen perc4 = perc3 + PLOT_SLF_PERC
gen perc5 = perc4 + PLOT_TUITION_PERC

graph twoway area PLOT_PS_SUM YEAR, sort || rarea PLOT_PS_SUM sum2 YEAR, sort || rarea sum2 sum3 YEAR, sort || rarea sum3 sum4 YEAR, sort || rarea sum4 sum5 YEAR, sort title("Funding Sources for `=title', $") xtitle("Year") xlabel(1986(5)2021) ytitle("Funding (billions)") ylabel(#5) legend(order(5 "Tuition" 4 "State and Local Funding" 3 "Federal Research Grants and Contracts" 2 "Pell Grants" 1 "Philanthropic Support") cols(2) position(6))

graph export "${ipeds_path}/outputs/Single Institutions/`=title'/layered_cake_institutional_funding.png", replace

graph twoway area PLOT_PS_PERC YEAR, sort || rarea PLOT_PS_PERC perc2 YEAR, sort || rarea perc2 perc3 YEAR, sort || rarea perc3 perc4 YEAR, sort || rarea perc4 perc5 YEAR, sort title("Funding Sources for `=title', %") xtitle("Year") xlabel(1986(5)2021) ytitle("Percentage of Total") ylabel(0 "0" 0.2 "20" 0.4 "40" 0.6 "60" 0.8 "80" 1 "100") legend(order(5 "Tuition" 4 "State and Local Funding" 3 "Federal Research Grants and Contracts" 2 "Pell Grants" 1 "Philanthropic Support") cols(2) position(6))

graph export "${ipeds_path}/outputs/Single Institutions/`=title'/perc_layered_cake_institutional_funding.png", replace

clear
