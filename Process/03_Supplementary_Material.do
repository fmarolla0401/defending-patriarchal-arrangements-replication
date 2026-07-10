********************************************************************************
* Project: Defending Patriarchal Arrangements: Explaining Men's disproportionate support for Populist Radical Right in Europe
* This do-file: 03_Supplementary_Material
********************************************************************************
clear all
set more off

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

* Load the dataset produced by 01_Data_Preparation.do
use "$OUT_DATA/Analysis_data.dta", clear

********************************************************************************
* Logging
********************************************************************************
cap log close _all
local stamp = subinstr("`c(current_date)'"," ","_",.)
log using "$OUT_LOG/03_Supplementary_Material_`stamp'.log", replace text

* NOTE ON STRUCTURE: This do-file reproduces, in order, every table of the
* Online Appendix (Tables A1-A16; see Partiarchal_Arrangements_PRR_Online_
* Appendix.md). Table A6 (domain-specificity comparison) is estimated here
* even though the identical models also appear in 02_Data_Analysis.do,
* so that this single do-file can reproduce the full appendix on its own.
* Table A1 is not reproduced as Stata output (see the note at that section
* below). The Online Appendix contains no figures, so the class-heterogeneity
* marginsplots present in earlier drafts of this do-file (for the breadwinner-
* norm and same-sex-fathers triple interactions) have been removed; the
* underlying models (lpm_m5, lpm_m6, lpm_m7) are retained because they still
* supply Tables A8-A10.

* GEOGRAPHIC RESTRICTION: Keep only European countries
keep if inlist(country, 40, 100, 191, 203, 208, 246, 250, 276, 300, 348, ///
                        352, 380, 440, 528, 578, 616, 703, 705, 724, 752, 756)

* Create the strict estimation sample flag
capture drop estimation_sample
gen estimation_sample = 1

replace estimation_sample = 0 if missing(rr_vote, male, age, educ_3cat, oesch8_class, urban)
replace estimation_sample = 0 if missing(relig_attend, in_work, econ_diff)
replace estimation_sample = 0 if missing(male_pol_lead, trad_bwnorm, gay_father, country)

* Keep only countries where a PRR party is actually available
capture drop prr_available
bysort country: egen prr_available = max(rr_vote)
replace estimation_sample = 0 if prr_available != 1


********************************************************************************
* TABLE A1. Populist Radical Right Parties Coded in this Study
********************************************************************************
* NOT reproduced here. Table A1 lists, by country, the specific party names
* classified as "Far Right" under PopuList 3.0 (e.g., Austria - FPOe, Germany -
* AfD). Party NAMES are not stored as string variables in Analysis_data.dta --
* only the numeric *_PRTY codes used to construct rr_vote are. The
* authoritative source for this table is the country-by-country coding block
* in 01_Data_Preparation.do (search "DEPENDENT VARIABLE PREPARATION"). Table
* A1 is a hand-maintained reference table, not a Stata output.


* -------------------------------------------------------------------------
* TABLE A2. Descriptive Statistics of the Analytical Sample
* -------------------------------------------------------------------------
preserve

levelsof educ_3cat if estimation_sample == 1, local(ed_levels)
foreach l of local ed_levels {
    local lbl : label (educ_3cat) `l'
    quietly gen educ_dummy_`l' = (educ_3cat == `l') if !missing(educ_3cat)
    label variable educ_dummy_`l' "Education: `lbl'"
}

levelsof oesch8_class if estimation_sample == 1, local(oesch_levels)
foreach l of local oesch_levels {
    local lbl : label (oesch8_class) `l'
    quietly gen oesch_dummy_`l' = (oesch8_class == `l') if !missing(oesch8_class)
    label variable oesch_dummy_`l' "Class: `lbl'"
}

estpost summarize rr_vote male male_pol_lead trad_bwnorm gay_father ///
    econ_diff age urban relig_attend in_work ///
    educ_dummy_* oesch_dummy_* ///
    if estimation_sample == 1, detail

esttab ., ///
    cells("count(fmt(0) label(N)) mean(fmt(3)) sd(fmt(3)) min(fmt(0)) max(fmt(0))") ///
    nomtitle nonumber noobs label ///
    title("Table A2. Descriptive Statistics of the Analytical Sample")

restore


* -------------------------------------------------------------------------
* TABLE A3. Bivariate Correlation Matrix of Key Independent Variables
* -------------------------------------------------------------------------
estpost correlate male_pol_lead trad_bwnorm gay_father econ_diff ///
    if estimation_sample == 1, matrix listwise

esttab ., ///
    unstack not noobs nomtitle nonumber compress ///
    title("Table A3. Bivariate Correlation Matrix of Key Independent Variables")


* -------------------------------------------------------------------------
* TABLE A4. Variance Inflation Factors (VIF)
* -------------------------------------------------------------------------
* Run using standard OLS, as VIF is a property of the X-matrix only
regress rr_vote i.male c.male_pol_lead c.trad_bwnorm c.gay_father c.econ_diff ///
    c.age i.educ_3cat i.oesch8_class i.urban c.relig_attend i.in_work ///
    if estimation_sample == 1

display ""
display "*****************************************************"
display "--- TABLE A4. VARIANCE INFLATION FACTORS (VIF) ---"
display "*****************************************************"
estat vif
display "Note: All VIF values below the conventional threshold of 10 -- no problematic multicollinearity."
display "*****************************************************"


* -------------------------------------------------------------------------
* TABLE A5. Null Model and Intraclass Correlation Coefficient
* -------------------------------------------------------------------------
display ""
display "*****************************************************"
display "--- TABLE A5. NULL MODEL AND INTRACLASS CORRELATION COEFFICIENT (ICC) ---"
display "*****************************************************"
melogit rr_vote if estimation_sample == 1 || country:
estat icc
display "Note: Empty two-level random-intercept logistic model."
display "*****************************************************"


* -------------------------------------------------------------------------
* TABLE A6. Comparing Interaction Effects across Domains of Male Leadership
* -------------------------------------------------------------------------
* Tests whether the gendered radicalization effect is specific to demand for
* male POLITICAL authority (the state) or generalizes to male authority in
* the economic (market) and academic (university) spheres. (Identical model
* specification to the "Specificity of the Political Sphere" section of
* 02_Data_Analysis.do -- re-estimated here for single-source
* reproducibility of the appendix.)

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
    label nobaselevels ///
    mtitles("Political (State)" "Economic (Market)" "Academic (Univ.)") ///
    varlabels(1.male "Male" ///
              male_pol_lead "Pref. Male Pol. Leadership" ///
              male_econ_lead "Pref. Male Econ. Leadership" ///
              male_acad_lead "Pref. Male Academ. Leadership" ///
              1.male#c.male_pol_lead "Male x Pref. Male Pol. Leadership" ///
              1.male#c.male_econ_lead "Male x Male Econ. Leadership" ///
              1.male#c.male_acad_lead "Male x Male Academ. Leadership" ///
              trad_bwnorm "Breadwinner Norm" ///
              gay_father "Rejects Same-Sex Fathers" ///
              econ_diff "Economic Precarity") ///
    title("Table A6. Comparing Interaction Effects across Domains of Male Leadership") ///
    addnotes("Note: Multilevel logistic regression models (log-odds). Coefficients are log-odds from two-level random-intercept logistic models with robust standard errors. * p<0.05, ** p<0.01, *** p<0.001.")


********************************************************************************
* TABLE A7. Multilevel Linear Probability Models
* TABLES A8-A10. Multilevel LPM Triple Interactions by Oesch Class
********************************************************************************
estimates clear

* Model 1: Raw Gender Gap
mixed rr_vote i.male ///
    if estimation_sample == 1 || country:, vce(robust)
estimates store lpm_m1

* Model 2: Structural Controls
mixed rr_vote i.male ///
    c.age##c.age i.educ_3cat i.oesch8_class i.urban c.relig_attend i.in_work c.econ_diff ///
    if estimation_sample == 1 || country:, vce(robust)
estimates store lpm_m2

* Model 3: Full Patriarchal Model
mixed rr_vote i.male ///
    c.age##c.age i.educ_3cat i.oesch8_class i.urban c.relig_attend i.in_work c.econ_diff ///
    c.gay_father c.trad_bwnorm c.male_pol_lead ///
    if estimation_sample == 1 || country:, vce(robust)
estimates store lpm_m3

* Model 4: Strongman Interaction
mixed rr_vote i.male##c.male_pol_lead ///
    c.trad_bwnorm c.gay_father c.econ_diff ///
    c.age##c.age i.educ_3cat i.oesch8_class i.urban c.relig_attend i.in_work ///
    if estimation_sample == 1 || country:, vce(robust)
estimates store lpm_m4

* -------------------------------------------------------------------------
* TABLE A7. Multilevel Linear Probability Models
* -------------------------------------------------------------------------
esttab lpm_m1 lpm_m2 lpm_m3 lpm_m4, ///
    cells(b(star fmt(3)) se(par fmt(3))) ///
    starlevels(* 0.05 ** 0.01 *** 0.001) ///
    stats(N N_g, labels("Observations" "Countries") fmt(0 0)) ///
    label nobaselevels ///
    mtitles("Model 1" "Model 2" "Model 3" "Model 4") ///
    varlabels(1.male "Male" ///
              1.male#c.male_pol_lead "Male x Male Leadership" ///
              male_pol_lead "Preference for Male Leadership" ///
              trad_bwnorm "Breadwinner Norm" ///
              gay_father "Rejects Same-Sex Fathers" ///
              econ_diff "Economic Precarity") ///
    title("Table A7. Multilevel Linear Probability Models") ///
    addnotes("Note: Coefficients represent linear changes in probability of voting for a PRR party. Multilevel linear probability models with random intercepts for country and robust standard errors. * p<0.05, ** p<0.01, *** p<0.001.")

* Model 5: Triple Interaction (Gender x Strongman x Oesch Class)
mixed rr_vote i.male##c.male_pol_lead##i.oesch8_class ///
    c.trad_bwnorm c.gay_father c.econ_diff ///
    c.age##c.age i.educ_3cat i.urban c.relig_attend i.in_work ///
    if estimation_sample == 1 || country:, vce(robust)
estimates store lpm_m5

* Model 6: Triple Interaction (Gender x Breadwinner Norms x Oesch Class)
mixed rr_vote i.male##c.trad_bwnorm##i.oesch8_class ///
    c.gay_father c.econ_diff c.male_pol_lead ///
    c.age##c.age i.educ_3cat i.urban c.relig_attend i.in_work ///
    if estimation_sample == 1 || country:, vce(robust)
estimates store lpm_m6

* Model 7: Triple Interaction (Gender x Anti-Gay Father x Oesch Class)
mixed rr_vote i.male##c.gay_father##i.oesch8_class ///
    c.trad_bwnorm c.male_pol_lead c.econ_diff ///
    c.age##c.age i.educ_3cat i.urban c.relig_attend i.in_work ///
    if estimation_sample == 1 || country:, vce(robust)
estimates store lpm_m7

********************************************************************************
* TABLES A8-A10: Triple Interactions (One Standalone Table per Dimension)
* Note: full model output shown (all controls included), unlike the trimmed
* row-subset used for the Word appendix -- retained here for completeness
* and single-source verifiability; trim rows when building the final table.
********************************************************************************

esttab lpm_m5, ///
    cells(b(star fmt(3)) se(par fmt(3))) ///
    starlevels(* 0.05 ** 0.01 *** 0.001) ///
    stats(N, labels("Observations") fmt(0)) ///
    label nobaselevels ///
    title("Table A8. Multilevel LPM Triple Interaction: Gender x Male Political Leadership x Oesch Class") ///
    addnotes("Note: Multilevel LPM with random intercepts for country and robust standard errors. * p<0.05, ** p<0.01, *** p<0.001.")

esttab lpm_m6, ///
    cells(b(star fmt(3)) se(par fmt(3))) ///
    starlevels(* 0.05 ** 0.01 *** 0.001) ///
    stats(N, labels("Observations") fmt(0)) ///
    label nobaselevels ///
    title("Table A9. Multilevel LPM Triple Interaction: Gender x Breadwinner Norm x Oesch Class") ///
    addnotes("Note: Multilevel LPM with random intercepts for country and robust standard errors. * p<0.05, ** p<0.01, *** p<0.001.")

esttab lpm_m7, ///
    cells(b(star fmt(3)) se(par fmt(3))) ///
    starlevels(* 0.05 ** 0.01 *** 0.001) ///
    stats(N, labels("Observations") fmt(0)) ///
    label nobaselevels ///
    title("Table A10. Multilevel LPM Triple Interaction: Gender x Rejects Same-Sex Fathers x Oesch Class") ///
    addnotes("Note: Multilevel LPM with random intercepts for country and robust standard errors. * p<0.05, ** p<0.01, *** p<0.001.")


********************************************************************************
* TABLE A11. Analytic Sample vs. Excluded Non-Voters (Balance Check)
* TABLE A12. Categorical Variables by Group (Column % and chi2)
* TABLE A13. Predictors of Non-Voter Exclusion (Joint Selection Model)
********************************************************************************
* Rationale: rr_vote models PRR support conditional on voting, following
* standard practice of separating the turnout decision from the party-choice
* decision. This section checks whether respondents excluded for having no
* valid vote-choice response (non-voters / vote-item non-response) differ
* systematically from the final analytic sample on the paper's core variables.
* Iceland is not part of this comparison: it has no PRR party coded at all
* (a structural scope decision, not a non-response issue).

capture drop nonvoter_group
gen nonvoter_group = .
replace nonvoter_group = 0 if estimation_sample == 1
replace nonvoter_group = 1 if missing(rr_vote) & prr_available == 1

label define nvg_lbl 0 "Included (Analytic Sample)" 1 "Excluded (Non-Voter / Missing Vote Item)"
label values nonvoter_group nvg_lbl

* -------------------------------------------------------------------------
* TABLE A11: Balance Table (Included vs. Excluded Non-Voters)
* -------------------------------------------------------------------------
estpost ttest male age relig_attend in_work econ_diff male_pol_lead trad_bwnorm gay_father ///
    if !missing(nonvoter_group), by(nonvoter_group) unequal

esttab ., ///
    cells("mu_1(fmt(3) label(Included)) mu_2(fmt(3) label(Excluded)) b(fmt(3) label(Diff)) se(fmt(3) label(SE)) t(fmt(2) label(t)) p(fmt(3) label(p-value))") ///
    noobs label ///
    title("Table A11. Analytic Sample vs. Excluded Non-Voters") ///
    addnotes("Note: Welch (unequal-variance) t-tests. Excluded = missing rr_vote in countries with a PRR party option.")

* -------------------------------------------------------------------------
* TABLE A12: Categorical Variables by Group (chi2)
* -------------------------------------------------------------------------
display ""
display "*****************************************************"
display "--- TABLE A12. CATEGORICAL VARIABLES BY GROUP (COLUMN % AND CHI2) ---"
display "*****************************************************"
tab educ_3cat nonvoter_group if !missing(nonvoter_group), col chi2
tab urban nonvoter_group if !missing(nonvoter_group), col chi2
tab oesch8_class nonvoter_group if !missing(nonvoter_group), col chi2
display "*****************************************************"

* -------------------------------------------------------------------------
* TABLE A13: Joint Selection Model (What Independently Predicts Exclusion?)
* -------------------------------------------------------------------------
logit nonvoter_group i.male c.age##c.age i.educ_3cat i.urban c.relig_attend i.in_work ///
    c.econ_diff i.oesch8_class c.male_pol_lead c.trad_bwnorm c.gay_father i.country ///
    if !missing(nonvoter_group), vce(robust)

estimates store selection_model

esttab selection_model, ///
    cells(b(star fmt(3)) se(par fmt(3))) ///
    starlevels(* 0.05 ** 0.01 *** 0.001) ///
    stats(N, labels("Observations") fmt(0)) ///
    label nobaselevels ///
    keep(*male* age *educ_3cat* *econ_diff* *male_pol_lead* *trad_bwnorm* *gay_father*) ///
    title("Table A13. Predictors of Non-Voter Exclusion") ///
    addnotes("Note: Logit predicting exclusion (1=excluded non-voter, 0=included). Country fixed effects included but omitted for readability. Coefficients are Log-Odds. Robust SEs in parentheses. * p<0.05, ** p<0.01, *** p<0.001.")


********************************************************************************
* TABLE A14. Analytic Sample vs. Excluded (Voted but Missing Core Attitudes)
* TABLE A15. Categorical Variables by Group (Column % and chi2)
* TABLE A16. Predictors of Core-Attitude Item Non-Response
********************************************************************************
* This group DID vote (rr_vote observed), but is missing on >=1 of the three
* core independent variables (male_pol_lead, trad_bwnorm, gay_father). Because
* their vote choice is known, we can test directly whether item non-response
* on the attitude battery is related to actual PRR support.

capture drop coreiv_missing
gen coreiv_missing = missing(male_pol_lead) | missing(trad_bwnorm) | missing(gay_father)

capture drop coreiv_group
gen coreiv_group = .
replace coreiv_group = 0 if estimation_sample == 1
replace coreiv_group = 1 if !missing(rr_vote) & prr_available == 1 & coreiv_missing == 1

label define civg_lbl 0 "Included (Analytic Sample)" 1 "Excluded (Missing Core IV, but Voted)"
label values coreiv_group civg_lbl

tab coreiv_group, missing

* -------------------------------------------------------------------------
* TABLE A14. PRR Vote Share by Core-IV Missingness (Direct Test) +
*            Balance Table on Demographics
* -------------------------------------------------------------------------
display ""
display "*****************************************************"
display "--- TABLE A14 (direct test): PRR Vote Share - Core-IV-Complete vs. Core-IV-Missing (among valid voters) ---"
display "*****************************************************"
ttest rr_vote if !missing(rr_vote) & prr_available == 1, by(coreiv_missing) unequal

estpost ttest male age relig_attend in_work econ_diff ///
    if !missing(coreiv_group), by(coreiv_group) unequal

esttab ., ///
    cells("mu_1(fmt(3) label(Included)) mu_2(fmt(3) label(Excluded)) b(fmt(3) label(Diff)) se(fmt(3) label(SE)) t(fmt(2) label(t)) p(fmt(3) label(p-value))") ///
    noobs label ///
    title("Table A14. Analytic Sample vs. Excluded (Voted but Missing Core Attitudes)") ///
    addnotes("Note: Welch (unequal-variance) t-tests. Excluded = voted (rr_vote observed) but missing on >=1 of male_pol_lead/trad_bwnorm/gay_father.")

* -------------------------------------------------------------------------
* TABLE A15. Categorical Variables by Group (chi2)
* -------------------------------------------------------------------------
display ""
display "*****************************************************"
display "--- TABLE A15. CATEGORICAL VARIABLES BY GROUP (COLUMN % AND CHI2) ---"
display "*****************************************************"
tab educ_3cat coreiv_group if !missing(coreiv_group), col chi2
tab oesch8_class coreiv_group if !missing(coreiv_group), col chi2
display "*****************************************************"

* -------------------------------------------------------------------------
* TABLE A16. Joint Selection Model (What Independently Predicts Core-IV
*            Item Non-Response, Including Actual Vote Choice?)
* -------------------------------------------------------------------------
logit coreiv_group i.male c.age##c.age i.educ_3cat i.urban c.relig_attend i.in_work ///
    c.econ_diff i.oesch8_class i.rr_vote i.country ///
    if !missing(coreiv_group), vce(robust)

estimates store coreiv_selection_model

esttab coreiv_selection_model, ///
    cells(b(star fmt(3)) se(par fmt(3))) ///
    starlevels(* 0.05 ** 0.01 *** 0.001) ///
    stats(N, labels("Observations") fmt(0)) ///
    label nobaselevels ///
    keep(*male* age *educ_3cat* *econ_diff* *rr_vote*) ///
    title("Table A16. Predictors of Core-IV Item Non-Response") ///
    addnotes("Note: Logit predicting exclusion (1=voted but missing core IV, 0=included). Country fixed effects included but omitted for readability. Coefficients are Log-Odds. Robust SEs in parentheses. * p<0.05, ** p<0.01, *** p<0.001.")

log close
