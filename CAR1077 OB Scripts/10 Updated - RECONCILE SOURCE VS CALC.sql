/****************************************************************************************************************
Created by:  Michael Herman
Created on:  06/08/2022
Description: Script to reconcile ob_batch to t_batch 
Run this after calculating checks in Back Office
****************************************************************************************************************/

--Step 1:  Verify all are calced (all should be B)
---------------------------------------------------------------------------------------------------------
SELECT mbtpaygroup, 
       mbtiscalculated, 
       Count (*) [COUNT] 
FROM   m_batch 
GROUP  BY mbtpaygroup, 
          mbtiscalculated 
ORDER  BY mbtpaygroup, 
          mbtiscalculated


/* Review Errors with Earnings Details
SELECT mbtpaygroup, 
		mbtgennumber,
       mbtiscalculated, mbtcalcerrorstatus,
	   mbtnamefirst,mbtnamelast,EbtEarnCode,EbtLITOccCode
,EbtLITOtherCode
,EbtLITResidentCode
,EbtLitResidentCounty
,EbtLITSDCode
,EbtLITWccCode
,EbtLITWorkInCode
,EbtLitWorkInCounty
,EbtSITResidentStateCode
,EbtSITWorkInStateCode
,EbtStateSDI
,EbtStateSUI
FROM   m_batch 
join e_batch on mbtgennumber=ebtgennumber 
where mbtiscalculated='E'
ORDER  BY mbtcalcerrorstatus
*/
          
/****** RUN Everything below this point then Recalc your OB's in BO ******/         
/*1*/
UPDATE t_batch 
SET    tbtexemptions = 0, 
       tbtaddlexemptions = 0 
FROM   m_batch 
WHERE  mbtgennumber = tbtgennumber 
       AND mbtcalcerrorstatus LIKE '%UltiSitUGA: GASIT' 
       AND tbttaxcode = 'GASIT' 
/*2*/
UPDATE t_batch 
SET    tbtexemptfromtax = eetexemptfromtax 
FROM   m_batch 
       JOIN t_batch 
         ON tbtgennumber = mbtgennumber 
       JOIN emptax 
         ON mbteeid = eeteeid 
            AND mbtcoid = eetcoid 
            AND tbttaxcode = eettaxcode 
WHERE  Isnull(tbtexemptfromtax, 'x') <> Isnull(eetexemptfromtax, 'N') 
       AND mbtdocno IN ( 'OBYTD', 'OBQTD' ) 
       
UPDATE t_batch 
SET    tbtnotsubjecttotax = eetnotsubjecttotax 
FROM   m_batch 
       JOIN t_batch 
         ON tbtgennumber = mbtgennumber 
       JOIN emptax 
         ON mbteeid = eeteeid 
            AND mbtcoid = eetcoid 
            AND tbttaxcode = eettaxcode 
WHERE  Isnull(tbtnotsubjecttotax, 'x') <> Isnull(eetnotsubjecttotax, 'N') 
       AND mbtdocno IN ( 'OBYTD', 'OBQTD' ) 

UPDATE t_batch 
SET    TbtIsWorkIntaxCode = EetIsWorkIntaxCode, 
	tbtWorkInHasRecAgrWithRes= EetWorkInHasRecAgrWithRes   
FROM   m_batch 
       JOIN t_batch 
         ON tbtgennumber = mbtgennumber 
       JOIN emptax 
         ON mbteeid = eeteeid 
            AND mbtcoid = eetcoid 
            AND tbttaxcode = eettaxcode 
WHERE  ISNULL(TbtIsWorkIntaxCode , 'x') <> ISNULL(TbtIsWorkIntaxCode , 'N') 
       AND mbtdocno IN ('OBYTD', 'OBQTD') 


UPDATE t_batch 
SET    tbtWorkInHasRecAgrWithRes = EetWorkInHasRecAgrWithRes   
FROM   m_batch 
       JOIN t_batch 
         ON tbtgennumber = mbtgennumber 
       JOIN emptax 
         ON mbteeid = eeteeid 
            AND mbtcoid = eetcoid 
            AND tbttaxcode = eettaxcode 
WHERE  ISNULL(tbtWorkInHasRecAgrWithRes, 'x') <> ISNULL(tbtWorkInHasRecAgrWithRes, 'N') 
       AND mbtdocno IN ('OBYTD', 'OBQTD') 

/*3 If any updates from the above scripts then recalc the checks */

/*4*/ -- This is there by default
-- UPDATE ob_batch 
-- SET    obtusesrctaxamt = 'S', 
--       obtobtaxamt = obtsrctaxamt 
-- WHERE  obttaxcode LIKE 'usmed%' 
--        OR obttaxcode LIKE 'ussoc%'

/*5 - Gross Wages will update as calculated by the system*/
update t_batch set TbtNotSubjectToTax = 'Y'
from t_batch 
join ob_batch on ObtGenNumber = TbtGenNumber and ObtTaxCode = TbtTaxCode
where ObtOBTaxAmt = 0 
  and tbttaxcode like '%SIT'
  and exists (select'x' from ob_batch where ObtGenNumber = TbtGenNumber and ObtTaxCode <> TbtTaxCode and ObtTaxCode like '%SIT')

update e_batch set EbtLITSDCode = obttaxcode
FROM   ob_batch 
       JOIN m_batch 
         ON obtgennumber = mbtgennumber 
       JOIN e_batch 
         ON obtgennumber = ebtgennumber 
       JOIN company 
         ON cmpcoid = mbtcoid 
              join T_batch  
              on ObtGenNumber = TbtGenNumber and ObtTaxCode = TbtTaxCode
WHERE  obtsrcgrosswages <> obtufwcurgrosswages
and TbtNotSubjectToTax ='N' and  tbtexemptfromtax ='N' and tbtblocktaxamt ='N'
and obtSRCTaxAmt > 0 
and EbtLITSDCode is null
and exists (select 'x' from taxcode where ctctypeoftax = 'LIT' and ctclocaltype IN ('SD', 'OCCSD') and ctctaxcode = obttaxcode)

update e_batch set ebtlitresidentcode = obttaxcode
FROM   ob_batch 
       JOIN m_batch 
         ON obtgennumber = mbtgennumber 
       JOIN e_batch 
         ON obtgennumber = ebtgennumber 
       JOIN company 
         ON cmpcoid = mbtcoid 
              join T_batch  
              on ObtGenNumber = TbtGenNumber and ObtTaxCode = TbtTaxCode
WHERE  obtsrcgrosswages <> obtufwcurgrosswages
and TbtNotSubjectToTax ='N' and  tbtexemptfromtax ='N' and tbtblocktaxamt ='N'
and obtSRCTaxAmt > 0 
and ebtlitresidentcode is null
and exists (select 'x' from taxcode where ctctypeoftax = 'LIT' and ctclocaltype IN ('CITY', 'CNTY', 'LIT', 'BORO', 'VIL', 'TWP') AND ctcworkinonlytax <> 'Y' and ctctaxcode = obttaxcode)

update e_batch set EbtLITWorkInCode = obttaxcode
FROM   ob_batch 
       JOIN m_batch 
         ON obtgennumber = mbtgennumber 
       JOIN e_batch 
         ON obtgennumber = ebtgennumber 
       JOIN company 
         ON cmpcoid = mbtcoid 
              join T_batch  
              on ObtGenNumber = TbtGenNumber and ObtTaxCode = TbtTaxCode
WHERE  obtsrcgrosswages <> obtufwcurgrosswages
and TbtNotSubjectToTax ='N' and  tbtexemptfromtax ='N' and tbtblocktaxamt ='N'
and obtSRCTaxAmt > 0 
and ebtlitresidentcode is not null
and EbtLITWorkInCode is null
and exists (select 'x' from taxcode where ctctypeoftax = 'LIT' and ctclocaltype IN ('CITY', 'CNTY', 'LIT', 'BORO', 'VIL', 'TWP') AND ctcworkinonlytax <> 'Y' and ctctaxcode = obttaxcode)

update e_batch set EbtLITWorkInCode = obttaxcode
FROM   ob_batch 
       JOIN m_batch 
         ON obtgennumber = mbtgennumber 
       JOIN e_batch 
         ON obtgennumber = ebtgennumber 
       JOIN company 
         ON cmpcoid = mbtcoid 
              join T_batch  
              on ObtGenNumber = TbtGenNumber and ObtTaxCode = TbtTaxCode
WHERE  obtsrcgrosswages <> obtufwcurgrosswages
and TbtNotSubjectToTax ='N' and  tbtexemptfromtax ='N' and tbtblocktaxamt ='N'
and obtSRCTaxAmt > 0 
and ebtlitocccode is not null
and EbtLITWorkInCode is null
and exists (select 'x' from taxcode where ctctypeoftax = 'LIT' and ctclocaltype = 'OCC' and ctctaxcode = obttaxcode)


/*6 and 7 removed because these are done at Posting or Tax Recon*/

/*Now please recalculate the checks in BO then update batchs then run the following to see if there are any other gross wages that you might need to be aware of ***PLEASE DON'T SPIN YOUR WHEELS ON THIS STEP IN INITIALS***/
/*research script
SELECT distinct mbtpercontrol, 
       mbtempno, 
       obtgennumber, mbtnamefirst,mbtnamelast,
       obttaxcode, 
       obtsrcgrosswages    AS 'SourceGrossWages', 
       obtufwcurgrosswages AS 'CalcGrossWages', 
       obtobgrosswages     AS 'OBGrossWages',
       obtSRCTaxAmt, 
       tbtNotSubjectToTax , tbtexemptfromtax, tbtblocktaxamt ,TbtLocalType,ctctypeoftax
FROM   ob_batch 
       JOIN m_batch 
         ON obtgennumber = mbtgennumber 
       JOIN company 
         ON cmpcoid = mbtcoid 
              join T_batch  
              on ObtGenNumber = TbtGenNumber and ObtTaxCode = TbtTaxCode
        left outer join taxcode on ctctaxcode=tbttaxcode
WHERE  obtsrcgrosswages <> obtufwcurgrosswages
and TbtNotSubjectToTax ='N' and  tbtexemptfromtax ='N' and tbtblocktaxamt ='N'
and tbttaxcode not in ('MNFLAER','NYPFLEE') and  obtusesrcgrosswages = 'S' and obtSRCTaxAmt<>0
ORDER  BY obtgennumber, ob_batch.obttaxcode 
*/
/*IF ANY UPDATES DONE FROM THE GROSS WAGE OUTAGES ABOVE PLEASE RECALC CHECKS AND UPDATE BATCHES BEFORE POSTING*/


/* AND.. finally post! */
