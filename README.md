Note: If you are interested in R instead, please click [here](https://github.com/maxleungtszchun/customerAnalytics) to read Customer Analytics in R. If you are interested in SAS, please continue reading.

# Customer Analytics in SAS
## 1. RFM Analysis
Click [here](https://drive.google.com/file/d/1xDuSTrjgy4JhtTae900DtdaKTWLfcs66/view?usp=sharing) to download customer data (Period 0) <br/>
Click [here](https://drive.google.com/file/d/1-0bqUvNFnQTbTI7hzfgAZQHUub_1-JY0/view?usp=sharing) to download transaction data (Period 0)
```SAS
%MACRO getData(path, out, dbms);
	PROC IMPORT DATAFILE = &path OUT = &out DBMS = &dbms REPLACE;
		GETNAMES = yes;
	RUN;
%MEND;

%MACRO getRfmTable(customerData_, transactionData_, rawDataIsSecond, bins = 5, table = "yes");
	PROC SQL;
		CREATE TABLE transactionData AS
			SELECT *,
			MAX(InvoiceDate) AS reportDate
			FROM &transactionData_;
	QUIT;
	
	DATA transactionData;
		SET transactionData;
		IF &rawDataIsSecond = "yes" THEN
			dateDiff = (reportDate - InvoiceDate) / 86400;
		ELSE
			dateDiff = reportDate - InvoiceDate;
	RUN;
	
	PROC SQL;
		CREATE TABLE whole AS
			SELECT *
			FROM &customerData_ c
			LEFT OUTER JOIN
				(SELECT CustomerID,
				MIN(dateDiff) AS Recency,
				COUNT(*) AS Frequency,
				SUM(revenue) AS Monetary
				FROM transactionData
				GROUP BY CustomerID) t
			ON c.CustomerID = t.CustomerID
			ORDER BY c.CustomerID ASC;
	QUIT;
	
	PROC RANK DATA = whole OUT = whole GROUPS = &bins TIES = low;
		VAR Frequency Monetary;
		RANKS Frequency_Score Monetary_Score;
	RUN;
	
	PROC RANK DATA = whole OUT = whole DESCENDING GROUPS = &bins TIES = low;
		VAR Recency;
		RANKS Recency_Score;
	RUN;
	
	DATA whole;
		SET whole;
		Recency_Score = Recency_Score + 1;
		Frequency_Score = Frequency_Score + 1;
		Monetary_Score = Monetary_Score + 1;
		RFM_Score = MEAN(Recency_Score, Frequency_Score, Monetary_Score);
	RUN;
	
	PROC SORT DATA = whole OUT = whole;
		BY RFM_Score;
	RUN;
	
	%IF &table = "yes" %THEN
		%DO;
			PROC MEANS DATA = whole MAXDEC = 2;
				VAR Recency Frequency Monetary;
			RUN;
			
			PROC MEANS DATA = whole MEAN MAXDEC = 2;
				CLASS Frequency_Score Recency_Score;
				VAR RFM_Score Monetary;
			RUN;
			
			PROC TABULATE DATA = whole;
				CLASS Frequency_Score Recency_Score;
				VAR RFM_Score Monetary;
				TABLE Frequency_Score,
					RFM_Score * Recency_Score * (n mean);
			RUN;
		%END;
%MEND;

%MACRO plotGroupBars(data, title, color);
	PROC SGPLOT DATA = &data NOBORDER;
		FORMAT RFM_score 10.2;
		HBAR Country /
			RESPONSE = RFM_Score
			STAT = mean
			CATEGORYORDER = respdesc
			DATALABEL
			FILLATTRS = (COLOR = &color)
			NOOUTLINE;
		YAXIS DISPLAY = (nolabel noline noticks);
		YAXISTABLE Country /
			STAT = freq
			POSITION = left
			LOCATION = inside
			LABELATTRS = (COLOR = white);
		XAXIS DISPLAY = (noline noticks) GRID;
		TITLE &title;
	RUN;
%MEND;

FILENAME c "/home/userAccount/sasuser.v94/customer_data.csv";
FILENAME t "/home/userAccount/sasuser.v94/transaction_data_longDate.csv";

%getData(c, customer_data, csv);	
%getData(t, transaction_data, csv);
%getRfmTable(customer_data, transaction_data, "yes");
%plotGroupBars(whole, "Average RFM scores By Country", "orange");

PROC EXPORT DATA = whole
   OUTFILE = "/home/userAccount/sasuser.v94/whole.csv" 
   DBMS = csv
   REPLACE;
RUN;
```
Click [here](https://maxleungtszchun.github.io/rfm-results) to get the results.

## 2. Statistical Modelling
Click [here](https://drive.google.com/file/d/1ZXElhRIbISSyisJIFKaDgtNcnPAyTFbv/view?usp=sharing) to download regression data <br/>
return_1 = come back indicator (Period 1) <br/>
f_1 = frequency of visit (Period 1) <br/>
n_r_s = standardized negative recency value (z-score) (Period 0) <br/>
f_s = standardized frequency value (z-score) (Period 0) <br/>
m_s = standardized monetary value (z-score) (Period 0)
```SAS
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
```
Click [here](https://maxleungtszchun.github.io/glm-results) to get the results.
