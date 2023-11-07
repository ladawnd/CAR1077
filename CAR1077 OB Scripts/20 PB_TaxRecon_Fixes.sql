/*****************************************************************************************************************
** Data Conversion Technical Team
**
** Name: OB_TaxRecon_Fixes.sql
** Desc: Review and fix Tax Recon errors.
** When to use:	This is tool for TCs to use on opening balance loads.
**				The is for the new Tax Recon Tool that was rolled out in November 2017.
**
**				If you run this entire script as is, then if will apply fixes to the errors 
**				we have identified as Ultipro calculated amounts and therefore safe to fix.
**
**				For errors that require analysis before potential fixing, the update statements 
**				are commented out.
**
**              In Pervasive this script is named: 7 - TAX RECON.sql
**
!! If in doubt contact Manager or Team Lead before running.
** Auth: Sean Peragine 
** Date: 11/28/2017
**************************
** Change History
**************************
** CID	Date		Author		Description	
** ---  --------	--------	------------------------------------
** 001	2017-11-28	Sean P
** 002	2017-11-29	Miles S		Added standardized description/history and grouped fixes by category.
** 003	2017-12-04	Sean P		Modified the Summary select to not join to iptaxhist.
** 004	2017-12-05	Maciek T	Modified the detail selects to left join to iptaxhist and display row even if missing iptaxhist.
** 005  2017-12-08      Miles S		Added the fix for "Calculation error (N/A)" or 'MnWagLkp missing:" 
** 006  2017-12-15  	Miles S		Added extra conditions on updating pthcurtaxamt to prevent updating EE taxes 
** 007  2017-12-19	Miles S		Added second update for USMEDER tax amount.  Need two updates, one for OBYTD and one for OBQTD
** 008	2017-12-19	Eric H		Added filter to only look at gennumbers that exist in OBLDMas table
** 009  2019-03-27	Miles S		Added error 315 and 316
** 010	2019-07-05	Miles S		Added fix for pthResidentTaxableWages
** 011	2019-08-28	Miles S		Added fix for pthWorkInTaxableWages 
** 012  2019-09-06	Miles S		Uncommented the Medicare Surcharge update for earnings over 200000.  Should always be run.
** 013  2019-09-25      Joe J	        Added fix for pthResidentTaxableWages   
******************************************************************************************************************/

--TAX RECON ERROR SUMMARY
/*

SELECT COUNT(*) as ErrorCount, ShortDesc, t.AdjustmentColumn, t.TestID as ErrorCode
FROM UaeReconTests t
JOIN UaeReconResults r on r.TestID = t.TestID
WHERE abs(MonBefore - MonAfter) > .05
AND (EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMOBSYSTEMID = R.GENNUMBER) 
OR EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMQTDGENNUM = R.GENNUMBER))
GROUP BY t.TestID, ShortDesc, t.AdjustmentColumn
ORDER BY t.TestID

*/

 /*********************************************************
All of these fields are calculated by Ultipro
therefore we can run the update statements below
to apply the tax recon fixes.
************************************************************/
--	prgcheckamt
--	prgnetamt
--	prgtotdedamt
--	prgtotearnamt
--	prgtottaxamt
--	pthCurD125                    
--	pthCurDefComp                 
--	pthCurDepCare                 
--	pthCurExcessWages             
--	pthCurExemptWages             
--	pthCurGrossWages              
--	pthCurHousing                 
--	pthCurOtherWages              
--	pthCurSec125                  
--	pthCurTaxableGross            
--	pthCurTaxableTips             
--	pthCurTaxableWages            
--	pthReportingTaxableWages  


/*==================================================================
 All of these fields need analysis by the TC
 to dedicde if any can be udpated.  All sample update
 statemens for these fields are commented out.
===================================================================*/
--	pthCurTaxAmt                  
--	pthGTLUncollectedTax
--	pthTipsUncollectedTax
--	pthUncollectedTax    



/*=============================================================================================================
  This fix can be used if you receive the tax recon errors "Calculation error (N/A)" or 'MnWagLkp missing:" 
===============================================================================================================*/

update payreg set 
-- select prgcoid, prgeeid,  prgpercontrol,  prgdocno, prggennumber, prgdatetimeinserted, PrgLMWOverride,PrgPeriodStartDate, prgpaygroup,
PrgLMWOverride = 'N' ,
PrgPeriodStartDate = (select PgpPeriodStartDate from pgpayper where PgpPeriodControl = prgpercontrol and PgpPayGroup = prgpaygroup)
from payreg
where prgdocno in ('OBYTD', 'OBQTD')



/*===============================================================================================
(pthCurD125)
================================================================================================*/

--ERROR: 221     DESCRIPTION: LIT WorkIn dependent care Section 125 (pthCurD125)
--ERROR: 222     DESCRIPTION: LIT Wcc dependent care Section 125 (pthCurD125)
--ERROR: 223     DESCRIPTION: LIT SD dependent care Section 125 (pthCurD125)
--ERROR: 224     DESCRIPTION: LIT Res dependent care Section 125 (pthCurD125)
--ERROR: 225     DESCRIPTION: LIT Other dependent care Section 125 (pthCurD125)
--ERROR: 226     DESCRIPTION: LIT Occ dependent care Section 125 (pthCurD125)
--ERROR: 227     DESCRIPTION: FUT dependent care Section 125 (pthCurD125)
--ERROR: 229     DESCRIPTION: MED dependent care Section 125 (pthCurD125)
--ERROR: 230     DESCRIPTION: SOC dependent care Section 125 (pthCurD125)
--ERROR: 232     DESCRIPTION: SIT WorkIn dependent care Section 125 (pthCurD125)
--ERROR: 233     DESCRIPTION: SIT Res dependent care Section 125 (pthCurD125)
--ERROR: 234     DESCRIPTION: SDI dependent care Section 125 (pthCurD125)
--ERROR: 237     DESCRIPTION: USFIT dependent care Section 125 (pthCurD125)

/*
SELECT CoID, EmpNo, Name, PayDate, DocNo, GenNumber, Code as TaxCode, t.TestId, pthCurD125, MonAfter, pthCurD125 - MonAfter as Diff
,Case when PTHGenNumber is null then 'Missing iPtaxHist Record' else null end as Comment
FROM UaeReconTests t
JOIN UaeReconResults r on r.TestId = t.TestId
left JOIN iPTaxHist on PthGenNumber = r.GenNumber and PthTaxCode = Code and abs(pthCurD125 - MonAfter) > .05
WHERE t.AdjustmentColumn = 'pthCurD125' 
*/

UPDATE iPTaxHist
SET pthCurD125  = MonAfter
FROM UaeReconTests t
JOIN UaeReconResults r on r.TestId = t.TestId
JOIN iPTaxHist on PthGenNumber = r.GenNumber and PthTaxCode = Code
WHERE t.AdjustmentColumn = 'pthCurD125'
AND (EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMOBSYSTEMID = R.GENNUMBER) 
OR EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMQTDGENNUM = R.GENNUMBER))
and pthtaxcode <> 'USSOCER'

/*===============================================================================================
(pthCurDefComp)
================================================================================================*/
--ERROR: 33     DESCRIPTION: SDI deferred comp (pthCurDefComp)
--ERROR: 34     DESCRIPTION: SUI deferred comp (pthCurDefComp)
--ERROR: 35     DESCRIPTION: SIT Res deferred comp (pthCurDefComp)
--ERROR: 36     DESCRIPTION: SIT WorkIn deferred comp (pthCurDefComp)
--ERROR: 118     DESCRIPTION: USFIT deferred comp (pthCurDefComp)
--ERROR: 162     DESCRIPTION: LIT Occ deferred comp (pthCurDefComp)
--ERROR: 172     DESCRIPTION: LIT Other deferred comp (pthCurDefComp)
--ERROR: 182     DESCRIPTION: LIT Res deferred comp (pthCurDefComp)
--ERROR: 192     DESCRIPTION: LIT SD deferred comp (pthCurDefComp)
--ERROR: 202     DESCRIPTION: LIT Wcc deferred comp (pthCurDefComp)
--ERROR: 212     DESCRIPTION: LIT WorkIn deferred comp (pthCurDefComp)

/*
SELECT CoID, EmpNo, Name, PayDate, DocNo, GenNumber, Code as TaxCode, t.TestId, pthCurDefComp, MonAfter, pthCurDefComp - MonAfter as Diff
,Case when PTHGenNumber is null then 'Missing iPtaxHist Record' else null end as Comment
FROM UaeReconTests t
JOIN UaeReconResults r on r.TestId = t.TestId
left JOIN iPTaxHist on PthGenNumber = r.GenNumber and PthTaxCode = Code and abs(pthCurDefComp - MonAfter) > .05
WHERE t.AdjustmentColumn = 'pthCurDefComp'
*/

UPDATE iPTaxHist
SET pthCurDefComp  = MonAfter
FROM UaeReconTests t
JOIN UaeReconResults r on r.TestId = t.TestId
JOIN iPTaxHist on PthGenNumber = r.GenNumber and PthTaxCode = Code
WHERE t.AdjustmentColumn = 'pthCurDefComp'
AND (EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMOBSYSTEMID = R.GENNUMBER) 
OR EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMQTDGENNUM = R.GENNUMBER))
/*===============================================================================================
(pthCurDepCare)
================================================================================================*/
--ERROR: 15     DESCRIPTION: SDI dependent care (pthCurDepCare)
--ERROR: 16     DESCRIPTION: SUI dependent care (pthCurDepCare)
--ERROR: 17     DESCRIPTION: SIT Res dependent care (pthCurDepCare)
--ERROR: 18     DESCRIPTION: SIT WorkIn dependent care (pthCurDepCare)
--ERROR: 84     DESCRIPTION: USFIT dependent care (pthCurDepCare)
--ERROR: 86     DESCRIPTION: SOC dependent care (pthCurDepCare)
--ERROR: 87     DESCRIPTION: MED dependent care (pthCurDepCare)
--ERROR: 89     DESCRIPTION: FUT dependent care (pthCurDepCare)
--ERROR: 163     DESCRIPTION: LIT Occ dependent care (pthCurDepCare)
--ERROR: 173     DESCRIPTION: LIT Other dependent care (pthCurDepCare)
--ERROR: 183     DESCRIPTION: LIT Res dependent care (pthCurDepCare)
--ERROR: 193     DESCRIPTION: LIT SD dependent care (pthCurDepCare)
--ERROR: 203     DESCRIPTION: LIT Wcc dependent care (pthCurDepCare)
--ERROR: 213     DESCRIPTION: LIT WorkIn dependent care (pthCurDepCare)

/*
SELECT CoID, EmpNo, Name, PayDate, DocNo, GenNumber, Code as TaxCode, t.TestId, pthCurDepCare, MonAfter, pthCurDepCare - MonAfter as Diff
,Case when PTHGenNumber is null then 'Missing iPtaxHist Record' else null end as Comment
FROM UaeReconTests t
JOIN UaeReconResults r on r.TestId = t.TestId
left JOIN iPTaxHist on PthGenNumber = r.GenNumber and PthTaxCode = Code and abs(pthCurDepCare - MonAfter) > .05
WHERE t.AdjustmentColumn = 'pthCurDepCare' 
*/

UPDATE iPTaxHist
SET pthCurDepCare  = MonAfter
FROM UaeReconTests t
JOIN UaeReconResults r on r.TestId = t.TestId
JOIN iPTaxHist on PthGenNumber = r.GenNumber and PthTaxCode = Code
WHERE t.AdjustmentColumn = 'pthCurDepCare'
AND (EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMOBSYSTEMID = R.GENNUMBER) 
OR EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMQTDGENNUM = R.GENNUMBER))
/*===============================================================================================
(pthCurExcessWages)
================================================================================================*/
--ERROR: 63     DESCRIPTION: SDI excess wages (pthCurExcessWages)
--ERROR: 64     DESCRIPTION: SUI excess wages (pthCurExcessWages)
--ERROR: 132     DESCRIPTION: SOC excess wages (pthCurExcessWages)
--ERROR: 135     DESCRIPTION: FUT excess wages (pthCurExcessWages)

/*
SELECT CoID, EmpNo, Name, PayDate, DocNo, GenNumber, Code as TaxCode, t.TestId, pthCurExcessWages, MonAfter, pthCurExcessWages - MonAfter as Diff
,Case when PTHGenNumber is null then 'Missing iPtaxHist Record' else null end as Comment
FROM UaeReconTests t
JOIN UaeReconResults r on r.TestId = t.TestId
left JOIN iPTaxHist on PthGenNumber = r.GenNumber and PthTaxCode = Code and abs(pthCurExcessWages - MonAfter) > .05
WHERE t.AdjustmentColumn = 'pthCurExcessWages' 
*/

UPDATE iPTaxHist
SET pthCurExcessWages  = MonAfter
FROM UaeReconTests t
JOIN UaeReconResults r on r.TestId = t.TestId
JOIN iPTaxHist on PthGenNumber = r.GenNumber and PthTaxCode = Code
WHERE t.AdjustmentColumn = 'pthCurExcessWages'
AND (EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMOBSYSTEMID = R.GENNUMBER) 
OR EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMQTDGENNUM = R.GENNUMBER))
/*===============================================================================================
(pthCurExemptWages)
================================================================================================*/
--ERROR: 27     DESCRIPTION: SDI exempt wages (pthCurExemptWages)
--ERROR: 28     DESCRIPTION: SUI exempt wages (pthCurExemptWages)
--ERROR: 29     DESCRIPTION: SIT Res exempt wages (pthCurExemptWages)
--ERROR: 30     DESCRIPTION: SIT WorkIn exempt wages (pthCurExemptWages)
--ERROR: 112     DESCRIPTION: USFIT exempt wages (pthCurExemptWages)
--ERROR: 114     DESCRIPTION: SOC exempt wages (pthCurExemptWages)
--ERROR: 115     DESCRIPTION: MED exempt wages (pthCurExemptWages)
--ERROR: 117     DESCRIPTION: FUT exempt wages (pthCurExemptWages)
--ERROR: 161     DESCRIPTION: LIT Occ exempt wages (pthCurExemptWages)
--ERROR: 171     DESCRIPTION: LIT Other exempt wages (pthCurExemptWages)
--ERROR: 181     DESCRIPTION: LIT Res exempt wages (pthCurExemptWages)
--ERROR: 191     DESCRIPTION: LIT SD exempt wages (pthCurExemptWages)
--ERROR: 201     DESCRIPTION: LIT Wcc exempt wages (pthCurExemptWages)
--ERROR: 211     DESCRIPTION: LIT WorkIn exempt wages (pthCurExemptWages)

/*
SELECT CoID, EmpNo, Name, PayDate, DocNo, GenNumber, Code as TaxCode, t.TestId, pthCurExemptWages, MonAfter, pthCurExemptWages - MonAfter as Diff
,Case when PTHGenNumber is null then 'Missing iPtaxHist Record' else null end as Comment
FROM UaeReconTests t
JOIN UaeReconResults r on r.TestId = t.TestId
left JOIN iPTaxHist on PthGenNumber = r.GenNumber and PthTaxCode = Code and abs(pthCurExemptWages - MonAfter) > .05
WHERE t.AdjustmentColumn = 'pthCurExemptWages'
*/

UPDATE iPTaxHist
SET pthCurExemptWages  = MonAfter
FROM UaeReconTests t
JOIN UaeReconResults r on r.TestId = t.TestId
JOIN iPTaxHist on PthGenNumber = r.GenNumber and PthTaxCode = Code
WHERE t.AdjustmentColumn = 'pthCurExemptWages'
AND (EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMOBSYSTEMID = R.GENNUMBER) 
OR EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMQTDGENNUM = R.GENNUMBER))
/*===============================================================================================
(pthCurGrossWages)
================================================================================================*/
--ERROR: 3     DESCRIPTION: SDI gross wages (pthCurGrossWages)
--ERROR: 4     DESCRIPTION: SUI gross wages (pthCurGrossWages)
--ERROR: 5     DESCRIPTION: SIT Res gross wages (pthCurGrossWages)
--ERROR: 6     DESCRIPTION: SIT WorkIn gross wages (pthCurGrossWages)
--ERROR: 76     DESCRIPTION: USFIT gross wages (pthCurGrossWages)
--ERROR: 103     DESCRIPTION: SOC gross wages (pthCurGrossWages)
--ERROR: 104     DESCRIPTION: MED gross wages (pthCurGrossWages)
--ERROR: 106     DESCRIPTION: FUT gross wages (pthCurGrossWages)
--ERROR: 160     DESCRIPTION: LIT Occ gross wages (pthCurGrossWages)
--ERROR: 170     DESCRIPTION: LIT Other gross wages (pthCurGrossWages)
--ERROR: 180     DESCRIPTION: LIT Res gross wages (pthCurGrossWages)
--ERROR: 190     DESCRIPTION: LIT SD gross wages (pthCurGrossWages)
--ERROR: 200     DESCRIPTION: LIT Wcc gross wages (pthCurGrossWages)
--ERROR: 210     DESCRIPTION: LIT WorkIn gross wages (pthCurGrossWages)

/*
SELECT CoID, EmpNo, Name, PayDate, DocNo, GenNumber, Code as TaxCode, t.TestId, pthCurGrossWages, MonAfter, pthCurGrossWages - MonAfter as Diff
,Case when PTHGenNumber is null then 'Missing iPtaxHist Record' else null end as Comment
FROM UaeReconTests t
JOIN UaeReconResults r on r.TestId = t.TestId
left JOIN iPTaxHist on PthGenNumber = r.GenNumber and PthTaxCode = Code and abs(pthCurGrossWages - MonAfter) > .05
WHERE t.AdjustmentColumn = 'pthCurGrossWages'
*/

UPDATE iPTaxHist
SET pthCurGrossWages  = MonAfter
FROM UaeReconTests t
JOIN UaeReconResults r on r.TestId = t.TestId
JOIN iPTaxHist on PthGenNumber = r.GenNumber and PthTaxCode = Code
WHERE t.AdjustmentColumn = 'pthCurGrossWages'
AND (EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMOBSYSTEMID = R.GENNUMBER) 
OR EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMQTDGENNUM = R.GENNUMBER))

/*===============================================================================================
(pthCurHousing)
================================================================================================*/
--ERROR: 39     DESCRIPTION: SDI housing (pthCurHousing)
--ERROR: 40     DESCRIPTION: SUI housing (pthCurHousing)
--ERROR: 41     DESCRIPTION: SIT Res housing (pthCurHousing)
--ERROR: 42     DESCRIPTION: SIT WorkIn housing (pthCurHousing)
--ERROR: 125     DESCRIPTION: USFIT housing (pthCurHousing)
--ERROR: 127     DESCRIPTION: SOC housing (pthCurHousing)
--ERROR: 128     DESCRIPTION: MED housing (pthCurHousing)
--ERROR: 130     DESCRIPTION: FUT housing (pthCurHousing)
--ERROR: 165     DESCRIPTION: LIT Occ housing (pthCurHousing)
--ERROR: 175     DESCRIPTION: LIT Other housing (pthCurHousing)
--ERROR: 185     DESCRIPTION: LIT Res housing (pthCurHousing)
--ERROR: 195     DESCRIPTION: LIT SD housing (pthCurHousing)
--ERROR: 205     DESCRIPTION: LIT Wcc housing (pthCurHousing)
--ERROR: 215     DESCRIPTION: LIT WorkIn housing (pthCurHousing)

/*
SELECT CoID, EmpNo, Name, PayDate, DocNo, GenNumber, Code as TaxCode, t.TestId, pthCurHousing, MonAfter, pthCurHousing - MonAfter as Diff
,Case when PTHGenNumber is null then 'Missing iPtaxHist Record' else null end as Comment
FROM UaeReconTests t
JOIN UaeReconResults r on r.TestId = t.TestId
left JOIN iPTaxHist on PthGenNumber = r.GenNumber and PthTaxCode = Code and abs(pthCurHousing - MonAfter) > .05
WHERE t.AdjustmentColumn = 'pthCurHousing' 
*/

UPDATE iPTaxHist
SET pthCurHousing  = MonAfter
FROM UaeReconTests t
JOIN UaeReconResults r on r.TestId = t.TestId
JOIN iPTaxHist on PthGenNumber = r.GenNumber and PthTaxCode = Code
WHERE t.AdjustmentColumn = 'pthCurHousing'
AND (EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMOBSYSTEMID = R.GENNUMBER) 
OR EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMQTDGENNUM = R.GENNUMBER))

/*===============================================================================================
(pthResidentTaxableWages)
================================================================================================*/

/*
SELECT CoID, EmpNo, Name, PayDate, DocNo, GenNumber, Code as TaxCode, t.TestId, pthResidentTaxableWages, MonAfter, pthCurHousing - MonAfter as Diff
,Case when PTHGenNumber is null then 'Missing iPtaxHist Record' else null end as Comment
FROM UaeReconTests t
JOIN UaeReconResults r on r.TestId = t.TestId
left JOIN iPTaxHist on PthGenNumber = r.GenNumber and PthTaxCode = Code and abs(pthCurHousing - MonAfter) > .05
WHERE t.AdjustmentColumn = 'pthResidentTaxableWages' 
*/

UPDATE iPTaxHist
SET pthResidentTaxableWages  = MonAfter
FROM UaeReconTests t
JOIN UaeReconResults r on r.TestId = t.TestId
JOIN iPTaxHist on PthGenNumber = r.GenNumber and PthTaxCode = Code
WHERE t.AdjustmentColumn = 'pthResidentTaxableWages'
AND (EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMOBSYSTEMID = R.GENNUMBER) 
OR EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMQTDGENNUM = R.GENNUMBER))

/*===============================================================================================
(pthCurOtherWages)
================================================================================================*/
--ERROR: 69     DESCRIPTION: SDI other wages (pthCurOtherWages)
--ERROR: 70     DESCRIPTION: SUI other wages (pthCurOtherWages)
--ERROR: 71     DESCRIPTION: SIT Res other wages (pthCurOtherWages)
--ERROR: 72     DESCRIPTION: SIT WorkIn other wages (pthCurOtherWages)
--ERROR: 96     DESCRIPTION: USFIT other wages (pthCurOtherWages)
--ERROR: 98     DESCRIPTION: SOC other wages (pthCurOtherWages)
--ERROR: 99     DESCRIPTION: MED other wages (pthCurOtherWages)
--ERROR: 101     DESCRIPTION: FUT other wages (pthCurOtherWages)
--ERROR: 169     DESCRIPTION: LIT Occ other wages (pthCurOtherWages)
--ERROR: 179     DESCRIPTION: LIT Other other wages (pthCurOtherWages)
--ERROR: 189     DESCRIPTION: LIT Res other wages (pthCurOtherWages)
--ERROR: 199     DESCRIPTION: LIT SD other wages (pthCurOtherWages)
--ERROR: 209     DESCRIPTION: LIT Wcc other wages (pthCurOtherWages)
--ERROR: 219     DESCRIPTION: LIT WorkIn other wages (pthCurOtherWages)

/*
SELECT CoID, EmpNo, Name, PayDate, DocNo, GenNumber, Code as TaxCode, t.TestId, pthCurOtherWages, MonAfter, pthCurOtherWages - MonAfter as Diff
,Case when PTHGenNumber is null then 'Missing iPtaxHist Record' else null end as Comment
FROM UaeReconTests t
JOIN UaeReconResults r on r.TestId = t.TestId
left JOIN iPTaxHist on PthGenNumber = r.GenNumber and PthTaxCode = Code and abs(pthCurOtherWages - MonAfter) > .05
WHERE t.AdjustmentColumn = 'pthCurOtherWages' 
*/

UPDATE iPTaxHist
SET pthCurOtherWages  = MonAfter
FROM UaeReconTests t
JOIN UaeReconResults r on r.TestId = t.TestId
JOIN iPTaxHist on PthGenNumber = r.GenNumber and PthTaxCode = Code
WHERE t.AdjustmentColumn = 'pthCurOtherWages'
AND (EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMOBSYSTEMID = R.GENNUMBER) 
OR EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMQTDGENNUM = R.GENNUMBER))

/*===============================================================================================
(pthCurSec125)
================================================================================================*/
--ERROR: 51     DESCRIPTION: SDI Section 125 (pthCurSec125)
--ERROR: 52     DESCRIPTION: SUI Section 125 (pthCurSec125)
--ERROR: 53     DESCRIPTION: SIT Res Section 125 (pthCurSec125)
--ERROR: 54     DESCRIPTION: SIT WorkIn Section 125 (pthCurSec125)
--ERROR: 108     DESCRIPTION: SOC Section 125 (pthCurSec125)
--ERROR: 109     DESCRIPTION: MED Section 125 (pthCurSec125)
--ERROR: 111     DESCRIPTION: FUT Section 125 (pthCurSec125)
--ERROR: 148     DESCRIPTION: USFIT Section 125 (pthCurSec125)
--ERROR: 164     DESCRIPTION: LIT Occ Section 125 (pthCurSec125)
--ERROR: 174     DESCRIPTION: LIT Other Section 125 (pthCurSec125)
--ERROR: 184     DESCRIPTION: LIT Res Section 125 (pthCurSec125)
--ERROR: 194     DESCRIPTION: LIT SD Section 125 (pthCurSec125)
--ERROR: 204     DESCRIPTION: LIT Wcc Section 125 (pthCurSec125)
--ERROR: 214     DESCRIPTION: LIT WorkIn Section 125 (pthCurSec125)

/*
SELECT CoID, EmpNo, Name, PayDate, DocNo, GenNumber, Code as TaxCode, t.TestId, pthCurSec125, MonAfter, pthCurSec125 - MonAfter as Diff
,Case when PTHGenNumber is null then 'Missing iPtaxHist Record' else null end as Comment
FROM UaeReconTests t
JOIN UaeReconResults r on r.TestId = t.TestId
left JOIN iPTaxHist on PthGenNumber = r.GenNumber and PthTaxCode = Code and abs(pthCurSec125 - MonAfter) > .05
WHERE t.AdjustmentColumn = 'pthCurSec125' 
*/

UPDATE iPTaxHist
SET pthCurSec125  = MonAfter
FROM UaeReconTests t
JOIN UaeReconResults r on r.TestId = t.TestId
JOIN iPTaxHist on PthGenNumber = r.GenNumber and PthTaxCode = Code
WHERE t.AdjustmentColumn = 'pthCurSec125'
AND (EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMOBSYSTEMID = R.GENNUMBER) 
OR EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMQTDGENNUM = R.GENNUMBER))
and pthtaxcode <> 'USSOCER'


/*===============================================================================================
(pthCurTaxableGross)
================================================================================================*/
--ERROR: 21     DESCRIPTION: SDI taxable gross wages (pthCurTaxableGross)
--ERROR: 22     DESCRIPTION: SUI taxable gross wages (pthCurTaxableGross)
--ERROR: 23     DESCRIPTION: SIT Res taxable gross wages (pthCurTaxableGross)
--ERROR: 24     DESCRIPTION: SIT WorkIn taxable gross wages (pthCurTaxableGross)
--ERROR: 119     DESCRIPTION: USFIT taxable gross wages (pthCurTaxableGross)
--ERROR: 121     DESCRIPTION: SOC taxable gross wages (pthCurTaxableGross)
--ERROR: 122     DESCRIPTION: MED taxable gross wages (pthCurTaxableGross)
--ERROR: 124     DESCRIPTION: FUT taxable gross wages (pthCurTaxableGross)
--ERROR: 166     DESCRIPTION: LIT Occ taxable gross wages (pthCurTaxableGross)
--ERROR: 176     DESCRIPTION: LIT Other taxable gross wages (pthCurTaxableGross)
--ERROR: 186     DESCRIPTION: LIT Res taxable gross wages (pthCurTaxableGross)
--ERROR: 196     DESCRIPTION: LIT SD taxable gross wages (pthCurTaxableGross)
--ERROR: 206     DESCRIPTION: LIT Wcc taxable gross wages (pthCurTaxableGross)
--ERROR: 216     DESCRIPTION: LIT WorkIn taxable gross wages (pthCurTaxableGross)

/*
SELECT CoID, EmpNo, Name, PayDate, DocNo, GenNumber, Code as TaxCode, t.TestId, pthCurTaxableGross, MonAfter, pthCurTaxableGross - MonAfter as Diff
,Case when PTHGenNumber is null then 'Missing iPtaxHist Record' else null end as Comment
FROM UaeReconTests t
JOIN UaeReconResults r on r.TestId = t.TestId
left JOIN iPTaxHist on PthGenNumber = r.GenNumber and PthTaxCode = Code and abs(pthCurTaxableGross - MonAfter) > .05
WHERE t.AdjustmentColumn = 'pthCurTaxableGross' 
*/

UPDATE iPTaxHist
SET pthCurTaxableGross  = MonAfter
FROM UaeReconTests t
JOIN UaeReconResults r on r.TestId = t.TestId
JOIN iPTaxHist on PthGenNumber = r.GenNumber and PthTaxCode = Code
WHERE t.AdjustmentColumn = 'pthCurTaxableGross'
AND (EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMOBSYSTEMID = R.GENNUMBER) 
OR EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMQTDGENNUM = R.GENNUMBER))
/*===============================================================================================
(pthCurTaxableTips)
================================================================================================*/
--ERROR: 9     DESCRIPTION: SDI taxable tips (pthCurTaxableTips)
--ERROR: 10     DESCRIPTION: SUI taxable tips (pthCurTaxableTips)
--ERROR: 11     DESCRIPTION: SIT Res taxable tips (pthCurTaxableTips)
--ERROR: 12     DESCRIPTION: SIT WorkIn taxable tips (pthCurTaxableTips)
--ERROR: 78     DESCRIPTION: USFIT taxable tips (pthCurTaxableTips)
--ERROR: 80     DESCRIPTION: SOC taxable tips (pthCurTaxableTips)
--ERROR: 81     DESCRIPTION: MED taxable tips (pthCurTaxableTips)
--ERROR: 83     DESCRIPTION: FUT taxable tips (pthCurTaxableTips)
--ERROR: 168     DESCRIPTION: LIT Occ taxable tips (pthCurTaxableTips)
--ERROR: 178     DESCRIPTION: LIT Other taxable tips (pthCurTaxableTips)
--ERROR: 188     DESCRIPTION: LIT Res taxable tips (pthCurTaxableTips)
--ERROR: 198     DESCRIPTION: LIT SD taxable tips (pthCurTaxableTips)
--ERROR: 208     DESCRIPTION: LIT Wcc taxable tips (pthCurTaxableTips)
--ERROR: 218     DESCRIPTION: LIT WorkIn taxable tips (pthCurTaxableTips)

/*
SELECT CoID, EmpNo, Name, PayDate, DocNo, GenNumber, Code as TaxCode, pthCurTaxableTips, MonAfter, pthCurTaxableTips - MonAfter as Diff
,Case when PTHGenNumber is null then 'Missing iPtaxHist Record' else null end as Comment
FROM UaeReconTests t
JOIN UaeReconResults r on r.TestId = t.TestId
left JOIN iPTaxHist on PthGenNumber = r.GenNumber and PthTaxCode = Code and abs(pthCurTaxableTips - MonAfter) > .05
WHERE t.AdjustmentColumn = 'pthCurTaxableTips' 
*/

UPDATE iPTaxHist
SET pthCurTaxableTips  = MonAfter
FROM UaeReconTests t
JOIN UaeReconResults r on r.TestId = t.TestId
JOIN iPTaxHist on PthGenNumber = r.GenNumber and PthTaxCode = Code
WHERE t.AdjustmentColumn = 'pthCurTaxableTips'
AND (EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMOBSYSTEMID = R.GENNUMBER) 
OR EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMQTDGENNUM = R.GENNUMBER))
/*===============================================================================================
(pthCurTaxableWages)
================================================================================================*/
--ERROR: 57     DESCRIPTION: SDI taxable wages (pthCurTaxableWages)
--ERROR: 58     DESCRIPTION: SUI taxable wages (pthCurTaxableWages)
--ERROR: 59     DESCRIPTION: SIT Res taxable wages (pthCurTaxableWages)
--ERROR: 60     DESCRIPTION: SIT WorkIn taxable wages (pthCurTaxableWages)
--ERROR: 90     DESCRIPTION: USFIT taxable wages (pthCurTaxableWages)
--ERROR: 92     DESCRIPTION: SOC taxable wages (pthCurTaxableWages)
--ERROR: 93     DESCRIPTION: MED taxable wages (pthCurTaxableWages)
--ERROR: 95     DESCRIPTION: FUT taxable wages (pthCurTaxableWages)
--ERROR: 167     DESCRIPTION: LIT Occ taxable wages (pthCurTaxableWages)
--ERROR: 177     DESCRIPTION: LIT Other taxable wages (pthCurTaxableWages)
--ERROR: 187     DESCRIPTION: LIT Res taxable wages (pthCurTaxableWages)
--ERROR: 197     DESCRIPTION: LIT SD taxable wages (pthCurTaxableWages)
--ERROR: 207     DESCRIPTION: LIT Wcc taxable wages (pthCurTaxableWages)
--ERROR: 217     DESCRIPTION: LIT WorkIn taxable wages (pthCurTaxableWages)

/*
SELECT CoID, EmpNo, Name, PayDate, DocNo, GenNumber, Code as TaxCode, t.TestId, pthCurTaxableWages, MonAfter, pthCurTaxableWages - MonAfter as Diff
,Case when PTHGenNumber is null then 'Missing iPtaxHist Record' else null end as Comment
FROM UaeReconTests t
JOIN UaeReconResults r on r.TestId = t.TestId
left JOIN iPTaxHist on PthGenNumber = r.GenNumber and PthTaxCode = Code and abs(pthCurTaxableWages - MonAfter) > .05
WHERE t.AdjustmentColumn = 'pthCurTaxableWages' 
*/

UPDATE iPTaxHist
SET pthCurTaxableWages  = MonAfter
FROM UaeReconTests t
JOIN UaeReconResults r on r.TestId = t.TestId
JOIN iPTaxHist on PthGenNumber = r.GenNumber and PthTaxCode = Code
WHERE t.AdjustmentColumn = 'pthCurTaxableWages'
AND (EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMOBSYSTEMID = R.GENNUMBER) 
OR EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMQTDGENNUM = R.GENNUMBER))
/*===============================================================================================
(pthReportingTaxableWages)
================================================================================================*/
--ERROR: 272     DESCRIPTION: SIT Res reporting taxable wages (pthReportingTaxableWages)
--ERROR: 273     DESCRIPTION: SIT WorkIn reporting taxable wages (pthReportingTaxableWages)
--ERROR: 312     DESCRIPTION: USFIT reporting taxable wages (pthReportingTaxableWages)
--ERROR: 313     DESCRIPTION: SOC reporting taxable wages (pthReportingTaxableWages)
--ERROR: 314     DESCRIPTION: MED reporting taxable wages (pthReportingTaxableWages)

/*
SELECT CoID, EmpNo, Name, PayDate, DocNo, GenNumber, Code as TaxCode, t.TestId, pthReportingTaxableWages, MonAfter, pthReportingTaxableWages - MonAfter as Diff
,Case when PTHGenNumber is null then 'Missing iPtaxHist Record' else null end as Comment
FROM UaeReconTests t
JOIN UaeReconResults r on r.TestId = t.TestId
left JOIN iPTaxHist on PthGenNumber = r.GenNumber and PthTaxCode = Code and abs(pthReportingTaxableWages - MonAfter) > .05
WHERE t.AdjustmentColumn = 'pthReportingTaxableWages' 
*/

UPDATE iPTaxHist
SET pthReportingTaxableWages  = MonAfter
FROM UaeReconTests t
JOIN UaeReconResults r on r.TestId = t.TestId
JOIN iPTaxHist on PthGenNumber = r.GenNumber and PthTaxCode = Code
WHERE t.AdjustmentColumn = 'pthReportingTaxableWages'
AND (EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMOBSYSTEMID = R.GENNUMBER) 
OR EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMQTDGENNUM = R.GENNUMBER))
/*===============================================================================================
Summary fields on ipayregdata
(prgcheckamt
,prgnetamt
,prgtotdedamt
,prgtotearnamt
,prgtottaxamt)
================================================================================================*/
update ipayregdata
set 
prgcheckamt =  (select isnull(sum(pehcuramt),0.00) from ipearhist where pehgennumber = prggennumber)-
           (select isnull(sum(pdheecuramt),0.00) from ipdedhist where pdhgennumber = prggennumber) -
            (select isnull(sum(pthcurtaxamt),0.00) from iptaxhist where pthgennumber = prggennumber and pthisemployertax = 'N'),
prgnetamt = (select isnull(sum(pehcuramt),0.00) from ipearhist where pehgennumber = prggennumber)-
           (select isnull(sum(pdheecuramt),0.00) from ipdedhist where pdhgennumber = prggennumber) -
            (select isnull(sum(pthcurtaxamt),0.00) from iptaxhist where pthgennumber = prggennumber and pthisemployertax = 'N'),
prgtotdedamt = (select isnull(sum(pdheecuramt),0.00) from ipdedhist where pdhgennumber = prggennumber),
prgtotearnamt =(select isnull(sum(pehcuramt),0.00) from ipearhist where pehgennumber = prggennumber),
prgtottaxamt = (select isnull(sum(pthcurtaxamt),0.00) from iptaxhist where pthgennumber = prggennumber and pthisemployertax = 'N')
from ipayregdata
where prggennumber in (select GenNumber from UaeReconResults where TestID in ('73','77'))  
 AND (EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMOBSYSTEMID = prgGENNUMBER) 
OR EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMQTDGENNUM = prgGENNUMBER))



/*===============================================================================================
 Note, all updates below this line are commented out.  The TC will need to review the
 data and make decisions on which errors should be updated and/or documented on Issues and Assumptions
 document.
 =============================================================================================*/


/*===============================================================================================

Tax Amounts (pthCurTaxAmt)

This section is for review and potentially updating employer paid tax amount.  The folloing list
of error codes are a mixture of employee paid and employer paid taxes.  If you run the update
below only run employer paid tax amounts (c.CtcIsEmployerTax = 'Y'). 
================================================================================================*/ 

--ERROR: 136     DESCRIPTION: SOC employer tax amount (pthCurTaxAmt)
--ERROR: 137     DESCRIPTION: SOC employee tax amount (pthCurTaxAmt)
--ERROR: 138     DESCRIPTION: MED employee tax amount (pthCurTaxAmt)
--ERROR: 139     DESCRIPTION: MED employer tax amount (pthCurTaxAmt)
--ERROR: 140     DESCRIPTION: FUT tax amount (pthCurTaxAmt)
--ERROR: 144     DESCRIPTION: SDI employer tax amount (pthCurTaxAmt)
--ERROR: 145     DESCRIPTION: SUI employer tax amount (pthCurTaxAmt)
--ERROR: 146     DESCRIPTION: SDI employee tax amount (pthCurTaxAmt)
--ERROR: 147     DESCRIPTION: SUI employee tax amount (pthCurTaxAmt)
--ERROR: 257     DESCRIPTION: LIT Occ employer tax amount (pthCurTaxAmt)
--ERROR: 258     DESCRIPTION: LIT Occ employee tax amount (pthCurTaxAmt)
--ERROR: 286     DESCRIPTION: USFIT tax amount (pthCurTaxAmt)
--ERROR: 288     DESCRIPTION: SIT Res tax amount (pthCurTaxAmt)
--ERROR: 290     DESCRIPTION: SIT WorkIn tax amount (pthCurTaxAmt)
--ERROR: 292     DESCRIPTION: LIT Res employee tax amount (pthCurTaxAmt)
--ERROR: 293     DESCRIPTION: LIT Res employer tax amount (pthCurTaxAmt)
--ERROR: 296     DESCRIPTION: LIT WorkIn employee tax amount (pthCurTaxAmt)
--ERROR: 297     DESCRIPTION: LIT WorkIn employer tax amount (pthCurTaxAmt)
--ERROR: 301     DESCRIPTION: LIT SD employee tax amount (pthCurTaxAmt)
--ERROR: 302     DESCRIPTION: LIT SD employer tax amount (pthCurTaxAmt)
--ERROR: 304     DESCRIPTION: LIT Other employee tax amount (pthCurTaxAmt)
--ERROR: 305     DESCRIPTION: LIT Other employer tax amount (pthCurTaxAmt)
--ERROR: 307     DESCRIPTION: LIT Wcc employee tax amount (pthCurTaxAmt)
--ERROR: 308     DESCRIPTION: LIT Wcc employer tax amount (pthCurTaxAmt)
/*
SELECT CoID, EmpNo, Name, PayDate, DocNo, PthGenNumber, PthTaxCode, t.TestId, pthCurTaxAmt, MonAfter, pthCurTaxAmt - MonAfter as Diff, c.CtcIsEmployerTax
FROM UaeReconTests t
JOIN UaeReconResults r on r.TestId = t.TestId
JOIN iPTaxHist on PthGenNumber = r.GenNumber and PthTaxCode = Code
JOIN TaxCode c on Ctctaxcode = PthTaxCode
			  and c.CtcEffectiveDate = (select max(c2.CtcEffectiveDate)
										from TaxCode c2
										where c2.Ctctaxcode = c.Ctctaxcode
										  and c2.CtcHasBeenReplaced = c.CtcHasBeenReplaced)
			  and c.CtcHasBeenReplaced = 'N'
			  and c.CtcCOID = COID
WHERE t.AdjustmentColumn = 'pthCurTaxAmt' and abs(pthCurTaxAmt - MonAfter) > .05
  and c.CtcIsEmployerTax = 'Y'
  AND (EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMOBSYSTEMID = R.GENNUMBER) 
OR EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMQTDGENNUM = R.GENNUMBER))


*/
--BEGIN TRAN
UPDATE iPTaxHist
SET pthCurTaxAmt  = MonAfter
FROM UaeReconTests t
JOIN UaeReconResults r on r.TestId = t.TestId
JOIN iPTaxHist on PthGenNumber = r.GenNumber and PthTaxCode = Code
JOIN TaxCode c on Ctctaxcode = PthTaxCode
			  and c.CtcEffectiveDate = (select max(c2.CtcEffectiveDate)
										from TaxCode c2
										where c2.Ctctaxcode = c.Ctctaxcode
										  and c2.CtcHasBeenReplaced = c.CtcHasBeenReplaced)
			  and c.CtcHasBeenReplaced = 'N'
			  and c.CtcCOID = COID
WHERE t.AdjustmentColumn = 'pthCurTaxAmt'
  and c.CtcIsEmployerTax = 'Y'  -- only update an employer paid taxamount
  and (EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMOBSYSTEMID = R.GENNUMBER) 
         OR EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMQTDGENNUM = R.GENNUMBER))
  and PthTaxCode NOT IN ('USSOCER', 'USMEDER') -- DO NOT UPDATE SOC\MED ER AMOUNTS
  and T.TestID = '145' -- CHANGE TO THE TEST CODE YOU ARE choosing TO UPDATE 


  UPDATE iPTaxHist
SET pthCurTaxAmt  = MonAfter
FROM UaeReconTests t
JOIN UaeReconResults r on r.TestId = t.TestId
JOIN iPTaxHist on PthGenNumber = r.GenNumber and PthTaxCode = Code
JOIN TaxCode c on Ctctaxcode = PthTaxCode
			  and c.CtcEffectiveDate = (select max(c2.CtcEffectiveDate)
										from TaxCode c2
										where c2.Ctctaxcode = c.Ctctaxcode
										  and c2.CtcHasBeenReplaced = c.CtcHasBeenReplaced)
			  and c.CtcHasBeenReplaced = 'N'
			  and c.CtcCOID = COID
WHERE t.AdjustmentColumn = 'pthCurTaxAmt'
  and c.CtcIsEmployerTax = 'Y'  -- only update an employer paid taxamount
  and (EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMOBSYSTEMID = R.GENNUMBER) 
         OR EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMQTDGENNUM = R.GENNUMBER))
  and PthTaxCode NOT IN ('USSOCER', 'USMEDER') -- DO NOT UPDATE SOC\MED ER AMOUNTS
  and T.TestID = '146' -- CHANGE TO THE TEST CODE YOU ARE choosing TO UPDATE 

  UPDATE iPTaxHist
SET pthCurTaxAmt  = MonAfter
FROM UaeReconTests t
JOIN UaeReconResults r on r.TestId = t.TestId
JOIN iPTaxHist on PthGenNumber = r.GenNumber and PthTaxCode = Code
JOIN TaxCode c on Ctctaxcode = PthTaxCode
			  and c.CtcEffectiveDate = (select max(c2.CtcEffectiveDate)
										from TaxCode c2
										where c2.Ctctaxcode = c.Ctctaxcode
										  and c2.CtcHasBeenReplaced = c.CtcHasBeenReplaced)
			  and c.CtcHasBeenReplaced = 'N'
			  and c.CtcCOID = COID
WHERE t.AdjustmentColumn = 'pthCurTaxAmt'
  and c.CtcIsEmployerTax = 'Y'  -- only update an employer paid taxamount
  and (EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMOBSYSTEMID = R.GENNUMBER) 
         OR EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMQTDGENNUM = R.GENNUMBER))
  and PthTaxCode NOT IN ('USSOCER', 'USMEDER') -- DO NOT UPDATE SOC\MED ER AMOUNTS
  and T.TestID = '147' -- CHANGE TO THE TEST CODE YOU ARE choosing TO UPDATE 


/*
UPDATE iPTaxHist
SET pthCurTaxAmt  = MonAfter
FROM UaeReconTests t
JOIN UaeReconResults r on r.TestId = t.TestId
JOIN iPTaxHist on PthGenNumber = r.GenNumber and PthTaxCode = Code
JOIN TaxCode c on Ctctaxcode = PthTaxCode
			  and c.CtcEffectiveDate = (select max(c2.CtcEffectiveDate)
										from TaxCode c2
										where c2.Ctctaxcode = c.Ctctaxcode
										  and c2.CtcHasBeenReplaced = c.CtcHasBeenReplaced)
			  and c.CtcHasBeenReplaced = 'N'
			  and c.CtcCOID = COID
WHERE t.AdjustmentColumn = 'pthCurTaxAmt'
   and (EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMOBSYSTEMID = R.GENNUMBER)
         OR EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMQTDGENNUM = R.GENNUMBER))
  and PthTaxCode  IN ('NJSUIEE', 'NJWFDEE') -- DO NOT UPDATE SOC\MED ER AMOUNTS
  and T.TestID = '147' -- CHANGE TO THE TEST CODE YOU ARE choosing TO UPDATE

  --commit

UPDATE iPTaxHist
SET pthCurTaxAmt  = MonAfter
FROM UaeReconTests t
JOIN UaeReconResults r on r.TestId = t.TestId
JOIN iPTaxHist on PthGenNumber = r.GenNumber and PthTaxCode = Code
JOIN TaxCode c on Ctctaxcode = PthTaxCode
			  and c.CtcEffectiveDate = (select max(c2.CtcEffectiveDate)
										from TaxCode c2
										where c2.Ctctaxcode = c.Ctctaxcode
										  and c2.CtcHasBeenReplaced = c.CtcHasBeenReplaced)
			  and c.CtcHasBeenReplaced = 'N'
			  and c.CtcCOID = COID
WHERE t.AdjustmentColumn = 'pthCurTaxAmt'
   and (EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMOBSYSTEMID = R.GENNUMBER)
         OR EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMQTDGENNUM = R.GENNUMBER))
  and PthTaxCode  IN ('NJFLIEE','NJSDIEE') -- DO NOT UPDATE SOC\MED ER AMOUNTS
  and T.TestID = '146' -- CHANGE TO THE TEST CODE YOU ARE choosing TO UPDATE
  --commit
*/

--  Fix for USMEDER surcharge to reduce employer to limit
--  for employees that have earned over 200000 for the year.
--Use for OBYTD
update iptaxhist set pthCurTaxAmt = MonAfter
from UaeReconTests T
join UaeReconResults r on r.testid = t.testid
join iptaxhist on pthgennumber = r.gennumber and pthtaxcode = code
join ipayregkeys on prggennumber = r.gennumber and prgdocno = 'OBYTD'
where  t.AdjustmentColumn = 'pthCurTaxAmt'
and pthtaxcode = 'USMEDER'
and pthcurtaxablewages >= 200000  
and (EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMOBSYSTEMID = R.GENNUMBER) 
     OR EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMQTDGENNUM = R.GENNUMBER))

--use for OBQTD
update iptaxhist set pthCurTaxAmt = MonAfter
from UaeReconTests T
join UaeReconResults r on r.testid = t.testid
join iptaxhist on pthgennumber = r.gennumber and pthtaxcode = code
join ipayregkeys on prggennumber = r.gennumber and prgdocno = 'OBQTD'
where  t.AdjustmentColumn = 'pthCurTaxAmt'
and pthtaxcode = 'USMEDER'
and (select sum(pthcurtaxablewages)
      from  ptaxhist 
       where pthcoid =  prgcoid and ptheeid = prgeeid and substring(PthPerControl,1,4) = substring(PrgPerControl,1,4)) >= 200000
and (EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMOBSYSTEMID = R.GENNUMBER) 
     OR EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMQTDGENNUM = R.GENNUMBER))


-- FIX FOR COVID-19 Taxation 2020  JJ

UPDATE iPTaxHist
SET pthCurTaxAmt  = MonAfter
FROM UaeReconTests t
JOIN UaeReconResults r on r.TestId = t.TestId
JOIN iPTaxHist on PthGenNumber = r.GenNumber and PthTaxCode = Code
JOIN TaxCode c on Ctctaxcode = PthTaxCode
			  and c.CtcEffectiveDate = (select max(c2.CtcEffectiveDate)
										from TaxCode c2
										where c2.Ctctaxcode = c.Ctctaxcode
										  and c2.CtcHasBeenReplaced = c.CtcHasBeenReplaced)
			  and c.CtcHasBeenReplaced = 'N'
			  and c.CtcCOID = COID
WHERE t.AdjustmentColumn = 'pthCurTaxAmt'
  and c.CtcIsEmployerTax = 'Y'  -- only update an employer paid taxamount
  and (EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMOBSYSTEMID = R.GENNUMBER) 
         OR EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMQTDGENNUM = R.GENNUMBER))
  and PthTaxCode  IN ('USSOCER') -- DO NOT UPDATE SOC\MED ER AMOUNTS
  and T.TestID = '136' and r.gennumber in (select pehgennumber from ipearhist where pehtaxcategory in ('ESLPY','EFMLP'))




/*===============================================================================================

Uncollected Tax Amounts (pthGTLUncollectedTax)

This section is for review and potentially updating uncollected GTL tax amount.  
================================================================================================*/ 
--ERROR: 281     DESCRIPTION: SOC GTL uncollected tax (pthGTLUncollectedTax)
--ERROR: 284     DESCRIPTION: MED GTL uncollected tax (pthGTLUncollectedTax)
/*
SELECT CoID, EmpNo, Name, PayDate, DocNo, PthGenNumber, PthTaxCode, t.TestId, pthGTLUncollectedTax, MonAfter, pthGTLUncollectedTax - MonAfter as Diff
FROM UaeReconTests t
JOIN UaeReconResults r on r.TestId = t.TestId
JOIN iPTaxHist on PthGenNumber = r.GenNumber and PthTaxCode = Code
WHERE t.AdjustmentColumn = 'pthGTLUncollectedTax' and abs(pthGTLUncollectedTax - MonAfter) > .05
*/
--UPDATE iPTaxHist
--SET pthGTLUncollectedTax  = MonAfter
--FROM UaeReconTests t
--JOIN UaeReconResults r on r.TestId = t.TestId
--JOIN iPTaxHist on PthGenNumber = r.GenNumber and PthTaxCode = Code
--WHERE t.AdjustmentColumn = 'pthGTLUncollectedTax'
--AND (EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMOBSYSTEMID = R.GENNUMBER) 
--OR EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMQTDGENNUM = R.GENNUMBER))

/*===============================================================================================

Uncollected Tips Tax Amounts (pthTipsUncollectedTax)

This section is for review and potentially updating uncollected tips tax amount.  
================================================================================================*/ 
--ERROR: 282     DESCRIPTION: SOC tips uncollected tax (pthTipsUncollectedTax)
--ERROR: 285     DESCRIPTION: MED tips uncollected tax (pthTipsUncollectedTax)
/*
SELECT CoID, EmpNo, Name, PayDate, DocNo, PthGenNumber, PthTaxCode, t.TestId, pthTipsUncollectedTax, MonAfter, pthTipsUncollectedTax - MonAfter as Diff
FROM UaeReconTests t
JOIN UaeReconResults r on r.TestId = t.TestId
JOIN iPTaxHist on PthGenNumber = r.GenNumber and PthTaxCode = Code
WHERE t.AdjustmentColumn = 'pthTipsUncollectedTax' and abs(pthTipsUncollectedTax - MonAfter) > .05
*/
--UPDATE iPTaxHist
--SET pthTipsUncollectedTax  = MonAfter
--FROM UaeReconTests t
--JOIN UaeReconResults r on r.TestId = t.TestId
--JOIN iPTaxHist on PthGenNumber = r.GenNumber and PthTaxCode = Code
--WHERE t.AdjustmentColumn = 'pthTipsUncollectedTax'
--AND (EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMOBSYSTEMID = R.GENNUMBER) 
--OR EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMQTDGENNUM = R.GENNUMBER))


/*===============================================================================================

Uncollected Tax Amounts (pthUncollectedTax)

This section is for review and potentially updating uncollected tax amount.  
================================================================================================*/ 
--ERROR: 280     DESCRIPTION: SOC uncollected tax (pthUncollectedTax)
--ERROR: 283     DESCRIPTION: MED uncollected tax (pthUncollectedTax)
--ERROR: 287     DESCRIPTION: USFIT uncollected tax (pthUncollectedTax)
--ERROR: 289     DESCRIPTION: SIT Res uncollected tax (pthUncollectedTax)
--ERROR: 291     DESCRIPTION: SIT WorkIn uncollected tax (pthUncollectedTax)
--ERROR: 294     DESCRIPTION: LIT Res uncollected tax (pthUncollectedTax)
--ERROR: 298     DESCRIPTION: LIT WorkIn uncollected tax (pthUncollectedTax)
--ERROR: 300     DESCRIPTION: LIT Occ uncollected tax (pthUncollectedTax)
--ERROR: 303     DESCRIPTION: LIT SD uncollected tax (pthUncollectedTax)
--ERROR: 306     DESCRIPTION: LIT Other uncollected tax (pthUncollectedTax)
--ERROR: 309     DESCRIPTION: LIT Wcc uncollected tax (pthUncollectedTax)
--ERROR: 310     DESCRIPTION: SDI uncollected tax (pthUncollectedTax)
--ERROR: 311     DESCRIPTION: SUI uncollected tax (pthUncollectedTax)
/*
SELECT CoID, EmpNo, Name, PayDate, DocNo, PthGenNumber, PthTaxCode, t.TestId, pthUncollectedTax, MonAfter, pthUncollectedTax - MonAfter as Diff
FROM UaeReconTests t
JOIN UaeReconResults r on r.TestId = t.TestId
JOIN iPTaxHist on PthGenNumber = r.GenNumber and PthTaxCode = Code
WHERE t.AdjustmentColumn = 'pthUncollectedTax' and abs(pthUncollectedTax - MonAfter) > .05
AND (EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMOBSYSTEMID = R.GENNUMBER) 
OR EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMQTDGENNUM = R.GENNUMBER))
*/
--UPDATE iPTaxHist
--SET pthUncollectedTax  = MonAfter
--FROM UaeReconTests t
--JOIN UaeReconResults r on r.TestId = t.TestId
--JOIN iPTaxHist on PthGenNumber = r.GenNumber and PthTaxCode = Code
--WHERE t.AdjustmentColumn = 'pthUncollectedTax'
--AND (EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMOBSYSTEMID = R.GENNUMBER) 
--OR EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMQTDGENNUM = R.GENNUMBER))

/*===============================================================================================
(PthCurCalcAccum1) (PthCurCalcAccum2)
================================================================================================*/

--ERROR: 315     DESCRIPTION: MED Addl Medicare Tax wages (PthCurCalcAccum1)
--ERROR: 316     DESCRIPTION: MED Addl Medicare Tax amount (PthCurCalcAccum2)

/*
SELECT CoID, EmpNo, Name, PayDate, DocNo, GenNumber, Code as TaxCode, t.TestId, PthCurCalcAccum1, MonAfter, PthCurCalcAccum1 - MonAfter as Diff
,Case when PTHGenNumber is null then 'MED Addl Medicare Tax wages' else null end as Comment
FROM UaeReconTests t
JOIN UaeReconResults r on r.TestId = t.TestId
left JOIN iPTaxHist on PthGenNumber = r.GenNumber and PthTaxCode = Code and abs(PthCurCalcAccum1 - MonAfter) > .05
WHERE t.AdjustmentColumn = 'PthCurCalcAccum1' 
*/

UPDATE iPTaxHist
SET PthCurCalcAccum1  = MonAfter
FROM UaeReconTests t
JOIN UaeReconResults r on r.TestId = t.TestId
JOIN iPTaxHist on PthGenNumber = r.GenNumber and PthTaxCode = Code
WHERE t.AdjustmentColumn = 'PthCurCalcAccum1'
AND (EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMOBSYSTEMID = R.GENNUMBER) 
OR EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMQTDGENNUM = R.GENNUMBER))

/*
SELECT CoID, EmpNo, Name, PayDate, DocNo, GenNumber, Code as TaxCode, t.TestId, PthCurCalcAccum2, MonAfter, PthCurCalcAccum2 - MonAfter as Diff
,Case when PTHGenNumber is null then 'MED Addl Medicare Tax amount' else null end as Comment
FROM UaeReconTests t
JOIN UaeReconResults r on r.TestId = t.TestId
left JOIN iPTaxHist on PthGenNumber = r.GenNumber and PthTaxCode = Code and abs(PthCurCalcAccum2 - MonAfter) > .05
WHERE t.AdjustmentColumn = 'PthCurCalcAccum2' 
*/

UPDATE iPTaxHist
SET PthCurCalcAccum2  = MonAfter
FROM UaeReconTests t
JOIN UaeReconResults r on r.TestId = t.TestId
JOIN iPTaxHist on PthGenNumber = r.GenNumber and PthTaxCode = Code
WHERE t.AdjustmentColumn = 'PthCurCalcAccum2'
AND (EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMOBSYSTEMID = R.GENNUMBER) 
OR EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMQTDGENNUM = R.GENNUMBER))



/*
SELECT CoID, EmpNo, Name, PayDate, DocNo, GenNumber, Code as TaxCode, t.TestId, pthWorkInTaxableWages, MonAfter, pthWorkInTaxableWages - MonAfter as Diff
,'pthWorkInTaxableWages' as Comment
FROM UaeReconTests t
JOIN UaeReconResults r on r.TestId = t.TestId
left JOIN iPTaxHist on PthGenNumber = r.GenNumber and PthTaxCode = Code and abs(pthWorkInTaxableWages - MonAfter) > .05
WHERE t.AdjustmentColumn = 'pthWorkInTaxableWages' 
*/

UPDATE iPTaxHist
SET pthWorkInTaxableWages  = MonAfter
FROM UaeReconTests t
JOIN UaeReconResults r on r.TestId = t.TestId
JOIN iPTaxHist on PthGenNumber = r.GenNumber and PthTaxCode = Code
WHERE t.AdjustmentColumn = 'pthWorkInTaxableWages'
AND (EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMOBSYSTEMID = R.GENNUMBER) 
OR EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMQTDGENNUM = R.GENNUMBER))




UPDATE iPTaxHist
SET pthResidentTaxableWages  = MonAfter
FROM UaeReconTests t
JOIN UaeReconResults r on r.TestId = t.TestId
JOIN iPTaxHist on PthGenNumber = r.GenNumber and PthTaxCode = Code
WHERE t.AdjustmentColumn = 'pthResidentTaxableWages'
AND (EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMOBSYSTEMID = R.GENNUMBER) 
OR EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMQTDGENNUM = R.GENNUMBER))

/*===============================================================================================
(PthCurCalcAccum3) (PthCurCalcAccum4)  NOT NEEDED CURRENTLY,  REACH OUT TO TEAM LEAD IF YOU FEEL YOU NEED TO RUN THIS
================================================================================================*/

--ERROR:  	 DESCRIPTION: COVID Deferred SOC Tax wages (PthCurCalcAccum3)
--ERROR:  	 DESCRIPTION: COVID Deferred SOC Tax amount (PthCurCalcAccum4)

/*
UPDATE iPTaxHist
SET PthCurCalcAccum3  = MonAfter
FROM UaeReconTests t
JOIN UaeReconResults r on r.TestId = t.TestId
JOIN iPTaxHist on PthGenNumber = r.GenNumber and PthTaxCode = Code
WHERE t.AdjustmentColumn = 'PthCurCalcAccum3'
AND (EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMOBSYSTEMID = R.GENNUMBER) 
OR EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMQTDGENNUM = R.GENNUMBER))



UPDATE iPTaxHist
SET PthCurCalcAccum4  = MonAfter
FROM UaeReconTests t
JOIN UaeReconResults r on r.TestId = t.TestId
JOIN iPTaxHist on PthGenNumber = r.GenNumber and PthTaxCode = Code
WHERE t.AdjustmentColumn = 'PthCurCalcAccum4'
AND (EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMOBSYSTEMID = R.GENNUMBER) 
OR EXISTS(SELECT 1 FROM OBLDMAS WHERE OLMQTDGENNUM = R.GENNUMBER))



*/


/*

USSOCER  FIX FOR SEC125 ISSUE Sept 2020

begin tran
 update socer
 set socer.pthcursec125 = socee.pthcursec125  
from payreg
join iptaxhist socee on socee.pthgennumber=prggennumber and socee.pthtaxcode='USSOCEE'
join iptaxhist socer on socer.pthgennumber=prggennumber and socer.pthtaxcode='USSOCER'
 where isnull(socee.pthcursec125, 0.00) <> 0.00
-- commit


begin tran
 update socer
 set socer.PthCurD125 = socee.PthCurD125
from payreg
join iptaxhist socee on socee.pthgennumber=prggennumber and socee.pthtaxcode='USSOCEE'
join iptaxhist socer on socer.pthgennumber=prggennumber and socer.pthtaxcode='USSOCER'
 where isnull(socee.PthCurD125, 0.00) <> 0.00
-- commit rollback

*/






