REPLICATION PACKAGE
====================

Defending Patriarchal Arrangements: Explaining Men's Disproportionate
Support for Populist Radical Right Parties in Europe

Francesco Marolla (University of Milan)

Published Article Reference:
This repository contains the replication package for the final published article.
Published in: International Journal of Sociology
DOI: 10.1080/00207659.2026.2718743

This package follows an Input -> Process -> Output (IPO) structure:

    Replication_Package/
    |-- Input/     Raw survey data goes here (not redistributed --
    |               see Input/README.txt)
    |-- Process/   The three do-files that build the analysis, in run order
    |-- Output/    Everything the do-files produce: derived data,
                    tables (in logs), figures, saved estimates, and run logs
        |-- Data/
        |-- Figures/
        |-- Estimates/
        |-- Logs/

SETUP
-----

1. Obtain the raw data and place it in Input/ -- see Input/README.txt.
2. Open each of the three .do files in Process/ and edit ONLY the
   `global ROOT "..."` line near the top to point at the absolute path
   of this Replication_Package folder on your machine. Every other path
   in every do-file is built relative to ROOT and needs no further editing.
3. Install the required user-written Stata packages (one-time):

       ssc install estout      // esttab / estpost, used for every table
       ssc install iscooesch   // Oesch 8-class occupational schema, used in 01

   melogit, mixed, margins, and marginsplot are built into Stata (13+);
   no extra install needed for those.

RUN ORDER
---------

Run the three do-files in numeric order -- each depends on the output of
the one before it:

01_Data_Preparation.do
    Reads   : Input/ZA10000_v2-0-0.dta
    Writes  : Output/Data/Analysis_data.dta
    Runtime : ~20 seconds

02_Data_Analysis.do
    Reads   : Output/Data/Analysis_data.dta
    Writes  : Tables 1-2 (in log), Figures 1-3,
              Output/Data/Mediation_Plot_Data.dta,
              Output/Data/Pol_Lead_Heterogeneity_Data.dta,
              .ster estimate files
    Runtime : Several hours (the country-by-country loops and the
              triple-interaction melogit models with vce(robust) are
              numerically intensive)

03_Supplementary_Material.do
    Reads   : Output/Data/Analysis_data.dta
    Writes  : Appendix Tables A2-A16 (in log)
    Runtime : ~2-3 minutes

WHERE EACH RESULT COMES FROM
-----------------------------

Main text:

  Table 1 (AMEs, Models 1-3)
      02_Data_Analysis.do, esttab ame_m1 ame_m2 ame_m3

  Table 2 (interactions, Models 4-6)
      02_Data_Analysis.do, esttab m4_int_pol_lead m5_int_bwnorm m6_int_policing

  Table 3 (triple interactions, Models 7-9, log-odds)
      02_Data_Analysis.do, read directly off the melogit output for
      m_triple_pol_lead, m_triple_bwnorm, m_triple_gayfather in the run log

  Table 4 (AMEs by gender x Oesch class)
      02_Data_Analysis.do, read directly off the three
      "margins male, dydx(...) over(oesch8_class)" outputs in the run log
      (also saved as .ster files in Output/Estimates/)

  Figure 1 (country mediation caterpillar plot)
      02_Data_Analysis.do -> Output/Figures/Gender_Gap_Mediation_Full_Caterpillar.png

  Figure 2 (predicted probability, Model 4)
      02_Data_Analysis.do -> Output/Figures/Interaction_Gender_Male_Pol_Lead.png

  Figure 3 (country heterogeneity, male leadership)
      02_Data_Analysis.do -> Output/Figures/Male_Pol_Lead_Heterogeneity_Split_AME.png

Online Appendix:

  Tables A1-A16 are all produced by 03_Supplementary_Material.do, in
  order, with matching table titles. Table A1 is a hand-maintained
  reference table (see the note at the top of that section in the
  do-file) rather than Stata output.

VERIFICATION
------------

All three do-files were run end-to-end in Stata (18.5) from a clean
state (fresh Input file, empty Output folders) and completed without
errors. Every reported number in Tables 1-4 and Appendix Tables A2-A16,
and Figures 1-3, was checked against this run's logs and matches the
manuscript and appendix exactly. See Output/Logs/ for the resulting run
logs (01: ~4 seconds, 02: ~7h13m, 03: ~2 minutes).
