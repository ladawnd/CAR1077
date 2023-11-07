/**************************************************************************************
** Name: Smart QA Script - Config.sql
Created by:			Data Conversion Team
Created on:			01/12/2012
revised on          10/21/2020
Description:		Script to run prior to conversion and prior to go live for QA.
					**Run with Results to Text or Results to File Output Options**

Mod by:		Mod On:		Description
            01/01/2019  Various prior updates PearsonM, WallantE, ArbelaezV, JacobJ
 
KevinF/MaciekT	05/22/2019	Completed requested updates to validation tests which are notated throughout the script. Added error codes to messages.
Miles S		9/12/2019	Updated a few validations to be country specific.
Kevin F		10/15/2020	Updated and added validations.	
DC Team		10/21/2020	Reviewed, Updated and added validations.	(Kevin F, Gene S, Maciek T, Joe J)		
DC Team		11/20/2020	Reviewed, Updated and added validations.	(Kevin F, Gene S, Maciek T, Joe J)
Vanessa A	12/30/2020	Updated deduction validations (section 08) to remove date logic that was excluding all deductions

**************************************************************************************/

/**************************************************************************************

Current last error codes used for each section:
01-0008		01 is for Master Company
02-0024		02 is for COMPONENT COMPANY
03-0041		03 is for TAXES
04-0010		04 is for Locations
05-0022		05 is for Banks
06-0010		06 is for Tax Groups
07-0027		07 is for Earnings
08-0034		08 is for Deductions
09-0016		09 is for Other Business Rules
10-0019		10 is for Security and Web Setup
11-0003		11 is for ACA
12-0020		12 is for Miscellaneous
13-0003		13 is for Pay Group
14-0004		14 is for TOA

**************************************************************************************/

/*DECLARE VARIABLES*/
	DECLARE @ISGOLIVE CHAR(1), @ISNONPROFIT CHAR(1), @ISCHECKPRINT CHAR(1), @LIVEDATE DATETIME, @ISOELE CHAR(1), @ENVIRONMENT VARCHAR(50), @Country VARCHAR(3), @TOA VARCHAR(10), @EEPAY CHAR(1)
	
/******SET VARIABLES PRIOR TO SCRIPT EXECUTION*******/
	SET @ISGOLIVE = 'N' -- If this is the Go Live QA enter 'Y'.  If this is the Pre Data Conversion QA set to 'N'
	SET @ISNONPROFIT = 'N' -- Is your customer a non-profit? SET TO 'Y' OR 'N'
	SET @ISCHECKPRINT = 'N' -- Is your customer using UltiPro Check Print?  SET TO 'Y' OR 'N'
	SET @LIVEDATE = '01/01/2024' -- Enter First Check Date IN 'MM/DD/YYYY' FORMAT
	SET @ISOELE = 'Y' -- Enter 'Y' only if customer is using OE / LE in Ultipro. For Benefits Prime and other vendors, please enter 'N'
	SET @ENVIRONMENT = 'G03W12' -- UltiPro Environment you are working in. 
	SET @Country = 'USA'  -- Enter USA or CAN.
	SET @TOA = 'N'	--Is your customer using TOA? SET TO 'Y' OR 'N'
	SET @EEPAY = 'N' --Is your customer using Employee Pay? Set to 'Y' or 'N'

------------------------------------------------------------------------------------------------------------------------------------------

/*DO NOT MODIFY*/
--KF ADDED LIST COUNT FOR ITEMS THAT ARE NOT ERRORS OR WARNINGS
	DECLARE @WARNINGCOUNT SMALLINT, @ERRORCOUNT SMALLINT, @LISTCOUNT SMALLINT
	SET @WARNINGCOUNT = 0
	SET @ERRORCOUNT = 0
	SET @LISTCOUNT = 0

	DECLARE @ISMIDMARKET CHAR(1)
	SELECT @ISMIDMARKET = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
	WHERE SUBSTRING(@ENVIRONMENT, 2, 1) = 'W' AND ISNUMERIC(SUBSTRING(@ENVIRONMENT, 3, 2)) = 1
	--MidMarket environments should have a 'W' as the 2nd character & numbers as the 3rd and 4th characters (ex. EW11)

------------------------------------------------------------------------------------------------------------------------------------------

PRINT '		   UltiPro Configuration QA'
PRINT '***********************************************'
PRINT '	'

PRINT 'Parms: Go Live: ' + @ISGOLIVE +', NonProfit: '+@ISNONPROFIT+', Check Print: '+@ISCHECKPRINT+', Live Date: '+convert(varchar(10), cast(@LIVEDATE as date), 101) +
	  ', Is Ole: '+@ISOELE+ ',Envrionment: '+@ENVIRONMENT+', Country: '+@Country+ ',TOA: '+@TOA+ ', EE Pay: '+ @EEPAY 


------------------------------------------------------------------------------------------------------------------------------------------

/** Master Company **/

PRINT '____________________________________________________________________________________________________________________________________________________________'
PRINT ''
PRINT '1) MASTER COMPANY INFORMATION'
PRINT '____________________________________________________________________________________________________________________________________________________________'
PRINT ''

DECLARE @cmmcompanycode CHAR(5)
DECLARE @cmmcompanyname VARCHAR(40)
DECLARE @cmmAddressLine1 VARCHAR(30)
DECLARE @cmmAddressLine2 VARCHAR(30)
DECLARE @CmmAddressCity VARCHAR(30)
DECLARE @CmmAddressState CHAR(2)
DECLARE @CmmAddressZipCode CHAR(10)
DECLARE @cmmPhoneNumber CHAR(10)
DECLARE @cmmfedtaxid CHAR(9)
DECLARE @cmmmasterempnomethod CHAR(1)
DECLARE @cmminstantcheckinquarter CHAR(1)
DECLARE @CmmCANBIN CHAR(9)

DECLARE CompMastCursor CURSOR FOR
	SELECT CmmCompanyCode, CmmCompanyName, CmmAddressLine1, CmmAddressLine2, CmmAddressCity, CmmAddressState,
		   CmmAddressZipCode, CmmPhoneNumber, CmmFedtaxId, CmmMasterEmpnoMethod, CmmInstantCheckInQuarter,
		   CmmCANBIN 
	FROM CompMast (NOLOCK)
OPEN CompMastCursor
FETCH NEXT FROM CompMastCursor INTO 
	@cmmcompanycode, @cmmcompanyname, @cmmaddressline1, @cmmaddressline2, @cmmaddresscity, @cmmaddressstate, 
	@cmmaddresszipcode, @cmmphonenumber, @cmmfedtaxid, @cmmmasterempnomethod, @cmminstantcheckinquarter,
	@CmmCANBIN
WHILE @@FETCH_STATUS = 0
BEGIN

	PRINT 'Company Code: ' + @cmmcompanycode
	PRINT 'Company Name: ' + @cmmcompanyname
	PRINT 'Company Address Line 1: ' + ISNULL(@cmmaddressline1,'')
	PRINT 'Company Address Line 2: ' + ISNULL(@cmmaddressline2,'')
	PRINT 'Company Address City: ' + ISNULL(@cmmaddresscity,'')
	PRINT 'Company Address State: ' + ISNULL(@cmmaddressstate,'')
	PRINT 'Company Phone: ' + ISNULL(@cmmphonenumber,'')
	PRINT 'Company Fed TaxID (USA): ' + ISNULL(@cmmfedtaxid,'')
	PRINT 'Company Business Number (Canada): ' + ISNULL(@CmmCANBIN,'')
	PRINT ''
	IF @cmmmasterempnomethod <> 'M' AND @ISGOLIVE = 'N' 
	BEGIN
	PRINT '!!Warning!! 01-0001 Employee Numbering method should be set to Manual before data conversion.' --KF added error/warning code
	PRINT ''
	SET @WARNINGCOUNT += 1
	END
	IF @cmmmasterempnomethod = 'M' AND @ISGOLIVE = 'Y'
	BEGIN
	PRINT '!!Warning!! 01-0002 Employee numbering method is set to Manual.  Please confirm with customer.' --KF added error/warning code
	PRINT ''
	SET @WARNINGCOUNT += 1
	END
	IF @cmminstantcheckinquarter <> 'Y'
	BEGIN
	PRINT '!!Error!! 01-0003 Instant/Manual check in quarter is not flagged.' --KF added error/warning code
	PRINT ''
	SET @ERRORCOUNT += 1
	END

	FETCH NEXT FROM CompMastCursor INTO 
	@cmmcompanycode, @cmmcompanyname, @cmmaddressline1, @cmmaddressline2, @cmmaddresscity, @cmmaddressstate, 
	@cmmaddresszipcode, @cmmphonenumber, @cmmfedtaxid, @cmmmasterempnomethod, @cmminstantcheckinquarter,
	@CmmCANBIN
	
END
CLOSE CompMastCursor
DEALLOCATE CompMastCursor

------------------------------------------------------------------------------------------------------------------------------------------------------------
-- * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
--  * * * To Report if Master Country code is not 'CAN' for Customers on Toronto server * * *
--  * * * Should be run for ALL. Country is irrelevent * * *
-- * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
--BB 20181120 new
DECLARE @PRINT_TORONTO_CAN_WARNING CHAR(1)

SELECT @PRINT_TORONTO_CAN_WARNING = 'Y' 
--select CmmCompanyName,CmmAddressCountry,CmmCountryCode
from CompMast
where Substring(@ENVIRONMENT,1,1) = 'T' and CmmCountryCode != 'CAN'

IF @PRINT_TORONTO_CAN_WARNING = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 01-0004 The Country Code for the following Customer that is setup on the Toronto server is not CAN' --KF added error/warning code
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
select CmmCompanyName,CmmAddressCountry,CmmCountryCode
from CompMast
where Substring(@ENVIRONMENT,1,1) = 'T' and CmmCountryCode != 'CAN'
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------------------------
-- * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
--  * * * To Report if Company does not have at least 1 ORGLEVEL configured * * *
--  * * * Should be run for ALL. Country is irrelevent * * *
-- * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
--BB 20181120 new
DECLARE @PRINT_ORGLVL_WARNING CHAR(1)

SELECT @PRINT_ORGLVL_WARNING = 'Y' 
--select CmmCompanyName,CmmOrgLvl1Label,CmmOrgLvl2Label,CmmOrgLvl3Label,CmmOrgLvl4Label
from CompMast
where ((CmmOrgLvl1Label is  NULL) and 
(CmmOrgLvl2Label is  NULL) and
(CmmOrgLvl3Label is  NULL) and
(CmmOrgLvl4Label is  NULL)) 


IF @PRINT_ORGLVL_WARNING = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 01-0005 The following Company does not have at least 1 ORGLVL setup.  At least 1 org level needs to be setup for the company.'
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
select CmmCompanyName,CmmOrgLvl1Label,CmmOrgLvl2Label,CmmOrgLvl3Label,CmmOrgLvl4Label
from CompMast
where ((CmmOrgLvl1Label is  NULL) and 
(CmmOrgLvl2Label is  NULL) and
(CmmOrgLvl3Label is  NULL) and
(CmmOrgLvl4Label is  NULL)) 

SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------------------------
-- * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
--  * * * To Report if PRO-Rate Pay is enabled * * *
--  * * * Should be run for ALL. Country is irrelevent * * *
-- * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
------------------------------------------------------------------------------------------------------------------------------------------
--BB 20181120 new
DECLARE @PRINT_PRRATEDPAY_WARNING CHAR(1)

SELECT @PRINT_PRRATEDPAY_WARNING= 'Y' 
--select CmmUseProRatePay,CmmWorkPatternAssignCtr, CmmWorkPatternCode 
from CompMast
where CmmUseProRatePay = 'Y'


IF @PRINT_PRRATEDPAY_WARNING= 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 01-0006 Pro-rate pay is enabled. Please ensure work pattern is established and Org Level is selected.'
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
select CmmUseProRatePay,CmmWorkPatternAssignCtr, CmmWorkPatternCode
FROM  CompMast
where CmmUseProRatePay = 'Y'

SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------------------------
-- * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
--  * * * To Report the Payroll Options * * *
--
--- * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
------------------------------------------------------------------------------------------------------------------------------------------
--BB 20181121 new
DECLARE @PRINT_PAYROLLOPTIONS_VALIDATION CHAR(1)

SELECT @PRINT_PAYROLLOPTIONS_VALIDATION = 'Y' 
--select CmmCompanyName,CmmUseMultipleJobGroups as 'Job Groups Enabled',CmmIsPlatinumClient as 'Timeclock – Create Regular pay if none in batch'
from CompMast


IF @PRINT_PAYROLLOPTIONS_VALIDATION = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 01-0007 Please verify with customer if the following options should be selected for master company.'
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
select CmmCompanyName,CmmUseMultipleJobGroups as 'Job Groups Enabled',CmmIsPlatinumClient as 'Timeclock – Create Regular pay if none in batch'
from CompMast

SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------

--KF 20190604 NEW
--KF 10/15/2020 UPDATED TO BE 5 YEARS INSTEAD OF 4 PER AVIVA MURPHY'S REQUEST

DECLARE @MASTER_0008 CHAR(1)

SELECT @MASTER_0008 = 'Y' 
-- SELECT cmmcompanyname, cmmelecformaccessyears 
FROM compmast
WHERE cmmelecformaccessyears < 5


IF @MASTER_0008 = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 01-0008 Please update field to be greater than 5 years.'
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
SELECT cmmcompanyname, cmmelecformaccessyears 
FROM compmast
WHERE cmmelecformaccessyears < 5
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------

/** Component Company **/
-- ms 20181120 replace
----VA 05/21/19: Remove detail component company if no errors or warnings. Just display company code and company name if warning or error appears.


PRINT '____________________________________________________________________________________________________________________________________________________________'
PRINT ''
PRINT '2) COMPONENT COMPANY INFORMATION'
PRINT '____________________________________________________________________________________________________________________________________________________________'
PRINT ''

DECLARE @cmpcompanycode CHAR(5)
DECLARE @cmpcompanyname VARCHAR(40)
DECLARE @cmpAddressLine1 VARCHAR(30)
DECLARE @cmpAddressLine2 VARCHAR(30)
DECLARE @CmpAddressCity VARCHAR(30)
DECLARE @CmpAddressState CHAR(2)
DECLARE @CmpAddressZipCode CHAR(10)
DECLARE @cmpPhoneNumber CHAR(10)
DECLARE @cmpfedtaxid CHAR(9)
DECLARE @cmpDefaultLocation CHAR(6)
DECLARE @cmpisexemptfromfuta CHAR(1)
DECLARE @cmptakesuicredit CHAR(1)
DECLARE @CmpCompEmpnoMethod CHAR(1)
DECLARE @cmpissuireimburse CHAR(1)
DECLARE @cmpcountrycode CHAR(3)
DECLARE @CmpCANBIN CHAR(9)
DECLARE @CmpExcludeFromTaxRpt CHAR(1)
DECLARE @CmpIsExemptFromCPP CHAR(1)
DECLARE @CmpIsExemptFromEI CHAR(1)
DECLARE @CmpIsExemptFromFNFMO CHAR(1)
DECLARE @CmpIsExemptFromQPIP CHAR(1)
DECLARE @CmpIsExemptFromQPP CHAR(1)
DECLARE @CMPCONTACT CHAR(30)


DECLARE CompComponentCursor CURSOR FOR
	SELECT CmpCompanyCode, CmpCompanyName, CmpAddressLine1, CmpAddressLine2, CmpAddressCity, CmpAddressState, CmpAddressZipCode, CmpPhoneNumber, 
		   CmpFedTaxID, CmpDefaultLocation, CmpIsExemptFromFUTA, CmpTakeSUICredit, CmpCompEmpnoMethod, CmpIsSUIReimburse, CmpCountryCode, 
		   CmpCANBIN, CmpExcludeFromTaxRpt, CmpIsExemptFromCPP,	CmpIsExemptFromEI,	CmpIsExemptFromFNFMO, CmpIsExemptFromQPIP, CmpIsExemptFromQPP,
		   CmpContact
	FROM Company (NOLOCK)
	  where cmpcountrycode = @country
OPEN CompComponentCursor
FETCH NEXT FROM CompComponentCursor INTO 
	@cmpcompanycode, @cmpcompanyname, @cmpAddressLine1, @cmpAddressLine2, @CmpAddressCity, @CmpAddressState, @CmpAddressZipCode, @cmpPhoneNumber,
	@cmpfedtaxid, @cmpDefaultLocation, @cmpisexemptfromfuta, @cmptakesuicredit, @CmpCompEmpnoMethod, @cmpissuireimburse, @cmpcountrycode, 
	@CmpCANBIN, @CmpExcludeFromTaxRpt, @CmpIsExemptFromCPP, @CmpIsExemptFromEI, @CmpIsExemptFromFNFMO, @CmpIsExemptFromQPIP, @CmpIsExemptFromQPP,
	@CMPCONTACT
WHILE @@FETCH_STATUS = 0
BEGIN
-- select cmpfedtaxid , cmpcountrycode from company
	PRINT '***********************************************'
	PRINT 'Component Company Code: ' + @cmpcompanycode
	PRINT 'Component Company Name: ' + @cmpcompanyname
	PRINT 'Component Company Address Line 1: ' + ISNULL(@cmpaddressline1,'')
	PRINT 'Component Company Address Line 2: ' + ISNULL(@cmpaddressline2,'')
	PRINT 'Component Company Address City: ' + ISNULL(@cmpaddresscity,'')
	PRINT 'Component Company Address State: ' + ISNULL(@cmpaddressstate,'')
	PRINT 'Component Company Phone: ' + ISNULL(@cmpphonenumber,'')
	PRINT 'Component Company USA Fed TaxID: ' + ISNULL(@cmpfedtaxid,'')
	PRINT 'Component Company CAN Business Num: ' + ISNULL(@CmpCANBIN,'')
	PRINT 'Component Company Default Location: ' + ISNULL(@cmpdefaultlocation,'')
	PRINT 'Component Company Contact: ' + ISNULL(@CMPCONTACT,'')
	PRINT ''
	IF @cmpisexemptfromfuta <> 'Y' AND @ISNONPROFIT = 'Y' AND @cmpcountrycode = 'USA' AND @Country = 'USA'
	BEGIN
	PRINT '!!Error!! 02-0001 Company is non-profit and FUTA exempt flag is not selected.'
	PRINT ''
	SET @ERRORCOUNT += 1
	END
	IF @cmpissuireimburse <> 'Y' AND @ISNONPROFIT = 'Y' AND @cmpcountrycode = 'USA' AND @Country = 'USA'
	BEGIN
	PRINT '!!Warning!! 02-0002 Company is non-profit and SUI reimburse flag is not selected.'
	PRINT ''
	SET @WARNINGCOUNT += 1
	END
	IF @cmptakesuicredit <> 'Y' AND @cmpcountrycode = 'USA'
	BEGIN
	PRINT '!!Warning!! 02-0003 Take SUI credit flag is not selected.  Please consult with customer on taking SUI credits.'
	PRINT ''
	SET @WARNINGCOUNT += 1
	END
	IF @cmpdefaultlocation IS NULL 
	BEGIN
	PRINT '!!Error!! 02-0004 This component company does not have a Default Location.'
	PRINT ''
	SET @ERRORCOUNT += 1
	END
	IF @CmpCompEmpnoMethod <> 'M' AND @ISGOLIVE = 'N' 
	BEGIN
	PRINT '!!Warning!! 02-0005 Employee Numbering method should be set to Manual before data conversion.'
	PRINT ''
	SET @WARNINGCOUNT += 1
	END
	IF @CmpCompEmpnoMethod = 'M' AND @ISGOLIVE = 'Y'
	BEGIN
	PRINT '!!Warning!! 02-0006 Employee numbering method is set to Manual.  Please confirm with customer.'
	PRINT ''
	SET @WARNINGCOUNT += 1
	END

	-- NEW CAN
	IF @CmpExcludeFromTaxRpt = 'Y' AND @cmpcountrycode = 'CAN' AND @Country = 'CAN'
	BEGIN
	PRINT '!!Warning!! 02-0007 Verify Exclude from RPT.  Please confirm with customer.'
	PRINT ''
	SET @WARNINGCOUNT += 1
	END
	IF @CmpIsExemptFromCPP = 'Y' AND @cmpcountrycode = 'CAN' AND @Country = 'CAN'
	BEGIN
	PRINT '!!Warning!! 02-0008 Verify Is Exempt From CPP.  Please confirm with customer.'
	PRINT ''
	SET @WARNINGCOUNT += 1
	END
	IF @CmpIsExemptFromEI = 'Y' AND @cmpcountrycode = 'CAN' AND @Country = 'CAN'
	BEGIN
	PRINT '!!Warning!! 02-0009 Verify Is Exempt From EI.  Please confirm with customer.'
	PRINT ''
	SET @WARNINGCOUNT += 1
	END
	IF @CmpIsExemptFromFNFMO = 'Y' AND @cmpcountrycode = 'CAN' AND @Country = 'CAN'
	BEGIN
	PRINT '!!Warning!! 02-0010 Verify Is Exempt From FNFMO.  Please confirm with customer.'
	PRINT ''
	SET @WARNINGCOUNT += 1
	END
	IF @CmpIsExemptFromQPIP = 'Y' AND @cmpcountrycode = 'CAN' AND @Country = 'CAN'
	BEGIN
	PRINT '!!Warning!! 02-0011 Verify Is Exempt From QPIP.  Please confirm with customer.'
	PRINT ''
	SET @WARNINGCOUNT += 1
	END
	IF @CmpIsExemptFromQPP = 'Y' AND @cmpcountrycode = 'CAN' AND @Country = 'CAN'
	BEGIN
	PRINT '!!Warning!! 02-0012 Verify Is Exempt From QPP.  Please confirm with customer.'
	PRINT ''
	SET @WARNINGCOUNT += 1
	END		
FETCH NEXT FROM CompComponentCursor INTO 
	@cmpcompanycode, @cmpcompanyname, @cmpAddressLine1, @cmpAddressLine2, @CmpAddressCity, @CmpAddressState, @CmpAddressZipCode, @cmpPhoneNumber, 
	@cmpfedtaxid, @cmpDefaultLocation, @cmpisexemptfromfuta, @cmptakesuicredit, @CmpCompEmpnoMethod, @cmpissuireimburse, @cmpcountrycode, 
	@CmpCANBIN, @CmpExcludeFromTaxRpt, @CmpIsExemptFromCPP, @CmpIsExemptFromEI, @CmpIsExemptFromFNFMO, @CmpIsExemptFromQPIP, @CmpIsExemptFromQPP,
	@CMPCONTACT
	
END
CLOSE CompComponentCursor
DEALLOCATE CompComponentCursor



---------------------------------------------------------------------------------------------------------------
--FUTA OR SDI EXEMPT:
-- ms 20181120 REPLACE
DECLARE @PRINT_FUTA_SDI_EXEMPT CHAR(1)

SELECT @PRINT_FUTA_SDI_EXEMPT =  'Y' 
FROM Company (NOLOCK)
WHERE (CmpIsExemptFromSDI = 'Y' OR CmpIsExemptFromFUTA = 'Y')
  and CmpCompanyCode = @Country
  and @Country  = 'USA'

IF @PRINT_FUTA_SDI_EXEMPT = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 02-0013 Customer is flagged as either FUTA or SDI exempt. Please confirm with customer.' 
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
SELECT CmpCompanyName, CmpCompanyCode, CmpCoID, CmpIsExemptFromFUTA, CmpTakeSUICredit, CmpIsSUIReimburse, CmpIsExemptFromSDI
FROM Company (NOLOCK)
WHERE (CmpIsExemptFromSDI = 'Y' OR CmpIsExemptFromFUTA = 'Y')
  and CmpCompanyCode = @Country
  and @Country  = 'USA'

SET NOCOUNT OFF

PRINT ''
END

-----------------------------------------------------------------------------------------------------------------------------------------------------------------

--Verify Canada BIN number is populated for component company
-- MS 20181120
DECLARE @IS_CmpCANBIN  CHAR(1)

SELECT @IS_CmpCANBIN =  'Y' 
-- select CmmCANBIN, *
FROM Company (NOLOCK)
WHERE CmpCountryCode = 'CAN'
  and @COUNTRY in ('CAN')
  and (CmpCANBIN is null or CmpCANBIN = '')


IF @IS_CmpCANBIN = 'Y' 
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 02-0014 Business Number should not be blank for Canada Component Company' 
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
select CmpCompanyCode, CmpCompanyName, CmpCANBIN
FROM Company (NOLOCK)
WHERE CmpCountryCode = 'CAN'
  and @COUNTRY in ('CAN')
  and (CmpCANBIN is null or CmpCANBIN = '')

PRINT ''
END

-------------------------------------------------------------------------------------------------------------------------------
-- MT 20181120 new
--NO allocation options have been selected for the component company
----05/21/2019 VA: this test should be either USA or CAN
-- MT 20190521  - Removed Country Specific Check 
-- KF 20190607 limited to USA and CAN

DECLARE @PRINT_CMPALLOC_WARNING CHAR(1)


--IF @COUNTRY in ('CAN','USA')
--BEGIN

	SELECT @PRINT_CMPALLOC_WARNING = 'Y' 
	FROM Company
	JOIN CompMast on cmmCOID = cmpMasterCOID
	WHERE ((CmpAllocEEDed = 'N') 
	AND (CmpAllocERDed = 'N') 
	AND (CmpAllocEETax = 'N') 
	AND (CmpAllocERTax = 'N') 
	AND (CmpAllocNetPay = 'N') 
	AND (CmpAllocWC = 'N')
	AND (CmpAllocByGLBaseSegment = 'N') 
	AND (CmpAllocByJobCode = 'N') 
	AND (CmpAllocByLocation = 'N') 
	AND (CmpAllocByOrgLvl1 = 'N') 
	AND (CmpAllocByOrgLvl2 = 'N') 
	AND (CmpAllocByOrgLvl3 = 'N') 
	AND (CmpAllocByOrgLvl4 = 'N')
	AND (CmpAllocByProject = 'N'))
	AND CmpCountryCode = @COUNTRY AND @COUNTRY in ('CAN','USA')
--END

IF @PRINT_CMPALLOC_WARNING = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 02-0015 The following Component Companies do not have an Allocation Option selected.'
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
Select CmmCompanyName, CmpCompanyCode, CmpCompanyName, CmpAddressCountry, CmpCountryCode
,CmpAllocEEDed
,CmpAllocERDed
,CmpAllocEETax 
,CmpAllocERTax 
,CmpAllocNetPay 
,CmpAllocWC
,CmpAllocByGLBaseSegment 
,CmpAllocByJobCode 
,CmpAllocByLocation 
,CmpAllocByOrgLvl1 
,CmpAllocByOrgLvl2 
,CmpAllocByOrgLvl3 
,CmpAllocByOrgLvl4
,CmpAllocByProject
FROM Company
JOIN CompMast on cmmCOID = cmpMasterCOID
WHERE ((CmpAllocEEDed = 'N') 
AND (CmpAllocERDed = 'N') 
AND (CmpAllocEETax = 'N') 
AND (CmpAllocERTax = 'N') 
AND (CmpAllocNetPay = 'N') 
AND (CmpAllocWC = 'N')
AND (CmpAllocByGLBaseSegment = 'N') 
AND (CmpAllocByJobCode = 'N') 
AND (CmpAllocByLocation = 'N') 
AND (CmpAllocByOrgLvl1 = 'N') 
AND (CmpAllocByOrgLvl2 = 'N') 
AND (CmpAllocByOrgLvl3 = 'N') 
AND (CmpAllocByOrgLvl4 = 'N')
AND (CmpAllocByProject = 'N'))
AND CmpCountryCode = @COUNTRY AND @COUNTRY in ('CAN','USA')

SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------------------------
-- * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
--  * * * To Report if Allocation Options Don't match between MAster and Component Coimpany * * *
--
-- * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
------------------------------------------------------------------------------------------------------------------------------------------
--BB 20181120 new
DECLARE @PRINT_ALLOCATION_WARNING CHAR(1)

SELECT @PRINT_ALLOCATION_WARNING= 'Y' 
--select Cmpcompanycode, CmpAllocEEDed, CmmAllocEEDed, CmpAllocERDed , CmmAllocERDed,CmpAllocEETax ,CmmAllocEETax, CmpAllocERTax ,CmmAllocERTax, CmpAllocNetPay ,CmmAllocNetPay,CmpAllocWC, CmmAllocWC,CmpAllocByGLBaseSegment ,CmmAllocByGLBaseSegment,CmpAllocByJobCode ,CmmAllocByJobCode,CmpAllocByLocation ,CmmAllocByLocation,CmpAllocByOrgLvl1 ,CmmAllocByOrgLvl1,CmpAllocByOrgLvl2 ,CmmAllocByOrgLvl2,CmpAllocByOrgLvl3 ,CmmAllocByOrgLvl3,CmpAllocByOrgLvl4 ,CmmAllocByOrgLvl4,CmpAllocByProject ,CmmAllocByProject
FROM  CompMast
join company on cmpmastercoid = cmmcoid
where  ((CmpAllocEEDed <> CmmAllocEEDed) or (CmpAllocERDed <> CmmAllocERDed) or (CmpAllocEETax <> CmmAllocEETax) or (CmpAllocERTax <> CmmAllocERTax) 
or (CmpAllocNetPay <> CmmAllocNetPay) or (CmpAllocWC <> CmmAllocWC)
or (CmpAllocByGLBaseSegment <> CmmAllocByGLBaseSegment) or (CmpAllocByJobCode <> CmmAllocByJobCode) or (CmpAllocByLocation <> CmmAllocByLocation) or 
(CmpAllocByOrgLvl1 <> CmmAllocByOrgLvl1) or (CmpAllocByOrgLvl2 <> CmmAllocByOrgLvl2) or (CmpAllocByOrgLvl3 <> CmmAllocByOrgLvl3) or (CmpAllocByOrgLvl4 <> CmmAllocByOrgLvl4)
or (CmpAllocByProject <> CmmAllocByProject))
and CmpCountryCode = @country
--AND @COUNTRY in ('CAN','USA') --KF 10/15/2020: removing so only the company variable is displayed

IF @PRINT_ALLOCATION_WARNING ='Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 02-0016 Allocation options do NOT match between master company and component company. Please review.'
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
select Cmpcompanycode, cmpaddresscountry, CmpAllocEEDed, CmmAllocEEDed, CmpAllocERDed , CmmAllocERDed,CmpAllocEETax ,CmmAllocEETax, CmpAllocERTax ,CmmAllocERTax, CmpAllocNetPay ,CmmAllocNetPay,CmpAllocWC, CmmAllocWC,
CmpAllocByGLBaseSegment ,CmmAllocByGLBaseSegment,CmpAllocByJobCode ,CmmAllocByJobCode,CmpAllocByLocation ,CmmAllocByLocation,CmpAllocByOrgLvl1 ,CmmAllocByOrgLvl1,CmpAllocByOrgLvl2 ,CmmAllocByOrgLvl2,
CmpAllocByOrgLvl3 ,CmmAllocByOrgLvl3,CmpAllocByOrgLvl4 ,CmmAllocByOrgLvl4,CmpAllocByProject ,CmmAllocByProject, CmpCountryCode
FROM  CompMast
join company on cmpmastercoid = cmmcoid
where  ((CmpAllocEEDed <> CmmAllocEEDed) or (CmpAllocERDed <> CmmAllocERDed) or (CmpAllocEETax <> CmmAllocEETax) or (CmpAllocERTax <> CmmAllocERTax) 
or (CmpAllocNetPay <> CmmAllocNetPay) or (CmpAllocWC <> CmmAllocWC)
or (CmpAllocByGLBaseSegment <> CmmAllocByGLBaseSegment) or (CmpAllocByJobCode <> CmmAllocByJobCode) or (CmpAllocByLocation <> CmmAllocByLocation) or 
(CmpAllocByOrgLvl1 <> CmmAllocByOrgLvl1) or (CmpAllocByOrgLvl2 <> CmmAllocByOrgLvl2) or (CmpAllocByOrgLvl3 <> CmmAllocByOrgLvl3) or (CmpAllocByOrgLvl4 <> CmmAllocByOrgLvl4)
or (CmpAllocByProject <> CmmAllocByProject))
and CmpCountryCode = @country
--AND @COUNTRY in ('CAN','USA') --KF 10/15/2020: removing so only the company variable is displayed
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------------------------
-- * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
--  * * * To Report if tax reporting fields are blank * * *
--  * * * Only to be run for CAN Component Companies * *
-- * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
------------------------------------------------------------------------------------------------------------------------------------------
--BB 20181120 new
DECLARE @PRINT_TAXREPORTINGFLD_WARNING CHAR(1)

SELECT @PRINT_TAXREPORTINGFLD_WARNING = 'Y' 
--select cmpcompanycode, CmpTCCCode, cmptmraddresscity,cmptmraddressline1,cmptmraddressstate,cmptmraddresszipcode,cmptmrphone,cmptmrphonecountrycode,cmptmrcontact,CmpPhoneTax,cmpphonetaxcountrycode
FROM  company 
where (CmpTCCCode is null or cmptmraddresscity is null or cmptmraddressline1 is null  or cmptmraddressstate is null or cmptmrphone is null or cmptmrphonecountrycode is null or 
cmptmrcontact is null or CmpPhoneTax is null or cmpphonetaxcountrycode is null)
and @country = 'CAN' and CmpCountryCode = @country

IF @PRINT_TAXREPORTINGFLD_WARNING= 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 02-0017 The following Tax Reporting fields are missing.  Enter a value.'
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
select cmpcompanycode, CmpTCCCode, cmptmraddresscity,cmptmraddressline1,cmptmraddressstate,cmptmraddresszipcode,cmptmrphone,cmptmrphonecountrycode,cmptmrcontact,CmpPhoneTax,
cmpphonetaxcountrycode
FROM  company 
where (CmpTCCCode is null or cmptmraddresscity is null or cmptmraddressline1 is null or cmptmraddressstate is null or cmptmrphone is null or cmptmrphonecountrycode is null or 
cmptmrcontact is null or CmpPhoneTax is null or cmpphonetaxcountrycode is null or CmpAddressZipCode is null)
and @country = 'CAN' and CmpCountryCode = @country
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------------------------
-- * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
--  * * * To validate if Country matches currency in company setup * * *
--
--- * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
------------------------------------------------------------------------------------------------------------------------------------------
--BB 20181121 new
----05/21/2019 VA: Add ERROR if CAN <> CAD or Global company compare CmpAddressCountry and CmpCurrencyCode against Currency table
-- MT 20190521  - Added System Currency Table to check against component company country

DECLARE @PRINT_COMPANYCUR_VALIDATION CHAR(1)

SELECT @PRINT_COMPANYCUR_VALIDATION = 'Y' 
--select CmpCompanyCode, CmpCompanyName,CmpAddressCountry ,cmpcurrencycode
from Company
WHERE NOT EXISTS(select * from ULTIPRO_SYSTEM.dbo.Currency WHERE CmpCountryCode = CurCountryCode ) --MT added


 
IF @PRINT_COMPANYCUR_VALIDATION ='Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 02-0018 Please validate that the country matches the currency.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
select CmpCompanyCode, CmpCompanyName, CmpAddressCountry , cmpcurrencycode, CmpCountryCode
from Company
order by CmpCountryCode , cmpcurrencycode
 

SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
--KF 20190528 NEW

DECLARE @PRINT_COMPANYFEDFEINDASH_VALIDATION CHAR(1)

SELECT @PRINT_COMPANYFEDFEINDASH_VALIDATION = 'Y' 
--Select CmpCompanyCode, CmpCompanyName, cmpfedtaxid
from Company
where cmpfedtaxid like '%-%' and @country = 'USA'


 
IF @PRINT_COMPANYFEDFEINDASH_VALIDATION ='Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 02-0019 FEIN number should NOT have dashes.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
Select CmpCompanyCode, CmpCompanyName, cmpfedtaxid
from Company
where cmpfedtaxid like '%-%' and @country = 'USA'
 

SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
--KF 20190528 NEW

DECLARE @PRINT_GLOBALCOMPANY_VALIDATION CHAR(1)

SELECT @PRINT_GLOBALCOMPANY_VALIDATION = 'Y' 
--List of global companies
--Select CmpCOID,CmpCompanyName,CmpCountryCode,CmpCurrencyCode,CmpExcludeFromTaxRpt
from Company
where CmpCountryCode not in ( 'USA','CAN')

 
IF @PRINT_GLOBALCOMPANY_VALIDATION ='Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '02-0020 Review global company setup.'
PRINT ''
SET @LISTCOUNT += 1

SET NOCOUNT ON
Select CmpCOID,CmpCompanyName,CmpCountryCode,CmpCurrencyCode,CmpExcludeFromTaxRpt
from Company
where CmpCountryCode not in ( 'USA','CAN')
 

SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------------------------
-- * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
--  * * * To Report if missing Company Email address * * *
--
--- * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
------------------------------------------------------------------------------------------------------------------------------------------
--BB 20181121 new
DECLARE @PRINT_COMPANYEMAIL_ERROR CHAR(1)

SELECT @PRINT_COMPANYEMAIL_ERROR = 'Y' 
--select CmpCompanyCode, CmpCompanyName, cmpaddressemail
from Company
where cmpaddressemail is null
and CmpCountryCode = @Country AND @Country = 'CAN'


IF @PRINT_COMPANYEMAIL_ERROR ='Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
--PRINT '!!ERROR!! 03-0033 Missing Company email for company.'
PRINT '!!ERROR!! 02-0021 Email address missing for component company.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
select CmpCompanyCode, CmpCompanyName, cmpaddressemail
from Company
where cmpaddressemail is null
and CmpCountryCode = @Country AND @Country = 'CAN'

SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
--KF 09/08/2020 NEW
DECLARE @PRINT_COMPANYCONTACT_ERROR CHAR(1)

SELECT @PRINT_COMPANYCONTACT_ERROR = 'Y' 
--select CmpCountryCode,CmpCompanyCode,CmpCompanyName,CmpContact
from Company
where LTRIM(RTRIM(ISNULL(CmpContact,''))) IN ('',' ')
and CmpCountryCode = @Country AND @Country = 'CAN'


IF @PRINT_COMPANYCONTACT_ERROR ='Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!ERROR!! 02-0022 Error - Contact name is missing from component company.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
select CmpCountryCode, CmpCompanyCode, CmpCompanyName, CmpContact = ISNULL(CmpContact,'')
from Company
where LTRIM(RTRIM(ISNULL(CmpContact,''))) IN ('',' ')
and CmpCountryCode = @Country AND @Country = 'CAN'

SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------

--KF 10/15/2020 NEW
--Submitted by Elliot Davenport to check for bad company codes for both USA and CAN
DECLARE @PRINT_BADCOMPANYCODE_ERROR CHAR(1)

SELECT @PRINT_BADCOMPANYCODE_ERROR = 'Y' 
--select CmpCompanyCode, CmpCompanyName, CmpCountryCode
from Company
where cmpcompanycode IN
('ALL','CON','PRN','AUX','NUL','COM1','COM2','COM3','COM4','COM5','COM6','COM7','COM8','COM9','COM0',
'LPT1','LPT2','LPT3','LPT4','LPT5','LPT6','LPT7','LPT8','LPT9','LPT0')


IF @PRINT_BADCOMPANYCODE_ERROR ='Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!ERROR!! 02-0023 Error - Company Code is using a code that will cause issues:'
PRINT ' **ALL,CON,PRN,AUX,NUL,COM1,COM2,COM3,COM4,COM5,COM6,COM7,COM8,COM9,COM0,LPT1,LPT2,LPT3,LPT4,LPT5,LPT6,LPT7,LPT8,LPT9,LPT0**.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
select CmpCompanyCode, CmpCompanyName, CmpCountryCode
from company 
where cmpcompanycode IN
('ALL','CON','PRN','AUX','NUL','COM1','COM2','COM3','COM4','COM5','COM6','COM7','COM8','COM9','COM0',
'LPT1','LPT2','LPT3','LPT4','LPT5','LPT6','LPT7','LPT8','LPT9','LPT0')


SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------

--KF 10/15/2020 NEW
--Submitted by Edward Fields
DECLARE @02_0024 CHAR(1)

SELECT @02_0024 = 'Y' 
FROM COMPANY 
WHERE LTRIM(RTRIM(CMPCOMPANYCODE)) LIKE '%[^a-zA-Z0-9]%'

IF @02_0024 ='Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!ERROR!! 02-0024 Error - Company Code is using special characters which will cause issues with UTE QE processing.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT CMPCOMPANYCODE 
FROM COMPANY 
WHERE LTRIM(RTRIM(CMPCOMPANYCODE)) LIKE '%[^a-zA-Z0-9]%'

SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------

/** Taxes **/
-- MS 20181120 replace

PRINT '____________________________________________________________________________________________________________________________________________________________'
PRINT ''
PRINT '3) TAXES'
PRINT '____________________________________________________________________________________________________________________________________________________________'
PRINT ''

DECLARE @PRINT_ID CHAR(1)

SELECT @PRINT_ID = 'Y' 
FROM TaxCode (NOLOCK)
JOIN Company (NOLOCK) ON CtcCOID = CmpCoID
WHERE CtcIDNumber IS NULL AND LEFT(LTRIM(CtcTaxCode),2) NOT IN ('US', 'TP','FN') AND CtcEffectiveStopDate >= GETDATE() AND CtcEffectiveInActiveStopDate IS NULL
AND CtcTypeOfTax <> 'LIT' AND CtcTaxCode NOT IN ('FLSIT', 'TXSIT', 'NVSIT', 'NHSIT', 'SDSIT', 'TNSIT', 'WYSIT', 'WASIT', 'AKSIT') 
AND (CtcTaxCode LIKE '%SIT' OR CtcTaxCode LIKE '%SUIER')
AND CmpCountryCode = @country
AND @Country = 'USA'

IF @PRINT_ID = 'Y'
BEGIN
PRINT ''
PRINT '!!Error!! 03-0001 The following tax codes are missing an ID.  Enter the ID or ''Applied For''.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT CmpCompanyCode, CmpCompanyName, CtcTaxCode, CtcIDNumber
FROM TaxCode (NOLOCK)
JOIN Company (NOLOCK) ON CtcCOID = CmpCoID
WHERE CtcIDNumber IS NULL AND LEFT(LTRIM(CtcTaxCode),2) NOT IN ('US', 'TP','FN') AND CtcEffectiveStopDate >= GETDATE() AND CtcEffectiveInActiveStopDate IS NULL
AND CtcTypeOfTax <> 'LIT' AND CtcTaxCode NOT IN ('FLSIT', 'TXSIT', 'NVSIT', 'NHSIT', 'SDSIT', 'TNSIT', 'WYSIT', 'WASIT', 'AKSIT')
AND (CtcTaxCode LIKE '%SIT' OR CtcTaxCode LIKE '%SUIER')
AND CmpCountryCode = @country
AND @Country = 'USA'
ORDER BY CmpCompanyCode, CtcTaxCode
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- MS 20181120 REPLACE
--05/21/2019 VA: add country variable to skip validation for CAN
--05/21/2019 VA: need validation to review missing linked tax codes based on tax codes setup for component company
--MT 20190521:  Added Country Variable for USA only (not needed for Canada)
	--Miles, you may need to see if existing checks exist for the missing linked tax codes

DECLARE @PRINT_TAXRATE_ERROR CHAR(1)

IF @Country = 'USA' 
BEGIN
	SELECT @PRINT_TAXRATE_ERROR = 'Y' 
	FROM TaxCRate (NOLOCK)
	JOIN (SELECT MAX(YEAR(TcrEffectiveDate)) MaxYear, TcrTaxCode FROM TaxCRate (NOLOCK) GROUP BY TcrTaxCode) MaxYear 
		ON MaxYear.MaxYear = YEAR(TcrEffectiveDate) AND MaxYear.TcrTaxCode = TaxCRate.TcrTaxCode
	JOIN Company (NOLOCK) ON CmpCoID = TcrCOID
	WHERE TcrUseSystemRate = 'N' AND TcrContributionRate = 0 AND TcrHasBeenReplaced = 'N' AND LEFT(LTRIM(TaxCRate.TcrTaxCode),2) <> 'FN'
	AND TaxCRate.TcrTaxCode LIKE '%SUIER' AND CmpIsSUIReimburse = 'N'
	AND CmpCountryCode = @country AND @country = 'USA'


	IF @PRINT_TAXRATE_ERROR = 'Y'
	BEGIN
	PRINT '*************************************************************************************************************************************************'
	PRINT ''
	PRINT '!!Error!! 03-0002 The following tax codes are missing a rate.  Enter the actual rate or the default rate for the jurisdiction.'
	PRINT '			  If zero rate is valid you MUST provide backup documentation to TC.'
	PRINT ''
	SET @ERRORCOUNT += 1

	SET NOCOUNT ON
	SELECT CmpCompanyCode, CmpCompanyName, TaxCRate.TcrTaxCode, CONVERT(VARCHAR,TcrEffectiveDate,101) TcrEffectiveDate, TcrContributionRate 
	FROM TaxCRate (NOLOCK)
	JOIN (SELECT MAX(YEAR(TcrEffectiveDate)) MaxYear, TcrTaxCode FROM TaxCRate (NOLOCK) GROUP BY TcrTaxCode) MaxYear 
		ON MaxYear.MaxYear = YEAR(TcrEffectiveDate) AND MaxYear.TcrTaxCode = TaxCRate.TcrTaxCode
	JOIN Company (NOLOCK) ON CmpCoID = TcrCOID
	WHERE TcrUseSystemRate = 'N' AND TcrContributionRate = 0 AND TcrHasBeenReplaced = 'N' AND LEFT(LTRIM(TaxCRate.TcrTaxCode),2) <> 'FN'
	AND TaxCRate.TcrTaxCode LIKE '%SUIER' AND CmpIsSUIReimburse = 'N'
	AND CmpCountryCode = @country AND @country = 'USA'
	ORDER BY CmpCompanyCode, TaxCRate.TcrTaxCode
	SET NOCOUNT OFF

	PRINT ''
	END
END

------------------------------------------------------------------------------------------------------------------------------------------
-- ms 20181120 replace

DECLARE @PRINT_TAXRATE_WARNING CHAR(1)

SELECT @PRINT_TAXRATE_WARNING = 'Y' 
FROM TaxCRate (NOLOCK)
JOIN (SELECT MAX(YEAR(TcrEffectiveDate)) MaxYear, TcrTaxCode FROM TaxCRate (NOLOCK) GROUP BY TcrTaxCode) MaxYear 
	ON MaxYear.MaxYear = YEAR(TcrEffectiveDate) AND MaxYear.TcrTaxCode = TaxCRate.TcrTaxCode
JOIN Company (NOLOCK) ON CmpCoID = TcrCOID
WHERE TcrUseSystemRate = 'N' AND TcrContributionRate = 0 AND TcrHasBeenReplaced = 'N' AND LEFT(LTRIM(TaxCRate.TcrTaxCode),2) <> 'FN'
AND TaxCRate.TcrTaxCode NOT LIKE '%SUIER' AND TaxCRate.TcrRateChangeReason <> 'WEBSRV' AND CmpIsSUIReimburse = 'N'
AND CmpCountryCode = @country
AND @Country = 'USA'
IF @PRINT_TAXRATE_WARNING = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 03-0003 The following tax codes are missing a rate.  Enter the actual rate or the default rate for the jurisdiction.'
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
SELECT CmpCompanyCode, CmpCompanyName, TaxCRate.TcrTaxCode, CONVERT(VARCHAR,TcrEffectiveDate,101) TcrEffectiveDate, TcrContributionRate 
FROM TaxCRate (NOLOCK)
JOIN (SELECT MAX(YEAR(TcrEffectiveDate)) MaxYear, TcrTaxCode FROM TaxCRate (NOLOCK) GROUP BY TcrTaxCode) MaxYear 
	ON MaxYear.MaxYear = YEAR(TcrEffectiveDate) AND MaxYear.TcrTaxCode = TaxCRate.TcrTaxCode
JOIN Company (NOLOCK) ON CmpCoID = TcrCOID
WHERE TcrUseSystemRate = 'N' AND TcrContributionRate = 0 AND TcrHasBeenReplaced = 'N' AND LEFT(LTRIM(TaxCRate.TcrTaxCode),2) <> 'FN'
AND TaxCRate.TcrTaxCode NOT LIKE '%SUIER' AND TaxCRate.TcrRateChangeReason <> 'WEBSRV' AND CmpIsSUIReimburse = 'N'
AND CmpCountryCode = @country
AND @Country = 'USA'
ORDER BY CmpCompanyCode, TaxCRate.TcrTaxCode
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------------------------
-- MS 20181120 replace
DECLARE @PRINT_TAXMD CHAR(1)

SELECT @PRINT_TAXMD = 'Y' 
FROM TaxCode (NOLOCK)
JOIN Company (NOLOCK) ON CmpCoID = CtcCOID
WHERE CtcTaxCode = 'MDSIT'
  and CmpCountryCode = @Country AND @Country = 'USA'

IF @PRINT_TAXMD = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 03-0004 Please ensure that all Maryland counties are set up.'
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
SELECT CmpCompanyCode, CmpCompanyName, CtcTaxCode 
FROM TaxCode (NOLOCK)
JOIN Company (NOLOCK) ON CmpCoID = CtcCOID 
WHERE CtcTaxCode = 'MDSIT'
  and CmpCountryCode = @Country AND @Country = 'USA'
ORDER BY CmpCompanyCode
SET NOCOUNT OFF

PRINT ''
END

--------------------------------------------------------------------------------------------------------------------------------------------
-- ms 20181120 replace
DECLARE @PRINT_TAXWA CHAR(1)

SELECT @PRINT_TAXWA = CASE WHEN ISNULL(TaxCount,0) >= 2 AND WcrState IS NOT NULL THEN 'N' ELSE 'Y' END 
FROM TaxCode (NOLOCK)
JOIN Company (NOLOCK) ON CmpCoID = CtcCOID
LEFT OUTER JOIN (SELECT CtcCOID, COUNT(*) TaxCount FROM TaxCode (NOLOCK) WHERE CtcTaxCode IN ('WALIEE', 'WALIER', 'WALIEP') GROUP BY CtcCOID) x ON x.CtcCOID = CmpCoID 
LEFT OUTER JOIN WCRisk (NOLOCK) ON WcrState = LEFT(LTRIM(TaxCode.CtcTaxCode),2) AND WcrCoID = TaxCode.CtcCOID
WHERE CtcTaxCode = 'WASUIER'
and CmpCountryCode = @Country AND @Country = 'USA'


IF @PRINT_TAXWA = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 03-0005 Washington L&I tax codes and/or Workers Comp codes are not set up correctly.'
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
SELECT CmpCompanyName, x.CtcTaxCode, WcrState 
FROM TaxCode (NOLOCK)
JOIN Company (NOLOCK) ON CmpCoID = CtcCOID
LEFT OUTER JOIN (SELECT CtcCOID, CtcTaxCode FROM TaxCode WHERE CtcTaxCode IN ('WALIEE', 'WALIER', 'WALIEP')) x ON x.CtcCOID = CmpCoID
LEFT OUTER JOIN WCRisk (NOLOCK) ON WcrState = LEFT(LTRIM(TaxCode.CtcTaxCode),2) AND WcrCoID = TaxCode.CtcCOID
WHERE TaxCode.CtcTaxCode = 'WASUIER'
and CmpCountryCode = @Country AND @Country = 'USA'
ORDER BY CmpCompanyName, x.CtcTaxCode
SET NOCOUNT OFF

PRINT ''
END

-----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- MS 20181120 replace
--Location WA:
--05/21/2019 VA: Update to ERROR - Update message: " ERROR - The following WA Locations do not have the correct WA local codes or have WALIEP setup"
--MT 20190521:  Changed message from Warning to Error

DECLARE @PRINT_LOCATIONWA CHAR(1)

SELECT @PRINT_LOCATIONWA = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM Location (NOLOCK)
WHERE LocSITWorkInStateCode = 'WASIT' AND LocLITResWorkInCode <> 'WALIEE' AND LocLITOCCCode <> 'WALIER'
  and LocAddressCountry = @Country AND @Country = 'USA'

IF @PRINT_LOCATIONWA = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
--PRINT '!!Warning!!  The following WA Locations do not have the correct WA local codes.' --MT 20190521
PRINT '!!Error!! 03-0006 The following WA Locations do not have the correct WA local codes or have WALIEP setup.' --MT 20190521
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT LocCode, LocLITResWorkInCode, LocLITNonResWorkInCode, LocLITOCCCode 
FROM Location (NOLOCK)
WHERE LocSITWorkInStateCode = 'WASIT' AND LocLITResWorkInCode <> 'WALIEE' AND LocLITOCCCode <> 'WALIER' 
  and LocAddressCountry = @Country AND @Country = 'USA'
SET NOCOUNT OFF

PRINT ''
END

-----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- MS 20181120 replace
--Verify multiple WC code flag is setup at the company level for Enterprise clients:

DECLARE @IS_WASIT CHAR(1), @IS_ALLOW_MULTI_WC CHAR(1)

SELECT @IS_WASIT = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM Location (NOLOCK)
WHERE LocSITWorkInStateCode = 'WASIT'
  and LocAddressCountry = @Country AND @Country = 'USA'

SELECT @IS_ALLOW_MULTI_WC = CmmAllowMultipleWCCodes
FROM CompMast (NOLOCK)

IF @ISMIDMARKET = 'N' AND @IS_WASIT = 'Y' AND @IS_ALLOW_MULTI_WC = 'N'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 03-0007 Master Company is NOT setup for multiple WC. Please review setup.' 
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
SELECT LocSITWorkInStateCode 
FROM Location (NOLOCK)
WHERE LocSITWorkInStateCode = 'WASIT'
  and LocAddressCountry = @Country AND @Country = 'USA'

SELECT CmmAllowMultipleWCCodes
FROM CompMast (NOLOCK)
SET NOCOUNT OFF

PRINT ''
END

-----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- MS 20181120 replace
--Location OR:

DECLARE @PRINT_LOCATIONOR CHAR(1)

SELECT @PRINT_LOCATIONOR = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM   Location (NOLOCK)
WHERE  LocSITWorkInStateCode = 'ORSIT' 
AND   (LocLITResWorkInCode <> 'ORWCEE' OR LocLITNonResWorkInCode <> 'ORWCEP') 
AND    loclitwcccode <> 'ORWCER'
and LocAddressCountry = @Country AND @Country = 'USA'

IF @PRINT_LOCATIONOR = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 03-0008 The following OR Locations do not have the correct OR local codes.' 
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT LocCode, LocLITResWorkInCode, LocLITNonResWorkInCode, loclitwcccode 
FROM   Location (NOLOCK)
WHERE  LocSITWorkInStateCode = 'ORSIT' 
AND   (LocLITResWorkInCode <> 'ORWCEE' OR LocLITNonResWorkInCode <> 'ORWCEP') 
AND    loclitwcccode <> 'ORWCER'
and LocAddressCountry = @Country AND @Country = 'USA'
SET NOCOUNT OFF

PRINT ''
END

-------------------------------------------------------------------------------------------------------------------------------
-- ms 20181120 replace
--Checks for OR taxes:

DECLARE @PRINT_TAXOR CHAR(1)

SELECT @PRINT_TAXOR = CASE WHEN ISNULL(TaxCount,0) >= 2 AND WcrState IS NOT NULL THEN 'N' ELSE 'Y' END 
FROM TaxCode (NOLOCK)
JOIN Company (NOLOCK) ON CmpCoID = CtcCOID
LEFT OUTER JOIN (SELECT CtcCOID, COUNT(*) TaxCount FROM TaxCode (NOLOCK) WHERE CtcTaxCode IN ('ORWCEE', 'ORWCEP', 'ORWCER') GROUP BY CtcCOID) x ON x.CtcCOID = CmpCoID
LEFT OUTER JOIN WCRisk ON WcrState = LEFT(LTRIM(TaxCode.CtcTaxCode),2) AND WcrCoID = TaxCode.CtcCOID
WHERE TaxCode.CtcTaxCode = 'ORSUIER'
and CmpCountryCode = @Country AND @Country = 'USA'

IF @PRINT_TAXOR = 'Y' 
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 03-0009 Oregon tax codes (ORWCEE/ORWCEP AND ORWCER) are not configured and/or Oregon is not setup within any Workers Comp codes. Please review job aid for further information.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT CmpCompanyName, x.CtcTaxCode, WcrState 
FROM TaxCode (NOLOCK)
JOIN Company (NOLOCK) ON CmpCoID = CtcCOID
LEFT OUTER JOIN (SELECT CtcCOID, CtcTaxCode FROM TaxCode (NOLOCK) WHERE CtcTaxCode IN ('ORWCEE', 'ORWCER', 'ORWCEP')) x ON x.CtcCOID = CmpCoID 
LEFT OUTER JOIN WCRisk (NOLOCK) ON WcrState = LEFT(LTRIM(TaxCode.CtcTaxCode),2) AND WcrCoID = TaxCode.CtcCOID
WHERE TaxCode.CtcTaxCode = 'ORSUIER'
and CmpCountryCode = @Country AND @Country = 'USA'
ORDER BY CmpCompanyName, x.CtcTaxCode
SET NOCOUNT OFF

PRINT ''
END

--------------------------------------------------------------------------------------------------------------------------------------
-- ms 20181120 replace
-- KF 20190620 UPDATED LOGIC, ONLY CHECKING FOR MORE THAN ONE ON THIS VALIDATION AS 03-0012 CHECKS FOR MISSING SDIEE
DECLARE @PRINT_TAXCA CHAR(1)

SELECT @PRINT_TAXCA = CASE WHEN ISNULL(TaxCount,0) > 1 THEN 'Y' ELSE 'N' END 
--select CASE WHEN ISNULL(TaxCount,0) = 1 THEN 'N' ELSE 'Y' END, TaxCount, CmpCoID
FROM TaxCode (NOLOCK)
JOIN Company (NOLOCK) ON CmpCoID = CtcCOID and CtcTaxCode like 'CA%' and CtcTypeOfTax = 'SDI'
LEFT OUTER JOIN (SELECT CtcCOID, COUNT(*) TaxCount FROM TaxCode (NOLOCK) WHERE CtcTaxCode IN ('CASDIEE', 'CASDIPEE', 'CAESDIEE') GROUP BY CtcCOID) x ON x.CtcCOID = CmpCoID
WHERE CmpCountryCode = @Country AND @Country = 'USA'

PRINT @PRINT_TAXCA

IF @PRINT_TAXCA = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 03-0010 The following CA wage plans are set up.  There should be only one plan per component company.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT CmpCompanyName, CtcTaxCode 
FROM TaxCode (NOLOCK)
JOIN Company (NOLOCK) ON CmpCoID = CtcCOID and CtcTaxCode like 'CA%' and CtcTypeOfTax = 'SDI'
LEFT OUTER JOIN (SELECT CtcCOID, COUNT(*) TaxCount FROM TaxCode (NOLOCK) WHERE CtcTaxCode IN ('CASDIEE', 'CASDIPEE', 'CAESDIEE') GROUP BY CtcCOID) x ON x.CtcCOID = CmpCoID
WHERE ISNULL(TaxCount,0) > 1 AND CtcTaxCode IN ('CASDIEE', 'CASDIPEE', 'CAESDIEE') 
AND EXISTS (SELECT 1 FROM TaxCode x WHERE x.CtcTaxCode = 'CASUIER' AND x.CtcCOID = TaxCode.CtcCOID)
and CmpCountryCode = @Country AND @Country = 'USA'
ORDER BY CmpCompanyName
SET NOCOUNT OFF

PRINT ''
END

-----------------------------------------------------------------------------------------------------------------------------------------------------------
-- MS 20181120 REPLACE
--Checks most recent record of SDI for states CA:

DECLARE @PRINT_TAXSDI CHAR(1)

SELECT @PRINT_TAXSDI = 'Y'
FROM TaxCRate (NOLOCK), TaxCode (NOLOCK), Company (NOLOCK)
WHERE TcrCOID = CtcCOID 
AND TcrTaxCode = CtcTaxCode
AND CmpCOID = CtcCOID
AND TcrHasBeenReplaced = 'N'
AND CtcEffectiveStopDate >= GETDATE() 
AND CtcEffectiveInActiveStopDate IS NULL
AND TcrEffectiveStopDate >= GETDATE() 
AND TcrInactiveDate IS NULL
AND CtcTypeOfTax = 'SDI'
AND TcrUseSystemRate = 'N'
AND (LEFT(TcrTaxCode,2) = 'CA')
and CmpCountryCode = @Country AND @Country = 'USA'
 
IF @PRINT_TAXSDI = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 03-0011 CA SDI Tax Codes Not Using System Rate.'
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
SELECT DISTINCT CmpCompanyCode, TcrTaxCode, CtcTypeOfTax, TcrUseSystemRate, TcrHasBeenReplaced
FROM TaxCRate (NOLOCK), TaxCode (NOLOCK), Company (NOLOCK)
WHERE TcrCOID = CtcCOID
AND TcrTaxCode = CtcTaxCode
AND CmpCOID = CtcCOID
AND CtcEffectiveStopDate >= GETDATE() 
AND CtcEffectiveInActiveStopDate IS NULL
AND TcrEffectiveStopDate >= GETDATE() 
AND TcrInactiveDate IS NULL
AND TcrHasBeenReplaced = 'N'
AND CtcTypeOfTax = 'SDI'
AND TcrUseSystemRate = 'N'
AND (LEFT(TcrTaxCode,2) = 'CA')
and CmpCountryCode = @Country AND @Country = 'USA'
ORDER BY CmpCompanyCode, TcrTaxCode
SET NOCOUNT OFF
  
PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------

--Customer has SUI in the following states, but missing SDI codes: CA, HI, PR, NJ, NY, RI:
-- ms 20181120 replace
-- KF 20190620 UPDATED LOGIC
-- GS 20201015 updated logic to add DC, MA, and WA
DECLARE @PRINT_SUI_MISSINGSDI CHAR(1)

SELECT @PRINT_SUI_MISSINGSDI = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM TaxCode (NOLOCK)
JOIN Company (NOLOCK) ON CmpCoID = CtcCOID
WHERE (
   (CtcTaxCode = 'CASUIER' AND NOT EXISTS(SELECT 1 FROM TaxCode (NOLOCK) WHERE CmpCoID = CtcCOID AND CtcTaxCode LIKE 'CA%SDI%'))
OR (CtcTaxCode = 'HISUIER' AND NOT EXISTS(SELECT 1 FROM TaxCode (NOLOCK) WHERE CmpCoID = CtcCOID AND CtcTaxCode LIKE 'HISDI%'))
OR (CtcTaxCode = 'PRSUIER' AND NOT EXISTS(SELECT 1 FROM TaxCode (NOLOCK) WHERE CmpCoID = CtcCOID AND CtcTaxCode LIKE 'PRSDI%'))
OR (CtcTaxCode = 'NJSUIER' AND NOT EXISTS(SELECT 1 FROM TaxCode (NOLOCK) WHERE CmpCoID = CtcCOID AND CtcTaxCode LIKE 'NJSDI%'))
OR (CtcTaxCode = 'NYSUIER' AND NOT EXISTS(SELECT 1 FROM TaxCode (NOLOCK) WHERE CmpCoID = CtcCOID AND CtcTaxCode LIKE 'NYSDI%'))
OR (CtcTaxCode = 'RISUIER' AND NOT EXISTS(SELECT 1 FROM TaxCode (NOLOCK) WHERE CmpCoID = CtcCOID AND CtcTaxCode LIKE 'RISDI%'))
OR (CtcTaxCode = 'DCSUIER' AND NOT EXISTS(SELECT 1 FROM TaxCode (NOLOCK) WHERE CmpCoID = CtcCOID AND CtcTaxCode LIKE 'DCPFL%'))
OR (CtcTaxCode = 'MASUIER' AND NOT EXISTS(SELECT 1 FROM TaxCode (NOLOCK) WHERE CmpCoID = CtcCOID AND CtcTaxCode LIKE 'MAPML%'))
OR (CtcTaxCode = 'WASUIER' AND NOT EXISTS(SELECT 1 FROM TaxCode (NOLOCK) WHERE CmpCoID = CtcCOID AND CtcTaxCode LIKE 'WAPML%'))
)
and CmpCountryCode = @Country AND @Country = 'USA'


IF @PRINT_SUI_MISSINGSDI = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 03-0012 Missing SDI code(s) associated with the SUI code for CA, HI, PR, NJ, NY, and/or RI.'
PRINT ''
SET @ERRORCOUNT += 1

--Need to add DC, MA and WA to this test as we treat the "family / leave tax codes" as SDI codes. When we have these states,
-- we should expect parent "family / leave tax codes" as follow:
--DCSUIER = DCPFLER
--MASUIER = MAPMLER
--WASUIER = WAPMLER

SET NOCOUNT ON
SELECT CmpCompanyName, CtcTaxCode
FROM TaxCode (NOLOCK)
JOIN Company (NOLOCK) ON CmpCoID = CtcCOID
WHERE (
   (CtcTaxCode = 'CASUIER' AND NOT EXISTS(SELECT 1 FROM TaxCode (NOLOCK) WHERE CmpCoID = CtcCOID AND CtcTaxCode LIKE 'CA%SDI%'))
OR (CtcTaxCode = 'HISUIER' AND NOT EXISTS(SELECT 1 FROM TaxCode (NOLOCK) WHERE CmpCoID = CtcCOID AND CtcTaxCode LIKE 'HISDI%'))
OR (CtcTaxCode = 'PRSUIER' AND NOT EXISTS(SELECT 1 FROM TaxCode (NOLOCK) WHERE CmpCoID = CtcCOID AND CtcTaxCode LIKE 'PRSDI%'))
OR (CtcTaxCode = 'NJSUIER' AND NOT EXISTS(SELECT 1 FROM TaxCode (NOLOCK) WHERE CmpCoID = CtcCOID AND CtcTaxCode LIKE 'NJSDI%'))
OR (CtcTaxCode = 'NYSUIER' AND NOT EXISTS(SELECT 1 FROM TaxCode (NOLOCK) WHERE CmpCoID = CtcCOID AND CtcTaxCode LIKE 'NYSDI%'))
OR (CtcTaxCode = 'RISUIER' AND NOT EXISTS(SELECT 1 FROM TaxCode (NOLOCK) WHERE CmpCoID = CtcCOID AND CtcTaxCode LIKE 'RISDI%'))
OR (CtcTaxCode = 'DCSUIER' AND NOT EXISTS(SELECT 1 FROM TaxCode (NOLOCK) WHERE CmpCoID = CtcCOID AND CtcTaxCode LIKE 'DCPFL%'))
OR (CtcTaxCode = 'MASUIER' AND NOT EXISTS(SELECT 1 FROM TaxCode (NOLOCK) WHERE CmpCoID = CtcCOID AND CtcTaxCode LIKE 'MAPML%'))
OR (CtcTaxCode = 'WASUIER' AND NOT EXISTS(SELECT 1 FROM TaxCode (NOLOCK) WHERE CmpCoID = CtcCOID AND CtcTaxCode LIKE 'WAPML%'))
                      )
and CmpCountryCode = @Country AND @Country = 'USA'
ORDER BY CmpCompanyName, CtcTaxCode

SET NOCOUNT OFF
  
PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- ms 20181120 replace
--Check for Local taxes setup for AL, CO, DE, MI, MS, NY, NJ, OH, IN, KY, MD, PA, WV:
----05/21/2019 VA: Break out validation. Add ERROR for state OH, IN, PA, MD.  / WARNING: AL, CO, DE, MI, NY, NJ, KY, WV, CA, NV, OR, WA, MO
--MT 20190521:  Separated into two sections.  This section is now an ERROR for states OH, IN, PA, MD

/*
DECLARE @PRINT_LOCALS CHAR(1)

SELECT @PRINT_LOCALS = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM TaxCode (NOLOCK)
JOIN Company (NOLOCK) ON CmpCOID = CtcCOID
WHERE CtcTaxCode IN ('ALSIT', 'COSIT', 'DESIT', 'MISIT', 'MSSIT', 'NYSIT', 'NJSIT', 'OHSIT', 'INSIT', 'KYSIT', 'MDSIT', 'PASIT', 'WVSIT')
AND CtcTypeOfTax = 'LIT'
AND CmpCountryCode = 'USA'
AND @Country = 'USA'

IF @PRINT_LOCALS = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 03-0013 Please ensure local taxes are setup for the following states (if applicable): AL, CO, DE, MI, MS, NY, NJ, OH, IN, KY, MD, PA, WV.'
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
SELECT CmpCompanyName, CtcTypeOfTax, CtcTaxCode
FROM TaxCode (NOLOCK)
JOIN Company (NOLOCK) ON CmpCOID = CtcCOID
WHERE CtcTaxCode IN ('ALSIT', 'COSIT', 'DESIT', 'MISIT', 'MSSIT', 'NYSIT', 'NJSIT', 'OHSIT', 'INSIT', 'KYSIT', 'MDSIT', 'PASIT', 'WVSIT')
AND CtcTypeOfTax = 'LIT'
AND CmpCountryCode = 'USA'
AND @Country = 'USA'
SET NOCOUNT OFF

PRINT ''
END
*/

DECLARE @PRINT_LOCALS CHAR(1)

SELECT @PRINT_LOCALS = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM TaxCode (NOLOCK)
JOIN Company (NOLOCK) ON CmpCOID = CtcCOID
WHERE CtcTaxCode IN ('OHSIT', 'INSIT', 'MDSIT', 'PASIT')
AND CtcTypeOfTax = 'LIT'
and CmpCountryCode = @Country AND @Country = 'USA'

IF @PRINT_LOCALS = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 03-0014 Please ensure local taxes are setup for the following states (if applicable): OH, IN, PA, MD.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT CmpCompanyName, CtcTypeOfTax, CtcTaxCode
FROM TaxCode (NOLOCK)
JOIN Company (NOLOCK) ON CmpCOID = CtcCOID
WHERE CtcTaxCode IN ('OHSIT', 'INSIT', 'MDSIT', 'PASIT')
AND CtcTypeOfTax = 'LIT'
and CmpCountryCode = @Country AND @Country = 'USA'
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
----05/21/2019 VA: Break out validation. Add ERROR for state OH, IN, PA, MD.  / WARNING: AL, CO, DE, MI, NY, NJ, KY, WV, CA, NV, OR, WA, MO
--MT 20190521:  Separated into two sections.  This section is now a Warning for states AL, CO, DE, MI, NY, NJ, KY, WV, CA, NV, OR, WA, MO

DECLARE @PRINT_LOCALS2 CHAR(1)

SELECT @PRINT_LOCALS2 = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM TaxCode (NOLOCK)
JOIN Company (NOLOCK) ON CmpCOID = CtcCOID
WHERE CtcTaxCode IN ('ALSIT', 'COSIT', 'DESIT', 'KYSIT', 'MISIT', 'MSSIT', 'MOSIT', 'NJSIT', 'NVSIT','NYSIT', 'ORSIT','WASIT', 'WVSIT')
AND CtcTypeOfTax = 'LIT'
and CmpCountryCode = @Country AND @Country = 'USA'

IF @PRINT_LOCALS2 = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 03-0015 Please ensure local taxes are setup for the following states (if applicable): AL, CO, DE, MI, NY, NJ, KY, WV, CA, NV, OR, WA, MO.'
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
SELECT CmpCompanyName, CtcTypeOfTax, CtcTaxCode
FROM TaxCode (NOLOCK)
JOIN Company (NOLOCK) ON CmpCOID = CtcCOID
WHERE CtcTaxCode IN ('ALSIT', 'COSIT', 'DESIT', 'KYSIT', 'MISIT', 'MSSIT', 'MOSIT', 'NJSIT', 'NVSIT','NYSIT', 'ORSIT','WASIT', 'WVSIT')
AND CtcTypeOfTax = 'LIT'
and CmpCountryCode = @Country AND @Country = 'USA'
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- ms 20181120 replace
--SIT and SUI check for all SIT codes in location:

IF OBJECT_ID('tempdb..#SITlocations') IS NOT NULL DROP TABLE #SITlocations
IF OBJECT_ID('tempdb..#SUIlocations') IS NOT NULL DROP TABLE #SUIlocations

DECLARE @PRINT_LOCSUI_MISSING CHAR(1)

SET NOCOUNT ON
SELECT DISTINCT CmpCompanyName, LocSITWorkInStateCode, LcpCOID
INTO #SITlocations
FROM Location (NOLOCK)
JOIN LocComp (NOLOCK) ON LocCode = LcpCode
JOIN Company (NOLOCK) ON CmpCOID = LcpCOID
where CmpCountryCode = @Country AND @Country = 'USA'

SET NOCOUNT ON
SELECT DISTINCT CmpCompanyName, CtcTaxCode, CtcCOID
INTO #SUIlocations
FROM TaxCode (NOLOCK)
JOIN Company (NOLOCK) ON CmpCOID = CtcCOID
WHERE CtcTaxCode LIKE '%SUIER'
and CmpCountryCode = @Country AND @Country = 'USA'
SET NOCOUNT OFF

SELECT @PRINT_LOCSUI_MISSING = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END 
FROM #SITlocations
LEFT JOIN #SUIlocations ON LcpCOID = CtcCOID AND SUBSTRING(LocSITWorkInStateCode, 1, 2) = SUBSTRING(CtcTaxCode, 1, 2)
WHERE CtcCOID IS NULL

IF @PRINT_LOCSUI_MISSING = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 03-0016 SUI tax codes need to be setup for all states in which customer has a work location.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT #SITlocations.CmpCompanyName, LocSITWorkInStateCode, LcpCOID, CtcTaxCode, CtcCOID
FROM #SITlocations
LEFT JOIN #SUIlocations ON LcpCOID = CtcCOID AND SUBSTRING(LocSITWorkInStateCode,1,2) = SUBSTRING(CtcTaxCode,1,2)
WHERE CtcCOID IS NULL
ORDER BY #SITlocations.CmpCompanyName, LocSITWorkInStateCode
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- MS 20181120 REPLACE
--Check to ensure SMART is used for PA locations:

DECLARE @PRINT_PA_SMART CHAR(1)

SELECT @PRINT_PA_SMART = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM Location (NOLOCK)
WHERE LocSITWorkInStateCode = 'PASIT' AND LocLatitude IS NULL
and LocAddressCountry = @Country AND @Country = 'USA'

IF @PRINT_PA_SMART = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 03-0017 Please use Smart Tax to ensure correct tax codes are setup for the PA location.'
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
Select LocCode, SUBSTRING(LocAddressCity,1,30) LocAddressCity, SUBSTRING(LocAddressLine1,1,30) LocAddressLine1, SUBSTRING(LocAddressLine2,1,30) LocAddressLine2, 
   SUBSTRING(LocAddressState,1,30) LocAddressState, SUBSTRING(LocAddressZipcode,1,12) LocAddressZipCode, LocSITWorkInStateCode, LocLatitude
FROM Location (NOLOCK)
WHERE LocSITWorkInStateCode = 'PASIT' AND LocLatitude IS NULL
and LocAddressCountry = @Country AND @Country = 'USA'
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- MS 20181120 REPLACE
--code not in location:
----05/21/2019 VA: update validation to include (CtcTaxCode <> 'ORTRAN'). Update message '!!Warning!!  Occupational tax code setup, but not attached to any location.'
--MT 20190521:  Included (CtcTaxCode <> 'ORTRAN'). Updated message '!!Warning!!  Occupational tax code setup, but not attached to any location.'

DECLARE @PRINT_LOCOCCTAX CHAR(1)

SELECT @PRINT_LOCOCCTAX = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM TaxCode (NOLOCK)
WHERE CtcLocalType = 'OCC' AND NOT EXISTS(SELECT 1 FROM Location (NOLOCK) WHERE LocLITOCCCode = CtcTaxCode) AND (CtcTaxCode <> 'OR001') AND (CtcTaxCode <> 'NY006')
  AND (CtcTaxCode <> 'ORTRAN') --MT 20190521
  and CtcCountryCode = @Country AND @Country = 'USA'
IF @PRINT_LOCOCCTAX = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
--PRINT '!!Warning!!  OCC tax code setup, but not attached to any location.' --MT 20190521
PRINT '!!Warning!! 03-0018 Occupational tax code setup, but not attached to any location.' --MT 20190521
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
SELECT CtcTaxCode, CtcTaxCodeDesc
FROM TaxCode (NOLOCK)
WHERE CtcLocalType = 'OCC' AND NOT EXISTS(SELECT 1 FROM Location (NOLOCK) WHERE LocLITOCCCode = CtcTaxCode) AND (CtcTaxCode <> 'OR001') AND (CtcTaxCode <> 'NY006')
  AND (CtcTaxCode <> 'ORTRAN') --MT 20190521
  and CtcCountryCode = @Country AND @Country = 'USA'
ORDER BY CtcTaxCode
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- MS 20181120 REPLACE
--Effective date is not 01/01 (of go-live year):

DECLARE @PRINT_EFFDATEGOLIVE CHAR(1)

SELECT @PRINT_EFFDATEGOLIVE = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM TaxCRate (NOLOCK)
JOIN (SELECT MAX(YEAR(TcrEffectiveDate)) MaxYear, TcrTaxCode FROM TaxCRate (NOLOCK) GROUP BY TcrTaxCode) MaxYear
       ON MaxYear.MaxYear = YEAR(TcrEffectiveDate) AND MaxYear.TcrTaxCode = TaxCRate.TcrTaxCode
JOIN Company (NOLOCK) ON CmpCoID = TcrCOID
WHERE TcrUseSystemRate = 'N' AND TcrContributionRate = 0 AND TcrHasBeenReplaced = 'N' AND LEFT(LTRIM(TaxCRate.TcrTaxCode),2) <> 'FN'
AND TaxCRate.TcrTaxCode LIKE '%SUIER' AND CmpIsSUIReimburse = 'N' AND TcrEffectiveDate <> YEAR(@LIVEDATE) + '0101'
and CmpCountryCode = @Country AND @Country = 'USA'

IF @ISGOLIVE = 'Y' AND @PRINT_EFFDATEGOLIVE = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 03-0019 Effective date on tax code setup is not 01/01 (of the go-live year).'
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
SELECT CmpCompanyCode, CmpCompanyName, TaxCRate.TcrTaxCode, CONVERT(VARCHAR,TcrEffectiveDate,101) TcrEffectiveDate, TcrContributionRate
FROM TaxCRate (NOLOCK)
JOIN (SELECT MAX(YEAR(TcrEffectiveDate)) MaxYear, TcrTaxCode FROM TaxCRate (NOLOCK) GROUP BY TcrTaxCode) MaxYear
       ON MaxYear.MaxYear = YEAR(TcrEffectiveDate) AND MaxYear.TcrTaxCode = TaxCRate.TcrTaxCode
JOIN Company (NOLOCK) ON CmpCoID = TcrCOID
WHERE TcrUseSystemRate = 'N' AND TcrContributionRate = 0 AND TcrHasBeenReplaced = 'N' AND LEFT(LTRIM(TaxCRate.TcrTaxCode),2) <> 'FN'
AND TaxCRate.TcrTaxCode LIKE '%SUIER' AND CmpIsSUIReimburse = 'N' AND TcrEffectiveDate <> YEAR(@LIVEDATE) + '0101'
and CmpCountryCode = @Country AND @Country = 'USA'
ORDER BY CmpCompanyCode, TaxCRate.TcrTaxCode
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- MS 20181120 REPLACE
--SUI HIGH LOW rate:

DECLARE @PRINT_SUI_HIGHLOW CHAR(1)

SELECT @PRINT_SUI_HIGHLOW = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM TaxCRate (NOLOCK)
JOIN (SELECT MAX(YEAR(TcrEffectiveDate)) MaxYear, TcrTaxCode FROM TaxCRate (NOLOCK) GROUP BY TcrTaxCode) MaxYear 
 ON MaxYear.MaxYear = YEAR(TcrEffectiveDate) AND MaxYear.TcrTaxCode = TaxCRate.TcrTaxCode
JOIN Company (NOLOCK) ON CmpCoID = TcrCOID
WHERE TcrUseSystemRate = 'N' AND TcrHasBeenReplaced = 'N' AND LEFT(LTRIM(TaxCRate.TcrTaxCode),2) <> 'FN'
AND TaxCRate.TcrTaxCode LIKE '%SUIER' AND CmpIsSUIReimburse = 'N'
AND (TcrContributionRate < 0.01 OR TcrContributionRate >= 0.15) AND TcrContributionRate != 0
and CmpCountryCode = @Country AND @Country = 'USA'
AND DATEPART(YEAR,@LIVEDATE) = DATEPART(YEAR,TcrEffectiveDate) --KF 10/15/2020 ADDED TO ONLY LOOK AT THE GO-LIVE YEAR

IF @PRINT_SUI_HIGHLOW = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 03-0020 Please review the following non-zero SUI rates (rate is either < 1% or >= 15%).'
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
SELECT CmpCompanyCode, CmpCompanyName, TaxCRate.TcrTaxCode, CONVERT(VARCHAR,TcrEffectiveDate,101) TcrEffectiveDate, TcrContributionRate 
FROM TaxCRate (NOLOCK)
JOIN (SELECT MAX(YEAR(TcrEffectiveDate)) MaxYear, TcrTaxCode FROM TaxCRate (NOLOCK) GROUP BY TcrTaxCode) MaxYear 
 ON MaxYear.MaxYear = YEAR(TcrEffectiveDate) AND MaxYear.TcrTaxCode = TaxCRate.TcrTaxCode
JOIN Company (NOLOCK) ON CmpCoID = TcrCOID
WHERE TcrUseSystemRate = 'N' AND TcrHasBeenReplaced = 'N' AND LEFT(LTRIM(TaxCRate.TcrTaxCode),2) <> 'FN'
AND TaxCRate.TcrTaxCode LIKE '%SUIER' AND CmpIsSUIReimburse = 'N'
AND (TcrContributionRate < 0.01 OR TcrContributionRate >= 0.15) AND TcrContributionRate != 0
and CmpCountryCode = @Country AND @Country = 'USA'
AND DATEPART(YEAR,@LIVEDATE) = DATEPART(YEAR,TcrEffectiveDate) --KF 10/15/2020 ADDED TO ONLY LOOK AT THE GO-LIVE YEAR
ORDER BY CmpCompanyCode, TaxCRate.TcrTaxCode
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
--Both "SUI reimbursable" and "Take SUI credit"  flags should NOT be flagged at the same time:
--ms 20181120 REPLACE
DECLARE @PRINT_SUIFLAGS CHAR(1)

SELECT @PRINT_SUIFLAGS = 'Y' 
FROM Company (NOLOCK)
WHERE CmpTakeSUICredit = 'Y' AND CmpIsSUIReimburse = 'Y'
  and CmpCountryCode = @Country AND @Country = 'USA'


IF @PRINT_SUIFLAGS = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 03-0021 Both "SUI reimbursable" and "Take SUI credit"  flags should NOT be flagged at the same time	'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT CmpCompanyName, CmpCompanyCode, CmpCoID, CmpIsExemptFromFUTA, CmpTakeSUICredit, CmpIsSUIReimburse,CmpIsExemptFromSDI
FROM Company (NOLOCK)
WHERE CmpTakeSUICredit = 'Y' AND CmpIsSUIReimburse = 'Y'
  and CmpCountryCode = @Country AND @Country = 'USA'

SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- MS 20181120 NEW
--Effective date is not 01/01 (of go-live year) CNEIER:

DECLARE @PRINT_EFFDATEGOLIVE_CNEIER CHAR(1)

SELECT @PRINT_EFFDATEGOLIVE_CNEIER = CASE WHEN TcrEffectiveDate <> DATEADD(yy, DATEDIFF(yy, 0, @LIVEDATE), 0) THEN 'Y' ELSE 'N' END
-- select CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM TaxCRate (NOLOCK)
JOIN (SELECT MAX(YEAR(TcrEffectiveDate)) MaxYear, TcrTaxCode FROM TaxCRate (NOLOCK) GROUP BY TcrTaxCode) MaxYear
       ON MaxYear.MaxYear = YEAR(TcrEffectiveDate) AND MaxYear.TcrTaxCode = TaxCRate.TcrTaxCode
JOIN Company (NOLOCK) ON CmpCoID = TcrCOID
WHERE TcrUseSystemRate = 'N' AND TcrHasBeenReplaced = 'N' 
AND TaxCRate.TcrTaxCode = 'CNEIER' --AND TcrEffectiveDate <> YEAR(@LIVEDATE) + '0101' 
AND @ISGOLIVE = 'Y'
and CmpCountryCode = @Country AND @Country = 'CAN'


IF @ISGOLIVE = 'Y' AND @PRINT_EFFDATEGOLIVE_CNEIER = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 03-0022 Effective date on tax code setup is not 01/01 (of the go-live year).'
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
SELECT CmpCompanyCode, CmpCompanyName, TaxCRate.TcrTaxCode, CONVERT(VARCHAR,TcrEffectiveDate,101) TcrEffectiveDate, TcrContributionRate
FROM TaxCRate (NOLOCK)
JOIN (SELECT MAX(YEAR(TcrEffectiveDate)) MaxYear, TcrTaxCode FROM TaxCRate (NOLOCK) GROUP BY TcrTaxCode) MaxYear
       ON MaxYear.MaxYear = YEAR(TcrEffectiveDate) AND MaxYear.TcrTaxCode = TaxCRate.TcrTaxCode
JOIN Company (NOLOCK) ON CmpCoID = TcrCOID
WHERE TcrUseSystemRate = 'N' AND TcrHasBeenReplaced = 'N' 
AND TaxCRate.TcrTaxCode = 'CNEIER' --AND TcrEffectiveDate <> YEAR(@LIVEDATE) + '0101' 
AND @ISGOLIVE = 'Y'
and CmpCountryCode = @Country AND @Country = 'CAN'
ORDER BY CmpCompanyCode, TaxCRate.TcrTaxCode
SET NOCOUNT OFF

PRINT ''
END
---------------------------------------------------------------------------------------------------------------------------------
-- MT 20181120 new
--Missing EI taxrate setup
DECLARE @PRINT_TaxCodeRatesMissing CHAR(1)

IF @COUNTRY = 'CAN'
BEGIN
	SELECT @PRINT_TaxCodeRatesMissing = 'Y'
	FROM Company (NOLOCK)
	LEFT JOIN TaxCRate (NOLOCK) ON CmpCoID = TcrCOID AND TcrTaxCode = 'CNEIER'
	WHERE CmpCountryCode = @Country AND @Country = 'CAN'
	AND TcrTaxCode IS NULL
END

IF @PRINT_TaxCodeRatesMissing = 'Y' AND @COUNTRY = 'CAN'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 03-0023 CNEIER Tax Rate is missing for Component Company.' 
PRINT ''
SET @ERRORCOUNT += 1

	SELECT CmpCompanyCode,TcrTaxCode
	FROM Company (NOLOCK)
	LEFT JOIN TaxCRate (NOLOCK) ON CmpCoID = TcrCOID AND TcrTaxCode = 'CNEIER'
	WHERE CmpCountryCode = @Country AND @Country = 'CAN'
	AND TcrTaxCode IS NULL
END

---------------------------------------------------------------------------------------------------------------------------------
-- MT 20181120 new
--Canada EI Tax Rate incorrect setup.
DECLARE @PRINT_CMP_EI CHAR(1)

IF @COUNTRY = 'CAN'
BEGIN
	SELECT @PRINT_CMP_EI = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
	-- select CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END, COUNT(*)
	FROM TaxCRate (NOLOCK)
	JOIN (SELECT MAX(YEAR(TcrEffectiveDate)) MaxYear, TcrTaxCode FROM TaxCRate (NOLOCK) GROUP BY TcrTaxCode) MaxYear 
		ON MaxYear.MaxYear = YEAR(TcrEffectiveDate) AND MaxYear.TcrTaxCode = TaxCRate.TcrTaxCode
	JOIN Company (NOLOCK) ON CmpCoID = TcrCOID
	WHERE CmpCountryCode = @Country AND @Country = 'CAN'
	AND TaxCRate.TcrTaxCode = 'CNEIER' 
	AND ISNULL(TcrContributionRate,0) = 0 
	AND TcrUseSystemRate = 'N' 
	AND TcrHasBeenReplaced = 'N' 
END

IF @PRINT_CMP_EI = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 03-0024 The following Component Company is missing EI Tax Rate.' 
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
	SELECT distinct CmpCompanyCode
	FROM TaxCRate (NOLOCK)
	JOIN (SELECT MAX(YEAR(TcrEffectiveDate)) MaxYear, TcrTaxCode FROM TaxCRate (NOLOCK) GROUP BY TcrTaxCode) MaxYear 
		ON MaxYear.MaxYear = YEAR(TcrEffectiveDate) AND MaxYear.TcrTaxCode = TaxCRate.TcrTaxCode
	JOIN Company (NOLOCK) ON CmpCoID = TcrCOID
	WHERE CmpCountryCode = @Country AND @Country = 'CAN'
	AND TaxCRate.TcrTaxCode = 'CNEIER' 
	AND ISNULL(TcrContributionRate,0) = 0 
	AND TcrUseSystemRate = 'N' 
	AND TcrHasBeenReplaced = 'N'  

SET NOCOUNT OFF

PRINT ''
END

---------------------------------------------------------------------------------------------------------------------------------
-- MT 20181120 new
--Canada EI System Tax Rate Setup:

DECLARE @PRINT_CMP_EI_Rate CHAR(1)
SET @PRINT_CMP_EI_Rate = 'Y'

IF @COUNTRY = 'CAN'
BEGIN
	SELECT @PRINT_CMP_EI_Rate = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
	FROM TaxCRate (NOLOCK)
	JOIN (SELECT MAX(YEAR(TcrEffectiveDate)) MaxYear, TcrTaxCode FROM TaxCRate (NOLOCK) GROUP BY TcrTaxCode) MaxYear 
		ON MaxYear.MaxYear = YEAR(TcrEffectiveDate) AND MaxYear.TcrTaxCode = TaxCRate.TcrTaxCode
	JOIN Company (NOLOCK) ON CmpCoID = TcrCOID
	WHERE CmpCountryCode = @Country AND @Country = 'CAN'
	AND TaxCRate.TcrTaxCode = 'CNEIER' 
	AND TcrContributionRate = 1.4
	AND TcrUseSystemRate <> 'Y'
	AND TcrHasBeenReplaced = 'N' 
END

IF @PRINT_CMP_EI_Rate  = 'Y' AND @COUNTRY = 'CAN'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 03-0025 The following Component Company must use System EI Tax Rate.' 
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
	SELECT CmpCompanyCode,TcrARNID,TcrContributionRate,TcrUseSystemRate,TcrHasBeenReplaced
	FROM TaxCRate (NOLOCK)
	JOIN (SELECT MAX(YEAR(TcrEffectiveDate)) MaxYear, TcrTaxCode FROM TaxCRate (NOLOCK) GROUP BY TcrTaxCode) MaxYear 
		ON MaxYear.MaxYear = YEAR(TcrEffectiveDate) AND MaxYear.TcrTaxCode = TaxCRate.TcrTaxCode
	JOIN Company (NOLOCK) ON CmpCoID = TcrCOID
	WHERE CmpCountryCode = @Country AND @Country = 'CAN'
	AND TaxCRate.TcrTaxCode = 'CNEIER' 
	AND TcrContributionRate = 1.4
	AND TcrUseSystemRate <> 'Y'
	AND TcrHasBeenReplaced = 'N'

SET NOCOUNT OFF

PRINT ''
END



---------------------------------------------------------------------------------------------------------------------------------
-- MT 20181120 new
--Canada Province Tax Setup:
DECLARE @PRINT_ProvinceTax CHAR(1)

SELECT @PRINT_ProvinceTax = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM TaxCode
JOIN Company ON CmpCOID = CtcCOID
WHERE CmpCountryCode = @Country AND @Country = 'CAN'
AND CtcTaxCode Like '%PIT'


IF @PRINT_ProvinceTax = 'N' AND @COUNTRY = 'CAN'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 03-0026 No Province Codes have been setup for Component Company.' 
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
	
	SELECT CmpCompanyCode, COUNT(*)
	FROM TaxCode
	JOIN Company ON CmpCOID = CtcCOID
	WHERE CmpCountryCode = @Country AND @Country = 'CAN'
	AND CtcTaxCode Like '%PIT'
	GROUP BY CmpCompanyCode

SET NOCOUNT OFF

PRINT ''
END
------------------------------------------------------------------------------------------------------------------------------------------
-- MS 20181120 NEW
--Effective date is not 01/01 (of go-live year) 'ONEHER','MBHPER','NLHPER','QCHSER':

DECLARE @PRINT_EFFDATEGOLIVE_CNEIER2 CHAR(1)

SELECT @PRINT_EFFDATEGOLIVE_CNEIER2 = CASE WHEN TcrEffectiveDate <> DATEADD(yy, DATEDIFF(yy, 0, @LIVEDATE), 0) THEN 'Y' ELSE 'N' END
FROM TaxCRate (NOLOCK)
JOIN (SELECT MAX(YEAR(TcrEffectiveDate)) MaxYear, TcrTaxCode FROM TaxCRate (NOLOCK) GROUP BY TcrTaxCode) MaxYear
       ON MaxYear.MaxYear = YEAR(TcrEffectiveDate) AND MaxYear.TcrTaxCode = TaxCRate.TcrTaxCode
JOIN Company (NOLOCK) ON CmpCoID = TcrCOID
WHERE TcrUseSystemRate = 'N' AND TcrHasBeenReplaced = 'N' 
--AND TaxCRate.TcrTaxCode IN ('ONEHER','MBHPER','NLHPER','QCHSER') 
AND TaxCRate.TcrTaxCode IN ('ONEHER', 'MBHPER', 'NLHPER', 'QCHSER', 'BCEHER') --KF 10/15/2020 ADDED BCEHER PER Aviva Murphy REQUEST
AND TcrEffectiveDate <> YEAR(@LIVEDATE) + '0101' 
AND @ISGOLIVE = 'Y'
and CmpCountryCode = @Country AND @Country = 'CAN'

IF @ISGOLIVE = 'Y' AND @PRINT_EFFDATEGOLIVE_CNEIER2 = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 03-0027 Effective date on tax code setup is not 01/01 (of the go-live year).  Please validate with customer if the rates changed.'
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
SELECT CmpCompanyCode, CmpCompanyName, TaxCRate.TcrTaxCode, CONVERT(VARCHAR,TcrEffectiveDate,101) TcrEffectiveDate, TcrContributionRate
FROM TaxCRate (NOLOCK)
JOIN (SELECT MAX(YEAR(TcrEffectiveDate)) MaxYear, TcrTaxCode FROM TaxCRate (NOLOCK) GROUP BY TcrTaxCode) MaxYear
       ON MaxYear.MaxYear = YEAR(TcrEffectiveDate) AND MaxYear.TcrTaxCode = TaxCRate.TcrTaxCode
JOIN Company (NOLOCK) ON CmpCoID = TcrCOID
WHERE TcrUseSystemRate = 'N' AND TcrHasBeenReplaced = 'N' 
--AND TaxCRate.TcrTaxCode IN ('ONEHER','MBHPER','NLHPER','QCHSER') --AND TcrEffectiveDate <> YEAR(@LIVEDATE) + '0101' 
AND TaxCRate.TcrTaxCode IN ('ONEHER', 'MBHPER', 'NLHPER', 'QCHSER', 'BCEHER') --KF 10/15/2020 ADDED BCEHER PER Aviva Murphy REQUEST
AND @ISGOLIVE = 'Y'
and CmpCountryCode = @Country AND @Country = 'CAN'
ORDER BY CmpCompanyCode, TaxCRate.TcrTaxCode
SET NOCOUNT OFF

PRINT ''
END

---------------------------------------------------------------------------------------------------------------------------------
-- MT 20181120 new
-- Canada Provincial tax codes missing rates.
DECLARE @PRINT_ProvTaxCodeRates CHAR(1)

IF @COUNTRY = 'CAN'
BEGIN
	SELECT @PRINT_ProvTaxCodeRates = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
	--SELECT TcrContributionRate, TcrHasBeenReplaced, CtcCalcTaxAmt,* --, CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
	FROM TaxCRate (NOLOCK)
	JOIN (SELECT MAX(YEAR(TcrEffectiveDate)) MaxYear, TcrTaxCode FROM TaxCRate (NOLOCK) GROUP BY TcrTaxCode) MaxYear 
		ON MaxYear.MaxYear = YEAR(TcrEffectiveDate) AND MaxYear.TcrTaxCode = TaxCRate.TcrTaxCode
	JOIN Company (NOLOCK) ON CmpCoID = TcrCOID
	JOIN TaxCode ON TaxCRate.TcrTaxCode = CtcTaxCode
	WHERE CmpCountryCode = @Country AND @Country = 'CAN'
	--AND TaxCRate.TcrTaxCode IN ('ONEHER', 'MBHPER', 'NLHPER', 'QCHSER')  -- MRS 20190313 Aviva wants only these four
	AND TaxCRate.TcrTaxCode IN ('ONEHER', 'MBHPER', 'NLHPER', 'QCHSER', 'BCEHER') --KF 10/15/2020 ADDED BCEHER PER Aviva Murphy REQUEST
	AND TcrHasBeenReplaced = 'N'
	AND CtcCalcTaxAmt = 'Y'
	AND ISNULL(TcrContributionRate,0) = 0


	--SELECT @PRINT_ProvTaxCodeRates = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
	---- SELECT TcrContributionRate, TcrHasBeenReplaced, CtcCalcTaxAmt,* --, CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
	---- select CtcTaxCode,*
	--FROM Taxcode (NOLOCK)
	--	JOIN Company (NOLOCK) ON CmpCoID = ctcCOID
	--left JOIN TaxCRate ON TaxCRate.TcrTaxCode = CtcTaxCode
	----JOIN (SELECT MAX(YEAR(TcrEffectiveDate)) MaxYear, TcrTaxCode FROM TaxCRate (NOLOCK) GROUP BY TcrTaxCode) MaxYear 
	----	  ON MaxYear.MaxYear = YEAR(TcrEffectiveDate) AND MaxYear.TcrTaxCode = TaxCRate.TcrTaxCode
	--WHERE CmpCountryCode = 'CAN'
	--AND TaxCRate.TcrTaxCode IN ('ONEHER', 'MBHPER', 'NLHPER', 'QCHSER')  -- MRS 20190313 Aviva wants only these four
	--AND TcrHasBeenReplaced = 'N'
	--AND CtcCalcTaxAmt = 'Y'
	--AND ISNULL(TcrContributionRate,0) = 0
END

--***** if row in taxcode table AND CtcCalcTaxAmt = 'Y' then there needs to be an entry into the taxcrate table ***
  -- *****  for these for taxcodes if ctccalctaxamt = 'Y' then the  CtcIDNumber needs to be populate.  This will be a new validation,   Warning - Business number is missing for provincial tax code (list four codes)'
IF @PRINT_ProvTaxCodeRates = 'Y' AND @COUNTRY = 'CAN'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 03-0028 Tax Rate is missing for Provincial Tax Codes (ONEHER, MBHPER, NLHPER, QCHSER).' 
PRINT ''
SET @ERRORCOUNT += 1

	SELECT CmpCompanyCode, TaxCRate.TcrTaxCode, TcrContributionRate
	FROM TaxCRate (NOLOCK)
	JOIN (SELECT MAX(YEAR(TcrEffectiveDate)) MaxYear, TcrTaxCode FROM TaxCRate (NOLOCK) GROUP BY TcrTaxCode) MaxYear 
		ON MaxYear.MaxYear = YEAR(TcrEffectiveDate) AND MaxYear.TcrTaxCode = TaxCRate.TcrTaxCode
	JOIN Company (NOLOCK) ON CmpCoID = TcrCOID
	JOIN TaxCode ON TaxCRate.TcrTaxCode = CtcTaxCode
	WHERE CmpCountryCode = @Country AND @Country = 'CAN'
	--AND TaxCRate.TcrTaxCode IN ('ONEHER', 'MBHPER', 'NLHPER', 'QCHSER')  -- MRS 20190313 Aviva wants only these four
	AND TaxCRate.TcrTaxCode IN ('ONEHER', 'MBHPER', 'NLHPER', 'QCHSER', 'BCEHER') --KF 10/15/2020 ADDED BCEHER PER Aviva Murphy REQUEST
	AND TcrHasBeenReplaced = 'N'
	AND CtcCalcTaxAmt = 'Y'
	AND ISNULL(TcrContributionRate,0) = 0
END
---------------------------------------------------------------------------------------------------------------------------------
-- MT 20181120 new
-- Canada Provincial Tax Rate is setup however CalcTaxAmt = 'N'
DECLARE @PRINT_ProvTaxCodeRateNotCalc CHAR(1)

IF @COUNTRY = 'CAN'
BEGIN
	SELECT @PRINT_ProvTaxCodeRateNotCalc = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
	-- select TaxCRate.TcrTaxCode, TcrContributionRate, TcrHasBeenReplaced, CtcCalcTaxAmt --, 
	-- select CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
	FROM TaxCRate (NOLOCK)
	JOIN (SELECT MAX(YEAR(TcrEffectiveDate)) MaxYear, TcrTaxCode FROM TaxCRate (NOLOCK) GROUP BY TcrTaxCode) MaxYear 
		ON MaxYear.MaxYear = YEAR(TcrEffectiveDate) AND MaxYear.TcrTaxCode = TaxCRate.TcrTaxCode
	JOIN Company (NOLOCK) ON CmpCoID = TcrCOID
	JOIN TaxCode ON TaxCRate.TcrTaxCode = CtcTaxCode
	WHERE CmpCountryCode = @Country AND @Country = 'CAN'
	AND TaxCRate.TcrTaxCode IN ('ONEHER', 'MBHPER', 'NLHPER', 'QCHSER', 'BCEHER') --KF 10/15/2020 ADDED BCEHER PER Aviva Murphy REQUEST
	AND TcrHasBeenReplaced = 'N'
	AND CtcCalcTaxAmt = 'N'
	AND ISNULL(TcrContributionRate,0) <> 0
END

IF @PRINT_ProvTaxCodeRateNotCalc = 'Y' AND @COUNTRY = 'CAN'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 03-0029 Provincial tax rate is setup however calculate tax is turned off.' 
PRINT ''
SET @WARNINGCOUNT += 1
-- select * from taxcrate where  tcrtaxcode = 'ONEHER' --tcrcoid = 'DHQZ2' 
-- select cmpcoid from company where cmpcompanycode = 'flmcn' and
-- select * from taxcode where  ctctaxcode = 'ONEHER'
SELECT distinct CmpCompanyCode, CtcTaxCode, TcrContributionRate, CtcCalcTaxAmt
	FROM TaxCRate (NOLOCK)
	JOIN (SELECT MAX(YEAR(TcrEffectiveDate)) MaxYear, TcrTaxCode FROM TaxCRate (NOLOCK) GROUP BY TcrTaxCode) MaxYear 
		ON MaxYear.MaxYear = YEAR(TcrEffectiveDate) AND MaxYear.TcrTaxCode = TaxCRate.TcrTaxCode
	JOIN Company (NOLOCK) ON CmpCoID = TcrCOID
	JOIN TaxCode ON TaxCRate.TcrTaxCode = CtcTaxCode
	WHERE CmpCountryCode = @Country AND @Country = 'CAN'
	AND TaxCRate.TcrTaxCode IN ('ONEHER', 'MBHPER', 'NLHPER', 'QCHSER', 'BCEHER') --KF 10/15/2020 ADDED BCEHER PER Aviva Murphy REQUEST
	AND TcrHasBeenReplaced = 'N'
	AND CtcCalcTaxAmt = 'N'
	AND ISNULL(TcrContributionRate,0) <> 0
END

------------------------------------------------------------------------------------------------------------------------------------------
-- MS 20181120 NEW
DECLARE @PRINT_EFFDATEGOLIVE_PIT CHAR(1)

SELECT @PRINT_EFFDATEGOLIVE_PIT = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
--select ctctaxcode 
from taxcode
JOIN Company on cmpcoid = ctccoid
where ctctaxcode like '%PIT'
and not exists (select 1 from location where ctctaxcode = LocSITWorkInStateCode)
and CmpCountryCode = @Country AND @Country = 'CAN'

IF @ISGOLIVE = 'Y' AND @PRINT_EFFDATEGOLIVE_PIT = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 03-0030 Provincial taxcode setup and not attached to a location'
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
SELECT CmpCompanyCode, CmpCompanyName, ctctaxcode, CtcTaxCodeDesc
--select ctctaxcode 
from taxcode
JOIN Company on cmpcoid = ctccoid
where ctctaxcode like '%PIT'
and not exists (select 1 from location where ctctaxcode = LocSITWorkInStateCode)
and CmpCountryCode = @Country AND @Country = 'CAN'
ORDER BY CmpCompanyCode, ctctaxcode
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TL 20181120 new
--Find ARNID's with no calc rules

DECLARE @PRINT_ARNCALCRULE_WARNING CHAR(1)

SELECT @PRINT_ARNCALCRULE_WARNING = 'Y' 
from eracctrefno (NOLOCK)
join company (NOLOCK) on cmpcoid = anocoid
left outer join arncalculationrules (NOLOCK) on arrarnid = anoarnid
where arrarnid is null and CmpCountryCode = @Country AND @Country = 'CAN'

IF @PRINT_ARNCALCRULE_WARNING = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 03-0031 An ARNID is setup but no calculation rules have been added.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
select cmpcompanycode,cmpcompanyname, anoarnid, anodesc, anotaxcalcgroupid
from eracctrefno (NOLOCK)
join company (NOLOCK) on cmpcoid = anocoid
left outer join arncalculationrules (NOLOCK) on arrarnid = anoarnid
where arrarnid is null and CmpCountryCode = @Country AND @Country = 'CAN'

SET NOCOUNT OFF

PRINT ''
END
------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TL 20181120 new
--Find where ARNID's do not exist for the company

DECLARE @PRINT_NOARNID_WARNING CHAR(1)

SELECT @PRINT_NOARNID_WARNING = 'Y' 
from company (NOLOCK)
where not exists (select 1 from eracctrefno (NOLOCK) where cmpcoid = anocoid)
and CmpCountryCode = @Country AND @Country = 'CAN'

IF @PRINT_NOARNID_WARNING = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 03-0032 No ARNIDs are setup for the Canadian Component Company.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
select cmpcompanycode,cmpcompanyname
from company (NOLOCK)
where not exists (select 1 from eracctrefno (NOLOCK) where cmpcoid = anocoid)
and CmpCountryCode = @Country AND @Country = 'CAN'


SET NOCOUNT OFF

PRINT ''
END


------------------------------------------------------------------------------------------------------------------------------------------------------------
--Checks if all Companies are attached to a Paygroups:
-- JJ 20181120 new
DECLARE @Print_CountryPaygroup CHAR(1)

SELECT @Print_CountryPaygroup = 'Y'
from company (nolock)
where CmpCountryCode not in
(select pgrcountrycode from paygroup)
and ((@Country = 'CAN' and CmpCountryCode != 'USA') or (@Country = 'USA' and CmpCountryCode != 'CAN'))


IF @Print_CountryPaygroup = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 03-0034 Please review your Pay Group setup.  There is a Global Company with no Paygroup attached.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
select CmpCountryCode from company (nolock)
where CmpCountryCode not in
(select pgrcountrycode from paygroup)
and ((@Country = 'CAN' and CmpCountryCode != 'USA') or (@Country = 'USA' and CmpCountryCode != 'CAN'))
ORDER BY CmpCountryCode
SET NOCOUNT OFF

PRINT ''
END
------------------------------------------------------------------------------------------------------------------------------------------
--KF 20190528 NEW

DECLARE @Print_PRSTEPS CHAR(1)

SELECT @Print_CountryPaygroup = 'Y'
-- select PrsStepSetID, PrsProcessID, PrsOutOfSeqAction
from prsteps where PrsProcessID in ('cddnacha', 'prntchks', 'prntddas')
and PrsOutOfSeqAction = 'P'


IF @Print_PRSTEPS = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 03-0035 Payroll step set in BO has incorrect "out of sequence action" for certain steps. Please correct.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
select PrsStepSetID, PrsProcessID, PrsOutOfSeqAction
from prsteps where PrsProcessID in ('cddnacha', 'prntchks', 'prntddas')
and PrsOutOfSeqAction = 'P'
order by 1,2
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
--KF 20190528 NEW

DECLARE @PRINT_TAXNM CHAR(1)

SELECT @PRINT_TAXNM = CASE WHEN ISNULL(TaxCount,0) >= 2 AND WcrState IS NOT NULL THEN 'N' ELSE 'Y' END 
FROM TaxCode (NOLOCK)
JOIN Company (NOLOCK) ON CmpCoID = CtcCOID
LEFT OUTER JOIN (SELECT CtcCOID, COUNT(*) TaxCount FROM TaxCode WHERE CtcTaxCode IN ('NMWCEE', 'NMWCER','NMWCEP') GROUP BY CtcCOID) x ON x.CtcCOID = CmpCoID 
LEFT OUTER JOIN WCRisk (NOLOCK) ON WcrState = LEFT(LTRIM(TaxCode.CtcTaxCode),2) AND WcrCoID = TaxCode.CtcCOID
WHERE CtcTaxCode = 'NMSUIER'
and CmpCountryCode = @Country AND @Country = 'USA'

IF @PRINT_TAXNM = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 03-0036 New Mexico tax codes and/or Workers Comp codes are not set up correctly.'
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
SELECT CmpCompanyName, x.CtcTaxCode, WcrState 
FROM TaxCode (NOLOCK)
JOIN Company (NOLOCK) ON CmpCoID = CtcCOID
LEFT OUTER JOIN (SELECT CtcCOID, CtcTaxCode FROM TaxCode WHERE CtcTaxCode IN ('NMWCEE', 'NMWCER','NMWCEP')) x ON x.CtcCOID = CmpCoID
LEFT OUTER JOIN WCRisk (NOLOCK) ON WcrState = LEFT(LTRIM(TaxCode.CtcTaxCode),2) AND WcrCoID = TaxCode.CtcCOID
WHERE TaxCode.CtcTaxCode = 'NMSUIER'
and CmpCountryCode = @Country AND @Country = 'USA'
ORDER BY CmpCompanyName, x.CtcTaxCode
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
--KF 20190528 NEW

DECLARE @PRINT_SIT_MISSINGORTRAN CHAR(1)

SELECT @PRINT_SIT_MISSINGORTRAN = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM TaxCode (NOLOCK)
JOIN Company (NOLOCK) ON CmpCoID = CtcCOID
WHERE CtcTaxCode = 'ORSIT' AND NOT EXISTS(SELECT 1 FROM TaxCode (NOLOCK) WHERE CtcTaxCode LIKE 'ORT%')
and CmpCountryCode = @Country AND @Country = 'USA'

IF @PRINT_SIT_MISSINGORTRAN = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 03-0037 Please add ORTRAN tax code to company setup'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT CmpCompanyName, CtcTaxCode
FROM TaxCode (NOLOCK)
JOIN Company (NOLOCK) ON CmpCoID = CtcCOID
WHERE CtcTaxCode = 'ORSIT' AND NOT EXISTS(SELECT 1 FROM TaxCode (NOLOCK) WHERE CtcTaxCode LIKE 'ORT%')
and CmpCountryCode = @Country AND @Country = 'USA'
ORDER BY CmpCompanyName, CtcTaxCode
SET NOCOUNT OFF
  
PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
--KF 20190528 NEW

DECLARE @PRINT_LOCATIONNM CHAR(1)

SELECT @PRINT_LOCATIONNM = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM Location (NOLOCK)
WHERE LocSITWorkInStateCode = 'NMSIT' AND LocLITResWorkInCode <> 'NMWCEE' AND LocLITOCCCode <> 'NMWCER'
and LocAddressCountry = @Country AND @Country = 'USA'

IF @PRINT_LOCATIONNM = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 03-0038 The following NM Locations do not have the correct NM local codes.' 
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
SELECT LocCode, LocLITResWorkInCode, LocLITNonResWorkInCode, LocLITOCCCode 
FROM Location (NOLOCK)
WHERE LocSITWorkInStateCode = 'NMSIT' AND LocLITResWorkInCode <> 'NMWCEE' AND LocLITOCCCode <> 'NMWCER' 
and LocAddressCountry = @Country AND @Country = 'USA'
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
--KF 20190528 NEW

DECLARE @WAGE_LIMIT_NY006 CHAR(1)

SELECT @WAGE_LIMIT_NY006 = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
From taxcode JOIN company ON cmpcoid = ctccoid
WHERE ctctaxcode = 'NY006'
AND NOT EXISTS (SELECT 1 From taxcrate WHERE tcrcoid = ctccoid AND ctctaxcode = tcrtaxcode)
and CmpCountryCode = @Country AND @Country = 'USA'


IF @WAGE_LIMIT_NY006 = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 03-0039 Incorrect NY006 configuration. Please add rate at component company level.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT cmpcompanyname, cmpcompanycode, ctctaxcode, 'NY Commuter Tax NY006' AS TAX_DESC
From taxcode JOIN company ON cmpcoid = ctccoid
WHERE ctctaxcode = 'NY006'
AND NOT EXISTS (SELECT 1 From taxcrate WHERE tcrcoid = ctccoid AND ctctaxcode = tcrtaxcode)
and CmpCountryCode = @Country AND @Country = 'USA'
ORDER BY 1
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
--KF 20190528 NEW

DECLARE @MISSING_WA_LEAVE CHAR(1)

SELECT @MISSING_WA_LEAVE = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM TaxCode (NOLOCK)
JOIN Company (NOLOCK) ON CmpCoID = CtcCOID
WHERE CtcTaxCode = 'WASUIER' AND NOT EXISTS(SELECT 1 FROM TaxCode (NOLOCK) WHERE CtcTaxCode in ('WAPMLEE', 'WAPLMER', 'WAPFLEE', 'WAPFLEP'))
and CmpCountryCode = @Country AND @Country = 'USA'


IF @MISSING_WA_LEAVE = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 03-0040 Please add WA Paid Family and Medical Leave tax code to company setup.' 
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT CmpCompanyName, CtcTaxCode
FROM TaxCode (NOLOCK)
JOIN Company (NOLOCK) ON CmpCoID = CtcCOID
WHERE CtcTaxCode = 'WASUIER' AND NOT EXISTS(SELECT 1 FROM TaxCode (NOLOCK) WHERE CtcTaxCode in ('WAPMLEE', 'WAPLMER', 'WAPFLEE', 'WAPFLEP'))
and CmpCountryCode = @Country AND @Country = 'USA'
ORDER BY CmpCompanyName, CtcTaxCode
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- KF 20190614 NEW
	--KF 20190604 WILL NEED TO ADD IN LOGIC TO IGNORE OLD OR INVALID WARNINGS

DECLARE @TAX_0041 CHAR(1)

SELECT @TAX_0041 = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
-- SELECT DISTINCT CmpCompanyCode, CmpCompanyName, ctcTaxCode, tlcLinkCode,MtcIsTaxCodeLinked,mtctaxcalcrule,MtcEffectiveDate,MtcEffectiveStopDate
FROM company (NOLOCK)
JOIN TaxCode (NOLOCK) ON cmpCOID = ctcCOID
JOIN Ultipro_System..TxCdMast (NOLOCK) ON ctcTaxCode = MtcTaxCode
JOIN Ultipro_System..TxCdLink (NOLOCK) ON ctcTaxCode = TlcTaxCode
WHERE CmpCountryCode = 'USA' AND
(MtcIsTaxCodeLinked = 'Y') AND
(MtcHasBeenReplaced = 'N') AND
(MtcEffectiveDate <= GetDate()) AND
(MtcEffectiveStopDate >= GetDate()) AND
(CtcDoNotUseLink = 'N') AND
(CtcHasBeenReplaced = 'N') AND
(TlcNotActiveDate IS NULL OR TlcNotActiveDate >= GetDate())
AND mtctaxcalcrule <> 'I' --KF 10/15/2020 UPDATED
AND NOT EXISTS (SELECT 1 FROM TaxCode (NOLOCK) WHERE ctcTaxCode = tlcLinkCode)
AND NOT EXISTS (SELECT 1 FROM Ultipro_System..TxCdMast T2 WHERE T2.mtctaxcalcrule = 'I' AND tlcLinkCode = T2.mtcTaxCode AND (T2.MtcEffectiveDate <= GetDate()) AND (T2.MtcEffectiveStopDate >= GetDate())
) 


IF @TAX_0041 = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 03-0041 Missing linked tax code. Please be sure to added any that are needed.'
PRINT '*Verify with the customer and/or Tax ASC before adding NYSDIEP as this linked tax code is not always needed.' --KF 10/15/2020 updated
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
SELECT DISTINCT CmpCompanyCode, CmpCompanyName, ctcTaxCode, tlcLinkCode
--,MtcIsTaxCodeLinked,mtctaxcalcrule,MtcEffectiveDate,MtcEffectiveStopDate
FROM company (NOLOCK)
JOIN TaxCode (NOLOCK) ON cmpCOID = ctcCOID
JOIN Ultipro_System..TxCdMast (NOLOCK) ON ctcTaxCode = MtcTaxCode
JOIN Ultipro_System..TxCdLink (NOLOCK) ON ctcTaxCode = TlcTaxCode
WHERE CmpCountryCode = 'USA' AND
(MtcIsTaxCodeLinked = 'Y') AND
(MtcHasBeenReplaced = 'N') AND
(getdate() between MtcEffectiveDate and MtcEffectiveStopDate) and
--(MtcEffectiveDate <= GetDate()) AND
--(MtcEffectiveStopDate >= GetDate()) AND
(CtcDoNotUseLink = 'N') AND
(CtcHasBeenReplaced = 'N') AND
(TlcNotActiveDate IS NULL OR TlcNotActiveDate >= GetDate())
AND mtctaxcalcrule <> 'I' 
AND NOT EXISTS (SELECT 1 FROM TaxCode (NOLOCK) WHERE ctcTaxCode = tlcLinkCode)
AND NOT EXISTS (SELECT 1 FROM Ultipro_System..TxCdMast T2 WHERE T2.mtctaxcalcrule = 'I' AND tlcLinkCode = T2.mtcTaxCode AND (T2.MtcEffectiveDate <= GetDate()) AND (T2.MtcEffectiveStopDate >= GetDate())
) 

SET NOCOUNT OFF

PRINT ''
END



------------------------------------------------------------------------------------------------------------------------------------------

/** Locations **/

PRINT '____________________________________________________________________________________________________________________________________________________________'
PRINT ''
PRINT '4) Locations'
PRINT '____________________________________________________________________________________________________________________________________________________________'
PRINT ''

------------------------------------------------------------------------------------------------------------------------------------------

--Checks multiple locations for PA, IN, KY, OH:

DECLARE @PRINT_LOCMULTI CHAR(1)

SELECT @PRINT_LOCMULTI = 'Y' 
FROM Location (NOLOCK)
JOIN LocComp (NOLOCK) ON LcpCode = LocCode
WHERE LEFT(LTRIM(LocSITWorkInStateCode),2) + LcpCoID IN 
	(SELECT LEFT(LTRIM(LocSITWorkInStateCode),2) + LcpCoID 
	 FROM Location (NOLOCK)
	 JOIN LocComp (NOLOCK) ON LcpCode = LocCode
	 WHERE LEFT(LTRIM(LocSITWorkInStateCode),2) IN ('KY', 'PA', 'IN', 'OH')
	 GROUP BY LEFT(LTRIM(LocSITWorkInStateCode),2) + LcpCoID
	 HAVING COUNT(*) = 1)
and LocAddressCountry = @Country AND @Country = 'USA'

IF @PRINT_LOCMULTI = 'Y' 
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 04-0001 Only one location exists for PA, IN, KY, or OH.  Please review your location setup.'
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
SELECT CmpCompanyCode, LocCode, LocDesc, LocSITWorkInStateCode
FROM Location (NOLOCK)
JOIN LocComp (NOLOCK) ON LcpCode = LocCode
JOIN Company (NOLOCK) ON LcpCoID = CmpCoID
WHERE LEFT(LTRIM(LocSITWorkInStateCode),2) + LcpCoID IN 
	(SELECT LEFT(LTRIM(LocSITWorkInStateCode),2) + LcpCoID 
	 FROM Location (NOLOCK)
	 JOIN LocComp (NOLOCK) ON LcpCode = LocCode 
	 WHERE LEFT(LTRIM(LocSITWorkInStateCode),2) IN ('KY', 'PA', 'IN', 'OH')
	 GROUP BY LEFT(LTRIM(LocSITWorkInStateCode),2) + LcpCoID
	 HAVING COUNT(*) = 1)
and LocAddressCountry = @Country AND @Country = 'USA'
ORDER BY CmpCompanyCode, LocCode
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- MS 20181120 REPLACE
--Locations with MWR, but address info missing:

DECLARE @PRINT_MWRMISSINGINFO CHAR(1)

SELECT @PRINT_MWRMISSINGINFO = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM Location (NOLOCK)
WHERE LocReportingUnitNo IS NOT NULL 
  AND (LocAddressCity IS NULL OR LocAddressLine1 IS NULL OR LocAddressState IS NULL OR LocAddressZipcode IS NULL)
and LocAddressCountry = @Country AND @Country = 'USA'

IF @PRINT_MWRMISSINGINFO = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 04-0002 Location(s) are setup for MWR, but setup is missing address.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT LocCode, LocReportingUnitNo, SUBSTRING(LocAddressCity,1,30) LocAddressCity , SUBSTRING(LocAddressLine1,1,30) LocAddressLine1,  
   SUBSTRING(LocAddressLine2,1,30) LocAddressLine2, SUBSTRING(LocAddressState,1,30) LocAddressState, SUBSTRING(LocAddressZipcode,1,12) LocAddressZipCode
FROM Location (NOLOCK)
WHERE LocReportingUnitNo IS NOT NULL 
  AND (LocAddressCity IS NULL OR LocAddressLine1 IS NULL OR LocAddressState IS NULL OR LocAddressZipcode IS NULL)
and LocAddressCountry = @Country AND @Country = 'USA'
ORDER BY LocCode
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- MS 201811220 REPLACE - ADDED WHERE CLAUSE TO OUTPUT
--No locations with MWR:

DECLARE @PRINT_MWRMISSING CHAR(1)

SELECT @PRINT_MWRMISSING = CASE WHEN COUNT(*) = 0 THEN 'N' ELSE 'Y' END
-- select CASE WHEN COUNT(*) = 0 THEN 'Y' ELSE 'N' END
FROM Location (NOLOCK)
--WHERE LocReportingUnitNo IS NOT NULL
WHERE LocReportingUnitNo IS NULL --KF 10/15/2020 UPDATED
and LocAddressCountry = @Country AND @Country = 'USA'


IF @PRINT_MWRMISSING = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 04-0003 There are no locations setup for MWR.'
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
SELECT LocCode, LocReportingUnitNo, SUBSTRING(LocAddressCity,1,30) LocAddressCity , SUBSTRING(LocAddressLine1,1,30) LocAddressLine1,  
   SUBSTRING(LocAddressLine2,1,30) LocAddressLine2, SUBSTRING(LocAddressState,1,30) LocAddressState, SUBSTRING(LocAddressZipcode,1,12) LocAddressZipCode
FROM Location (NOLOCK)
WHERE LocReportingUnitNo IS NULL --KF logic is that if all locations are NULL for LocReportingUnitNo display the message and list the locations that have a NULL
and LocAddressCountry = @Country AND @Country = 'USA'
ORDER BY LocCode
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- MS 20181120 REPLACE
--List of locations with MWR:

DECLARE @PRINT_MWR CHAR(1)

SELECT @PRINT_MWR = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM Location (NOLOCK)
WHERE LocReportingUnitNo IS NOT NULL
and LocAddressCountry = @Country AND @Country = 'USA'

IF @PRINT_MWR = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Info!! 04-0004 The following locations have Worksite Reporting ID''s (MWR).'
PRINT ''
SET @LISTCOUNT += 1
-- KF missing error/warning message and counter

SET NOCOUNT ON
SELECT LocCode, LocReportingUnitNo, SUBSTRING(LocAddressCity,1,30) LocAddressCity , SUBSTRING(LocAddressLine1,1,30) LocAddressLine1,  
   SUBSTRING(LocAddressLine2,1,30) LocAddressLine2, SUBSTRING(LocAddressState,1,30) LocAddressState, SUBSTRING(LocAddressZipcode,1,12) LocAddressZipCode
FROM Location (NOLOCK)
WHERE LocReportingUnitNo IS NOT NULL
and LocAddressCountry = @Country AND @Country = 'USA'
ORDER BY LocCode
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- KF 20190604 NEW

DECLARE @LOC_NY001 CHAR(1)

SELECT @LOC_NY001 = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
-- SELECT LocCode, LocDesc, locsitworkinstatecode, loclitresworkincode
FROM Location (NOLOCK)
WHERE loclitresworkincode = 'NY001'
AND locsitworkinstatecode = 'NYSIT'
and LocAddressCountry = @Country AND @Country = 'USA'


IF @LOC_NY001 = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 04-0005 Location setup should NOT have NY001 local tax code (resident address).'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT LocCode, LocDesc, locsitworkinstatecode, loclitresworkincode
FROM Location (NOLOCK)
WHERE loclitresworkincode = 'NY001'
AND locsitworkinstatecode = 'NYSIT'
and LocAddressCountry = @Country AND @Country = 'USA'
ORDER BY LocCode
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- KF 20190604 NEW

DECLARE @LOC_MDSIT CHAR(1)

SELECT @LOC_MDSIT = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
-- SELECT LocCode, LocDesc, locsitworkinstatecode, loclitresworkincode
FROM Location (NOLOCK)
WHERE loclitresworkincode IS NOT NULL AND locsitworkinstatecode = 'MDSIT' 
and LocAddressCountry = @Country AND @Country = 'USA'


IF @LOC_MDSIT = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 04-0006 Maryland Local Taxes are paid where the employee lives. This location is set up to have work in taxes calculated. Please remove county.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT LocCode, LocDesc, locsitworkinstatecode, loclitresworkincode
FROM Location (NOLOCK)
WHERE loclitresworkincode IS NOT NULL AND locsitworkinstatecode = 'MDSIT' 
and LocAddressCountry = @Country AND @Country = 'USA' 
ORDER BY LocCode
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- KF 20190604 NEW

DECLARE @LOC_KY001 CHAR(1)

SELECT @LOC_KY001 = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
-- SELECT LocCode, LocDesc, loclitresworkincode, loclitocccode
FROM Location (NOLOCK)
WHERE loclitresworkincode = 'KY001' 
AND loclitocccode = 'KY049'
and LocAddressCountry = @Country AND @Country = 'USA'



IF @LOC_KY001 = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 04-0007 KY001 and KY049 should not be setup together in the same location setup. Please remove KY049.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT LocCode, LocDesc, loclitresworkincode, loclitocccode
FROM Location (NOLOCK)
WHERE loclitresworkincode = 'KY001' 
AND loclitocccode = 'KY049'
and LocAddressCountry = @Country AND @Country = 'USA'
ORDER BY LocCode
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- KF 20190604 NEW

DECLARE @LOC_QCPIT CHAR(1)

SELECT @LOC_QCPIT = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
-- SELECT loccode, locsitworkinstatecode, loclitothercode, locqeidcode
FROM Location (NOLOCK)
WHERE locsitworkinstatecode = 'QCPIT' 
AND (LTRIM(RTRIM(ISNULL(loclitothercode,''))) IN ('',' ') OR LTRIM(RTRIM(ISNULL(locqeidcode,''))) IN ('',' '))
and LocAddressCountry = @Country AND @Country = 'CAN'


IF @LOC_QCPIT = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 04-0008 Other Tax Code and QEID code should be populated for Quebec locations.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT loccode, locsitworkinstatecode, loclitothercode, locqeidcode
FROM Location (NOLOCK)
WHERE locsitworkinstatecode = 'QCPIT' 
AND (LTRIM(RTRIM(ISNULL(loclitothercode,''))) IN ('',' ') OR LTRIM(RTRIM(ISNULL(locqeidcode,''))) IN ('',' '))
and LocAddressCountry = @Country AND @Country = 'CAN'
ORDER BY LocCode
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- KF 20190604 NEW

DECLARE @LOC_NEED_LOCAL_TAX CHAR(1)

SELECT @LOC_NEED_LOCAL_TAX = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
--SELECT loccode AS LocCode, locdesc AS LocDesc, locsitworkinstatecode AS Work_State, loclitworkincounty AS WorkInCounty,
--	loclitresworkincode AS WorkInCode, loclitwcccode AS WC_Code,  
--	loclitocccode AS OCC_Code, loclitothercode AS Other_Code,  locaddressline1 AS AddrLine1, locaddresscity AS AddrCity,
--	locaddressstate AS Addrstate,  locaddresszipcode AS AddrZip 
FROM location 
WHERE ((locsitworkinstatecode = 'PASIT' AND LocLatitude is NULL AND ((loclitresworkincode IS NULL) OR (loclitocccode IS NULL) OR (loclitothercode IS NULL))) 
OR (locsitworkinstatecode = 'INSIT' AND LocLatitude is NULL AND loclitnonresworkincode IS NULL)
OR (locsitworkinstatecode = 'OHSIT' AND LocLatitude is NULL AND loclitresworkincode IS NULL)) 
and LocAddressCountry = @Country AND @Country = 'USA'


IF @LOC_NEED_LOCAL_TAX = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 04-0009 These states required local taxes (OH, IN, PA). Please review setup of location.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT loccode AS LocCode, locdesc AS LocDesc, locsitworkinstatecode AS Work_State, loclitworkincounty AS WorkInCounty,
	loclitresworkincode AS WorkInCode, loclitwcccode AS WC_Code,  
	loclitocccode AS OCC_Code, loclitothercode AS Other_Code,  locaddressline1 AS AddrLine1, locaddresscity AS AddrCity,
	locaddressstate AS Addrstate,  locaddresszipcode AS AddrZip 
FROM location 
WHERE ((locsitworkinstatecode = 'PASIT' AND LocLatitude is NULL AND ((loclitresworkincode IS NULL) OR (loclitocccode IS NULL) OR (loclitothercode IS NULL))) 
OR (locsitworkinstatecode = 'INSIT' AND LocLatitude is NULL AND loclitnonresworkincode IS NULL)
OR (locsitworkinstatecode = 'OHSIT' AND LocLatitude is NULL AND loclitresworkincode IS NULL)) 
and LocAddressCountry = @Country AND @Country = 'USA'
ORDER BY LocCode
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- KF 20190604 NEW

DECLARE @LOC_POSSIBLE_LOCAL_TAX CHAR(1)

SELECT @LOC_POSSIBLE_LOCAL_TAX = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
--SELECT loccode AS LocCode, locdesc AS LocDesc, locsitworkinstatecode AS Work_State, loclitworkincounty AS WorkInCounty,
-- loclitresworkincode AS WorkInCode, loclitwcccode AS WC_Code,  
--loclitocccode AS OCC_Code, loclitothercode AS Other_Code,  locaddressline1 AS AddrLine1, locaddresscity AS AddrCity,
--locaddressstate AS Addrstate,  locaddresszipcode AS AddrZip 
FROM location 
WHERE locsitworkinstatecode in ('ALSIT', 'COSIT', 'DESIT','MISIT','NYSIT','NJSIT','KYSIT','WVSIT','CASIT','NVSIT','ORSIT','WASIT','MOSIT')
AND LocLatitude is NULL and LocAddressCountry = @Country AND @Country = 'USA'


IF @LOC_POSSIBLE_LOCAL_TAX = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 04-0010 Please review setup of the following locations as these states may require locals: AL, CO, DE, MI, NY, NJ, KY, WV, CA, NV, OR, WA, MO.'
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
SELECT loccode AS LocCode, locdesc AS LocDesc, locsitworkinstatecode AS Work_State, loclitworkincounty AS WorkInCounty,
 loclitresworkincode AS WorkInCode, loclitwcccode AS WC_Code,  
loclitocccode AS OCC_Code, loclitothercode AS Other_Code,  locaddressline1 AS AddrLine1, locaddresscity AS AddrCity,
locaddressstate AS Addrstate,  locaddresszipcode AS AddrZip 
FROM location 
WHERE locsitworkinstatecode in ('ALSIT', 'COSIT', 'DESIT','MISIT','NYSIT','NJSIT','KYSIT','WVSIT','CASIT','NVSIT','ORSIT','WASIT','MOSIT')
AND LocLatitude is NULL and LocAddressCountry = @Country AND @Country = 'USA'
ORDER BY LocCode
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
	
/** Banks **/

PRINT '____________________________________________________________________________________________________________________________________________________________'
PRINT ''
PRINT '5) Banks'
PRINT '____________________________________________________________________________________________________________________________________________________________'
PRINT ''

------------------------------------------------------------------------------------------------------------------------------------------
-- MS 20181120 REPLACE
--Bank	If client is using UltiPro Check Print Service or if the client is printing checks on blank stock, 
--is the Print MICR box selected?	Bank	BNKBnkChkPrnMICR, BnkMicrAcctNo, BnkBankName	
--If Criteria5 = 'Y' and (BNKBnkChkPrnMICR is NULL or BnkMicrAcctNo IS NULL) and BnkChkFmt = 'USGCKP'	


DECLARE @CHKPRINT_BANKFLAG CHAR(1), @CHKPRINT_ACCTNUM CHAR(1), @CHKPRINT_BANKFLAG_CAN CHAR(1), @CHKPRINT_ACCTNUM_CAN CHAR(1)

IF @ISCHECKPRINT = 'Y'
Begin
SELECT @CHKPRINT_BANKFLAG = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM Bank (NOLOCK)
JOIN CheckFmt (NOLOCK) ON BnkChkFmt = CfmFormatCode
WHERE ISNULL(BnkChkPrnMICR,'N') <> 'Y' AND CfmAsciiFormatCode = 'STDULTICHK'
and BnkCountryCode = @Country AND @Country = 'USA'

SELECT @CHKPRINT_ACCTNUM = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM Bank (NOLOCK)
JOIN CheckFmt (NOLOCK) ON BnkChkFmt = CfmFormatCode
WHERE ISNULL(BnkMicrAcctNo,'N') <> 'Y' AND CfmAsciiFormatCode = 'STDULTICHK'
and BnkCountryCode = @Country AND @Country = 'USA'

SELECT @CHKPRINT_BANKFLAG_CAN = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM Bank (NOLOCK)
JOIN CheckFmt (NOLOCK) ON BnkChkFmt = CfmFormatCode
WHERE ISNULL(BnkChkPrnMICR,'N') <> 'Y'  AND CfmAsciiFormatCode = 'STDULTICAN'
and BnkCountryCode = @Country AND @Country = 'CAN'

SELECT @CHKPRINT_ACCTNUM_CAN = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
-- SELECT CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END  --, CfmAsciiFormatCode,CfmAsciiFormatCode2,  *
FROM Bank (NOLOCK)
JOIN CheckFmt (NOLOCK) ON BnkChkFmt = CfmFormatCode
WHERE ISNULL(BnkMicrAcctNo,'N') <> 'Y' AND CfmAsciiFormatCode = 'STDULTICAN'
and BnkCountryCode = @Country AND @Country = 'CAN'
end

IF @CHKPRINT_BANKFLAG = 'Y' and  @CHKPRINT_ACCTNUM = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 05-0001 You are using the Ultipro Check Print Export format but you do not have the Bank flagged to print MICR or there is no MICR account number.'
PRINT ''
SET @ERRORCOUNT += 1 

SET NOCOUNT ON
SELECT BnkBankName, BnkChkPrnMICR, BnkMicrAcctNo
FROM Bank (NOLOCK)
JOIN CheckFmt (NOLOCK) ON BnkChkFmt = CfmFormatCode
WHERE (BnkChkPrnMICR IS NULL OR BnkMicrAcctNo IS NULL) AND CfmAsciiFormatCode = 'STDULTICHK'
  and BnkCountryCode = @Country AND @Country = 'USA'
ORDER BY BnkBankName
PRINT ''
END

IF @CHKPRINT_BANKFLAG_CAN = 'Y' and @CHKPRINT_ACCTNUM_CAN = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 05-0002 You are using the Ultipro Check Print Export format but you do not have the Bank flagged to print MICR or there is no MICR account number.'
PRINT ''
SET @ERRORCOUNT += 1 

SET NOCOUNT ON
SELECT BnkBankName, BnkChkPrnMICR, BnkMicrAcctNo
FROM Bank (NOLOCK)
JOIN CheckFmt (NOLOCK) ON BnkChkFmt = CfmFormatCode
WHERE (BnkChkPrnMICR IS NULL OR BnkMicrAcctNo IS NULL) AND CfmAsciiFormatCode = 'STDULTICAN'
  and BnkCountryCode = @Country AND @Country = 'CAN'
ORDER BY BnkBankName
SET NOCOUNT OFF
 
PRINT ''
END



------------------------------------------------------------------------------------------------------------------------------------------------------------
--Checks if ASCII is setup for Positive Pay File:
-- JJ 20181120 new
--'
DECLARE @Print_AsciiFormatCode CHAR(1)

IF @Country = 'CAN'
BEGIN
	SELECT @Print_AsciiFormatCode = 'Y'
	-- select *
	FROM Bank (NOLOCK)
	JOIN CheckFmt (NOLOCK) ON BnkChkFmt = CfmFormatCode
	WHERE CfmAsciiFormatCode2 is NULL 
	AND BnkCoBankID in (select PgrBankId from PayGroup)
	AND CfmAsciiFormatCode = 'STDULTICAN' 
END

IF @Country = 'USA'
BEGIN
	SELECT @Print_AsciiFormatCode = 'Y'
	-- select *
	FROM Bank (NOLOCK)
	JOIN CheckFmt (NOLOCK) ON BnkChkFmt = CfmFormatCode
	WHERE CfmAsciiFormatCode2 is NULL 
	AND BnkCoBankID in (select PgrBankId from PayGroup)
	AND CfmAsciiFormatCode = 'STDULTICHK'
END


IF @Print_AsciiFormatCode = 'N'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 05-0003 Please review your Positive Pay setup, check format has not been updated to use posi pay file.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON

IF @Country = 'CAN'
BEGIN
	SELECT BnkCoBankID,BnkBankName,CfmFormatCode,CfmFormatDesc,CfmOutputEngineType,CfmAsciiFormatCode,CfmAsciiFormatCode2
	FROM Bank (NOLOCK)
	JOIN CheckFmt (NOLOCK) ON BnkChkFmt = CfmFormatCode
	WHERE CfmAsciiFormatCode2 is NULL 
	AND BnkCoBankID in (select PgrBankId from PayGroup)
	AND CfmAsciiFormatCode = 'STDULTICAN' 
END

IF @Country = 'USA'
BEGIN
	SELECT BnkCoBankID,BnkBankName,CfmFormatCode,CfmFormatDesc,CfmOutputEngineType,CfmAsciiFormatCode,CfmAsciiFormatCode2
	FROM Bank (NOLOCK)
	JOIN CheckFmt (NOLOCK) ON BnkChkFmt = CfmFormatCode
	WHERE CfmAsciiFormatCode2 is NULL 
	AND BnkCoBankID in (select PgrBankId from PayGroup)
	AND CfmAsciiFormatCode = 'STDULTICHK'
END

SET NOCOUNT OFF

PRINT ''
END



------------------------------------------------------------------------------------------------------------------------------------------
-- ms 20181120 replace
--Please review your bank setup to ensure that you have a bank set up with the Ultipro Check Print Export format:
--05/21/2019 VA: This now should be an ERROR for all markets / all customers (USA / CAN)
--MT 20190521:  Added CAN to country check, and removed Mid Market flag

DECLARE @PRINTBANK_USGCKP CHAR(1), @PRINTBANK_USGCKP_CAN CHAR(1)

SELECT @PRINTBANK_USGCKP = CASE WHEN COUNT(*) = 0 THEN 'Y' ELSE 'N' END
FROM Bank (NOLOCK)
JOIN CheckFmt (NOLOCK) ON BnkChkFmt = CfmFormatCode
WHERE CfmAsciiFormatCode = 'STDULTICHK'

SELECT @PRINTBANK_USGCKP_CAN = CASE WHEN COUNT(*) = 0 THEN 'Y' ELSE 'N' END
FROM Bank (NOLOCK)
JOIN CheckFmt (NOLOCK) ON BnkChkFmt = CfmFormatCode
WHERE CfmAsciiFormatCode = 'STDULTICAN'

IF @ISCHECKPRINT = 'Y' AND @PRINTBANK_USGCKP = 'Y' AND @Country IN ('USA','CAN') --@Country = 'USA' --MT 20190521 ADDED CANADA
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
IF @ISMIDMARKET = 'Y' 
BEGIN 
PRINT '!!Error!! 05-0004 Please review your bank setup to ensure that you have a bank set up with the Ultipro Check Print Export format.' 
SET @ERRORCOUNT += 1
END

/* --MT 20190521 REMOVED MID MARKET CHECK
IF @ISMIDMARKET = 'N' 
BEGIN 
PRINT '!!Warning!! 05-0005 Please review your bank setup to ensure that you have a bank set up with the Ultipro Check Print Export format.' 
SET @WARNINGCOUNT += 1
END
PRINT ''
*/

PRINT ''
END

/* --MT 20190521 REMOVED MID MARKET CHECK
IF @ISCHECKPRINT = 'Y' AND @PRINTBANK_USGCKP_CAN = 'Y' AND @Country = 'CAN'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
IF @ISMIDMARKET = 'Y' 
BEGIN 
PRINT '!!Warning!! 05-0006 Please review your bank setup to ensure that you have a bank set up with the Ultipro Check Print Export format.' 
SET @@WARNINGCOUNT += 1
END
IF @ISMIDMARKET = 'N' 
BEGIN 
PRINT '!!Warning!! 05-0007 Please review your bank setup to ensure that you have a bank set up with the Ultipro Check Print Export format.' 
SET @WARNINGCOUNT += 1
END
PRINT ''

SET NOCOUNT ON
SELECT BnkCountryCode, BnkBankName, BnkChkFmt 
FROM Bank (NOLOCK)
ORDER BY BnkCountryCode, BnkBankName
SET NOCOUNT OFF

PRINT ''
END
*/

------------------------------------------------------------------------------------------------------------------------------------------

--Verify next Check/DDA number entered	Bank	BnkLastChkNo, BnkLastDDNo		(data):

IF @ISGOLIVE = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 05-0008 Verify next Check/DDA number entered before customer opens first live payroll.'
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
SELECT BnkBankName, BnkLastChkNo, BnkLastDDNo
FROM Bank (NOLOCK)
WHERE BnkCountryCode = @Country
ORDER BY BnkBankName
SET NOCOUNT OFF
END

------------------------------------------------------------------------------------------------------------------------------------------
-- MS 20181120 REPLACE
--CHECK FOR VALID LOGO FILE PATH:

DECLARE @PRINTBANK_LOGO CHAR(1), @PRINTBANK_LOGO_CAN CHAR(1)

SELECT @PRINTBANK_LOGO = 'Y'
FROM Bank (NOLOCK)
WHERE BnkChkLogoFileName IS NOT NULL AND LEFT(LTRIM(BnkChkLogoFileName),10) <> '\\US.SAAS\'
  and BnkCountryCode = @Country AND @Country = 'USA'


SELECT @PRINTBANK_LOGO_CAN = 'Y'
FROM Bank (NOLOCK)
WHERE BnkChkLogoFileName IS NOT NULL AND LEFT(LTRIM(BnkChkLogoFileName),10) <> '\\CA.SAAS\'
  and BnkCountryCode = @Country AND @Country = 'CAN'


IF @PRINTBANK_LOGO = 'Y' or @PRINTBANK_LOGO_CAN = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 05-0009 The following Banks have an invalid path for the Logo file.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT BnkCountrycode, BnkBankName, BnkChkLogoFileName
FROM Bank (NOLOCK)
WHERE BnkChkLogoFileName IS NOT NULL AND LEFT(LTRIM(BnkChkLogoFileName),10) <> '\\US.SAAS\'
  and BnkCountryCode = @Country AND @Country = 'USA'
ORDER BY BnkCountrycode, BnkBankName

SELECT BnkCountrycode, BnkBankName, BnkChkLogoFileName
FROM Bank (NOLOCK)
WHERE BnkChkLogoFileName IS NOT NULL AND LEFT(LTRIM(BnkChkLogoFileName),10) <> '\\CA.SAAS\'
  and BnkCountryCode = @Country AND @Country = 'CAN'
ORDER BY BnkCountrycode, BnkBankName

SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- MS 20181120 REPLACE
--CHECK FOR VALID SIGNATURE FILE PATH:

DECLARE @PRINTBANK_SIG CHAR(1), @PRINTBANK_SIG_CAN CHAR(1)

SELECT @PRINTBANK_SIG = 'Y'
FROM Bank (NOLOCK)
WHERE BnkChkSigFileName IS NOT NULL AND LEFT(LTRIM(BnkChkSigFileName),10) <> '\\US.SAAS\'
  and BnkCountryCode = @Country AND @Country = 'USA'

SELECT @PRINTBANK_SIG_CAN = 'Y'
FROM Bank (NOLOCK)
WHERE BnkChkSigFileName IS NOT NULL AND LEFT(LTRIM(BnkChkSigFileName),10) <> '\\CA.SAAS\'
  and BnkCountryCode = @Country AND @Country = 'CAN'

IF @PRINTBANK_SIG = 'Y' OR @PRINTBANK_SIG_CAN = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 05-0010 The following Banks have an invalid path for the Signature file.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT BnkCountrycode, BnkBankName, BnkChkSigFileName
FROM Bank (NOLOCK)
WHERE BnkChkSigFileName IS NOT NULL AND LEFT(LTRIM(BnkChkSigFileName),10) <> '\\US.SAAS\'
  and BnkCountryCode = @Country AND @Country = 'USA'
ORDER BY BnkCountrycode, BnkBankName

SELECT BnkCountrycode, BnkBankName, BnkChkSigFileName
FROM Bank (NOLOCK)
WHERE BnkChkSigFileName IS NOT NULL AND LEFT(LTRIM(BnkChkSigFileName),10) <> '\\CA.SAAS\'
  and BnkCountryCode = @Country AND @Country = 'CAN'
ORDER BY BnkCountrycode, BnkBankName
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- MS 20181120 REPLACE
--CHECK FOR INSTANT CHECK BANK:

DECLARE @PRINTBANK_INSTANT CHAR(1)

SELECT @PRINTBANK_INSTANT = CASE WHEN COUNT(*) = 0 THEN 'Y' ELSE 'N' END
FROM Bank (NOLOCK)
WHERE BnkUseForInstantCheck = 'Y'

IF @PRINTBANK_INSTANT = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 05-0011 You do not have a bank established for instant checks.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT BnkCountrycode, BnkBankName, BnkUseForInstantCheck
FROM Bank (NOLOCK)
ORDER BY BnkCountrycode, BnkBankName
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- MS 20181120 REPLACE
--BANK CA/NY FORMAT CHECK:

DECLARE @BANKCANY CHAR(1)

SELECT @BANKCANY = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM Bank (NOLOCK)
JOIN PayGroup (NOLOCK) ON PgrBankId = BnkCoBankID
JOIN PyGrComp (NOLOCK) ON PgcPayGroup = PgrPayGroup
JOIN Company (NOLOCK) ON CmpCoID = PgcCoID
WHERE EXISTS(SELECT 1 FROM TaxCode WHERE CtcState IN ('NY', 'CA') AND CtcCOID = CmpCoID)
AND NOT EXISTS(SELECT 1 
			   FROM CheckFmt 
			   WHERE BnkChkFmt = CfmFormatCode 
			   AND (CfmProgID = 'HRMSStdChecks.CheckCATop' OR CfmProgID = 'HRMSStdChecks.CheckCAOTTop' 
					OR CfmAsciiFormatCode = 'STDULTICHK' or CfmProgID = 'HRMSStdChecks.CheckWKJTop'
                       or CfmProgID = 'HRMSStdChecks.CheckWKJInfoSeal'))
and CmpCountryCode = @Country AND @Country = 'USA'

IF @BANKCANY = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 05-0012 The following companies have tax codes for NY and CA but the bank check format is not "California Version of Top Check" or "California OT Top Check" or "UltiPro Check Print Export Format".'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT DISTINCT CmpCompanyName, CmpCompanyCode, BnkChkFmt 
FROM Bank (NOLOCK)
JOIN PayGroup (NOLOCK) ON PgrBankId = BnkCoBankID
JOIN PyGrComp (NOLOCK) ON PgcPayGroup = PgrPayGroup
JOIN Company (NOLOCK) ON CmpCoID = PgcCoID
WHERE EXISTS(SELECT 1 FROM TaxCode WHERE CtcState IN ('NY', 'CA') AND CtcCOID = CmpCoID)
AND NOT EXISTS(SELECT 1 
			   FROM CheckFmt 
			   WHERE BnkChkFmt = CfmFormatCode 
			   AND (CfmProgID = 'HRMSStdChecks.CheckCATop' OR CfmProgID = 'HRMSStdChecks.CheckCAOTTop' 
					OR CfmAsciiFormatCode = 'STDULTICHK' or CfmProgID = 'HRMSStdChecks.CheckWKJTop'
                       or CfmProgID = 'HRMSStdChecks.CheckWKJInfoSeal'))
and CmpCountryCode = @Country AND @Country = 'USA'
ORDER BY CmpCompanyCode, BnkChkFmt
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- MS 20181120 REPLACE
--A bank does not have a banking institution assigned:

DECLARE @PRINT_BANKINSTMISSING CHAR(1)

SELECT @PRINT_BANKINSTMISSING = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM Bank (NOLOCK)
WHERE NULLIF(RTRIM(LTRIM(BnkInstitution)),'') IS NULL
and BnkCountryCode = @Country AND @Country = 'USA'

IF @PRINT_BANKINSTMISSING = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 05-0013 The following Banks do not have a Banking Institution assigned.  Please add a unique Banking Institution to the Bank.'  
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT BnkInstitution, BnkCoBankID, BnkBankName, BnkBankAcctNo 
FROM Bank (NOLOCK)
WHERE NULLIF(RTRIM(LTRIM(BnkInstitution)),'') IS NULL
and BnkCountryCode = @Country AND @Country = 'USA'
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- MS 20181120 REPLACE
--Number of Banks and Bank Institutions:
 

DECLARE @bankcount INT, @bankintcount INT
 set @bankintcount = 0

select  @bankcount = COUNT(*)
  from bank
   where bnkinstitution is null
     or bnkinstitution not in (select codcode 
FROM Codes (NOLOCK) 
WHERE CodTable = 'BANKINSTITUTION' AND CodCode <> 'U              ' 
and codCOUNTRYCODE = @Country AND @Country = 'USA')

--SELECT @bankcount = COUNT(*) FROM Bank (NOLOCK)
	
--SELECT @bankintcount = COUNT(*)
---- select *
--FROM Codes (NOLOCK) 
--WHERE CodTable = 'BANKINSTITUTION' AND CodCode <> 'U              '
--and codCOUNTRYCODE = @Country AND @Country = 'USA'

IF @bankcount <> @bankintcount AND @COUNTRY = 'USA'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 05-0014 Number of banking institutions does not equal the number of banks.  There should be a unique banking institution for each bank.'
PRINT ''
SET @WARNINGCOUNT += 1
END

------------------------------------------------------------------------------------------------------------------------------------------
--Bank account number in the Print MICR line is NOT the same as the account number:
-- ms 20181120 replace
DECLARE @PRINT_ACCTNOMISMATCH_CAN CHAR(1)

SELECT @PRINT_ACCTNOMISMATCH_CAN = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM Bank (NOLOCK)
WHERE BnkChkPrnMICR = 'Y'
AND BnkBankAcctNo <> CASE WHEN ISNUMERIC(RIGHT(BnkMicrAcctNo, 1)) <> 1
						  THEN [dbo].[dsi_fnRemoveChars] ('QWERTYUIOPASDFGHJKLZXCVBNM',BnkMicrAcctNo)
						  ELSE isnull(BnkMicrAcctNo,'') END
and BnkCountryCode = @Country AND @Country = 'USA'


IF @PRINT_ACCTNOMISMATCH_CAN = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 05-0015 Bank account number in the Print MICR line is NOT the same as the account number.  Canada'  
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT BnkCoBankID, BnkBankName, BnkChkPrnMICR, BnkBankAcctNo, BnkMicrAcctNo
, [dbo].[dsi_fnRemoveChars] ('QWERTYUIOPASDFGHJKLZXCVBNM',BnkMicrAcctNo)
FROM Bank (NOLOCK)
WHERE BnkChkPrnMICR = 'Y'
AND BnkBankAcctNo <> CASE WHEN ISNUMERIC(RIGHT(BnkMicrAcctNo, 1)) <> 1
						  THEN [dbo].[dsi_fnRemoveChars] ('QWERTYUIOPASDFGHJKLZXCVBNM',BnkMicrAcctNo)
						  ELSE isnull(BnkMicrAcctNo,'') END
and BnkCountryCode = @Country AND @Country = 'USA'
SET NOCOUNT OFF

PRINT ''
END
------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TL 20181120 new
--Company banking information missing

DECLARE @PRINT_NOBANKDD_WARNING CHAR(1)

SELECT @PRINT_NOBANKDD_WARNING = 'Y' 
from bank (NOLOCK)
where (bnkbankacctno is null or bnkbankroutingno is null or bnkinstitutionno is null)
and BnkCountryCode = @Country AND @Country = 'CAN'

IF @PRINT_NOBANKDD_WARNING = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 05-0016 Banking information is not populated for the following bank. Please update setup if needed.'
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
select bnkcountrycode,bnkbankname,bnkbankacctno,bnkbankroutingno,bnkinstitutionno
from bank (NOLOCK)
where (bnkbankacctno is null or bnkbankroutingno is null or bnkinstitutionno is null)
and BnkCountryCode = @Country AND @Country = 'CAN'


SET NOCOUNT OFF

PRINT ''
END



------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TL 20181120 new
--Find countries that have no banks attached.
--05/21/2019 VA: This should be an ERROR
--KF 20190522 UPDATED MESSAGE

DECLARE @PRINT_NOBANKI_WARNING CHAR(1)

SELECT @PRINT_NOBANKI_WARNING = 'Y' 
from company (NOLOCK)
where not exists (select 1 from bank (NOLOCK) where cmpcountrycode = bnkcountrycode) and cmpcountrycode = @country 

IF @PRINT_NOBANKI_WARNING = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
--PRINT '!!Warning!!  No Bank is setup for the following countries.' --KF 20190522 UPDATED MESSAGE
PRINT '!!Error!! 05-0017 No Bank is setup for the following countries.' --KF 20190522 UPDATED MESSAGE
PRINT ''
--SET @WARNINGCOUNT += 1
SET @ERRORCOUNT += 1


SET NOCOUNT ON
select cmpcountrycode 
from company (NOLOCK)
where not exists (select 1 from bank (NOLOCK) where cmpcountrycode = bnkcountrycode) and  cmpcountrycode = @country 


SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------

--CA/NY Check Format:

DECLARE @PRINTNYCACHECK CHAR(1)

SELECT @PRINTNYCACHECK = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM Bank (NOLOCK)
JOIN CheckFmt (NOLOCK) ON CfmFormatCode = BnkChkFmt
JOIN PayGroup (NOLOCK) ON BnkCoBankID = PgrBankId
WHERE CfmAsciiFormatCode = 'STDULTICHK' AND CfmDetailEarnings <> 'Y'
AND EXISTS(SELECT 1 FROM TaxCode WHERE CtcState IN ('CA', 'NY'))
and pgrcountrycode = @Country

IF @PRINTNYCACHECK = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 05-0018 A Bank exists with an UltiPro Check Print check format and CA and NY state taxes are configured.  Therefore, Detailed Earnings MUST be selected in the check format.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON	
SELECT PgrPayGroup, BnkCoBankID, BnkBankName, CfmFormatCode, CfmFormatDesc 
FROM Bank (NOLOCK)
JOIN CheckFmt (NOLOCK) ON CfmFormatCode = BnkChkFmt
JOIN PayGroup (NOLOCK) ON BnkCoBankID = PgrBankId
WHERE CfmAsciiFormatCode = 'STDULTICHK' AND CfmDetailEarnings <> 'Y'
AND EXISTS(SELECT 1 FROM TaxCode WHERE CtcState IN ('CA', 'NY'))
and pgrcountrycode = @Country
ORDER BY PgrPayGroup, BnkBankName
SET NOCOUNT OFF
	
PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------

--KF NEW 20190604

DECLARE @BANKPRENOTE1 CHAR(1)

SELECT @BANKPRENOTE1 = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
--SELECT BnkCoBankID,BnkBankName,BnkDDNoOfPrenoteDays
FROM Bank
WHERE BnkCountryCode = @Country
AND @Country = 'USA'
AND BnkDDNoOfPrenoteDays IS NULL

IF @BANKPRENOTE1 = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 05-0019 Bank BnkDDNoOfPrenoteDays IS NULL.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON	
SELECT BnkCoBankID,BnkBankName,BnkDDNoOfPrenoteDays
FROM Bank
WHERE BnkCountryCode = @Country
AND @Country = 'USA'
AND BnkDDNoOfPrenoteDays IS NULL
ORDER BY BnkCoBankID, BnkBankName
SET NOCOUNT OFF
	
PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------

--KF NEW 20190604

DECLARE @BANKPRENOTE2 CHAR(1)

SELECT @BANKPRENOTE2 = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
--SELECT BnkCoBankID,BnkBankName,BnkDDNoOfPrenoteDays
FROM Bank
WHERE BnkCountryCode = @Country
AND @Country = 'USA'
AND BnkDDNoOfPrenoteDays IS NOT NULL
AND BnkDDNoOfPrenoteDays NOT IN (0,6)

IF @BANKPRENOTE2 = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 05-0020 Please confirm prenote days in Bank table  to ensure proper setup (0 if no prenote or 6 if prenote).'
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON	
SELECT BnkCoBankID,BnkBankName,BnkDDNoOfPrenoteDays
FROM Bank
WHERE BnkCountryCode = @Country
AND @Country = 'USA'
AND BnkDDNoOfPrenoteDays IS NOT NULL
AND BnkDDNoOfPrenoteDays NOT IN (0,6)
ORDER BY BnkCoBankID, BnkBankName
SET NOCOUNT OFF
	
PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------

--KF NEW 20190604

DECLARE @BANK_0021 CHAR(1)

SELECT @BANK_0021 = CASE WHEN COUNT(*) = 0 THEN 'Y' ELSE 'N' END
FROM printservicescontacts


IF @BANK_0021 = 'Y' and @ISCHECKPRINT = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 05-0021 Please setup contact for Process Automation if Ulti print services = Y.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON	
SELECT *
FROM printservicescontacts
SET NOCOUNT OFF
	
PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------

--KF NEW 20190604

DECLARE @BANK_0022 CHAR(1)

SELECT @BANK_0022 = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
-- SELECT BnkCoBankID, BnkBankName
FROM Bank
WHERE ((BnkBankName LIKE '#') OR (BnkBankName LIKE '-') OR (BnkBankName LIKE '@') OR (BnkBankName LIKE '^') OR (BnkBankName LIKE '*'))


IF @BANK_0022 = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 05-0022 Please remove special character from Bank name.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON	
SELECT BnkCoBankID, BnkBankName
FROM Bank
WHERE ((BnkBankName LIKE '#') OR (BnkBankName LIKE '-') OR (BnkBankName LIKE '@') OR (BnkBankName LIKE '^') OR (BnkBankName LIKE '*'))
SET NOCOUNT OFF
	
PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------

/** Tax Groups **/

PRINT '____________________________________________________________________________________________________________________________________________________________'
PRINT ''
PRINT '6) Tax Groups'
PRINT '____________________________________________________________________________________________________________________________________________________________'
PRINT ''

------------------------------------------------------------------------------------------------------------------------------------------

--TAX GROUP COUNT COMPARISON:

DECLARE @TAXGROUPCOUNT INT
DECLARE @COMPONENTCOUNT INT
DECLARE @PRINTTAXGROUP_COUNT CHAR(1)

SELECT @TAXGROUPCOUNT = COUNT(*) FROM TaxGroup (NOLOCK) WHERE TgrCountryCode = 'USA'
SELECT @COMPONENTCOUNT = COUNT(*) FROM Company (NOLOCK) WHERE CmpCountryCode = 'USA'

IF @TAXGROUPCOUNT <> @COMPONENTCOUNT AND @COUNTRY = 'USA'
BEGIN
SET @PRINTTAXGROUP_COUNT = 'Y'
END

IF @PRINTTAXGROUP_COUNT = 'Y' AND @COUNTRY = 'USA'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 06-0001 Please review your Tax Group setup.  Check Tax Group setup to make sure that there are no component companies with different FEINs mapped to the same Tax Group.'
PRINT ''
SET @WARNINGCOUNT += 1

PRINT 'COUNT OF US TAX GROUPS:  ' + CONVERT(VARCHAR,@TAXGROUPCOUNT)
PRINT 'COUNT OF US COMPONENT COMPANIES:  ' + CONVERT(VARCHAR,@COMPONENTCOUNT)
PRINT ''

SET NOCOUNT ON
SELECT DISTINCT CmpCompanyName, TgrTaxCalcGroupDesc 
FROM TaxGroup (NOLOCK)
JOIN PyGrComp (NOLOCK) ON TgrTaxCalcGroupID = PgcTaxFilingClient
JOIN Company (NOLOCK) ON CmpCoID = PgcCoID AND CmpCountryCode = 'USA'
WHERE TgrCountryCode = 'USA'
ORDER BY CmpCompanyName
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
--MS 2011120 NEW
--TAX GROUP COUNT COMPARISON (can):

DECLARE @TAXGROUPCOUNT_CAN INT
DECLARE @COMPONENTCOUNT_CAN  INT
DECLARE @PRINTTAXGROUP_COUNT_CAN CHAR(1)

SELECT @TAXGROUPCOUNT_CAN = COUNT(*) FROM TaxGroup (NOLOCK) WHERE TgrCountryCode = 'CAN'
SELECT @COMPONENTCOUNT_CAN = COUNT(*) FROM Company (NOLOCK) WHERE CmpCountryCode = 'CAN'

IF @TAXGROUPCOUNT_CAN <> @COMPONENTCOUNT_CAN  AND @COUNTRY = 'CAN'
BEGIN
SET @PRINTTAXGROUP_COUNT_CAN = 'Y'
END

IF @PRINTTAXGROUP_COUNT_CAN = 'Y' AND @COUNTRY = 'CAN'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 06-0002 Please review your Tax Group setup.  Check Tax Group setup to make sure that there are no component companies with different BNs mapped to the same Tax Group.'
PRINT ''
SET @WARNINGCOUNT += 1

PRINT 'COUNT OF CAN TAX GROUPS:  ' + CONVERT(VARCHAR,@TAXGROUPCOUNT_CAN)
PRINT 'COUNT OF CAN COMPONENT COMPANIES:  ' + CONVERT(VARCHAR,@COMPONENTCOUNT_CAN)
PRINT ''
-- select * from PyGrComp   ***** review the joins.  maybe coid on TaxGroup  *****
SET NOCOUNT ON
SELECT DISTINCT CmpCompanyName, TgrTaxCalcGroupDesc , TgrCountryCode, CmpCountryCode
-- select TgrTaxCalcGroupID,*    -- select * from PyGrComp
FROM TaxGroup (NOLOCK)
JOIN PyGrComp (NOLOCK) ON TgrTaxCalcGrpRptID = Pgccoid
JOIN Company (NOLOCK) ON CmpCoID = PgcCoID 
WHERE TgrCountryCode = 'CAN'
ORDER BY CmpCompanyName
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- MS 20181120 REPLACE
--Checks if all Paygroups are attached to a TaxGroup:

DECLARE @PrintTaxGroup_PayGroup CHAR(1)

SELECT @PrintTaxGroup_PayGroup = 'Y'
FROM PayGroup (NOLOCK)
WHERE PgrStatus = 'A' AND PgrCountryCode = @COUNTRY AND PgrPayGroup NOT IN (SELECT DISTINCT PgcPayGroup FROM PyGrComp (NOLOCK))

IF @PrintTaxGroup_PayGroup = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 06-0003 Please review your Tax Group setup.  There is a paygroup that is not mapped to a Tax Group.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT PgrPayGroup
FROM PayGroup (NOLOCK)
WHERE PgrStatus = 'A' AND PgrCountryCode = @COUNTRY AND PgrPayGroup NOT IN (SELECT DISTINCT PgcPayGroup FROM PyGrComp (NOLOCK))
ORDER BY PgrPayGroup
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------------------------
--To return if January paydate does not exist for USA or CAN
-- TL 20181120 new
--05/21/2019 VA: this should be ERROR
--KF 20190522 UPDATED MESSAGE and statement to look for a January pay date in the go-live year that is the first monthly pay period number.


DECLARE @PRINT_PERCONTROLC_WARNING CHAR(1)

SELECT @PRINT_PERCONTROLC_WARNING = 'Y' 
-- select pgrcountrycode, pgrpaygroup, pgpperiodcontrol, PgpMonthlyPayPeriodNumber, DATEPART(year,'04/11/2004')
from paygroup (NOLOCK)
left outer join pgpayper (NOLOCK) on pgppaygroup = pgrpaygroup and substring(pgpperiodcontrol,5,2) = '01' and PgpMonthlyPayPeriodNumber = '1'
and PgpPeriodType = 'R'
where substring(pgpperiodcontrol,1,4) = DATEPART(year,@LIVEDATE)
and @country = pgrcountrycode 
and pgppaygroup is null 



IF @PRINT_PERCONTROLC_WARNING = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
--PRINT '!!Warning!!  The following paygroup has no beginning per control in January.' --KF 20190522 UPDATED MESSAGE
PRINT '!!Error!! 06-0005 The following paygroup has no beginning per control in January.' --KF 20190522 UPDATED MESSAGE
PRINT ''
--SET @WARNINGCOUNT += 1
SET @ERRORCOUNT += 1


SET NOCOUNT ON
select pgrcountrycode, pgrpaygroup--, pgpperiodcontrol, PgpMonthlyPayPeriodNumber
from paygroup (NOLOCK)
left outer join pgpayper (NOLOCK) on pgppaygroup = pgrpaygroup and substring(pgpperiodcontrol,5,2) = '01' and PgpMonthlyPayPeriodNumber = '1' --KF JUST VERIFIES THAT A JANUARY PAY DATE HAS 1 FOR PAY PERIOD NUMBER
and PgpPeriodType = 'R'
--where  pgppaygroup is null and @country = pgrcountrycode 
where substring(pgpperiodcontrol,1,4) = DATEPART(year,@LIVEDATE)
and @country = pgrcountrycode 
and pgppaygroup is null 
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- ms 20181120 replace
--Ensure the calendar starts in Jan for each paygroup:
--05/21/2019 VA: Possible duplicate. If so, please remove.

SET NOCOUNT ON
IF OBJECT_ID('tempdb..#PayGrps_JanPerCntrlLiveYr') IS NOT NULL DROP TABLE #PayGrps_JanPerCntrlLiveYr
IF OBJECT_ID('tempdb..#PayGrps_JanPerCntrlLiveYr2') IS NOT NULL DROP TABLE #PayGrps_JanPerCntrlLiveYr2

DECLARE @PRINT_PAYGRP_JANPERCONTROL CHAR(1)

SET NOCOUNT ON
SELECT PgpPayGroup, PgpPeriodControl, pgrcountrycode, PgrPayFrequency,
	CASE WHEN PgrPayFrequency = 'W' THEN 52
		 WHEN PgrPayFrequency = 'B' THEN 26
		 WHEN PgrPayFrequency = 'S' THEN 24
		 WHEN PgrPayFrequency = 'M' THEN 12 END AS MIN_PAYS_FOR_YEAR
INTO DBO.#PayGrps_JanPerCntrlLiveYr
-- SELECT DISTINCT PgrPayFrequency, PgpMonthlyPayPeriodNumber
FROM PgPayPer (NOLOCK)
join paygroup on pgrpaygroup = pgppaygroup
WHERE PgpPeriodType = 'R' --AND PgpMonthlyPayPeriodNumber = '1'
  AND PgpMonthlyPayPeriodNumber <> 0
  AND DATEPART(year,PgPayPer.PgpPayDate) = DATEPART(year,@LIVEDATE)
  --AND DATEPART(year, DATEADD(yy, DATEDIFF(yy, 0, PgPayPer.PgpPayDate), 0)) = DATEPART(year, DATEADD(yy, DATEDIFF(yy, 0, @LIVEDATE), 0)) 
  AND pgrcountrycode = @Country
  --AND PgrPayFrequency <> 'M'
GROUP BY PgpPayGroup, PgpPeriodControl, pgrcountrycode, PgrPayFrequency--, PgpMonthlyPayPeriodNumber
ORDER BY PgpPayGroup

--SELECT @PRINT_PAYGRP_JANPERCONTROL = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
--FROM  #PayGrps_JanPerCntrlLiveYr

SET NOCOUNT ON
SELECT PgpPayGroup, MIN_PAYS_FOR_YEAR, COUNT(*) AS PAY_COUNT, CASE WHEN COUNT(*) >= MIN_PAYS_FOR_YEAR THEN 'Y' ELSE 'N' END AS COUNT_MEETS_FREQUENCY
-- SELECT *
INTO DBO.#PayGrps_JanPerCntrlLiveYr2
FROM DBO.#PayGrps_JanPerCntrlLiveYr
GROUP BY PgpPayGroup, MIN_PAYS_FOR_YEAR


SELECT @PRINT_PAYGRP_JANPERCONTROL =  
(SELECT DISTINCT 'N'
FROM DBO.#PayGrps_JanPerCntrlLiveYr2
WHERE COUNT_MEETS_FREQUENCY = 'N')

--SELECT * FROM DBO.#PayGrps_JanPerCntrlLiveYr2

IF @PRINT_PAYGRP_JANPERCONTROL = 'N'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 06-0006 Payroll calendars should be setup for the entire year.' 
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
SELECT PgPayPer.PgpPayGroup, PgPayPer.PgpPeriodControl, PgpPayDate, PgpPeriodStartDate, PgpPeriodEndDate, PgpActive, PgpMonthlyPayPeriodNumber, PgpPeriodType, PgrPayFrequency
FROM PgPayPer (NOLOCK)
join paygroup on pgrpaygroup = pgppaygroup
WHERE PgpMonthlyPayPeriodNumber <> '0' AND PgpPeriodType = 'R'
  AND pgrcountrycode = @Country
  AND DATEPART(year,PgPayPer.PgpPayDate) = DATEPART(year,@LIVEDATE)
  AND EXISTS (SELECT 1 FROM DBO.#PayGrps_JanPerCntrlLiveYr2 Y2 WHERE Y2.PgpPayGroup = PgPayPer.PgpPayGroup AND  Y2.COUNT_MEETS_FREQUENCY = 'N')
  --AND PgrPayFrequency <> 'M'
ORDER BY PgpPayGroup, PgpPayDate, PgPayPer.PgpPeriodControl
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TL 20181120 new
--Find paygroup named "ALL"

DECLARE @PRINT_ALLPPI_WARNING CHAR(1)

SELECT @PRINT_ALLPPI_WARNING = 'Y' 
from PayGroup (NOLOCK)
--where PgrPayGroup = 'ALL' and @country = pgrcountrycode  --KF 10/15/2020 UPDATED PER Yvonne Ruiz
where PgrPayGroup in ('ALL','CON','PRN','AUX','NUL','COM1','COM2','COM3','COM4','COM5','COM6','COM7','COM8','COM9','COM0', --KF 10/15/2020 UPDATED PER Yvonne Ruiz
'LPT1','LPT2','LPT3','LPT4','LPT5','LPT6','LPT7','LPT8','LPT9','LPT0') and @country = pgrcountrycode  --KF 10/15/2020 UPDATED PER Yvonne Ruiz

IF @PRINT_ALLPPI_WARNING = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
--PRINT '!!Warning!! 06-0007 Pay group code should not be "ALL" (especially, if customer has multiple pay groups)'  --KF 10/15/2020 UPDATED
PRINT '!!Warning!! 06-0007 Pay group code should not be in the below list (especially, if customer has multiple pay groups)' --KF 10/15/2020 UPDATED
PRINT '"ALL, CON, PRN, AUX, NUL, COM1, COM2, COM3, COM4, COM5, COM6, COM7, COM8, COM9, COM0, LPT1, LPT2, LPT3, LPT4, LPT5, LPT6, LPT7, LPT8, LPT9, LPT0"' --KF 10/15/2020 UPDATED
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
select pgrcountrycode,PgrPayGroup,PgrDesc
from PayGroup (NOLOCK)
--where PgrPayGroup = 'ALL' and @country = pgrcountrycode  --KF 10/15/2020 UPDATED PER Yvonne Ruiz
where PgrPayGroup in ('ALL','CON','PRN','AUX','NUL','COM1','COM2','COM3','COM4','COM5','COM6','COM7','COM8','COM9','COM0', --KF 10/15/2020 UPDATED PER Yvonne Ruiz
'LPT1','LPT2','LPT3','LPT4','LPT5','LPT6','LPT7','LPT8','LPT9','LPT0') and @country = pgrcountrycode  --KF 10/15/2020 UPDATED PER Yvonne Ruiz

SET NOCOUNT OFF

PRINT ''
END

---------------------------------------------------------------------------------------------------------------------------------
-- MT 20181120 new
--Canada Tax group table RP Account number tab is not setup
--05/21/2019 VA: move to Tax Group section
--KF 05/23/2019 MOVED TO TAX GROUP SECTION

DECLARE @PRINT_RPAccount CHAR(1)

--IF @COUNTRY = 'CAN'
--BEGIN
SELECT @PRINT_RPAccount = CASE WHEN COUNT(CmpCompanyCode) = 0 THEN 'N' ELSE (CASE WHEN COUNT(*) = 0 THEN 'Y' ELSE 'N' END) END
FROM (
	SELECT CmpCompanyCode, TcrARNID, anoCOID
	FROM TaxCRate (NOLOCK)
	JOIN Company (NOLOCK) ON CmpCoID = TcrCOID AND CmpCountryCode = 'CAN'
	left JOIN ErAcctRefNo ON anoARNID = TcrARNID AND anoCoID = TcrCOID
	WHERE CmpCountryCode = 'CAN'
	AND TcrHasBeenReplaced = 'N'
	AND CmpCountryCode = @COUNTRY AND @COUNTRY = 'CAN'
	AND anoCOID is NULL
) X
--END

IF @PRINT_RPAccount = 'Y' --AND @COUNTRY = 'CAN'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 06-0008 Tax group table RP Account number tab is not setup for the following companies.' 
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
	SELECT CmpCompanyCode, TcrARNID, ErAcctRefNo.*
	FROM TaxCRate (NOLOCK)
	JOIN Company (NOLOCK) ON CmpCoID = TcrCOID AND CmpCountryCode = 'CAN'
	left JOIN ErAcctRefNo ON anoARNID = TcrARNID AND anoCoID = TcrCOID
	WHERE CmpCountryCode = 'CAN'
	AND TcrHasBeenReplaced = 'N'
	AND CmpCountryCode = @COUNTRY AND @COUNTRY = 'CAN'
	AND anoCOID is NULL
SET NOCOUNT OFF

PRINT ''
END

---------------------------------------------------------------------------------------------------------------------------------
-- MT 20181120 new
--Tax Groups Table Missing Employer ID #
--05/21/2019 VA: move to Tax Group section
--KF 05/23/2019 MOVED TO TAX GROUP SECTION

DECLARE @PRINT_QCProvTaxGrp_EmplID CHAR(1)

	SELECT @PRINT_QCProvTaxGrp_EmplID = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
		-- select  CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
	FROM Company
	LEFT JOIN QuebecERIDNo ON qidTaxCalcGroupID = CmpTaxCalcGroupID 
	WHERE Exists (Select 1 from TaxCode WHERE CtcCOID = CmpCOID AND CtcTaxCode = 'QCPIT')
	AND qidAddressState = 'QUEBEC' --KF ADDED
	AND qidTaxCalcGroupID IS NULL

IF @PRINT_QCProvTaxGrp_EmplID = 'Y' AND @Country = 'CAN'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 06-0009 Tax Groups Table is missing Quebec Employer ID Number.' 
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT CmpCompanyCode
	FROM Company
	LEFT JOIN QuebecERIDNo ON qidTaxCalcGroupID = CmpTaxCalcGroupID
	WHERE Exists (Select 1 from TaxCode WHERE CtcCOID = CmpCOID AND CtcTaxCode = 'QCPIT')
	AND qidAddressState = 'QUEBEC' --KF ADDED
	AND qidTaxCalcGroupID IS NULL

PRINT ''
END

---------------------------------------------------------------------------------------------------------------------------------
--KF 10/15/2020 NEW TEST PER Vanessa Arbelaez

BEGIN
IF @Country = 'USA'
BEGIN

DECLARE @06_0010 CHAR(1)

SELECT COUNT(TgrTaxCalcGrpRptID) CNT, CmpFedTaxID
INTO DBO.#TEMP_06_0010
FROM TaxGroup (NOLOCK)
JOIN Company (NOLOCK) ON CmpCoID = TgrTaxCalcGrpRptID AND CmpCountryCode = @Country
WHERE TgrCountryCode = @Country
GROUP BY CmpFedTaxID
HAVING COUNT(TgrTaxCalcGrpRptID) > 1

SELECT @06_0010 = 'Y'
FROM TaxGroup (NOLOCK)
JOIN Company (NOLOCK) ON CmpCoID = TgrTaxCalcGrpRptID AND CmpCountryCode = @Country
WHERE TgrCountryCode = @Country
AND EXISTS (SELECT 1 FROM DBO.#TEMP_06_0010 T WHERE T.CmpFedTaxID = Company.CmpFedTaxID)

IF @06_0010 = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 06-0010 Please review your Tax Group setup.  Check Tax Group setup to make sure that there are no different Tax Groups for the same FEIN.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT CmpCompanyName, TgrTaxCalcGroupDesc, CmpFedTaxID, TgrTaxCalcGrpRptID, CmpCOID, CmpCountryCode
FROM TaxGroup (NOLOCK)
JOIN Company (NOLOCK) ON CmpCoID = TgrTaxCalcGrpRptID AND CmpCountryCode = @Country
WHERE TgrCountryCode = @Country
AND EXISTS (SELECT 1 FROM DBO.#TEMP_06_0010 T WHERE T.CmpFedTaxID = Company.CmpFedTaxID)
ORDER BY 3,1

PRINT ''
END
END
IF @Country = 'USA' DROP TABLE DBO.#TEMP_06_0010  
END

------------------------------------------------------------------------------------------------------------------------------------------
	
/** Earnings **/

PRINT '____________________________________________________________________________________________________________________________________________________________'
PRINT ''
PRINT '7) Earnings'
PRINT '____________________________________________________________________________________________________________________________________________________________'
PRINT ''

------------------------------------------------------------------------------------------------------------------------------------------
-- MS 20181120 REPLACE

--EARNINGS START DATE CHECK:

DECLARE @PRINT_EARNDATE CHAR(1)

SELECT @PRINT_EARNDATE = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END 
FROM EarnCode (NOLOCK)
WHERE ErnActiveStatusAsOfDate <> '01/01/1950'
  AND ERNCOUNTRYCODE = @COUNTRY
  AND ErnIsActive = 'Y' --KF 09/08/2020 - Update to existing test to ignore earnings that are not active	

IF @PRINT_EARNDATE = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 07-0001 Start date does not equal 1/1/1950 for the following earning codes.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT ERNCOUNTRYCODE, ErnEarncode, ErnStubDesc, CONVERT(VARCHAR,ErnActiveStatusAsOfDate,101) ErnActiveStatusAsOfDate 
FROM EarnCode (NOLOCK)
WHERE ErnActiveStatusAsOfDate <> '01/01/1950'
  AND ERNCOUNTRYCODE = @COUNTRY
  AND ErnIsActive = 'Y' --KF 09/08/2020 - Update to existing test to ignore earnings that are not active
ORDER BY ERNCOUNTRYCODE, ErnEarnCode
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- MS 20181120 new
-- Validate earnings are not setup with the same code as deductions

DECLARE @PRINT_EARNFALSEOFFSET CHAR(1)

SELECT @PRINT_EARNFALSEOFFSET = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
from EarnCode 
join DedCode on ErnEarnCode = DedDedCode and (DedIsDedOffset = 'N' or ErnUseDedOffSet = 'N')
WHERE ERNCOUNTRYCODE = @COUNTRY
AND ErnIsActive = 'Y' --KF 09/08/2020 - Update to existing test to ignore earnings that are not active


IF @PRINT_EARNFALSEOFFSET = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 07-0002 The following earnings are setup with the same code as a deduction code and the deduction is not an offset.'  
PRINT '           Please delete the earning code and recreate it with different earning code.  Do not use the earning code copy feature.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT Erncountrycode, ErnEarnCode, ErnStubDesc, ErnUseDedOffSet, DedDedCode, DedStubDesc, DedIsDedOffset
from EarnCode 
join DedCode on ErnEarnCode = DedDedCode and (DedIsDedOffset = 'N' or ErnUseDedOffSet = 'N')
WHERE ERNCOUNTRYCODE = @COUNTRY
AND ErnIsActive = 'Y' --KF 09/08/2020 - Update to existing test to ignore earnings that are not active
order by Erncountrycode, ErnEarnCode

SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- ms 20181120 replace
--Is the earning set up to reduce an Accrual code:

DECLARE @PRINT_EARNACCR CHAR(1)

SELECT @PRINT_EARNACCR = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END 
FROM EarnCode (NOLOCK)
WHERE ErnAccrualCode IS NOT NULL AND ErnAccrualCode <> 'Z'
and ERNCOUNTRYCODE = @COUNTRY
AND ErnIsActive = 'Y' --KF 09/08/2020 - Update to existing test to ignore earnings that are not active

IF @PRINT_EARNACCR = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 07-0003 Verify that the following Earning codes should reduce the Accrual code.'
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
SELECT ErnEarnCode, ErnAccrualCode 
FROM EarnCode (NOLOCK)
WHERE ErnAccrualCode IS NOT NULL AND ErnAccrualCode <> 'Z'
and ERNCOUNTRYCODE = @COUNTRY
AND ErnIsActive = 'Y' --KF 09/08/2020 - Update to existing test to ignore earnings that are not active

ORDER BY ErnEarnCode
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- MS 20181120 replace
--Is there a unique earning group for 1099 wages?	Earncode	earnprog, earncode		

DECLARE @PRINT_1099ERNGRP CHAR(1)

SELECT @PRINT_1099ERNGRP = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END 
-- select CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END 
FROM EarnCode 
JOIN ULTIPRO_SYSTEM..ETaxCat (NOLOCK) ON EtcTaxCategory = ErnTaxCategory 
WHERE EtcDesc LIKE '%1099%'
  AND ErnCountryCode = @Country
  AND @Country = 'USA'

IF @PRINT_EARNACCR = 'N' AND @Country = 'USA'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 07-0004 Verify that a unique earning group has been setup for 1099 employees (if applicable).'
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
SELECT CegEarnGroupCode, CegEarnGroupDesc 
FROM EarnGrp (NOLOCK)
where CegCountryCode = 'USA'
ORDER BY CegEarnGroupCode
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- MS 20181120 replace
--HSA EARN CODE AND TAX CATEGORY CHECK:

DECLARE @PRINT_EARNHSA CHAR(1)

SELECT @PRINT_EARNHSA = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM EarnCode (NOLOCK)
WHERE ErnEarncode LIKE '%HSA%' AND ErnTaxCategory NOT IN ('HSAUP', 'HSAPY', 'HSNTU', 'HSNTP')
  AND ErnCountryCode = @Country 
  AND @Country = 'USA'
  AND ErnIsActive = 'Y' --KF 09/08/2020 - Update to existing test to ignore earnings that are not active

IF @PRINT_EARNHSA = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 07-0005 Please review the following Earning codes.  If HSA earnings, please update the tax category to ''''Health Savings Account'''' .'
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
SELECT ErnEarnCode, ErnTaxCategory
FROM EarnCode (NOLOCK)
WHERE ErnEarncode LIKE '%HSA%' AND ErnTaxCategory NOT IN ('HSAUP', 'HSAPY', 'HSNTU', 'HSNTP')
  AND ErnCountryCode = @Country 
  AND @Country = 'USA'
  AND ErnIsActive = 'Y' --KF 09/08/2020 - Update to existing test to ignore earnings that are not active
ORDER BY ErnEarnCode
SET NOCOUNT OFF

PRINT ''
END

--------------------------------------------------------------------------------------------------------------------------------------------------
--ms 20181120 replace
DECLARE @PRINT_Earngroup_GTL CHAR(1)

SELECT @PRINT_Earngroup_GTL = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END 
from dedcode (NOLOCK)
join earnprog on dedimputedearn = cepearncode
where cepautoadd = 'N'
  AND dedcountrycode = @Country AND @Country = 'USA'

IF @PRINT_Earngroup_GTL = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 07-0006 Verify earnings groups have GTL earnings code as auto-add.'
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
select CepEarnGroupCode, dedimputedearn 
from dedcode (NOLOCK)
join earnprog on dedimputedearn = cepearncode
where cepautoadd = 'N'
  AND dedcountrycode = @Country AND @Country = 'USA'
ORDER BY CepEarnGroupCode
SET NOCOUNT OFF

PRINT ''
END


------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------
-- ms 20181120 replace
--Checks if Earning RateFactor = 1 FOR OT/DT:
--05/21/2019 VA: update validation to separate test. For USA only: this should be ERROR and condition should be ((ErnIsOvertime = 'Y' AND ErnRateFactor > '0.5') or (ErnIsOvertime = 'N' AND ErnRateFactor > '1')). 
--KF 20190522 BROKE INTO USA AND CAN VALIDATIONS


DECLARE @PRINT_EARNRULES CHAR(1)

--IF @Country = 'CAN' 
--BEGIN
	SELECT @PRINT_EARNRULES = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
	FROM EarnCode (NOLOCK)
	JOIN Codes (NOLOCK) ON CodCode = ErnCalcRule AND CodTable = 'EarnCalcRule'
	WHERE ((ErnIsOvertime = 'Y' AND ErnRateFactor = '1') OR (ErnIsOvertime = 'N' AND ErnRateFactor > '1'))
	and erncountrycode = @Country
	AND @Country = 'CAN' 
	AND ErnIsActive = 'Y' --KF 09/08/2020 - Update to existing test to ignore earnings that are not active

	IF @PRINT_EARNRULES = 'Y'
	BEGIN
	PRINT '*************************************************************************************************************************************************'
	PRINT ''
	PRINT '!!Warning!! 07-0007 Warning – Please verify these rate factors are correct for these earning codes.'
	PRINT ''
	SET @WARNINGCOUNT += 1

	SET NOCOUNT ON
	SELECT Erncountrycode, ErnEarncode, ErnIsOvertime, ErnCalcRule, CodDesc, ErnRateFactor 
	FROM EarnCode (NOLOCK)
	JOIN Codes (NOLOCK) ON CodCode = ErnCalcRule AND CodTable = 'EarnCalcRule'
	WHERE ((ErnIsOvertime = 'Y' AND ErnRateFactor = '1') OR (ErnIsOvertime = 'N' AND ErnRateFactor > '1'))
		and erncountrycode = @Country
		AND @Country = 'CAN' 
		AND ErnIsActive = 'Y' --KF 09/08/2020 - Update to existing test to ignore earnings that are not active
	ORDER BY Erncountrycode, ErnEarnCode  
	SET NOCOUNT OFF

	PRINT '' 
	END
--END

------------------------------------------------------------------------------------------------------------------------------------------

DECLARE @PRINT_EARNRULES2 CHAR(1)
--05/21/2019 VA: update validation to separate test. For USA only: this should be ERROR and condition should be ((ErnIsOvertime = 'Y' AND ErnRateFactor > '0.5') or (ErnIsOvertime = 'N' AND ErnRateFactor > '1')). 

--IF @Country = 'USA' 
--	BEGIN
	SELECT @PRINT_EARNRULES2 = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
	FROM EarnCode (NOLOCK)
	JOIN Codes (NOLOCK) ON CodCode = ErnCalcRule AND CodTable = 'EarnCalcRule'
	WHERE ((ErnIsOvertime = 'Y' AND ErnRateFactor > '0.5') OR (ErnIsOvertime = 'N' AND ErnRateFactor > '1'))
	and erncountrycode = @Country 
	AND @Country = 'USA'
	AND ErnIsActive = 'Y' --KF 09/08/2020 - Update to existing test to ignore earnings that are not active

	IF @PRINT_EARNRULES2 = 'Y'
	BEGIN
	PRINT '*************************************************************************************************************************************************'
	PRINT ''
	PRINT '!!Warning!! 07-0008 There are Overtime EARNINGS WITH A RATE FACTOR that are not our preferred standard.  Please review with customer.'
	PRINT ''
	SET @WARNINGCOUNT += 1

	SET NOCOUNT ON
	SELECT Erncountrycode, ErnEarncode, ErnIsOvertime, ErnCalcRule, CodDesc, ErnRateFactor 
	FROM EarnCode (NOLOCK)
	JOIN Codes (NOLOCK) ON CodCode = ErnCalcRule AND CodTable = 'EarnCalcRule'
	WHERE ((ErnIsOvertime = 'Y' AND ErnRateFactor > '0.5') OR (ErnIsOvertime = 'N' AND ErnRateFactor > '1'))
		and erncountrycode = @Country
		AND @Country = 'USA'
		AND ErnIsActive = 'Y' --KF 09/08/2020 - Update to existing test to ignore earnings that are not active
	ORDER BY Erncountrycode, ErnEarnCode  
	SET NOCOUNT OFF

	PRINT '' 
	END
--END

------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------
-- ms 20181120 replace
--Checks if Earn CalcRule = 41:

DECLARE @PRINT_EARNRULES3 CHAR(1)

SELECT @PRINT_EARNRULES3 = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM EarnCode (NOLOCK)
JOIN Codes (NOLOCK) ON CodCode = ErnCalcRule AND CodTable = 'EarnCalcRule'
WHERE ErnCalcRule = '41'
  and erncountrycode = @Country
  AND ErnIsActive = 'Y' --KF 09/08/2020 - Update to existing test to ignore earnings that are not active
  

IF @PRINT_EARNRULES3 = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 07-0009 The following Earning Codes have a calculation rule of Flat amount, track hours.  Please verify setup.'
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
SELECT erncountrycode, ErnEarncode, ErnStubDesc, ErnCalcRule, CodDesc 'CalcRule Description'
FROM EarnCode (NOLOCK)
JOIN Codes (NOLOCK) ON CodCode = ErnCalcRule AND CodTable = 'EarnCalcRule'
WHERE ErnCalcRule = '41'
  and erncountrycode = @Country
  AND ErnIsActive = 'Y' --KF 09/08/2020 - Update to existing test to ignore earnings that are not active
ORDER BY erncountrycode, ErnEarnCode  
SET NOCOUNT OFF

PRINT '' 
END

------------------------------------------------------------------------------------------------------------------------------------------
-- ms 20181120 replace
--CHECK FOR EARNINGS WITHOUT OFFSET DEDUCTIONS:

DECLARE @PRINT_EARNOFFSET CHAR(1)

SELECT @PRINT_EARNOFFSET = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM EarnCode (NOLOCK)
LEFT OUTER JOIN DedCode (NOLOCK) ON ErnEarncode = DedDedCode
WHERE ErnUseDedOffset = 'Y' AND DedDedCode IS NULL
  and erncountrycode = @Country
  AND ErnIsActive = 'Y' --KF 09/08/2020 - Update to existing test to ignore earnings that are not active

IF @PRINT_EARNOFFSET = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 07-0010 The following earnings do not have offsetting deductions even though they are flagged to have offsetting deductions.'  
PRINT '           Please delete the earning code and recreate it.  Do not use the earning code copy feature.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT erncountrycode, ErnEarnCode, ErnUseDedOffSet, DedDedCode
FROM EarnCode (NOLOCK)
LEFT OUTER JOIN DedCode (NOLOCK) ON ErnEarncode = DedDedCode
WHERE ErnUseDedOffset = 'Y' AND DedDedCode IS NULL
  and erncountrycode = @Country
  AND ErnIsActive = 'Y' --KF 09/08/2020 - Update to existing test to ignore earnings that are not active
ORDER BY erncountrycode, ErnEarnCode
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- ms 20181120 replace
--If an earning is (not flagged as "Reg" OR "OT") AND (calculation rule is "PxHxR") AND ("Reduce scheduled hours" is not selected):
--05/21/2019 VA: update condition: WHERE ErnIsOvertime = 'N' AND ErnIsRegularPayCode = 'N' AND ErnCalcRule = '01' AND (ErnReduceRegHrs = 'N' OR ErnReduceRegDlrs = 'N')
--KF 20190522 UPDATED CONDITION

DECLARE @PRINT_EARNFLAG_SCHEDHRS CHAR(1)

SELECT @PRINT_EARNFLAG_SCHEDHRS =  CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE '' END
FROM EarnCode (NOLOCK)
WHERE ErnIsOvertime = 'N' AND ErnIsRegularPayCode = 'N' AND ErnCalcRule = '01' AND ErnReduceRegHrs = 'N' AND ErnReduceRegDlrs = 'N'
  and erncountrycode = @Country
  AND ErnIsActive = 'Y' --KF 09/08/2020 - Update to existing test to ignore earnings that are not active

IF @PRINT_EARNFLAG_SCHEDHRS = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 07-0011 The following Earning Codes are not flagged to reduce scheduled hours. Please review to ensure these settings are correct.'
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
SELECT erncountrycode, ErnEarncode, ErnStubDesc, ErnReduceRegHrs, ErnReduceRegDlrs
FROM EarnCode (NOLOCK)
--WHERE ErnIsOvertime = 'N' AND ErnIsRegularPayCode = 'N' AND ErnCalcRule = '01' AND ErnReduceRegHrs = 'N' AND ErnReduceRegDlrs = 'N' --KF 20190522 UPDATED CONDITION
WHERE ErnIsOvertime = 'N' AND ErnIsRegularPayCode = 'N' AND ErnCalcRule = '01' AND (ErnReduceRegHrs = 'N' OR ErnReduceRegDlrs = 'N') --KF 20190522 UPDATED CONDITION
  and erncountrycode = @Country
  AND ErnIsActive = 'Y' --KF 09/08/2020 - Update to existing test to ignore earnings that are not active
order by erncountrycode, ErnEarncode
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- ms 20181120 replace
--Earning is flagged as "Supp Wage":

DECLARE @PRINT_EARNFLAG_SUPPWAGE CHAR(1)

SELECT @PRINT_EARNFLAG_SUPPWAGE = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM EarnCode (NOLOCK)
WHERE (ErnIsSpecSupp = 'Y' OR ErnIsSuppWages = 'Y')
  and erncountrycode = @country
  and @country = 'USA'
  AND ErnIsActive = 'Y' --KF 09/08/2020 - Update to existing test to ignore earnings that are not active

IF @PRINT_EARNFLAG_SUPPWAGE = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 07-0012 The following earnings are flagged as Supp Wages. Please have customer confirm setup.'
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
SELECT ErnEarncode, ErnStubDesc, ErnIsSpecSupp, ErnIsSuppWages
FROM EarnCode (NOLOCK)
WHERE (ErnIsSpecSupp = 'Y' OR ErnIsSuppWages = 'Y')
  and erncountrycode = @country
  and @country = 'USA'
  AND ErnIsActive = 'Y' --KF 09/08/2020 - Update to existing test to ignore earnings that are not active
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- ms 20181120 replace
--No earnings are flagged as "Supp Wage":

DECLARE @PRINT_EARNFLAG_NOSUPP CHAR(1)

SELECT @PRINT_EARNFLAG_NOSUPP = CASE WHEN COUNT(*) = 0 THEN 'Y' ELSE 'N' END
-- select CASE WHEN COUNT(*) = 0 THEN 'Y' ELSE 'N' END
FROM EarnCode (NOLOCK)
WHERE (ErnIsSpecSupp = 'Y' OR ErnIsSuppWages = 'Y')
  and erncountrycode = @country
  and @country = 'USA'
  AND ErnIsActive = 'Y' --KF 09/08/2020 - Update to existing test to ignore earnings that are not active

IF @PRINT_EARNFLAG_NOSUPP = 'Y' and @country = 'USA'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 07-0013 There are no earnings flagged as Supp Wages.  Please review with customer and update configuration as necessary.'
PRINT ''
PRINT ''
SET @WARNINGCOUNT += 1
END

------------------------------------------------------------------------------------------------------------------------------------------
-- ms 20181120 replace
--If earning code tax cat is "Group Term Life", the earning is not flagged as DisplayinPDE NOR scheduled in payroll:
--05/21/2019 VA: This should be an ERROR
--KF 20190522 UPDATED MESSAGE

DECLARE @PRINT_EARNGTDFLAG CHAR(1)

SELECT @PRINT_EARNGTDFLAG = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM EarnCode (NOLOCK)
WHERE (ErnTaxCategory = 'GTLUP' OR ErnTaxCategory = 'GTDUP') AND ErnDisplayInPde = 'N'
  and erncountrycode = @country
  and @country = 'USA'
  AND ErnIsActive = 'Y' --KF 09/08/2020 - Update to existing test to ignore earnings that are not active

IF @PRINT_EARNGTDFLAG = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
--PRINT '!!Warning!! The GTL earning code is not flagged to "Display in PDE". Please update if calculation is to occur on every payroll.' --KF 20190522 UPDATED MESSAGE
PRINT '!!Error!! 07-0014 The GTL earning code is not flagged to "Display in PDE". Please update if calculation is to occur on every payroll.' --KF 20190522 UPDATED MESSAGE
PRINT ''
--SET @WARNINGCOUNT += 1
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT ErnEarncode, ErnStubDesc, ErnDisplayInPde
FROM EarnCode (NOLOCK)
WHERE (ErnTaxCategory = 'GTLUP' OR ErnTaxCategory = 'GTDUP') AND ErnDisplayInPde = 'N'
  and erncountrycode = @country
  and @country = 'USA'
  AND ErnIsActive = 'Y' --KF 09/08/2020 - Update to existing test to ignore earnings that are not active
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------

--Earnings code is setup to use deduction offset code, but no deduction offset linked to the earn code.

IF OBJECT_ID('tempdb..#ErnDedOffset') IS NOT NULL DROP TABLE #ErnDedOffset
IF OBJECT_ID('tempdb..#DedOffset') IS NOT NULL DROP TABLE #DedOffset

DECLARE @PRINT_EARNDED_UNLINKED CHAR(1)

SET NOCOUNT ON
SELECT erncountrycode, ErnEarnCode, ErnStubDesc, ErnUseDedOffset
INTO #ErnDedOffset
FROM EarnCode (NOLOCK)
WHERE ErnUseDedOffset = 'Y'
  and @country = erncountrycode

SET NOCOUNT ON
SELECT dedcountrycode, DedDedCode, DedStubDesc, DedIsDedOffSet
INTO #DedOffSet
FROM DedCode (NOLOCK)
WHERE DedIsDedOffSet = 'Y'  
  and @country = dedcountrycode     
SET NOCOUNT OFF

SELECT @PRINT_EARNDED_UNLINKED = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM #ErnDedOffset 
JOIN #DedOffSet ON ErnEarncode = DedDedCode and erncountrycode = dedcountrycode
WHERE DedDedCode NOT LIKE '%+' AND ((ErnUseDedOffset = 'N' AND DedIsDedOffSet = 'Y') OR (ErnUseDedOffset = 'Y' AND DedIsDedOffSet = 'N'))

IF @PRINT_EARNDED_UNLINKED = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 07-0015 Earnings code is setup to use deduction offset code; however, there is no deduction offset linked to the earn code.'  
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT erncountrycode, ErnEarnCode, ErnStubDesc 
FROM #ErnDedOffset  
where erncountrycode = @country
ORDER BY erncountrycode, ErnEarnCode

SELECT dedcountrycode, DedDedCode, DedStubDesc 
FROM #DedOffSet
ORDER BY dedcountrycode, DedDedCode                          

SELECT erncountrycode, ErnEarnCode, ErnStubDesc, DedDedCode, DedStubDesc 
FROM #ErnDedOffset 
JOIN #DedOffSet ON ErnEarncode = DedDedCode and erncountrycode = dedcountrycode
WHERE DedDedCode NOT LIKE '%+' AND ((ErnUseDedOffset = 'N' AND DedIsDedOffSet = 'Y') OR (ErnUseDedOffset = 'Y' AND DedIsDedOffSet = 'N'))
ORDER BY erncountrycode, ErnEarnCode
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- ms 20181120 replace
--If earn code uses coefficient OT or coefficient lookback, check that earn codes are flagged for FLSA:

DECLARE @PRINT_COEFF CHAR(1)

SELECT @PRINT_COEFF = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM EarnCode (NOLOCK)
JOIN Codes ON CodCode = ErnCalcRule
WHERE CodTable LIKE 'EarnCalc%' AND CodDesc LIKE '%Coeff%'
 and erncountrycode = @country
 and @country = 'USA'
 AND ErnIsActive = 'Y' --KF 09/08/2020 - Update to existing test to ignore earnings that are not active

IF @PRINT_COEFF = 'Y'
BEGIN
PRINT '!!Info!! 07-0016 The following earn codes are flagged to be included in the Coefficient OT calculation.  Please ensure all needed earn codes are flagged.'
PRINT ''
SET @LISTCOUNT += 1
-- KF missing error/warning message and counter

SET NOCOUNT ON
SELECT ErnEarnCode, ErnStubDesc, ErnInclInAvgHrsCalc, ErnInclInFLSAAvgPayCalc  
FROM EarnCode (NOLOCK)
WHERE (ErnInclInAvgHrsCalc = 'Y' OR ErnInclInFLSAAvgPayCalc = 'Y')
 and erncountrycode = @country
 and @country = 'USA'
 AND ErnIsActive = 'Y' --KF 09/08/2020 - Update to existing test to ignore earnings that are not active
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- ms 20181120 replace
--List earning codes with calculation expression and show if flagged for "display in pay data entry":

DECLARE @PRINT_DISPLAYINPDE CHAR(1)

SELECT @PRINT_DISPLAYINPDE = 'Y'
FROM EarnCode (NOLOCK)
WHERE ErnCalcRule = '90' AND ErnDisplayInPDE = 'Y'
  and erncountrycode = @country
  AND ErnIsActive = 'Y' --KF 09/08/2020 - Update to existing test to ignore earnings that are not active

IF @PRINT_DISPLAYINPDE = 'Y'
BEGIN
PRINT '!!Info!! 07-0017 List of earnings with calculation "expression" and flagged to display in PDE.'
PRINT ''
SET @LISTCOUNT += 1
-- KF missing error/warning message and counter

SET NOCOUNT ON
SELECT erncountrycode, ErnEarnCode, ErnStubDesc, ErnDisplayInPDE 
FROM EarnCode (NOLOCK)
WHERE ErnCalcRule = '90' AND ErnDisplayInPDE = 'Y'
  and erncountrycode = @country
  AND ErnIsActive = 'Y' --KF 09/08/2020 - Update to existing test to ignore earnings that are not active
order by  erncountrycode, ErnEarnCode
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- MS 20181120 REPLACE
--Earnings code < > time clock code (common mistake when cloning code in BO):

DECLARE @PRINT_ERNTIMECLOCK CHAR(1)

SELECT @PRINT_ERNTIMECLOCK = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM EarnCode (NOLOCK)
WHERE ErnEarncode <> ErnTimeclockCode
  and erncountrycode = @country
  AND ErnIsActive = 'Y' --KF 09/08/2020 - Update to existing test to ignore earnings that are not active

IF @PRINT_ERNTIMECLOCK = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 07-0018 Earnings time clock code does not match earnings code.  Please verify.'
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
SELECT erncountrycode, ErnEarncode, ErnTimeclockCode, ErnStubDesc 
FROM EarnCode (NOLOCK)
WHERE ErnEarncode <> ErnTimeclockCode
  and erncountrycode = @country
  AND ErnIsActive = 'Y' --KF 09/08/2020 - Update to existing test to ignore earnings that are not active
ORDER by erncountrycode, ErnEarncode
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- MS 20181120 REPLACE
--Earning code not in earning group:

DECLARE @PRINT_EARNGRP CHAR(1)

SELECT @PRINT_EARNGRP = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM EarnCode (NOLOCK)
WHERE NOT EXISTS(SELECT 1 FROM EarnProg (NOLOCK) WHERE CepEarnCode = ErnEarncode)
  and erncountrycode = @country
  AND ErnIsActive = 'Y' --KF 09/08/2020 - Update to existing test to ignore earnings that are not active

IF @PRINT_EARNGRP = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 07-0019 The following earning codes are not in any Earning Group:'
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
SELECT erncountrycode, ErnEarnCode, ErnLongDesc
FROM EarnCode (NOLOCK)
WHERE NOT EXISTS(SELECT 1 FROM EarnProg (NOLOCK) WHERE CepEarnCode = ErnEarncode)
  and erncountrycode = @country
  AND ErnIsActive = 'Y' --KF 09/08/2020 - Update to existing test to ignore earnings that are not active
ORDER BY erncountrycode, ErnEarnCode
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- ms 20181120 replace
--Earncode blocked for taxes:

DECLARE @PRINT_ERNBLOCK CHAR(1)

SELECT @PRINT_ERNBLOCK = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM EarnCode (NOLOCK)
WHERE (ErnBlockFIT = 'Y' OR ErnBlockSIT = 'Y' OR ErnBlockLIT = 'Y')
  and ErnCountryCode = @country AND @country = 'USA'
  AND ErnIsActive = 'Y' --KF 09/08/2020 - Update to existing test to ignore earnings that are not active

IF @PRINT_ERNBLOCK = 'Y' AND  @COUNTRY = 'USA'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 07-0020 The following earnings codes have FIT, SIT or LIT blocked. Please confirm with customer.'
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
SELECT ErnEarncode, ErnLongDesc, ErnBlockFIT, ErnBlockSIT, ErnBlockLIT
FROM EarnCode (NOLOCK)
WHERE (ErnBlockFIT = 'Y' OR ErnBlockSIT = 'Y' OR ErnBlockLIT = 'Y')
 and ErnCountryCode = @country AND @country = 'USA'
 AND ErnIsActive = 'Y' --KF 09/08/2020 - Update to existing test to ignore earnings that are not active
SET NOCOUNT OFF

PRINT ''
END

---------------------------------------------------------------------------------------------------------------------------------
-- MT 20181120 new
-- Validating for Earn Codes are Blocked For Taxes 
DECLARE @PRINT_EarnCodeBlockedTaxes CHAR(1)

	SELECT @PRINT_EarnCodeBlockedTaxes = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
	FROM EarnCode
	WHERE (ErnBlockFIT = 'Y' OR ErnBlockSIT = 'Y')
	and ErnCountryCode = @country AND @country = 'CAN'
	AND ErnIsActive = 'Y' --KF 09/08/2020 - Update to existing test to ignore earnings that are not active



IF @PRINT_EarnCodeBlockedTaxes = 'Y' AND  @COUNTRY = 'CAN'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 07-0021 Earn Codes are Blocked For Taxes.' 
PRINT ''
SET @WARNINGCOUNT += 1

	SELECT ErnEarnCode,ErnCountryCode,ErnBlockFIT,ErnBlockSIT,*
	FROM EarnCode
	WHERE (ErnBlockFIT = 'Y' OR ErnBlockSIT = 'Y')
	and ErnCountryCode = @country AND @country = 'CAN'
	AND ErnIsActive = 'Y' --KF 09/08/2020 - Update to existing test to ignore earnings that are not active

END

---------------------------------------------------------------------------------------------------------------------------------
-- KF 20190604 NEW

DECLARE @PRINT_Earn_90_93 CHAR(1)

SELECT @PRINT_Earn_90_93 = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
--SELECT ernearncode, ernlongdesc, erncalcrule
FROM earncode 
WHERE erncalcrule in ('90','93')
AND (erncustcalcexpkey IS NULL OR erncustcalcexpkey  = '')
AND ErnIsActive = 'Y' --KF 09/08/2020 - Update to existing test to ignore earnings that are not active


IF @PRINT_Earn_90_93 = 'Y' 
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 07-0022 Please update earning setup to add missing expression or change calc rule.' 
PRINT ''
SET @ERRORCOUNT += 1

SELECT ernearncode, ernlongdesc, erncalcrule
FROM earncode 
WHERE erncalcrule in ('90','93')
AND (erncustcalcexpkey IS NULL OR erncustcalcexpkey  = '')
AND ErnIsActive = 'Y' --KF 09/08/2020 - Update to existing test to ignore earnings that are not active

END

---------------------------------------------------------------------------------------------------------------------------------
-- KF 20190604 NEW

DECLARE @PRINT_REG_PDE CHAR(1)

SELECT @PRINT_REG_PDE = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
--SELECT ErnEarncode, ErnLongDesc, ErnIsRegularPayCode
FROM EarnCode (NOLOCK)
WHERE ErnIsRegularPayCode = 'Y' AND ErnDisplayInPde = 'N'
AND ErnIsActive = 'Y' --KF 09/08/2020 - Update to existing test to ignore earnings that are not active


IF @PRINT_REG_PDE = 'Y' 
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 07-0023 "Regular Pay Code" should be flagged to "display in PDE."' 
PRINT ''
SET @ERRORCOUNT += 1

SELECT ErnEarncode, ErnLongDesc, ErnIsRegularPayCode, ErnDisplayInPde
FROM EarnCode (NOLOCK)
WHERE ErnIsRegularPayCode = 'Y' AND ErnDisplayInPde = 'N'
AND ErnIsActive = 'Y' --KF 09/08/2020 - Update to existing test to ignore earnings that are not active

END

---------------------------------------------------------------------------------------------------------------------------------
-- KF 20190604 NEW

DECLARE @PRINT_CAN_OFFSET CHAR(1)

SELECT @PRINT_CAN_OFFSET = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
--SELECT ernearncode, ernusededoffset, erndisplayinpde
FROM earncode (NOLOCK)
WHERE ernusededoffset = 'Y' AND erndisplayinpde = 'N'
AND ERNCOUNTRYCODE = @COUNTRY AND @Country = 'CAN'
AND ErnIsActive = 'Y' --KF 09/08/2020 - Update to existing test to ignore earnings that are not active


IF @PRINT_CAN_OFFSET = 'Y' 
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 07-0024 Canada earn code setup with deduction offset is not flagged for Display in PDE. Please review.' 
PRINT ''
SET @WARNINGCOUNT += 1

SELECT ernearncode, ernusededoffset, erndisplayinpde
FROM earncode (NOLOCK)
WHERE ernusededoffset = 'Y' AND erndisplayinpde = 'N'
AND ERNCOUNTRYCODE = @COUNTRY AND @Country = 'CAN'
AND ErnIsActive = 'Y' --KF 09/08/2020 - Update to existing test to ignore earnings that are not active

END

------------------------------------------------------------------------------------------------------------------------------------------
--KF 09/08/2020 New test: ERROR: No earnings are flagged for accrual calculations when the company has PTO Plans with "per included hours" or "per included earnings" accrual rules.		

DECLARE @PRINT_ACCRINCLUDEB_ERROR CHAR(1)

SELECT @PRINT_ACCRINCLUDEB_ERROR = 'Y'
-- SELECT * -- Select * from ACCRINCL
FROM ACCROPTS (NOLOCK)
WHERE AccAccrCalcRule IN ('05','06')
--AND AccAccrCode NOT IN (SELECT AclAccrualCode FROM ACCRINCL (NOLOCK))
AND NOT EXISTS (SELECT 1 FROM ACCRINCL (NOLOCK) WHERE AclAccrualCode = AccAccrCode
	AND EXISTS (SELECT 1 FROM earncode (NOLOCK) WHERE ErnIsActive = 'Y' AND ernearncode = AclEarncode)) --KF 09/08/2020 - Update to existing test to ignore earnings that are not active
AND @country = acccountrycode

IF @PRINT_ACCRINCLUDEB_ERROR = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 07-0025 There are no earning codes flagged to be included in the accrual code plan calculation (included hours or included earnings).'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT DISTINCT AccCountryCode,AccAccrCode,AccAccrOption,AccAccrDesc,AccAccrCalcRule
FROM ACCROPTS (NOLOCK)
WHERE AccAccrCalcRule IN ('05','06')
--AND AccAccrCode NOT IN (SELECT AclAccrualCode FROM ACCRINCL (NOLOCK))
AND NOT EXISTS (SELECT 1 FROM ACCRINCL (NOLOCK) WHERE AclAccrualCode = AccAccrCode
	AND EXISTS (SELECT 1 FROM earncode (NOLOCK) WHERE ErnIsActive = 'Y' AND ernearncode = AclEarncode)) --KF 09/08/2020 - Update to existing test to ignore earnings that are not active
AND @country = acccountrycode
ORDER BY 1,2

SET NOCOUNT OFF

PRINT ''

END

------------------------------------------------------------------------------------------------------------------------------------------
--KF 10/15/2020 New test PER Elliot Davenport

DECLARE @07_0026 CHAR(1)

select @07_0026 = 'Y'
from codes 
where codtable = 'ACCRUALCODE'
and CodCode not in (Select distinct ErnAccrualCode from EarnCode)

IF @07_0026 = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 07-0026 Accrual code exists, but they are not setup to reduce balances for the setup accrual plans'
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
select CodCode,CodDesc 
from codes 
where codtable = 'ACCRUALCODE'
and CodCode not in (Select distinct ErnAccrualCode from EarnCode)

SET NOCOUNT OFF
PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
--KF 10/15/2020 New test PER Homer Hernandez

DECLARE @07_0027 CHAR(1)

select @07_0027 = 'Y'
from pgernsch
where PgeEarnCode not in
(select ernearncode  from EarnCode)


IF @07_0027 = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 07-0027 Orphan earn code exists in the PgErnSch (payroll earning schedule) table, but not in the EarnCode table.'
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
select pgepaygroup, pgeearncode
from pgernsch
where PgeEarnCode not in
(select ernearncode  from EarnCode)

SET NOCOUNT OFF
PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------

/** Deductions **/

PRINT '____________________________________________________________________________________________________________________________________________________________'
PRINT ''
PRINT '8) Deductions'
PRINT '____________________________________________________________________________________________________________________________________________________________'
PRINT ''

------------------------------------------------------------------------------------------------------------------------------------------
-- MS 20181120 REPLACE
--Verify DedStartDate:

DECLARE @PRINT_DEDSTART CHAR(1)

SELECT @PRINT_DEDSTART = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM DedCode (NOLOCK)
WHERE DedDedEffStartDate <> '01/01/1950' AND DedDedCode NOT IN ('3PS', 'AZNC+', 'RVOD+', 'CVOD+')
  AND DEDCOUNTRYCODE = @country
  AND ISNULL(DedBenPlanProvider,'') <> 'API' --KF 09/08/2020 added logic to exclude API deductions (i.e. benefits prime or plansource).
  AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date

IF @PRINT_DEDSTART = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 08-0001 Start date is not equal to 1/1/1950 for the following deduction codes.'  
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT DEDCOUNTRYCODE, DedDedCode, DedStubDesc, CONVERT(VARCHAR,DedDedEffStartDate,101) DedDedEffStartDate
FROM DedCode (NOLOCK)
WHERE DedDedEffStartDate <> '01/01/1950' AND DedDedCode NOT IN ('3PS', 'AZNC+', 'RVOD+', 'CVOD+')
  AND DEDCOUNTRYCODE = @country
  AND ISNULL(DedBenPlanProvider,'') <> 'API' --KF 09/08/2020 added logic to exclude API deductions (i.e. benefits prime or plansource).
  AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date
ORDER BY DEDCOUNTRYCODE, DedDedCode
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- MS 20181120 REPLACE
--The following benefit/deduction plans are set up with a deduction rule of 'Flat amount':

DECLARE @PRINT_DEDFLAT CHAR(1)

SELECT @PRINT_DEDFLAT = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM DedCode (NOLOCK)
JOIN DedType (NOLOCK) ON DedDedType = CdtDedTypeCode
WHERE DedEECalcRule = '20' AND DedDedType IN ('ADD', 'DEN', 'LTD', 'MED', 'OPC', 'OPS', 'OPT', 'STD', 'VIS', 'GTL') 
  AND DEDCOUNTRYCODE = @country
  AND ISNULL(DedBenPlanProvider,'') <> 'API' --KF 09/08/2020 added logic to exclude API deductions (i.e. benefits prime or plansource).
  AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date

IF @ISOELE = 'Y' AND @PRINT_DEDFLAT = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 08-0002 The use of ''Flat Amount'' calculations with UltiPro OE LE is not recommended.'  
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
SELECT DedDedType, CdtDedTypeDesc, DedDedCode, DedStubDesc, DedEECalcRule
FROM DedCode (NOLOCK)
JOIN DedType ON DedDedType = CdtDedTypeCode
WHERE DedEECalcRule = '20' AND DedDedType IN ('ADD', 'DEN', 'LTD', 'MED', 'OPC', 'OPS', 'OPT', 'STD', 'VIS', 'GTL') 
  AND DEDCOUNTRYCODE = @country
  AND ISNULL(DedBenPlanProvider,'') <> 'API' --KF 09/08/2020 added logic to exclude API deductions (i.e. benefits prime or plansource).
  AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date
ORDER BY DEDCOUNTRYCODE, DedDedType, DedDedCode
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- MS 20181120 REPLACE
DECLARE @PRINT_DEDOPT CHAR(1)

SELECT @PRINT_DEDOPT = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM DedCode (NOLOCK)
WHERE DedEECalcRule = '21' AND NOT EXISTS(SELECT 1 FROM OptRate (NOLOCK) WHERE CorDedCode = DedDedCode)
  AND DEDCOUNTRYCODE = @country
  AND ISNULL(DedBenPlanProvider,'') <> 'API' --KF 09/08/2020 added logic to exclude API deductions (i.e. benefits prime or plansource).
  AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date

IF @PRINT_DEDOPT = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT '' 
PRINT '!!Error!! 08-0003 The following benefit option deduction plans do not have an option rate setup.'  
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT DEDCOUNTRYCODE, DedDedType, CdtDedTypeDesc, DedDedCode, DedStubDesc, DedEECalcRule
FROM DedCode (NOLOCK)
JOIN DedType (NOLOCK) ON DedDedType = CdtDedTypeCode
WHERE DedEECalcRule = '21' AND NOT EXISTS(SELECT 1 FROM OptRate (NOLOCK) WHERE CorDedCode = DedDedCode)
  AND DEDCOUNTRYCODE = @country
  AND ISNULL(DedBenPlanProvider,'') <> 'API' --KF 09/08/2020 added logic to exclude API deductions (i.e. benefits prime or plansource).
  AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date
ORDER BY DEDCOUNTRYCODE, DedDedType, DedDedCode
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- MS 20181120 REPLACE
--Check Age Graded Rates:

IF @ISOELE = 'Y'
BEGIN

DECLARE @PRINT_DEDAGE CHAR(1)

SELECT @PRINT_DEDAGE = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM DedCode (NOLOCK)
--WHERE DEDEECALCRULE = '31'
WHERE DEDEECALCRULE IN ('31','32') --KF 10/15/2020 ADDED LOGIC TO INCLUDE "Benefit Amount * Age Graded Rates" (32) PER Jamie Musgrove's request.
  AND DEDCOUNTRYCODE = @country
  AND ISNULL(DedBenPlanProvider,'') <> 'API' --KF 09/08/2020 added logic to exclude API deductions (i.e. benefits prime or plansource).
  AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date

IF @PRINT_DEDAGE = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 08-0004 Please verify the following plans with a calculation rule of Benefit Amount * Age Graded Rates to ensure that a Benefit Amount rule is established.'
PRINT '             Also verify there is a rate for every Age and Pay Frequency, and that the rate is per $1000 Per Pay Period.'
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
SELECT DEDCOUNTRYCODE, DedDedCode, DedStubDesc, DedEECalcRule
FROM DedCode (NOLOCK)
--WHERE DEDEECALCRULE = '31'
WHERE DEDEECALCRULE IN ('31','32') --KF 10/15/2020 ADDED LOGIC TO INCLUDE "Benefit Amount * Age Graded Rates" (32) PER Jamie Musgrove's request.
  AND DEDCOUNTRYCODE = @country
  AND ISNULL(DedBenPlanProvider,'') <> 'API' --KF 09/08/2020 added logic to exclude API deductions (i.e. benefits prime or plansource).
  AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date
ORDER BY DEDCOUNTRYCODE, DedDedCode
SET NOCOUNT OFF

PRINT ''
END
END

------------------------------------------------------------------------------------------------------------------------------------------
-- MS 20181120 new
--Please review age graded rates setup:

IF @ISOELE = 'Y'
BEGIN

DECLARE @PRINT_DEDAGERANGE CHAR(1)

SELECT @PRINT_DEDAGERANGE = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM insrate (NOLOCK)
JOIN DEDCODE ON DEDDEDCODE = RATDEDCODE
WHERE (ratmaxage - ratminage) < 5
  AND DEDCOUNTRYCODE = @country
  AND ISNULL(DedBenPlanProvider,'') <> 'API' --KF 09/08/2020 added logic to exclude API deductions (i.e. benefits prime or plansource).
  AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date

IF @PRINT_DEDAGERANGE = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 08-0005 Please verify the following plans with a calculation rule of Age Graded Rates to ensure that ages are correct.'
PRINT '             The seperation between the ages appears small.'
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
select DEDCOUNTRYCODE, ratdedcode, rateffdate,ratpayfreq, ratminage, ratmaxage
from insrate (NOLOCK)
JOIN DEDCODE ON DEDDEDCODE = RATDEDCODE
where (ratmaxage - ratminage) < 5
  AND DEDCOUNTRYCODE = @country
  AND ISNULL(DedBenPlanProvider,'') <> 'API' --KF 09/08/2020 added logic to exclude API deductions (i.e. benefits prime or plansource).
  AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date
order by DEDCOUNTRYCODE, 2,3 desc,4,5
SET NOCOUNT OFF

PRINT ''
END
END

------------------------------------------------------------------------------------------------------------------------------------------
-- MS 20181120 REPLACE
--HSA DED TYPE CHECK:

DECLARE @PRINT_DEDHSATYPE CHAR(1)

SELECT @PRINT_DEDHSATYPE = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM DedCode (NOLOCK) 
WHERE DedDedType = 'HSA' 
  AND DEDCOUNTRYCODE = @country
  AND ISNULL(DedBenPlanProvider,'') <> 'API' --KF 09/08/2020 added logic to exclude API deductions (i.e. benefits prime or plansource).
  AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date

IF @PRINT_DEDHSATYPE = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 08-0006 Please verify the following HSA deduction type plans to ensure that they have the correct tax categories.'  
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
SELECT DedDedCode, DedStubDesc, DedDedType, DedTaxCategory, DedERCalcRule
FROM DedCode (NOLOCK)
WHERE DedDedType = 'HSA' 
  AND DEDCOUNTRYCODE = @country
  AND ISNULL(DedBenPlanProvider,'') <> 'API' --KF 09/08/2020 added logic to exclude API deductions (i.e. benefits prime or plansource).
  AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date
ORDER BY DedDedCode 
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- MS 20181120 REPLACE
--Verify HSA ER:

DECLARE @PRINT_DEDHSAER CHAR(1)

SELECT @PRINT_DEDHSAER = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM DedCode (NOLOCK)
WHERE DedTaxCategory IN ('HSA', 'HSACU', 'HSAF', 'HSAFC', 'HSAI', 'HSAIC') AND DedERCalcRule NOT IN ('99')
  AND DEDCOUNTRYCODE = @country
  AND ISNULL(DedBenPlanProvider,'') <> 'API' --KF 09/08/2020 added logic to exclude API deductions (i.e. benefits prime or plansource).
  AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date

IF @PRINT_DEDHSAER = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 08-0007 The ER calculation rule is not set to ''None'' for the following HSA plans.'  
PRINT '!!Error!!  EMPLOYER HSA CONTRIBUTIONS MUST BE SET UP AS EARNINGS!'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT  DedDedCode, DedStubDesc, DedDedType, DedTaxCategory, DedERCalcRule
FROM DedCode (NOLOCK)
WHERE DedTaxCategory IN ('HSA', 'HSACU', 'HSAF', 'HSAFC', 'HSAI', 'HSAIC') AND DedERCalcRule NOT IN ('99')
  AND DEDCOUNTRYCODE = @country
  AND ISNULL(DedBenPlanProvider,'') <> 'API' --KF 09/08/2020 added logic to exclude API deductions (i.e. benefits prime or plansource).
  AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date
ORDER BY DedDedCode
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- MS 20181120 REPLACE
--Verify FSA:

DECLARE @PRINT_FSA CHAR(1)

SELECT @PRINT_FSA = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM DedCode (NOLOCK)
WHERE DedDedType = 'FSA'
  AND DEDCOUNTRYCODE = @country
  AND ISNULL(DedBenPlanProvider,'') <> 'API' --KF 09/08/2020 added logic to exclude API deductions (i.e. benefits prime or plansource).
  AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date

IF @PRINT_FSA = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 08-0008 Please verify the following plans with a deduction type of FSA have correct tax category (i.e. FSA Dependent Care plans should have tax category of D125).'
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
SELECT DedDedCode, DedStubDesc, DedDedType, DedTaxCategory, DedERCalcRule
FROM DedCode (NOLOCK)
WHERE DedDedType = 'FSA'
  AND DEDCOUNTRYCODE = @country
  AND ISNULL(DedBenPlanProvider,'') <> 'API' --KF 09/08/2020 added logic to exclude API deductions (i.e. benefits prime or plansource).
  AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date
ORDER BY DedDedCode
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
--- MS 20181120 REPLACE
--BEN AMT X RATE CHECK:

IF @ISOELE = 'Y'
BEGIN

DECLARE @PRINT_BENAMTRATE CHAR(1)

SELECT @PRINT_BENAMTRATE = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM DedCode (NOLOCK)
WHERE DedEECalcRule = '30'
  AND DEDCOUNTRYCODE = @country
  AND ISNULL(DedBenPlanProvider,'') <> 'API' --KF 09/08/2020 added logic to exclude API deductions (i.e. benefits prime or plansource).
  AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date

IF @PRINT_BENAMTRATE = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 08-0009 Please verify the following plans with a calculation rule of benefit amount * rate, to ensure that a benefit amount rule is established,' 
PRINT '             and the rate is per $1000, per period.'
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
SELECT DEDCOUNTRYCODE, DedDedCode, DedStubDesc, DedEECalcRule
FROM DedCode (NOLOCK)
WHERE DedEECalcRule = '30'
  AND DEDCOUNTRYCODE = @country
  AND ISNULL(DedBenPlanProvider,'') <> 'API' --KF 09/08/2020 added logic to exclude API deductions (i.e. benefits prime or plansource).
  AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date
ORDER BY DEDCOUNTRYCODE, DedDedCode
SET NOCOUNT OFF

PRINT ''
END
END

------------------------------------------------------------------------------------------------------------------------------------------
-- MS 20181120 REPLACE
--VERIFY WAGE ATTACHMENTS:

DECLARE @PRINT_DEDWAGE CHAR(1)

SELECT @PRINT_DEDWAGE = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM DedCode (NOLOCK)
WHERE DedInclWageAttachment = 'N' 
  AND @country = 'USA'
  AND DEDCOUNTRYCODE = @country
  AND (DedDedType = 'GAR' OR DedLongDesc LIKE '%Bankr%' OR DedLongDesc LIKE '%Student%' OR DedLongDesc LIKE '%Levy%')
  AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date

IF @PRINT_DEDWAGE = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 08-0010 Please review the following deduction codes.  Wage Attachments are not flagged to be included in Wage Attachment file.' 
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT DEDCOUNTRYCODE, DedDedCode, DedStubDesc, DedDedType 
FROM DedCode (NOLOCK)
WHERE DedInclWageAttachment = 'N'
  AND @country = 'USA'
  AND DEDCOUNTRYCODE = @country
  AND (DedDedType = 'GAR' OR DedLongDesc LIKE '%Bankr%' OR DedLongDesc LIKE '%Student%' OR DedLongDesc LIKE '%Levy%')
  AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date
ORDER BY DEDCOUNTRYCODE, DedDedCode
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- MS 20181120 REPLACE
--NON WAGE ATTACHMENTS:
--05/21/2019 VA: please update last part of condition (after country code): AND (dedtaxcategory not in('FAMSUP','VOL','GARNIS','GARNSH','STLOAN','STLONS','TXLEVY','CHILD','BANKRP','BNKRPS')
----or deddedtype not in('OTH','OT1','GAR'))
--KF 20190522 UPDATED CONDITION

DECLARE @PRINT_NONWAGE CHAR(1)

SELECT @PRINT_NONWAGE = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM DedCode (NOLOCK)
WHERE DedInclWageAttachment = 'Y' 
  AND @country = 'USA' 
  AND DEDCOUNTRYCODE = @country
  AND (dedtaxcategory not in('FAMSUP','VOL','GARNIS','GARNSH','STLOAN','STLONS','TXLEVY','CHILD','BANKRP','BNKRPS') or deddedtype not in ('OTH','OT1','GAR')) --KF 20190522 UPDATED CONDITION
  AND DedDedType <> 'GAR' AND DedLongDesc NOT LIKE '%Bankr%' AND DedLongDesc NOT LIKE '%Student%' AND DedLongDesc NOT LIKE '%Levy%'
  AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date

IF @PRINT_NONWAGE = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
--PRINT '!!Error!! 08-0011 Please review the following deduction codes.  Non-Garnishments are flagged to be included in Wage Attachment file.' 
PRINT '!!Error!! 08-0011 Invalid Tax Category/Deduction Type Setup for Wage Attachment' --KF NEW ERROR MESSAGE
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT DedCountryCode, DedDedCode, DedStubDesc, DedDedType 
FROM DedCode (NOLOCK)
WHERE DedInclWageAttachment = 'Y'
  AND @country = 'USA' 
  AND DEDCOUNTRYCODE = @country
  AND (dedtaxcategory not in('FAMSUP','VOL','GARNIS','GARNSH','STLOAN','STLONS','TXLEVY','CHILD','BANKRP','BNKRPS') or deddedtype not in ('OTH','OT1','GAR')) --KF 20190522 UPDATED CONDITION
  AND DedDedType <> 'GAR' AND DedLongDesc NOT LIKE '%Bankr%' AND DedLongDesc NOT LIKE '%Student%' AND DedLongDesc NOT LIKE '%Levy%'
  AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date
ORDER BY DedCountryCode,  DedDedCode
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- MS 20181120 REPLACE
--DED GOAL RULE REVIEW:

DECLARE @PRINT_DEDGOALRULE CHAR(1)

SELECT @PRINT_DEDGOALRULE = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM DedCode (NOLOCK)
WHERE (((DedDedType = 'FSA' OR DedDedType = 'DEF') AND DedEEGoalRule <> 'Y') OR
      ((DedDedType = 'GAR' OR DedLongDesc LIKE '%Bank%' OR DedLongDesc LIKE '%Student%') AND dedtaxcategory <> 'CHILD' AND (DedEEGoalRule <> 'C')) OR   (Deddedtype = 'LOAN' AND DedEEGoalRule <> 'C'))
  --AND @country = 'USA' 
  AND DEDCOUNTRYCODE = @country
  AND ISNULL(DedBenPlanProvider,'') <> 'API' --KF 09/08/2020 added logic to exclude API deductions (i.e. benefits prime or plansource).
  AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date

IF @PRINT_DEDGOALRULE = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 08-0012 Please review the following deduction plans to ensure that the correct goal rule is being used.'
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
SELECT DedCountryCode, DedDedCode, DedStubDesc, DedEEGoalRule
FROM DedCode (NOLOCK)
WHERE (((DedDedType = 'FSA' OR DedDedType = 'DEF') AND DedEEGoalRule <> 'Y') OR 
	  ((DedDedType = 'GAR' OR DedLongDesc LIKE '%Bank%' OR DedLongDesc LIKE '%Student%') AND dedtaxcategory <> 'CHILD' AND (DedEEGoalRule <> 'C')) OR (DedDedType = 'LOAN' AND DedEEGoalRule <> 'C'))
  --AND @country = 'USA' 
  AND DEDCOUNTRYCODE = @country
  AND ISNULL(DedBenPlanProvider,'') <> 'API' --KF 09/08/2020 added logic to exclude API deductions (i.e. benefits prime or plansource).
  AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date
ORDER BY DedCountryCode, DedDedCode
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- MS 20181120 REPLACE
--Checks for Deferred Comp employer match:

DECLARE @PRINT_DEDMATCH CHAR(1)
DECLARE @PRINT_DEDNOMATCH CHAR(1)

SELECT @PRINT_DEDMATCH = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM DedCode (NOLOCK)
JOIN Codes (NOLOCK) ON DedERPerCapCalcRule = CodCode AND CodTable = 'DEDERPERCAPCALCRULE'
WHERE DedDedType = 'DEF' AND DedERCalcRateOrPct > .00
  AND @country = 'USA' 
  AND DEDCOUNTRYCODE = @country
  AND ISNULL(DedBenPlanProvider,'') <> 'API' --KF 09/08/2020 added logic to exclude API deductions (i.e. benefits prime or plansource).
  AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date

SELECT @PRINT_DEDNOMATCH = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM DedCode (NOLOCK)
JOIN Codes (NOLOCK) ON DedERPerCapCalcRule = CodCode AND CodTable = 'DEDERPERCAPCALCRULE'
WHERE DedDedType = 'DEF' AND ISNULL(DedERCalcRateorPct,0) = 0 
  AND @country = 'USA' 
  AND DEDCOUNTRYCODE = @country
  AND ISNULL(DedBenPlanProvider,'') <> 'API' --KF 09/08/2020 added logic to exclude API deductions (i.e. benefits prime or plansource).
  AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date

IF @PRINT_DEDMATCH = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 08-0013 The following codes have an Employer Match.'
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
SELECT DedCountryCode, DedDedCode, DedERCalcRateOrPct * 100 DedERCalcRateorPct, DedERPerCapCalcRule, DedERPerCapPct
FROM DedCode (NOLOCK)
JOIN Codes (NOLOCK) ON DedERPerCapCalcRule = CodCode AND CodTable = 'DEDERPERCAPCALCRULE'
WHERE DedDedType = 'DEF' AND DedERCalcRateOrPct > .00
  AND @country = 'USA' 
  AND DEDCOUNTRYCODE = @country
  AND ISNULL(DedBenPlanProvider,'') <> 'API' --KF 09/08/2020 added logic to exclude API deductions (i.e. benefits prime or plansource).
  AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date
ORDER BY DedCountryCode, DedDedCode 
SET NOCOUNT OFF

PRINT ''
END

IF @PRINT_DEDNOMATCH = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 08-0014 The following codes do not have an employer match.'
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
SELECT DedCountryCode, DedDedCode,DedERCalcRateOrPct * 100 DedERCalcRateorPct, DedERPerCapCalcRule, DedERPerCapPct
FROM DedCode (NOLOCK)
JOIN Codes (NOLOCK) ON DedERPerCapCalcRule = CodCode AND CodTable = 'DEDERPERCAPCALCRULE'
WHERE DedDedType = 'DEF' AND ISNULL(DedERCalcRateorPct,0) = 0 
  AND @country = 'USA' 
  AND DEDCOUNTRYCODE = @country
  AND ISNULL(DedBenPlanProvider,'') <> 'API' --KF 09/08/2020 added logic to exclude API deductions (i.e. benefits prime or plansource).
  AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date
ORDER BY DedCountryCode, DedDedCode
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- MS 20181120 REPLACE
-- REMOVED @ISOELE = 'Y'
--Deduction is flagged as benefit AND coverage start date or coverage stop date or deduction start date equals 'Z' or (blank) or IS NULL:

DECLARE @PRINT_DATERULEMISSING CHAR(1)

SELECT @PRINT_DATERULEMISSING = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM DedCode
WHERE DedIsBenefit = 'Y' AND (DedPlanCovStartRule = '00' OR DedPlanCovStopRule = '00' OR DedDedStartRule = '00' )
  AND DEDCOUNTRYCODE = @country
  AND ISNULL(DedBenPlanProvider,'') <> 'API' --KF 09/08/2020 added logic to exclude API deductions (i.e. benefits prime or plansource).
  AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date

IF @PRINT_DATERULEMISSING = 'Y' and @ISOELE = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 08-0015 The following deductions are flagged as a benefit, but do not have date rules.  Please add date rules.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT DEDCOUNTRYCODE, DedDedType DedType, DedDedCode DedCode, DedStubDesc StubDesc, DedIsBenefit IsBenefit, 
	   DedPlanCovStartRule CovStartRule, DedPlanCovStopRule CovStopRule, DedDedStartRule DedStartRule, DedDedStopRule DedStopRule
FROM DedCode
WHERE DedIsBenefit = 'Y' AND (DedPlanCovStartRule = '00' OR DedPlanCovStopRule = '00' OR DedDedStartRule = '00')
  AND DEDCOUNTRYCODE = @country
  AND ISNULL(DedBenPlanProvider,'') <> 'API' --KF 09/08/2020 added logic to exclude API deductions (i.e. benefits prime or plansource).
  AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date
ORDER BY DEDCOUNTRYCODE, DedDedType, DedDedCode
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- MS 20181120 REPLACE
-- REMOVED @ISOELE = 'Y'
--Deduction is not flagged as benefit AND coverage start date or coverage stop date or deduction start date is not 'Z' and not (blank) and IS NOT NULL:

DECLARE @PRINT_NONBENDATERULE CHAR(1)

SELECT @PRINT_NONBENDATERULE = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM DedCode
WHERE DedIsBenefit = 'N' AND DedIsDedOffSet = 'N' AND (DedPlanCovStartRule <> '00' OR DedPlanCovStopRule <> '00')
  AND DEDCOUNTRYCODE = @country
  AND ISNULL(DedBenPlanProvider,'') <> 'API' --KF 09/08/2020 added logic to exclude API deductions (i.e. benefits prime or plansource).
  AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date

IF @PRINT_NONBENDATERULE = 'Y' and @ISOELE = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 08-0016 The following deductions are NOT flagged as a benefit, but do have date rules.  Please update deduction type if date rules are needed.'
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
SELECT DedDedType DedType, DedDedCode DedCode, DedStubDesc StubDesc, DedIsBenefit IsBenefit, 
	   DedPlanCovStartRule CovStartRule, DedPlanCovStopRule CovStopRule, DedDedStartRule DedStartRule, DedDedStopRule DedStopRule
FROM DedCode
WHERE DedIsBenefit = 'N' AND DedIsDedOffSet = 'N' AND (DedPlanCovStartRule <> '00' OR DedPlanCovStopRule <> '00')
  AND DEDCOUNTRYCODE = @country
  AND ISNULL(DedBenPlanProvider,'') <> 'API' --KF 09/08/2020 added logic to exclude API deductions (i.e. benefits prime or plansource).
  AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date
ORDER BY DedDedType, DedDedCode
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- MS 20181120 REPLACE
-- REMOVED @ISOELE = 'Y'
--Deduction type "Other" is flagged as benefit:

DECLARE @PRINT_DEDOTHISBEN CHAR(1)

SELECT @PRINT_DEDOTHISBEN = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END 
FROM DedType
WHERE CdtDedTypeCode = 'OTH' AND CdtIsBenefit = 'Y'


IF @PRINT_DEDOTHISBEN = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 08-0017 The deduction type "Other" should not be flagged as a benefit.  Please update the deduction type to either Miscellaneous or Additional.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT CdtDedTypeCode, CdtDedTypeDesc, CdtAllowMultiples, CdtIsBenefit
FROM DedType
WHERE CdtDedTypeCode = 'OTH' AND CdtIsBenefit = 'Y'
ORDER BY CdtDedTypeCode
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- m s 20181120 replace
--Goal on deduction is less than statutory goal at company level:
--KF 20190607 modified to show results for the go-live year and forward for max end date. This may give more results per deduction, but will allow SC to see the yearly limits to ignore any limits not in go-live year.

DECLARE @PRINT_DEDGOAL CHAR(1)

SELECT @PRINT_DEDGOAL = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END 
FROM ULTIPRO_SYSTEM.dbo.DTaxCat (NOLOCK)
JOIN dbo.DedCode (NOLOCK) ON DedTaxCategory = DtcCode
--JOIN (SELECT MAX(DtcEffectiveStopDate) MaxEffStop, DtcCode FROM ULTIPRO_SYSTEM.dbo.DTaxCat (NOLOCK) GROUP BY DtcCode) MaxEffStop 
JOIN (SELECT DtcEffectiveStopDate MaxEffStop, DtcCode FROM ULTIPRO_SYSTEM.dbo.DTaxCat (NOLOCK) 
		WHERE DATEPART(YEAR,@LIVEDATE) <= DATEPART(YEAR,DtcEffectiveStopDate)
		--WHERE DATEPART(YEAR,'2018') <= DATEPART(YEAR,DtcEffectiveStopDate)
		--GROUP BY DtcCode
		) MaxEffStop 
	ON MaxEffStop.MaxEffStop = DtcEffectiveStopDate AND MaxEffStop.DtcCode = ULTIPRO_SYSTEM.dbo.DTaxCat.DtcCode
WHERE DedDedType IN ('DEF', 'HSA', 'FSA') AND DedEEGoalRule = 'Y' 
AND DtcCountryCode = 'USA' 
AND DtcCountryCode = @Country 
AND DtcHasBeenReplaced = 'N' 
AND (DtcDedPlanType = '125' OR DtcIsDefComp = 'Y') AND DedEEGoalAmt < DtcElectiveDefCompLimit
AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date

IF @PRINT_DEDGOAL = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 08-0018 Goal amount in the deduction code is less than the max limit for the deduction code''s tax category.'
PRINT ''
SET @WARNINGCOUNT += 1


SET NOCOUNT ON
SELECT DedDedType, DedDedCode, DedTaxCategory, DedStubDesc, DedIsBenefit, DedEEGoalAmt, DtcElectiveDefCompLimit, DtcDescription
FROM ULTIPRO_SYSTEM.dbo.DTaxCat (NOLOCK)
JOIN dbo.DedCode (NOLOCK) ON DedTaxCategory = DtcCode
--JOIN (SELECT MAX(DtcEffectiveStopDate) MaxEffStop, DtcCode FROM ULTIPRO_SYSTEM.dbo.DTaxCat (NOLOCK) GROUP BY DtcCode) MaxEffStop 
JOIN (SELECT DtcEffectiveStopDate MaxEffStop, DtcCode FROM ULTIPRO_SYSTEM.dbo.DTaxCat (NOLOCK) 
		WHERE DATEPART(YEAR,@LIVEDATE) <= DATEPART(YEAR,DtcEffectiveStopDate)
		--WHERE DATEPART(YEAR,'2018') <= DATEPART(YEAR,DtcEffectiveStopDate)
		--GROUP BY DtcCode
		) MaxEffStop 
	ON MaxEffStop.MaxEffStop = DtcEffectiveStopDate AND MaxEffStop.DtcCode = ULTIPRO_SYSTEM.dbo.DTaxCat.DtcCode
WHERE DedDedType IN ('DEF', 'HSA', 'FSA') AND DedEEGoalRule = 'Y' 
AND DtcCountryCode = 'USA' 
--AND DtcCountryCode = @Country 
AND DtcHasBeenReplaced = 'N' 
AND (DtcDedPlanType = '125' OR DtcIsDefComp = 'Y') AND DedEEGoalAmt < DtcElectiveDefCompLimit
AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date
ORDER BY DedDedType, DedDedCode, DtcRecordType, DtcDedPlanType, ULTIPRO_SYSTEM.dbo.DTaxCat.DtcCode, DtcCatGroup, DtcDescription
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- ms 20181020 replace
-- removed @ISOELE = 'Y' 
--Deduction type = MED, DEN, VIS, OPS, OPC:

DECLARE @PRINT_DEDDEPENROLL CHAR(1)

SELECT @PRINT_DEDDEPENROLL = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END 
FROM DedType (NOLOCK)
WHERE CdtUseDependent = 'Y'

IF @PRINT_DEDDEPENROLL = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 08-0019 The following deduction types are setup to allow dependent enrollment.'
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
SELECT CdtDedTypeCode, CdtDedTypeDesc, CdtIsBenefit, CdtUseDependent
FROM DedType (NOLOCK)
WHERE CdtUseDependent = 'Y'
ORDER BY CdtDedTypeCode
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------

--Benefit option code contains one or more numbers:
--05/21/2019 VA: This test should be USA only
--KF 20190522 UPDATED TO BE USA CHECK ONLY

DECLARE @PRINT_INVALIDBENOPT CHAR(1)

IF @Country = 'USA' --KF 20190522 UPDATED
BEGIN
	SELECT @PRINT_INVALIDBENOPT = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END 
	FROM OptRate (NOLOCK)
	WHERE CorBenOption LIKE '%[0-9]%'
	AND NOT EXISTS (SELECT 1 FROM DEDCODE WHERE DEDDEDCODE = CorDedCode 
		AND ISNULL(DedBenPlanProvider,'') <> 'API' --KF 09/08/2020 added logic to exclude API deductions (i.e. benefits prime or plansource).
		AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date
		)

	IF @ISMIDMARKET = 'Y' AND @PRINT_INVALIDBENOPT = 'Y'
	BEGIN
	PRINT '*************************************************************************************************************************************************'
	PRINT ''
	PRINT '!!Warning!! 08-0020 The following deduction codes have "invalid" benefit options (containing one or more numbers).'
	PRINT ''
	SET @WARNINGCOUNT += 1

	SET NOCOUNT ON
	SELECT CorDedCode, CorBenOption, CorPayFreq, CorEERate, CorERRate, CorEffDate
	FROM OptRate (NOLOCK)
	WHERE CorBenOption LIKE '%[0-9]%'
	AND NOT EXISTS (SELECT 1 FROM DEDCODE WHERE DEDDEDCODE = CorDedCode 
		AND ISNULL(DedBenPlanProvider,'') <> 'API' --KF 09/08/2020 added logic to exclude API deductions (i.e. benefits prime or plansource).
		AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date
		)
	ORDER BY CorDedCode, CorBenOption
	SET NOCOUNT OFF

	PRINT ''
	END
END

------------------------------------------------------------------------------------------------------------------------------------------
-- ms 20181120 replace
--Show rates where there is not a pay frequency for the pay groups setup in the company (i.e. Biweekly pay groups, but semi-monthly rates):

DECLARE @PRINT_RATESNOFREQ CHAR(1)

SELECT @PRINT_RATESNOFREQ = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END 
FROM OptRate (NOLOCK)
join dedcode on deddedcode = cordedcode
WHERE CorPayFreq NOT IN (SELECT DISTINCT PgrPayFrequency FROM PayGroup)
  and dedcountrycode = @country
  AND ISNULL(DedBenPlanProvider,'') <> 'API' --KF 09/08/2020 added logic to exclude API deductions (i.e. benefits prime or plansource).
  AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date

IF @PRINT_RATESNOFREQ = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 08-0021 The following benefit options have rates for a pay frequency that is not a pay group pay frequency.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT dedcountrycode, CorDedCode, CorBenOption, CorPayFreq, CorEERate, CorERRate, CorEffDate
FROM OptRate (NOLOCK)
join dedcode on deddedcode = cordedcode
WHERE CorPayFreq NOT IN (SELECT DISTINCT PgrPayFrequency FROM PayGroup)
  and dedcountrycode = @country
  AND ISNULL(DedBenPlanProvider,'') <> 'API' --KF 09/08/2020 added logic to exclude API deductions (i.e. benefits prime or plansource).
  AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date
order by dedcountrycode, CorDedCode
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- ms 20181120 replace
--When a plan has EE calculation rule of "option rate table", "benefit amt * rate", "benefit amt * age graded rate" and "benefit amt * dependent age grade rate", 
--then the flag for "Use rule at ee level" or "use rate at ee level" should NOT be checked:
--05/21/2019 VA: update condition to add calc rule 90 and 93 i.e. DedEECalcRule IN ('21', '30', '31', '32','90',93')
--KF 20190522 UPDATED CONDITION

DECLARE @PRINT_CALCRULEEEFLAG CHAR(1)

SELECT @PRINT_CALCRULEEEFLAG = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM DedCode (NOLOCK)
WHERE DedEECalcRule IN ('21', '30', '31', '32', '90', '93') AND (DedEEUseEERate = 'Y' OR DedEEUseEERule = 'Y') --KF 20190522 UPDATED CONDITION
  and dedcountrycode = @country 
  AND ISNULL(DedBenPlanProvider,'') <> 'API' --KF 09/08/2020 added logic to exclude API deductions (i.e. benefits prime or plansource).
  AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date

IF @PRINT_CALCRULEEEFLAG = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 08-0022 Please remove flag for "Use rule at EE level" or "Use rate at EE level".'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT dedcountrycode, DedDedCode, DedStubDesc, DedDedType,  DedEECalcRule, DedEEUseEERate, DedEEUseEERule 
FROM DedCode (NOLOCK)
WHERE DedEECalcRule IN ('21', '30', '31', '32', '90', '93') AND (DedEEUseEERate = 'Y' OR DedEEUseEERule = 'Y') --KF 20190522 UPDATED CONDITION
  and dedcountrycode = @country
  AND ISNULL(DedBenPlanProvider,'') <> 'API' --KF 09/08/2020 added logic to exclude API deductions (i.e. benefits prime or plansource).
  AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date
ORDER BY dedcountrycode, DedDedCode
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- ms 20181120 replace
--When a plan has ER calculation rule of "option rate table", "benefit amt * rate", "benefit amt * age graded rate" and "benefit amt * dependent age grade rate", 
--then the flag for "Use rule at ER level" or "use rate at ER level" should NOT be checked:
--05/21/2019 VA: update condition to add calc rule 90 and 93 i.e. DedERCalcRule IN ('21', '30', '31', '32','90',93')
--KF 20190522 UPDATED CONDITION

DECLARE @PRINT_CALCRULEERFLAG CHAR(1)

SELECT @PRINT_CALCRULEERFLAG = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM DedCode (NOLOCK)
WHERE DedERCalcRule IN ('21', '30', '31', '32', '90', '93') AND (DedERUseEERate = 'Y' OR DedERUseEERule = 'Y') --KF 20190522 UPDATED CONDITION
  and dedcountrycode = @country
  AND ISNULL(DedBenPlanProvider,'') <> 'API' --KF 09/08/2020 added logic to exclude API deductions (i.e. benefits prime or plansource).
  AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date

IF @PRINT_CALCRULEERFLAG = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 08-0023 Please remove flag for "Use rule at ER level" or "Use rate at ER level".'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT dedcountrycode, DedDedCode, DedStubDesc, DedDedType,  DedERCalcRule, DedERUseEERate, DedERUseEERule 
FROM DedCode (NOLOCK)
WHERE DedERCalcRule IN ('21', '30', '31', '32', '90', '93') AND (DedERUseEERate = 'Y' OR DedERUseEERule = 'Y') --KF 20190522 UPDATED CONDITION
  and dedcountrycode = @country
  AND ISNULL(DedBenPlanProvider,'') <> 'API' --KF 09/08/2020 added logic to exclude API deductions (i.e. benefits prime or plansource).
  AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date
ORDER BY dedcountrycode, DedDedCode
SET NOCOUNT OFF

PRINT ''
END

--------------------------------------------------------------------------------------------------------------------------------------------------------
-- TL 20181120 replace
--Check for deduction codes that have no calculation rule:

DECLARE @PRINT_DEDCALCB_WARNING CHAR(1)

SELECT @PRINT_DEDCALCB_WARNING = 'Y' 
from DedCode (NOLOCK)
where DedEECalcRule = '99' 
and DedERCalcRule = '99'
and DedEEUseEERate = 'N'
and DedEEUseEERule = 'N'
and DedERUseEERate = 'N'
and DedERUseEERule = 'N'
and DedDedEffStopDate is NULL 
and DedTaxCategory <> 'TXLEVY'
and @country= dedcountrycode
AND ISNULL(DedBenPlanProvider,'') <> 'API' --KF 09/08/2020 added logic to exclude API deductions (i.e. benefits prime or plansource).
AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date

IF @PRINT_DEDCALCB_WARNING = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 08-0024 Deduction codes should not be setup with NONE as the calc rule without having the USE flags activated.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
Select dedcountrycode,DedDedType, DedDedCode,DedLongDesc, DedEECalcRule, DedERCalcRule,DedEEUseEERate, DedEEUseEERule,DedERUseEERate,DedERUseEERule
from DedCode (NOLOCK)
where DedEECalcRule = '99' 
and DedERCalcRule = '99'
and DedEEUseEERate = 'N'
and DedEEUseEERule = 'N'
and DedERUseEERate = 'N'
and DedERUseEERule = 'N'
and DedDedEffStopDate is NULL 
and DedTaxCategory <> 'TXLEVY' --KF ADDED 20190604
and @country= dedcountrycode
AND ISNULL(DedBenPlanProvider,'') <> 'API' --KF 09/08/2020 added logic to exclude API deductions (i.e. benefits prime or plansource).
AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date
order by 1,3

SET NOCOUNT OFF

PRINT ''
END


------------------------------------------------------------------------------------------------------------------------------------------
-- 20181120 replace 
--Deductions code <> time clock code (common mistake when cloning code in BO):

DECLARE @PRINT_TIMECLOCKMISMATCH CHAR(1)

SELECT @PRINT_TIMECLOCKMISMATCH = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM DedCode (NOLOCK)
WHERE DedDedCode <> DedTimeclockCode AND DedIsDedOffSet = 'N'
and @country= dedcountrycode
AND ISNULL(DedBenPlanProvider,'') <> 'API' --KF 09/08/2020 added logic to exclude API deductions (i.e. benefits prime or plansource).
AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date

IF @PRINT_TIMECLOCKMISMATCH = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 08-0025 Deductions time clock code does not match deduction code.  Please verify.' 
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
SELECT dedcountrycode, DedDedCode, DedTimeclockCode, DedStubDesc 
FROM DedCode (NOLOCK)
WHERE DedDedCode <> DedTimeclockCode AND DedIsDedOffSet = 'N'
and @country= dedcountrycode
AND ISNULL(DedBenPlanProvider,'') <> 'API' --KF 09/08/2020 added logic to exclude API deductions (i.e. benefits prime or plansource).
AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date
order by dedcountrycode, deddedcode
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- ms 20181120 replace
--Employer Option Rate Amounts:
--05/21/2019 VA: This test is USA only
--KF 20190522 UPDATED TO BE USA ONLY

DECLARE @PRINT_EROPTIONRATE CHAR(1)

IF @Country = 'USA' --KF 20190522 UPDATED TO BE USA ONLY
BEGIN
	SELECT @PRINT_EROPTIONRATE = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
	FROM DedCode (NOLOCK)
	JOIN OptRate (NOLOCK) ON CorDedCode = DedDedCode
	WHERE DedDedType IN ('MED', 'DEN', 'VIS') AND CorERRate = 0 AND CorBenOption <> 'Z'
	and dedcountrycode =  @country
	AND ISNULL(DedBenPlanProvider,'') <> 'API' --KF 09/08/2020 added logic to exclude API deductions (i.e. benefits prime or plansource).
	AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date

	IF @PRINT_EROPTIONRATE = 'Y'
	BEGIN
	PRINT '*************************************************************************************************************************************************'
	PRINT ''
	PRINT '!!Warning!! 08-0026 The following Benefit Options with a deduction type of MED, DEN, or VIS do not have Employer Amounts.' 
	PRINT ''
	SET @WARNINGCOUNT += 1

	SET NOCOUNT ON
	SELECT dedcountrycode, DedDedCode, DedStubDesc, CorBenOption, CorERRate
	FROM DedCode (NOLOCK)
	JOIN OptRate (NOLOCK) ON CorDedCode = DedDedCode
	WHERE DedCode.DedDedType IN ('MED', 'DEN', 'VIS') AND OptRate.CorERRate = 0 AND CorBenOption <> 'Z'
	and dedcountrycode =  @country
	AND ISNULL(DedBenPlanProvider,'') <> 'API' --KF 09/08/2020 added logic to exclude API deductions (i.e. benefits prime or plansource).
	AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date
	ORDER BY dedcountrycode,  DedDedCode, CorBenOption
	SET NOCOUNT OFF
	
	PRINT ''
	END
END

------------------------------------------------------------------------------------------------------------------------------------------
-- ms 20181120 rpelace
--Deduction code not in deduction group:
--KF 20190607 EXCLUDING DED CODE 'CVOD+'

DECLARE @PRINT_DEDGRP CHAR(1)

SELECT @PRINT_DEDGRP = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM DedCode (NOLOCK)
WHERE DedIsDedOffSet = 'N' AND NOT EXISTS(SELECT 1 FROM BenProg (NOLOCK) WHERE CbpDedCode = DedDedCode)
  and dedcountrycode =  @country
  AND DedDedCode <> 'CVOD+'
  AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date

IF @PRINT_DEDGRP = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 08-0027 The following deduction codes are not in any Deduction Group:'
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
SELECT dedcountrycode,DedDedCode, DedLongDesc
FROM DedCode (NOLOCK)
WHERE DedIsDedOffSet = 'N' AND NOT EXISTS(SELECT 1 FROM BenProg (NOLOCK) WHERE CbpDedCode = DedDedCode)
  and dedcountrycode =  @country
  AND DedDedCode <> 'CVOD+'
  AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date
ORDER BY dedcountrycode, DedDedCode
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- ms 20181120 replace
--Deductions flagged for arrears should not be flagged to be included in manual checks:

DECLARE @PRINT_ARREARSMANUALINCL CHAR(1)

SELECT @PRINT_ARREARSMANUALINCL = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM DedCode (NOLOCK)
WHERE DedUncollected2Arrears = 'Y' AND DedInclInManlChk = 'Y'
  and dedcountrycode =  @country
  AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date

IF @PRINT_ARREARSMANUALINCL = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 08-0028 Deductions flagged for arrears should not be flagged to be included in instant checks/cheques.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT dedcountrycode, DedDedType, DedDedCode, DedLongDesc, DedUncollected2Arrears, DedInclInManlChk 
FROM DedCode (NOLOCK)
WHERE DedUncollected2Arrears = 'Y' AND DedInclInManlChk = 'Y'
  and dedcountrycode =  @country
  AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date
ORDER BY dedcountrycode, DedDedType, DedDedCode
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- ms 20181120 replace
--Deduction codes should not have flag "This plan is available to employees who are eligible for health care under PPACA" as that will prevent EEs from making elections in OE:

DECLARE @PRINT_DEDISHCE CHAR(1)

SELECT @PRINT_DEDISHCE = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM DedCodeFull (NOLOCK)
WHERE DedIsHCE = '1'
  and dedcountrycode =  @country
  and @country =  'USA'
  AND ISNULL(DedBenPlanProvider,'') <> 'API' --KF 09/08/2020 added logic to exclude API deductions (i.e. benefits prime or plansource).
  AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date

IF @ISOELE = 'Y' AND @PRINT_DEDISHCE = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 08-0029 Deductions should not have flag "This plan is available to employees who are eligible for health care under PPACA", as this will impact OE.'
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
SELECT dedcountrycode, DedTVStartDate, DedDedType, DedDedcode ,DedLongDesc, DedIsHCE
FROM DedCodeFull (NOLOCK)
WHERE DedIsHCE = '1'
  and dedcountrycode =  @country
  and @country =  'USA'
  AND ISNULL(DedBenPlanProvider,'') <> 'API' --KF 09/08/2020 added logic to exclude API deductions (i.e. benefits prime or plansource).
  AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date
ORDER BY dedcountrycode, DedTVStartDate, DedDedType
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- ms 20181120 replace
--Box 12 check:

DECLARE @PRINT_MED_W2 CHAR(1)

SELECT @PRINT_MED_W2 = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM DedCode (NOLOCK)
WHERE DedDedType = 'MED' AND DedW2HealthcareReporting = 'N'
  and dedcountrycode =  @country
  and @country =  'USA'
  AND ISNULL(DedBenPlanProvider,'') <> 'API' --KF 09/08/2020 added logic to exclude API deductions (i.e. benefits prime or plansource).
  AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date

IF @PRINT_MED_W2 = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 08-0030 Deduction under ded type MED is NOT setup for W2 Healthcare reporting (W2 - Box 12 DD).'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT DedDedType, DedDedCode, DedLongDesc, DedW2HealthcareReporting
FROM DedCode (NOLOCK)
WHERE DedDedType = 'MED' AND DedW2HealthcareReporting = 'N'
  and dedcountrycode =  @country
  and @country =  'USA'
  AND ISNULL(DedBenPlanProvider,'') <> 'API' --KF 09/08/2020 added logic to exclude API deductions (i.e. benefits prime or plansource).
  AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- KF NEW 20190604

DECLARE @EE_DED_VIEW CHAR(1)

SELECT @EE_DED_VIEW = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
-- SELECT deddedcode,dedlongdesc,dedeeviewplandesc 
FROM dedcode
WHERE dedeeviewplandesc IS NULL
and DedCountryCode = @Country 
AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date
AND ISNULL(DedIsDedOffSet,'N') <> 'Y' --KF 10/15/2020 Aviva Murphy requested that deduction offsets be excluded from this validation.

IF @EE_DED_VIEW = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 08-0031 Please add EE view description.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT deddedcode,dedlongdesc,dedeeviewplandesc 
FROM dedcode
WHERE dedeeviewplandesc IS NULL
and DedCountryCode = @Country 
AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date
AND ISNULL(DedIsDedOffSet,'N') <> 'Y' --KF 10/15/2020 Aviva Murphy requested that deduction offsets be excluded from this validation.
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- KF NEW 20190604

DECLARE @EE_DED_VIEW_DESC CHAR(1)

SELECT @EE_DED_VIEW_DESC = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
-- SELECT deddedcode,dedlongdesc,dedeeviewplandesc 
FROM dedcode
WHERE (ISNULL(dedeeviewplandesc,'X') <> ISNULL(dedlongdesc,'X'))
and DedCountryCode = @Country
AND ISNULL(DedBenPlanProvider,'') <> 'API' --KF 09/08/2020 added logic to exclude API deductions (i.e. benefits prime or plansource).
AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date
AND ISNULL(DedIsDedOffSet,'N') <> 'Y' --KF 10/15/2020 Aviva Murphy requested that deduction offsets be excluded from this validation.

IF @EE_DED_VIEW_DESC = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 08-0032 Please review EE view description that are not equal to deduction long description.'
PRINT ''
SET @WARNINGCOUNT += 1


SET NOCOUNT ON
SELECT deddedcode,dedlongdesc,dedeeviewplandesc 
FROM dedcode
WHERE (ISNULL(dedeeviewplandesc,'X') <> ISNULL(dedlongdesc,'X'))
and DedCountryCode = @Country
AND ISNULL(DedBenPlanProvider,'') <> 'API' --KF 09/08/2020 added logic to exclude API deductions (i.e. benefits prime or plansource).
AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date
AND ISNULL(DedIsDedOffSet,'N') <> 'Y' --KF 10/15/2020 Aviva Murphy requested that deduction offsets be excluded from this validation.
SET NOCOUNT OFF

PRINT ''
END



------------------------------------------------------------------------------------------------------------------------------------------
-- KF NEW 20190604

DECLARE @DED_0033 CHAR(1)

SELECT @DED_0033 = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
--SELECT deddedcode,dedlongdesc,dedeecalcrule,dedeecalcexprkey,dedercalcrule,dedercalcexprkey
FROM dedcode
WHERE ((dedeecalcrule in ('90','93') AND (dedeecalcexprkey IS NULL OR dedeecalcexprkey = ''))
OR (dedercalcrule in ('90','93') AND (dedercalcexprkey IS NULL OR dedercalcexprkey = '')))
AND ISNULL(DedBenPlanProvider,'') <> 'API' --KF 09/08/2020 added logic to exclude API deductions (i.e. benefits prime or plansource).
AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date


IF @DED_0033 = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 08-0033 Please update deduction code setup to add missing expression or change calc rule.'
PRINT ''
SET @ERRORCOUNT += 1


SET NOCOUNT ON
SELECT deddedcode,dedlongdesc,dedeecalcrule,dedeecalcexprkey,dedercalcrule,dedercalcexprkey
FROM dedcode
WHERE ((dedeecalcrule in ('90','93') AND (dedeecalcexprkey IS NULL OR dedeecalcexprkey = ''))
OR (dedercalcrule in ('90','93') AND (dedercalcexprkey IS NULL OR dedercalcexprkey = '')))
AND ISNULL(DedBenPlanProvider,'') <> 'API' --KF 09/08/2020 added logic to exclude API deductions (i.e. benefits prime or plansource).
AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- KF NEW 20190604

DECLARE @DED_0034 CHAR(1)

SELECT @DED_0034 = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
--SELECT DedDedCode, DedStubDesc, DedTaxCategory,DedEEGoalRule
FROM DedCode (NOLOCK)
WHERE dedtaxcategory in ('3RDPTY','GARNIS','REQPAY')
AND DedEEGoalRule <> 'C'
AND dedcountrycode = @Country AND @Country = 'CAN'
AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date


IF @DED_0034 = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 08-0034 Please review garnishment code setup to include EE goal rule..'
PRINT ''
SET @ERRORCOUNT += 1


SET NOCOUNT ON
SELECT DedDedCode, DedStubDesc, DedTaxCategory,DedEEGoalRule
FROM DedCode (NOLOCK)
WHERE dedtaxcategory in ('3RDPTY','GARNIS','REQPAY')
AND DedEEGoalRule <> 'C'
AND dedcountrycode = @Country AND @Country = 'CAN'
AND ((deddedeffstopdate is NULL) OR (deddedeffstopdate >= @LIVEDATE)) --KF 09/08/2020 Update to existing test to ignore deductions with stop dates prior to the go live date
ORDER BY DedDedCode
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------

/** Other Business Rules **/

PRINT '____________________________________________________________________________________________________________________________________________________________'
PRINT ''
PRINT '9) Other Business Rules'
PRINT '____________________________________________________________________________________________________________________________________________________________'
PRINT ''

------------------------------------------------------------------------------------------------------------------------------------------
-- ms 20181120 replace
--CHECK FOR INVALID JOB CODE SETUP:

DECLARE @PRINT_JOBDUPLICATE CHAR(1)
DECLARE @PRINT_JOBWC CHAR(1)
DECLARE @PRINT_JOBEEO CHAR(1)
DECLARE @PRINT_JOBFLSA CHAR(1)
DECLARE @PRINT_JOBYESNO CHAR(1)
DECLARE @PRINT_JOBSALGRADE CHAR(1)
DECLARE @PRINT_JOBTIP CHAR(1)
DECLARE @PRINT_JOBSALHR CHAR(1)

SELECT @PRINT_JOBDUPLICATE = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END 
FROM JobCode (NOLOCK)
where JbcCountryCode = @Country
GROUP BY JbcJobCode
HAVING COUNT(*) > 1

SELECT @PRINT_JOBWC = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END 
FROM JobCode (NOLOCK)
WHERE NOT EXISTS(SELECT 1 FROM Codes WHERE CodTable = 'WCCODES' AND CodCode = JbcWCCode)
  and JbcCountryCode = @Country

SELECT @PRINT_JOBEEO = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END 
FROM JobCode (NOLOCK)
WHERE NOT EXISTS(SELECT 1 FROM Codes WHERE CodTable = 'EEOCATEGORY' AND CodCode = JbcEEOCategory)
  and @Country = 'USA'
  and JbcCountryCode = @Country

SELECT @PRINT_JOBFLSA = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END 
FROM JobCode (NOLOCK)
WHERE NOT EXISTS(SELECT 1 FROM Codes WHERE CodTable = 'FLSATYPE' AND CodCode = JbcFLSAType)
  and @Country = 'USA'
  and JbcCountryCode = @Country

SELECT @PRINT_JOBYESNO = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END 
FROM JobCode (NOLOCK)
WHERE (JbcIsPiecework NOT IN ('Y', 'N') OR JbcIsStaff NOT IN ('Y', 'N') OR JbcIsSupervisor NOT IN ('Y', 'N')
OR JbcJobPremiumIsPct NOT IN ('Y', 'N') OR JbcTopPromotable NOT IN ('Y', 'N') OR JbcUsePayScales NOT IN ('Y', 'N'))
and JbcCountryCode = @Country

SELECT @PRINT_JOBSALGRADE = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END 
FROM JobCode (NOLOCK)
WHERE JbcSalaryGrade IS NOT NULL AND NOT EXISTS (SELECT 1 FROM SalGrade WHERE SlgSalgrade = JbcSalaryGrade) AND JbcSalaryGrade IS NOT NULL
  and JbcCountryCode = @Country

SELECT @PRINT_JOBTIP = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END 
FROM JobCode (NOLOCK)
WHERE NOT EXISTS (SELECT 1 FROM Codes WHERE CodTable = 'TIPTYPE' AND CodCode = JbcTipType)
  and @Country = 'USA'
  and JbcCountryCode = @Country

SELECT @PRINT_JOBSALHR = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END 
FROM JobCode (NOLOCK)
WHERE JbcSalaryOrHourly NOT IN ('S', 'H')
  and JbcCountryCode = @Country

IF @PRINT_JOBDUPLICATE = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 09-0001 Duplicate Job Codes in the JobCode table.'  
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT DISTINCT JbcJobCode 
FROM JobCode (NOLOCK)
where JbcCountryCode = @Country
GROUP BY JbcJobCode
HAVING COUNT(*) > 1
SET NOCOUNT OFF

PRINT ''
END

----

IF @PRINT_JOBWC = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 09-0002 Invalid WC Code in the JobCode Table.'  
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT JbcJobCode, JbcWcCode 
FROM JobCode (NOLOCK)
WHERE NOT EXISTS (SELECT 1 FROM Codes WHERE CodTable = 'WCCODES' AND CodCode = JbcWCCode)
  and JbcCountryCode = @Country
SET NOCOUNT OFF

PRINT ''
END

----

IF @PRINT_JOBEEO = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 09-0003 Invalid EEO Code in the JobCode Table.'  
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT DISTINCT JbcJobCode, JbcEEOCategory 
FROM JobCode (NOLOCK)
WHERE NOT EXISTS (SELECT 1 FROM Codes WHERE CodTable = 'EEOCATEGORY' AND CodCode = JbcEEOCategory)
  and JbcCountryCode = @Country
SET NOCOUNT OFF

PRINT ''
END

----

IF @PRINT_JOBFLSA = 'Y' 
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 09-0004 Invalid FLSA Type Code in the JobCode table.'  
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT DISTINCT JbcJobCode, JbcFLSAType 
FROM JobCode (NOLOCK)
WHERE NOT EXISTS (SELECT 1 FROM Codes WHERE CodTable = 'FLSATYPE' AND CodCode = JbcFLSAType)
  and JbcCountryCode = @Country
SET NOCOUNT OFF

PRINT ''
END

----

IF @PRINT_JOBYESNO = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 09-0005 Invalid Yes/No Indicators in the JobCode Table.'  
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT DISTINCT JbcJobCode, JbcIsPieceWork, JbcIsStaff, JbcIsSupervisor, JbcJobPremiumIsPct, JbcTopPromotable, JbcUsePayScales 
FROM JobCode (NOLOCK)
WHERE (JbcIsPiecework NOT IN ('Y', 'N') OR JbcIsStaff NOT IN ('Y', 'N') OR JbcIsSupervisor NOT IN ('Y', 'N')
OR JbcJobPremiumIsPct NOT IN ('Y', 'N') OR JbcTopPromotable NOT IN ('Y', 'N') OR JbcUsePayScales NOT IN ('Y', 'N'))
  and JbcCountryCode = @Country
SET NOCOUNT OFF

PRINT ''
END

----

IF @PRINT_JOBSALGRADE = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 09-0006 Invalid Salary Grade Code in the JobCode Table.'  
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT DISTINCT JbcJobCode, JbcSalaryGrade 
FROM JobCode (NOLOCK)
WHERE JbcSalaryGrade IS NOT NULL AND NOT EXISTS (SELECT 1 FROM SalGrade WHERE SlgSalgrade = JbcSalaryGrade) AND JbcSalaryGrade IS NOT NULL
  and JbcCountryCode = @Country
SET NOCOUNT OFF

PRINT ''
END

----

IF @PRINT_JOBTIP = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 09-0007 Invalid TipType Code in the JobCode Table.'  
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT DISTINCT JbcJobCode, JbcTipType 
FROM JobCode (NOLOCK)
WHERE NOT EXISTS (SELECT 1 FROM Codes WHERE CodTable = 'TIPTYPE' AND CodCode = JbcTipType)
  and JbcCountryCode = @Country
SET NOCOUNT OFF

PRINT ''
END

----

IF @PRINT_JOBSALHR = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 09-0008 Invalid Salary/Hourly Code in the JobCode Table.'  
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT DISTINCT JbcJobCode, JbcSalaryorHourly 
FROM JobCode (NOLOCK)
WHERE JbcSalaryOrHourly NOT IN ('S', 'H')
  and JbcCountryCode = @Country
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- ms 20181120 replace
--Job Code Spaces:

DECLARE @JOBSPACE CHAR(1)

SELECT @JOBSPACE = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM JobCode (NOLOCK)
WHERE CHARINDEX(' ',RTRIM(JbcJobCode),0) <> 0
and jbccountrycode = @Country

IF @JOBSPACE = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 09-0009 The jobcode should not contain spaces.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON	
SELECT JbcJobCode, JbcDesc
FROM JobCode (NOLOCK)
WHERE CHARINDEX(' ',RTRIM(JbcJobCode),0) <> 0
and jbccountrycode = @Country
ORDER BY JbcJobCode
SET NOCOUNT OFF
	
PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- ms 20181120 replace
--Checks Worker's Comp ER Rates:

DECLARE @PRINT_WCRATES CHAR(1)

SELECT @PRINT_WCRATES = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM WCRisk (NOLOCK)
join company on cmpcoid = WcrCoID
WHERE WcrHasBeenReplaced = 'N' AND (WcrERRiskRate > 0.2 OR WcrERRiskRate < .002)
  and cmpcountrycode = @Country
 
IF @PRINT_WCRATES = 'Y'
BEGIN 
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 09-0010 Verify Employer WC Rates that are > 0.2 or < .002.'
PRINT '             NOTE: If Customer is using WC, please remember to verify which earnings should be included/excluded from the WC Calculations.'
PRINT ''
SET @WARNINGCOUNT += 1
-- select * from WCRisk
SET NOCOUNT ON
SELECT DISTINCT cmpcountrycode, WcrWcCode, WcrState, WcrERRiskRate, WcrHasBeenReplaced
FROM WCRisk (NOLOCK)
join company on cmpcoid = WcrCoID
WHERE WcrHasBeenReplaced = 'N' AND (WcrERRiskRate > 0.2 OR WcrERRiskRate < .002)
  and cmpcountrycode = @Country
ORDER BY cmpcountrycode, WcrWcCode, WcrState, WcrERRiskRate
SET NOCOUNT OFF 

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- ms 20181120 replace
--Identical jobs in the same job group:

DECLARE @PRINT_DUPLICATEJOBSSAMEGRP CHAR(1)

SELECT @PRINT_DUPLICATEJOBSSAMEGRP = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM JobProg (NOLOCK)
join jobcode (NOLOCK) on jbcjobcode = CjpJobCode
WHERE JobProg.AuditKey IN (SELECT MIN(AuditKey) 
				   FROM JobProg (NOLOCK)
				   GROUP BY CjpJobGroupCode, CjpJobCode 
				   HAVING COUNT(*) > 1)
  and jbccountrycode = @Country

IF @PRINT_DUPLICATEJOBSSAMEGRP = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 09-0011 There are duplicate job codes in the job groups.  Please remove duplicate record(s).'  
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT CjpJobGroupCode, CjpJobCode
FROM JobProg (NOLOCK)
join jobcode (NOLOCK) on jbcjobcode = CjpJobCode
WHERE JobProg.AuditKey IN (SELECT MIN(AuditKey) 
				   FROM JobProg (NOLOCK)
				   GROUP BY CjpJobGroupCode, CjpJobCode 
				   HAVING COUNT(*) > 1)
  and jbccountrycode = @Country

SET NOCOUNT OFF 

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------

--Org Level Spaces:

DECLARE @ORGSPACE CHAR(1)

SELECT @ORGSPACE = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM OrgLevel (NOLOCK)
WHERE CHARINDEX(' ',RTRIM(OrgCode),0) <> 0

IF @ORGSPACE = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 09-0012 Organizational Levels should not contain spaces.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON	
SELECT OrgCode, OrgDesc, OrgLvl
FROM OrgLevel (NOLOCK)
WHERE CHARINDEX(' ',RTRIM(OrgCode),0) <> 0
ORDER BY OrgLvl, OrgCode
SET NOCOUNT OFF
	
PRINT ''
END	

------------------------------------------------------------------------------------------------------------------------------------------

--Project Spaces:

DECLARE @PROJECTSPACE CHAR(1)

SELECT @PROJECTSPACE = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM Project (NOLOCK)
WHERE CHARINDEX(' ',RTRIM(CodCode),0) <> 0

IF @PROJECTSPACE = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 09-0013 Project codes should not contain spaces.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON	
SELECT CodCode, CodDesc
FROM Project (NOLOCK)
WHERE CHARINDEX(' ',RTRIM(CodCode),0) <> 0
ORDER BY CodCode
SET NOCOUNT OFF
	
PRINT ''
END	

------------------------------------------------------------------------------------------------------------------------------------------

--CHECK FOR DUPLICATE ORG LEVELS:

DECLARE @PRINT_ORGDUPLICATE CHAR(1)

SELECT @PRINT_ORGDUPLICATE = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END 
FROM OrgLevel (NOLOCK)
GROUP BY OrgCode, OrgLvl
HAVING COUNT(*) > 1

IF @PRINT_ORGDUPLICATE = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 09-0014 Duplicate Org Codes in the OrgLevel table.'  
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT DISTINCT OrgCode, OrgLvl 
FROM OrgLevel (NOLOCK)
GROUP BY OrgCode, OrgLvl
HAVING COUNT(*) > 1
ORDER BY OrgLvl, OrgCode
SET NOCOUNT OFF

PRINT ''
END
	
------------------------------------------------------------------------------------------------------------------------------------------

--CHECK FOR DUPLICATE PROJECT CODES:

DECLARE @PRINT_PROJECTDUPLICATE CHAR(1)

SELECT @PRINT_PROJECTDUPLICATE = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END 
FROM Project (NOLOCK)
GROUP BY CodCode
HAVING COUNT(*) > 1

IF @PRINT_PROJECTDUPLICATE = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 09-0015 Duplicate Project Codes in the Project table.'  
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT CodCode 
FROM Project (NOLOCK)
GROUP BY CodCode
HAVING COUNT(*) > 1
ORDER BY CodCode
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------

--KF 10/15/2020 New
--REQUESTED BY: Natasha Byrne

DECLARE @PRINT_EMPGENDER CHAR(1)

SELECT @PRINT_EMPGENDER = CASE WHEN COUNT(*) <> 2 THEN 'Y' ELSE 'N' END 
from EmployeeGender (NOLOCK)
WHERE GenderCode IN ('D','X')

IF @PRINT_EMPGENDER = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 09-0016 Employee Gender business rule missing values. Update to include D: "Decline to Answer" and X: "Non-Binary".'  
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT GenderCode, GenderCodeDescr, GenderCountryCode, ISNULL(GenderMapping,'') GenderMapping
from EmployeeGender (NOLOCK)
--WHERE GenderCode IN ('D','X') --COMMENTING OUT TO DISPLAY ALL ENTRIES IN CASE D AND X ARE NOT STANDARD
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------

/** Security and Web Setup **/

PRINT '____________________________________________________________________________________________________________________________________________________________'
PRINT ''
PRINT '10) Security and Web Setup'
PRINT '____________________________________________________________________________________________________________________________________________________________'
PRINT ''

------------------------------------------------------------------------------------------------------------------------------------------
-- 
--DIST CENTER CHECK:
--05/21/2019 VA: This test is now for all markets
--KF 05/23/2019 UPDATED THE VALIDATION

DECLARE @PRINT_DISTCENTER2 CHAR(1)

SELECT @PRINT_DISTCENTER2 = CASE WHEN COUNT(*) = 0 THEN 'Y' ELSE 'N' END 
FROM DistributionCenter (NOLOCK)
WHERE dstIsDefaultCenter = 'Y' AND dstActive = 'Y' --KF 10/15/2020 ADDED LOGIC FOR AN ACITVE DEFAULT LOCATION

--IF @PRINT_DISTCENTER2 = 'Y' /*and @ISMIDMARKET = 'Y'*/ and @ISCHECKPRINT = 'Y' --KF REMOVED THE MIDMARKET CHECK
IF @PRINT_DISTCENTER2 = 'Y' /*and @ISMIDMARKET = 'Y'*/ and (@ISCHECKPRINT = 'Y' OR @EEPAY = 'Y') --KF 10/15/2020 UPDATED
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 10-0001 You must have at least one Distribution Center established.'  
PRINT ''
SET @ERRORCOUNT += 1
END


/* --KF REMOVING THIS SECTION SINCE THE ABOVE VALIDATION IS NOT FOR ALL MARKETS
IF @PRINT_DISTCENTER2 = 'Y' and @ISMIDMARKET = 'N' and @ISCHECKPRINT = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!!  You must have at least one Distribution Center established if using Ultipro Check Print Services.'  
PRINT ''
SET @WARNINGCOUNT += 1
END
*/

------------------------------------------------------------------------------------------------------------------------------------------

--DIST CENTER CODE CHECK:

DECLARE @PRINT_DISTCENTER3 CHAR(1)

SELECT @PRINT_DISTCENTER3 = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END 
FROM DistributionCenter (NOLOCK)
WHERE isnumeric(DstDistributionCenterCode) = 1 and DstDistributionCenterCode between 1 and 99

IF @PRINT_DISTCENTER3 = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 10-0002 Distribution Center Code cannot be between 01 and 99. Must be Alpha.'  
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT DstDistributionCenterCode, DstDescription 
FROM DistributionCenter (NOLOCK)
WHERE isnumeric(DstDistributionCenterCode) = 1 and DstDistributionCenterCode between 1 and 99
ORDER BY DstDistributionCenterCode
SET NOCOUNT OFF 

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------

--Distribution Center:

DECLARE @PRINT_DISTCENTER CHAR(1)

SELECT @PRINT_DISTCENTER = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM DistributionCenter (NOLOCK)
WHERE DistributionCenter.DstIs2ndDayShipping = 'Y'

IF @PRINT_DISTCENTER = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 10-0003 2nd day shipping is configured for the following distribution centers.' 
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
SELECT DstDistributionCenterCode, DstDescription 
FROM DistributionCenter (NOLOCK)
WHERE DistributionCenter.DstIs2ndDayShipping = 'Y'
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- ms 20181120 replace
-- remove @ISMIDMARKET = 'Y'
--CHECK FOR TEST PAYROLL AUTOMATION STATUS PRIOR TO LIVE:

DECLARE @PRINT_PAPROCESS CHAR(1)

SELECT @PRINT_PAPROCESS = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM PAProcesses (NOLOCK)
WHERE PapStatus = 'TEST'
AND papProcessType NOT like 'CAN%'
AND @Country = 'USA'

IF @PRINT_PAPROCESS = 'Y' AND @ISGOLIVE = 'Y' 
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 10-0004 Please update Payroll Automation to ''Production'' for the following processes.'  
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT PapProcessType 
FROM PAProcesses (NOLOCK)
WHERE PapStatus = 'TEST'
AND papProcessType NOT like 'CAN%'
AND @Country = 'USA'

ORDER BY PapProcessType
SET NOCOUNT OFF

PRINT ''
END
------------------------------------------------------------------------------------------------------------------------------------------
-- ms 20181120 replace
-- remove @ISMIDMARKET = 'Y'
--CHECK FOR TEST PAYROLL AUTOMATION STATUS PRIOR TO LIVE:

DECLARE @PRINT_PAPROCESS2 CHAR(1)

SELECT @PRINT_PAPROCESS2 = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM PAProcesses (NOLOCK)
WHERE PapStatus = 'TEST'
AND papProcessType like 'CAN%'
AND @Country = 'CAN'

IF @PRINT_PAPROCESS2 = 'Y' AND @ISGOLIVE = 'Y' 
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 10-0004 Please update Payroll Automation to ''Production'' for the following processes.'  
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT PapProcessType 
FROM PAProcesses (NOLOCK)
WHERE PapStatus = 'TEST'
AND papProcessType like 'CAN%'
AND @Country = 'CAN'

ORDER BY PapProcessType
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- ms 20181120 replace
-- removed @ISMIDMARKET = 'Y'
-- Canada version
--CHECK PAYROLL AUTOMATION STATUS DURING TESTING:
 
DECLARE @PRINT_PATEST_CAN CHAR(1)

SELECT @PRINT_PATEST_CAN = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
-- SELECT *
FROM PAProcesses (NOLOCK)
WHERE PapStatus = 'PROD' 
AND papProcessType like 'CAN%'
AND @Country = 'CAN'
  -- select papProcessType, PapStatus, * from PAProcesses
IF  @PRINT_PATEST_CAN = 'Y' AND @ISGOLIVE = 'N'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 10-0005 Please update Payroll Automation to ''Test'' for the following processes.'
PRINT ' 		  Ensure that Payroll Automation is configured for cheque printing and EFT.'  
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT PapProcessType 
FROM PAProcesses (NOLOCK)
WHERE PapStatus = 'PROD' 
AND papProcessType like 'CAN%'
AND @Country = 'CAN'
ORDER BY PapProcessType
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- ms 20181120 replace
-- removed @ISMIDMARKET = 'Y'
-- USA Version
--CHECK PAYROLL AUTOMATION STATUS DURING TESTING:





DECLARE @PRINT_PATEST CHAR(1)

SELECT @PRINT_PATEST = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM PAProcesses (NOLOCK)
WHERE PapStatus <> 'TEST' 
AND (NOT EXISTS (SELECT 1 FROM PAProcesses WHERE papProcessType = 'PRINTCHECK')
  OR NOT EXISTS (SELECT 1 FROM PAProcesses WHERE papProcessType = 'NACHAFILE')
  OR NOT EXISTS (SELECT 1 FROM PAProcesses WHERE papProcessType = 'ULTIWAD'))
AND @Country = 'USA'

IF  @PRINT_PATEST = 'Y' AND @ISGOLIVE = 'N'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 10-0006 Please update Payroll Automation to ''Test'' for the following processes.'
PRINT ' 		  Ensure that Payroll Automation is configured for check printing, NACHA, and Wage Attachments.'  
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT PapProcessType 
FROM PAProcesses (NOLOCK)
WHERE PapStatus <> 'TEST'
AND (NOT EXISTS (SELECT 1 FROM PAProcesses WHERE papProcessType = 'PRINTCHECK')
  OR NOT EXISTS (SELECT 1 FROM PAProcesses WHERE papProcessType = 'NACHAFILE')/*
  OR NOT EXISTS (SELECT 1 FROM PAProcesses WHERE papProcessType = 'ULTIWAD')*/) --remove this last part of the test 'ULTIWAD' --KF 10/15/2020 updated per Yvonne Ruiz request.
AND @Country = 'USA'
ORDER BY PapProcessType
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- ms 20181120 replace
--Verify that PTO Plans are set as viewable by Manager and Employee:

DECLARE @PRINT_PTOVIEW CHAR(1)

SELECT @PRINT_PTOVIEW = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END 
FROM PtoView (NOLOCK)
JOIN Company (NOLOCK) ON ptoCOID = CmpCoID
WHERE (ptoEmployeeView <> 'Y' OR ptoManagerView <> 'Y')
  and cmpcountrycode = @Country
  AND @TOA = 'N'

IF @PRINT_PTOVIEW = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 10-0007 The following PTO plans are not set as viewable by Manager or Employee.'  
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
SELECT CmpCompanyCode, CmpCompanyName, PtoAccrual 
FROM PtoView (NOLOCK)
JOIN Company (NOLOCK) ON ptoCOID = CmpCoID
WHERE (ptoEmployeeView <> 'Y' OR ptoManagerView <> 'Y')
  and cmpcountrycode = @Country
  AND @TOA = 'N'
ORDER BY CmpCompanyCode, PtoAccrual
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- ms 20181120 replace
--Verify Accrual and Rollover Rule:

DECLARE @PRINT_PTOROLLOVER CHAR(1)

SELECT @PRINT_PTOROLLOVER = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END 
FROM AccrOpts (NOLOCK)
WHERE ((AccAccrCalcRule = '03' AND AccRolloverPer = 'F') OR (AccAccrCalcRule = '04' AND AccRolloverPer = 'F') OR (AccAccrCalcRule = '07' AND AccRolloverPer = 'Y')
OR (AccAccrCalcRule = '07' AND AccRolloverPer = 'W') OR (AccAccrCalcRule = '07' AND AccRolloverPer = 'M'))
and AccCountryCode = @Country

IF @PRINT_PTOROLLOVER = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 10-0008 The following PTO plans having conflicting accrual and rollover rules.'  
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
SELECT AccAccrCode, AccAccrCalcRule, AccRolloverPer
FROM AccrOpts (NOLOCK)
WHERE ((AccAccrCalcRule = '03' AND AccRolloverPer = 'F') OR (AccAccrCalcRule = '04' AND AccRolloverPer = 'F') OR (AccAccrCalcRule = '07' AND AccRolloverPer = 'Y')
OR (AccAccrCalcRule = '07' AND AccRolloverPer = 'W') OR (AccAccrCalcRule = '07' AND AccRolloverPer = 'M'))
and AccCountryCode = @Country
ORDER BY AccAccrCode
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- ms 20181120 replace
--ACCRUAL ROLLOVER RULE:

DECLARE @PRINT_ACCRROLL CHAR(1)

SELECT @PRINT_ACCRROLL = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM AccrOpts (NOLOCK)
WHERE AccRolloverPer = 'N'
and AccCountryCode = @Country

IF @PRINT_ACCRROLL = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 10-0009 The following PTO plans are setup with a rollover rule of No Rollover.' 
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
SELECT AccAccrCode, AccAccrOption, AccAccrDesc, AccRolloverPer 
FROM AccrOpts (NOLOCK)
WHERE AccRolloverPer = 'N'
and AccCountryCode = @Country
ORDER BY AccAccrOption
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- ms 20181120 replace
--ACCRUAL CARRY OVER:

DECLARE @PRINT_ACCRCARRY CHAR(1)

SELECT @PRINT_ACCRCARRY = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM AccrRate (NOLOCK)
JOIN AccrOpts (NOLOCK) ON ArrAccrOption = AccAccrOption
WHERE ArrMaxCarryOver IS NULL
and AccCountryCode = @Country

IF @PRINT_ACCRCARRY = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 10-0010 The following PTO plans do not have a Carry Over Rate (Carry Over Rate IS NULL).' 
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
SELECT AccAccrCode, AccAccrOption, AccAccrDesc, ArrMaxCarryOver 
FROM AccrRate (NOLOCK)
JOIN AccrOpts (NOLOCK) ON ArrAccrOption = AccAccrOption
WHERE ArrMaxCarryOver IS NULL
and AccCountryCode = @Country
ORDER BY AccAccrOption
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------

--Check for PTO plans using per included hours or dollars:
------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TL 20181120 replace
--To return PTO plans that use per included hours or dollars for US or CAN

DECLARE @PRINT_ACCRINCLUDEB_WARNING CHAR(1)

SELECT @PRINT_ACCRINCLUDEB_WARNING = 'Y' 
from ACCRINCL (NOLOCK)
 join ACCROPTS (NOLOCK) on AccAccrCode = AclAccrualCode
where AccAccrCalcRule in ('05','06') 
and @country = acccountrycode


IF @PRINT_ACCRINCLUDEB_WARNING = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 10-0011 Confirm list of earning codes for each accrual code plan calculation (using included hours or included earnings).'
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
select distinct acccountrycode,AclAccrualCode,AclEarnCode 
from ACCRINCL (NOLOCK)
 join ACCROPTS (NOLOCK) on AccAccrCode = AclAccrualCode
where AccAccrCalcRule in ('05','06')
 and @country = acccountrycode
 order by 1,2

SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TL 20181120 new
--To return PTO plans that have no rates setup for US or CAN
---05/21/2019 VA: This should be an ERROR
--KF 20190522 UPDATED MESSAGE

DECLARE @PRINT_ACCROPTB_WARNING CHAR(1)

SELECT @PRINT_ACCROPTB_WARNING = 'Y' 
from accropts  (NOLOCK)
where accaccroption not in (select arraccroption from accrrate) 
and @country = acccountrycode


IF @PRINT_ACCROPTB_WARNING = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
--PRINT '!!Warning!!  Accrual setup with no rate table.' --KF 20190522 UPDATED MESSAGE
PRINT '!!Error!! 10-0012 Accrual setup with no rate table.' --KF 20190522 UPDATED MESSAGE
PRINT ''
--SET @WARNINGCOUNT += 1
SET @ERRORCOUNT += 1

SET NOCOUNT ON
select acccountrycode,Accaccrcode, accaccroption, accaccrdesc
 from accropts (NOLOCK)
where accaccroption not in (select arraccroption from accrrate) 
and @country = acccountrycode


SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- ms 20181120 replace
--PTO IMPORT:
--05/21/2019 VA: Remove this test
--KF 20190522 REMOVED THE TEST

/*
DECLARE @PRINT_PTOIMPORT CHAR(1)

SELECT @PRINT_PTOIMPORT = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM PayGroupModel (NOLOCK) 
JOIN PayGroup (NOLOCK) ON pgmPayGroup = PgrPayGroup AND PgrStatus = 'A'
JOIN CoPayrollModel (NOLOCK) ON pgmPayrollModelID = prmPayrollModelID
WHERE (PgrProcessPTORequestDefault <> 'Y' OR PgrUsePTORequest <> 'Y') 
AND EXISTS(SELECT 1 
           FROM CoPayrollModelProcesses 
           JOIN CoPayrollModel (NOLOCK) ON pmpPayrollModelID = prmPayrollModelID 
           WHERE pmpPayrollModelID = pgmPayrollModelID AND pmpDesc = 'Import PTO')
and PgrCountryCode = @Country 

IF @PRINT_PTOIMPORT = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 10-0013 The following paygroups contain a payroll model with a step to import PTO requests.  Please run the following script to update the required fields.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT PgmPayGroup, PrmPayrollModelDesc, PgrProcessPTORequestDefault, PgrUsePTORequest 
FROM PayGroupModel (NOLOCK) 
JOIN PayGroup (NOLOCK) ON pgmPayGroup = PgrPayGroup AND PgrStatus = 'A'
JOIN CoPayrollModel (NOLOCK) ON pgmPayrollModelID = prmPayrollModelID
WHERE (PgrProcessPTORequestDefault <> 'Y' OR PgrUsePTORequest <> 'Y') 
AND EXISTS(SELECT 1 
           FROM CoPayrollModelProcesses 
           JOIN CoPayrollModel (NOLOCK) ON pmpPayrollModelID = prmPayrollModelID 
           WHERE pmpPayrollModelID = pgmPayrollModelID AND pmpDesc = 'Import PTO') 
and PgrCountryCode = @Country 
SET NOCOUNT OFF

PRINT 'UPDATE PayGroup 
SET    PgrProcessPTORequestDefault = ''Y'', 
       PgrUsePTORequest = ''Y'' 
WHERE  PgrStatus = ''A'' AND PgrPayGroup IN ( '''' ) --POPULATE WITH PAYGROUP(S)'
PRINT ''
END
*/

------------------------------------------------------------------------------------------------------------------------------------------
-- Aviva to follow up,  Should this be moved to Smart QA Employee script?
--PTO REQUEST IMPORT:
--05/21/2019 VA: This test should only run for GoLive = Y
--KF 20190522 UPDATED TO SET TEST ONLY FOR GoLive = Y

DECLARE @PRINT_PTOREQUESTIMPORT CHAR(1)

IF @ISGOLIVE = 'Y' --KF 20190522 UPDATED TO SET TEST ONLY FOR GoLive = Y
BEGIN
	SELECT @PRINT_PTOREQUESTIMPORT = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
	-- SELECT CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
	FROM PayGroupModel (NOLOCK) 
	JOIN PayGroup (NOLOCK) ON pgmPayGroup = PgrPayGroup AND PgrStatus = 'A'
	JOIN EmpComp (NOLOCK) ON EecPayGroup = PgrPayGroup
	JOIN PTORequest (NOLOCK) ON ptrEEID = EecEEID AND ptrCoID = EecCoID
	JOIN CoPayrollModel (NOLOCK) ON pgmPayrollModelID = prmPayrollModelID
	WHERE pgmPayrollType = 'R' 
	AND NOT EXISTS(SELECT * 
               FROM CoPayrollModelProcesses (NOLOCK) 
               JOIN CoPayrollModel (NOLOCK) ON pmpPayrollModelID = prmPayrollModelID 
               WHERE pmpPayrollModelID = pgmPayrollModelID AND pmpDesc = 'Import PTO')

	IF @PRINT_PTOREQUESTIMPORT = 'Y'
	BEGIN
	PRINT '*************************************************************************************************************************************************'
	PRINT ''
	PRINT '!!Warning!! 10-0014 The following paygroups have employees with PTO Requests; however, the payroll model assigned to the paygroup does not have a PTO import step.'
	PRINT ''
	SET @WARNINGCOUNT += 1

	SET NOCOUNT ON
	SELECT PgmPayGroup, PrmPayrollModelDesc
	FROM PayGroupModel (NOLOCK) 
	JOIN PayGroup (NOLOCK) ON pgmPayGroup = PgrPayGroup AND PgrStatus = 'A'
	JOIN EmpComp (NOLOCK) ON EecPayGroup = PgrPayGroup
	JOIN PTORequest (NOLOCK) ON ptrEEID = EecEEID AND ptrCoID = EecCoID
	JOIN CoPayrollModel (NOLOCK) ON pgmPayrollModelID = prmPayrollModelID
	WHERE pgmPayrollType = 'R' 
	AND NOT EXISTS(SELECT * 
               FROM CoPayrollModelProcesses (NOLOCK) 
               JOIN CoPayrollModel (NOLOCK) ON pmpPayrollModelID = prmPayrollModelID 
               WHERE pmpPayrollModelID = pgmPayrollModelID AND pmpDesc = 'Import PTO')
	GROUP BY PgmPayGroup, PrmPayrollModelDesc
	SET NOCOUNT OFF

	PRINT ''
	END
END


------------------------------------------------------------------------------------------------------------------------------------------
-- ms 20181120 replace
--PAYGROUP PROCESSING MODEL CHECK:

DECLARE @PRINT_PAYGROUPMODEL CHAR(1)

SELECT @PRINT_PAYGROUPMODEL = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM PayGroupModel (NOLOCK)
JOIN PayGroup (NOLOCK) ON PgmPayGroup = PgrPayGroup AND PgrStatus = 'A'
WHERE PgmPayrollModelID IS NULL AND PgmPayrollType = 'R'
  and pgrcountrycode = @Country

IF @PRINT_PAYGROUPMODEL = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 10-0015 A payroll processing model is not established for the following paygroups.'  
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT PgmPayGroup 
FROM PayGroupModel (NOLOCK)
JOIN PayGroup (NOLOCK) ON PgmPayGroup = PgrPayGroup AND PgrStatus = 'A'
WHERE PgmPayrollModelID IS NULL AND PgmPayrollType = 'R'
  and pgrcountrycode = @Country
ORDER BY PgmPayGroup
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- ms 20181120 replace
--Ensure the calendar starts in Jan for each paygroup:

------------------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------------------------------------------------------
-- ms 20181120 replace
--CHECK FOR TIME ENTRY TEMPLATE:

DECLARE @PRINT_TIMETEMPLATE CHAR(1)

SELECT @PRINT_TIMETEMPLATE = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM PayGroupModel (NOLOCK)
JOIN PayGroup (NOLOCK) ON  PgmPayGroup = PgrPayGroup AND PgrStatus = 'A'
WHERE PgmTemplateCode IS NULL AND PgmPayrollType = 'R'
  and PgrCountryCode = @Country

IF @PRINT_TIMETEMPLATE = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 10-0016 A time entry template is not established for the following paygroups.'  
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT PgmPayGroup 
FROM PayGroupModel (NOLOCK)
JOIN PayGroup (NOLOCK) ON  PgmPayGroup = PgrPayGroup AND PgrStatus = 'A'
WHERE PgmTemplateCode IS NULL AND PgmPayrollType = 'R'
  and PgrCountryCode = @Country
ORDER BY PgmPayGroup
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
--svlValue = N or there are 0 result rows:

DECLARE @PRINT_MFADISABLED CHAR(1)

--NOTE: By default, if no one ever clicks the button, then 0 rows will be returned for this query. That means it is disabled.?  If it is enabled,?svlValue will have a 'Y'. If?svlValue = N, then it is also disabled.
SELECT @PRINT_MFADISABLED = CASE WHEN COUNT(*) = 0 THEN 'Y' ELSE 'N' END
FROM dbo.vw_rbsCompanyValues (NOLOCK)
WHERE SvlCode = 'MFAReqDefaultPw' AND SvlValue = 'Y'

IF @ISGOLIVE = 'Y' AND @PRINT_MFADISABLED = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 10-0017 Password Multi-factor Authentication is not turned on.  Please review with customer and update setup.'  
PRINT ''
PRINT ''
SET @WARNINGCOUNT += 1
END

------------------------------------------------------------------------------------------------------------------------------------------

--Customer has SSO productkey, ensure that Direct Login is activated:

DECLARE @PRINT_HASSSO CHAR(1), @PRINT_HASDIRECTLOGIN CHAR(1)

SELECT @PRINT_HASSSO = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM ProductKeys (NOLOCK)
WHERE PrkProdCode = 'ADFS'

SELECT @PRINT_HASDIRECTLOGIN = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM vw_SSODirectLoginConfig

IF @ISGOLIVE = 'N' AND @PRINT_HASSSO = 'Y' AND @PRINT_HASDIRECTLOGIN = 'N'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 10-0018 Customer has SSO product key.  Please ensure Direct Login is activated.'  
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT *
FROM ProductKeys (NOLOCK)
WHERE PrkProdCode = 'ADFS'
ORDER BY PrkProdCode
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------

DECLARE @DUPLICATE_PTO CHAR(1)

SELECT @DUPLICATE_PTO = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END 
FROM ptoview
JOIN company ON cmpcoid = ptocoid
WHERE cmpcountrycode = @Country
  AND @Country = 'USA'
  AND @TOA = 'N'
GROUP BY ptoaccrual, ptocoid,cmpcompanyname
HAVING COUNT(*) > 1


IF @DUPLICATE_PTO = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 10-0019 Duplicate PTO View Table Entry.'  
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT ptoaccrual, ptocoid, cmpcompanyname
FROM ptoview
JOIN company ON cmpcoid = ptocoid
WHERE cmpcountrycode = @Country
  AND @Country = 'USA'
  AND @TOA = 'N'
GROUP BY ptoaccrual, ptocoid,cmpcompanyname
HAVING COUNT(*) > 1
ORDER BY 1,3
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------

/** ACA **/

PRINT '____________________________________________________________________________________________________________________________________________________________'
PRINT ''
PRINT '11) ACA'
PRINT '____________________________________________________________________________________________________________________________________________________________'
PRINT ''

------------------------------------------------------------------------------------------------------------------------------------------
-- ms 20181120 replace
--No ALE members:
--05/21/2019 VA: This should be a WARNING only
--KF 20190522 UPDATED MESSAGE

DECLARE @PRINT_NOALE CHAR(1)

SELECT @PRINT_NOALE = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END 
FROM Company (NOLOCK)
LEFT OUTER JOIN ACAALEMember (NOLOCK) ON CmpFedTaxID = EIN
WHERE Code IS NULL 
AND @Country = 'USA'
and CmpCountryCode = @Country

IF @PRINT_NOALE = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
--PRINT '!!Error!!  ACA configuration issue.  The following companies are not tied to an ALE member.' --KF 20190522 UPDATED MESSAGE
PRINT '!!Warning!! 11-0001 ACA configuration issue.  The following companies are not tied to an ALE member.' --KF 20190522 UPDATED MESSAGE
PRINT ''
--SET @ERRORCOUNT += 1
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
SELECT CmpCompanyCode, CmpCompanyName, CmpFedTaxID
FROM Company (NOLOCK)
LEFT OUTER JOIN ACAALEMember (NOLOCK) ON CmpCompanyCode = Code AND CmpFedTaxID = EIN
WHERE Code IS NULL 
AND @Country = 'USA'
and CmpCountryCode = @Country
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- ms 20181120 replace
--An ALE member exists and no deduction with a MED deduction type is configured for ACA:

IF @ISOELE = 'Y' --KF 10/15/2020 UPDATED
BEGIN

DECLARE @ALEMemberExists CHAR(1), @PRINT_ACADEDS CHAR(1)
   
SELECT @ALEMemberExists = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END 
FROM ACAALEMember (NOLOCK)

IF @ALEMemberExists = 'Y'
BEGIN
SELECT @PRINT_ACADEDS = CASE WHEN COUNT(*) = 0 THEN 'Y' ELSE 'N' END
FROM DedCode (NOLOCK)
WHERE DedCanBeOfferedUnderPPACA = '1' AND DedDedType = 'MED'
--could we update test to add logic: 
AND ISNULL(DedBenPlanProvider,'') <> 'API' --KF 09/08/2020 added logic to exclude API deductions (i.e. benefits prime or plansource).
AND @Country = 'USA'
AND dedCountryCode = @Country
END

IF @PRINT_ACADEDS = 'Y' AND @Country = 'USA'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 11-0002 There are no deductions configured for ACA.  Please review your configuration.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT * 
FROM ACAALEMember (NOLOCK)
where @Country = 'USA'
SET NOCOUNT OFF

PRINT ''
END
END

------------------------------------------------------------------------------------------------------------------------------------------
-- ms 20181120 replace
--An ALE member exists and the following earnings are flagged for ACA reporting:

DECLARE @PRINT_ALEEARNS CHAR(1)

SELECT @PRINT_ALEEARNS = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END 
FROM EarnCode (NOLOCK)
WHERE ErnInclInHealthCareHours = 'Y'
AND @Country = 'USA'
and ernCountryCode = @Country 

IF @PRINT_ALEEARNS = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Info!! 11-0003 The following earnings are flagged as included hours for the ACA auto generation.'  
PRINT ''
SET @LISTCOUNT += 1
-- KF missing error/warning message and counter

SET NOCOUNT ON
SELECT ErnEarncode, ErnStubDesc, ErnInclInHealthCareHours 
FROM EarnCode (NOLOCK)
WHERE ErnInclInHealthCareHours = 'Y' 
AND @Country = 'USA'
and ernCountryCode = @Country 
ORDER BY EarnCode.ErnEarncode
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------

/** Miscellaneous **/

PRINT '____________________________________________________________________________________________________________________________________________________________'
PRINT ''
PRINT '12) Miscellaneous'
PRINT '____________________________________________________________________________________________________________________________________________________________'
PRINT ''

------------------------------------------------------------------------------------------------------------------------------------------
-- ms 230181120 replace
-- Aviva to review, changed update to a print of the update statement
--Update Blank GL System IDs:
DECLARE @GlbAccts CHAR(1)

SELECT @GlbAccts = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM GlbAccts (NOLOCK)
WHERE GlbSystemID IS NULL

IF @GlbAccts = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 12-0001 GlbBaseSegment has null GlbSystemID.  Please run the following SQL script once GL Base Accounts have been updated.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON	
SELECT GlbBaseSegment
FROM GlbAccts (NOLOCK)
WHERE GlbSystemID IS NULL
ORDER BY GlbBaseSegment

	
PRINT 'UPDATE GlbAccts 
SET GlbSystemID = dbo.fn_GetTimedKey() 
WHERE GlbSystemID IS NULL'
PRINT ''
SET NOCOUNT OFF

END

--SET NOCOUNT ON	
--UPDATE GlbAccts 
--SET GlbSystemID = dbo.fn_GetTimedKey() 
--WHERE GlbSystemID IS NULL
--SET NOCOUNT OFF

------------------------------------------------------------------------------------------------------------------------------------------------------------
--Checks if GL Base Setup is Empty:
-- JJ 20181120 new
--05/21/2019 VA: This should be WARNING for GoLive = N and ERROR for GoLive = Y'
--KF 20190522 SPLIT TO TWO VALIDATIONS

DECLARE @Print_GLBaseAcct CHAR(1)

IF @ISGOLIVE = 'N'
BEGIN
SELECT @Print_GLBaseAcct = 'Y'
 from GLBAccts (nolock)
 having count(*) = 0


IF @Print_GLBaseAcct = 'Y' and @ISGOLIVE = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 12-0002 Please review your GL Base setup.  There are no GL Base Accounts listed for this customer.'
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
select count(*)  from GLBAccts (nolock)
 having count(*) = 0


SET NOCOUNT OFF

PRINT ''
END
END

DECLARE @Print_GLBaseAcct2 CHAR(1)

IF @ISGOLIVE = 'Y'
BEGIN
SELECT @Print_GLBaseAcct2 = 'Y'
 from GLBAccts (nolock)
 having count(*) = 0


IF @Print_GLBaseAcct2 = 'Y' and @ISGOLIVE = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 12-0003 Please review your GL Base setup.  There are no GL Base Accounts listed for this customer.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
select count(*)  from GLBAccts (nolock)
 having count(*) = 0


SET NOCOUNT OFF

PRINT ''
END
END


------------------------------------------------------------------------------------------------------------------------------------------------------------
--Checks if GL Segment Setup is Empty:
-- JJ 20181120 new
--05/21/2019 VA: This should be WARNING for GoLive = N and ERROR for GoLive = Y'
--KF 20190522 SPLIT TO TWO VALIDATIONS

DECLARE @Print_GLSegSeq CHAR(1)

IF @ISGOLIVE = 'Y'
BEGIN
SELECT @Print_GLSegSeq = 'Y'
 from GLSegSeq (nolock)
 having count(*) = 0


IF @Print_GLSegSeq = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 12-0004 Please review your GL Segment setup.  There are no GL Segments listed for this customer.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
select count(*)  from GLSegSeq (nolock)
 having count(*) = 0


SET NOCOUNT OFF

PRINT ''
END
END

DECLARE @Print_GLSegSeq2 CHAR(1)

IF @ISGOLIVE = 'N'
BEGIN
SELECT @Print_GLSegSeq2 = 'Y'
 from GLSegSeq (nolock)
 having count(*) = 0


IF @Print_GLSegSeq2 = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 12-0005 Please review your GL Segment setup.  There are no GL Segments listed for this customer.'
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
select count(*)  from GLSegSeq (nolock)
 having count(*) = 0


SET NOCOUNT OFF

PRINT ''
END
END

------------------------------------------------------------------------------------------------------------------------------------------
-- Aviva to review
--TestSessionDate table:
--05/21/2019 VA: This test should done for all markets
--KF 20190522 UPDATED

DECLARE @TESTSESSIONDATE CHAR(1)

SELECT @TESTSESSIONDATE = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM TestSessionDate (NOLOCK)
    
--IF @ISMIDMARKET = 'Y' AND @TESTSESSIONDATE = 'Y' AND @ISGOLIVE = 'Y' --KF 20190522 UPDATED
IF @TESTSESSIONDATE = 'Y' AND @ISGOLIVE = 'Y' --KF 20190522 UPDATED
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 12-0006 The TestSessionDate table should not contain a record.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON	
SELECT SUBSTRING(CompanyDBName,1,50) CompanyDBName, SessionDate, UserName 
FROM TestSessionDate (NOLOCK)
ORDER BY CompanyDBName
SET NOCOUNT OFF

PRINT ''
END	

------------------------------------------------------------------------------------------------------------------------------------------
-- ms 20181120 replace
--Holiday table does not have any records with a year = go live year:

DECLARE @PRINT_HOLIDAYS CHAR(1), @LIVEDATE_YEAREND VARCHAR(8)

SET @LIVEDATE_YEAREND = CONVERT(VARCHAR(4), YEAR(@LIVEDATE)) + '1231'

SELECT @PRINT_HOLIDAYS = CASE WHEN COUNT(*) = 0 THEN 'Y' ELSE 'N' END
FROM Holiday (NOLOCK)
WHERE HolHolidayDate BETWEEN GETDATE() AND CONVERT(VARCHAR(24), @LIVEDATE_YEAREND, 121)
  and HolCountryCode = @Country

IF @PRINT_HOLIDAYS = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 12-0007 There are no holidays established.  Please update the Holiday table and manually correct all pay groups with pay dates on a holiday.'  
PRINT ''
SET @ERRORCOUNT += 1
END

------------------------------------------------------------------------------------------------------------------------------------------
-- ms 20181120 replace
--KF 09/08/2020 REMOVED PAW2Approvals LOGIC
--VA 12/01/2021 add validation back
--Paw2Approvals query should show 1 for each tax group. YrEESum and YREEDet should be empty:

DECLARE @W2PRINTOFF CHAR(1), @YREESUMEMPTY CHAR(1), @YREEDETEMPTY CHAR(1)

IF MONTH(@LIVEDATE) = '1'
BEGIN

SELECT @W2PRINTOFF = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END --if table HAS records for year previous to live year this indicates W2 print job is stopped
FROM PAW2Approvals (NOLOCK)
WHERE pawYear = YEAR(@LIVEDATE) - 1

SELECT @YREESUMEMPTY = CASE WHEN COUNT(*) = 0 THEN 'Y' ELSE 'N' END
FROM YREESum (NOLOCK)
WHERE YesTaxYear = YEAR(@LIVEDATE) - 1

SELECT @YREEDETEMPTY = CASE WHEN COUNT(*) = 0 THEN 'Y' ELSE 'N' END
FROM YREEDet (NOLOCK)
WHERE YedTaxYear = YEAR(@LIVEDATE) - 1
END

IF @ISMIDMARKET = 'Y' AND @W2PRINTOFF = 'N' OR @YREESUMEMPTY = 'N' OR @YREEDETEMPTY = 'N' and @Country = 'USA'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 12-0008 Please ensure W2 print job is stopped and that the W2 tables are empty for your January go live.' --KF 09/08/2020 REMOVED PAW2Approvals LOGIC---VA 12/01/2021 add validation back
--PRINT '!!Warning!! 12-0008 Please ensure that the W2 tables are empty for your January go live.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT COUNT(pawTaxGroup) [Count], PawTaxGroup, PawYear, PawApproved, PawApprovedBy
FROM PAW2Approvals (NOLOCK)
WHERE pawYear = YEAR(@LIVEDATE) - 1
GROUP BY pawYear, pawTaxGroup, pawApproved, pawApprovedBy                              

SELECT Distinct YesTaxYear,YesTaxCalcGroupID,YesCompanyName,YesPayGroup 
FROM YREESum (NOLOCK)
WHERE YesTaxYear = YEAR(@LIVEDATE) - 1

SELECT Distinct YedTaxYear,YedTaxCalcGroupID 
FROM YREEDet (NOLOCK)
WHERE YedTaxYear = YEAR(@LIVEDATE) - 1
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- ms 20181120 replace
--Deduction ER W2 Reporting:

DECLARE @PRINT_ERW2REPORTING CHAR(1)

SELECT @PRINT_ERW2REPORTING = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM DedCode (NOLOCK)
WHERE DedDedType IN ('MED', 'DEN', 'VIS') AND DedDedType = 'N'
 and dedcountrycode = @Country
 and @Country = 'USA'

IF @PRINT_ERW2REPORTING = 'Y' 
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 12-0009 The following Deduction Codes with a deduction type of MED, DEN, or VIS are not flagged for W2 Reporting.' 
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
SELECT dedcountrycode, DedDedCode, DedStubDesc, CorBenOption, CorERRate
FROM DedCode (NOLOCK)
JOIN OptRate (NOLOCK) ON CorDedCode = DedDedCode
WHERE DedCode.DedDedType IN ('MED', 'DEN', 'VIS') AND OptRate.CorERRate = 0 AND CorBenOption <> 'Z'
ORDER BY dedcountrycode, DedDedCode, CorBenOption
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------

--Ensure audit is on:

DECLARE @PRINT_AUDITOFF CHAR(1)

SELECT @PRINT_AUDITOFF = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM AuditStatus (NOLOCK)
WHERE [Status] = 0

IF @PRINT_AUDITOFF = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 12-0010 Audit is not ON.  Please turn on audit.'  
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT * 
FROM AuditStatus (NOLOCK)
WHERE [Status] = 0
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------

--Review provider address:

DECLARE @PRINT_PROVIDERADDRESS CHAR(1)

SELECT @PRINT_PROVIDERADDRESS = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM Provider (NOLOCK)
WHERE ProProviderCode NOT LIKE '%SDU1' AND ProProviderCode <> 'Z' AND ProIsPayee = 'Y'

IF @PRINT_PROVIDERADDRESS = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Info!! 12-0011 Please review provider address.  USA - do NOT add provider address for Child Support agencies.'
PRINT ''
SET @LISTCOUNT += 1
-- KF missing error/warning message and counter

SET NOCOUNT ON
SELECT ProProviderCode, ProCompanyName, ProIsPayee, ProIsWageAttachment, ProAddressLine1, ProAddressState, ProAddressZipCode 
FROM Provider (NOLOCK)
WHERE ProProviderCode NOT LIKE '%SDU1' AND ProProviderCode <> 'Z' AND ProIsPayee = 'Y'
  and proaddresscountrycode = @country
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------
-- ms 20181120 replace
--Verify "display accrual hours taken" is checked if AZ is set up on Location:

DECLARE @Is_AZSIT_InLocation CHAR(1), @Is_DisplayAccrualHoursTaken_On CHAR(1)

--If we get results from this script:
SELECT @Is_AZSIT_InLocation = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM Location (NOLOCK)
WHERE LocSITWorkInStateCode = 'AZSIT'

--Then there should be values on this script:
SELECT @Is_DisplayAccrualHoursTaken_On = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM PayGroupConfigDataSource
WHERE EntryID IN(SELECT EntryID 
				 FROM PayGroupConfigDataSource
                 WHERE FieldName = 'DisplayAccrualHoursTaken' AND Value = 'Y')

IF @Is_AZSIT_InLocation = 'Y' AND @Is_DisplayAccrualHoursTaken_On = 'N' and @Country = 'USA'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
--PRINT '!!Warning!! 12-0012 The following companies have AZSIT but do not have the pay group options to display accrual hours taken.'
--Can we update this to say... ""pay statement options""... instead of Pay Group.   This is a setting in the Pay Statement Options in the web."
PRINT '!!Warning!! 12-0012 The following companies have AZSIT but do not have the pay statement options to display accrual hours taken.' --KF 10/15/2020 updated per Natasha Byrne
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
SELECT LocCode, LocDesc, LocSITWorkInStateCode Work_State
FROM Location (NOLOCK)
WHERE LocSITWorkInStateCode = 'AZSIT'
ORDER BY LocCode
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------

--Check calendar for regular payrolls where pay date sequence is NOT 1:
---05/21/2019 VA: move test to "misc" section
--KF 05/23/2019 MOVED TO THE Miscellaneous SECTION

DECLARE @PRINT_PAYDATESEQ CHAR(1)

SELECT @PRINT_PAYDATESEQ = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM PgPayPer (NOLOCK)
join PayGroup on PgrPayGroup = PgpPayGroup
WHERE PgrCountryCode = @Country AND PgpPeriodType = 'R' AND PgpPayDateSeq <> '1'

IF @PRINT_PAYDATESEQ = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 12-0013 The following are regular pay dates; however, the pay date sequence is not 1.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT PgpPeriodControl, PgpPayGroup, PgpPeriodType, PgpPayDateSeq 
FROM PgPayPer (NOLOCK)
join PayGroup on PgrPayGroup = PgpPayGroup
WHERE PgrCountryCode = @Country AND PgpPeriodType = 'R' AND PgpPayDateSeq <> '1'
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------

--KF 06/04/2019 NEW

DECLARE @TEST_DATA CHAR(1)

IF OBJECT_ID('tempdb..#TEST_DATA_IN_TABLES') IS NOT NULL DROP TABLE #TEST_DATA_IN_TABLES

SET NOCOUNT ON
SELECT *
INTO DBO.#TEST_DATA_IN_TABLES
FROM (
SELECT COUNT(*) AS CNT, 'iChkAccrs' AS TABLENAME FROM iChkAccrs UNION
SELECT COUNT(*) AS CNT, 'iChkDeds' AS TABLENAME FROM iChkDeds UNION
SELECT COUNT(*) AS CNT, 'iChkDDs' AS TABLENAME FROM iChkDDs UNION
SELECT COUNT(*) AS CNT, 'iChkDedsER' AS TABLENAME FROM iChkDedsER UNION
--SELECT COUNT(*) AS CNT, 'iChkDedTaxes' AS TABLENAME FROM iChkDedTaxes UNION --(Canadian table only) 
SELECT COUNT(*) AS CNT, 'iChkEarns' AS TABLENAME FROM iChkEarns UNION
SELECT COUNT(*) AS CNT, 'iChkTaxes' AS TABLENAME FROM iChkTaxes UNION
SELECT COUNT(*) AS CNT, 'ChkHead' AS TABLENAME FROM ChkHead UNION
SELECT COUNT(*) AS CNT, 'ChkGenList' AS TABLENAME FROM ChkGenList UNION
SELECT COUNT(*) AS CNT, 'chkBankChecks' AS TABLENAME FROM chkBankChecks UNION
SELECT COUNT(*) AS CNT, 'CalcLog' AS TABLENAME FROM CalcLog UNION
SELECT COUNT(*) AS CNT, 'reprintlog' AS TABLENAME FROM reprintlog UNION
SELECT COUNT(*) AS CNT, 'nachadat' AS TABLENAME FROM nachadat UNION
SELECT COUNT(*) AS CNT, 'nachasum' AS TABLENAME FROM nachasum UNION
SELECT COUNT(*) AS CNT, 'PayrollStatusMessage' AS TABLENAME FROM PayrollStatusMessage UNION
SELECT COUNT(*) AS CNT, 'PayrollStatus' AS TABLENAME FROM PayrollStatus UNION
SELECT COUNT(*) AS CNT, 'PrstLog' AS TABLENAME FROM PrstLog UNION
SELECT COUNT(*) AS CNT, 'DirectDepositFile' AS TABLENAME FROM DirectDepositFile 
) X


-- SELECT * FROM DBO.#TEST_DATA_IN_TABLES

SELECT @TEST_DATA = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
-- SELECT *
FROM DBO.#TEST_DATA_IN_TABLES
WHERE CNT > 0

IF @TEST_DATA = 'Y' AND @ISGOLIVE = 'Y' AND @Country = 'USA'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 12-0014 Please ensure the following tables are cleared of test data.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT TABLENAME, CNT AS RECORD_COUNT, @Country AS COUNTRY
FROM DBO.#TEST_DATA_IN_TABLES
WHERE CNT > 0
SET NOCOUNT OFF

PRINT ''
END



------------------------------------------------------------------------------------------------------------------------------------------

--KF 05/23/2019 MOVED TO THE Miscellaneous SECTION
--KF 10/15/2020 ADDED LOGIC AND JOIN FOR COUNTRY

DECLARE @MISC_0015 CHAR(1)

SELECT @MISC_0015 = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
-- SELECT cjpjobgroupcode, cjpjobcode
FROM jobprog 
JOIN jobGRP ON CjgJobGroupCode = CjpJobGroupCode
WHERE CjgCountryCode = @Country
AND NOT EXISTS (SELECT 1 FROM jobcode WHERE cjpjobcode = jbcjobcode)

IF @MISC_0015 = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 12-0015 Please update job group setup to remove invalid job code.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON
SELECT cjpjobgroupcode, cjpjobcode, CjgCountryCode
FROM jobprog 
JOIN jobGRP ON CjgJobGroupCode = CjpJobGroupCode
WHERE CjgCountryCode = @Country
AND NOT EXISTS (SELECT 1 FROM jobcode WHERE cjpjobcode = jbcjobcode)
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------

--KF 05/23/2019 MOVED TO THE Miscellaneous SECTION and limited to USA and CAN only

DECLARE @MISC_0016 CHAR(1)

SELECT @MISC_0016 = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
-- SELECT jbcwccode, jbcjobcode, JbcDesc 
FROM jobcode
WHERE ((jbcwccode IS NULL) OR (jbcwccode = 'Z'))
AND JbcCountryCode = @Country AND @Country IN ('USA','CAN')


IF @MISC_0016 = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 12-0016 The following jobs do not have a proper WC code attached. Please review setup if customer tracks WC thru Ultipro.'
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
SELECT jbcwccode, jbcjobcode, JbcDesc 
FROM jobcode
WHERE ((jbcwccode IS NULL) OR (jbcwccode = 'Z'))
AND JbcCountryCode = @Country AND @Country IN ('USA','CAN')
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------

--KF 05/23/2019 MOVED TO THE Miscellaneous SECTION

DECLARE @MISC_0017 CHAR(1)

SELECT @MISC_0017 = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM ProductKeys
WHERE PrkProdCode = 'POSM'

IF @MISC_0017 = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 12-0017 Customer has product key for Position Management. Please review if product is truly needed.'
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON
SELECT *
FROM ProductKeys
WHERE PrkProdCode = 'POSM'
SET NOCOUNT OFF

PRINT ''
END

------------------------------------------------------------------------------------------------------------------------------------------

--KF 10/15/2019
--REQUESTED BY: Michelle Pounds Ricco
IF @Country = 'USA'
BEGIN
DECLARE @MISC_0018 CHAR(1)

Select @MISC_0018 = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
from DistributionCenter
where dstDistributionCenterCode not like '%MAIL%'
and dstShippingAccountNum like '%Postage%'

IF @MISC_0018 = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 12-0018 You have a distribution center that is not "USMAIL" set with an account number of "Postage." Please review your configuration.'
PRINT ''
SET @ERRORCOUNT += 1

Select dstDistributionCenterCode,dstDescription,dstShippingProv,dstShippingAccountNum
from DistributionCenter
where dstDistributionCenterCode not like '%MAIL%'
and dstShippingAccountNum like '%Postage%'
SET NOCOUNT OFF

PRINT ''
END
END

------------------------------------------------------------------------------------------------------------------------------------------

--KF 10/15/2019
--REQUESTED BY: Michelle Pounds Ricco

IF @Country = 'USA'
BEGIN
DECLARE @MISC_0019 CHAR(1)

Select @MISC_0019 = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
from DistributionCenter
where dstDistributionCenterCode like '%MAIL%'
and dstShippingAccountNum NOT like '%Postage%'

IF @MISC_0019 = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 12-0019 You have a distribution center that is "USMAIL" set with an account number that is not "Postage." Please review your configuration.'
PRINT ''
SET @ERRORCOUNT += 1

Select dstDistributionCenterCode,dstDescription,dstShippingProv,dstShippingAccountNum
from DistributionCenter
where dstDistributionCenterCode like '%MAIL%'
and dstShippingAccountNum NOT like '%Postage%'
SET NOCOUNT OFF

PRINT ''
END
END

------------------------------------------------------------------------------------------------------------------------------------------

--KF 10/15/2019
--REQUESTED BY: Mike Sousa

IF @Country = 'USA'
BEGIN
DECLARE @MISC_0020 CHAR(1)

Select @MISC_0020 = CASE WHEN COUNT(*) = 0 THEN 'Y' ELSE 'N' END
from DistributionCenter
where dstDistributionCenterCode like '%MAIL%'
and dstShippingAccountNum like '%Postage%'

IF @MISC_0020 = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 12-0020 You do not have a distribution center to mail an employee''s check/DDA to their home address or you have set it up incorrectly.'
PRINT ''
SET @WARNINGCOUNT += 1

Select dstDistributionCenterCode,dstDescription,dstShippingProv,dstShippingAccountNum
from DistributionCenter
where dstDistributionCenterCode like '%MAIL%'
OR dstShippingAccountNum like '%Postage%' --USING LOGIC TO SHOW ANY THAT HIT EITHER CRITERIA SO THEY MAY GET RESULTS
SET NOCOUNT OFF

PRINT ''
END
END


------------------------------------------------------------------------------------------------------------------------------------------
/** Pay Groups **/

PRINT '____________________________________________________________________________________________________________________________________________________________'
PRINT ''
PRINT '13) Pay Groups'
PRINT '____________________________________________________________________________________________________________________________________________________________'
PRINT ''

------------------------------------------------------------------------------------------------------------------------------------------

-- KF 20190604 NEW

DECLARE @PAYGROUP_0001 CHAR(1)

SELECT @PAYGROUP_0001 = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
--SELECT PgrPayGroup, PgrDesc, PgrStepSetID
FROM PayGroup (NOLOCK)
WHERE PgrCountryCode = @Country AND PgrStepSetID <>'BASIT'


IF @PAYGROUP_0001 = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 13-0001 Please correct pay group setup to use delivered payroll step set.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON	
SELECT PgrPayGroup, PgrDesc, PgrStepSetID 
FROM PayGroup (NOLOCK)
WHERE PgrCountryCode = @Country AND PgrStepSetID <>'BASIT'
SET NOCOUNT OFF

END

------------------------------------------------------------------------------------------------------------------------------------------

-- KF 20190604 NEW

DECLARE @PAYGROUP_0002 CHAR(1)

SELECT @PAYGROUP_0002 = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
-- SELECT PgrPayGroup, PgrDesc
FROM PayGroup (NOLOCK)
WHERE ((PgrDesc LIKE '#') OR (PgrDesc LIKE '-') OR (PgrDesc LIKE '@') OR (PgrDesc LIKE '^') OR (PgrDesc LIKE '*'))


IF @PAYGROUP_0002 = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 13-0002 Please remove special character from Pay Group name.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON	
SELECT PgrPayGroup, PgrDesc
FROM PayGroup (NOLOCK)
WHERE ((PgrDesc LIKE '#') OR (PgrDesc LIKE '-') OR (PgrDesc LIKE '@') OR (PgrDesc LIKE '^') OR (PgrDesc LIKE '*'))
SET NOCOUNT OFF

END

------------------------------------------------------------------------------------------------------------------------------------------

-- KF 20190604 NEW

BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Info!! 13-0003 Review list of Pay Groups and ensure the correct Banks are attached to each Pay Group.'
PRINT ''
SET @LISTCOUNT += 1


SET NOCOUNT ON	
Select PgrPayGroup, PgrDesc, PgrPayFrequency, PgrSchedHrs, PgrStatus, PgrBankId, BnkBankName
from PayGroup
JOIN Bank (NOLOCK) ON PgrBankId = BnkCoBankID
 where pgrcountrycode = @country
order by 1,2
SET NOCOUNT OFF

END

------------------------------------------------------------------------------------------------------------------------------------------
/** TOA **/

PRINT '____________________________________________________________________________________________________________________________________________________________'
PRINT ''
PRINT '14) TOA'
PRINT '____________________________________________________________________________________________________________________________________________________________'
PRINT ''

------------------------------------------------------------------------------------------------------------------------------------------
-- KF 20190604 NEW
DECLARE @TOA_0001 CHAR(1)

IF @TOA = 'Y'
BEGIN

SELECT @TOA_0001 = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
--SELECT CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM (
SELECT * FROM compsettings 
WHERE name = 'TOAEnabledDate' 
AND value = '2999-12-31'
UNION
SELECT * FROM compsettings 
WHERE Name = 'TOAEnabled' 
AND value = 0) X

IF @TOA_0001 = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 14-0001 TOA is not enabled, please reach out to TMC.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON	
SELECT [Description], ID, Name, [Namespace], Value
FROM compsettings 
WHERE name = 'TOAEnabledDate' 
AND value = '2999-12-31'
UNION
SELECT [Description], ID, Name, [Namespace], Value
FROM compsettings 
WHERE Name = 'TOAEnabled' 
AND value = 0
SET NOCOUNT OFF

END
END

------------------------------------------------------------------------------------------------------------------------------------------
-- KF 20190604 NEW
DECLARE @TOA_0002 CHAR(1)

IF @TOA = 'Y'
BEGIN

SELECT @TOA_0002 = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
--SELECT * 
FROM compsettings 
WHERE name = 'TOAEnabledDate' 
AND value <> '2999-12-31' 
AND value IS NOT NULL 
AND value <> '' 
AND (CASE WHEN (Select COUNT(*) CNT from AccrOpts) > 0 THEN 'Y' ELSE 'N' END) = 'Y'


IF @TOA_0002 = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 14-0002 TOA is enabled but a Core PTO Benefit plan is configured.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON	
SELECT AccAccrCalcRule, AccAccrCode, AccAccrDesc, AccAccrOption, AccIsWebViewable
FROM AccrOpts
SET NOCOUNT OFF

END
END

------------------------------------------------------------------------------------------------------------------------------------------
-- KF 20190604 NEW
DECLARE @TOA_0003 CHAR(1)

IF @TOA = 'N'
BEGIN

SELECT @TOA_0003 = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
FROM (
SELECT * 
FROM compsettings 
WHERE name = 'TOAEnabledDate' 
AND value <> '2999-12-31' 
AND value IS NOT NULL 
AND value <> '' 
UNION
SELECT * 
FROM compsettings 
WHERE Name = 'TOAEnabled' 
AND value = 1
) X

IF @TOA_0003 = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Error!! 14-0003 TOA is enabled, run script to disable TOA.'
PRINT ''
SET @ERRORCOUNT += 1

SET NOCOUNT ON	
SELECT [Description], ID, Name, [Namespace], Value
FROM compsettings 
WHERE name = 'TOAEnabledDate' 
AND value <> '2999-12-31' 
AND value IS NOT NULL 
AND value <> '' 
UNION
SELECT [Description], ID, Name, [Namespace], Value
FROM compsettings 
WHERE Name = 'TOAEnabled' 
AND value = 1
SET NOCOUNT OFF

END
END

------------------------------------------------------------------------------------------------------------------------------------------
-- KF 20190604 NEW
DECLARE @TOA_0004 CHAR(1)

IF @TOA = 'Y'
BEGIN

SELECT @TOA_0004 = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
-- SELECT *
FROM PayGroupModel (NOLOCK) 
JOIN PayGroup (NOLOCK) ON pgmPayGroup = PgrPayGroup AND PgrStatus = 'A'
JOIN CoPayrollModel (NOLOCK) ON pgmPayrollModelID = prmPayrollModelID
WHERE EXISTS (SELECT 1 
           FROM CoPayrollModelProcesses 
           JOIN CoPayrollModel (NOLOCK) ON pmpPayrollModelID = prmPayrollModelID 
           WHERE pmpPayrollModelID = pgmPayrollModelID AND pmpDesc = 'Import PTO')



IF @TOA_0004 = 'Y'
BEGIN
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Warning!! 14-0004 The following paygroups do not have a payroll model with the "Bring in PTO" step, taken time may not come into payroll.'
PRINT ''
SET @WARNINGCOUNT += 1

SET NOCOUNT ON	
SELECT PgrPayGroup, PgrDesc, PgrModel, PgrStatus, pgmPayrollModelID, pgmPayrollType, pgmTemplateCode, pmpDesc, pmpPayrollModelID
FROM PayGroupModel (NOLOCK) 
JOIN PayGroup (NOLOCK) ON pgmPayGroup = PgrPayGroup AND PgrStatus = 'A'
JOIN CoPayrollModel (NOLOCK) ON pgmPayrollModelID = prmPayrollModelID
JOIN CoPayrollModelProcesses (NOLOCK) ON pmpPayrollModelID = prmPayrollModelID
WHERE EXISTS (SELECT 1 
           FROM CoPayrollModelProcesses 
           JOIN CoPayrollModel (NOLOCK) ON pmpPayrollModelID = prmPayrollModelID 
           WHERE pmpPayrollModelID = pgmPayrollModelID AND pmpDesc = 'Import PTO')
SET NOCOUNT OFF

END
END

------------------------------------------------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------

DECLARE @CURRUSER VARCHAR(100)

SET @CURRUSER = CURRENT_USER

PRINT ''
PRINT ''
PRINT '*************************************************************************************************************************************************'
PRINT '*************************************************************************************************************************************************'
PRINT ''
PRINT '!!Variable Selections!!'
PRINT ''
PRINT 'ISGOLIVE: ' + @ISGOLIVE
PRINT 'ISNONPROFIT: ' + @ISNONPROFIT
PRINT 'ISCHECKPRINT: ' + @ISCHECKPRINT
PRINT 'LIVEDATE: ' + CONVERT(VARCHAR(24), @LIVEDATE, 107)
PRINT 'ISOELE: ' + @ISOELE
PRINT 'ISTOA: ' + @TOA
PRINT 'ENVIRONMENT: ' + @ENVIRONMENT
PRINT 'COUNTRY: ' + @Country
PRINT ''
PRINT 'WARNINGCOUNT: ' + CONVERT(VARCHAR,@WARNINGCOUNT)
PRINT 'ERRORCOUNT: ' + CONVERT(VARCHAR,@ERRORCOUNT)
PRINT 'LISTCOUNT: ' + CONVERT(VARCHAR,@LISTCOUNT)
PRINT '__________________________________'
PRINT 'Date/Time Run: ' + CONVERT(VARCHAR(24), GETDATE(), 100)
PRINT 'Run By User: ' + @CURRUSER
PRINT ''
PRINT '*************************************************************************************************************************************************'
PRINT '*************************************************************************************************************************************************'



