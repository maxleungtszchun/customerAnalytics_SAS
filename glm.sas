%MACRO getData(path, out, dbms);
	PROC IMPORT DATAFILE = &path OUT = &out DBMS = &dbms REPLACE;
		GETNAMES = yes;
	RUN;
%MEND;

%MACRO GLM(data, y, x, dist, link);
	PROC GENMOD DATA = &data DESCENDING;
		MODEL &y = &x /
		DIST = &dist
		LINK = &link;
	RUN;
%MEND;

%getData("/home/userAccount/sasuser.v94/regression_data.csv", regression_data, "csv");
%GLM(regression_data, return_1, n_r_s f_s m_s, binomial, logit);
%GLM(regression_data, f_1, n_r_s f_s m_s, poisson, log);

PROC CORR DATA = regression_data PLOTS = MATRIX PLOTS(maxpoints = none);
	VAR n_r_s f_s m_s;
RUN;