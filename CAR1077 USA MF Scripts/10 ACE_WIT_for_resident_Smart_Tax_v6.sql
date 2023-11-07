/*****************************************************************************************************************
** Data Conversion Technical Team
**
** Name: ACE_WIT_for_resident_Smart_Tax_V6.sql
** Desc: This script will walk you through the process of using the WIT (Web Import Tool) to Smart Tax 
	and employee's address WHERE they live in a state that requires a resident local/SD/coutny.
** When to use: Recommend doing this for all Masterfile loads to ensure resident fields are populated correctly.
This process will also address updating local work-in tax codes that may need to be updated for non-resident since
as of 3/20/2020 the SP process is mostly just pulling the location resident tax code for the Masterfile load.
If a customer/SC is confident that all translations or tax codes provided in the Masterfile are correct this does not
have to be run as this process will overwrite employee resdient county and tax code where needed vis the WIT and Smart Tax.
!! If in doubt contact Manager OR Team Lead before running.
** Auth: Kevin Fretz
** Date: 3/13/2020
** Who did QA: [name(s) of person(s) that originally did QA]
** QA Date
**************************
** Change History
**************************
** CID	Date		Author		Description	
** ---  --------	--------	------------------------------------
** 001	3/13/2020	Kevin F		Standardized for submission format.
** 002	3/19/2020	Kevin F		More notes and revised logic based on local tax guide and working with Hsu.
** 003	3/20/2020	Kevin F		Added more comments and descriptions for the process and scripts to better explain the goal and need for each step.
** 004	9/9/2020	Kevin F		Added and updated Step 15 scripts for post process checks. 
** 005	11/11/2020	Kevin F		Added notes, a warning, and another report script so that KY SD tax codes can be added.
** 006	07/28/2021      Gene S	        Table compliant and move to SharePoint


WARNING!!!
** I highly recommend jumping to Step 10-A before running the process to ensure that Philly and IN locations are set correctly.
     IN should always have a LIT non-resident tax code. Philly locations should always have LIT resident and non-resident tax codes.
     I would also double-check with the SC if you have MD or IN residents to ensure all local tax codes are added before running the process.
	MD should get all LIT tax codes added.
	IN should get all LIT resident tax codes added (non-resident versions should be added per location).



******************************************************************************************************************/


/*
Notes ON testing AND confirmation of tax codes that work, things that don't work, AND other tips OR gotchas:

KF 2/19/2020
confirmed the WIT for NY will add NY001 AND NY003 
NY006 is a work tax code AND has to be loaded ON an insert script, customer needs to identify these employees

KF 3/13/2020
these are the states from the Sales Transition that have an idication of needed something for locals:
'AL','CO','IN','KY','MD','MI','MO','NM','NV','NY','OH','OR','PA','WA','WV'

KF 3/19/2020 notes
added DE as Wilmington residents get the resident local tax code regardless of where they work
removed the states that only apply locals if the employee works in that location. Since they do not care about residency, removing from this process.
revised list: ('IN','KY','MD','MI','MO','NY','OH','OR','PA','DE')

KF 3/24/2020 notes
Need to give a report on the states we are running through WIT where the address is a P.O.Box (mailing address) that the customer/SC will then have to 
manually Smart Tax since they need the physical address.

KF 9/9/2020 notes
OH will add LIT resident county and LIT resident code to empcomp. It will also add LIT resident tax code to emptax. The LIT resident tax code may not exist in the Taxcode table, so run the OH specific steps.
Component companies that have locations or employees living in MD need to have all MD counties and local tax codes added.
Component companies that have locations or employees living in IN should require the SC to add all IN local RESIDENT tax codes (the IN SIT filing # should be used for IN LIT filing # as I understand),
	otherwise the IN LIT resident tax code may not add via the WIT Smart Tax process. Added scripts for this in Step 15 to have IN LIT resident tax codes added per the counties in IN where employees live.


KF 11/11/2020 notes
Adding in a warning and extra commit before the WIT instructions to help ensure the WIT process is not slowed to a crawl by an uncommitted transaction.
Adding additional report for SC to add KY local taxes for the county any added SD tax code is in as you cannot directly add KY SD tax codes, but they become available after adding the corresponding LIT tax code.
Adding notes on how to export and sort the WIT results as any that say "cannot find address" are the true Smart Tax fails.
*/



/******************************************************************************************************************/

--Step 1. Preparing Data for Import
--The scipt below will pull the existing employee address as loaded from the Masterfile to be used with the WIT.
--The list of states has been refined to only look at the employees that live in a state that require a resident tax field (tax code or county).

SELECT '1' AS D,
'"cmpcompanycode","eecempno","eepaddressline1","eepaddressline2","eepaddresscity","eepaddressstate","eepaddresscountry","eepaddresszipcode"' AS DATA
UNION
SELECT '2' AS D,
'"'+LTRIM(RTRIM(cmpcompanycode))+'",'+
'"'+LTRIM(RTRIM(eecempno))+'",'+
'"'+LTRIM(RTRIM(ISNULL(eepaddressline1,'')))+'",'+
'"'+LTRIM(RTRIM(ISNULL(eepaddressline2,'')))+'",'+
'"'+LTRIM(RTRIM(ISNULL(eepaddresscity,'')))+'",'+
'"'+LTRIM(RTRIM(ISNULL(eepaddressstate,'')))+'",'+
'"'+LTRIM(RTRIM(ISNULL(eepaddresscountry,'')))+'",'+
'"'+LTRIM(RTRIM(ISNULL(eepaddresszipcode,'')))+'"' AS DATA
FROM (

SELECT cmpcompanycode, eecempno, eepaddressline1, eepaddressline2,
eepaddresscity, eepaddressstate, eepaddresscountry, eepaddresszipcode
FROM emppers 
JOIN empcomp ON eeceeid = eepeeid AND eeccoid = eephomecoid
JOIN company ON cmpcoid = eephomecoid
--WHERE eepaddressstate IN ('AL','CO','IN','KY','MD','MI','MO','NM','NV','NY','OH','OR','PA','WA','WV') --complete list of locals per list ON sales transition file
WHERE eepaddressstate IN ('DE','IN','KY','MD','MI','MO','NY','OH','OR','PA') --KF 3/19/2020 revised list
	--the logic below is to try to ignore P.O. Boxes as these are typically mailing address and not physical address
	AND (eepaddressline1 NOT LIKE '%p%o%box%' AND eepaddressline1 NOT LIKE 'p%o%box%' AND isnull(eepaddressline2,'') NOT LIKE '%p%o%box%' AND isnull(eepaddressline2,'') NOT LIKE 'p%o%box%')
	--only need non-terminated employees and current year terms
	AND (eecemplstatus <> 'T' OR (eecdateoftermination IS NOT NULL AND eecdateoftermination > '12/31/2019')) --only need non-termed for conversion year
--other helpful clauses to limit results
--AND EXISTS (SELECT 1 FROM lodepers l WHERE l.eepsessionid ='CONV' AND l.EepPendingUpdateID = empcomp.EecUDField15) -- set up for EecUDField15 = EepPendingUpdateID


--for any customer where the SIT res is not set up and you set SIT res to work-in SIT to do the MF import:
-- **please note this is currently not limited to only non-terms AND current year terms
UNION
SELECT cmpcompanycode, eecempno, eepaddressline1, eepaddressline2,
eepaddresscity, eepaddressstate, eepaddresscountry, eepaddresszipcode--, CtcTaxCode
FROM emppers p
JOIN empcomp ON eeceeid = p.eepeeid AND eeccoid = p.eephomecoid
JOIN company ON cmpcoid = p.eephomecoid AND eepaddresscountry = 'USA'
LEFT OUTER JOIN taxcode ON cmpcoid = CtcCOID AND (UPPER(LEFT(LTRIM(eepaddressstate),2))+'SIT') = CtcTaxCode
WHERE CtcTaxCode is null
--AND EXISTS (SELECT 1 FROM lodepers l WHERE l.eepsessionid ='CONV' AND l.EepPendingUpdateID = empcomp.EecUDField15)

) X ORDER BY 1
--

/* --very important **** must do the following:

-- ** NOTE: Copy only the "DATA" column of the results, paste into a text editor AND save the file as a .csv file **
		--****Do NOT click on the results and do "save as", the saved file has extra double quotes and the first column, both of which will fail in the web import***

*/

/******************************************************************************************************************/

--Step 2.  Create a custom table in SQL to store original data and to us for an update of Address line 1 if Smart Tax or WIT fails for an employee.

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'DBO.ACE_TEMP_WIT_Smart_Tax') AND type IN (N'U'))
	DROP TABLE DBO.ACE_TEMP_WIT_Smart_Tax


SELECT 
cmpcompanycode, 
eepeeid AS EEID, 
eephomecoid AS COID,
eecempno, 
eepaddressline1, 
eepaddressline2,
eepaddresscity, 
eepaddressstate, 
eepaddresscountry, 
eepaddresszipcode,
eepaddresscounty 
INTO DBO.ACE_TEMP_WIT_Smart_Tax
FROM (
SELECT cmpcompanycode, eepeeid, eephomecoid, eecempno, eepaddressline1, eepaddressline2, eepaddresscity, 
	eepaddressstate, eepaddresscountry, eepaddresszipcode, eepaddresscounty
FROM emppers 
JOIN empcomp ON eeceeid = eepeeid AND eeccoid = eephomecoid
JOIN company ON cmpcoid = eephomecoid
--WHERE eepaddressstate IN ('AL','CO','IN','KY','MD','MI','MO','NM','NV','NY','OH','OR','PA','WA','WV') --complete list of locals per list ON sales transition file
WHERE eepaddressstate IN ('IN','KY','MD','MI','MO','NY','OH','OR','PA','DE') --KF 3/19/2020 revised list
	--the logic below is to try to ignore P.O. Boxes as these are typically mailing address and not physical address
	AND (eepaddressline1 NOT LIKE '%p%o%box%' AND eepaddressline1 NOT LIKE 'p%o%box%' AND isnull(eepaddressline2,'') NOT LIKE '%p%o%box%' AND isnull(eepaddressline2,'') NOT LIKE 'p%o%box%')
	--only need non-terminated employees and current year terms
	AND (eecemplstatus <> 'T' OR (eecdateoftermination IS NOT NULL AND eecdateoftermination > '12/31/2019')) --only need non-termed for conversion year
--AND EXISTS (SELECT 1 FROM lodepers l WHERE l.eepsessionid ='CONV' AND l.EepPendingUpdateID = empcomp.EecUDField15)

--for any customer WHERE the SIT res is not set up AND you set SIT res to work-in SIT to do the MF import:
UNION
SELECT cmpcompanycode, eepeeid, eephomecoid, eecempno, eepaddressline1, eepaddressline2, eepaddresscity, 
	eepaddressstate, eepaddresscountry, eepaddresszipcode, eepaddresscounty
FROM emppers p
JOIN empcomp ON eeceeid = p.eepeeid AND eeccoid = p.eephomecoid
JOIN company ON cmpcoid = p.eephomecoid AND eepaddresscountry = 'USA'
--JOIN taxcode ON cmpcoid = CtcCOID AND (upper(left(ltrim(eepaddressstate),2))+'SIT') = CtcTaxCode
LEFT OUTER JOIN taxcode ON cmpcoid = CtcCOID AND (UPPER(LEFT(LTRIM(eepaddressstate),2))+'SIT') = CtcTaxCode
WHERE CtcTaxCode IS NULL
--AND EXISTS (SELECT 1 FROM lodepers l WHERE l.eepsessionid ='CONV' AND l.EepPendingUpdateID = empcomp.EecUDField15)

 ) x

--helpful script to review the results AND to keep track of the counts for how many employees will be updated
SELECT * FROM DBO.ACE_TEMP_WIT_Smart_Tax --

--helpful script to see the states that are part of the update
SELECT DISTINCT eepaddressstate FROM DBO.ACE_TEMP_WIT_Smart_Tax --

/******************************************************************************************************************/

--Step 3.  Update Addressline 1 in EmpPers. WIT and Smart Tax must see a change in order to update the employee.
--  See WARNING Below

BEGIN TRAN
UPDATE EmpPers
	SET eepaddressline1 = '.' WHERE EXISTS (SELECT 'True'                                                     
	FROM DBO.ACE_TEMP_WIT_Smart_Tax WHERE EEID = eepeeid AND COID = eephomecoid
	--AND eecempno IN ('') --to limit OR test
	)
 -- COMMIT 
  -- ROLLBACK
  -- 

/******************************************************************************************************************

--4. Complete the WIT import.

WARNING!!! WARNING!!! WARNING!!! WARNING!!! WARNING!!! WARNING!!! WARNING!!! WARNING!!! WARNING!!! WARNING!!! WARNING!!!

--You must make sure to commit before running the WIT otherwise it will crawl.
 COMMIT

Log into UKG Pro in impersonate. 
 
Fastest way to WIT is in the search box, type "import" and then select the Web Import Tool.
Follow the word document ("WIT Smart Tax for Change Name Address output (kh).docx") 
	**When setting up WIT and making sure smart tax is on for name and address, double check that the path (a few lines up) has your environment and AR#, if not ask the SC to update the path so the import does not fail.
to make sure the address will be Smart Taxed, validation mode is off,
the template is loaded, verified, and activated. Then upload the file. Once the import is completed, move on.

Once the import is complete, recommend selecting "Export to Excel (*.xlsx)" from the "actions" dropdown on the results page.
Give this to the SC first. Recommend filtering on column J (Messages) for "not found" and "not set" to see where Smart Tax failed.

******************************************************************************************************************/

--Step 5.  Create a temp table of any employee that failed to be updated by WIT/Smart Tax. These will need to
-- have their address updated back to the oridignal value for Address Line 1 as well as provide a report
-- to the SC/Customer on employees that should be manually Smart Taxed.

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'DBO.ACE_TEMP_smart_tax_needed') AND type IN (N'U'))
	DROP TABLE DBO.ACE_TEMP_smart_tax_needed

--only need to keep track of addresses that failed to update
SELECT eecempno, eepnamelast, eepnamefirst, eecemplstatus 
INTO DBO.ACE_TEMP_smart_tax_needed
FROM emppers 
JOIN empcomp ON eeceeid = eepeeid AND eephomecoid = eeccoid 
WHERE eepaddressline1 = '.'
-- 
select cmpcompanycode, cmpcompanyname from company 

select * from ACE_TEMP_smart_tax_needed

/******************************************************************************************************************/

--Step 6.  Fix all employees that failed to update with WIT/Smart tax so that their Address Line 1 is set back to the original.

BEGIN TRAN
UPDATE EmpPers
	SET eepaddressline1 = (SELECT [ACE_TEMP_WIT_Smart_Tax].[eepaddressline1]                                                  
		FROM DBO.ACE_TEMP_WIT_Smart_Tax WHERE EEID = eepeeid AND COID = eephomecoid)
	WHERE eepaddressline1 LIKE '.'
--COMMIT ROLLBACK
--2

--helpful script to see what the WIT/Smart Tax updated on employees
SELECT EecLITOccCode, EecLITOtherCode, EecLITResidentCode, EecLITResidentCounty, EecLITSDCode
FROM EMPCOMP
JOIN EMPPERS ON EECEEID = EEPEEID
WHERE EXISTS (SELECT 'True' FROM DBO.ACE_TEMP_WIT_Smart_Tax WHERE EEID = eepeeid AND COID = eephomecoid) 
AND eepaddressline1 <> '.'
--AND LTRIM(RTRIM(ISNULL(EecLITSDCode,''))) NOT IN ('',' ') --10


/******************************************************************************************************************/

--Step 7. Back up empcomp and emptax after web import as going into back office AND looking at taxes may delete what smart tax added
	--this also captures empcomp as it is after the WIT before further updates are done

DECLARE @BackupQuery VARCHAR(1000), @table VARCHAR(50)
SET @table = 'EMPCOMP' --table you are backing up
SET @BackupQuery = 'SELECT * INTO DBO.ACEbkup_'+@table+ CONVERT(VARCHAR(10),GetDate(),112) + '_' + RIGHT('0' + CAST(DATEPART(hh,GetDate()) AS VARCHAR(2)),2) + RIGHT('0' + CAST(DATEPART(mi,GetDate()) AS VARCHAR(2)),2) +' FROM ' + @table
EXEC(@BackupQuery)
PRINT @BackupQuery

--

--DECLARE @BackupQuery VARCHAR(1000), @table VARCHAR(50)
SET @table = 'EMPTAX' --table you are backing up
SET @BackupQuery = 'SELECT * INTO DBO.ACEbkup_'+@table+ CONVERT(VARCHAR(10),GetDate(),112) + '_' + RIGHT('0' + CAST(DATEPART(hh,GetDate()) AS VARCHAR(2)),2) + RIGHT('0' + CAST(DATEPART(mi,GetDate()) AS VARCHAR(2)),2) +' FROM ' + @table
EXEC(@BackupQuery)
PRINT @BackupQuery
 

/******************************************************************************************************************/

--Step 8. Report for SC/Customer for employees that need to be manually Smart Taxed.

SELECT cmpcompanycode, cmpcompanyname, eecempno, eepnamelast, eepnamefirst, eecemplstatus,
	EepAddressLine1, EepAddressLine2, EepAddressCity, EepAddressState, EepAddressZipCode, EepAddressCounty, EepAddressCountry
FROM emppers 
JOIN empcomp ON eeceeid = eepeeid AND eephomecoid = eeccoid 
JOIN company ON eeccoid = cmpcoid
WHERE EXISTS (SELECT * FROM DBO.ACE_TEMP_smart_tax_needed a WHERE a.eecempno = empcomp.eecempno)
AND EepAddressCountry = 'USA'
-- 

/******************************************************************************************************************/

--Step 9. Double check that no eepaddressline1 = '.'

SELECT * FROM emppers WHERE eepaddressline1 = '.' 
-- 
-- *** should have 0 results ***

/******************************************************************************************************************/

--Step 10. In this section we are looking at location set up that have local resident and non-resident tax codes.
/*
--New process as of 3/20/2020 and is being tested and vetted.--
The assumption is the Masterfile load (SP and/or scripting process) is mostly using the LocLITResWorkInCode
from location setup for loading employees. To the best of my knowledge there is nothing in place to switch 
the employee to the LocLITNonResWorkInCode when needed. In this section we are attempting to address this issue
so that employees get the correct LITRESWorkIn tax code. Right now we are only addressing changes to employees
that were also Smart Taxed with WIT, but this may need to be rewritten/expanded as testing and time goes on.

*/

 
--Step 10-A. Review the location set up as all steps below are looking back to the taxes in the location setup.

SELECT LocCode,LocSITWorkInStateCode,  LocLITResWorkInCode, LocLITNonResWorkInCode, LocAddressCity 
FROM location 
WHERE (LocLITResWorkInCode <> LocLITNonResWorkInCode)
OR (LocAddressCity LIKE 'Louisville%' OR LocAddressCity LIKE 'Philadelphia%' OR LocSITWorkInStateCode = 'INSIT')
--Philladelphia and Louisville always need to have res and non-res filled out. IN needs to always have non-res and res should be NULL.

update location set LocLITResWorkInCode = NULL 
--select loccode, LocSITWorkInStateCode, * 
FROM location where  LocSITWorkInStateCode = 'INSIT' and LocLITResWorkInCode is not null 


--Step 10-B. Create a temp table that will store existing emptax data from the Masterfile load for the local work-in tax where there
-- is a need to update the employee to add the LocLITNonResWorkInCode

--drop the temp table if it exists
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'DBO.ACE_TEMP_LITResWorkInCode_fix') AND type IN (N'U'))
	DROP TABLE DBO.ACE_TEMP_LITResWorkInCode_fix

--create the temp table that will store emptax data for later updates
SELECT EEID, COID, eettaxcode AS Old_taxcode, LocLITNonResWorkInCode AS New_taxcode,
	EetAddlExemptions, EetBlockTaxAmt, EetExemptFromTax, EetExemptions, EetExtraTaxDollars,
	EetExtraTaxMethod, EetFilingStatus, EetIsEmpCompTaxCode, EetIsResidentTaxCode, EetIsWorkInTaxCode,
	EetNotSubjectToTax, EetRegWageTaxMethod, EetResWageNotSubjToWorkIn, EetSuppAddlTaxPct,
	EetSuppWageTaxMethod, EetWorkInHasRecAgrWithRes, EetDependentAmt, EetOtherIncome, EetDeductionAmt
INTO DBO.ACE_TEMP_LITResWorkInCode_fix
FROM empmloc
JOIN DBO.ACE_TEMP_WIT_Smart_Tax ON emlCoID = COID AND emlEEID = EEID
JOIN empcomp ON eecCoID = COID AND eecEEID = EEID AND emlIsPrimary = 'Y' AND emlCode = EecLocation
JOIN location ON emlCode = LocCode 
	AND LocSITWorkInStateCode NOT IN ('INSIT') --KF 3/19/2020 removing IN as all IN residents should have their own LIT tax code. All non-residents should have the location non-resident LIT code from the location. **Possible follow up for Hsu, if the ee has the non-res IN LIT tax code, does it need to be flagged as "not subject to" or will system know what to do?
	/*AND LocSITWorkInStateCode IN ('OHSIT','COSIT','KYSIT','MOSIT','PASIT','NMSIT','ORSIT','WASIT','INSIT','MISIT')*/ --KF 3/19/2020 removed
JOIN emptax ON LocLITResWorkInCode = eettaxcode AND eetCoID = COID AND eetEEID = EEID
WHERE LocLITResWorkInCode IS NOT NULL AND LocLITNonResWorkInCode IS NOT NULL AND LocLITResWorkInCode <> LocLITNonResWorkInCode
AND EecLITResidentCode IS NOT NULL AND EecLITResidentCode <> LocLITResWorkInCode
--0

--Step 10-C. Now we need to update empmloc (for the primary location only **assumes empcomp.eeclocation is the primary location) and empcomp to reflect 
-- the change from LocLITResWorkInCode to LocLITNonResWorkInCode. 
-- We only need to update empmloc where the location has two different LIT work-in codes (resident and non-resident) and the smart tax EecLITResidentCode <> LocLITResWorkInCode

BEGIN TRAN
UPDATE empmloc SET emlLITWorkInCode = LocLITNonResWorkInCode -- select emlLITWorkInCode, LocLITNonResWorkInCode, EecLITResidentCode
FROM empmloc
JOIN DBO.ACE_TEMP_WIT_Smart_Tax ON emlCoID = COID AND emlEEID = EEID
JOIN empcomp ON eecCoID = COID AND eecEEID = EEID AND emlIsPrimary = 'Y' AND emlCode = EecLocation
JOIN location ON emlCode = LocCode /*AND LocSITWorkInStateCode IN ('OHSIT','COSIT','KYSIT','MOSIT','PASIT','NMSIT','ORSIT','WASIT','INSIT','MISIT')*/
WHERE LocLITResWorkInCode IS NOT NULL AND LocLITNonResWorkInCode IS NOT NULL AND LocLITResWorkInCode <> LocLITNonResWorkInCode
AND EecLITResidentCode IS NOT NULL AND EecLITResidentCode <> LocLITResWorkInCode
and emlLITWorkInCode <> LocLITNonResWorkInCode --added
--COMMIT ROLLBACK
--0

BEGIN TRAN
UPDATE empcomp SET EecLITWorkInCode = LocLITNonResWorkInCode -- select EecLITWorkInCode, LocLITNonResWorkInCode, EecLITResidentCode
FROM empcomp
JOIN DBO.ACE_TEMP_WIT_Smart_Tax ON eecCoID = COID AND eecEEID = EEID
JOIN location ON EecLocation = LocCode /*AND LocSITWorkInStateCode IN ('OHSIT','COSIT','KYSIT','MOSIT','PASIT','NMSIT','ORSIT','WASIT','INSIT','MISIT')*/
WHERE LocLITResWorkInCode IS NOT NULL AND LocLITNonResWorkInCode IS NOT NULL AND LocLITResWorkInCode <> LocLITNonResWorkInCode
AND EecLITResidentCode IS NOT NULL AND EecLITResidentCode <> LocLITResWorkInCode
and EecLITWorkInCode <> LocLITNonResWorkInCode --added
--COMMIT ROLLBACK
--0


--Step 10-D. Now we need to update the old emptax record for the tax code that loaded with the Masterfile that the employee does not need.
-- Right now "not subject to" is being set to 'Y' instead of deleting. If needed this can be changed to delete.

BEGIN TRAN
UPDATE emptax SET EetNotSubjectToTax = 'Y'
WHERE EXISTS (SELECT 1 FROM DBO.ACE_TEMP_LITResWorkInCode_fix WHERE eetCoID = COID AND eetEEID = EEID AND eettaxcode = Old_taxcode)
--COMMIT ROLLBACK
--

--Step 10-E. Now run the SP to add in the non-resident tax code to emptax for employees.

BEGIN TRAN
DECLARE @COID CHAR(5), @EEID CHAR(12), @TaxCode CHAR(8)
DECLARE NeedTaxCsr CURSOR FOR

	SELECT COID, EEID, New_taxcode TAXCODE 
	FROM DBO.ACE_TEMP_LITResWorkInCode_fix
	WHERE NOT EXISTS (SELECT 1 FROM EMPTAX WHERE EETEEID = EEID AND EETCOID = COID AND New_taxcode = EETTAXCODE)
	
	
OPEN NeedTaxCsr

FETCH NEXT FROM NeedTaxCsr INTO @COID, @EEID, @TaxCode
WHILE @@fetch_status = 0
  BEGIN
	EXEC dbo.ACEsp_OBCodes_AddEmpTaxRecord @EEID, @COID, @TaxCode 
	FETCH NEXT FROM NeedTaxCsr INTO @COID, @EEID, @TaxCode
  END
CLOSE NeedTaxCsr
DEALLOCATE NeedTaxCsr
--COMMIT ROLLBACK
--

--Step 10-F. Now that LocLITNonResWorkInCode is in emptax, update the values we originally stored from LocLITResWorkInCode
-- this should ensure the local work-in tax code keeps the filing status, exemptions, etc. that were originally loaded.

BEGIN TRAN
UPDATE EMPTAX SET
EetAddlExemptions = A.EetAddlExemptions,
EetBlockTaxAmt = A.EetBlockTaxAmt,
EetExemptFromTax = A.EetExemptFromTax,
EetExemptions = A.EetExemptions,
EetExtraTaxDollars = A.EetExtraTaxDollars,
EetExtraTaxMethod = A.EetExtraTaxMethod,
EetFilingStatus = A.EetFilingStatus,
EetIsEmpCompTaxCode = 'Y', --A.EetIsEmpCompTaxCode,
EetIsResidentTaxCode = CASE WHEN eettaxcode = EecLITResidentCode THEN 'Y' ELSE 'N' END, --A.EetIsResidentTaxCode,
EetIsWorkInTaxCode = 'Y', --A.EetIsWorkInTaxCode,
EetNotSubjectToTax = A.EetNotSubjectToTax,
--EetRegWageTaxMethod = A.EetRegWageTaxMethod,
EetResWageNotSubjToWorkIn = A.EetResWageNotSubjToWorkIn,
EetSuppAddlTaxPct = A.EetSuppAddlTaxPct,
--EetSuppWageTaxMethod = A.EetSuppWageTaxMethod,
EetWorkInHasRecAgrWithRes = A.EetWorkInHasRecAgrWithRes,
EetDependentAmt = A.EetDependentAmt,
EetOtherIncome = A.EetOtherIncome,
EetDeductionAmt = A.EetDeductionAmt
FROM EMPTAX
JOIN DBO.ACE_TEMP_LITResWorkInCode_fix A ON A.EEID = EETEEID AND A.COID = EETCOID AND A.New_taxcode = eettaxcode
JOIN EMPCOMP ON A.EEID = EECEEID AND A.COID = EECCOID
--COMMIT ROLLBACK
--


/*
This section is commented out as it was helpful in the original design of the process. Below is a helpful
location script and some result examples. This is informational only and may eventually be deleted once
the process has been fully vetted and verified.

SELECT LocLITResWorkInCode, LocLITNonResWorkInCode, LocAddressCity, LocCode 
FROM location 
WHERE (LocLITResWorkInCode <> LocLITNonResWorkInCode)
OR (LocAddressCity LIKE 'Louisville%' OR LocAddressCity LIKE 'Philadelphia%' OR LocAddressState = 'INSIT')


 --some examples of the location having LocLITResWorkInCode <> LocLITNonResWorkInCode
LocLITResWorkInCode		LocLITNonResWorkInCode		LocAddressCity
PA100018				PA100012					Philadelphia
PA103006				PA110007					Pittsburgh
NY003   				NY004   					New York **HSU said this location set up is invalid
NY003   				NY004  					 	Yonkers
IN005   				IN006   					Aurora
IN005   				IN006   					Greendale
IN085   				IN136   					Versailles
OH1006  				OH1656  					Cincinnati
KY001   				KY002   					Louisville
IN089   				IN140   					Angola
MI003				   	MI004   					Grand Rapids
MI054				   	MI055   					East Lansing
WALIEE  				WALIEP  					Spokane	**HSU said WALIEP is obsolete, make sure this is not on any ee for emptax
COGRNEE 				COGRNEP 					Greenwood Village
*/



/******************************************************************************************************************/



--Step 11. Per Hsu, any SD tax code on employees from the Masterfile load or added from Smart Tax via WIT needs to be added to the component company.
-- The select below will give the SC a list of tax codes added by smart tax to be added to the component companies and should be reviewed with customers
-- and need to be added to UltiPro or the employees will need to be manually udpated.

--All SD tax codes should be on employees and added to taxcode for the component company. Customers should also be aware of what SD codes need to be added.
SELECT cmpCOMPANYCODE, t.mtctaxcode, t.MtcTaxCodeDesc, t.MtcState, t.MtcCounty, t.MtcCountyCode, t.MtcTypeOfTax, t.mtclocaltype, t.MtcStandardCode,
	(SELECT ISNULL(t1.mtctaxcode,'') FROM ultipro_system..TxCdMast t1 
		WHERE GETDATE() BETWEEN t1.MtcEffectiveDate AND t1.MtcEffectiveStopDate AND t1.MtcHasBeenReplaced = 'N'
		AND t1.MtcState = t.MtcState AND t1.MtcCounty = t.MtcCounty AND t.mtctaxcode = t1.MtcLinkedSD) as Linked_LIT_to_add --KF this was added as KY SD cannot be added, you need to add the LIT code instead.
-- SELECT *
FROM ultipro_system..TxCdMast t
JOIN (
SELECT DISTINCT eeccoid, EecLITSDCode AS taxcode
FROM empcomp (NOLOCK) 
JOIN emppers (NOLOCK) ON eeceeid = eepeeid
JOIN emptax (NOLOCK) ON eeceeid = eeteeid AND eeccoid = eetcoid
WHERE eepaddressline1 <> '.' 
AND LTRIM(RTRIM(ISNULL(EecLITSDCode,''))) NOT IN ('',' ')
--AND EXISTS (SELECT 'True' FROM DBO.ACE_TEMP_WIT_Smart_Tax WHERE EEID = eeceeid AND COID = eeccoid) --KF 3/19/2020 removed the temp table reference as all SD tax codes should be added where needed
AND NOT EXISTS (SELECT 1 FROM TaxCode (NOLOCK) WHERE (ctcTaxCode = eettaxcode) AND (eeccoid = ctccoid))
) t2 ON mtctaxcode = t2.taxcode
JOIN company ON eeccoid = cmpcoid
WHERE GETDATE() BETWEEN t.MtcEffectiveDate AND t.MtcEffectiveStopDate AND t.MtcHasBeenReplaced = 'N'
--0

/******************************************************************************************************************/

--Step 12. Here we are providing a report on all local resident tax codes added to employees. Again, the SC should review with the customer
-- as it may be these are needed. Most PA resident local codes do not need to be added, so make sure the SC is aware of this (a false error on Employee Smart QA as well so PA is excluded).


SELECT cmpCOMPANYCODE, mtctaxcode, MtcTaxCodeDesc, MtcState, MtcCounty, MtcCountyCode, MtcTypeOfTax, mtclocaltype, MtcStandardCode, eecempno, eecemplstatus, eepnamefirst, eepnamelast --report with EE data
-- SELECT DISTINCT cmpCOMPANYCODE, mtctaxcode, MtcTaxCodeDesc, MtcState, MtcCounty, MtcCountyCode, MtcTypeOfTax, mtclocaltype, MtcStandardCode --distinct report of just tax codes
-- SELECT *
FROM ultipro_system..TxCdMast 
JOIN (
SELECT DISTINCT eeccoid, EecLITResidentCode AS taxcode, eecempno, eecemplstatus, eepnamefirst, eepnamelast
FROM empcomp (NOLOCK) 
JOIN emppers (NOLOCK) ON eeceeid = eepeeid
WHERE eepaddressline1 <> '.' AND LTRIM(RTRIM(ISNULL(EecLITResidentCode,''))) NOT IN ('',' ')
--AND EXISTS (SELECT 'True' FROM DBO.ACE_TEMP_WIT_Smart_Tax WHERE EEID = eeceeid AND COID = eeccoid)
AND NOT EXISTS (SELECT 1 FROM TaxCode (NOLOCK) 
                  WHERE (ctcTaxCode = EecLITResidentCode) AND (eeccoid = ctccoid)) 
                      AND EecLITResidentCode NOT LIKE 'PA%' --KF excluding PA as resident locals are not needed (location drives taxation)
) t ON mtctaxcode = taxcode
JOIN company ON eeccoid = cmpcoid
WHERE GETDATE() BETWEEN MtcEffectiveDate AND MtcEffectiveStopDate 
AND MtcHasBeenReplaced = 'N'
--0

--give the report to the SC/Customer along with a message..."Smart Tax added these code that are not set up. You need to review and add the tax codes if they need to be applied. If they are not being applied, they may have to be removed from the employee (OH is one such state)."

--*** Special note: the WIT Smart Tax import adds LIT resident county and tax code to empcomp as well as adds LIT resident tax code to empcomp even though the tax code is not in the taxcode table for the coid. 
	-- This is why the SC/customer review is needed and the next steps to update emptax and empcomp if they do not want to add the tax codes.

/******************************************************************************************************************/

--Step 13. In this step we are removing tax codes from employees where the tax code does not exist for the component company.
-- As far as timing goes, I suggest the report in Step 12 be provided first and allow the SC and customer to review.
-- Once the report from Step 12 has been addressed, move forward with this step.

--*** This section has to be run before parallels at the very least. ****
-- This process comes from Hsu as OH employees would cause payrolls to error out or not open as the tax code did not exist.
-- As of 3/20/2020, it is only OH that has this issue, so that is the only state we are cleaning up.

--Step 13-A. drop the temp table if it already exists:
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'DBO.ACE_TEMP_OH_FIX') AND type IN (N'U'))
	DROP TABLE DBO.ACE_TEMP_OH_FIX


--Step 13-B. Create the temp table for OH employees to be fixed.
SELECT eeceeid AS eeid, eeccoid AS coid, eeclitresidentcode AS taxcode 
INTO DBO.ACE_TEMP_OH_FIX   
FROM empcomp 
WHERE eeclitresidentcode LIKE 'OH%' 
AND NOT EXISTS (SELECT 1 FROM taxcode WHERE ctctaxcode = eeclitresidentcode AND ctccoid = eeccoid ) 
--0

--Step 13-C. Update EmpComp to set eeclitresidentcode to Null where eeclitresidentcode is not in the taxcode table for the component company.
BEGIN TRAN
UPDATE empcomp
SET eeclitresidentcode = NULL 
FROM DBO.ACE_TEMP_OH_FIX
WHERE eeceeid = eeid AND eeccoid = coid
AND taxcode = eeclitresidentcode 
--COMMIT ROLLBACK
--0
 
--Step 13-D. helpful script to know the count of OH employees' emptax records that will be updated.
SELECT eecempno, eeccoid,eeclitworkincode, eeclitresidentcode,eeclitsdcode, eettaxcode, eetisempcomptaxcode, eetisworkintaxcode, EetIsResidentTaxCode, eetnotsubjecttotax
FROM empcomp 
JOIN emptax ON eeteeid = eeceeid AND eetcoid = eeccoid
WHERE eeclitresidentcode like 'OH%'  AND eettaxcode = eeclitresidentcode
AND eetisworkintaxcode = 'N' AND eetisresidenttaxcode = 'Y'
--0

--Step 13-E. Now set the "not subject to" flag to 'Y' where the OH eeclitresidentcode is not in the taxcode table for the component company.
BEGIN TRAN
UPDATE emptax
SET eetnotsubjecttotax = 'Y'
FROM empcomp 
WHERE eeceeid = eeteeid AND eetcoid = eeccoid
AND eettaxcode = eeclitresidentcode
AND eetisworkintaxcode = 'N' AND eetisresidenttaxcode = 'Y'
AND eeclitresidentcode like 'OH%' AND eetnotsubjecttotax = 'N'
--0
--COMMIT

/******************************************************************************************************************/

--Step 14. Lastly run the two Smart QA - Employee validations related to locals (PA, MD, and KY).
-- These will come up when you run the employee Smart QA script so we might as well look into the issues now.

SELECT CompanyCode = CmpCompanyCode
		,RecordType = 'Taxes'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00418'
		,ErrorMessage = 'Employee is in PA or MD and resident county not set up.  Use Web Import tool to update resident tax information.  Reach out to your LSC for help.'
		,ErrorKeyLabel = 'LIT Resident County'
		,ErrorKeyFieldName= 'EecLITResidentCounty'
		,ErrorKeyValue = isnull(EecLITResidentCounty,'') 
		,Details = 'Address State: ' + EEPADDRESSSTATE
		,RoleToReview ='SC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM Empcomp (NOLOCK)
JOIN EmpPers (NOLOCK) ON eepEEID = EecEEID 
JOIN Company  (NOLOCK) ON cmpcoid = eeccoid AND CmpAddressCountry = 'USA'
WHERE eecemplstatus <> 'T'
AND EEPADDRESSSTATE in ('PA','MD')  AND  EECLITRESIDENTCOUNTY is null


SELECT CompanyCode = CmpCompanyCode
		,RecordType = 'Taxes'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00430'
		,ErrorMessage = 'KY107 Will Not Calculate Unless Both Resident and Work In County and Tax are setup.'
		,ErrorKeyLabel = 'Work In County'
		,ErrorKeyFieldName= 'emllitworkincounty'
		,ErrorKeyValue = isnull(emllitworkincounty,'') 
		,Details = 'Work In Code: ' + substring(emllitworkincode,1,2)
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM Empcomp (NOLOCK)
JOIN EmpPers (NOLOCK) ON eepEEID = EecEEID 
JOIN Company (NOLOCK) ON cmpcoid = eeccoid AND CmpAddressCountry = 'USA'
JOIN empmloc (NOLOCK) on emlcoid = eeccoid AND emleeid = eeceeid 
WHERE (emllitworkincounty = '' or emllitworkincode = '' or emllitworkincounty is NULL or emllitworkincode is NULL OR EecLITResidentCounty IS NULL OR EecLITResidentCounty = '') 
  AND EecLITSDCode = 'KY107'

/******************************************************************************************************************/


--Step 15. This section is updated as of V0004 on 9/9/2020, but we are always looking to maintain and grow validation.

		/***************************	IN			*************************************************/

--Notes from Hsu: 
--IN will always have a LIT res code if they live in IN, location will have a non-resient tax code, 
	-- **if you live in IN you pay your own local res tax code, if you don't you pay the IN work-in non-res local tax code from the location

select eeccoid, eeceeid, eecempno, eecemplstatus, EepAddressState, LocAddressState, eecempno, EecLITResidentCounty, EecLITResidentCode, eettaxcode, emlLITWorkInCode, LocLITResWorkInCode, LocLITNonResWorkInCode, emllitworkincounty
  from emppers
   join empcomp on eepeeid = eeceeid
   join emptax on eeceeid = eeteeid      
              and eeccoid = eetcoid 
   join empmloc on emleeid = eeteeid      
              and emlcoid = eetcoid 
			  and emlisprimary = 'Y'
   join location on EecLocation = loccode
   where eettaxcode like 'IN%'
	 and eettaxcode not like 'INS%'
	 and locaddressstate = 'IN' and EepAddressState = 'IN'
	  and EecLITResidentCode is null
	  and eecemplstatus <> 'T'
	 order by 2
-- 
--***if EecLITResidentCode is null, it probably means not all IN LIT resident tax codes are set up for the component company, so ask the SC to add them
	-- tax filing # for IN LIT should match the company's IN SIT filing #, so should be fine to add them all (per Kimah Thomas).

SELECT DISTINCT cmpCOMPANYCODE, mtctaxcode, MtcTaxCodeDesc, MtcState, MtcCounty, MtcCountyCode, MtcTypeOfTax, mtclocaltype, MtcStandardCode, MtcIsNonResident
		--, eecempno, eecemplstatus, eepnamefirst, eepnamelast, eeceeid, eeccoid --report with EE data
-- SELECT DISTINCT cmpCOMPANYCODE, mtctaxcode, MtcTaxCodeDesc, MtcState, MtcCounty, MtcCountyCode, MtcTypeOfTax, mtclocaltype, MtcStandardCode --distinct report of just tax codes
-- SELECT *
FROM ultipro_system..TxCdMast 
JOIN (
SELECT DISTINCT eeceeid, eeccoid, EecLITResidentCode AS taxcode, eecempno, eecemplstatus, eepnamefirst, eepnamelast, EecLITResidentCounty, EepAddressState
FROM empcomp (NOLOCK) 
JOIN emppers (NOLOCK) ON eeceeid = eepeeid
WHERE eepaddressline1 <> '.' AND eecemplstatus <> 'T' AND EepAddressState = 'IN' AND EecLITResidentCode IS NULL AND EecLITResidentCounty IS NOT NULL
) t ON MtcCounty = EecLITResidentCounty AND MtcState = EepAddressState
JOIN company ON eeccoid = cmpcoid
WHERE GETDATE() BETWEEN MtcEffectiveDate AND MtcEffectiveStopDate 
AND MtcHasBeenReplaced = 'N' AND MtcIsNonResident = 'N' and MtcTypeOfTax = 'LIT'
AND NOT EXISTS (SELECT 1 FROM TAXCODE WHERE mtctaxcode = CTCTAXCODE AND cmpcoid = CTCCOID)
--**** If you need the SC to add any IN tax codes, you should redo the WIT for IN employees so they do get the proper IN LIT resident tax codes added. You should be fine to rerun the entire process.

/*
--all IN resident codes should be added
SELECT mtctaxcode, MtcTaxCodeDesc, MtcState, MtcCounty, MtcCountyCode, MtcTypeOfTax, mtclocaltype, MtcStandardCode, MtcIsNonResident
-- select *
FROM ultipro_system..TxCdMast 
WHERE GETDATE() BETWEEN MtcEffectiveDate AND MtcEffectiveStopDate 
AND MtcHasBeenReplaced = 'N'
and mtctaxcode like 'IN%'
and MtcIsNonResident = 'N' and MtcTypeOfTax = 'LIT'
-- 
*/

--If the employee is in an IN location and does not have and IN LIT tax code, point them towards LocLITNonResWorkInCode (sync to the location may be better, but for IN make sure it is the LocLITNonResWorkInCode tax code).
begin tran
 update eml 
   set emlLITWorkInCode = LocLITNonResWorkInCode 
  from emppers
   join empcomp on eepeeid = eeceeid
   join emptax on eeceeid = eeteeid      
              and eeccoid = eetcoid 
   join empmloc eml on emleeid = eeteeid      
              and emlcoid = eetcoid 
			  and emlisprimary = 'Y'
   join location on EecLocation = loccode
   where eettaxcode like 'IN%'
	 and eettaxcode not like 'INS%'
	 and locaddressstate = 'IN'
	  and EecLITResidentCode is null
--commit

		/***************************	PA			*************************************************/

--PA will have a lit res code, but if they do not also work in PA, not required (rare, don't code for that). 
select eeccoid, eeceeid, eecemplstatus, EepAddressState, LocAddressState, eecempno, EecLITResidentCode, eettaxcode, EecLITResidentCounty  
  from emppers
   join empcomp on eepeeid = eeceeid
   join location on EecLocation = loccode
   left outer join emptax on eeceeid = eeteeid      
              and eeccoid = eetcoid 
   where eepaddressstate = 'PA' and eecemplstatus <> 'T'
	 and eettaxcode like 'PA%'
	 and eettaxcode not like 'PAS%'
	 and (ltrim(rtrim(isnull(EecLITResidentCode,''))) in ('',' ') or ltrim(rtrim(isnull(EecLITResidentCounty,''))) in ('',' '))
-- 

		/***************************	MD			*************************************************/
		
--MD will always have EECLITRESIDENTCOUNTY populated where SIT res is MDSIT, and should have a lit res code (all resident local MD tax codes should be added if any employee lives in MD) **work-in (Location) usually is not populated
select eeccoid, eeceeid, eecemplstatus, EepAddressState, LocAddressState, eecempno, EecLITResidentCode, eettaxcode, EecLITResidentCounty  
  from emppers
   join empcomp on eepeeid = eeceeid
   join location on EecLocation = loccode
   left outer join emptax on eeceeid = eeteeid      
              and eeccoid = eetcoid 
   where eepaddressstate = 'MD' and eecemplstatus <> 'T'
	 and eettaxcode like 'MD%'
	 and eettaxcode not like 'MDS%'
	 and (ltrim(rtrim(isnull(EecLITResidentCode,''))) in ('',' ') or ltrim(rtrim(isnull(EecLITResidentCounty,''))) in ('',' '))
-- 

/*
--all MD resident codes should be added
SELECT mtctaxcode, MtcTaxCodeDesc, MtcState, MtcCounty, MtcCountyCode, MtcTypeOfTax, mtclocaltype, MtcStandardCode, MtcIsNonResident
-- select *
FROM ultipro_system..TxCdMast 
WHERE GETDATE() BETWEEN MtcEffectiveDate AND MtcEffectiveStopDate 
AND MtcHasBeenReplaced = 'N'
and mtctaxcode like 'MD%' -- 
and MtcIsNonResident = 'N' and MtcTypeOfTax = 'LIT'
-- 
*/

		/***************************	KY			*************************************************/
		
--KY: KY049 is invald, make sure this does not show. KY107 is linked to KY101
select cmpcompanycode, eecempno, eepnamefirst, eepnamelast, eecemplstatus, eettaxcode, eetnotsubjecttotax
  from emppers
   join empcomp on eepeeid = eeceeid
   join company on eeccoid = cmpcoid
   join emptax et1 on eeceeid = et1.eeteeid      
              and eeccoid = eetcoid 
where eettaxcode = 'KY049' 
-- 
--not sure if this matters if the employees are terminated.

--if have KY001 (louisville metro local - work-in Lit code for resident only), then must have KY107 (KY107 is res SD tax code).
--    Otherwise, just location work-in non-resdient (KY002)


--if have KY001 (louisville metro local - work-in Lit code for resident only), then must have KY107 (KY107 is res SD tax code).
--    Otherwise, just location work-in non-resdient (KY002)
select eeccoid, eepeeid, eecempno, eepnamefirst, eepnamelast, eecemplstatus,
	EepAddressState, LocAddressState, LocAddressCity, LocLITNonResWorkInCode, LocLITResWorkInCode, 
	EecLITResidentCode, EecLITResidentCounty, eeclitsdcode, EecLITWorkInCode, et1.eettaxcode, et2.eettaxcode
  from emppers
   join empcomp on eepeeid = eeceeid
   join location on EecLocation = loccode and locaddressstate = 'KY' --and LocAddressCity LIKE 'Louisville%'
   join empmloc on emleeid = eeceeid and emlcoid = eeccoid and emlisprimary = 'Y'
   left outer join emptax et1 on eeceeid = et1.eeteeid and eeccoid = et1.eetcoid and et1.eettaxcode = emlLITWorkInCode
   left outer join emptax et2 on eeceeid = et2.eeteeid and eeccoid = et2.eetcoid and et2.eettaxcode = 'KY107'
where eecemplstatus <> 'T'
and LocAddressCity LIKE 'Louisville%'
and ((et1.eettaxcode = 'KY001' and isnull(et2.eettaxcode,'') <> 'KY107') or (et1.eettaxcode = 'KY002' and ltrim(rtrim(isnull(et2.eettaxcode,''))) not in ('',' ')))
-- 


/******************************************************************************************************************/


