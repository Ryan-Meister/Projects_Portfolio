*title the report;
TITLE ' Ryan A. Meister ' ;

*clean the windows;
ODS HTML CLOSE ; 
ODS HTML ; 
DM 'LOG; CLEAR; ODSRESULTS; CLEAR;' ;

*import the data;
PROC IMPORT DATAFILE = ' D:\Buxton\Project 4\Aspen_Row4_5645.CSV ' 
	OUT = Aspen1a
	DBMS = CSV
	REPLACE;
	GETNAMES = YES ;
	RUN;


*CHECK FOR UNREASONABLE VALUES OF THE DEPENDENT VARIABLE;
TITLE2 'Using All Observations' ;
*delete observations with values of zero;
DATA Aspen2a;
	SET Aspen1a;
	IF SALES=0 THEN DELETE;
	RUN;
*print out the above revised dataset (without 0s) and add a title;
TITLE2 'Using Non-Zero Observations' ;
*CHECK FOR AND ELIMINATE OULIER OBSERVATIONS
*using the data with dropped unreasonable values and calculate the specific outlier values - 
	low outlier = ybar - 2.5(std. dev y)
	high outlier = ybar + 2.5(std. dev y);
*for this dataset
	low outlier = 14,599,464 - 2.5(7,057,857) = -$3,045,178.50
	high outlier = 14,599,464 + 2.5(7,057,857) = $32,244,106.50;

*generate a new dataset that does not have outliers;
DATA Aspen3a;
	SET Aspen2a;
	IF SALES < -3045175.50 THEN DELETE;
	IF SALES > 32244106.50 THEN DELETE;
	RUN;
*print out the above revised dataset (without 0s) and add a title;
TITLE2 'Using Non-Zero and No Outlier Observations' ;
*get summary statistics and get the coefficient of variation on the dependent variable from the revised dataset;
PROC MEANS MAXDEC =0 N MEAN STD MIN MAX CV;
	VAR SALES;
	RUN;

DATA Aspen4a;
SET Aspen3a;
*LIMITED INTEGER VALUE (LIV) CONVERSIONS;

*movie_theaters_2rm;
MOVIE_THEATERS_LIV_2RM = 0;
	IF movie_theaters_2rm = 1 THEN MOVIE_THEATERS_LIV_2RM = 1;
	IF movie_theaters_2rm > 1 THEN MOVIE_THEATERS_LIV_2RM = 2;
	
*movie_theaters_10dtm;
MOVIE_THEATERS_LIV_10DTM = 0;
	IF movie_theaters_10DTM = 1 THEN MOVIE_THEATERS_LIV_10DTM = 1;
	IF movie_theaters_10DTM > 1 THEN MOVIE_THEATERS_LIV_10DTM = 2;



*DUMMY VARIABLE CONVERSIONS;
*competitorB_1rm;
COMP_B_DUM_1RM = 0;
	IF competitorB_1rm = 0 then COMP_B_DUM_1RM = 0;
	IF competitorB_1rm > 0 then COMP_B_DUM_1RM = 1;

*grocery_hi_1rm - DUMMY;
GROCERY_HI_DUM_1RM = 0;
	IF grocery_hi_1rm > 0 THEN GROCERY_HI_DUM_1RM = 1;

*grocery_low_1rm - DUMMY;
GROCERY_LOW_DUM_1RM = 0;
	IF grocery_low_1rm > 0 THEN GROCERY_LOW_DUM_1RM = 1;

*grocery_low_2rm - DUMMY;
GROCERY_LOW_DUM_2RM = 0;
	IF grocery_low_2rm > 0 THEN GROCERY_LOW_DUM_2RM = 1;

*dollar_stores_1rm - DUMMY;
DOLLAR_STORE_DUM_1RM = 0;
	IF dollar_stores_1rm > 0 THEN DOLLAR_STORE_DUM_1RM = 1;



*CREATED VARIABLES;

*Malls 25dtm;
Malls_25dtm = malls_luxury_25dtm + malls_general_25dtm + malls_high_25dtm ;

*Malls_Luxury_High_1RM;
Malls_Luxury_High_1RM = malls_high_1rm + malls_luxury_1rm;

*Xhomes_lt_250K_25DTM;
Xhomes_lt_250K_25DTM = Xhomes_lt_49K_25dtm + Xhomes_50_99K_25dtm + Xhomes_100_249K_25dtm;

*Xhomes_ge_250K_25dtm;
Xhomes_ge_250K_25dtm = Xhomes_250_499K_25dtm + Xhomes_500_999K_25dtm + Xhomes_ge_1mil_25dtm;

*ln_Med_Hhinc_ADJ_25DTM;
ln_Med_Hhinc_ADJ_25DTM = log(Med_Hhinc_ADJ_25DTM);

*malls_high_2rm_less_1RM;
malls_high_2rm_less_1RM = malls_high_2rm - malls_high_1rm;



	RUN;



*6 - FORCED;
*IF THERE ARE VARIABLES YOU MUST INCLUDE, LOOK AT THE FOLLOWING:
	here, we use the stepwise method, and force the variables that we want to never leave the regression equation

	how the sequential regression works
	FEED THE MODEL THE VARIABLES YOU WANT TO TEST (narrow it down from "all of them")
		1. finds the +1 variable regression equation, pared with the forced regreessors that has the lowest p-value (forced vars + x1)
		2. finds the +2 variable regression equation that has x1, paired with the forced variables and the variable with the next lowest p-value (forced vars + x1 + x2)
			BUT X1 MUST STAY SIGNIFICANT
		3. finds the 3 variable regression equation that has x1, x2, paired with the forced variables and the variable with the next lowest p-value (forced vars + x1 + x2 + x3)
			BUT X1 AND X2 MUST STAY SIGNIFICANT
		.
		.
		.
		stepwise selection keeps on going until there are no more regressors that can be 
		added that aren't significant themself, when paired with the forced variables, and keep other (non forced vars) significant too;
PROC REG;
	STEP_FORCED: MODEL SALES = 

Malls_Luxury_High_1RM	Xpop_70_85_25dtm	labor_white_col_25dtm	med_hhinc_adj_25dtm

	Malls_25dtm		Xhomes_ge_250K_25dtm	employed_25dtm	labor_farm_25dtm	employed_10dtm	labor_blue_25dtm	employed_2rm	employed_1rm	homes_500_999K_25dtm	homes_250_499K_25dtm	homes_500_999K_10dtm	Xhomes_500_999K_10dtm	Xhomes_100_249K_25dtm	Xhomes_500_999K_2rm	Xhomes_500_999K_25dtm	homes_500_999K_2rm	Xhomes_100_249K_1rm	Xhomes_100_249K_2rm	Xhomes_500_999K_1rm	Xhomes_100_249K_10dtm	hhinc_100_149K_25dtm	hhinc_ge_100K_25dtm	hhinc_150_249K_25dtm	hhinc_ge_250K_25dtm	hhinc_75_99K_25dtm	hhinc_50_74K_25dtm	hhinc_25_49K_25dtm	inc_percap_25dtm	hhinc_ge_250K_10dtm	hhinc_ge_100K_10dtm	hhinc_150_249K_10dtm	hhinc_lt_25K_25dtm	hhinc_100_149K_10dtm	avg_hhinc_adj_25dtm	hhinc_75_99K_10dtm	restaurants_25dtm	retail_25dtm	restaurants_retail_25dtm	Xrestaurants_retail_25dtm	grocery_hi_10dtm	grocery_hi_25dtm	grocery_mid_25dtm	movie_theaters_25dtm	dining_hi_1rm	dining_hi_2rm	dining_hi_10dtm	dining_hi_25dtm	dining_luxury_1rm	dining_luxury_2rm	dining_luxury_10dtm	dining_luxury_25dtm	malls_high_1rm	malls_high_10dtm	malls_high_25dtm	malls_luxury_1rm	malls_luxury_2rm	malls_luxury_10dtm	malls_luxury_25dtm	power_centers_25dtm	total_hh_expend_25dtm	Xretail_25dtm	Xrestaurants_retail_2rm	Xrestaurants_retail_10dtm	retail_10dtm	dining_casual_10dtm	Xretail_2rm	dining_casual_1rm	restaurants_retail_10dtm	dining_casual_2rm	Xretail_10dtm	total_hh_expend_10dtm	dining_casual_25dtm	malls_high_2rm	hh_2person_25dtm	hh_4person_25dtm	hh_25dtm	hh_3person_25dtm	hh_5person_25dtm	hh_1person_25dtm	hh_6person_25dtm	Brady_Bunch_25dtm	hh_4person_10dtm	hh_5person_10dtm	hh_2person_10dtm	hh_6person_10dtm	hh_3person_10dtm	hh_10dtm	pop_ge65_25dtm	pop_70_85_25dtm	fpop_ge65_25dtm	fpop_70_85_25dtm	mpop_ge65_25dtm	mpop_70_85_25dtm	pop_45_59_25dtm	pop_50_69_25dtm	fpop_45_59_25dtm	mpop_ge21__25dtm	mpop_40_49_25dtm	mpop_45_59_25dtm	mpop_50_69_25dtm	pop_ge18_25dtm	pop_ge21_25dtm	pop_40_49_25dtm	fpop_40_49_25dtm	fpop_50_69_25dtm	mpop_ge18_25dtm	fpop_ge18_25dtm	fpop_ge21_25dtm	mpop_35_44_25dtm	pop_35_44_25dtm	fpop_35_44_25dtm	mpop_21_39_25dtm	pop_21_39_25dtm	mpop_25_34_25dtm	pop_25_34_25dtm	fpop_21_39_25dtm	mpop_18_24_25dtm	fpop_25_34_25dtm	pop_18_24_25dtm	fpop_18_24_25dtm	mpop_70_85_10dtm	mpop_18_21_25dtm	pop_18_21_25dtm	fpop_18_21_25dtm	mpop_ge65_10dtm	pop_70_85_10dtm	Xmpop_ge21__25dtm	pop_ge65_10dtm	fpop_70_85_10dtm	fpop_ge65_10dtm	Xpop_ge21_25dtm	Xfpop_ge21_25dtm	fpop_50_69_10dtm	fpop_45_59_10dtm	pop_50_69_10dtm	pop_45_59_10dtm	Xfpop_ge21_10dtm	Xpop_ge21_10dtm	mpop_50_69_10dtm	mpop_45_59_10dtm	Xmpop_ge21__10dtm	fpop_ge21_10dtm	pop_ge21_10dtm	mpop_70_85_2rm	mpop_ge21__10dtm	fpop_40_49_10dtm	mpop_5_14_10dtm	pop_married_25dtm	pop_grades_9_12_25dtm	pop_15_17_25dtm	fpop_15_17_25dtm	mpop_15_17_25dtm	mpop_5_14_25dtm	pop_5_14_25dtm	mpop_4_17_25dtm	pop_4_17_25dtm	fpop_5_14_25dtm	fpop_4_17_25dtm	mpop_le20_25dtm	pop_le20_25dtm	fpop_le20_25dtm	mpop_le4_25dtm	pop_le4_25dtm	fpop_le4_25dtm	Xmpop_le20_25dtm	pop_married_10dtm	Xpop_le20_25dtm	Xfpop_le20_25dtm	Xfpop_le20_10dtm	Xpop_le20_10dtm	Xpop_married_25dtm	Xmpop_le20_10dtm	pop_bachelors_25dtm	pop_ge_bachelors_25dtm	pop_masters_25dtm	pop_professional_25dtm	pop_PhD_25dtm	pop_associates_25dtm	schools_25dtm	pop_grad_school_25dtm	Xpop_bachelors_25dtm	Xpop_bachelors_1rm	Xpop_bachelors_10dtm	pop_masters_10dtm	Xpop_ge_bachelors_25dtm	Xpop_bachelors_2rm	pop_2010_25dtm	COMP_B_DUM_1RM	competitorB_2rm	competitorB_10dtm	competitorB_25dtm	competitorA_2rm	competitorA_25dtm


	/ SELECTION=STEPWISE SLENTRY=0.10 SLSTAY=0.05 INCLUDE=4 ;
	RUN;
*NOTE: slentry stands for Significance Level to Enter in the model;
*NOTE: slstay stands for Significance Level to Stay in the model;
*NOTE: "include" indicates the regressor that must stay (the number indicates, starting from the left side of the regressor list
		how many must be forced to stay in the final result;



*end the program;
QUIT;


