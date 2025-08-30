*wash the windows ;
ODS HTML CLOSE ;
ODS HTML ;
DM 'LOG; CLEAR; ODSRESULTS; CLEAR' ;

* The following line places a title on the first line of each page of output ;
TITLE ' Ryan Meister ' ;
RUN;

*import the dataset;
PROC IMPORT DATAFILE = ' D:/Project/TXPOP.CSV '
  OUT = POP
  DBMS = CSV
  REPLACE ;
  GETNAMES = YES ;
  RUN ;
* The following code estimates all possible ARMA(p,q) models for the first difference of Y, where p and
  q range from 0 to 3, with and without an intercept. If you think that the first difference of Y is
  the stationary version of the variable, you must remove the comments from this block of code; 
PROC ARIMA;
  IDENTIFY VAR=Y(1);
  ESTIMATE P=1 METHOD=ML;
  ESTIMATE P=1 METHOD=ML NOINT;
  ESTIMATE P=2 METHOD=ML;
  ESTIMATE P=2 METHOD=ML NOINT;
  ESTIMATE P=3 METHOD=ML;
  ESTIMATE P=3 METHOD=ML NOINT;
  ESTIMATE Q=1 METHOD=ML;
  ESTIMATE Q=1 METHOD=ML NOINT;
  ESTIMATE Q=2 METHOD=ML;
  ESTIMATE Q=2 METHOD=ML NOINT;
  ESTIMATE Q=3 METHOD=ML;
  ESTIMATE Q=3 METHOD=ML NOINT;
  ESTIMATE P=1 Q=1 METHOD=ML;
  ESTIMATE P=1 Q=1 METHOD=ML NOINT;
  ESTIMATE P=1 Q=2 METHOD=ML;
  ESTIMATE P=1 Q=2 METHOD=ML NOINT;
  ESTIMATE P=1 Q=3 METHOD=ML;
  ESTIMATE P=1 Q=3 METHOD=ML NOINT;
  ESTIMATE P=2 Q=1 METHOD=ML;
  ESTIMATE P=2 Q=1 METHOD=ML NOINT;
  ESTIMATE P=2 Q=2 METHOD=ML;
  ESTIMATE P=2 Q=2 METHOD=ML NOINT;
  ESTIMATE P=2 Q=3 METHOD=ML;
  ESTIMATE P=2 Q=3 METHOD=ML NOINT;
  ESTIMATE P=3 Q=1 METHOD=ML;
  ESTIMATE P=3 Q=1 METHOD=ML NOINT;
  ESTIMATE P=3 Q=2 METHOD=ML;
  ESTIMATE P=3 Q=2 METHOD=ML NOINT;
  ESTIMATE P=3 Q=3 METHOD=ML;
  ESTIMATE P=3 Q=3 METHOD=ML NOINT;
  RUN;


* End with a quit statement to close out the DM call;
QUIT;


