********************************************************************************
* Project: Defending Patriarchal Arrangements: Explaining Men's disproportionate support for Populist Radical Right in Europe
* This do-file: 02_Data_Analysis
********************************************************************************
* REPLICATION PACKAGE NOTE: This do-file reproduces Tables 1-2 and Figures 1-3
* of the paper in full, and estimates the three triple-interaction models
* underlying Tables 3-4. Per the paper's own analytical strategy, Table 3's
* log-odds coefficients and Table 4's average marginal effects are read
* directly off this do-file's own estimation and margins output (captured in
* the run log) -- there is no separate table-formatting step for Tables 3-4,
* consistent with how every other reported coefficient in this package is
* verified straight from Stata's native output.
*
* Three marginsplot/graph export blocks present in earlier drafts (for the
* Gender x Breadwinner Norm interaction, Gender x Same-Sex Fathers
* interaction, and the three triple-interaction class plots) have been
* removed: none of those figures are referenced in the paper or in the
* Online Appendix. The underlying models are untouched, since they still
* supply Tables 2, 3, and 4.

clear all
macro drop _all
set linesize 200

********************************************************************************
* PATHS
* Edit ONLY the line below (ROOT) to point Stata at the folder that contains
* this replication package's Input / Process / Output subfolders. All other
* paths in this file are built relative to ROOT and require no further edits.
********************************************************************************
global ROOT "C:/Users/Reviewer/Desktop/Replication_Package"

global OUTPUT   "$ROOT/Output"
global OUT_DATA "$OUTPUT/Data"
global OUT_LOG  "$OUTPUT/Logs"
global OUT_FIG  "$OUTPUT/Figures"
global OUT_EST  "$OUTPUT/Estimates"

********************************************************************************
* Logging
********************************************************************************
cap log close _all
local stamp = subinstr("`c(current_date)'"," ","_",.)
log using "$OUT_LOG/02_Data_Analysis_`stamp'.log", replace text

* Load the dataset produced by 01_Data_Preparation.do
use "$OUT_DATA/Analysis_data.dta", clear

********************************************************************************
* GEOGRAPHIC RESTRICTION: Keep only European countries
********************************************************************************
* This drops non-European democracies and electoral autocracies to ensure
* theoretical consistency regarding the PRR and post-industrial labor markets.
keep if inlist(country, 40, 100, 191, 203, 208, 246, 250, 276, 300, 348, ///
                        352, 380, 440, 528, 578, 616, 703, 705, 724, 752, 756)

********************************************************************************
* MULTILEVEL LOGISTIC MODELS: Stepwise Average Marginal Effects
********************************************************************************

* Create a flag to keep the analytical sample strictly constant across all models
gen estimation_sample = 1

replace estimation_sample = 0 if missing(rr_vote, male, age, educ_3cat, oesch8_class, urban)
replace estimation_sample = 0 if missing(relig_attend, in_work, econ_diff)
replace estimation_sample = 0 if missing(male_pol_lead, trad_bwnorm, gay_father, country)

bysort country: egen prr_available = max(rr_vote)
replace estimation_sample = 0 if prr_available != 1

* -------------------------------------------------------------------------
* Model 1: The Raw Gender Gap
* -------------------------------------------------------------------------
melogit rr_vote i.male ///
    if estimation_sample == 1 || country:, vce(robust)
* Post the AMEs to memory so esttab displays probabilities instead of log-odds
margins, dydx(male) post
estimates store ame_m1

* -------------------------------------------------------------------------
* Model 2: Structural Controls & Economic Grievance
* -------------------------------------------------------------------------
melogit rr_vote i.male ///
    c.age##c.age i.educ_3cat i.oesch8_class i.urban c.relig_attend i.in_work c.econ_diff ///
    if estimation_sample == 1 || country:, vce(robust)
margins, dydx(male age educ_3cat oesch8_class urban relig_attend in_work econ_diff) post
estimates store ame_m2

* -------------------------------------------------------------------------
* Model 3: Full Model (Adding the Three Dimensions of Patriarchy)
* -------------------------------------------------------------------------
melogit rr_vote i.male ///
    c.age##c.age i.educ_3cat i.oesch8_class i.urban c.relig_attend i.in_work c.econ_diff ///
    c.gay_father c.trad_bwnorm c.male_pol_lead ///
    if estimation_sample == 1 || country:, vce(robust)
margins, dydx(male age educ_3cat oesch8_class urban relig_attend in_work econ_diff gay_father trad_bwnorm male_pol_lead) post
estimates store ame_m3

********************************************************************************
* TABLE 1: Average Marginal Effects
********************************************************************************

* Output the stored models into a single comparative table
esttab ame_m1 ame_m2 ame_m3, ///
    cells(b(star fmt(3)) se(par fmt(3))) ///
    starlevels(* 0.05 ** 0.01 *** 0.001) ///
    stats(N, labels("Observations") fmt(0)) ///
    label replace nobaselevels ///
    varlabels(1.male "Male" ///
              econ_diff "Economic Precarity" ///
              gay_father "Rejects Same-Sex Fathers" ///
              trad_bwnorm "Traditional Breadwinner Norm" ///
              male_pol_lead "Preference for male political leadership") ///
    title("Table 1. Average Marginal Effects on Populist Radical Right Voting") ///
    addnotes("Note: Coefficients represent Average Marginal Effects (change in probability). Standard errors in parentheses. * p<0.05, ** p<0.01, *** p<0.001.")


********************************************************************************
* FIGURE 1: Country-Level Mediation: Raw Gender Gap vs. Full Patriarchal Model (AMEs)
********************************************************************************

preserve

* Filter out missing values for all variables used in the full model
* to ensure an identical sample size for both estimates in every country
drop if missing(rr_vote, male, age, educ_3cat, oesch8_class, urban, relig_attend, in_work)
drop if missing(econ_diff, gay_father, trad_bwnorm, male_pol_lead, c_alphan)

* Safely drop the flag if it exists, then recreate it for the current clean sample
capture drop prr_available
bysort c_alphan: egen prr_available = max(rr_vote)
keep if prr_available == 1

* Set up a temporary file to store the regression coefficients
tempname memhold
tempfile results
postfile `memhold' str2 c_alphan coef_base ci_lo_base ci_hi_base coef_full ci_lo_full ci_hi_full using `results'

* Loop through each country
levelsof c_alphan, local(countries)
foreach c of local countries {

    * ---------------------------------------------------------------------
    * Model 1: Raw Gender Gap (Average Marginal Effect)
    * ---------------------------------------------------------------------
    logit rr_vote i.male if c_alphan == "`c'", vce(robust)
    margins, dydx(male) post

    local b_base = _b[1.male]
    local se_base = _se[1.male]
    local z = invnormal(0.975)
    local lo_base = `b_base' - `z'*`se_base'
    local hi_base = `b_base' + `z'*`se_base'

    * ---------------------------------------------------------------------
    * Model 3: Full Patriarchal & Structural Model (Average Marginal Effect)
    * ---------------------------------------------------------------------
    * Note: 'capture noisily' is used because a small PRR N in a single country
    * might cause perfect prediction with categorical controls like oesch8_class.
    capture noisily logit rr_vote i.male ///
        c.age##c.age i.educ_3cat i.oesch8_class i.urban c.relig_attend i.in_work ///
        c.econ_diff c.gay_father c.trad_bwnorm c.male_pol_lead ///
        if c_alphan == "`c'", vce(robust)

    if _rc == 0 {
        capture noisily margins, dydx(male) post
        if _rc == 0 {
            local b_full = _b[1.male]
            local se_full = _se[1.male]
            local lo_full = `b_full' - `z'*`se_full'
            local hi_full = `b_full' + `z'*`se_full'
        }
        else {
            local b_full = .
            local lo_full = .
            local hi_full = .
        }
    }
    else {
        local b_full = .
        local lo_full = .
        local hi_full = .
    }

    * Post both sets of results to the tempfile
    post `memhold' ("`c'") (`b_base') (`lo_base') (`hi_base') (`b_full') (`lo_full') (`hi_full')
}
postclose `memhold'

* Load the results dataset
use `results', clear

* Drop countries where the full model failed to converge due to small N / perfect prediction
drop if missing(coef_full)

* Sort by the base coefficient to maintain a clean caterpillar order
sort coef_base
generate id = _n

* Create offset IDs to plot the two estimates side-by-side without overlapping
generate id_base = id - 0.15
generate id_full = id + 0.15

* Build a local macro to explicitly label the Y-axis ticks with country names
local y_labels ""
local N = _N
forvalues i = 1/`N' {
    local cname = c_alphan[`i']
    local y_labels `"`y_labels' `i' "`cname'""'
}

* SAVE THE DATASET TO AVOID RERUNNING THE LOOP FOR PLOT TWEAKS
save "$OUT_DATA/Mediation_Plot_Data.dta", replace

* -------------------------------------------------------------------------
* TO REPLOT LATER WITHOUT RERUNNING THE LOOP:
* use "$OUT_DATA/Mediation_Plot_Data.dta", clear
* (Then run the twoway block below)
* -------------------------------------------------------------------------

* Generate the comparative caterpillar plot (Figure 1)
twoway (rcap ci_hi_base ci_lo_base id_base, horizontal lcolor(gs10)) ///
       (scatter id_base coef_base, mcolor(maroon) msymbol(D) msize(small)) ///
       (rcap ci_hi_full ci_lo_full id_full, horizontal lcolor(gs10)) ///
       (scatter id_full coef_full, mcolor(navy) msymbol(O) msize(small)), ///
       xline(0, lcolor(black) lpattern(solid)) ///
       ylabel(`y_labels', angle(horizontal) labsize(vsmall) grid) ///
       ytitle("") ///
       xtitle("Average Marginal Effect of Being Male (Percentage Points)", size(small)) ///
       legend(order(2 "M1: Raw Gender Gap" 4 "M3: Full Model") rows(2) size(small) region(lcolor(white))) ///
       graphregion(color(white)) plotregion(color(white)) bgcolor(white) ///
       name(country_mediation_plot, replace)

graph export "$OUT_FIG/Gender_Gap_Mediation_Full_Caterpillar.png", replace width(2400)

restore

********************************************************************************
* INTERACTION MODELS: Moderation by Gender (Table 2)
********************************************************************************

* -------------------------------------------------------------------------
* Model 4: Gender x Preference for male political leadership
* -------------------------------------------------------------------------
melogit rr_vote i.male##c.male_pol_lead ///
    c.trad_bwnorm c.gay_father c.econ_diff ///
    c.age##c.age i.educ_3cat i.oesch8_class i.urban c.relig_attend i.in_work ///
    if estimation_sample == 1 || country:, vce(robust)

estimates store m4_int_pol_lead

* Calculate predictive margins, post them, and save to disk (feeds Figure 2)
margins male, at(male_pol_lead=(1(1)5)) post
estimates save "$OUT_EST/margins_m4_pol_lead.ster", replace

* TO REPLOT LATER: use "$OUT_DATA/Analysis_data.dta", clear | estimates use "$OUT_EST/margins_m4_pol_lead.ster"
marginsplot, recast(line) recastci(rarea) ///
    plot1opts(lcolor(gs8) mcolor(gs8) msymbol(Oh) lpattern(dash) lwidth(medthick)) ///
    plot2opts(lcolor(navy) mcolor(navy) msymbol(D) lpattern(solid) lwidth(medthick)) ///
    ci1opts(fcolor(gs12%30) lwidth(none)) ///
    ci2opts(fcolor(navy%30) lwidth(none)) ///
    ytitle("Predicted Pr(PRR Vote)") ///
    xtitle("Preference for Male Political Leadership (1=Women, 5=Men)", size(small)) ///
    ylabel(, angle(horizontal) labsize(small) grid) ///
    legend(order(3 "Women" 4 "Men") ///
           region(lcolor(white)) position(6) rows(1)) ///
    graphregion(color(white)) plotregion(color(white)) bgcolor(white) ///
    name(int_gender_pol_lead_plot, replace)

graph export "$OUT_FIG/Interaction_Gender_Male_Pol_Lead.png", replace width(2400)


* -------------------------------------------------------------------------
* Model 5: Gender x Traditional Breadwinner Norm
* -------------------------------------------------------------------------
* Predictive-margins plot for this model is not reproduced here: it is not
* referenced as a Figure anywhere in the paper. The log-odds estimates below
* (stored as m5_int_bwnorm) are what feeds Table 2.
melogit rr_vote i.male##c.trad_bwnorm ///
    c.male_pol_lead c.gay_father c.econ_diff ///
    c.age##c.age i.educ_3cat i.oesch8_class i.urban c.relig_attend i.in_work ///
    if estimation_sample == 1 || country:, vce(robust)

estimates store m5_int_bwnorm


* -------------------------------------------------------------------------
* Model 6: Gender x Normative Policing
* -------------------------------------------------------------------------
* Predictive-margins plot for this model is not reproduced here: it is not
* referenced as a Figure anywhere in the paper. The log-odds estimates below
* (stored as m6_int_policing) are what feeds Table 2.
melogit rr_vote i.male##c.gay_father ///
    c.male_pol_lead c.trad_bwnorm c.econ_diff ///
    c.age##c.age i.educ_3cat i.oesch8_class i.urban c.relig_attend i.in_work ///
    if estimation_sample == 1 || country:, vce(robust)

estimates store m6_int_policing

********************************************************************************
* TABLE 2: Symmetric Interactions
********************************************************************************

esttab m4_int_pol_lead m5_int_bwnorm m6_int_policing, ///
    cells(b(star fmt(3)) se(par fmt(3))) ///
    starlevels(* 0.05 ** 0.01 *** 0.001) ///
    stats(N N_g ll, labels("Observations" "Number of Countries" "Log Likelihood") fmt(0 0 2)) ///
    label replace nobaselevels ///
    varlabels(1.male "Male" ///
              male_pol_lead "Pref. Male Pol. Leadership" ///
              trad_bwnorm "Breadwinner Norm" ///
              gay_father "Rejects Gay Fathers" ///
              econ_diff "Economic Precarity (Control)" ///
              1.male#c.male_pol_lead "Gender x Pref. Male Pol. Lead" ///
              1.male#c.trad_bwnorm "Gender x Breadwinner" ///
              1.male#c.gay_father "Gender x Policing") ///
    title("Table 2. Symmetric Moderation: Does the impact of patriarchal dimensions vary by Gender?") ///
    addnotes("Note: Coefficients are Log-Odds. Standard errors in parentheses. * p<0.05, ** p<0.01, *** p<0.001.")


********************************************************************************
* The Specificity of the Political Sphere (Appendix Table A6)
********************************************************************************

melogit rr_vote i.male##c.male_pol_lead ///
    c.trad_bwnorm c.gay_father c.econ_diff ///
    c.age##c.age i.educ_3cat i.oesch8_class i.urban c.relig_attend i.in_work ///
    if estimation_sample == 1 || country:, vce(robust)
estimates store m_int_pol

melogit rr_vote i.male##c.male_econ_lead ///
    c.trad_bwnorm c.gay_father c.econ_diff ///
    c.age##c.age i.educ_3cat i.oesch8_class i.urban c.relig_attend i.in_work ///
    if estimation_sample == 1 || country:, vce(robust)
estimates store m_int_econ

melogit rr_vote i.male##c.male_acad_lead ///
    c.trad_bwnorm c.gay_father c.econ_diff ///
    c.age##c.age i.educ_3cat i.oesch8_class i.urban c.relig_attend i.in_work ///
    if estimation_sample == 1 || country:, vce(robust)
estimates store m_int_acad

esttab m_int_pol m_int_econ m_int_acad, ///
    cells(b(star fmt(3)) se(par fmt(3))) ///
    starlevels(* 0.05 ** 0.01 *** 0.001) ///
    stats(N N_g ll, labels("Observations" "Number of Countries" "Log Likelihood") fmt(0 0 2)) ///
    label replace nobaselevels ///
    mtitles("Political (State)" "Economic (Market)" "Academic (Univ.)") ///
    varlabels(1.male "Male" ///
              male_pol_lead "Pref. Male Pol. Leadership" ///
              male_econ_lead "Economic Executive Demand" ///
              male_acad_lead "Academic Leader Demand" ///
              1.male#c.male_pol_lead "Gender x Political Lead" ///
              1.male#c.male_econ_lead "Gender x Economic Lead" ///
              1.male#c.male_acad_lead "Gender x Academic Lead" ///
              trad_bwnorm "Breadwinner Norm" ///
              gay_father "Rejects Gay Fathers" ///
              econ_diff "Economic Precarity (Control)") ///
    title("Appendix Table A6. The Specificity of Political Authority: Comparing Spheres") ///
    addnotes("Note: Coefficients are Log-Odds. Standard errors in parentheses. * p<0.05, ** p<0.01, *** p<0.001.")

********************************************************************************
* FIGURE 3: Country Heterogeneity: Preference for Male Political Leadership Interaction
********************************************************************************

preserve

drop if missing(rr_vote, male, male_pol_lead, c_alphan)
capture drop prr_available
bysort c_alphan: egen prr_available = max(rr_vote)
keep if prr_available == 1

tempname memhold
tempfile results
postfile `memhold' str2 c_alphan ame_w lo_w hi_w ame_m lo_m hi_m using `results'

levelsof c_alphan, local(countries)
foreach c of local countries {

    capture noisily logit rr_vote i.male##c.male_pol_lead if c_alphan == "`c'", vce(robust)

    if _rc == 0 {
        capture noisily margins, dydx(male_pol_lead) over(male) post
        if _rc == 0 {
            local b_w = _b[0.male]
            local se_w = _se[0.male]
            local lo_w = `b_w' - 1.96*`se_w'
            local hi_w = `b_w' + 1.96*`se_w'

            local b_m = _b[1.male]
            local se_m = _se[1.male]
            local lo_m = `b_m' - 1.96*`se_m'
            local hi_m = `b_m' + 1.96*`se_m'
        }
        else {
            local b_w = .
            local lo_w = .
            local hi_w = .
            local b_m = .
            local lo_m = .
            local hi_m = .
        }
        post `memhold' ("`c'") (`b_w') (`lo_w') (`hi_w') (`b_m') (`lo_m') (`hi_m')
    }
}
postclose `memhold'

use `results', clear

drop if missing(ame_w)

sort ame_m
generate id = _n

generate id_w = id - 0.15
generate id_m = id + 0.15

levelsof id, local(ids)
foreach i of local ids {
    local cname = c_alphan[`i']
    label define id_lbl `i' "`cname'", add
}
label values id id_lbl

local y_labels ""
local N = _N
forvalues i = 1/`N' {
    local cname = c_alphan[`i']
    local y_labels `"`y_labels' `i' "`cname'""'
}

* SAVE THE DATASET TO AVOID RERUNNING THE LOOP FOR PLOT TWEAKS
save "$OUT_DATA/Pol_Lead_Heterogeneity_Data.dta", replace

* -------------------------------------------------------------------------
* TO REPLOT LATER WITHOUT RERUNNING THE LOOP:
* use "$OUT_DATA/Pol_Lead_Heterogeneity_Data.dta", clear
* (Then run the twoway block below)
* -------------------------------------------------------------------------

twoway (rcap hi_w lo_w id_w, horizontal lcolor(gs12)) ///
       (scatter id_w ame_w, mcolor(gs8) msymbol(Oh) msize(small)) ///
       (rcap hi_m lo_m id_m, horizontal lcolor(navy%50)) ///
       (scatter id_m ame_m, mcolor(navy) msymbol(D) msize(small)), ///
       xline(0, lcolor(black) lpattern(solid)) ///
       ylabel(`y_labels', angle(horizontal) labsize(vsmall) grid) ///
       ytitle("") ///
       xtitle("Marginal Effect of Pref. for Male Pol. Leadership on PRR Voting (Prob. Points)", size(small)) ///
       legend(order(2 "Effect for Women" 4 "Effect for Men") ///
              region(lcolor(white)) position(6) rows(1) size(small)) ///
       graphregion(color(white)) plotregion(color(white)) bgcolor(white) ///
       name(pol_lead_split_ame, replace)

graph export "$OUT_FIG/Male_Pol_Lead_Heterogeneity_Split_AME.png", replace width(2400)

restore

********************************************************************************
* TABLES 3-4 SOURCE MODELS: Triple Interactions (Gender x Attitude x Oesch Class)
********************************************************************************
* Table 3 (log-odds) is read directly off each melogit's own estimation
* output below. Table 4 (average marginal effects by gender and Oesch class)
* is read directly off each subsequent "margins male, dydx(...) over(oesch8_class)"
* output below. Both are captured verbatim in this do-file's run log. The
* margins results are also saved as standalone .ster files in Output/Estimates
* for direct reuse without re-running the models. No marginsplot/graph export
* is produced for these three models: the triple-interaction class plots from
* earlier drafts are not referenced as Figures in the paper or Online Appendix.

* -------------------------------------------------------------------------
* Model 7: Preference for Male Political Leadership (Triple Interaction)
* -------------------------------------------------------------------------
melogit rr_vote i.male##c.male_pol_lead##i.oesch8_class ///
    c.trad_bwnorm c.gay_father c.econ_diff ///
    c.age##c.age i.educ_3cat i.urban c.relig_attend i.in_work ///
    if estimation_sample == 1 || country:, vce(robust)

estimates store m_triple_pol_lead

* Table 4 (Male Political Leadership columns): AME by gender x Oesch class
margins male, dydx(male_pol_lead) over(oesch8_class) post
estimates save "$OUT_EST/margins_triple_pol_lead.ster", replace

* -------------------------------------------------------------------------
* Model 8: Breadwinner Norms (Triple Interaction)
* -------------------------------------------------------------------------
melogit rr_vote i.male##c.trad_bwnorm##i.oesch8_class ///
    c.gay_father c.econ_diff c.male_pol_lead ///
    c.age##c.age i.educ_3cat i.urban c.relig_attend i.in_work ///
    if estimation_sample == 1 || country:, vce(robust)

estimates store m_triple_bwnorm

* Table 4 (Breadwinner Norm columns): AME by gender x Oesch class
margins male, dydx(trad_bwnorm) over(oesch8_class) post
estimates save "$OUT_EST/margins_triple_bwnorm.ster", replace

* -------------------------------------------------------------------------
* Model 9: Anti-Gay Father Attitudes (Triple Interaction)
* -------------------------------------------------------------------------
melogit rr_vote i.male##c.gay_father##i.oesch8_class ///
    c.trad_bwnorm c.male_pol_lead c.econ_diff ///
    c.age##c.age i.educ_3cat i.urban c.relig_attend i.in_work ///
    if estimation_sample == 1 || country:, vce(robust)

estimates store m_triple_gayfather

* Table 4 (Same-Sex Fathers columns): AME by gender x Oesch class
margins male, dydx(gay_father) over(oesch8_class) post
estimates save "$OUT_EST/margins_triple_gayfather.ster", replace

log close
