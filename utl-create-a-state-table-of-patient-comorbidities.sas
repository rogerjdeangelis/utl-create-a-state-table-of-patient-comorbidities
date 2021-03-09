Create a state table of patient comorbidities

github
https://tinyurl.com/43pbuzmf
https://github.com/rogerjdeangelis/utl-create-a-state-table-of-patient-comorbidities

Inspired by
https://stackoverflow.com/questions/66475841/load-and-combine-all-sas-dataset

  RULES

      INPUTS TWO TABLES
      =================

         NAME     DIAGNOSIS

        Carol     Diabetes
        Janet     Diabetes
        Judy      Diabetes
        Robert    Diabetes


         NAME     DIAGNOSIS

        James      Obesity
        Judy       Obesity
        Thomas     Obesity


      OUTPUT
      ======
         NAME     DIABETES    OBESITY

        Carol         1          0
        James         0          1
        Janet         1          0

        Judy          1          1  ** Note judy is the only patient whose
                                       state is two cormorbities
        Robert        1          0
        Thomas        0          1

   TWO SOLUTIONS

        a. transpose
        b. merge

*_                   _
(_)_ __  _ __  _   _| |_
| | '_ \| '_ \| | | | __|
| | | | | |_) | |_| | |_
|_|_| |_| .__/ \__,_|\__|
        |_|
;

proc sort data=sashelp.class out=have noequals;
by name;
run;quit;

libname sd1 "d:/sd1";
 data
     sd1.hav1 (rename=diag1=Diagnosis drop=diag2)
     sd1.hav2 (rename=diag2=Diagnosis drop=diag1)
     ;
   set have(keep=name);

   diag1="Diabetes";
   diag2="Obesity";
   by name;
   if mod(_n_,4)=0 then output sd1.hav1;
   if mod(_n_,6)=0 then output sd1.hav2;

run;quit;

/*

SD1.HAV1 total obs=4

Obs     NAME     DIAGNOSIS

 1     Carol     Diabetes
 2     Janet     Diabetes
 3     Judy      Diabetes
 4     Robert    Diabetes

SD1.HAV2 total obs=3

Obs     NAME     DIAGNOSIS

 1     James      Obesity
 2     Judy       Obesity
 3     Thomas     Obesity

*/
*
 _ __  _ __ ___   ___ ___  ___ ___
| '_ \| '__/ _ \ / __/ _ \/ __/ __|
| |_) | | | (_) | (_|  __/\__ \__ \
| .__/|_|  \___/ \___\___||___/___/
|_|        _
  __ _    | |_ _ __ __ _ _ __  ___ _ __   ___  ___  ___
 / _` |   | __| '__/ _` | '_ \/ __| '_ \ / _ \/ __|/ _ \
| (_| |_  | |_| | | (_| | | | \__ \ |_) | (_) \__ \  __/
 \__,_(_)  \__|_|  \__,_|_| |_|___/ .__/ \___/|___/\___|
                                  |_|
;

/*
only if you rerun you rerun;

proc datasets lib=work nolist;
  delete hav Cmb hav Xpo Want;
run;quit;

%arraydelete(mem);   /* macro array of tables in d:/sd1 folder */
%arraydelete(diag);  /* macro array of comorbitities ie Diabetes Obrsity */
*/

* create a macro array of table names in folder d:/sd1;
proc sql;
  select
    memname into :mem1-
  from
    sashelp.vtable
  where
    libname = "SD1"
;quit;

%let memn=&sqlobs;

/*
%put &=mem1;
%put &=mem2;
%put &=memn;

Macro array

MEM1=HAV1
MEM2=HAV2
MEMN=2

*/

* create a macro array of diagnosis codes;
data _null_;
  length diagnosis $32;
  set
    %do_over(mem,phrase=sd1.?(obs=1))
  end=dne;
  call symputx(cats("diag",_n_),diagnosis);
  if dne then call symputx("diagn",_n_);
run;quit;

/*
%put &=diag1;
%put &=diag2;
%put &=diagn;

Macro array

DIAG1=Diabetes
DIAG2=Obesity
DIAGN=2
*/

data havCmb;
  length diagnosis $32;
  set
     %do_over(mem,phrase=sd1.?);
  by name ; /* inportant for rename? */
run;quit;

/*
WORK.HAVE total obs=7

Obs     NAME     DIAGNOSIS

 1     Carol     Diabetes
 2     James     Obesity
 3     Janet     Diabetes

 4     Judy      Diabetes
 5     Judy      Obesity

 6     Robert    Diabetes
 7     Thomas    Obesity
*/

proc transpose data=havCmb out=havXpo(drop=_name_) prefix=diag;
by name ;
var diagnosis;
run;quit;

/*
WORK.HAVXPO total obs=6

Obs     NAME      DIAG1       DIAG2

 1     Carol     Diabetes
 2     James     Obesity
 3     Janet     Diabetes
 4     Judy      Diabetes    Obesity
 5     Robert    Diabetes
 6     Thomas    Obesity
*/

%array(dgns,values=%utl_varlist(data=havXpo,prx=/DIAG/i));

/*
%put &=dgns1;
%put &=dgns2;
%put &=dgnsn;

DGNS1=DIAG1
DGNS2=DIAG2
DGNSN=2

*/

data want;
  set havXpo;
  %do_over(dgns diag,phrase=%str(
    if ?dgns = ""  then ?diag=0;
    else ?diag=1;
    drop ?dgns;
  ));
run;quit;

*_
| |__     _ __ ___   ___ _ __ __ _  ___
| '_ \   | '_ ` _ \ / _ \ '__/ _` |/ _ \
| |_) |  | | | | | |  __/ | | (_| |  __/
|_.__(_) |_| |_| |_|\___|_|  \__, |\___|
                             |___/
;

/*
 only if you rerun you rerun

proc datasets lib=work nolist;
  delete hav Cmb hav Xpo Want;
run;quit;

%arraydelete(mem);   /* macro array of tables in d:/sd1 folder */
%arraydelete(diag);  /* macro array of comorbitities ie Diabetes Obrsity */
%arraydelete(dgns);  /* proc transpose generted column name we nee to rename */
*/


* create macro arrays of table names and diagnosis codes;

* create a macro array of table names;
proc sql;
  select
    memname into :mem1-
  from
    sashelp.vtable
  where
    libname = "SD1"
;quit;

%let memn=&sqlobs;

/*
%put &=mem1;
%put &=mem2;
%put &=memn;

Macro array

MEM1=HAV1
MEM2=HAV2
MEMN=2

*/

* create a macro array of diagnosis codes;
data _null_;
  set
    %do_over(mem,phrase=sd1.?(obs=1))
  end=dne;
  call symputx(cats("diag",_n_),diagnosis);
  if dne then call symputx("diagn",_n_);
run;quit;

/*
%put &=diag1;
%put &=diag2;
%put &=diagn;

Macro array

DIAG1=Diabetes
DIAG2=Obesity
DIAGN=2
*/

* merge will hanle much more tha 200 tables;
data want;

  merge
    %do_over(mem diag,phrase=%str(sd1.?mem(rename=diagnosis=?diagc))) end=dne;
  by name;

  %do_over(diag,phrase=%str(
    if ?c = ""  then ?=0;
    else ?=1;
    drop ?c;
  ));

run;quit;

*            _               _
  ___  _   _| |_ _ __  _   _| |_
 / _ \| | | | __| '_ \| | | | __|
| (_) | |_| | |_| |_) | |_| | |_
 \___/ \__,_|\__| .__/ \__,_|\__|
                |_|
;
/*
Up to 40 obs WORK.WANT total obs=6

Obs     NAME     DIABETES    OBESITY

 1     Carol         1          0
 2     James         0          1
 3     Janet         1          0
 4     Judy          1          1
 5     Robert        1          0
 6     Thomas        0          1
*/
