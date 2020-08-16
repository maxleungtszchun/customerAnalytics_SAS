%MACRO getData(path, out, dbms);
	PROC IMPORT DATAFILE = &path OUT = &out DBMS = &dbms REPLACE;
		GETNAMES = yes;
	RUN;
%MEND;

%getData("/home/userAccount/sasuser.v94/regression_data.csv", regression_data, "csv");

PROC HPFOREST DATA = regression_data
	MAXTREES = 500
	VARS_TO_TRY = 2
	SEED = 1
	TRAINFRACTION = 1
	MAXDEPTH = 50
	LEAFSIZE = 10
	ALPHA = 0.1;
	TARGET return_1 / LEVEL = binary;
	INPUT n_r_s f_s m_s / LEVEL = interval;
	ODS OUTPUT fitstatistics = fit;
RUN;