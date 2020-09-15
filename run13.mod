$SIZES      PD=-150

$PROB run13.mod; Claret TGI model




$INPUT 


C	PROT	NSID	ID	STID	DOSE	DOSEP	DOSIV	
DOSIVP	DOS2	DOS2P	TRT	TRTG=DROP	PERD	NTPD	DAY	
TIME	FLAGE	AGE	SEX	RACE	ETHN	RACD	BWT	
SMOK	BBMI	BCCL	BCAL	BPLT	BNEU	BHGB	BALB	
BLDH	BALT	BAST	BBIL	BSLD	DV	SURT	CENS	
ECOG	METS	LIVMET	LNGMET	BONMET	MSKCC	HENG	EGFR	
EVID	EVNT	DOSRED	DOSINT	BLYM
DSLD	TREAT=DROP	TREAT2=DROP	LBSLD	LSLD


;TAFD is time in weeks
;DV is the SLD column in mm


$DATA RCC_COMBINED_PD2_SLD_31OCT2019.csv
IGNORE=@

$SUBROUTINE ADVAN 13 TOL=6

$MODEL
COMP=TUMOR

$PK
;;; LAMTRT-DEFINITION START
IF(TRT.EQ.2)   LAMTRT = 1
IF(TRT.EQ.1)   LAMTRT = (1+THETA(15))
IF(TRT.EQ.3)   LAMTRT = (1+THETA(16))
IF(TRT.EQ.4)   LAMTRT = (1+THETA(17))
IF(TRT.EQ.5)   LAMTRT = (1+THETA(18))
;;; LAMTRT-DEFINITION END

;;; LAM-RELATION START
LAMCOV=LAMTRT
;;; LAM-RELATION END


;;; KLTRT-DEFINITION START
IF(TRT.EQ.2)   KLTRT = 1
IF(TRT.EQ.1)   KLTRT = (1+THETA(11))
IF(TRT.EQ.3)   KLTRT = (1+THETA(12))
IF(TRT.EQ.4)   KLTRT = (1+THETA(13))
IF(TRT.EQ.5)   KLTRT = (1+THETA(14))
;;; KLTRT-DEFINITION END

;;; KL-RELATION START
KLCOV=KLTRT
;;; KL-RELATION END


;;; KDTRT-DEFINITION START
IF(TRT.EQ.2)   KDTRT = 1
IF(TRT.EQ.1)   KDTRT = (1+THETA(7))
IF(TRT.EQ.3)   KDTRT = (1+THETA(8))
IF(TRT.EQ.4)   KDTRT = (1+THETA(9))
IF(TRT.EQ.5)   KDTRT = (1+THETA(10))
;;; KDTRT-DEFINITION END


;;; KDBSLD-DEFINITION START
   KDBSLD = ((BSLD/91)**THETA(6))
;;; KDBSLD-DEFINITION END

;;; KD-RELATION START
KDCOV=KDBSLD*KDTRT
;;; KD-RELATION END



TVKL=LOG(THETA(1)/52)		; change to rate/year from /weeks

TVKL = KLCOV*TVKL
MU_1=TVKL		
KL = EXP(MU_1+ETA(1))

TVKD=LOG(THETA(2)/52)

TVKD = KDCOV*TVKD
MU_2=TVKD
KD = EXP(MU_2+ETA(2))

TVLAM=LOG(THETA(3)/52)

TVLAM = LAMCOV*TVLAM
MU_3=TVLAM
LAM = EXP(MU_3+ETA(3))

A_0(1)=BSLD



$DES

  ;y(t) = y(0) exp[ kL t - (kD Treatment/lam)(1-exp(-lam t)) ]. 
  ;dy/dt = [kL t - kD/lam Treatment (exp(-lam t))] y(t).


DADT(1) = (KL - KD*EXP(-LAM*T))*A(1)




$ERROR

IPRED=A(1)
W = SQRT(THETA(4)**2*IPRED**2+THETA(5)**2)
   
Y=IPRED+W*ERR(1)

IWRES=(DV-IPRED)/W


XL=LOG(KL)
XD=LOG(LAM*KD)

IF(XL.GT.XD) THEN
   TTG=0
ELSE
  TTG=(LOG(LAM*KD)-LOG(KL))/LAM ; added lam for KD term to adjust
ENDIF

   
   W6 = BSLD*EXP(KL*6-(KD/LAM)*(1-EXP(-LAM*6)))
   W8 = BSLD*EXP(KL*8-(KD/LAM)*(1-EXP(-LAM*8)))
   TR6= W6/BSLD
   TR8= W8/BSLD
   

$THETA  (0,0.143663) ; KL
 (0,1.60217) ; KD
 (0,3.939) ; LAM
 (0.01,0.0811432) ; Proportional Error
 (0.01,2.26872) ; Additive Error
 
$THETA  (-100,0.0506293,100000) ; KDBSLD1

$THETA  (-100000,0.352134,100000) ; KDTRT1
 (-100000,-0.0745063,100000) ; KDTRT2
 (-100000,0.0073258,100000) ; KDTRT3
 (-100000,-0.0769689,100000) ; KDTRT4
 
$THETA  (-100000,-0.0946182,100000) ; KLTRT1
 (-100000,-0.036812,100000) ; KLTRT2
 (-100000,0.0612846,100000) ; KLTRT3
 (-100000,0.0898521,100000) ; KLTRT4
 
$THETA  (-100000,0.212748,100000) ; LAMTRT1
 (-100000,-0.397089,100000) ; LAMTRT2
 (-100000,0.0522,100000) ; LAMTRT3
 (-100000,0.0611664,100000) ; LAMTRT4
 
$OMEGA  2.26315  ;    ETA(KL)
 0.839075  ;    ETA(KD)
 1.66932  ;   ETA(LAM)
 
$SIGMA  1  FIX

;$EST PRINT=10 MAXEVAL=9999 METHOD=1 INTER  FILE=run4.ext

$EST METHOD=SAEM EONLY=0 INTER NBURN=3000 NITER=250 SEED=2019 PRINT=50 DF=0 
GRD=DDDSS CTYPE=3 CITER=10 CALPHA=0.05 ISAMPLE=2 IACCEPT=0.4
$EST METHOD=IMP EONLY=1 NITER=5 ISAMPLE=4000 PRINT=1 DF=4 GRD=DDDSS IACCEPT=1.0 MAPITER=0 FILE=run13.ext
CTYPE=3 CITER=10 CALPHA=0.05 MSFO=MK13.msf

$COV PRINT=E

$TABLE PROT ID TIME IPRED WRES CWRES IWRES 
KL KD LAM TTG TR6 TR8  
BSLD DV DSLD LBSLD LSLD TRT
ETA1 ETA2 ETA3 
FORMAT=sF12.6 ONEHEADER NOPRINT FILE=tgi13.fit

