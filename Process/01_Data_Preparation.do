********************************************************************************
* Project: Defending Patriarchal Arrangements: Explaining Men's disproportionate support for Populist Radical Right in Europe
* This do-file: 01_Data_Preparation
********************************************************************************
* REPLICATION PACKAGE NOTE: This do-file reproduces every variable used in the
* paper and Online Appendix from the raw ISSP 2022 "Family and Changing Gender
* Roles V" module (GESIS archive ZA10000, v2.0.0). It does not reproduce the
* raw-PRR-vote-by-country caterpillar plot from earlier drafts, which is not
* referenced anywhere in the paper or Online Appendix.

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

global INPUT   "$ROOT/Input"
global OUTPUT  "$ROOT/Output"
global OUT_DATA "$OUTPUT/Data"
global OUT_LOG  "$OUTPUT/Logs"

********************************************************************************
* Logging
********************************************************************************
cap log close _all
local stamp = subinstr("`c(current_date)'"," ","_",.)
log using "$OUT_LOG/01_Data_Preparation_`stamp'.log", replace text

* Load the raw dataset (see Input/README.txt for how to obtain this file --
* it is not redistributed in this package due to GESIS/ISSP data-use terms)
use "$INPUT/ZA10000_v2-0-0.dta", clear

********************************************************************************
* GEOGRAPHIC RESTRICTION: Keep only European countries
********************************************************************************
* This drops non-European democracies and electoral autocracies to ensure
* theoretical consistency regarding the PRR and post-industrial labor markets.
* Note: this list includes Iceland (352), which is dropped later from the
* analytic sample because no PRR party is coded there (see Appendix Table A11).
keep if inlist(country, 40, 100, 191, 203, 208, 246, 250, 276, 300, 348, ///
                        352, 380, 440, 528, 578, 616, 703, 705, 724, 752, 756)

* =========================================================================
* DEPENDENT VARIABLE PREPARATION: Populist Radical Right (PRR) Vote
* =========================================================================
* Coding rule: Only parties explicitly categorized as "Far Right" (1 or 1*)
* in the PopuList 3.0 database are coded as 1. All other valid votes are 0.
* Full party-by-country listing: Online Appendix Table A1.

gen rr_vote = .
label variable rr_vote "Voted for a Populist Radical Right Party"

* Austria (AT_PRTY) - PopuList Far Right: FPÖ
replace rr_vote = 0 if inrange(AT_PRTY, 1, 95)
replace rr_vote = 1 if AT_PRTY == 3

* Bulgaria (BG_PRTY) - PopuList Far Right: Revival (Vazrazhdane)
replace rr_vote = 0 if inrange(BG_PRTY, 1, 95)
replace rr_vote = 1 if BG_PRTY == 8

* Switzerland (CH_PRTY) - PopuList Far Right: SVP, EDU, Lega
replace rr_vote = 0 if inrange(CH_PRTY, 1, 95)
replace rr_vote = 1 if inlist(CH_PRTY, 1, 9, 10)

* Czech Republic (CZ_PRTY) - PopuList Far Right: SPD
replace rr_vote = 0 if inrange(CZ_PRTY, 1, 95)
replace rr_vote = 1 if CZ_PRTY == 4

* Germany (DE_PRTY) - PopuList Far Right: AfD
replace rr_vote = 0 if inrange(DE_PRTY, 1, 95)
replace rr_vote = 1 if DE_PRTY == 3

* Denmark (DK_PRTY) - PopuList Far Right: DF, NB (Nye Borgerlige)
replace rr_vote = 0 if inrange(DK_PRTY, 1, 95)
replace rr_vote = 1 if inlist(DK_PRTY, 4, 9)

* Spain (ES_PRTY) - PopuList Far Right: VOX
replace rr_vote = 0 if inrange(ES_PRTY, 1, 95)
replace rr_vote = 1 if ES_PRTY == 3

* Finland (FI_PRTY) - PopuList Far Right: PS (Finns Party)
replace rr_vote = 0 if inrange(FI_PRTY, 1, 95)
replace rr_vote = 1 if FI_PRTY == 2

* France (FR_PRTY) - PopuList Far Right: RN, Reconquête, DLR (Debout la République)
replace rr_vote = 0 if inrange(FR_PRTY, 1, 95)
replace rr_vote = 1 if inlist(FR_PRTY, 10, 11, 12)

* Greece (GR_PRTY) - PopuList Far Right: EL (Greek Solution)
* (Note: NIKI is not classified in PopuList)
replace rr_vote = 0 if inrange(GR_PRTY, 1, 95)
replace rr_vote = 1 if GR_PRTY == 5

* Croatia (HR_PRTY) - PopuList Far Right: DP, MOST/Sovereigntists
replace rr_vote = 0 if inrange(HR_PRTY, 1, 95)
replace rr_vote = 1 if inlist(HR_PRTY, 4, 5)

* Hungary (HU_PRTY) - PopuList Far Right: Fidesz-KDNP, MHM (Our Homeland)
replace rr_vote = 0 if inrange(HU_PRTY, 1, 95)
replace rr_vote = 1 if inlist(HU_PRTY, 1, 3)

* Italy (IT_PRTY) - PopuList Far Right: FdI, Lega
replace rr_vote = 0 if inrange(IT_PRTY, 1, 95)
replace rr_vote = 1 if inlist(IT_PRTY, 1, 2)

* Lithuania (LT_PRTY) - PopuList Far Right: NS (National Alliance)
replace rr_vote = 0 if inrange(LT_PRTY, 1, 95)
replace rr_vote = 1 if LT_PRTY == 7

* Netherlands (NL_PRTY) - PopuList Far Right: PVV, BBB, FvD, JA21
replace rr_vote = 0 if inrange(NL_PRTY, 1, 95)
replace rr_vote = 1 if inlist(NL_PRTY, 1, 6, 11, 15)

* Norway (NO_PRTY) - PopuList Far Right: FrP
replace rr_vote = 0 if inrange(NO_PRTY, 1, 95)
replace rr_vote = 1 if NO_PRTY == 2

* Poland (PL_PRTY) - PopuList Far Right: Konfederacja, PiS
replace rr_vote = 0 if inrange(PL_PRTY, 1, 95)
replace rr_vote = 1 if inlist(PL_PRTY, 3, 5)

* Sweden (SE_PRTY) - PopuList Far Right: SD
replace rr_vote = 0 if inrange(SE_PRTY, 1, 95)
replace rr_vote = 1 if SE_PRTY == 7

* Slovenia (SI_PRTY) - PopuList Far Right: SNS, SDS, NSi
replace rr_vote = 0 if inrange(SI_PRTY, 1, 95)
replace rr_vote = 1 if inlist(SI_PRTY, 4, 5, 6)

* Slovakia (SK_PRTY) - PopuList Far Right: SME Rodina, SNS, VLAST, L'SNS
replace rr_vote = 0 if inrange(SK_PRTY, 1, 95)
replace rr_vote = 1 if inlist(SK_PRTY, 4, 9, 17, 24)

label define rr_vote_lbl 0 "Other Party" 1 "Populist Radical Right"
label values rr_vote rr_vote_lbl
tab rr_vote, missing

* =========================================================================
* INDEPENDENT VARIABLES: The Three Dimensions of Patriarchy
* =========================================================================
* These continuous variables capture specific patriarchal attitudes that
* will be interacted with Gender to explain the PRR gap.

* -------------------------------------------------------------------------
* Public Patriarchy: Strongman Demand (Political Masculinity)
* -------------------------------------------------------------------------
clonevar male_pol_lead = v57
recode male_pol_lead (-9 -8 = .)

label define lead_pref_lbl 1 "Women much better" ///
                           2 "Women somewhat better" ///
                           3 "Equally suited" ///
                           4 "Men somewhat better" ///
                           5 "Men much better"
label values male_pol_lead lead_pref_lbl
label variable male_pol_lead "Prefers Male Political Leadership (Cabinet)"

* -------------------------------------------------------------------------
* 1b. Public Patriarchy: Economic & Academic Leadership (Placebo Tests)
* -------------------------------------------------------------------------
clonevar male_acad_lead = v58
clonevar male_econ_lead = v59

* Recode missing values
recode male_acad_lead male_econ_lead (-9 -8 = .)

* Apply the exact same 1-5 label used for political leadership
label values male_acad_lead male_econ_lead lead_pref_lbl

label variable male_acad_lead "Prefers Male Academic Leadership (University)"
label variable male_econ_lead "Prefers Male Economic Leadership (Executive)"

tab1 male_acad_lead male_econ_lead, missing

* -------------------------------------------------------------------------
* Productive Patriarchy: Traditional Breadwinner Norm
* -------------------------------------------------------------------------
clonevar trad_bwnorm = v6
recode trad_bwnorm (-9 -8 = .)

* Recode so 5=Strongly Agree (Higher = More Traditional)
recode trad_bwnorm (1=5) (2=4) (3=3) (4=2) (5=1)
label define trad_bwnorm_lbl 1 "Strongly disagree" 2 "Disagree" ///
                             3 "Neither agree nor disagree" 4 "Agree" ///
                             5 "Strongly agree"
label values trad_bwnorm trad_bwnorm_lbl
label variable trad_bwnorm "Men should earn, Women look after home (High=Agree)"

* -------------------------------------------------------------------------
* Private Patriarchy: Normative Policing of Family Roles
* -------------------------------------------------------------------------
clonevar gay_father = v18
recode gay_father (-9 -8 = .)

* Already in the correct direction (5=Strongly Disagree / Higher = Rejection)
label define agree_policing_lbl 1 "Strongly agree" 2 "Agree" ///
                                3 "Neither agree nor disagree" 4 "Disagree" ///
                                5 "Strongly disagree"
label values gay_father agree_policing_lbl
label variable gay_father "Same-sex male couple can raise child as well (High=Disagree)"

tab1 male_pol_lead trad_bwnorm gay_father, missing


* =========================================================================
* CONTROL VARIABLES: Socio-Demographics & Economic Grievance
* =========================================================================

* -------------------------------------------------------------------------
* Economic Precarity (Control for "Losers of Globalization" thesis)
* -------------------------------------------------------------------------
clonevar econ_diff = v60
recode econ_diff (-9 -8 = .)

* Recode so 5=Very difficult (Higher = More Precarity)
recode econ_diff (1=5) (2=4) (3=3) (4=2) (5=1)
label define econ_diff_lbl 1 "Very easy" 2 "Fairly easy" ///
                           3 "Neither easy nor difficult" 4 "Fairly difficult" ///
                           5 "Very difficult"
label values econ_diff econ_diff_lbl
label variable econ_diff "Difficulty making ends meet (High=Very difficult)"

* -------------------------------------------------------------------------
* Gender (SEX)
* -------------------------------------------------------------------------
clonevar gender = SEX
recode gender (-9 = .)
gen male = (gender == 1) if !missing(gender)
label variable male "Male Respondent (Dummy)"

* -------------------------------------------------------------------------
* Age (AGE)
* -------------------------------------------------------------------------
clonevar age = AGE
recode age (-9 = .)
label variable age "Age of Respondent (Years)"

* -------------------------------------------------------------------------
* Education (EDULEVEL) - 3 Categories
* -------------------------------------------------------------------------
clonevar educ = EDULEVEL
recode educ (-9 -8 = .)
gen educ_3cat = .
replace educ_3cat = 1 if inrange(educ, 0, 2)
replace educ_3cat = 2 if inrange(educ, 3, 4)
replace educ_3cat = 3 if inrange(educ, 5, 8)
label define educ_3cat_lbl 1 "Low Education" 2 "Medium Education" 3 "High Education"
label values educ_3cat educ_3cat_lbl
label variable educ_3cat "Highest Level of Education (3 Categories)"

* -------------------------------------------------------------------------
* Urban/Rural Residence (URBRURAL)
* -------------------------------------------------------------------------
clonevar urbrural = URBRURAL
recode urbrural (-9 -8 = .)
gen urban = (urbrural == 1 | urbrural == 2) if !missing(urbrural)
label variable urban "Lives in Urban Area (City/Suburbs)"

* -------------------------------------------------------------------------
* Religiosity (ATTEND) - Reversed to High = Frequent
* -------------------------------------------------------------------------
clonevar relig_attend = ATTEND
recode relig_attend (-9 -8 -7 = .)
recode relig_attend (1=8) (2=7) (3=6) (4=5) (5=4) (6=3) (7=2) (8=1)
label define relig_attend_lbl 1 "Never" 2 "Less than once a year" ///
                              3 "Once a year" 4 "Several times a year" ///
                              5 "Once a month" 6 "2 or 3 times a month" ///
                              7 "Once a week" 8 "Several times a week"
label values relig_attend relig_attend_lbl
label variable relig_attend "Religious Attendance (High = Frequent)"

* -------------------------------------------------------------------------
* Employment Status (WORK)
* -------------------------------------------------------------------------
clonevar work_stat = WORK
recode work_stat (-9 = .)
gen in_work = (work_stat == 1) if !missing(work_stat)
label variable in_work "Currently in Paid Work (Dummy)"

* =========================================================================
* SES: Oesch 8-Class Occupational Schema (via iscooesch package)
* =========================================================================
clonevar isco_clean = ISCO08
recode isco_clean (-9 -8 -6 -4 = .)

* Clean EMPREL for the package
gen emp_clean = .
replace emp_clean = 1 if EMPREL == 1
replace emp_clean = 2 if inlist(EMPREL, 2, 3, 4)
replace emp_clean = 3 if EMPREL == 5

* Clean EMPLNO (Number of supervised employees)
clonevar emplno_clean = NSUP
recode emplno_clean (-9 -8 -4 = .)
replace emplno_clean = 0 if EMPREL == 1 & WRKSUP == 2
replace emplno_clean = 1 if EMPREL == 1 & WRKSUP == 1 & missing(emplno_clean)
replace emplno_clean = 0 if EMPREL == 2
replace emplno_clean = 5 if EMPREL == 3
replace emplno_clean = 10 if EMPREL == 4

* Generate the 8-class schema
iscooesch class, isco(isco_clean) emplrel(emp_clean) emplno(emplno_clean) eight replace

* Recovering the "Never Worked" Population
replace oesch8_class = 9 if WORK == 3
label define oesch8_class 9 "Never Worked / Outside Labor Force", add
label values oesch8_class oesch8_class

* Final save of fully harmonized dataset
save "$OUT_DATA/Analysis_data.dta", replace

* Close log file
log close
