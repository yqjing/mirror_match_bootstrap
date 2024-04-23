options pagesize=50 linesize=80;
options formchar='|----|+|---+=|-/\<>*';
title1 "SYC Data Computing";
footnote "SYC Data Computing";


/* Import the weight data - bootstrap_weights_matrix.csv */
proc import datafile='/home/u63744989/dataset/bootstrap_weights_matrix.csv'
	out = bootstrap_weights
	dbms = csv
	replace;
run;

/* set format */
proc format;
	value sex 1="male" 2="female";
	value race 1="white" 2="black" 3="Asian" 4="Native" 5="other";
	value prviol 1="yes" 0="no";
	value everdrug 1="yes" 0="no";
run;
	
/* Import the syc data - syc_sas.csv */
/* The finalwt is the improved version - finalwt2, which is computed in R */
data SYC;
	infile "/home/u63744989/dataset/syc_sas.csv" missover firstobs=2 delimiter = ',';
	input stratum finalwt age race sex numarr prviol everdrug;
	
	/* assign format */
	format sex sex.;
	format race race.;
	format prviol prviol.;
	format everdrug everdrug.;
run;

/* Merging syc with bootstrap weights */
data SYC;
	merge SYC bootstrap_weights;
	by stratum;
run;

/* part a) - estimate average age of youth in custody with taylor method*/
title2 "(a) (Taylor) The average age of youth in custody (point estimate and corresponding 95% CI)";  
proc surveymeans mean clm plots=none total=23655 data=SYC;
	var age;
	strata stratum;
	weight finalwt;
run;

title2 "(a) (Bootstrap) The average age of youth in custody (point estimate and corresponding 95% CI)"; 
proc surveymeans mean clm plots=none data = SYC varmethod=bootstrap;
	var age;
	weight finalwt;
	repweights w1-w100;
run;

/* part b) - the mean number of prior arrests */
title2 "(b) (Taylor) the mean number of prior arrests (point estimate and corresponding 95% CI)";
proc surveymeans mean clm plots=none total=23655 data=SYC;
	var numarr;
	strata stratum;
	weight finalwt;
run;

title2 "(b) (Bootstrap) the mean number of prior arrests (point estimate and corresponding 95% CI)";
proc surveymeans mean clm plots=none data = SYC varmethod=bootstrap;
	var numarr;
	weight finalwt;
	repweights w1-w100;
run;

/* part c) - the proportion of juveniles/young adults in custody that have used illegal drugs */
title2 "(c) (Taylor) the proportion of juveniles/young adults in custody that have used illegal drugs(point estimate and corresponding 95% CI)";
proc surveyfreq total=23655 data=SYC;
	tables everdrug / cl; 
	strata stratum;
	weight finalwt;
run;

title2 "(c) (Bootstrap) the proportion of juveniles/young adults in custody that have used illegal drugs (point estimate and corresponding 95% CI)";
proc surveyfreq data = SYC varmethod=bootstrap;
	tables everdrug / cl;
	weight finalwt;
	repweights w1-w100;
run;

/* part d) - the proportion of juveniles/young adults in custody that were previously arrested for a violent crime */
title2 "(d) (Taylor) the proportion of juveniles/young adults in custody that were previously arrested for a violent crime (point estimate and corresponding 95% CI)";
proc surveyfreq total=23655 data=SYC;
	tables prviol / cl; 
	strata stratum;
	weight finalwt;
run;

title2 "(d) (Bootstrap) the proportion of juveniles/young adults in custody that were previously arrested for a violent crime (point estimate and corresponding 95% CI)";
proc surveyfreq data = SYC varmethod=bootstrap;
	tables prviol / cl;
	weight finalwt;
	repweights w1-w100;
run;

/* part e) - the proportion of juveniles/young adults in custody that have used illegal drugs and were previously arrested for a violent crime */
title2 "(e) (Taylor) the proportion of juveniles/young adults in custody that have used illegal drugs and were previously arrested for a violent crime (point estimate and corresponding 95% CI)";
proc surveyfreq total=23655 data=SYC;
	tables everdrug*prviol / cl; 
	strata stratum;
	weight finalwt;
run;

title2 "(e) (Bootstrap) the proportion of juveniles/young adults in custody that have used illegal drugs and were previously arrested for a violent crime (point estimate and corresponding 95% CI)";
proc surveyfreq data = SYC varmethod=bootstrap;
	tables everdrug*prviol / cl;
	weight finalwt;
	repweights w1-w100;
run;

/* part f) - the proportion of males amongst juveniles/young adults in custody. */
title2 "(f) (Taylor) the proportion of males amongst juveniles/young adults in custody. (point estimate and corresponding 95% CI)";
proc surveyfreq total=23655 data=SYC;
	tables sex / cl; 
	strata stratum;
	weight finalwt;
	
run;

title2 "(f) (Bootstrap) the proportion of males amongst juveniles/young adults in custody. (point estimate and corresponding 95% CI)";
proc surveyfreq data = SYC varmethod=bootstrap;
	tables sex / cl;
	weight finalwt;
	repweights w1-w100;
run;

/* part g) - the proportion of males amongst juveniles/young adults in custody. */
title2 "(f) (Taylor) the proportion of African Americans . (point estimate and corresponding 95% CI)";
proc surveyfreq total=23655 data=SYC;
	tables race / cl; 
	strata stratum;
	weight finalwt;
run;

title2 "(g) (Bootstrap) the proportion of African Americans . (point estimate and corresponding 95% CI)";
proc surveyfreq data = SYC varmethod=bootstrap;
	tables race / cl;
	weight finalwt;
	repweights w1-w100;
run;

/* part h) - the proportion of males amongst juveniles/young adults in custody. */
title2 "(h) (Taylor) the proportion of African Americans males. (point estimate and corresponding 95% CI)";
proc surveyfreq total=23655 data=SYC;
	tables race*sex / cl; 
	strata stratum;
	weight finalwt;
run;

title2 "(h) (Bootstrap) the proportion of African Americans males. (point estimate and corresponding 95% CI)";
proc surveyfreq data = SYC varmethod=bootstrap;
	tables race*sex / cl;
	weight finalwt;
	repweights w1-w100;
run;







	




