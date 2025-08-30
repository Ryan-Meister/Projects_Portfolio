*wash the windows;
ODS HTML CLOSE ;
ODS HTML ;
DM ' LOG; CLEAR; ODSRESULTS; CLEAR; ' ;

*title the program;
TITLE 'Ryan A. Meister' ;
	RUN;

*read in the data from the flash drive;
PROC IMPORT DATAFILE = ' D:\PROJECT\TXPOP.CSV '
	OUT = GDP
	DBMS = CSV
	REPLACE ;
	GETNAMES = YES ;
	RUN ;
PROC ARIMA;
	IDENTIFY VAR=Y(1);
	*ARMA(2, 1) with an intercept;
	ESTIMATE P=2 Q=1 METHOD=ML;
	RUN;

*test RMSFE of best model;
PROC ARIMA;
	IDENTIFY VAR=Y(1);
	ESTIMATE Q=1 P=2 METHOD=ML;
	FORECAST LEAD = 3;
	RUN;

*end the program;
QUIT;
