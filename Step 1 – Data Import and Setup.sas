*wash the windows;
ODS HTML CLOSE ;
ODS HTML ;
DM ' LOG; CLEAR; ODSRESULTS; CLEAR; ' ;
*title the program;
TITLE 'Ryan A. Meister' ;
	RUN;
*read in the data from the flash drive;
PROC IMPORT DATAFILE = ' D:\Project\TXPOP.CSV '
	OUT = TRADE
	DBMS = CSV
	REPLACE ;
	GETNAMES = YES ;
	RUN ;
*y in levels in lags 0, 1, and 2;
PROC ARIMA;
	IDENTIFY VAR=Y STATIONARY = ( ADF = (0, 1, 2, 3) );
	RUN;
*first difference in y in lags 0, 1 and 2;
PROC ARIMA;
	IDENTIFY VAR=Y(1) STATIONARY = ( ADF = (0, 1, 2, 3) );
	RUN;

*Pr > ChiSq
	ftr - white noise (good -> stationary)
	rej - not white noise (keep testing -> non-stationary);

*if trending upwards, consider the tau tau test (trend)
*if it has zero mean, consider tau test (zero mean)

*the number of consecutive significant pacfs = autocorrelation in error term (the # of lags you check to see if stationary)
	0 significant pacf = look at lag 0
	1 signifcant pacf = look at lag 1
	2 significant pacf = look at lag 2;

*To find if it is significant:
	test statistic is negative & 1/2 p-value is significant (<.05);

PROC ARIMA;
	*1st difference y;
	IDENTIFY VAR=Y(1);
	*ar(1) with no int;
	ESTIMATE P=1 NOINT METHOD=ML;
	*forecast one period ahead;
	FORECAST LEAD=3;
	RUN;

PROC ARIMA;
	*1st difference y;
	IDENTIFY VAR=Y(2);
	*ar(1) with no int;
	ESTIMATE P=1 NOINT METHOD=ML;
	*forecast one period ahead;
	FORECAST LEAD=3;
	RUN;

PROC ARIMA;
	*1st difference y;
	IDENTIFY VAR=Y(3);
	*ar(1) with no int;
	ESTIMATE P=1 NOINT METHOD=ML;
	*forecast one period ahead;
	FORECAST LEAD=5;
	RUN;

*end the program;
QUIT;
