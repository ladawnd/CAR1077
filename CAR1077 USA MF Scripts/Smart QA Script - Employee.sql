/*****************************************************************************************************************
** Name: Smart QA Script - Employee.sql
** Desc: Validation of employee data after it's loaded into Ultipro.
** When to use:	After any data conversion or SQL updates.  Run this script, analyze the results.
**              Some errors will be obvious TC fixes but many will need to be passed to the SC\Customer
**				to review AND fix in Ultipro.  Some fixes by the SC\Customer will be setup changes while
**				others will require employee data updates.  If volume of employee data updates is large,
**				then the TC could be asked to assist.
** Auth: Eric Hason, Sean Merz, Miles Supola, Joe Jacob
** Date: 12/11/2017
**************************
** Change History
**************************
** CID	Date		Author		Description	
** ---  --------	--------	------------------------------------
** 001	2017-12-11	Team		Version 1
** 002	2019-07-01	Miles S		Version 2
** 003  2019-10-24  Miles S		Added TC error 00540
** 004  2020-10-23  DC Team 	Revew, Adds and Update (Kevin F, Maciek T, Gene S, Joe J)
** 004  2020-11-20  DC Team 	Revew, Adds and Update (Kevin F, Maciek T, Gene S, Joe J)
******************************************************************************************************************/
set nocount on
/*DECLARE VARIABLES*/
	DECLARE @LIVEDATE datetime
	DECLARE @CreateDate datetime
	DECLARE @ENVIRONMENT VARCHAR(50)
	DECLARE @LastDateRunningQA datetime
	DECLARE @LastUserRunningQA VARCHAR(50)
	DECLARE @Country VARCHAR(3)
	DECLARE @TaxRate_USMED Float
	DECLARE @TaxRate_USSOC Float
	
	
/******SET VARIABLES PRIOR TO SCRIPT EXECUTION*******/
	SET @LIVEDATE = '01/01/2024' -- Enter earliest OB Check Date  'MM/DD/YYYY' FORMAT
	SET @createdate = getdate() - 364 -- Defaulted to 120 to pull employees loaded in last 120 days. Only adjust if necessary. Mario rule use 999 - lower if needed.
	SET @ENVIRONMENT = 'G03P11' -- UltiPro Environment you are working in. 
	SET @Country = 'USA' -- Enter USA or CAN.

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
print getdate()
RAISERROR ('Employee QA Started', 0, 1) WITH NOWAIT
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
 
 
IF not EXISTS (SELECT * FROM sysobjects WHERE NAME = 'ACE_DataQualityCheck_log' and xType = 'U')
	CREATE TABLE dbo.ACE_DataQualityCheck_log (
	LastUserRunningQA varchar(255),
	LastDateRunningQA Datetime,
	) ON [PRIMARY]  --select count(*) from #ACE_DataQualityCheck

	SET @LastDateRunningQA = GETDATE()
	set @LastUserRunningQA = SUSER_NAME()
	INSERT into dbo.ACE_DataQualityCheck_log (LastDateRunningQA, LastUserRunningQA) select @LastDateRunningQA, @LastUserRunningQA

	IF OBJECT_ID('tempdb..#ACE_DataQualityCheck') IS NOT NULL
    DROP TABLE #ACE_DataQualityCheck

CREATE TABLE #ACE_DataQualityCheck (
	CompanyCode char(5) NULL,
	PayGroup char(6) NULL,
	RecordType varchar(20) NOT NULL,
	EmpNo varchar(9) NULL,
	EmployeeName varchar(255) NULL,
	EmploymentStatus char(1) NULL,
	Severity varchar(1) NOT NULL,
	ErrorNumber varchar(5) NOT NULL,
	ErrorMessage varchar(255) NOT NULL,
	ErrorKeyLabel varchar(255) NOT NULL,
	ErrorKeyFieldName varchar(255) NOT NULL,
	ErrorKeyValue varchar(8000) NULL,
	Details varchar(500) NULL,
	EEID char(12) NULL,
	COID char(5) NULL,
	ConSystemid char(12) NULL,
	DependentName varchar(255) NOT NULL,
	RoleToReview varchar(255) NULL
) ON [PRIMARY]


/*DO NOT MODIFY*/
         DECLARE @ISMIDMARKET CHAR(1)
             SELECT @ISMIDMARKET = CASE WHEN COUNT(*) > 0 THEN 'Y' ELSE 'N' END
                WHERE SUBSTRING(@ENVIRONMENT, 2, 1) = 'W' AND ISNUMERIC(SUBSTRING(@ENVIRONMENT, 3, 2)) = 1


-- Pull tax rates into variables

Select @TaxRate_USMED = MttTaxPercentOverBase
From Ultipro_System..TxCdMast WITH (NOLOCK)
INNER JOIN Ultipro_System..TxtbMast WITH (NOLOCK)
ON MtcDateTimeCreated  = MttDateTimeCreated AND MtcTaxCode = MttTaxCode
   -- AND MttFilingStatus = 'M'  AND  MttTaxCalcRule in ('A','L','E','M','Q','W','Y')
WHERE getdate() between MtcEffectiveDate and MtcEffectiveStopDate
AND MtcHasBeenReplaced = 'N'
AND MtcTaxCode = 'USMEDER'

Select @TaxRate_USSOC = MttTaxPercentOverBase
From Ultipro_System..TxCdMast WITH (NOLOCK)
INNER JOIN Ultipro_System..TxtbMast WITH (NOLOCK)
ON MtcDateTimeCreated  = MttDateTimeCreated AND MtcTaxCode = MttTaxCode
   -- AND MttFilingStatus = 'M'  AND  MttTaxCalcRule in ('A','L','E','M','Q','W','Y')
WHERE getdate() between MtcEffectiveDate and MtcEffectiveStopDate
AND MtcHasBeenReplaced = 'N'
AND MtcTaxCode = 'USSOCER'

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = eecpaygroup
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00001'
		,ErrorMessage = 'The Username should be an email address.'
		,ErrorKeyLabel = 'Web Username'
		,ErrorKeyFieldName= 'SusUserName'
		,ErrorKeyValue = SusUserName
		,Details = ''
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid=''
FROM EmpComp (NOLOCK)
JOIN vw_SecUserContext (NOLOCK) ON sucUserKey = EecEEID
JOIN vw_SecUsers (NOLOCK) ON vw_SecUserContext.sucUserID = vw_SecUsers.susUserID
JOIN EmpPers (NOLOCK) on eeceeid = eepeeid
JOIN Company (NOLOCK) on cmpcoid=eeccoid
WHERE EecEmplStatus = 'A'
AND  NULLIF(LTRIM(RTRIM(SusUserName)),'') IS NOT NULL 
AND (PATINDEX('%[ &'',:;!+=\/()<>]%', LTRIM(RTRIM(SusUserName))) > 0 OR 
	 PATINDEX('[@.-_]%', SusUserName) > 0 OR 
	 PATINDEX('%[@.-_]', SusUserName) > 0 OR 
	 SusUserName NOT LIKE '%@%.%' OR 
	 SusUserName LIKE '%..%' OR SusUserName LIKE '%@%@%' OR SusUserName LIKE '%.@%' OR SusUserName LIKE '%@.%' OR 
	 SusUserName LIKE '%.cm' OR SusUserName LIKE '%.co' OR SusUserName LIKE '%.or' OR SusUserName LIKE '%.ne' OR 
	 LEN(LTRIM(RTRIM(SusUserName))) > 50) 
AND @ISMIDMARKET = 'Y'	  
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = eecpaygroup
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00002'
		,ErrorMessage = 'More than one current Status History Record found in EmpHStat.'
		,ErrorKeyLabel = 'Is Current'
		,ErrorKeyFieldName= 'EshIsCurrent'
		,ErrorKeyValue = EshIsCurrent
		,Details = 'Count of Current Records = ' + ltrim(rtrim(convert(char(20),COUNT(EshIsCurrent))))
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid=''
FROM EmpHStat (NOLOCK)
JOIN EmpComp (NOLOCK) on eeceeid = esheeid AND eeccoid = eshcoid
JOIN EmpPers (NOLOCK) ON EepEEID = EshEEID 
JOIN Company (NOLOCK) on eeccoid = cmpcoid
WHERE EshIsCurrent = 'Y'
AND eepdatetimecreated >= @createdate
GROUP BY EepNameLast, EepNameFirst, CmpCompanyCode, eecPayGroup, eecempno, eecemplstatus,EshIsCurrent, eeceeid, eeccoid
HAVING COUNT(EshIsCurrent) > 1

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = eecpaygroup
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00003'
		,ErrorMessage = 'EmpHStat status start date is after the status stop date.'
		,ErrorKeyLabel = 'Status Start Date'
		,ErrorKeyFieldName= 'EshStatusStartDate'
		,ErrorKeyValue = isnull(convert(char(10),EshStatusStartDate,110),'') 
		,Details = 'EshStatusStartDate of '+isnull(convert(char(10),EshStatusStartDate,110),'') + ' > EshStatusStopDate of '+isnull(convert(char(10),EshStatusStopDate,110),'')
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid=''
FROM EmpHStat (NOLOCK)
JOIN EmpComp (NOLOCK) on eeceeid = esheeid AND eeccoid = eshcoid
JOIN EmpPers (NOLOCK) ON EepEEID = EshEEID 
JOIN Company (NOLOCK) on eeccoid = cmpcoid
WHERE EshStatusStartDate > EshStatusStopDate
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = eecpaygroup
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00004'
		,ErrorMessage = 'The Next Performance Review Date is NULL.'
		,ErrorKeyLabel = 'Date Of Next Perf Review'
		,ErrorKeyFieldName= 'EecDateOfNextPerfReview'
		,ErrorKeyValue = isnull(convert(char(10),EecDateOfNextPerfReview,110),'')
		,Details = ''
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid=''
FROM EmpComp (NOLOCK)
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) on eeccoid = cmpcoid
WHERE NULLIF(EecDateOfNextPerfReview,'') IS NULL 
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = eecpaygroup
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00005'
		,ErrorMessage = 'The Next Salary Review Date is NULL.'
		,ErrorKeyLabel = 'Date Of Next Sal Review'
		,ErrorKeyFieldName= 'EecDateOfNextPerfReview'
		,ErrorKeyValue = isnull(convert(char(10),EecDateOfNextSalReview,110),'')
		,Details = ''
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid=''
FROM EmpComp (NOLOCK)
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) on eeccoid = cmpcoid
WHERE NULLIF(EecDateOfNextSalReview,'') IS NULL
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = eecpaygroup
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00006'
		,ErrorMessage = 'First Name Field contains punctuation/special characters'
		,ErrorKeyLabel = 'First Name'
		,ErrorKeyFieldName= 'EepNameFirst'
		,ErrorKeyValue = case when EepNameFirst like '%,%' AND EepNameFirst not like '%%' then ''+ISNULL(RTRIM(EepNameFirst),'')+''
								when EepNameFirst like '%,%' AND EepNameFirst like '%%' then ''+REPLACE(ISNULL(RTRIM(EepNameFirst),''),'','')+''
							else ISNULL(RTRIM(EepNameFirst),'') end
		,Details = ''
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = ''
		,ConSystemid=''
	FROM EmpComp (NOLOCK)
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
	--WHERE dbo.dsi_fn_SpecialCharCheck (EepNameFirst) = 1
WHERE PATINDEX('%[^A-Z^a-z^0-9^ ^'']%', REPLACE(EepNameFirst,'-','')) > 0  --Could not figure out how to exclude dashes so did a replace
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = eecpaygroup
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00007'
		,ErrorMessage = 'Last Name Field contains punctuation/special characters'
		,ErrorKeyLabel = 'Last Name'
		,ErrorKeyFieldName= 'EepNameLast'
		,ErrorKeyValue = case when EepNameLast like '%,%' AND EepNameLast not like '%%' then ''+ISNULL(RTRIM(EepNameLast),'')+''
								when EepNameLast like '%,%' AND EepNameLast like '%%' then ''+REPLACE(ISNULL(RTRIM(EepNameLast),''),'','')+''
							else ISNULL(RTRIM(EepNameLast),'') end
		,Details = ''
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = ''
		,ConSystemid=''
	FROM EmpComp (NOLOCK)
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
	--WHERE dbo.dsi_fn_SpecialCharCheck (EepNameLast) = 1
WHERE PATINDEX('%[^A-Z^a-z^0-9^ ^''^.]%', REPLACE(EepNameLast,'-','')) > 0  --Could not figure out how to exclude dashes so did a replace
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = eecpaygroup
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00008'
		,ErrorMessage = 'Middle Name Field contains punctuation/special characters'
		,ErrorKeyLabel = 'Middle Name'
		,ErrorKeyFieldName= 'EepNameMiddle'
		,ErrorKeyValue = case when EepNameMiddle like '%,%' AND EepNameMiddle not like '%%' then ''+ISNULL(RTRIM(EepNameMiddle),'')+''
								when EepNameMiddle like '%,%' AND EepNameMiddle like '%%' then ''+REPLACE(ISNULL(RTRIM(EepNameMiddle),''),'','')+''
							else ISNULL(RTRIM(EepNameMiddle),'') end
		,Details = ''
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = ''
		,ConSystemid=''
	FROM EmpComp (NOLOCK)
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
	--WHERE dbo.dsi_fn_SpecialCharCheck (EepNameMiddle) = 1
WHERE (PATINDEX('%[^A-Z^a-z^0-9^ ^''^.]%', REPLACE(EepNameMiddle,'-','')) > 0 AND len(EepNameMiddle) = 2) --(if single character, then allow for period)
		or (PATINDEX('%[^A-Z^a-z^0-9^ ^'']%', REPLACE(EepNameMiddle,'-','')) > 0 AND len(EepNameMiddle) > 2) --(if longer string then don't allow period)
AND eepdatetimecreated >= @createdate

--Address 1 Field contains punctuation/special characters
INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = eecpaygroup
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00009'
		,ErrorMessage = 'Address 1 Field contains punctuation/special characters'
		,ErrorKeyLabel = 'Address Line 1'
		,ErrorKeyFieldName= 'eepAddressLine1'
		,ErrorKeyValue = case when eepAddressLine1 like '%,%' AND eepAddressLine1 not like '%%' then ''+ISNULL(RTRIM(EepAddressLine1),'')+''
								when eepAddressLine1 like '%,%' AND eepAddressLine1 like '%%' then ''+REPLACE(ISNULL(RTRIM(EepAddressLine1),''),'','')+''
							else ISNULL(RTRIM(EepAddressLine1),'') end
		,Details = ''
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = ''
		,ConSystemid=''
		-- select eepAddressLine1
	FROM EmpComp (NOLOCK)
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
	--WHERE dbo.dsi_fn_SpecialCharCheck (EepAddressLine1) = 1
WHERE PATINDEX('%[^A-Z^a-z^0-9^ ^''^.^#]%', REPLACE(EepAddressLine1,'-','')) > 0  --Could not figure out how to exclude dashes so did a replace
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = eecpaygroup
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00010'
		,ErrorMessage = 'Address 2 Field contains punctuation/special characters'
		,ErrorKeyLabel = 'Address Line 2'
		,ErrorKeyFieldName= 'eepAddressLine2'
		,ErrorKeyValue = case when eepAddressLine2 like '%,%' AND eepAddressLine2 not like '%%' then ''+ISNULL(RTRIM(EepAddressLine2),'')+''
								when eepAddressLine2 like '%,%' AND eepAddressLine2 like '%%' then ''+REPLACE(ISNULL(RTRIM(EepAddressLine2),''),'','')+''
							else ISNULL(RTRIM(EepAddressLine2),'') end
		,Details = ''
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = ''
		,ConSystemid=''
	FROM EmpComp (NOLOCK)
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
	--WHERE dbo.dsi_fn_SpecialCharCheck (EepAddressLine2) = 1
WHERE PATINDEX('%[^A-Z^a-z^0-9^ ^''^.^#]%', REPLACE(EepAddressLine2,'-','')) > 0  
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = eecpaygroup
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00011'
		,ErrorMessage = 'Invalid or Missing Email Address'
		,ErrorKeyLabel = 'E-Mail Address'
		,ErrorKeyFieldName= 'EepAddressEmail'
		,ErrorKeyValue = ISNULL(RTRIM(EepAddressEmail),'')
		,Details = ''
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = ''
		,ConSystemid=''
	FROM EmpComp (NOLOCK)
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
WHERE (isnull(EepAddressEmail,'') = '' or eepAddressEmail not like '%@%')
  AND eecEmplStatus <> 'T'
  AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = eecpaygroup
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00012'
		,ErrorMessage = 'Invalid Gender'
		,ErrorKeyLabel = 'Gender'
		,ErrorKeyFieldName= 'EepGender'
		,ErrorKeyValue = ISNULL(RTRIM(EepGender),'')
		,Details = ''
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = ''
		,ConSystemid=''
	FROM EmpComp (NOLOCK)
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
WHERE ISNULL(EepGender,'') NOT IN ('M','F')
  AND not exists (select 'X' from employeegender where Gendercode = ISNULL(EepGender,''))
  AND eepdatetimecreated >= @createdate


INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00013'
		,ErrorMessage = 'Invalid Employee SSN'
		,ErrorKeyLabel = 'SSN'
		,ErrorKeyFieldName= 'EepSSN'
		,ErrorKeyValue = ISNULL(RTRIM(EepSSN),'NULL')
		,Details = ''
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = ''
		,ConSystemid=''
	FROM EmpComp (NOLOCK)
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
WHERE ((ISNULL(EepSSN,'') = '') -- SSN is Blank
		OR (ISNULL(LEFT(EepSSN,3),'') IN ('000','666')) -- First 3 Characters Start with '000','666'
		OR (ISNULL(LEFT(EepSSN,1),'') IN ('9')) -- First Character Start with '9'
	)
	and @Country = 'USA'
	AND eepdatetimecreated >= @createdate
  --AND eecEmplStatus <> 'T'

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = eecpaygroup
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00014'
		,ErrorMessage = 'Invalid Date of OriginalHire: Less than or equal to Date of Birth'
		,ErrorKeyLabel = 'Date of Original Hire'
		,ErrorKeyFieldName= 'eecDateofOriginalHire'
		,ErrorKeyValue = case when eecDateofOriginalHire is null then 'NULL' else convert(char(10),eecDateofOriginalHire,101) end
		,Details = 'Date of Birth: ' + case when eepDateofBirth is null then 'NULL' else convert(char(10),eepDateofBirth,101) end
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid=''
FROM EmpComp (NOLOCK)
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
WHERE eecDateofOriginalHire < eepDateofBirth
AND eepdatetimecreated >= @createdate
  --AND eecEmplStatus <> 'T'

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = eecpaygroup
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00015'
		,ErrorMessage = 'Invalid Date of Last Hire, Less than Original Hire Date'
		,ErrorKeyLabel = 'Date of Last Hire'
		,ErrorKeyFieldName= 'eecDateofLastHire'
		,ErrorKeyValue = case when eecDateofLastHire is null then 'NULL' else convert(char(10),eecDateofLastHire,101) end
		,Details = 'Date of Original Hire: ' + case when eecDateofOriginalHire is null then 'NULL' else convert(char(10),eecDateofOriginalHire,101) end + ', Date of Last Hire: ' + case when eecDateofLastHire is null then 'NULL' else convert(char(10),eecDateofLastHire,101) end
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid=''
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
WHERE eecDateofLastHire < eecDateofOriginalHire
AND eepdatetimecreated >= @createdate
		--AND eecEmplStatus <> 'T'

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = eecpaygroup
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00016'
		,ErrorMessage = 'First Name too long, Maximum length is 20 for Payroll Employees'
		,ErrorKeyLabel = 'First Name'
		,ErrorKeyFieldName= 'EepNameFirst'
		,ErrorKeyValue = 'First Name: '+eepnamefirst+', Length='+rtrim(ltrim(convert(char(20),len(eepnamefirst))))
		,Details = ''
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = ''
		,ConSystemid=''

	FROM EmpComp (NOLOCK)
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID AND CmpCountryCode in ('USA','CAN')
WHERE Len(eepnamefirst) > 20
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = eecpaygroup
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00017'
		,ErrorMessage = 'Last Name too long, Maximum length is 30 for Payroll Employees'
		,ErrorKeyLabel = 'Last Name'
		,ErrorKeyFieldName= 'EepNameLast'
		,ErrorKeyValue = 'First Name: '+eepnamelast+', Length='+rtrim(ltrim(convert(char(20),len(eepnamelast))))
		,Details = ''
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = ''
		,ConSystemid=''

FROM EmpComp (NOLOCK)
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID AND CmpCountryCode in ('USA','CAN')
WHERE Len(eepnamelast) > 30
AND eepdatetimecreated >= @createdate
	
INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = eecpaygroup
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00018'
		,ErrorMessage = 'Middle Name too long, Maximum length is 20 for Payroll Employees'
		,ErrorKeyLabel = 'Middle Name'
		,ErrorKeyFieldName= 'EepNameMiddle'
		,ErrorKeyValue = 'First Name: '+eepnamemiddle+', Length='+rtrim(ltrim(convert(char(20),len(eepnamemiddle))))
		,Details = ''
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = ''
		,ConSystemid=''
FROM EmpComp (NOLOCK)
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID AND CmpCountryCode in ('USA','CAN')
WHERE Len(eepnamemiddle) > 20
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = eecpaygroup
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00019'
		,ErrorMessage = 'Employee "suppress SSN" option does not match company level setup'
		,ErrorKeyLabel = 'Suppress SSN'
		,ErrorKeyFieldName= 'EepSuppressSSN'
		,ErrorKeyValue = EepSuppressSSN
		,Details = ''
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid=''
FROM EmpPers (NOLOCK)
JOIN EmpComp (NOLOCK) ON EecEEID = EepEEID
JOIN Company (NOLOCK) ON CmpCoID = EecCOID
WHERE EepSuppressSSN <> CmpSuppressSSN 
AND @Country = 'USA'
AND eepdatetimecreated >= @createdate
ORDER BY CmpCompanyName, EepNameLast

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = eecpaygroup
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00021'
		,ErrorMessage = 'Employee has addresses or phone numbers attached to a country that is not set up for this customer'
		,ErrorKeyLabel = 'Country'
		,ErrorKeyFieldName= 'EepAddressCountry and/or EepPhoneHomeCountry'
		,ErrorKeyValue = 'EepAddressCountry: ' +  EepAddressCountry + ' EepPhoneHomeCountry: ' + EepPhoneHomeCountry
		,Details = ''
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid=''
FROM EmpPers (NOLOCK)
JOIN EmpComp (NOLOCK) ON EecEEID = EepEEID
JOIN Company (NOLOCK) ON CmpCoID = EecCOID
WHERE (EepAddressCountry NOT IN(SELECT CodCode FROM Codes (NOLOCK) WHERE CodTable = 'COUNTRY') OR
	   EepPhoneHomeCountry NOT IN(SELECT CodCode FROM Codes (NOLOCK) WHERE CodTable = 'COUNTRY'))
  AND NULLIF(LTRIM(RTRIM(EepPhoneHomeNumber)),'') IS NOT NULL
  AND NULLIF(LTRIM(RTRIM(EepAddressCountry)),'') IS NOT NULL
  AND eepdatetimecreated >= @createdate
ORDER BY CmpCompanyName, EepNameLast

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = eecpaygroup
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00022'
		,ErrorMessage = 'Employee pay rate is zero'
		,ErrorKeyLabel = 'Annual Salary'
		,ErrorKeyFieldName= 'EecAnnSalary'
		,ErrorKeyValue = isnull(EecAnnSalary,'') 
		,Details = 'Scheduled Work Hrs ' + isnull(convert(varchar(10),cast(EecScheduledWorkHrs as money)),'0.00')+'' 
		,RoleToReview ='TC\SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
WHERE (isnull(EecAnnSalary,0) = 0
	   or isnull(EecHourlyPayRate,0) = 0
	   or isnull(EecPeriodPayRate,0) = 0
       or isnull(EecWeeklyPayRate,0) = 0)
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = eecpaygroup
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00223'
		,ErrorMessage = 'Invalid Org Level for employee'
		,ErrorKeyLabel = 'Org Level 1'
		,ErrorKeyFieldName= 'EecOrgLvl1'
		,ErrorKeyValue = isnull(EecOrgLvl1,'') 
		,Details = ''
		,RoleToReview ='TC\SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM EmpPers (NOLOCK) 
JOIN EmpComp (NOLOCK) ON eecEEID = EepEEID 
JOIN Company  (NOLOCK) ON cmpcoid = eeccoid
WHERE (EecOrgLvl1 NOT IN(SELECT OrgCode FROM OrgLevel (NOLOCK) WHERE OrgLvl = '1') AND NULLIF(LTRIM(RTRIM(EecOrgLvl1)),'') IS NOT NULL)
and eecdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = eecpaygroup
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='02223'
		,ErrorMessage = 'Invalid Org Level for employee'
		,ErrorKeyLabel = 'Org Level 2'
		,ErrorKeyFieldName= 'EecOrgLvl2'
		,ErrorKeyValue = isnull(EecOrgLvl2,'') 
		,Details = ''
		,RoleToReview ='TC\SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM EmpPers (NOLOCK) 
JOIN EmpComp (NOLOCK) ON eecEEID = EepEEID 
JOIN Company  (NOLOCK) ON cmpcoid = eeccoid
WHERE (EecOrgLvl2 NOT IN(SELECT OrgCode FROM OrgLevel (NOLOCK) WHERE OrgLvl = '2') AND NULLIF(LTRIM(RTRIM(EecOrgLvl2)),'') IS NOT NULL)
and eecdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = eecpaygroup
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='03223'
		,ErrorMessage = 'Invalid Org Level for employee'
		,ErrorKeyLabel = 'Org Level 3'
		,ErrorKeyFieldName= 'EecOrgLvl3'
		,ErrorKeyValue = isnull(EecOrgLvl3,'') 
		,Details = ''
		,RoleToReview ='TC\SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM EmpPers (NOLOCK) 
JOIN EmpComp (NOLOCK) ON eecEEID = EepEEID 
JOIN Company  (NOLOCK) ON cmpcoid = eeccoid
WHERE (EecOrgLvl3 NOT IN(SELECT OrgCode FROM OrgLevel (NOLOCK) WHERE OrgLvl = '3') AND NULLIF(LTRIM(RTRIM(EecOrgLvl3)),'') IS NOT NULL)
and eecdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = eecpaygroup
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='04223'
		,ErrorMessage = 'Invalid Org Level for employee'
		,ErrorKeyLabel = 'Org Level 4'
		,ErrorKeyFieldName= 'EecOrgLvl4'
		,ErrorKeyValue = isnull(EecOrgLvl4,'') 
		,Details = ''
		,RoleToReview ='TC\SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM EmpPers (NOLOCK) 
JOIN EmpComp (NOLOCK) ON eecEEID = EepEEID 
JOIN Company  (NOLOCK) ON cmpcoid = eeccoid
WHERE (EecOrgLvl4 NOT IN(SELECT OrgCode FROM OrgLevel (NOLOCK) WHERE OrgLvl = '4') AND NULLIF(LTRIM(RTRIM(EecOrgLvl4)),'') IS NOT NULL)
and eecdatetimecreated >= @createdate


INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = eecpaygroup
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00023'
		,ErrorMessage = 'Invalid Org Level in Job history'
		,ErrorKeyLabel = 'Org Level 1'
		,ErrorKeyFieldName= 'EjhOrgLvl1'
		,ErrorKeyValue = isnull(EjhOrgLvl1,'') 
		,Details = ''
		,RoleToReview ='TC\SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM EmpHJob (NOLOCK)
JOIN EmpPers (NOLOCK) ON eepEEID = EjhEEID AND eepHomeCoID = EjhCoID 
JOIN EmpComp (NOLOCK) ON eecEEID = EjhEEID AND eecCoID = EjhCoID
JOIN Company  (NOLOCK) ON cmpcoid = eeccoid
WHERE (EjhOrgLvl1 NOT IN(SELECT OrgCode FROM OrgLevel (NOLOCK) WHERE OrgLvl = '1') AND NULLIF(LTRIM(RTRIM(EjhOrgLvl1)),'') IS NOT NULL)
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = eecpaygroup
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00024'
		,ErrorMessage = 'Invalid Org Level in Job history'
		,ErrorKeyLabel = 'Org Level 2'
		,ErrorKeyFieldName= 'EjhOrgLvl2'
		,ErrorKeyValue = isnull(EjhOrgLvl2,'') 
		,Details = ''
		,RoleToReview ='TC\SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM EmpHJob (NOLOCK)
JOIN EmpPers (NOLOCK) ON eepEEID = EjhEEID AND eepHomeCoID = EjhCoID 
JOIN EmpComp (NOLOCK) ON eecEEID = EjhEEID AND eecCoID = EjhCoID
JOIN Company (NOLOCK) ON cmpcoid = eeccoid
WHERE (EjhOrgLvl2 NOT IN(SELECT OrgCode FROM OrgLevel (NOLOCK) WHERE OrgLvl = '2') AND NULLIF(LTRIM(RTRIM(EjhOrgLvl2)),'') IS NOT NULL) 
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = eecpaygroup
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00025'
		,ErrorMessage = 'Invalid Org Level in Job history'
		,ErrorKeyLabel = 'Org Level 3'
		,ErrorKeyFieldName= 'EjhOrgLvl3'
		,ErrorKeyValue = isnull(EjhOrgLvl3,'') 
		,Details = ''
		,RoleToReview ='TC\SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM EmpHJob (NOLOCK)
JOIN EmpPers (NOLOCK) ON eepEEID = EjhEEID AND eepHomeCoID = EjhCoID 
JOIN EmpComp (NOLOCK) ON eecEEID = EjhEEID AND eecCoID = EjhCoID
JOIN Company (NOLOCK) ON cmpcoid = eeccoid
WHERE (EjhOrgLvl3 NOT IN(SELECT OrgCode FROM OrgLevel (NOLOCK) WHERE OrgLvl = '3') AND NULLIF(LTRIM(RTRIM(EjhOrgLvl3)),'') IS NOT NULL) 
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = eecpaygroup
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00026'
		,ErrorMessage = 'Invalid Org Level in Job history'
		,ErrorKeyLabel = 'Org Level 4'
		,ErrorKeyFieldName= 'EjhOrgLvl4'
		,ErrorKeyValue = isnull(EjhOrgLvl4,'') 
		,Details = ''
		,RoleToReview ='TC\SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM EmpHJob (NOLOCK)
JOIN EmpPers (NOLOCK) ON eepEEID = EjhEEID AND eepHomeCoID = EjhCoID
JOIN EmpComp (NOLOCK) ON eecEEID = EjhEEID AND eecCoID = EjhCoID
JOIN Company (NOLOCK) ON cmpcoid = eeccoid
WHERE (EjhOrgLvl4 NOT IN(SELECT OrgCode FROM OrgLevel (NOLOCK) WHERE OrgLvl = '4') AND NULLIF(LTRIM(RTRIM(EjhOrgLvl4)),'') IS NOT NULL)
 AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = eecpaygroup
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00027'
		,ErrorMessage = 'The following employees either have a stop date in their current status history record or their non-current status history record does not have a stop date.'
		,ErrorKeyLabel = 'Is Current & Status Stop Date'
		,ErrorKeyFieldName= 'EshIsCurrent & EshStatusStopDate'
		,ErrorKeyValue = isnull(EshIsCurrent,'') 
		,Details = 'Is Current: ' + isnull(EshIsCurrent,'') + ' Status Stop Date: ' + convert(char(10),EshStatusStopDate,101)
		,RoleToReview ='TC\SC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM EmpHStat (NOLOCK)
JOIN EmpPers (NOLOCK) ON eepEEID = EshEEID AND eepHomeCoID = EshCoID 
JOIN EmpComp (NOLOCK) ON eecEEID = EshEEID AND eecCoID = eshCoID
JOIN Company (NOLOCK) ON cmpcoid = eeccoid
WHERE ((EshIsCurrent = 'Y' AND EshStatusStopDate IS NOT NULL) OR
	  (EshIsCurrent = 'N' AND EshStatusStopDate IS NULL))
AND eepdatetimecreated >= @createdate
  
INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = eecpaygroup
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00029'
		,ErrorMessage = 'Employee has multiple jobs flagged as primary job'
		,ErrorKeyLabel = 'Job Code'
		,ErrorKeyFieldName= 'EejJobCode'
		,ErrorKeyValue = isnull(EejJobCode,'') 
		,Details = ''
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM EmpMJobs a (NOLOCK)
JOIN EmpPers (NOLOCK) ON eepEEID = EejEEID 
JOIN EmpComp (NOLOCK) ON eecEEID = EejEEID AND eecCoID = EejCoID
JOIN Company (NOLOCK) ON cmpcoid = eeccoid
WHERE EejIsPrimaryJob  = 'Y'
  AND EXISTS (SELECT 'X' FROM EmpMJobs b (NOLOCK) 
			WHERE a.eejcoid = b.eejcoid 
				  AND a.eejeeid = b.eejeeid 
				  AND a.eejjobcode <> b.eejjobcode
				  AND a.EejIsPrimaryJob = b.EejIsPrimaryJob)
  AND eepdatetimecreated >= @createdate
			    
INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = eecpaygroup
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00030'
		,ErrorMessage = 'Employee has hourly pay less than $7.25'
		,ErrorKeyLabel = 'Hourly Pay Rate'
		,ErrorKeyFieldName= 'EecHourlyPayRate'
		,ErrorKeyValue = isnull(EecHourlyPayRate,'') 
		,Details = 'Pay Group: ' + eecpaygroup
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM Empcomp (NOLOCK)
JOIN EmpPers (NOLOCK) ON eepEEID = EecEEID 
JOIN Company (NOLOCK) ON cmpcoid = eeccoid
WHERE EecEmplStatus <> 'T' 
AND EecHourlyPayRate > 0  AND EecHourlyPayRate < 7.25
AND @Country = 'USA'
AND eepdatetimecreated >= @createdate

 -- update message from: ErrorMessage = 'Employee not flagged as autopaid in a pay group where employees are often autopaid'
 -- to: ErrorMessage = 'Employee is Salaried but not flagged as Autopaid'"


INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = eecpaygroup
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00031'
		,ErrorMessage = 'Employee is Salaried but not flagged as Autopaid'
		,ErrorKeyLabel = 'Is auto paid Y/N'
		,ErrorKeyFieldName= 'EecIsAutoPaid'
		,ErrorKeyValue = isnull(EecIsAutoPaid,'') 
		,Details = 'Pay Group: ' + eecpaygroup + ', Hourly or Salaried = ' + EecSalaryOrHourly
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM Empcomp (NOLOCK)
JOIN EmpPers (NOLOCK) ON eepEEID = EecEEID 
JOIN Company (NOLOCK) ON cmpcoid = eeccoid
WHERE EecEmplStatus <> 'T' 
AND EecIsAutoPaid = 'N'  
AND EecSalaryOrHourly = 'S'
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = eecpaygroup
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00032'
		,ErrorMessage = 'Employee Pay Frequency is NULL or Invalid'
		,ErrorKeyLabel = 'Pay Period'
		,ErrorKeyFieldName= 'EecPayperiod'
		,ErrorKeyValue = isnull(eecpayperiod,'') 
		,Details = 'Pay Group: ' + isnull(eecpaygroup,'')
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM Empcomp (NOLOCK)
JOIN EmpPers (NOLOCK) ON eepEEID = EecEEID 
JOIN Company (NOLOCK) ON cmpcoid = eeccoid
WHERE ((eecpayperiod not in (select codcode FROM codes (NOLOCK) WHERE codtable = 'PAYPERIODFREQ'))
   or (eecpayperiod is NULL))
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = eecpaygroup
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00033'
		,ErrorMessage = 'Employee First Name contains double quotes.'
		,ErrorKeyLabel = 'First Name'
		,ErrorKeyFieldName= 'EepNameFirst'
		,ErrorKeyValue = isnull(eepnamefirst,'') 
		,Details = ''
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM Empcomp (NOLOCK)
JOIN EmpPers (NOLOCK) ON eepEEID = EecEEID 
JOIN Company (NOLOCK) ON cmpcoid = eeccoid
WHERE (eepnamefirst like '%""%') 
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = eecpaygroup
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00034'
		,ErrorMessage = 'Employee Last Name contains double quotes.'
		,ErrorKeyLabel = 'Last Name'
		,ErrorKeyFieldName= 'EepNameLast'
		,ErrorKeyValue = isnull(EepNameLast,'') 
		,Details = ''
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM Empcomp (NOLOCK)
JOIN EmpPers (NOLOCK) ON eepEEID = EecEEID 
JOIN Company (NOLOCK) ON cmpcoid = eeccoid
WHERE (eepnamelast like '%""%') 
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = eecpaygroup
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00035'
		,ErrorMessage = 'Employee Middle Name contains double quotes.'
		,ErrorKeyLabel = 'Middle Name'
		,ErrorKeyFieldName= 'eepnamemiddle'
		,ErrorKeyValue = isnull(eepnamemiddle,'') 
		,Details = ''
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM Empcomp (NOLOCK)
JOIN EmpPers (NOLOCK) ON eepEEID = EecEEID 
JOIN Company (NOLOCK) ON cmpcoid = eeccoid
WHERE (eepnamemiddle like '%""%')
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = eecpaygroup
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00036'
		,ErrorMessage = 'OtherRate fields should NOT have NULL values.'
		,ErrorKeyLabel = 'Other Rate 1'
		,ErrorKeyFieldName= 'EecOtherRate1'
		,ErrorKeyValue = isnull(EecOtherRate1,'') 
		,Details = ''
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM Empcomp (NOLOCK)
JOIN EmpPers (NOLOCK) ON eepEEID = EecEEID 
JOIN Company (NOLOCK) ON cmpcoid = eeccoid
WHERE (EecOtherRate1 is NULL) 
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = eecpaygroup
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00037'
		,ErrorMessage = 'OtherRate fields should NOT have NULL values.'
		,ErrorKeyLabel = 'Other Rate 2'
		,ErrorKeyFieldName= 'EecOtherRate2'
		,ErrorKeyValue = isnull(EecOtherRate2,'') 
		,Details = ''
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM Empcomp (NOLOCK)
JOIN EmpPers (NOLOCK) ON eepEEID = EecEEID 
JOIN Company (NOLOCK) ON cmpcoid = eeccoid
WHERE (EecOtherRate2 is NULL) 
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = eecpaygroup
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00038'
		,ErrorMessage = 'OtherRate fields should NOT have NULL values.'
		,ErrorKeyLabel = 'Other Rate 3'
		,ErrorKeyFieldName= 'EecOtherRate3'
		,ErrorKeyValue = isnull(EecOtherRate3,'') 
		,Details = ''
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM Empcomp (NOLOCK)
JOIN EmpPers (NOLOCK) ON eepEEID = EecEEID 
JOIN Company (NOLOCK) ON cmpcoid = eeccoid
WHERE (EecOtherRate3 is NULL)
AND eepdatetimecreated >= @createdate 

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = eecpaygroup
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00039'
		,ErrorMessage = 'OtherRate fields should NOT have NULL values.'
		,ErrorKeyLabel = 'Other Rate 4'
		,ErrorKeyFieldName= 'EecOtherRate4'
		,ErrorKeyValue = isnull(EecOtherRate4,'') 
		,Details = ''
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM Empcomp (NOLOCK)
JOIN EmpPers (NOLOCK) ON eepEEID = EecEEID 
JOIN Company (NOLOCK) ON cmpcoid = eeccoid
WHERE (EecOtherRate4 is NULL) 
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = isnull(CmpCompanyCode,'')
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00040'
		,ErrorMessage = 'There are records in EmpPers with no related record in EmpComp.'
		,ErrorKeyLabel = 'EEID'
		,ErrorKeyFieldName= 'EepEeid'
		,ErrorKeyValue = isnull(EepEeid,'') 
		,Details = ''
		,RoleToReview ='TC'
		,EEID = EePEEID
		,COID = isnull(EecCOID,'')
		,ConSystemid = ''
FROM EmpPers (NOLOCK)
LEFT JOIN EmpComp (NOLOCK) ON eepEEID = EecEEID 
LEFT JOIN Company (NOLOCK) ON cmpcoid = eeccoid
WHERE eeccoid is null
  AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = isnull(CmpCompanyCode,'')
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00041'
		,ErrorMessage = 'There are records in EmpComp with no related record in EmpPers.'
		,ErrorKeyLabel = 'EEID'
		,ErrorKeyFieldName= 'EeCEeid'
		,ErrorKeyValue = isnull(EecEeid,'') 
		,Details = ''
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = isnull(EecCOID,'')
		,ConSystemid = ''
FROM Empcomp (NOLOCK)
LEFT JOIN EmpPers (NOLOCK) ON eepEEID = EecEEID
JOIN Company (NOLOCK) ON cmpcoid = eeccoid
WHERE eepeeid is null
AND eepdatetimecreated >= @createdate


INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00042'
		,ErrorMessage = 'Employee has job history records with NULL values in the pay rate fields'
		,ErrorKeyLabel = 'Annual Salary'
		,ErrorKeyFieldName= 'EjhAnnSalary'
		,ErrorKeyValue = EjhAnnSalary 
		,Details = 'Job Effective Date: ' + convert(char(10),ejhjobeffdate,101) + ', Job Reason: ' + ejhreason
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM EmpHJob (NOLOCK)
JOIN EmpPers (NOLOCK) ON eepEEID = EjhEEID 
JOIN EmpComp (NOLOCK) ON eecEEID = EjhEEID AND eecCoID = EjhCoID
JOIN Company (NOLOCK) ON cmpcoid = eeccoid
WHERE EjhAnnSalary is null
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00043'
		,ErrorMessage = 'Employee has job history records with NULL values in the pay rate fields'
		,ErrorKeyLabel = 'Weekly Pay Rate'
		,ErrorKeyFieldName= 'EjhWeeklyPayRate'
		,ErrorKeyValue = EjhWeeklyPayRate 
		,Details = 'Job Effective Date: ' + convert(char(10),ejhjobeffdate,101) + ', Job Reason: ' + ejhreason
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM EmpHJob (NOLOCK)
JOIN EmpPers (NOLOCK) ON eepEEID = EjhEEID 
JOIN EmpComp (NOLOCK) ON eecEEID = EjhEEID AND eecCoID = EjhCoID
JOIN Company  (NOLOCK) ON cmpcoid = eeccoid
WHERE EjhWeeklyPayRate is null
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00045'
		,ErrorMessage = 'Employee has job history records with NULL values in the pay rate fields'
		,ErrorKeyLabel = 'Hourly Pay Rate'
		,ErrorKeyFieldName= 'EjhHourlyPayRate'
		,ErrorKeyValue = EjhHourlyPayRate 
		,Details = 'Job Effective Date: ' + convert(char(10),ejhjobeffdate,101) + ', Job Reason: ' + ejhreason
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM EmpHJob (NOLOCK)
JOIN EmpPers (NOLOCK) ON eepEEID = EjhEEID 
JOIN EmpComp (NOLOCK) ON eecEEID = EjhEEID AND eecCoID = EjhCoID
JOIN Company (NOLOCK) ON cmpcoid = eeccoid
WHERE EjhHourlyPayRate is null
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00046'
		,ErrorMessage = 'Employee has job history records with NULL values in the pay rate fields'
		,ErrorKeyLabel = 'Period Pay Rate'
		,ErrorKeyFieldName= 'EjhPeriodPayRate'
		,ErrorKeyValue = EjhPeriodPayRate 
		,Details = 'Job Effective Date: ' + convert(char(10),ejhjobeffdate,101) + ', Job Reason: ' + ejhreason
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM EmpHJob (NOLOCK)
JOIN EmpPers (NOLOCK) ON eepEEID = EjhEEID 
JOIN EmpComp (NOLOCK) ON eecEEID = EjhEEID AND eecCoID = EjhCoID
JOIN Company (NOLOCK) ON cmpcoid = eeccoid
WHERE EjhPeriodPayRate is null
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00047'
		,ErrorMessage = 'Employee has job history records with NULL values in the pay rate fields'
		,ErrorKeyLabel = 'Piece Pay Rate'
		,ErrorKeyFieldName= 'EjhPiecePayRate'
		,ErrorKeyValue = EjhPiecePayRate 
		,Details = 'Job Effective Date: ' + convert(char(10),ejhjobeffdate,101) + ', Job Reason: ' + ejhreason
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM EmpHJob (NOLOCK)
JOIN EmpPers (NOLOCK) ON eepEEID = EjhEEID 
JOIN EmpComp (NOLOCK) ON eecEEID = EjhEEID AND eecCoID = EjhCoID
JOIN Company (NOLOCK) ON cmpcoid = eeccoid
WHERE EjhPiecePayRate is null
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00048'
		,ErrorMessage = 'Employee has job history records with NULL value in pay percent-change'
		,ErrorKeyLabel = 'Percent Change'
		,ErrorKeyFieldName= 'EjhPctChange'
		,ErrorKeyValue = EjhPctChange 
		,Details = 'Job Effective Date: ' + convert(char(10),ejhjobeffdate,101) + ', Job Reason: ' + ejhreason
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM EmpHJob (NOLOCK)
JOIN EmpPers (NOLOCK) ON eepEEID = EjhEEID 
JOIN EmpComp (NOLOCK) ON eecEEID = EjhEEID AND eecCoID = EjhCoID
JOIN Company (NOLOCK) ON cmpcoid = eeccoid
WHERE EjhPctChange is null
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00049'
		,ErrorMessage = 'Active employee has termination date.'
		,ErrorKeyLabel = 'Date Of Termination'
		,ErrorKeyFieldName= 'EecDateOfTermination'
		,ErrorKeyValue = isnull(EecDateOfTermination,'') 
		,Details = ''
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM Empcomp (NOLOCK)
JOIN EmpPers (NOLOCK) ON eepEEID = EecEEID 
JOIN Company (NOLOCK) ON cmpcoid = eeccoid
WHERE eecemplstatus <> 'T'
AND eecdateoftermination is not null
AND eepdatetimecreated >= @createdate



INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
	SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00149'
		,ErrorMessage = 'Terminated employee has termination invalid reason or type.'
		,ErrorKeyLabel = 'Term Reason'
		,ErrorKeyFieldName= 'EecTermReason'
		,ErrorKeyValue = 'Reason: ' +isnull(EecTermReason,'') +', Type: '+ isnull(eectermtype, '')
		,Details = ''
		,RoleToReview ='TC\SC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM Empcomp (NOLOCK)
  JOIN EmpPers (NOLOCK) ON eepEEID = EecEEID 
  JOIN Company (NOLOCK) ON cmpcoid = eeccoid
left join TrmReasn  (NOLOCK) on TchCode = EecTermReason and TchType = EecTermType 
where eecemplstatus = 'T'
  and tchcode is null
  AND eepdatetimecreated >= @createdate


INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00050'
		,ErrorMessage = 'Employee allocations do not add to 1.0 (100%)'
		,ErrorKeyLabel = 'Pct To Alloc'
		,ErrorKeyFieldName= 'EeaPctToAlloc'
		,ErrorKeyValue = null
		,Details = 'Total Allocation: ' + convert( varchar(10), (select SUM(EeaPctToAlloc) FROM EmpAlloc WHERE eeacoid = eecCoid AND eeaeeid = eeceeid))
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM Empcomp (NOLOCK)
JOIN EmpPers (NOLOCK) ON eepEEID = EecEEID 
JOIN Company (NOLOCK) ON cmpcoid = eeccoid
WHERE (select SUM(EeaPctToAlloc) FROM EmpAlloc WHERE eeacoid = eecCoid AND eeaeeid = eeceeid) <> 1
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00051'
		,ErrorMessage = 'Employee home allocations Org Level 1 does not match empcomp'
		,ErrorKeyLabel = 'Org Level 1'
		,ErrorKeyFieldName= 'EeaOrglvl1'
		,ErrorKeyValue = EeaOrglvl1
		,Details = 'Empcomp orglvl1: ' + isnull(eeaorglvl1,'')
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM Empcomp (NOLOCK)
JOIN EmpAlloc (NOLOCK) on eeacoid = eecCoid AND eeaeeid = eeceeid AND EeaIsHome = 'Y'
JOIN EmpPers (NOLOCK) ON eepEEID = EecEEID 
JOIN Company (NOLOCK) ON cmpcoid = eeccoid
WHERE isnull(eecorglvl1,'') <> isnull(eeaorglvl1,'')
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00052'
		,ErrorMessage = 'Employee home allocations Org Level 2 does not match empcomp'
		,ErrorKeyLabel = 'Org Level 2'
		,ErrorKeyFieldName= 'EeaOrglvl2'
		,ErrorKeyValue = EeaOrglvl2
		,Details = 'Empcomp orglvl2: ' + isnull(eeaorglvl2,'')
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM Empcomp (NOLOCK)
JOIN EmpAlloc (NOLOCK) on eeacoid = eecCoid AND eeaeeid = eeceeid AND EeaIsHome = 'Y'
JOIN EmpPers (NOLOCK) ON eepEEID = EecEEID
JOIN Company (NOLOCK) ON cmpcoid = eeccoid
WHERE isnull(eecorglvl2,'') <> isnull(eeaorglvl2,'')
 AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00053'
		,ErrorMessage = 'Employee home allocations Org Level 3 does not match empcomp'
		,ErrorKeyLabel = 'Org Level 3'
		,ErrorKeyFieldName= 'EeaOrglvl3'
		,ErrorKeyValue = EeaOrglvl3
		,Details = 'Empcomp orglvl3: ' + isnull(eeaorglvl3,'')
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM Empcomp (NOLOCK)
JOIN EmpAlloc (NOLOCK) on eeacoid = eecCoid AND eeaeeid = eeceeid AND EeaIsHome = 'Y'
JOIN EmpPers (NOLOCK) ON eepEEID = EecEEID 
JOIN Company (NOLOCK) ON cmpcoid = eeccoid
WHERE isnull(eecorglvl3,'') <> isnull(eeaorglvl3,'')
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00054'
		,ErrorMessage = 'Employee home allocations Org Level 4 does not match empcomp'
		,ErrorKeyLabel = 'Org Level 4'
		,ErrorKeyFieldName= 'EeaOrglvl4'
		,ErrorKeyValue = EeaOrglvl4
		,Details = 'Empcomp orglvl4: ' + isnull(eeaorglvl4,'')
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM Empcomp (NOLOCK)
JOIN EmpAlloc (NOLOCK) on eeacoid = eecCoid AND eeaeeid = eeceeid AND EeaIsHome = 'Y'
JOIN EmpPers (NOLOCK) ON eepEEID = EecEEID 
JOIN Company (NOLOCK) ON cmpcoid = eeccoid
WHERE isnull(eecorglvl4,'') <> isnull(eeaorglvl4,'')
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00154'
		,ErrorMessage = 'Employee home allocations Loction does not match empcomp'
		,ErrorKeyLabel = 'Location'
		,ErrorKeyFieldName= 'Eealocation'
		,ErrorKeyValue = Eealocation
		,Details = 'Empcomp Location: ' + isnull(Eeclocation,'')
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM Empcomp (NOLOCK)
JOIN EmpAlloc (NOLOCK) on eeacoid = eecCoid AND eeaeeid = eeceeid AND EeaIsHome = 'Y'
JOIN EmpPers (NOLOCK) ON eepEEID = EecEEID 
JOIN Company (NOLOCK) ON cmpcoid = eeccoid
WHERE isnull(Eealocation,'') <> isnull(Eeclocation,'')
  AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00155'
		,ErrorMessage = 'Employee home allocations Jobcode does not match empcomp'
		,ErrorKeyLabel = 'Jobcode'
		,ErrorKeyFieldName= 'EeaJobcode'
		,ErrorKeyValue = EeaJobcode
		,Details = 'Empcomp Location: ' + isnull(EecJobcode,'')
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM Empcomp (NOLOCK)
JOIN EmpAlloc (NOLOCK) on eeacoid = eecCoid AND eeaeeid = eeceeid AND EeaIsHome = 'Y'
JOIN EmpPers (NOLOCK) ON eepEEID = EecEEID 
JOIN Company (NOLOCK) ON cmpcoid = eeccoid
WHERE isnull(EeaJobcode,'') <> isnull(EecJobcode,'')
  AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00155'
		,ErrorMessage = 'Employee home allocations Paygroup does not match empcomp'
		,ErrorKeyLabel = 'Location'
		,ErrorKeyFieldName= 'EeaPaygroup'
		,ErrorKeyValue = EeaPaygroup
		,Details = 'Empcomp Location: ' + isnull(EecPaygroup,'')
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM Empcomp (NOLOCK)
JOIN EmpAlloc (NOLOCK) on eeacoid = eecCoid AND eeaeeid = eeceeid AND EeaIsHome = 'Y'
JOIN EmpPers (NOLOCK) ON eepEEID = EecEEID 
JOIN Company (NOLOCK) ON cmpcoid = eeccoid
WHERE isnull(EeaPaygroup,'') <> isnull(EecPaygroup,'')
  AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00055'
		,ErrorMessage = 'Employee address city is longer than 30 characters'
		,ErrorKeyLabel = 'Address City'
		,ErrorKeyFieldName= 'eepAddressCity'
		,ErrorKeyValue = eepAddressCity
		,Details = ''
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM Empcomp (NOLOCK)
JOIN EmpPers (NOLOCK) ON eepEEID = EecEEID 
JOIN Company (NOLOCK) ON cmpcoid = eeccoid AND cmpcountrycode in ('USA', 'CAN')
WHERE eecemplstatus <> 'T'
  AND LEN(eepAddressCity) > 30
  AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00056'
		,ErrorMessage = 'Employee address county is longer than 30 characters'
		,ErrorKeyLabel = 'Address County'
		,ErrorKeyFieldName= 'eepAddressCounty'
		,ErrorKeyValue = eepAddressCounty
		,Details = ''
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM Empcomp (NOLOCK)
JOIN EmpPers (NOLOCK) ON eepEEID = EecEEID 
JOIN Company (NOLOCK) ON cmpcoid = eeccoid AND cmpcountrycode in ('USA', 'CAN')
WHERE eecemplstatus <> 'T'
  AND LEN(eepAddressCounty) > 30
  AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00057'
		,ErrorMessage = 'Employee address line 1 is longer than 30 characters'
		,ErrorKeyLabel = 'Address Line 1'
		,ErrorKeyFieldName= 'eepAddressLine1'
		,ErrorKeyValue = eepAddressLine1
		,Details = ''
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM Empcomp (NOLOCK)
JOIN EmpPers (NOLOCK) ON eepEEID = EecEEID 
JOIN Company (NOLOCK) ON cmpcoid = eeccoid AND cmpcountrycode in ('USA', 'CAN')
WHERE eecemplstatus <> 'T'
  AND LEN(eepAddressLine1) > 30
  AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00058'
		,ErrorMessage = 'Employee address line 2 is longer than 30 characters'
		,ErrorKeyLabel = 'Address Line 2'
		,ErrorKeyFieldName= 'eepAddressLine2'
		,ErrorKeyValue = eepAddressLine1
		,Details = ''
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM Empcomp (NOLOCK)
JOIN EmpPers (NOLOCK) ON eepEEID = EecEEID 
JOIN Company (NOLOCK) ON cmpcoid = eeccoid AND cmpcountrycode in ('USA', 'CAN')
WHERE eecemplstatus <> 'T'
  AND LEN(eepAddressLine2) > 30
  AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00059'
		,ErrorMessage = 'Employee address state is longer than 2 characters'
		,ErrorKeyLabel = 'Address state'
		,ErrorKeyFieldName= 'EepAddressState'
		,ErrorKeyValue = EepAddressState
		,Details = ''
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM Empcomp (NOLOCK)
JOIN EmpPers (NOLOCK) ON eepEEID = EecEEID 
JOIN Company (NOLOCK) ON cmpcoid = eeccoid AND cmpcountrycode in ('USA', 'CAN')
WHERE eecemplstatus <> 'T'
  AND LEN(EepAddressState) > 2
  AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00060'
		,ErrorMessage = 'Employee address zip is longer than 9 characters'
		,ErrorKeyLabel = 'Address zip'
		,ErrorKeyFieldName= 'eepaddresszipcode'
		,ErrorKeyValue = eepaddresszipcode
		,Details = ''
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM Empcomp (NOLOCK)
JOIN EmpPers (NOLOCK) ON eepEEID = EecEEID 
JOIN Company (NOLOCK) ON cmpcoid = eeccoid AND cmpcountrycode = 'USA'
WHERE eecemplstatus <> 'T'
  AND LEN(eepaddresszipcode) > 9
  AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00060'
		,ErrorMessage = 'Employee postal code is longer than 6 characters'
		,ErrorKeyLabel = 'Postal Code'
		,ErrorKeyFieldName= 'eepaddresszipcode'
		,ErrorKeyValue = eepaddresszipcode
		,Details = ''
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM Empcomp (NOLOCK)
JOIN EmpPers (NOLOCK) ON eepEEID = EecEEID 
JOIN Company (NOLOCK) ON cmpcoid = eeccoid AND cmpcountrycode = 'CAN'
WHERE eecemplstatus <> 'T'
  AND LEN(eepaddresszipcode) > 6
  AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00061'
		,ErrorMessage = 'Employee has two Emppers records.'
		,ErrorKeyLabel = 'Employee SSN'
		,ErrorKeyFieldName= 'eepSSN'
		,ErrorKeyValue = EepSSN
		,Details = ''
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid=''
FROM EmpPers E (NOLOCK)
JOIN EmpComp (NOLOCK) ON EepEEID = EecEEID
JOIN Company (NOLOCK) on eeccoid = cmpcoid AND cmpcountrycode = 'USA'
WHERE exists (select 'x' from Emppers E2 (NOLOCK) WHERE E.eepssn = E2.eepssn and E.eepeeid <> E2.eepeeid) 
  AND eepssn <> '999999999'
  AND  @Country = 'USA'
  AND eepdatetimecreated >= @createdate
order by E.eepssn, E.EepNameLast

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00161'
		,ErrorMessage = 'Employee has two Emppers records.'
		,ErrorKeyLabel = 'Employee einNationalID'
		,ErrorKeyFieldName= 'einNationalID'
		,ErrorKeyValue = einNationalID
		,Details = ''
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid=''
FROM EmpPers E (NOLOCK)
JOIN EmpComp (NOLOCK) ON EepEEID = EecEEID
Join Empintl T (NOLOCK) ON einEEID = EepEEID AND einCountryCode = 'CAN'  
JOIN Company (NOLOCK) on eeccoid = cmpcoid AND cmpcountrycode = 'CAN'
WHERE exists (select 'x' from Empintl T2 (NOLOCK) WHERE T.einNationalID = T2.einNationalID AND einCountryCode = 'CAN' and T.einEEID <> T2.einEEID) 
  AND eepssn <> '999999999'
  AND  @Country = 'CAN'
  AND eepdatetimecreated >= @createdate
order by E.eepssn, E.EepNameLast

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(ejhpaygroup, '')
		,RecordType = 'Employee'
		,EmpNo = ''
		,EmployeeName = ''
		,EmploymentStatus = ''
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00062'
		,ErrorMessage = 'Orphan EmphJob Record (TC to help remove)'
		,ErrorKeyLabel = 'Orphan EmphJob'
		,ErrorKeyFieldName= 'Ejheeid'
		,ErrorKeyValue = Ejheeid 
		,Details = 'Ejhcoid: ' + Ejhcoid + '  Ejheeid: ' + Ejheeid + '  Job Effective Date: ' + convert(char(10),ejhjobeffdate,101) + ', Job Reason: ' + ejhreason
		,RoleToReview ='TC'
		,EEID = EJhEEID
		,COID = EjhCOID
		,ConSystemid = ''
FROM EmpHJob (NOLOCK)
JOIN Company (NOLOCK) ON cmpcoid = ejhcoid
WHERE not exists (SELECT 'x' from Empcomp (NOLOCK) where Eeccoid = Ejhcoid and Eeceeid = Ejheeid)

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup =  '' 
		,RecordType = 'Employee'
		,EmpNo = ''
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = ''
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00063'
		,ErrorMessage = 'Orphan Emppers record (TC to help research and possibly remove)'
		,ErrorKeyLabel = 'Employee SSN'
		,ErrorKeyFieldName= 'eepSSN'
		,ErrorKeyValue = EepSSN
		,Details = ''
		,RoleToReview ='TC'
		,EEID = EepEEID
		,COID = EepHomeCOID
		,ConSystemid=''
FROM EmpPers E (NOLOCK)
JOIN Company (NOLOCK) on eephomecoid = cmpcoid
WHERE not exists (SELECT 'x' FROM Empcomp (NOLOCK) WHERE eepeeid = eeceeid)
  AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00064'
		,ErrorMessage = 'Home COID does not exist for company (TC to help update)'
		,ErrorKeyLabel = 'Employee SSN'
		,ErrorKeyFieldName= 'eepSSN'
		,ErrorKeyValue = EepSSN
		,Details = ''
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid=''
FROM EmpPers E (NOLOCK)
JOIN EmpComp (NOLOCK) ON EepEEID = EecEEID
JOIN Company (NOLOCK) on eeccoid = cmpcoid
WHERE not exists (select 'x' from Company (NOLOCK) where cmpcoid = eephomecoid) 
  AND eepdatetimecreated >= @createdate
order by E.eepssn, E.EepNameLast

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00065'
		,ErrorMessage = 'Home COID in EmpPers record does not match EmpComp active record.'
		,ErrorKeyLabel = 'Employee SSN'
		,ErrorKeyFieldName= 'eepSSN'
		,ErrorKeyValue = EepSSN
		,Details = ''
		,RoleToReview ='SC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid=''
FROM EmpPers E (NOLOCK)
JOIN EmpComp (NOLOCK) ON EepEEID = EecEEID and Eecemplstatus = 'A'
JOIN Company (NOLOCK) on eeccoid = cmpcoid
WHERE Eeccoid <> Eephomecoid
  AND eepdatetimecreated >= @createdate
order by E.eepssn, E.EepNameLast

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00066'
		,ErrorMessage = 'Missing EmpIntl Table for Global Employee'
		,ErrorKeyLabel = 'Employee Empno'
		,ErrorKeyFieldName= 'Eecempno'
		,ErrorKeyValue = EecEmpno
		,Details = ''
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid=''
FROM EmpPers E (NOLOCK)
JOIN EmpComp (NOLOCK) ON EepEEID = EecEEID and Eecemplstatus = 'A'
JOIN Company (NOLOCK) on eeccoid = cmpcoid
WHERE cmpcountrycode <> 'USA'
  AND not exists (Select 'x' FROM Empintl (NOLOCK) WHERE Eineeid = Eepeeid)
  AND eepdatetimecreated >= @createdate
order by E.eepssn, E.EepNameLast

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00067'
		,ErrorMessage = case when (eshiscurrent = 'Y' and eecemplstatus <> eshemplstatus) then 'EmpComp Status and Current Record In History do not match' 
							 else 'Employee Status history is Current with Stop Date or Not Current with no stop date' end
		,ErrorKeyLabel = 'Employee Empno'
		,ErrorKeyFieldName= 'Eecempno'
		,ErrorKeyValue = EecEmpno
		,Details = 'Emplouee Status(Empcomp): '+ eecemplstatus + '  Emplouee Status(EmpHStat): '+ eshemplstatus + '  Status Startdate: ' + convert(char(10),eshstatusstartdate,101) + '  Status Stopdate: ' + convert(char(10),eshstatusstopdate,101)
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid=''
FROM EmpPers E (NOLOCK)
JOIN EmpComp (NOLOCK) ON EepEEID = EecEEID and Eecemplstatus = 'A'
JOIN Company (NOLOCK) ON eeccoid = cmpcoid
JOIN EmpHStat (NOLOCK) ON eeceeid = esheeid and eeccoid = eshcoid
WHERE ((eshiscurrent = 'Y' AND eshstatusstopdate is not null)
        OR (eshiscurrent = 'N' and eshstatusstopdate is null)
        OR (eshiscurrent = 'Y' and eecemplstatus <> eshemplstatus))
  AND eepdatetimecreated >= @createdate
order by E.eepssn, E.EepNameLast

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00068'
		,ErrorMessage = 'EE with multiple direct deposits have incorrect setup (total % > 100%)'
		,ErrorKeyLabel = 'Employee Empno'
		,ErrorKeyFieldName= 'Eecempno'
		,ErrorKeyValue = EecEmpno
		,Details = 'Total Percent: ' + convert( varchar(10),round(sum(EddAmtOrPct)*100,2))+'%'
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid=''
FROM EmpPers E (NOLOCK)
JOIN EmpComp (NOLOCK) ON EepEEID = EecEEID and Eecemplstatus = 'A'
JOIN Company (NOLOCK) ON eeccoid = cmpcoid
JOIN EmpDirDp (NOLOCK) ON Eddcoid = Eeccoid and Eddeeid = Eeceeid AND eddaccountisinactive ='N' AND EddDepositRule = 'P' 
WHERE eepdatetimecreated >= @createdate
Group By CmpCompanyCode, eecpaygroup, EecEmpNo, EepNameLast, EepNameFirst, EecEmplStatus, EecEmpno, EecEEID, EecCOID
Having sum(EddAmtOrPct) > 1
order by E.EepNameLast

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00069'
		,ErrorMessage = 'Employee with multiple direct deposits has incorrect setup (mix of both percent and flat amount)'
		,ErrorKeyLabel = 'Employee Empno'
		,ErrorKeyFieldName= 'Eecempno'
		,ErrorKeyValue = EecEmpno
		,Details = ''
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid=''
FROM EmpPers E (NOLOCK)
JOIN EmpComp (NOLOCK) ON EepEEID = EecEEID and Eecemplstatus = 'A'
JOIN Company (NOLOCK) ON eeccoid = cmpcoid
JOIN EmpDirDp (NOLOCK) ON Eddcoid = Eeccoid and Eddeeid = Eeceeid AND eddaccountisinactive ='N' AND EddDepositRule = 'P' 
WHERE exists (Select 'x' FROM EmpDirDp (NOLOCK) WHERE Eddcoid = Eeccoid and Eddeeid = Eeceeid AND eddaccountisinactive ='N' AND EddDepositRule = 'D')
  AND eepdatetimecreated >= @createdate
order by E.eepssn, E.EepNameLast

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00070'
		,ErrorMessage = 'Please review EE setup. EE has multiple direct deposits, but % total is less than 100% and there is no available balance acct.'
		,ErrorKeyLabel = 'Employee Empno'
		,ErrorKeyFieldName= 'Eecempno'
		,ErrorKeyValue = EecEmpno
		,Details = 'Total Percent: ' + convert( varchar(10),round(sum(EddAmtOrPct)*100,2))+'%'
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid=''
FROM EmpPers E (NOLOCK)
JOIN EmpComp (NOLOCK) ON EepEEID = EecEEID and Eecemplstatus = 'A'
JOIN Company (NOLOCK) ON eeccoid = cmpcoid
JOIN EmpDirDp (NOLOCK) ON Eddcoid = Eeccoid and Eddeeid = Eeceeid AND eddaccountisinactive ='N' AND EddDepositRule = 'P' 
WHERE not exists (Select 'x' FROM EmpDirDp (NOLOCK) WHERE Eddcoid = Eeccoid and Eddeeid = Eeceeid AND eddaccountisinactive ='N' AND EddDepositRule = 'A')
  AND eepdatetimecreated >= @createdate
Group By CmpCompanyCode, eecpaygroup, EecEmpNo, EepNameLast, EepNameFirst, EecEmplStatus, EecEmpno, EecEEID, EecCOID
Having sum(EddAmtOrPct) < 1
order by E.EepNameLast

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00071'
		,ErrorMessage = 'Invalid Employee SIN'
		,ErrorKeyLabel = 'SIN'
		,ErrorKeyFieldName= 'einNationalID'
		,ErrorKeyValue = ISNULL(RTRIM(einNationalID),'NULL')
		,Details = ''
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = ''
		,ConSystemid=''
	FROM EmpComp (NOLOCK)
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
Join Empintl (NOLOCK) ON einEEID = EepEEID
WHERE ((ISNULL(einNationalID,'') = '') -- SSN is Blank
		OR (ISNULL(LEFT(einNationalID,3),'') IN ('666')) -- First 3 Characters Start with '000','666'
       )
  AND @Country = 'CAN'
  AND eepdatetimecreated >= @createdate  

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00072'
		,ErrorMessage = 'Temporary SIN missing expiry date.'
		,ErrorKeyLabel = 'SIN'
		,ErrorKeyFieldName= 'einNationalID'
		,ErrorKeyValue = ISNULL(RTRIM(einNationalID),'NULL')
		,Details = ''
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = ''
		,ConSystemid=''
	FROM EmpComp (NOLOCK)
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
Join Empintl (NOLOCK) ON einEEID = EepEEID
WHERE ISNULL(LEFT(einNationalID,1),'') IN ('9')
  AND EinNationalIdExpireDate is NULL
  AND @Country = 'CAN'
  AND eepdatetimecreated >= @createdate 

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00073'
		,ErrorMessage = 'SSN field is populated.  It should not contain the SIN number.'
		,ErrorKeyLabel = 'SIN'
		,ErrorKeyFieldName= 'einNationalID'
		,ErrorKeyValue = ISNULL(RTRIM(einNationalID),'NULL')
		,Details = 'SSN: '+EepSSN
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = ''
		,ConSystemid=''
	FROM EmpComp (NOLOCK)
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
Join Empintl (NOLOCK) ON einEEID = EepEEID
WHERE EepSSN = EinNationalId
  AND @Country = 'CAN'
  AND eepdatetimecreated >= @createdate  
			    
INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00074'
		,ErrorMessage = 'Employee has hourly pay less than $11.00'
		,ErrorKeyLabel = 'Hourly Pay Rate'
		,ErrorKeyFieldName= 'EecHourlyPayRate'
		,ErrorKeyValue = isnull(EecHourlyPayRate,'') 
		,Details = 'Pay Group: ' + eecpaygroup
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM Empcomp (NOLOCK)
JOIN EmpPers (NOLOCK) ON eepEEID = EecEEID 
JOIN Company (NOLOCK) ON cmpcoid = eeccoid AND CMPCOUNTRYCODE = 'CAN'
WHERE EecEmplStatus <> 'T' 
AND EecHourlyPayRate > 0  AND EecHourlyPayRate < 11.00
AND @Country = 'CAN'   
AND eepdatetimecreated >= @createdate


INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00075'
		,ErrorMessage = 'Employee is Hourly but flagged as Autopaid'
		,ErrorKeyLabel = 'Is auto paid Y/N'
		,ErrorKeyFieldName= 'EecIsAutoPaid'
		,ErrorKeyValue = isnull(EecIsAutoPaid,'') 
		,Details = 'Pay Group: ' + eecpaygroup + ', Hourly or Salaried = ' + EecSalaryOrHourly
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM Empcomp (NOLOCK)
JOIN EmpPers (NOLOCK) ON eepEEID = EecEEID 
JOIN Company (NOLOCK) ON cmpcoid = eeccoid
WHERE EecEmplStatus <> 'T' 
AND EecIsAutoPaid = 'Y'  
AND EecSalaryOrHourly = 'H'
AND eepdatetimecreated >= @createdate


INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00149'
		,ErrorMessage = 'Terminated employee has termination invalid reason or type.'
		,ErrorKeyLabel = 'Term Reason'
		,ErrorKeyFieldName= 'EecTermReason'
		,ErrorKeyValue = isnull(EecTermReason,'') 
		,Details = ''
		,RoleToReview ='TC\SQ\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
-- select *
FROM Empcomp (NOLOCK)
JOIN EmpPers (NOLOCK) ON eepEEID = EecEEID 
JOIN Company (NOLOCK) ON cmpcoid = eeccoid
WHERE eecemplstatus = 'T'
  AND not exists (select 'x' from [dbo].[TrmReasn] (NOLOCK) where TchCode = EecTermReason and TchType = EecTermType)
  AND eepdatetimecreated >= @createdate

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
print getdate()
RAISERROR ('Employee QA thru 00099', 0, 1) WITH NOWAIT
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
--Contacts/Dep/Ben Checks

-- Attached to a benefit as a Dependent but no SSN
INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Contacts'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = RTRIM(ConNameLast) + ', ' + RTRIM(ConNameFirst)
		,Severity = 'E'
		,ErrorNumber='00100'
		,ErrorMessage = 'Contact does not have a SSN, but is attached to benefits as a dependent'
		,ErrorKeyLabel = 'Contact SSN'
		,ErrorKeyFieldName= 'ConSSN'
		,ErrorKeyValue = isnull(conssn,'')
		,Details = 'Is a Dependent: ' + isnull(conisdependent,'N') + ', ConSSN: ' + isnull(conssn,'')
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = consystemid
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN Contacts (NOLOCK) ON eepEEID = ConEEID AND ConIsActive = 'Y'
WHERE ConSSN IS NULL
AND ConSystemID IN (SELECT DISTINCT DbnDepRecID FROM DepBPlan (NOLOCK)) 
AND @Country = 'USA'
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Contacts'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = isnull(RTRIM(ConNameLast), 'N/A') + ', ' + isnull(RTRIM(ConNameFirst), 'N/A')
		,Severity = 'W'  -- should this be a warning?
		,ErrorNumber='00101'
		,ErrorMessage = 'Contact does not have a SSN, but is attached to benefits as a beneficiary.'
		,ErrorKeyLabel = 'Contact SSN'
		,ErrorKeyFieldName= 'ConSSN'
		,ErrorKeyValue = isnull(conssn,'')
		,Details = 'Is a Beneficiary: ' + isnull(conisbeneficiary,'N') + ', ConSSN: ' + isnull(conssn,'')
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = consystemid
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN Contacts (NOLOCK) ON eepEEID = ConEEID AND ConIsActive = 'Y'
WHERE ConSSN IS NULL
AND ConSystemID IN (SELECT DISTINCT BfpConRecID FROM BnfBPlan (NOLOCK))
AND @Country = 'USA'
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Contacts'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = isnull(RTRIM(ConNameLast), 'N/A') + ', ' + isnull(RTRIM(ConNameFirst), 'N/A')
		,Severity = 'E'
		,ErrorNumber='00102'
		,ErrorMessage = 'Contact does not have a SSN, but is indicated as a Dependent'
		,ErrorKeyLabel = 'Contact SSN'
		,ErrorKeyFieldName= 'ConSSN'
		,ErrorKeyValue = isnull(conssn,'')
		,Details = 'Is a Dependent: ' + isnull(conisdependent,'N') + ', ConSSN: ' + isnull(conssn,'')
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = consystemid
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN Contacts (NOLOCK) ON eepEEID = ConEEID AND ConIsActive = 'Y' AND (ConIsDependent = 'Y')
WHERE ConSSN IS NULL
AND not (ConSystemID IN (SELECT DISTINCT DbnDepRecID FROM DepBPlan (NOLOCK))) --exclude the records reported in the previous query
AND @Country = 'USA'
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Contacts'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
	    ,DependentName = isnull(RTRIM(ConNameLast), 'N/A') + ', ' + isnull(RTRIM(ConNameFirst), 'N/A')
		,Severity = 'W'
		,ErrorNumber='00104'
		,ErrorMessage = 'Contact has the same SSN as an employee.'
		,ErrorKeyLabel = 'Contact SSN'
		,ErrorKeyFieldName= 'ConSSN'
		,ErrorKeyValue = isnull(conssn,'')
		,Details = 'Employee SSN: ' + eepssn+ ', ConSSN: ' + isnull(conssn,'')+'  Contact Name Last: '+ConNameLast + '  Contact Name First: '+ ConNameFirst
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = consystemid
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN Contacts (NOLOCK) ON eepEEID = ConEEID AND ConIsActive = 'Y'
WHERE ConSSN = EepSSN 
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Contacts'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = isnull(RTRIM(ConNameLast), 'N/A') + ', ' + isnull(RTRIM(ConNameFirst), 'N/A')
		,Severity = 'E'
		,ErrorNumber='00105'
		,ErrorMessage = 'Invalid Gender (Null or Z) for Dependent/Beneficiary'
		,ErrorKeyLabel = 'Contact Gender'
		,ErrorKeyFieldName= 'ConGender'
		,ErrorKeyValue = isnull(ConGender,'')
		,Details = 'Is a Dependent: ' + isnull(conisdependent,'N') + ', is a Beneficiary: ' + isnull(conisbeneficiary,'N') + ', Contact Gender: ' + ConGender
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = consystemid
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN Contacts (NOLOCK) ON eepEEID = ConEEID AND ConIsActive = 'Y' AND (ConIsDependent = 'Y')
WHERE not exists (select 'X' from employeegender (nolock) where Gendercode = ISNULL(conGender,''))
  AND not exists (select 'X' FROM codes (nolock) WHERE codtable = 'GENDER' AND isnull(conGender,'Z') = codcode)
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Contacts'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = isnull(RTRIM(ConNameLast), 'N/A') + ', ' + isnull(RTRIM(ConNameFirst), 'N/A')
		,Severity = 'E'
		,ErrorNumber='02105'
		,ErrorMessage = 'Invalid Relationship'
		,ErrorKeyLabel = 'Contact Relationship'
		,ErrorKeyFieldName= 'ConRelationship'
		,ErrorKeyValue = isnull(ConRelationship,'')
		,Details = 'Contact Relationship: ' + ConRelationship
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = consystemid
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN Contacts (NOLOCK) ON eepEEID = ConEEID AND ConIsActive = 'Y'
WHERE ConRelationship not in (select codcode FROM codes (NOLOCK) WHERE codtable = 'relation')
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Contacts'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = isnull(RTRIM(ConNameLast), 'N/A') + ', ' + isnull(RTRIM(ConNameFirst), 'N/A')
		,Severity = 'E'
		,ErrorNumber='00106'
		,ErrorMessage = 'Date of birth greater than current date'
		,ErrorKeyLabel = 'Contact Date of Birth'
		,ErrorKeyFieldName= 'ConDateofBirth'
		,ErrorKeyValue = isnull(convert(char(10),ConDateofBirth,110),'')
		,Details = 'Contact ConDateofBirth: ' + isnull(convert(char(10),ConDateofBirth,110),'')
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = consystemid
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN Contacts (NOLOCK) ON eepEEID = ConEEID AND ConIsActive = 'Y'
WHERE ConDateofBirth > Getdate()
  AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Contacts'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = isnull(RTRIM(ConNameLast), 'N/A') + ', ' + isnull(RTRIM(ConNameFirst), 'N/A')
		,Severity = 'W'
		,ErrorNumber='01107'
		,ErrorMessage = 'Child Date of birth before Employee Date of Birth'
		,ErrorKeyLabel = 'Contact Date of Birth'
		,ErrorKeyFieldName= 'ConDateofBirth'
		,ErrorKeyValue = isnull(convert(char(10),ConDateofBirth,110),'')
		,Details = 'Employee Birthdate: '  + isnull(convert(char(10),EEpdateofbirth,110),'') + ', Contact Birthdate: ' + isnull(convert(char(10),ConDateofBirth,110),'') + ', Relationship: ' + conrelationship + '-' + coddesc
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = consystemid
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN Contacts (NOLOCK) ON eepEEID = ConEEID AND ConIsActive = 'Y' 
LEFT outer JOIN Codes (NOLOCK) on codtable = 'Relation' AND codcode = conrelationship
WHERE ConDateofBirth < EepDateofBirth
  AND Conrelationship in ('son','chl','dau','stc','dch')
  AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Contacts'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = isnull(RTRIM(ConNameLast), 'N/A') + ', ' + isnull(RTRIM(ConNameFirst), 'N/A')
		,Severity = 'E'
		,ErrorNumber='02107'
		,ErrorMessage = 'Dependent is missing Birthdate'
		,ErrorKeyLabel = 'Contact Date of Birth'
		,ErrorKeyFieldName= 'ConDateofBirth'
		,ErrorKeyValue = isnull(convert(char(10),ConDateofBirth,110),'')
		,Details = 'Is a Dependent: ' + isnull(conisdependent,'N') + ', Contact Birthdate: ' + isnull(convert(char(10),ConDateofBirth,110),'') + ', Relationship: ' + conrelationship + '-' + coddesc
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = consystemid
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN Contacts (NOLOCK) ON eepEEID = ConEEID AND ConIsActive = 'Y' AND ConIsDependent = 'Y'
LEFT outer JOIN Codes (NOLOCK) on codtable = 'Relation' AND codcode = conrelationship
WHERE ConDateOfBirth is null 
  AND ((EXISTS (Select 'X' from DepBPlan (NOLOCK) where DbnEEID = Coneeid and DbnDepRecID = ConSystemID))
        OR
       (EXISTS (Select 'X' from BnfBPlan (NOLOCK) where bFPEEID = Coneeid and BfpConRecID = ConSystemID)))
  AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Contacts'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = isnull(RTRIM(ConNameLast), 'N/A') + ', ' + isnull(RTRIM(ConNameFirst), 'N/A')
		,Severity = 'E'
		,ErrorNumber='00107'
		,ErrorMessage = 'Contact Birthdate has a placeholder date of birth from activation (01/01/1900 or 01/01/1950)'
		,ErrorKeyLabel = 'Contact Date of Birth'
		,ErrorKeyFieldName= 'ConDateofBirth'
		,ErrorKeyValue = isnull(convert(char(10),ConDateofBirth,110),'')
		,Details = 'Contact Birthdate: ' + isnull(convert(char(10),ConDateofBirth,110),'') + ', Relationship: ' + conrelationship + '-' + coddesc
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = consystemid
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN Contacts (NOLOCK) ON eepEEID = ConEEID AND ConIsActive = 'Y' 
LEFT outer JOIN Codes (NOLOCK) on codtable = 'Relation' AND codcode = conrelationship
WHERE (ConDateofBirth='01-01-1950' or ConDateofBirth='01-01-1900' or ConDateofBirth is null)
  AND ((EXISTS (Select 'X' from DepBPlan (NOLOCK) where DbnEEID = Coneeid and DbnDepRecID = ConSystemID)))
       -- OR
       --(EXISTS (Select 'X' from BnfBPlan (NOLOCK) where bFPEEID = Coneeid and BfpConRecID = ConSystemID)))
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Contacts'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = isnull(RTRIM(ConNameLast), 'N/A') + ', ' + isnull(RTRIM(ConNameFirst), 'N/A')
		,Severity = 'E'
		,ErrorNumber='00108'
		,ErrorMessage = 'Contact Name Suffix Missing'
		,ErrorKeyLabel = 'Contact Name Suffix'
		,ErrorKeyFieldName= 'connamesuffix'
		,ErrorKeyValue = isnull(connamesuffix,'')
		,Details = 'Name Suffix: ' + isnull(connamesuffix,'')
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = consystemid
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN Contacts (NOLOCK) ON eepEEID = ConEEID
WHERE (connamesuffix = '' or connamesuffix = ' ' or connamesuffix is null)
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Contacts'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = isnull(RTRIM(ConNameLast), 'N/A') + ', ' + isnull(RTRIM(ConNameFirst), 'N/A')
		,Severity = 'E'
		,ErrorNumber='00109'
		,ErrorMessage = 'Contact Name Suffix value is not valid.'
		,ErrorKeyLabel = 'Contact Name Suffix'
		,ErrorKeyFieldName= 'connamesuffix'
		,ErrorKeyValue = isnull(connamesuffix,'')
		,Details = 'Name Suffix: ' + isnull(connamesuffix,'')
		,RoleToReview ='TC\SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = consystemid
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN Contacts (NOLOCK) ON eepEEID = ConEEID
WHERE isnull(connamesuffix,'') not in (select codcode FROM codes (NOLOCK) WHERE codtable = 'SUFFIX')
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Contacts'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = isnull(RTRIM(ConNameLast), 'N/A') + ', ' + isnull(RTRIM(ConNameFirst), 'N/A')
		,Severity = 'E'
		,ErrorNumber='00129'
		,ErrorMessage = 'Emergency Contacts without phone numbers'
		,ErrorKeyLabel = 'Contact Phone Numbers'
		,ErrorKeyFieldName= 'ConWorkNumber, ConPhoneHomeNumber, ConPhoneOtherNumber'
		,ErrorKeyValue = isnull(COALESCE(ConWorkNumber, ConPhoneHomeNumber, ConPhoneOtherNumber),'')
		,Details = 'Contact Work#: ' + isnull(ConWorkNumber,'') + ', Contact Home#: ' + isnull(ConPhoneHomeNumber,'') + ', Contact Other#: ' + isnull(ConPhoneOtherNumber,'') 
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = consystemid
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN Contacts (NOLOCK) ON eepEEID = ConEEID
WHERE ConIsEmergencyContact = 'Y' AND COALESCE(ConWorkNumber, ConPhoneHomeNumber, ConPhoneOtherNumber) IS NULL
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Contacts'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = isnull(RTRIM(ConNameLast), 'N/A') + ', ' + isnull(RTRIM(ConNameFirst), 'N/A')
		,Severity = 'E'
		,ErrorNumber='02109'  
		,ErrorMessage = 'Emergency Contacts phone numbers defaulted during Launch'
		,ErrorKeyLabel = 'Contact Phone Numbers'
		,ErrorKeyFieldName= 'ConWorkNumber, ConPhoneHomeNumber, ConPhoneOtherNumber'
		,ErrorKeyValue = isnull(COALESCE(ConWorkNumber, ConPhoneHomeNumber, ConPhoneOtherNumber),'')
		,Details = 'Contact Work#: ' + isnull(ConWorkNumber,'') + ', Contact Home#: ' + isnull(ConPhoneHomeNumber,'') + ', Contact Other#: ' + isnull(ConPhoneOtherNumber,'') 
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = consystemid
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN Contacts (NOLOCK) ON eepEEID = ConEEID
WHERE ConIsEmergencyContact = 'Y' 
	AND (ConWorkNumber in ('9999999999','5555555555') or ConPhoneHomeNumber in ('9999999999','5555555555') or ConPhoneOtherNumber in ('9999999999','5555555555'))
	AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Contacts'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = isnull(RTRIM(ConNameLast), 'N/A') + ', ' + isnull(RTRIM(ConNameFirst), 'N/A')
		,Severity = 'E'
		,ErrorNumber='00110'
		,ErrorMessage = 'Emergency Contacts missing phone number that matches the Preferred Phone Type'
		,ErrorKeyLabel = 'Contact Phone Preferred'
		,ErrorKeyFieldName= 'ConPhonePreferred'
		,ErrorKeyValue = isnull(ConPhonePreferred,'')
		,Details = 'Contact Phone Preferred: '+ConPhonePreferred+ case ConPhonePreferred
																	when 'W' then ', Contact Work#: ' + isnull(ConWorkNumber,'') 
																	when 'H' then ', Contact Home#: ' + isnull(ConPhoneHomeNumber,'') 
																	when 'O' then ', Contact Other#: ' + isnull(ConPhoneOtherNumber,'') 
																	end
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = consystemid
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN Contacts (NOLOCK) ON eepEEID = ConEEID
WHERE (ConIsEmergencyContact = 'Y') AND ((ConPhonePreferred = 'H' AND ConPhoneHomeNumber is null)
	or (ConPhonePreferred = 'O' AND ConPhoneOtherNumber is null) or (ConPhonePreferred = 'W' AND ConWorkNumber IS NULL))
   AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Beneficiary'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = isnull(RTRIM(ConNameLast), 'N/A') + ', ' + isnull(RTRIM(ConNameFirst), 'N/A')
		,Severity = 'E'
		,ErrorNumber='00111'
		,ErrorMessage = 'Beneficiaries with benefit codes that do not exist at the employee level'
		,ErrorKeyLabel = 'Beneficiary Benefit Code'
		,ErrorKeyFieldName= 'bfpDedCode'
		,ErrorKeyValue = isnull(bfpdedcode,'')
		,Details =  'Dedcode ' + isnull(bfpdedcode,'') + ''
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = consystemid
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN Contacts (NOLOCK) ON eepEEID = ConEEID
JOIN BnfBPlan (NOLOCK) on coneeid = bfpeeid AND consystemid = bfpconrecid
WHERE not exists (select 1 FROM empded (NOLOCK) WHERE bfpeeid = eedeeid AND bfpdedcode = eeddedcode)
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Dependent'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = isnull(RTRIM(ConNameLast), 'N/A') + ', ' + isnull(RTRIM(ConNameFirst), 'N/A')
		,Severity = 'E'
		,ErrorNumber='00112'
		,ErrorMessage = 'Dependent has Deduction Code that Employee does not have.'
		,ErrorKeyLabel = 'Dependent Benefit Code'
		,ErrorKeyFieldName= 'dbnDedCode'
		,ErrorKeyValue = isnull(dbnDedCode,'')
		,Details =  'Dedcode ' + isnull(dbnDedCode,'') + ''
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = consystemid
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN Contacts (NOLOCK) ON eepEEID = ConEEID
JOIN DepBPlan (NOLOCK) on coneeid = dbneeid AND consystemid = DbnDepRecID
WHERE not exists (select 1 FROM empded (NOLOCK) WHERE dbneeid = eedeeid AND dbndedcode = eeddedcode)
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Beneficiary'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = isnull(RTRIM(ConNameLast), 'N/A') + ', ' + isnull(RTRIM(ConNameFirst), 'N/A')
		,Severity = 'E'
		,ErrorNumber='00113'
		,ErrorMessage = 'Contact in BnfbPlan not flagged as Beneficiary in Contacts table'
		,ErrorKeyLabel = 'Contact is Beneficiary'
		,ErrorKeyFieldName= 'ConIsBeneficiary'
		,ErrorKeyValue = isnull(ConIsBeneficiary,'')
		,Details =  'Is Beneficiary ' + isnull(ConIsBeneficiary,'') + ''
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = consystemid
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN Contacts (NOLOCK) ON eepEEID = ConEEID
JOIN BnfBPlan (NOLOCK) on coneeid = bfpeeid AND consystemid = bfpconrecid AND bfpstatus = 'A'
WHERE conisbeneficiary <> 'Y'
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Dependent'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = isnull(RTRIM(ConNameLast), 'N/A') + ', ' + isnull(RTRIM(ConNameFirst), 'N/A')
		,Severity = 'E'
		,ErrorNumber='00114'
		,ErrorMessage = 'Contact in DepbPlan not flagged as a Dependent in the Contacts table'
		,ErrorKeyLabel = 'Contact is Dependent'
		,ErrorKeyFieldName= 'ConIsDependent'
		,ErrorKeyValue = isnull(ConIsDependent,'')
		,Details =  'Is Dependent ' + isnull(ConIsDependent,'') + ''
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = consystemid
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN Contacts (NOLOCK) ON eepEEID = ConEEID
JOIN DepBPlan (NOLOCK) on coneeid = dbneeid AND consystemid = DbnDepRecID AND dbnbenstatus = 'A'
WHERE ConIsDependent <> 'Y'
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Beneficiary'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''   -- isnull(RTRIM(ConNameLast), 'N/A') + ', ' + isnull(RTRIM(ConNameFirst), 'N/A')
		,Severity = 'E'
		,ErrorNumber='00115'
		,ErrorMessage = 'Sum of Beneficiary allocation > 100%'
		,ErrorKeyLabel = 'Beneficiary Allocation Percent'
		,ErrorKeyFieldName= 'bfppcttoalloc'
		,ErrorKeyValue = rtrim(isnull(convert(char(20),TotalAlloc),''))
		,Details =  'DedCode:' + isnull(bfpDedCode,'') + ', Beneficiary Type: '+bfpbeneficiarytype+', Total Percent Allocated: ' + rtrim(isnull(convert(char(20),TotalAlloc),''))
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN (select bfpeeid, bfpdedcode, bfpbeneficiarytype, sum(bfppcttoalloc) TotalAlloc 
		  FROM bnfbplan (NOLOCK)
		  group by bfpeeid, bfpdedcode, bfpbeneficiarytype 
		  having sum(bfppcttoalloc) > 100) as x on eepeeid = bfpeeid 
WHERE eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Contacts'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + rtrim(isnull(' ' + eesuf.coddesc, '')) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = isnull(RTRIM(ConNameLast), 'N/A') + rtrim(isnull(' ' + consuf.coddesc, '')) +  ', ' + isnull(RTRIM(ConNameFirst), 'N/A')
		,Severity = 'W'
		,ErrorNumber='00116'
		,ErrorMessage = 'Possible duplicate contact records.  Please review AND correct any duplicate records in the system.'
		,ErrorKeyLabel = 'Contact Duplicates'
		,ErrorKeyFieldName= 'ConNameFirst/ConNameLast'
		,ErrorKeyValue = RTRIM(ConNameLast) + rtrim(isnull(' ' + consuf.coddesc, '')) + ', ' + RTRIM(ConNameFirst) 
		,Details =  'Contact Name: '+RTRIM(ConNameLast) + rtrim(isnull(' ' + consuf.coddesc, '')) + ', ' + RTRIM(ConNameFirst) + ', Contact Date of Birth: '+ isnull(convert(varchar,condateofbirth,101),'') +', Relationship: ' + conrelationship + ' '
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = consystemid
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
LEFT outer JOIN codes eesuf (NOLOCK) on eesuf.codtable = 'suffix' AND eepnamesuffix =eesuf.codcode
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN Contacts (NOLOCK) ON eepEEID = ConEEID
LEFT outer JOIN codes consuf (NOLOCK) on consuf.codtable = 'suffix' AND connamesuffix = consuf.codcode
    JOIN (SELECT coneeid EEID, 
                    LEFT(Ltrim(Rtrim(connamelast)), 3)  Last3Name, 
                    LEFT(Ltrim(Rtrim(connamefirst)), 3) First3Name 
             FROM   contacts (NOLOCK) 
             GROUP  BY coneeid, 
                       LEFT(Ltrim(Rtrim(connamelast)), 3), 
                       LEFT(Ltrim(Rtrim(connamefirst)), 3) 
             HAVING Count(*) > 1) x 
         ON coneeid = eeid 
            AND LEFT(Ltrim(Rtrim(connamelast)), 3) = last3name 
            AND LEFT(Ltrim(Rtrim(connamefirst)), 3) = first3name 
WHERE eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Dependent'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = isnull(RTRIM(ConNameLast), 'N/A') + ', ' + isnull(RTRIM(ConNameFirst), 'N/A')
		,Severity = 'E'
		,ErrorNumber='00117'
		,ErrorMessage = 'Dependent Benefit is Active but the Employee Benefit is not'
		,ErrorKeyLabel = 'Dependent Benefit Status'
		,ErrorKeyFieldName= 'dbnBenStatus'
		,ErrorKeyValue = isnull(dbnBenStatus,'')
		,Details = 'Dedcode ' + isnull(dbndedcode,'') + ', Dependent Benefit Status: ' + isnull(dbnBenStatus,'') + ', EE Benefit Status : ' + isnull(eedbenstatus,'') + ', Dep Ben Stop Date: ' + isnull(convert(char(10),dbnbenstopDate,110),'') 
		,RoleToReview ='TC\SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = consystemid
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN Contacts (NOLOCK) ON eepEEID = ConEEID AND ConIsActive = 'Y' 
JOIN DepBPlan (NOLOCK) on  dbneeid = coneeid AND dbndeprecid = consystemid
JOIN EmpDed (NOLOCK) on dbndedcode = eeddedcode AND eedeeid = eeceeid AND eedcoid = eeccoid
WHERE eedbenstatus <> dbnbenstatus AND (DbnBenStatus = 'A')
 AND eecemplstatus <> 'T'
 AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Dependent'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = isnull(RTRIM(ConNameLast), 'N/A') + ', ' + isnull(RTRIM(ConNameFirst), 'N/A')
		,Severity = 'E'
		,ErrorNumber='00118'
		,ErrorMessage = 'Dependent Benefit is Active but the Dependent Benefit Stop Date is populated'
		,ErrorKeyLabel = 'Dependent Benefit Stop Date'
		,ErrorKeyFieldName= 'dbnBenStopdate'
		,ErrorKeyValue = isnull(convert(char(10),dbnBenStopdate,110),'')
		,Details = 'Dedcode ' + isnull(dbndedcode,'') + ', Dependent Benefit Status: ' + isnull(dbnBenStatus,'') + ', Stop Date : ' + isnull(convert(char(10),dbnBenStopdate,110),'') 
		,RoleToReview ='TC\SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = consystemid
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN Contacts (NOLOCK) ON eepEEID = ConEEID AND ConIsActive = 'Y' 
JOIN DepBPlan (NOLOCK) on  dbneeid = coneeid AND dbndeprecid = consystemid
JOIN EmpDed (NOLOCK) on dbndedcode = eeddedcode AND eedeeid = eeceeid AND eedcoid = eeccoid
WHERE dbnbenstatus = 'A' AND dbnbenstopdate is not null
	AND not (eedbenstatus <> dbnbenstatus AND (DbnBenStatus = 'A'))
	AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Dependent'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = isnull(RTRIM(ConNameLast), 'N/A') + ', ' + isnull(RTRIM(ConNameFirst), 'N/A')
		,Severity = 'E'
		,ErrorNumber='00119'
		,ErrorMessage = 'Dependent Benefit is not Active but the Stop Date is blank'
		,ErrorKeyLabel = 'Dependent Benefit Stop Date'
		,ErrorKeyFieldName= 'dbnBenStopdate'
		,ErrorKeyValue = isnull(convert(char(10),dbnBenStopdate,110),'')
		,Details = 'Dedcode ' + isnull(dbndedcode,'') + ', Dependent Benefit Status: ' + isnull(dbnBenStatus,'') + ', Stop Date : ' + isnull(convert(char(10),dbnBenStopdate,110),'') 
		,RoleToReview ='TC\SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = consystemid
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN Contacts (NOLOCK) ON eepEEID = ConEEID AND ConIsActive = 'Y' 
LEFT outer JOIN Codes (NOLOCK) on codtable = 'Relation' AND codcode = conrelationship
JOIN DepBPlan (NOLOCK) on  dbneeid = coneeid AND dbndeprecid = consystemid
JOIN EmpDed (NOLOCK) on dbndedcode = eeddedcode AND eedeeid = eeceeid AND eedcoid = eeccoid
WHERE dbnBENSTATUS IN('W','T','C') AND (dbnbenstopdate is null)
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Dependent'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = isnull(RTRIM(ConNameLast), 'N/A') + ', ' + isnull(RTRIM(ConNameFirst), 'N/A')
		,Severity = 'E'
		,ErrorNumber='00120'
		,ErrorMessage = 'Employee benefit that covers dependents but no dependent has the coverage'
		,ErrorKeyLabel = 'Employee Benefit Option'
		,ErrorKeyFieldName= 'EedBenOption'
		,ErrorKeyValue = isnull(EedBenOption,'')
		,Details = 'Dedcode ' + isnull(eeddedcode,'N') + ', Benefit Option: ' + isnull(EedBenOption,'') + ', Descr : ' + isnull(bnoDescription,'') 
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = consystemid
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN Contacts (NOLOCK) ON eepEEID = ConEEID AND ConIsActive = 'Y' 
JOIN EmpDed (NOLOCK) on eedeeid = eeceeid AND eedcoid = eeccoid
JOIN benopt (NOLOCK) on bnocode = eedbenoption
Join Dedcode on eeddedcode = Deddedcode
Join DedType on deddedtype = cdtdedtypecode and CdtUseDependent = 'Y'
WHERE bnoDepMax > 0
  and bnorecorddependents = '1'
--isnull(eedbenoption,'') not in ('EE','Z','WAIVE','')
--	AND bnoDescription not like '%EE%only%'
	AND eedbenstopdate is null
	AND not exists (select 1 FROM depbplan (NOLOCK)
				WHERE eedeeid = dbneeid
			  AND eeddedcode = dbndedcode
			  AND dbnbenstopdate is null)
    AND eepdatetimecreated >= @createdate
 

-- last
--SELECT CompanyCode = CmpCompanyCode
--      ,PayGroup = isnull(eecpaygroup, '')
--		,RecordType = 'Dependent'
--		,EmpNo = RTRIM(EecEmpNo)
--		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
--		,EmploymentStatus = EecEmplStatus
--		,DependentName = isnull(RTRIM(ConNameLast), 'N/A') + ', ' + isnull(RTRIM(ConNameFirst), 'N/A')
--		,Severity = 'E'
--		,ErrorNumber='00120'
--		,ErrorMessage = 'Employee benefit that covers dependents but no dependent has the coverage'
--		,ErrorKeyLabel = 'Employee Benefit Option'
--		,ErrorKeyFieldName= 'EedBenOption'
--		,ErrorKeyValue = isnull(EedBenOption,'')
--		,Details = 'Dedcode ' + isnull(eeddedcode,'N') + ', Benefit Option: ' + isnull(EedBenOption,'') + ', Descr : ' + isnull(bnoDescription,'') 
--		,RoleToReview ='SC\Customer'
--		,EEID = EecEEID
--		,COID = EecCOID
--		,ConSystemid = consystemid
--FROM EmpComp (NOLOCK) 
--JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
--JOIN Company (NOLOCK) ON CmpCOID = EecCOID
--JOIN Contacts (NOLOCK) ON eepEEID = ConEEID AND ConIsActive = 'Y' 
--JOIN EmpDed (NOLOCK) on eedeeid = eeceeid AND eedcoid = eeccoid
--JOIN benopt (NOLOCK) on bnocode = eedbenoption
--WHERE bnoDepMax > 0
--  and bnorecorddependents = '1'
----isnull(eedbenoption,'') not in ('EE','Z','WAIVE','')
----	AND bnoDescription not like '%EE%only%'
--	AND eedbenstopdate is null
--	AND not exists (select 1 FROM depbplan (NOLOCK)
--				WHERE eedeeid = dbneeid
--			  AND eeddedcode = dbndedcode
--			  AND dbnbenstopdate is null)
--AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Dependent'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = isnull(RTRIM(ConNameLast), 'N/A') + ', ' + isnull(RTRIM(ConNameFirst), 'N/A')
		,Severity = 'E'
		,ErrorNumber='00121'
		,ErrorMessage = 'Employee only benefit but a dependent has the coverage'
		,ErrorKeyLabel = 'Employee Benefit Option'
		,ErrorKeyFieldName= 'EedBenOption'
		,ErrorKeyValue = isnull(EedBenOption,'')
		,Details = 'Dedcode ' + isnull(dbndedcode,'') + ', Benefit Option: ' + isnull(EedBenOption,'') + ', Descr : ' + isnull(bnoDescription,'') 
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = consystemid
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN Contacts (NOLOCK) ON eepEEID = ConEEID AND ConIsActive = 'Y' 
JOIN DepBPlan (NOLOCK) on  dbneeid = coneeid AND dbndeprecid = consystemid AND dbnbenstopdate is null
JOIN EmpDed (NOLOCK) on dbndedcode = eeddedcode AND eedeeid = eeceeid AND eedcoid = eeccoid
JOIN benopt (NOLOCK) on bnocode = eedbenoption 
WHERE (isnull(eedbenoption,'') in ('EE','EEO','Z','WAIVE','')
		or bnoDescription like '%EE%only%')
	AND eedbenstopdate is null
   AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Dependent'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = isnull(RTRIM(ConNameLast), 'N/A') + ', ' + isnull(RTRIM(ConNameFirst), 'N/A')
		,Severity = 'E'
		,ErrorNumber='02121'
		,ErrorMessage = 'Dependents with a coverage start date before the employee coverage date'
		,ErrorKeyLabel = 'Dependent Benefit Start Date'
		,ErrorKeyFieldName= 'eedBenStartdate/dbnBenStartdate'
		,ErrorKeyValue = isnull(convert(char(10),eedBenStartdate,110),'')+' - '+isnull(convert(char(10),dbnBenStartdate,110),'')
		,Details = 'Dedcode ' + isnull(dbndedcode,'') + ', EE Benefit Start Date: ' + isnull(convert(char(10),eedBenStartdate,110),'') + ', Dependent Benefit Start Date: ' + isnull(convert(char(10),dbnBenStartdate,110),'') + ''
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = consystemid
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN Contacts (NOLOCK) ON eepEEID = ConEEID AND ConIsActive = 'Y' 
JOIN DepBPlan (NOLOCK) on  dbneeid = coneeid AND dbndeprecid = consystemid AND dbnbenstopdate is null
JOIN EmpDed (NOLOCK) on dbndedcode = eeddedcode AND eedeeid = eeceeid AND eedcoid = eeccoid
WHERE dbnbenstopdate is null
  AND dbnbenstartdate < eedbenstartdate
  AND EECEMPLSTATUS <> 'T'
  AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Dependent'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = isnull(RTRIM(ConNameLast), 'N/A') + ', ' + isnull(RTRIM(ConNameFirst), 'N/A')
		,Severity = 'E'
		,ErrorNumber='00122'
		,ErrorMessage = 'Dependents with a coverage stop date after the employee coverage stop date'
		,ErrorKeyLabel = 'Dependent Benefit Start Date'
		,ErrorKeyFieldName= 'eedBenStopdate/dbnBenStopdate'
		,ErrorKeyValue = isnull(convert(char(10),eedBenStopdate,110),'')+' - '+isnull(convert(char(10),dbnBenStopdate,110),'')
		,Details = 'Dedcode ' + isnull(dbndedcode,'') + ', EE Benefit Stop Date: ' + isnull(convert(char(10),eedBenStopdate,110),'') + ', Dependent Benefit Stop Date: ' + isnull(convert(char(10),dbnBenStopdate,110),'') + ''
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = consystemid
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN Contacts (NOLOCK) ON eepEEID = ConEEID AND ConIsActive = 'Y' 
JOIN DepBPlan (NOLOCK) on  dbneeid = coneeid AND dbndeprecid = consystemid AND dbnbenstopdate is null
JOIN EmpDed (NOLOCK) on dbndedcode = eeddedcode AND eedeeid = eeceeid AND eedcoid = eeccoid
WHERE eedbenstopdate is not null
  AND (dbnbenstopdate > eedbenstopdate or dbnbenstopdate is null)
  AND eepdatetimecreated >= @createdate

-- TC can list of IA but then set the dbnbenstartdate = condateofbirth
INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Dependent'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = isnull(RTRIM(ConNameLast), 'N/A') + ', ' + isnull(RTRIM(ConNameFirst), 'N/A')
		,Severity = 'E'
		,ErrorNumber='00123'
		,ErrorMessage = 'Dependents with a coverage start date before the Dependent''s Date of Birth'
		,ErrorKeyLabel = 'Dependent Benefit Start Date'
		,ErrorKeyFieldName= 'ConDateofBirth/dbnBenStartdate'
		,ErrorKeyValue = isnull(convert(char(10),ConDateofBirth,110),'')+' - '+isnull(convert(char(10),dbnBenStartdate,110),'')
		,Details = 'Dedcode ' + isnull(dbndedcode,'') + ', Dependent Date of Birth: ' + isnull(convert(char(10),ConDateofBirth,110),'') + ', Dependent Benefit Start Date: ' + isnull(convert(char(10),dbnBenStartdate,110),'') + ''
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = consystemid
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN Contacts (NOLOCK) ON eepEEID = ConEEID AND ConIsActive = 'Y' 
JOIN DepBPlan (NOLOCK) on  dbneeid = coneeid AND dbndeprecid = consystemid AND dbnbenstopdate is null
JOIN EmpDed (NOLOCK) on dbndedcode = eeddedcode AND eedeeid = eeceeid AND eedcoid = eeccoid
WHERE dbnbenstopdate is null
  AND dbnbenstartdate < condateofbirth
  AND eepdatetimecreated >= @createdate
  
INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Dependent'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = isnull(RTRIM(ConNameLast), 'N/A') + ', ' + isnull(RTRIM(ConNameFirst), 'N/A')
		,Severity = 'W'
		,ErrorNumber='00125'
		,ErrorMessage = 'Dependent is Max Age for Benefit Plan'
		,ErrorKeyLabel = 'Deduction Code'
		,ErrorKeyFieldName= 'dbnDedCode'
		,ErrorKeyValue = isnull(dbndedcode,'') 
		,Details = 'Dedcode ' + isnull(dbndedcode,'') + ' Max Age: '+ cast(RTRIM(CbpDepMaxAge) as char(3)) + ' / Dependent Age: ' + cast(FLOOR(DATEDIFF(day,conDateOfBirth,@CreateDate)/365.242199) as char(3))
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = consystemid
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN Contacts (NOLOCK) ON eepEEID = ConEEID AND ConIsActive = 'Y' 
JOIN DepBPlan (NOLOCK) on  dbneeid = coneeid AND dbndeprecid = consystemid AND dbnbenstopdate is null
JOIN EmpDed (NOLOCK) on dbndedcode = eeddedcode AND eedeeid = eeceeid AND eedcoid = eeccoid
JOIN BenProg on dbndedcode = cbpDedCode AND eecdedgroupcode = cbpbengroupcode
WHERE FLOOR(DATEDIFF(day,conDateOfBirth,@CreateDate)/365.242199) > CbpDepMaxAge
  AND (dbnBenStatus = 'A' or dbnBenStopDate is null)
  AND conRelationship not in ('SPS','DP','HUS','WIF','EXS')
  AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Dependent'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = isnull(RTRIM(ConNameLast), 'N/A') + ', ' + isnull(RTRIM(ConNameFirst), 'N/A')
		,Severity = 'E'
		,ErrorNumber='00126'
		,ErrorMessage = 'Dependent benefit status is not termed but matching employee benefit is'
		,ErrorKeyLabel = 'Deduction Code'
		,ErrorKeyFieldName= 'dbnDedCode'
		,ErrorKeyValue = isnull(dbndedcode,'') 
		,Details = 'Dedcode ' + isnull(dbndedcode,'') + ', EE Ben Status = '+eedbenstatus+', Dependent Ben Status: '+dbnbenstatus+''
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = consystemid
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN Contacts (NOLOCK) ON eepEEID = ConEEID AND ConIsActive = 'Y' 
JOIN DepBPlan (NOLOCK) on  dbneeid = coneeid AND dbndeprecid = consystemid AND dbnbenstopdate is null
JOIN EmpDed (NOLOCK) on dbndedcode = eeddedcode AND eedeeid = eeceeid AND eedcoid = eeccoid
WHERE ((eedBenStatus <> 'A' or eedBenStopDate is not null)
  AND (dbnBenStatus = 'A' or dbnBenStopDate is null))
  AND EECEMPLSTATUS <> 'T'
  AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Dependent'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = isnull(RTRIM(ConNameLast), 'N/A') + ', ' + isnull(RTRIM(ConNameFirst), 'N/A')
		,Severity = 'E'
		,ErrorNumber='00127'
		,ErrorMessage = 'Contact Cobra status is missing'
		,ErrorKeyLabel = 'COBRA Status'
		,ErrorKeyFieldName= 'ConCOBRAStatus'
		,ErrorKeyValue = isnull(ConCOBRAStatus,'') 
		,Details = ''
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = consystemid
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN Contacts (NOLOCK) ON eepEEID = ConEEID --AND ConIsActive = 'Y' 
WHERE (ConCOBRAStatus = '' or ConCOBRAStatus = ' ' or ConCOBRAStatus is null)
  AND @Country = 'USA'
  AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Dependent'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = isnull(RTRIM(ConNameLast), 'N/A') + ', ' + isnull(RTRIM(ConNameFirst), 'N/A')
		,Severity = 'W'
		,ErrorNumber='00128'
		,ErrorMessage = 'Contact Cobra status not set up at company level'
		,ErrorKeyLabel = 'COBRA Status'
		,ErrorKeyFieldName= 'ConCOBRAStatus'
		,ErrorKeyValue = isnull(ConCOBRAStatus,'') 
		,Details = ''
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = consystemid
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN Contacts (NOLOCK) ON eepEEID = ConEEID --AND ConIsActive = 'Y' 
WHERE ConCOBRAStatus NOT IN(SELECT CodCode FROM Codes (NOLOCK) WHERE CodTable = 'COBRASTATUS')
AND @Country = 'USA'
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Contacts'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00130'
		,ErrorMessage = 'Contacts have addresses or phone numbers attached to a country that is not set up for this customer'
		,ErrorKeyLabel = 'Country'
		,ErrorKeyFieldName= 'ConAddressCountry and/or ConPhoneHomeCountry'
		,ErrorKeyValue = 'ConAddressCountry: ' +  ConAddressCountry + ' ConPhoneHomeCountry: ' + ConPhoneHomeCountry
		,Details = ''
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid=''
FROM Contacts (NOLOCK)
JOIN EmpPers (NOLOCK) ON eepEEID = ConEEID 
JOIN EmpComp (NOLOCK) on eepeeid = eeceeid
JOIN Company (NOLOCK) on cmpcoid = eeccoid
WHERE (ConAddressCountry NOT IN(SELECT CodCode FROM Codes (NOLOCK) WHERE CodTable = 'COUNTRY') OR
	   ConPhoneHomeCountry NOT IN(SELECT CodCode FROM Codes (NOLOCK) WHERE CodTable = 'COUNTRY'))
AND NULLIF(LTRIM(RTRIM(ConPhoneHomeNumber)),'') IS NOT NULL
AND NULLIF(LTRIM(RTRIM(ConAddressCountry)),'') IS NOT NULL
AND eepdatetimecreated >= @createdate
ORDER BY CmpCompanyName, EepNameLast
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
--Deduction Validations

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Deduction'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00200'
		,ErrorMessage = 'Employee is missing deduction that is set to Auto-Add in the Benefit Group'
		,ErrorKeyLabel = 'Deduction Code'
		,ErrorKeyFieldName= 'dbnDedCode'
		,ErrorKeyValue = isnull(cbpdedcode,'') 
		,Details = 'DedGroup: '+eecdedgroupcode+', Dedcode ' + isnull(cbpdedcode,'') + ', Stop Date = '+isnull(convert(char(10),eedStopdate,110),'')+''
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN benprog (NOLOCK) on cbpbengroupcode = eecdedgroupcode AND cbpautoadd='Y'
LEFT outer JOIN EmpDed (NOLOCK) on cbpdedcode = eeddedcode AND eedeeid = eeceeid AND eedcoid = eeccoid
WHERE eecemplstatus = 'A' AND (eeddedcode is null)
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Deduction'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='01200'
		,ErrorMessage = 'Employee has a stopped deduction that is set to Auto-Add in the Benefit Group'
		,ErrorKeyLabel = 'Deduction Code'
		,ErrorKeyFieldName= 'EedDedCode'
		,ErrorKeyValue = isnull(eeddedcode,'') 
		,Details = 'Dedcode ' + isnull(eeddedcode,'') + ', Stop Date = '+isnull(convert(char(10),eedStopdate,110),'')+''
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN benprog (NOLOCK) on cbpbengroupcode = eecdedgroupcode AND cbpautoadd='Y'
JOIN EmpDed (NOLOCK) on cbpdedcode = eeddedcode AND eedeeid = eeceeid AND eedcoid = eeccoid
WHERE eecemplstatus = 'A' AND eedstopdate is not null
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Deduction'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00201'
		,ErrorMessage = 'Missing Goal Amount (FSA or Dependent Care)'
		,ErrorKeyLabel = 'Deduction Code'
		,ErrorKeyFieldName= 'eedDedCode'
		,ErrorKeyValue = isnull(eeddedcode,'') 
		,Details = 'Dedcode ' + isnull(eeddedcode,'') + ', Per Pay Amt = '+ltrim(rtrim(isnull(convert(char(20),eedeeamt),'')))+', Goal Amt = '+ltrim(rtrim(isnull(convert(char(20),eedeegoalamt),'')))
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN EmpDed (NOLOCK) on eedeeid = eeceeid AND eedcoid = eeccoid
JOIN DedCode (NOLOCK) on eeddedcode = deddedcode
WHERE eedBenStatus = 'A' AND deddedtype = 'FSA' AND isnull(eedEEGoalAmt,0) = 0 AND EedEEAmt <> 0
AND @Country = 'USA'
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Deduction'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00202'
		,ErrorMessage = 'Invalid wage attachment setup'
		,ErrorKeyLabel = 'Deduction Code'
		,ErrorKeyFieldName= 'eedDedCode'
		,ErrorKeyValue = isnull(eeddedcode,'') 
		,Details = 'Dedcode ' + isnull(eeddedcode,'') + ', Per Pay Amt = '+ltrim(rtrim(isnull(convert(char(20),eedeeamt),'')))+
					', EE % = '+ltrim(rtrim(isnull(convert(char(20),eedeecalcrateorPct),'')))+
					', Goal Amt = '+ltrim(rtrim(isnull(convert(char(20),eedeegoalamt),'')))+
					', Payee = '+EedPayeeID + ' - ' + ProCompanyName
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN EmpDed (NOLOCK) on eedeeid = eeceeid AND eedcoid = eeccoid
JOIN DedCode (NOLOCK) on eeddedcode = deddedcode
LEFT JOIN Codes cd1 (NOLOCK) ON cd1.CodCode = DedEECalcRule AND cd1.CodTable='DEDEECALCRULE'
LEFT JOIN Codes cd2 (NOLOCK) ON cd2.CodCode = EedEECalcRule AND cd2.CodTable='DEDEECALCRULE'
LEFT JOIN Provider (NOLOCK) ON EedPayeeID = ProProviderCode
WHERE DedInclWageAttachment = 'Y'
	 AND EedStopDate IS NULL 
	--AND (EedStopDate IS NULL OR EedStopDate > GETDATE())
	AND  EecEmplStatus <> 'T'
	AND (NULLIF(LTRIM(RTRIM(EedPayeeID)),'') IS NULL OR EedPayeeID = 'Z' OR NULLIF(LTRIM(RTRIM(EedEEMemberOrCaseNo)),'') IS NULL OR
	(EedWgaWageCode <> 'FDLEV' AND EedEEAmt = 0 AND EedEECalcRateOrPct = 0) OR 
	 EedERAmt <> 0 OR
	(DedDedType NOT IN ('OTH', 'OT2') AND (EedWgaState IS NULL OR EedWgaWageCode IS NULL)) OR
	(DedTaxCategory = 'CHILD' AND EedFipsCode IS NULL) OR
	(DedEEUseEERule = 'Y' AND NULLIF(LTRIM(RTRIM(EedEECalcRule)),'99') IS NULL) OR
	(DedEEUseEERule = 'N' AND NULLIF(LTRIM(RTRIM(DedEECalcRule)),'99') IS NULL) OR
	 EedWgaWageCode = 'TXGAR' OR EedWgaWageCode = 'SCGAR' OR
	(EedWgaWageCode = 'FDLEV' AND (NULLIF(LTRIM(RTRIM(EedWgaEELevyTaxYear)),'') IS NULL OR NULLIF(LTRIM(RTRIM(EedWgaFilingStatus)),'') IS NULL)))
AND @Country = 'USA'
AND eepdatetimecreated >= @createdate
	
INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Deduction'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00203'
		,ErrorMessage = 'Benefit eligibility date is before date of benefit seniority'
		,ErrorKeyLabel = 'Deduction Code'
		,ErrorKeyFieldName= 'eedDedCode'
		,ErrorKeyValue = isnull(eeddedcode,'') 
		,Details = 'Dedcode ' + isnull(eeddedcode,'') + ', Date of Benefit Seniority = '+isnull(convert(char(10),EecDateOfBenefitSeniority,110),'')+''+
					', EE Elig Date = '+isnull(convert(char(10),eedeeeligdate,110),'')+''
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN EmpDed (NOLOCK) on eedeeid = eeceeid AND eedcoid = eeccoid
JOIN DedCode (NOLOCK) on eeddedcode = deddedcode
WHERE EedEEEligDate < EecDateOfBenefitSeniority AND DedIsBenefit = 'Y'
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Deduction'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00204'
		,ErrorMessage = 'Coverage Start date is before date of benefit seniority'
		,ErrorKeyLabel = 'Deduction Code'
		,ErrorKeyFieldName= 'eedDedCode'
		,ErrorKeyValue = isnull(eeddedcode,'') 
		,Details = 'Dedcode ' + isnull(eeddedcode,'') + ', Date of benefit seniority = '+isnull(convert(char(10),EecDateOfBenefitSeniority,110),'')+''+
					', Ben Start Date = '+isnull(convert(char(10),EedBenStartDate,110),'')+''
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN EmpDed (NOLOCK) on eedeeid = eeceeid AND eedcoid = eeccoid
JOIN DedCode (NOLOCK) on eeddedcode = deddedcode
WHERE EedBenStartDate < EecDateOfBenefitSeniority AND DedIsBenefit = 'Y'
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Deduction'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00205'
		,ErrorMessage = 'Benefit stop date is before benefit startdate'
		,ErrorKeyLabel = 'Deduction Code'
		,ErrorKeyFieldName= 'eedDedCode'
		,ErrorKeyValue = isnull(eeddedcode,'') 
		,Details = 'Dedcode ' + isnull(eeddedcode,'') + ', Benefit Start Date = '+isnull(convert(char(10),eedbenstartdate,110),'')+''+
					', Benefit Stop Date = '+isnull(convert(char(10),eedbenStopdate,110),'')+''
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN EmpDed (NOLOCK) on eedeeid = eeceeid AND eedcoid = eeccoid
JOIN DedCode (NOLOCK) on eeddedcode = deddedcode
WHERE EedBenStopDate < EedBenStartDate AND eedbenstopdate is not null AND DedIsBenefit = 'Y'
AND eepdatetimecreated >= @createdate
	
INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Deduction'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00206'
		,ErrorMessage = 'Deduction Stop date is before the Deduction Start Date'
		,ErrorKeyLabel = 'Deduction Code'
		,ErrorKeyFieldName= 'eedDedCode'
		,ErrorKeyValue = isnull(eeddedcode,'') 
		,Details = 'Dedcode ' + isnull(eeddedcode,'') + ', Start Date = '+isnull(convert(char(10),eedstartdate,110),'')+''+
					', Stop Date = '+isnull(convert(char(10),eedStopdate,110),'')+''
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN EmpDed (NOLOCK) on eedeeid = eeceeid AND eedcoid = eeccoid
JOIN DedCode (NOLOCK) on eeddedcode = deddedcode
WHERE EedStopDate < EedStartDate AND eedstopdate is not null
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Deduction'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00207'
		,ErrorMessage = 'Employee has a benefit that is missing the Benefit Status Date, Benefit Status Code, Eligibility Date, Benefit Start Date or Deduction Start Date'
		,ErrorKeyLabel = 'Deduction Code'
		,ErrorKeyFieldName= 'eedDedCode'
		,ErrorKeyValue = isnull(eeddedcode,'') 
		,Details = 'Dedcode ' + isnull(eeddedcode,'') + ', Benefit Status = '+isnull(eedbenstatus,'')+', Ben Status Date = '+isnull(convert(char(10),eedbenstatusdate,110),'')+''+
					', Ben Start Date = '+isnull(convert(char(10),eedBenStartdate,110),'')+', EE Elig Date = '+isnull(convert(char(10),eedeeeligdate,110),'')+', Ded Start Date'+isnull(convert(char(10),eedstartdate,110),'')+''
		,RoleToReview ='SC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN EmpDed (NOLOCK) on eedeeid = eeceeid AND eedcoid = eeccoid AND eedbenstatus <> 'W' 
JOIN DedCode (NOLOCK) on eeddedcode = deddedcode
WHERE DedIsBenefit='Y' AND (eedbenstatusdate is null OR eedbenstatus is null OR eedbenstartdate is null OR eedeeeligdate is null or EedStartdate is null) --AND eedbenstatus <> 'W'
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Deduction'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00208'
		,ErrorMessage = 'Terminated benefit deduction on active employee is missing a coverage or deduction stop date'
		,ErrorKeyLabel = 'Deduction Code'
		,ErrorKeyFieldName= 'eedDedCode'
		,ErrorKeyValue = isnull(eeddedcode,'') 
		,Details = 'Dedcode ' + isnull(eeddedcode,'') + ', Benefit Status = '+isnull(eedbenstatus,'')+', Ben Stop Date = '+isnull(convert(char(10),EedBenStopDate,110),'')+''+
					', Ded Stop Date = '+isnull(convert(char(10),EedStopDate,110),'')+''
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN EmpDed (NOLOCK) on eedeeid = eeceeid AND eedcoid = eeccoid
JOIN DedCode (NOLOCK) on eeddedcode = deddedcode
WHERE EedBenStatus <> 'A' AND EedBenStatus <> 'W' AND DedIsBenefit = 'Y' AND EecEmplStatus <> 'T'
	AND (EedBenStopDate IS NULL OR EedStopDate IS NULL)
	AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Deduction'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00209'
		,ErrorMessage = 'Benefit deduction has an Active Status on but also has a coverage or deduction stop date'
		,ErrorKeyLabel = 'Deduction Code'
		,ErrorKeyFieldName= 'eedDedCode'
		,ErrorKeyValue = isnull(eeddedcode,'') 
		,Details = 'Dedcode ' + isnull(eeddedcode,'') + ', Benefit Status = '+isnull(eedbenstatus,'')+', Ben Stop Date = '+isnull(convert(char(10),EedBenStopDate,110),'')+''+
					', Ded Stop Date = '+isnull(convert(char(10),EedStopDate,110),'')+''
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN EmpDed (NOLOCK) on eedeeid = eeceeid AND eedcoid = eeccoid
JOIN DedCode (NOLOCK) on eeddedcode = deddedcode
WHERE EedBenStatus = 'A' AND DedIsBenefit = 'Y' AND EecEmplStatus <> 'T'
	AND (EedBenStopDate IS NOT NULL OR EedStopDate IS NOT NULL)
	AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Deduction'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00211'
		,ErrorMessage = 'Employee has a deduction that does not match the company level setting for "include in additional check" or "include in manual check"'
		,ErrorKeyLabel = 'Deduction Code'
		,ErrorKeyFieldName= 'eedDedCode'
		,ErrorKeyValue = isnull(eeddedcode,'') 
		,Details = 'Dedcode ' + isnull(eeddedcode,'') + ', Ded Include in Addl = '+dedInclInAddlChk+', EE Level Includ in Addl = '+EedInclInAddlChk+', Ded Include in Manual = '+dedInclInManlChk+', EE Level Includ in Manual = '+EedInclInManlChk+''
		,RoleToReview ='SC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN EmpDed (NOLOCK) on eedeeid = eeceeid AND eedcoid = eeccoid
JOIN DedCode (NOLOCK) on eeddedcode = deddedcode
WHERE (EedInclInAddlChk<>dedInclInAddlChk OR EedInclInManlChk<>dedInclInManlChk)
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Deduction'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00212'
		,ErrorMessage = 'Employee has a Benefit with an invalid Benefit Status'
		,ErrorKeyLabel = 'Deduction Code'
		,ErrorKeyFieldName= 'eedDedCode'
		,ErrorKeyValue = isnull(eeddedcode,'') 
		,Details = 'Dedcode ' + isnull(eeddedcode,'') + ', Ben Status = '+eedbenstatus+''
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
	-- select eeddedcode, eedbenstatus, eedbenstartdate, dedcode.*
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN EmpDed (NOLOCK) on eedeeid = eeceeid AND eedcoid = eeccoid
JOIN DedCode (NOLOCK) on eeddedcode = deddedcode
WHERE dedisbenefit = 'Y' 
    and dedisdedoffset <> 'Y'
	AND not exists (select 1 FROM Codes (NOLOCK) WHERE CodCode = EedBenStatus AND CodTable = 'BENSTAT')
	AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Deduction'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00213'
		,ErrorMessage = 'Employee has a Benefit with an invalid Benefit Option'
		,ErrorKeyLabel = 'Deduction Code'
		,ErrorKeyFieldName= 'eedDedCode'
		,ErrorKeyValue = isnull(eeddedcode,'') 
		,Details = 'Dedcode ' + isnull(eeddedcode,'') + ', Ben Option = '+isnull(EedBenOption,'')+''
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN EmpDed (NOLOCK) on eedeeid = eeceeid AND eedcoid = eeccoid
JOIN DedCode (NOLOCK) on eeddedcode = deddedcode
LEFT JOIN BenOpt (NOLOCK) ON bnoCode = EedBenOption
WHERE ISNULL(EedBenOption,'') IN ('','Z')
  AND EXISTS (select distinct corbenoption, bnoDescription
					FROM OptRate (NOLOCK)
					 JOIN benopt (NOLOCK) on bnocode = CorBenOption
					 JOIN DedCode (NOLOCK) on deddedcode = CorDedCode
					 WHERE eeddedcode = cordedcode)
  AND EedBenStatus <> 'W' AND (EedBenStopDate <> EedBenStartDate)
  AND eepdatetimecreated >= @createdate
  and eedstopdate is null
  --AND eecEmplStatus <> 'T'

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Deduction'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00214'
		,ErrorMessage = 'Deduction Start/Ben Start date does not match Deduction Code Rule (Ex. Cov Stop Date = End of Month)'
		,ErrorKeyLabel = 'Deduction Code'
		,ErrorKeyFieldName= 'eedDedCode'
		,ErrorKeyValue = isnull(eeddedcode,'') 
		,Details = 'Dedcode ' + isnull(eeddedcode,'') + 
					', EE Elig Date = '+isnull(convert(char(10),eedEEEligDate,110),'')+
					', Ben Start Date = '+isnull(convert(char(10),EedBenStartDate,110),'')+
					', Ded Start Date = '+isnull(convert(char(10),EedstartDate,110),'')+
					', Ded Stop Date = '+isnull(convert(char(10),EedStopDate,110),'')+
					', Cov Start Rule: '+isnull(cstart.dsc,'')+ 
					', Ded Start Rule: '+isnull(dstart.dsc,'')+ ''
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN EmpDed (NOLOCK) on eedeeid = eeceeid AND eedcoid = eeccoid
JOIN DedCode (NOLOCK) on eeddedcode = deddedcode
LEFT JOIN (select codCode Code, CodDesc Dsc FROM Codes (NOLOCK) WHERE CodTable = 'COVSTART') cstart on cstart.Code = DedPlanCovStartRule
LEFT JOIN (select codCode Code, CodDesc Dsc FROM Codes (NOLOCK) WHERE CodTable = 'DEDSTART') dstart on dstart.Code = DedDedStartRule
WHERE ((DedPlanCovStartRule = '50' AND datepart(dd,eedBenStartDate) <> '01' AND datepart(mm,eedBenStartDate) not in ('01','07'))
		OR (DedPlanCovStartRule in ('10','20') AND eedbenstartdate < eedEEEligDate))
  AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Deduction'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00215'
		,ErrorMessage = 'Deduction Stop/Ben Stop date does not match Deduction Code Rule (Ex. Cov Stop Date = End of Month)'
		,ErrorKeyLabel = 'Deduction Code'
		,ErrorKeyFieldName= 'eedDedCode'
		,ErrorKeyValue = isnull(eeddedcode,'') 
		,Details = 'Dedcode ' + isnull(eeddedcode,'') + 
					', EE Elig Date = '+isnull(convert(char(10),eedEEEligDate,110),'')+
					', EE Term Date = '+isnull(convert(char(10),EecDateoftermination,110),'')+
					', Ben Stop Date = '+isnull(convert(char(10),EedBenStopDate,110),'')+
					',  Ded Stop Date = '+isnull(convert(char(10),EedStopDate,110),'')+
					', Cov Stop Rule: '+isnull(cstop.dsc,'')+ 
					', Ded Stop Rule: '+isnull(dstop.dsc,'')+ ''
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN EmpDed (NOLOCK) on eedeeid = eeceeid AND eedcoid = eeccoid
JOIN DedCode (NOLOCK) on eeddedcode = deddedcode
LEFT JOIN (select codCode Code, CodDesc Dsc FROM Codes (NOLOCK) WHERE CodTable = 'COVSTOP') cstop on cstop.Code = DedPlanCovStopRule
LEFT JOIN (select 'Y' Code, 'Stop deduction at Termination' Dsc) dstop on dstop.Code = deddedstoprule
WHERE ((DedPlanCovStopRule = '20' AND eecDateofTermination <> eedBenStopDate AND eecEmplStatus = 'T' AND eedBenStatus not in ('W','A'))
		OR (DedPlanCovStopRule = '20' AND eecDateofTermination <> eedBenStopDate AND eecEmplStatus = 'T' AND eedBenStatus = 'A')
		OR (DedPlanCovStopRule = '30' AND eedBenStopDate <> dbo.Mk2_RET_MaskDates('DateFN','EndofCurrentMonth',eedBenStopDate,'','') AND eedBenStatus not in ('W','A'))
		OR (deddedstoprule = 'Y' AND eedstopdate is null AND eedBenStatus not in ('W','A'))
		OR (deddedstoprule = 'Y' AND dedisbenefit = 'N' AND eedstopdate is null AND eecEmplStatus = 'T' AND eedBenStatus = 'A'))
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Deduction'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00216'
		,ErrorMessage = 'Missing benefit amount for benefit amount calculation rule that requires benefit amount'
		,ErrorKeyLabel = 'Deduction Code'
		,ErrorKeyFieldName= 'eedDedCode'
		,ErrorKeyValue = isnull(eeddedcode,'') 
		,Details = 'Dedcode ' + isnull(eeddedcode,'') + ', Benefit Calc Rule: '+ RTRIM(CodDesc) +', Benefit Amount: ' + cast(isnull(eedBenAmt,0) as varchar)
		,RoleToReview ='TC\SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
		-- select *
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID --
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN EmpDed (NOLOCK) on eedeeid = eeceeid AND eedcoid = eeccoid
JOIN DedCode (NOLOCK) on eeddedcode = deddedcode
JOIN DedType  (NOLOCK) on CdtDedTypeCode = deddedtype
LEFT JOIN Codes on CodCode = dedBenAmtCalcRule AND codTable = '_BENCALCRULE'
WHERE eedBenStatus = 'A' AND DedBenAmtCalcRule = '30' and CdtAllowBenAmtChg = 'Y' AND isnull(eedBenAmt,0) = 0
AND eepdatetimecreated >= @createdate


INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Deduction'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00229'
		,ErrorMessage = 'Employee level deduction calc rule is "None" when deduction code is is flagged to "Use rule at EE level"'
		,ErrorKeyLabel = 'Deduction Code'
		,ErrorKeyFieldName= 'eedDedCode'
		,ErrorKeyValue = isnull(eeddedcode,'') 
		,Details = 'Dedcode ' + isnull(eeddedcode,'') + ', Ded Calc Rule: '+ RTRIM(DedEECalcRule)  + ', Empded Calc Rule: '+ RTRIM(eedEECalcRule) 
		,RoleToReview ='TC\SC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
		-- select *
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID --
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN EmpDed (NOLOCK) on eedeeid = eeceeid AND eedcoid = eeccoid
JOIN DedCode (NOLOCK) on eeddedcode = deddedcode
WHERE eedBenStatus = 'A' 
  AND dedeecalcrule = '99' 
  and dedeeuseeerule = 'Y'          --- Please add dedeeuseeerule = 'Y' in the query
  AND (eedeecalcrule is null or dedercalcexprkey = '')
AND eepdatetimecreated >= @createdate

--select deddedcode, dedeecalcrule, dedeeviewplandesc, * from dedcode where dedeecalcrule = '99'  -- where deddedcode like 'CF%' 

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Deduction'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00217'
		,ErrorMessage = 'Active Garnishment missing address or payee information'
		,ErrorKeyLabel = 'Deduction Code'
		,ErrorKeyFieldName= 'eedDedCode'
		,ErrorKeyValue = isnull(eeddedcode,'') 
		,Details = 'Dedcode ' + isnull(eeddedcode,'') + ', Payee: '+eedpayeeid+' - '+rtrim(ProCompanyName) +
						', Addr: '+ isnull(rtrim(proaddressline1),'') + 
						', City: '+ isnull(rtrim(proaddresscity),'') +
						', ST: '+ isnull(rtrim(proaddressstate),'') +
						', Zip: '+ isnull(rtrim(proaddresszipcode),'') +''
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN EmpDed (NOLOCK) on eedeeid = eeceeid AND eedcoid = eeccoid
JOIN DedCode (NOLOCK) on eeddedcode = deddedcode
JOIN [provider] (NOLOCK) on proprovidercode=eedpayeeid
WHERE DedInclWageAttachment='Y'
	AND eedstopdate is null
	AND procompanyname not like '%State Disbursement%'
	AND (proaddressline1 is null OR proaddresscity is null OR proaddressstate is null OR proaddresszipcode is null)
	AND eecemplstatus<>'T'
	AND @Country = 'USA'
	AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Deduction'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='01217'
		,ErrorMessage = 'Garnishment required fields missing.'
		,ErrorKeyLabel = 'Deduction Code'
		,ErrorKeyFieldName= 'eedDedCode'
		,ErrorKeyValue = isnull(eeddedcode,'') 
		,Details = 'Dedcode ' + isnull(eeddedcode,'') 
					+ ', Wage State: '+ isnull(rtrim(EedWgaState),'')
					+ ', Wage Code: '+ isnull(rtrim(EedWgaWageCode),'')
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN EmpDed (NOLOCK) on eedeeid = eeceeid AND eedcoid = eeccoid
JOIN DedCode (NOLOCK) on eeddedcode = deddedcode AND DedDedType = 'GAR'
WHERE eedstopdate is null
  AND eecemplstatus<>'T'
  AND ((EedWgaState is NULL) or (EedWgaWageCode is NULL))
  AND eepdatetimecreated >= @createdate	

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Deduction'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00218'
		,ErrorMessage = 'Employee deduction stop date is after the current pay period start date'
		,ErrorKeyLabel = 'Deduction Stop Date'
		,ErrorKeyFieldName= 'EedStopDate'
		,ErrorKeyValue =  ltrim(rtrim(isnull(CONVERT(varchar, EedStopDate, 101),''))) 
		,Details = 'Dedcode ' + isnull(eeddedcode,'') 
		        +', Pay Group: '+eecpaygroup
				+', Period Start Date: ' + ltrim(rtrim(isnull(CONVERT(varchar, PgrPeriodStartDate, 101),''))) 
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN EmpDed (NOLOCK) on eedeeid = eeceeid AND eedcoid = eeccoid
JOIN DedCode (NOLOCK) on eeddedcode = deddedcode
JOIN PayGroup (NOLOCK) on PgrPayGroup = EecPayGroup
WHERE EedStopDate > PgrPeriodStartDate  
	  AND EecEmplStatus <> 'T' 
	  AND EedStopDate is not NULL 
	  AND ((EedEEAmt <> 0) or (EedEECalcRateOrPct <> 0))
	  AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Deduction'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00219'
		,ErrorMessage = 'Employee deductions have start dates greater than the current pay period end date.'
		,ErrorKeyLabel = 'Deduction Start Date'
		,ErrorKeyFieldName= 'EedStartDate'
		,ErrorKeyValue =  ltrim(rtrim(isnull(CONVERT(varchar, EedStartDate, 101),''))) 
		,Details = 'Dedcode ' + isnull(eeddedcode,'') 
		        +', Pay Group: '+eecpaygroup
				+', Period End Date: ' + ltrim(rtrim(isnull(CONVERT(varchar, PgrPeriodEndDate, 101),''))) 
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN EmpDed (NOLOCK) on eedeeid = eeceeid AND eedcoid = eeccoid
JOIN DedCode (NOLOCK) on eeddedcode = deddedcode
JOIN PayGroup (NOLOCK) on PgrPayGroup = EecPayGroup
WHERE EedStartDate > PgrPeriodEndDate  
	AND EecEmplStatus <> 'T' 
	AND EedStopDate is not NULL 
	AND ((EedEEAmt <> 0) or (EedEECalcRateOrPct <> 0))
	AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Deduction'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00220'
		,ErrorMessage = 'Employee deduction percentage greater than 100%'
		,ErrorKeyLabel = 'Employee Calc Rate of Pct'
		,ErrorKeyFieldName= 'EedEECalcRateOrPct'
		,ErrorKeyValue =  EedEECalcRateOrPct
		,Details = 'Dedcode ' + isnull(eeddedcode,'') 
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN EmpDed (NOLOCK) on eedeeid = eeceeid AND eedcoid = eeccoid
JOIN DedCode (NOLOCK) on eeddedcode = deddedcode
WHERE EecEmplStatus <> 'T' 
	AND EedStopDate is NULL 
	AND EedEECalcRateOrPct > 1.00
	AND eepdatetimecreated >= @createdate
	
INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Deduction'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00221'
		,ErrorMessage = 'Employee has a Benefit with an invalid Benefit Option on PBADD.  TC should default a valid Benefit Option.'
		,ErrorKeyLabel = 'Deduction Code'
		,ErrorKeyFieldName= 'eedDedCode'
		,ErrorKeyValue = isnull(eeddedcode,'') 
		,Details = 'Dedcode ' + isnull(eeddedcode,'') + ', Ben Option = '+isnull(EedBenOption,'')+''
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN EmpDed (NOLOCK) on eedeeid = eeceeid AND eedcoid = eeccoid
JOIN DedCode (NOLOCK) on eeddedcode = deddedcode
LEFT JOIN BenOpt (NOLOCK) ON bnoCode = EedBenOption
WHERE ISNULL(EedBenOption,'') IN ('','Z')
  AND EXISTS (select distinct corbenoption, bnoDescription
					FROM OptRate (NOLOCK)
					JOIN benopt (NOLOCK) on bnocode = CorBenOption
					JOIN DedCode (NOLOCK) on deddedcode = CorDedCode
					WHERE eeddedcode = cordedcode)
  AND EedBenStatus <> 'W' AND (EedBenStopDate <> EedBenStartDate)
  AND eecEmplStatus <> 'T'
  AND eedBenStatus = 'T'
  AND eedNotes like 'PBADD%'
  AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Deduction'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00222'
		,ErrorMessage = 'Missing Goal Amount (Garnishment)'
		,ErrorKeyLabel = 'Deduction Code'
		,ErrorKeyFieldName= 'eedDedCode'
		,ErrorKeyValue = isnull(eeddedcode,'') 
		,Details = 'Dedcode ' + isnull(eeddedcode,'') + ', Per Pay Amt = '+ltrim(rtrim(isnull(convert(char(20),eedeeamt),'')))+', Goal Amt = '+ltrim(rtrim(isnull(convert(char(20),eedeegoalamt),'')))
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID AND CmpCountrycode = 'CAN'
JOIN EmpDed (NOLOCK) on eedeeid = eeceeid AND eedcoid = eeccoid and isnull(EedEEGoalAmt,0) = 0
JOIN DedCode (NOLOCK) on eeddedcode = deddedcode AND DedDedType = 'GAR'
WHERE Eecemplstatus <> 'T'
  AND @Country = 'CAN'
  AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Deduction'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00223'
		,ErrorMessage = 'Please review EE GTD amounts to ensure amt is correct before go live.'
		,ErrorKeyLabel = 'Deduction Code'
		,ErrorKeyFieldName= 'eedDedCode'
		,ErrorKeyValue = isnull(eeddedcode,'') 
		,Details = 'Dedcode ' + isnull(eeddedcode,'') + ', Per Pay Amt = '+ltrim(rtrim(isnull(convert(char(20),eedeeamt),'')))+', Goal To Date Amt = '+ltrim(rtrim(isnull(convert(char(20),eedeegtdamt),'')))
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID AND CmpCountrycode = 'USA'
JOIN EmpDed (NOLOCK) on eedeeid = eeceeid AND eedcoid = eeccoid and eedeegtdamt <> 0
JOIN DedCode (NOLOCK) on eeddedcode = deddedcode
WHERE Eecemplstatus <> 'T'
  AND @Country = 'USA'
  AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Deduction'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00224'
		,ErrorMessage = 'Please review EE Arrears amounts to ensure amt is correct before go live.'
		,ErrorKeyLabel = 'Arrears Amount'
		,ErrorKeyFieldName= 'eedarrearsamt'
		,ErrorKeyValue = isnull(eedarrearsamt,'') 
		,Details = 'Dedcode ' + isnull(eeddedcode,'') + ', Per Pay Amt = '+ltrim(rtrim(isnull(convert(char(20),eedeeamt),'')))
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID AND CmpCountrycode = 'USA'
JOIN EmpDed (NOLOCK) on eedeeid = eeceeid AND eedcoid = eeccoid and eedarrearsamt <> 0
JOIN DedCode (NOLOCK) on eeddedcode = deddedcode
WHERE @Country = 'USA'
  AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Deduction'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00226'
		,ErrorMessage = 'Regular garnishment should not have a Filing Status. Please correct employee record.'
		,ErrorKeyLabel = 'Deduction Code'
		,ErrorKeyFieldName= 'eedDedCode'
		,ErrorKeyValue = isnull(eeddedcode,'') 
		,Details = 'Dedcode ' + isnull(eeddedcode,'') 
					+ ', Wage State: '+ isnull(rtrim(EedWgaState),'')
					+ ', Wage Code: '+ isnull(rtrim(EedWgaWageCode),'')
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN EmpDed (NOLOCK) on eedeeid = eeceeid AND eedcoid = eeccoid
JOIN DedCode (NOLOCK) on eeddedcode = deddedcode AND DedDedType = 'GAR'
WHERE eedstopdate is null
  AND eecemplstatus <>'T'
  AND eedwgafilingstatus <> ''
  AND eedwgawagecode not in ('FDLEV','AZLEV','MILEV','MALEV','KYLEV','NELEV','NELVP','VATLV','VALEV') 
  AND eedwgawagecode is not null
  AND eepdatetimecreated >= @createdate	


 --E 00227
 -- New SC/Customer:
 -- Agre rated deduction does not have dependent associated.

 INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
 SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Deduction'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00227'
		,ErrorMessage = 'Employee age rated deduction without dependent'
		,ErrorKeyLabel = 'Deduction Code'
		,ErrorKeyFieldName= 'eedDedCode'
		,ErrorKeyValue = EecEmpno
		,Details = 'Dedcode: ' + eeddedcode+
		       ' Start date: '+isnull(convert(char(10),eedstartdate,110),'')+
			   ' Ben Start date: '+isnull(convert(char(10),eedbenstartdate,110),'')
		,RoleToReview ='SC/Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid=''
  FROM EmpComp (NOLOCK)
   JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
   JOIN Company (NOLOCK) ON CmpCOID = EecCOID
   JOIN EmpDed (NOLOCK) on eedeeid = eeceeid AND eedcoid = eeccoid
   JOIN DedCode (NOLOCK) on eeddedcode = deddedcode
   where EedDedCode in (select DedDedCode from DedCode where DedEECalcRule = '32')
	and EedDepRecID is NULL
	and EecEmplStatus <> 'T'
	and EedBenStatus <> 'W'
	and eepdatetimecreated >= @createdate


 --E 00228
 -- New SC/Customer:
 -- Employee deduction contains a benefit option for a deduction code that does not have a calc rule of "Benefit Option"

 INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
 SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Deduction'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00228'
		,ErrorMessage = 'Employee deduction contains a benefit option for a deduction code that does not have a calc rule of "Benefit Option"'
		,ErrorKeyLabel = 'Deduction Code'
		,ErrorKeyFieldName= 'eedDedCode'
		,ErrorKeyValue = EecEmpno
		,Details = 'Dedcode: ' + eeddedcode+
		       ' BenOption: '+eedbenoption
		,RoleToReview ='SC/Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid=''
  FROM EmpComp (NOLOCK)
   JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
   JOIN Company (NOLOCK) ON CmpCOID = EecCOID
   JOIN EmpDed (NOLOCK) on eedeeid = eeceeid AND eedcoid = eeccoid
   JOIN DedCode (NOLOCK) on eeddedcode = deddedcode
where EedBenOption is not null
  and dedeecalcrule <> '21'
  and EedBenOption <> 'Z'
  and EedBenOption <> '' 
	and eepdatetimecreated >= @createdate



 --W 00230
 --New SC/Customer:
 --Changing date of hire can cause deduction start dates to predate hire date.  Add a validation to point this out.

 INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
 SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Deduction'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00230'
		,ErrorMessage = 'Employee has deduction start dates before seniority date'
		,ErrorKeyLabel = 'Employee Empno'
		,ErrorKeyFieldName= 'Eecempno'
		,ErrorKeyValue = EecEmpno
		,Details = 'Dedcode: ' + eeddedcode+
		       ' Start date: '+isnull(convert(char(10),eedstartdate,110),'')+
			   ' Ben Start date: '+isnull(convert(char(10),eedbenstartdate,110),'')+
			   ' Seniority date: '+isnull(convert(char(10),eecdateofbenefitseniority,110),'')+
			   ' Last Hire date: '+isnull(convert(char(10),eecdateoflasthire,110),'')
		,RoleToReview ='SC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid=''
  FROM EmpComp (NOLOCK)
   JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
   JOIN Company (NOLOCK) ON CmpCOID = EecCOID
   JOIN EmpDed (NOLOCK) on eedeeid = eeceeid AND eedcoid = eeccoid
   JOIN DedCode (NOLOCK) on eeddedcode = deddedcode
  WHERE eepdatetimecreated >= @createdate
    and eedstartdate < eecdateofbenefitseniority
	and DedIsDedOffSet = 'N' 


-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
print getdate()
RAISERROR ('Employee QA thru 00299', 0, 1) WITH NOWAIT
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
--Earning Validations

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Earning'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00300'
		,ErrorMessage = 'Employee''s display in PDE option does NOT match earn code display in PDE option'
		,ErrorKeyLabel = 'Earning Code'
		,ErrorKeyFieldName= 'eeeEarnCode'
		,ErrorKeyValue = isnull(eeeEarnCode,'') 
		,Details = 'Earncode ' + isnull(eeeearncode,'') + ', EE DisplayInPDE: '+EeeDisplayInPDE+ ', EarnCode DisplayInPDE: '+ErnDisplayInPDE +''
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN EmpEarn (NOLOCK) on eeeeeid = eeceeid AND eeecoid = eeccoid
JOIN EarnCode (NOLOCK) ON ErnEarncode = EeeEarnCode
WHERE ErnDisplayInPDE <> EeeDisplayInPDE 
	AND EeeStopDate IS NULL 
	AND ErnActiveStatusAsOfDate IS NOT NULL 
	AND EecEmplStatus <> 'T'
	AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Earning'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00302'
		,ErrorMessage = 'Auto-Add Earning missing for Employee'
		,ErrorKeyLabel = 'Earning Code'
		,ErrorKeyFieldName= 'cepEarnCode'
		,ErrorKeyValue = isnull(cepEarnCode,'') 
		,Details = 'Earncode ' + isnull(cepearncode,'') + case when eeeearncode is null 
																then ', Earn Code is set to auto-add but does not exist for this Employee' 
																else ', Earn code  is set to auto-add but has a Stop Date = '+isnull(convert(char(10),eeeStopdate,110),'')+'' 
																end
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN earnprog (NOLOCK) on cepearngroupcode = eecearngroupcode	 AND cepautoadd='Y'
LEFT outer JOIN Empearn (NOLOCK) on cepearncode = eeeearncode AND eeeeeid = eeceeid AND eeecoid = eeccoid
WHERE eecemplstatus = 'A' AND eeeearncode is null

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Earning'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='01302'
		,ErrorMessage = 'Auto-Add Earning is stopped for Employee'
		,ErrorKeyLabel = 'Earning Code'
		,ErrorKeyFieldName= 'cepEarnCode'
		,ErrorKeyValue = isnull(cepEarnCode,'') 
		,Details = 'Earncode ' + isnull(cepearncode,'') + case when eeeearncode is null 
																then ', Earn Code is set to auto-add but does not exist for this Employee' 
																else ', Earn code  is set to auto-add but has a Stop Date = '+isnull(convert(char(10),eeeStopdate,110),'')+'' 
																end
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID AND eepdatetimecreated >= @createdate
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN earnprog (NOLOCK) on cepearngroupcode = eecearngroupcode	 AND cepautoadd='Y'
JOIN Empearn (NOLOCK) on cepearncode = eeeearncode AND eeeeeid = eeceeid AND eeecoid = eeccoid
WHERE eecemplstatus = 'A' AND eeestopdate is not null
AND eepdatetimecreated >= @createdate

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
print getdate()
RAISERROR ('Employee QA thru 00399', 0, 1) WITH NOWAIT
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
--Tax validations

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Taxes'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00400'
		,ErrorMessage = 'Incorrect SUI setup - SUI Tax Code Not Found'
		,ErrorKeyLabel = 'Tax Code'
		,ErrorKeyFieldName= 'eecStateSUI'
		,ErrorKeyValue = isnull(eecStateSUI,'') 
		,Details = 'SUI Tax Code ' + isnull(eecStateSUI,'')+'' + case when eettaxcode is null then ' Not found in EmpTax' else ' Found in Emptax but not flagged as IsEmpCompTaxCode' end
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
-- select count(*)
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
LEFT outer JOIN emptax (NOLOCK) on eeceeid = eeteeid AND eeccoid = eetcoid AND eecstateSUI = eettaxcode
WHERE (eetisempcomptaxcode = 'N' or eettaxcode is null) AND CmpCountryCode = 'USA'
AND @Country = 'USA'
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Taxes'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00401'
		,ErrorMessage = 'Employee Address does not match resident state tax set up'
		,ErrorKeyLabel = 'SIT Resident State Code'
		,ErrorKeyFieldName= 'EecSITResidentStateCode'
		,ErrorKeyValue = isnull(EecSITResidentStateCode,'') 
		,Details = 'Address State: ' + isnull(EepAddressState,'')+'' + ' does not match SIT Resident State Tax: ' + LEFT(EecSITResidentStateCode, 2)
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
-- select count(*)
FROM EmpComp (NOLOCK)
JOIN EmpPers (NOLOCK) ON eepEEID = EecEEID AND eepHomeCoID = EecCoID
JOIN Company (NOLOCK) ON CmpCoID = EecCoID
WHERE EecEmplStatus <> 'T' AND EecSITResidentStateCode IS NOT NULL AND EepAddressState <> LEFT(EecSITResidentStateCode, 2)
AND @Country = 'USA'
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Taxes'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00407'
		,ErrorMessage = 'Employee in a company marked as SUI Reimbursable AND employee flagged as exempt FROM SUI'
		,ErrorKeyLabel = 'Exempt FROM Tax'
		,ErrorKeyFieldName= 'EetExemptFROMTax'
		,ErrorKeyValue = EetExemptFROMTax
		,Details = 'Employee taxcode marked exempt: ' + EetTaxCode
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid=''
	-- select count(*)
FROM EmpComp (NOLOCK)
JOIN EmpPers (NOLOCK) ON eepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCoID = EecCoID AND CmpIsSUIReimburse = 'Y'
JOIN EmpMLoc (NOLOCK) ON emlEEID = EecEEID AND emlCoID = EecCoID AND emlIsPrimary = 'Y'
JOIN EmpTax  (NOLOCK) ON EetEEID = EecEEID AND EetCoID = EecCoID AND EetTaxCode = LEFT(LTRIM(emlSITWorkInStateCode),2) + 'SUIER' AND EetExemptFROMTax = 'Y'
WHERE @Country = 'USA'
AND eepdatetimecreated >= @createdate
ORDER BY CmpCompanyName, EepNameLast, EepNameFirst
 


INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Taxes'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00408'
		,ErrorMessage = 'Invalid employee tax filing status.'
		,ErrorKeyLabel = 'Filing Status'
		,ErrorKeyFieldName= 'EetFilingStatus'
		,ErrorKeyValue = EetFilingStatus
		,Details = 'Taxcode: ' + EetTaxCode + ' Invalid Filing Status: ' + EmpTax.EetFilingStatus
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid=''
-- select count(*)
FROM EmpTax (NOLOCK)
JOIN EmpComp (NOLOCK) ON EecEEID = EetEEID AND EecCoID = EetCoID
JOIN EmpPers (NOLOCK) ON eepEEID = EecEEID
JOIN Company (NOLOCK) ON CmpCoID = EecCoID
LEFT OUTER JOIN 
(
SELECT Ultipro_System.dbo.TxWhMast.MtwTaxCode, 
       Ultipro_System.dbo.TxWhMast.MtwFilingStatus, 
       Ultipro_System.dbo.TxWhMast.MtwStatusDescription 
FROM   Ultipro_System.dbo.TxWhMast (NOLOCK)
JOIN  (SELECT MtwTaxCode, Max(AuditKey) MaxKey, MtwFilingStatus 
       FROM   Ultipro_System.dbo.TxWhMast (NOLOCK)
       GROUP  BY MtwTaxCode, MtwFilingStatus) MaxRecord ON MaxKey = AuditKey
) SYSTEM_TAX ON SYSTEM_TAX.MtwTaxCode = EetTaxCode AND SYSTEM_TAX.MtwFilingStatus = EmpTax.EetFilingStatus
WHERE SYSTEM_TAX.MtwTaxCode IS NULL
  AND @Country = 'USA'
  AND eepdatetimecreated >= @createdate
ORDER BY EepNameLast, EepNameFirst, CmpCompanyCode, EetTaxCode

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
print getdate()
RAISERROR ('Employee QA thru 00409', 0, 1) WITH NOWAIT
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Taxes'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00410'
		,ErrorMessage = 'Employee SUI code in EmpComp does not match the SUI code in their primary work location'
		,ErrorKeyLabel = 'Eec State SUI'
		,ErrorKeyFieldName= 'EecStateSUI'
		,ErrorKeyValue = isnull(EecStateSUI,'') 
		,Details = ''
		,RoleToReview ='TC\SC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
-- select count(*)
FROM EmpMLoc (NOLOCK)
JOIN EmpPers (NOLOCK) ON eepEEID = EmlEEID 
JOIN EmpComp (NOLOCK) ON eecEEID = EmlEEID AND eecCoID = EmlCoID AND EecLocation = EmlCode
JOIN Company (NOLOCK) ON cmpcoid = eeccoid AND CmpAddressCountry = 'USA'
WHERE EmlIsPrimary = 'Y' AND (SUBSTRING(EecStateSUI, 1, 2) <> SUBSTRING(EmlSITWorkInStateCode, 1, 2))
AND @Country = 'USA'
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Taxes'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00411'
		,ErrorMessage = 'Employees are flagged as exempt. Please ensure setup is correct.'
		,ErrorKeyLabel = 'EetTaxCode'
		,ErrorKeyFieldName= 'EetTaxCode'
		,ErrorKeyValue = isnull(EetTaxCode,'') 
		,Details = 'Exempt FROM Tax: ' + EetExemptFROMTax  
		,RoleToReview ='SC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
-- select count(*)
FROM Emptax (NOLOCK)
JOIN EmpPers (NOLOCK) ON eepEEID = EetEEID 
JOIN EmpComp (NOLOCK) ON eecEEID = EetEEID AND eecCoID = EetCoID 
JOIN Company (NOLOCK) ON cmpcoid = eeccoid AND CmpCountryCode = 'USA'
WHERE EecEmplStatus <> 'T' AND (EetExemptFROMTax = 'Y')
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Taxes'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='01411'
		,ErrorMessage = 'Employees are flagged as blocked. Please ensure setup is correct.'
		,ErrorKeyLabel = 'EetTaxCode'
		,ErrorKeyFieldName= 'EetTaxCode'
		,ErrorKeyValue = isnull(EetTaxCode,'') 
		,Details = 'Blocked FROM Tax: ' + EETBLOCKTAXAMT
		,RoleToReview ='SC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
-- select count(*)
FROM Emptax (NOLOCK)
JOIN EmpPers (NOLOCK) ON eepEEID = EetEEID 
JOIN EmpComp (NOLOCK) ON eecEEID = EetEEID AND eecCoID = EetCoID 
JOIN Company (NOLOCK) ON cmpcoid = eeccoid AND CmpCountryCode = 'USA'
WHERE EecEmplStatus <> 'T' AND (EETBLOCKTAXAMT='Y')
AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Taxes'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00412'
		,ErrorMessage = 'Employees are flagged as not subjext to tax. Please ensure setup is correct.'
		,ErrorKeyLabel = 'EetTaxCode'
		,ErrorKeyFieldName= 'EetTaxCode'
		,ErrorKeyValue = isnull(EetTaxCode,'') 
		,Details = 'Not Subject ToTax: ' + EetNotSubjectToTax + ' Is Resident Tax: ' + EetIsResidentTaxCode + ' Is Work-in Tax: ' +  EetIsWorkInTaxCode
		,RoleToReview ='Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
-- select count(*)
FROM Emptax (NOLOCK)
JOIN EmpPers (NOLOCK) ON eepEEID = EetEEID 
JOIN EmpComp (NOLOCK) ON eecEEID = EetEEID AND eecCoID = EetCoID 
JOIN Company (NOLOCK) ON cmpcoid = eeccoid AND CmpAddressCountry = 'USA'
WHERE EecEmplStatus <> 'T' AND EetNotSubjectToTax = 'Y'
AND Eettaxcode like '%SIT' 
AND @Country = 'USA'
AND eepdatetimecreated >= @createdate
Order by CmpCompanyCode, Eecempno, EetTaxCode

 


INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Taxes'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00416'
		,ErrorMessage = 'Employee has resident state tax not set up for company. Either correct EE address or add state to company setup.'
		,ErrorKeyLabel = 'SIT Resident Code'
		,ErrorKeyFieldName= 'EecSITResidentStateCode'
		,ErrorKeyValue = isnull(EecSITResidentStateCode,'') 
		,Details = ''
		,RoleToReview ='SC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
-- select count(*)
FROM Empcomp (NOLOCK)
JOIN EmpPers (NOLOCK) ON eepEEID = EecEEID 
JOIN Company (NOLOCK) ON cmpcoid = eeccoid AND CmpAddressCountry = 'USA'
WHERE EecEmplStatus <> 'T' AND EecSITResidentStateCode is not null
  AND not exists (select 1 FROM TaxCode (NOLOCK)
		   WHERE CtcTaxCode = EecSITResidentStateCode AND CtcCOID = Eeccoid)
		  AND eepdatetimecreated >= @createdate


INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Taxes'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00417'
		,ErrorMessage = 'Employee location tax setup does not match the location tax set up on the Location business rule'
		,ErrorKeyLabel = 'Employee location based taxes'
		,ErrorKeyFieldName= 'emlLITWorkInCounty, emlLITOCCCOde, emlLITOtherCode, emlLITWCCCode'
		,ErrorKeyValue = '' 
		,Details = 'LocLITWorkInCounty: '	+ isnull(LocLITWorkInCounty,'')	+ 'vs. emlLITWorkInCounty: '	+ isnull(emlLITWorkInCounty,'')	+ ' || '
				+  'locLITOCCCode: '		+ isnull(locLITOCCCode,'')		+ 'vs. emlLITOCCCOde: '			+ isnull(emlLITOCCCOde,'')	+ ' || '
				+  'LocLITOtherCode: '		+ isnull(LocLITOtherCode,'')	+ 'vs. emlLITOtherCode: '		+ isnull(emlLITOtherCode,'') + ' || '
				+  'LocLITWCCCode: '		+ isnull(LocLITWCCCode,'')		+ 'vs. emlLITWCCCode: '			+ isnull(emlLITWCCCode,'') +' || '
				+  'Comments:'	
				+	isnull(Case When LocLITWorkInCounty <> emlLITWorkInCounty then 'Location county does not match from employee to company setup' end,'') + ' || '
				+   isnull(Case when emlLITOCCCOde <> locLITOCCCode then 'Occupational Code on Employee Level Does Not Match Company' end,'') + ' || '
				+	isnull(Case when emlLITOtherCode <> LocLITOtherCode then 'Other Code on employee level does not match company' end,'') + ' || '
				+	isnull(Case when emlLITWCCCode <> LocLITWCCCode then 'WCC Code on employee level does not match company'  end,'')
		,RoleToReview ='SC\TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
-- select count(*)
FROM Empcomp (NOLOCK)
JOIN EmpMLoc (NOLOCK) on emlcoid = eeccoid AND emleeid = eeceeid AND emlcode = eeclocation
JOIN EmpPers (NOLOCK) ON eepEEID = EecEEID 
JOIN [Location] (NOLOCK) on loccode = emlCode
JOIN Company (NOLOCK) ON cmpcoid = eeccoid AND CmpAddressCountry = 'USA'
WHERE EecEmplStatus <> 'T'
  AND (LocLITWorkInCounty <> emlLITWorkInCounty 
		or emlLITOCCCOde <> locLITOCCCode 
		or emlLITOtherCode <> LocLITOtherCode 
		or emlLITWCCCode <> LocLITWCCCode)
  AND eepdatetimecreated >= @createdate


  --((eeclitresidentcounty is null) or (eeclitresidentcounty = ' '))  to replace where the test says eeclitresidentcounty is null

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Taxes'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00418'
		,ErrorMessage = 'Employee is in PA or MD and resident county not set up.  Use Web Import tool to update resident tax information.
		                 Reach out to your LSC for help.'
		,ErrorKeyLabel = 'LIT Resident County'
		,ErrorKeyFieldName= 'EecLITResidentCounty'
		,ErrorKeyValue = isnull(EecLITResidentCounty,'') 
		,Details = 'Address State: ' + EEPADDRESSSTATE
		,RoleToReview ='SC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
-- select count(*)
FROM Empcomp (NOLOCK)
JOIN EmpPers (NOLOCK) ON eepEEID = EecEEID 
JOIN Company  (NOLOCK) ON cmpcoid = eeccoid AND CmpAddressCountry = 'USA'
join location (nolock) on eeclocation = loccode
WHERE eecemplstatus <> 'T'
AND EEPADDRESSSTATE in ('PA','MD')
and substring(locsitworkinstatecode, 1, 2) = eepaddressstate   
--AND  EECLITRESIDENTCOUNTY is null
AND ((eeclitresidentcounty is null) or (eeclitresidentcounty = ' ') or (eeclitresidentcounty = '')) 
AND @Country = 'USA'
AND eepdatetimecreated >= @createdate

  --((eeclitresidentcounty is null) or (eeclitresidentcounty = ' '))  to replace where the test says eeclitresidentcounty is null

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Taxes'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00419'
		,ErrorMessage = 'Employee lives in PA and works out of state with resident county not set up. Review with client.'
		,ErrorKeyLabel = 'LIT Resident County'
		,ErrorKeyFieldName= 'EecLITResidentCounty'
		,ErrorKeyValue = isnull(EecLITResidentCounty,'') 
		,Details = 'Address State: ' + EEPADDRESSSTATE +' Work SIT: ' + locsitworkinstatecode
		,RoleToReview ='SC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
-- select count(*)
FROM Empcomp (NOLOCK)
JOIN EmpPers (NOLOCK) ON eepEEID = EecEEID 
JOIN Company  (NOLOCK) ON cmpcoid = eeccoid AND CmpAddressCountry = 'USA'
join location (nolock) on eeclocation = loccode
WHERE eecemplstatus <> 'T'
AND EEPADDRESSSTATE = 'PA'
and substring(locsitworkinstatecode, 1, 2) <> eepaddressstate  
--AND  EECLITRESIDENTCOUNTY is null
AND ((eeclitresidentcounty is null) or (eeclitresidentcounty = ' ') or (eeclitresidentcounty = '')) 
AND @Country = 'USA'
AND eepdatetimecreated >= @createdate


-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
print getdate()
RAISERROR ('Employee QA thru 00419', 0, 1) WITH NOWAIT
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Taxes'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00420'
		,ErrorMessage = 'Missing WC tax codes for employees in NM, OR, WA'
		,ErrorKeyLabel = 'WC Code'
		,ErrorKeyFieldName= 'emlLITWCCCode'
		,ErrorKeyValue = isnull(emlLITWCCCode,'') 
		,Details = 'State: ' + substring(emlSITWorkInStateCode,1,2)
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
-- select count(*)
FROM Empcomp (NOLOCK)
JOIN EmpPers (NOLOCK) ON eepEEID = EecEEID 
JOIN Company (NOLOCK) ON cmpcoid = eeccoid AND CmpAddressCountry = 'USA'
JOIN empmloc (NOLOCK) on emlcoid = eeccoid AND emleeid = eeceeid AND isnull(emlLITWCCCode,'') = '' AND substring(emlSITWorkInStateCode,1,2) in ('NM','OR','WA')
AND @Country = 'USA'
AND eepdatetimecreated >= @createdate

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
print getdate()
RAISERROR ('Employee QA thru 00420', 0, 1) WITH NOWAIT
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

--INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
--SELECT CompanyCode = CmpCompanyCode 
--        ,PayGroup = isnull(eecpaygroup, '')
--		,RecordType = 'Taxes'
--		,EmpNo = RTRIM(EecEmpNo)
--		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
--		,EmploymentStatus = EecEmplStatus
--		,DependentName = ''
--		,Severity = 'E'
--		,ErrorNumber='00421'
--		,ErrorMessage = 'Invalid Supplemental Wage Tax Method'
--		,ErrorKeyLabel = 'Supplemental Wage Tax Method'
--		,ErrorKeyFieldName= 'EetSuppWageTaxMethod'
--		,ErrorKeyValue = EetSuppWageTaxMethod
--		,Details = 'Taxcode: ' + EetTaxCode + ' Invalid Supplemental Wage Tax Method: ' + EmpTax.EetSuppWageTaxMethod + '     - Valid values are: '+
--			CASE WHEN MtcPSuppWageTaxMthdOpt LIKE '%P%' or MtcPSuppWageTaxMthdOpt LIKE '%S%' or MtcPSuppWageTaxMthdOpt LIKE '%E%'THEN 'P,' ELSE '' END
--			+
--			CASE WHEN MtcPSuppWageTaxMthdOpt LIKE '%R%' or MtcPSuppWageTaxMthdOpt LIKE '%N%'									 THEN 'R,' ELSE '' END
--			+
--			CASE WHEN MtcASuppWageTaxMthdOpt LIKE '%A%' or MtcASuppWageTaxMthdOpt LIKE '%C%' or MtcASuppWageTaxMthdOpt LIKE '%Y%'THEN 'A' ELSE '' END
			 
--		,RoleToReview ='TC\SC'
--		,EEID = EecEEID
--		,COID = EecCOID
--		,ConSystemid=''
---- select count(*)
--FROM EmpTax (NOLOCK)
--JOIN EmpComp (NOLOCK) ON EecEEID = EetEEID AND EecCoID = EetCoID
--JOIN EmpPers (NOLOCK) ON eepEEID = EecEEID
--JOIN Company (NOLOCK) ON CmpCoID = EecCoID
--JOIN ULTIPRO_SYSTEM.dbo.txWhMast (NOLOCK) ON mtwtaxcode = eettaxcode
--JOIN ULTIPRO_SYSTEM.dbo.txCdMast (NOLOCK) ON MtwTaxCode+convert(char(15), MtwDateTimeCreated) = MtcTaxCode+Convert(Char(15), MtcDateTimeCreated)
--								AND MtwDateTimeCreated = ( SELECT MAX(MtcDateTimeCreated)
--															 FROM ULTIPRO_SYSTEM.dbo.txcdmast (NOLOCK) 
--															WHERE mtcTaxCode = mtwTaxCode
--															  AND MtcHasBeenReplaced = 'N')
--WHERE EetTaxcode like '%SIT' 
--  AND EetFilingStatus = MtwFilingStatus
--  AND ISNULL(EetSuppWageTaxMethod,'') <> CASE
--											WHEN MtcPSuppWageTaxMthdOpt LIKE '%P%' or MtcPSuppWageTaxMthdOpt LIKE '%S%' or MtcPSuppWageTaxMthdOpt LIKE '%E%'THEN 'P' 
--											WHEN MtcPSuppWageTaxMthdOpt LIKE '%R%' or MtcPSuppWageTaxMthdOpt LIKE '%N%'										THEN 'R' 
--											WHEN MtcASuppWageTaxMthdOpt LIKE '%A%' or MtcASuppWageTaxMthdOpt LIKE '%C%' or MtcASuppWageTaxMthdOpt LIKE '%Y%'THEN 'A'
--											ELSE MtcASuppWageTaxMthdOpt
--											END

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
print getdate()
RAISERROR ('Employee QA thru 00421', 0, 1) WITH NOWAIT
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode

        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Taxes'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00422'
		,ErrorMessage = 'Employee tax location does not exist in location table.'
		,ErrorKeyLabel = 'Eec State SUI'
		,ErrorKeyFieldName= 'EecStateSUI'
		,ErrorKeyValue = isnull(EecStateSUI,'') 
		,Details = ''
		,RoleToReview ='TC\SC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
-- select count(*)
FROM EmpMLoc (NOLOCK)
JOIN EmpPers (NOLOCK) ON eepEEID = EmlEEID 
JOIN EmpComp (NOLOCK) ON eecEEID = EmlEEID AND eecCoID = EmlCoID AND EecLocation = EmlCode
JOIN Company (NOLOCK) ON cmpcoid = eeccoid AND CmpAddressCountry = 'USA'
WHERE EmlIsPrimary = 'Y' 
  and not exists (select 'X' from dbo.[Location] where LocCode = EecLocation)
  AND eepdatetimecreated >= @createdate

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
print getdate()
RAISERROR ('Employee QA thru 00422', 0, 1) WITH NOWAIT
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Taxes'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00423'
		,ErrorMessage = 'EetIsResidentTaxCode should be N for Canada'
		,ErrorKeyLabel = 'Is Marked as Resident Taxcode'
		,ErrorKeyFieldName= 'EetIsResidentTaxCode'
		,ErrorKeyValue = EetIsResidentTaxCode
		,Details = 'Employee taxcode: ' + EetTaxCode
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid=''
		-- select EetIsResidentTaxCode
FROM EmpComp (NOLOCK)
JOIN EmpPers (NOLOCK) ON eepEEID = EecEEID 
join EmpIntl (NOLOCK) on EecEEID = EinEEID 
JOIN Company (NOLOCK) ON CmpCoID = EecCoID AND CmpCountryCode = 'CAN'
JOIN EmpTax  (NOLOCK) ON EetEEID = EecEEID AND EetCoID = EecCoID AND EetIsResidentTaxCode <> 'N'
WHERE @Country = 'CAN'
  AND eepdatetimecreated >= @createdate
--ORDER BY CmpCompanyName, EepNameLast, EepNameFirst

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
print getdate()
RAISERROR ('Employee QA thru 00423', 0, 1) WITH NOWAIT
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Taxes'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00424'
		,ErrorMessage = 'ArnID is missing.'
		,ErrorKeyLabel = 'arnid'
		,ErrorKeyFieldName= 'arnid'
		,ErrorKeyValue = arnid
		,Details = ''
		,RoleToReview ='TC\SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid=''
		-- select arnid
FROM EmpComp (NOLOCK)
JOIN EmpPers (NOLOCK) ON eepEEID = EecEEID 
JOIN EmpIntl (NOLOCK) on EecEEID = EinEEID 
JOIN dbo.fnemployeeARN() on eeceeid=eeid and eeccoid=coid
JOIN Company (NOLOCK) ON CmpCoID = EecCoID 
WHERE arnid is NULL
  AND @Country = 'CAN'
  AND eepdatetimecreated >= @createdate
--ORDER BY CmpCompanyName, EepNameLast, EepNameFirst

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
print getdate()
RAISERROR ('Employee QA thru 00424', 0, 1) WITH NOWAIT
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Taxes'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00425'
		,ErrorMessage = 'StateSui is not in the correct format.'
		,ErrorKeyLabel = 'StateSui'
		,ErrorKeyFieldName= 'EecStateSui'
		,ErrorKeyValue = EecStateSui
		,Details = ''
		,RoleToReview ='TC\SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid=''
FROM EmpComp (NOLOCK)
JOIN EmpPers (NOLOCK) ON eepEEID = EecEEID 
JOIN EmpIntl (NOLOCK) on EecEEID = EinEEID 
JOIN Company (NOLOCK) ON CmpCoID = EecCoID 
WHERE EecStateSui not like '%PIT'
  AND @Country = 'CAN'
  AND eepdatetimecreated >= @createdate
--ORDER BY CmpCompanyName, EepNameLast, EepNameFirst


INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Taxes'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00426'
		,ErrorMessage = 'EetIsEmpCompTaxCode should be Y except for QCCTER.'
		,ErrorKeyLabel = 'Is EmpComp Tax Code'
		,ErrorKeyFieldName= 'EetIsEmpCompTaxCode'
		,ErrorKeyValue = EetIsEmpCompTaxCode
		,Details = 'Employee taxcode: ' + EetTaxCode
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid=''
		-- select count(*)
FROM EmpComp (NOLOCK)
JOIN EmpPers (NOLOCK) ON eepEEID = EecEEID 
join EmpIntl (NOLOCK) on EecEEID = EinEEID AND EinCountryCode = 'CAN'
JOIN Company (NOLOCK) ON CmpCoID = EecCoID AND CmpCountryCode = 'CAN'
JOIN EmpTax  (NOLOCK) ON EetEEID = EecEEID AND EetCoID = EecCoID AND EetTaxCode <> 'QCCTER' AND EetIsEmpCompTaxCode <> 'Y'
WHERE EecEmplStatus <> 'T'
  AND @Country = 'CAN'
  AND eepdatetimecreated >= @createdate
--ORDER BY CmpCompanyName, EepNameLast, EepNameFirst

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Taxes'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00427'
		,ErrorMessage = 'EetIsEmpCompTaxCode should be N for QCCTER'
		,ErrorKeyLabel = 'Is EmpComp Tax Code'
		,ErrorKeyFieldName= 'EetIsEmpCompTaxCode'
		,ErrorKeyValue = EetIsEmpCompTaxCode
		,Details = 'Employee taxcode: ' + EetTaxCode
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid=''
		-- select count(*)
FROM EmpComp (NOLOCK)
JOIN EmpPers (NOLOCK) ON eepEEID = EecEEID 
join EmpIntl (NOLOCK) on EecEEID = EinEEID AND EinCountryCode = 'CAN'
JOIN Company (NOLOCK) ON CmpCoID = EecCoID AND CmpCountryCode = 'CAN'
JOIN EmpTax  (NOLOCK) ON EetEEID = EecEEID AND EetCoID = EecCoID AND EetTaxCode = 'QCCTER' AND EetIsEmpCompTaxCode <> 'N'
WHERE EecEmplStatus <> 'T'
  AND @Country = 'CAN'
  AND eepdatetimecreated >= @createdate
--ORDER BY CmpCompanyName, EepNameLast, EepNameFirst

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Taxes'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00428'
		,ErrorMessage = 'EetIsWorkInTaxCode should be N'
		,ErrorKeyLabel = 'Is Marked as Resident Taxcode'
		,ErrorKeyFieldName= 'EetIsWorkInTaxCode'
		,ErrorKeyValue = EetIsWorkInTaxCode
		,Details = 'Employee taxcode: ' + EetTaxCode
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid=''
		-- select count(*)
FROM EmpComp (NOLOCK)
JOIN EmpPers (NOLOCK) ON eepEEID = EecEEID 
join EmpIntl (NOLOCK) on EecEEID = EinEEID AND EinCountryCode = 'CAN'
JOIN Company (NOLOCK) ON CmpCoID = EecCoID AND CmpCountryCode = 'CAN'
JOIN EmpTax  (NOLOCK) ON EetEEID = EecEEID AND EetCoID = EecCoID AND EetIsWorkInTaxCode <> 'N'
WHERE EecEmplStatus <> 'T'
  AND @Country = 'CAN'
  AND eepdatetimecreated >= @createdate
--ORDER BY CmpCompanyName, EepNameLast, EepNameFirst

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Taxes'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00429'
		,ErrorMessage = 'Total Claim Amount should be zero when Use Basic Personal Amount is selected.'
		,ErrorKeyLabel = 'Total Claim Amount'
		,ErrorKeyFieldName= 'EetTotClaimAmt'
		,ErrorKeyValue = EetTotClaimAmt
		,Details = 'Employee taxcode: ' + EetTaxCode + '  EetUseBasicPersonalAmt: ' + EetUseBasicPersonalAmt
		,RoleToReview ='SC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid=''
		-- select count(*)
FROM EmpComp (NOLOCK)
JOIN EmpPers (NOLOCK) ON eepEEID = EecEEID 
join EmpIntl (NOLOCK) on EecEEID = EinEEID AND EinCountryCode = 'CAN'
JOIN Company (NOLOCK) ON CmpCoID = EecCoID AND CmpCountryCode = 'CAN'
JOIN EmpTax  (NOLOCK) ON EetEEID = EecEEID AND EetCoID = EecCoID AND EetUseBasicPersonalAmt = 'Y' AND EetTotClaimAmt <> 0
WHERE EecEmplStatus <> 'T'
  AND @Country = 'CAN'
  AND eepdatetimecreated >= @createdate
--ORDER BY CmpCompanyName, EepNameLast, EepNameFirst

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
print getdate()
RAISERROR ('Employee QA thru 00429', 0, 1) WITH NOWAIT
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
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
-- select count(*)
FROM Empcomp (NOLOCK)
JOIN EmpPers (NOLOCK) ON eepEEID = EecEEID 
JOIN Company (NOLOCK) ON cmpcoid = eeccoid AND CmpAddressCountry = 'USA'
JOIN empmloc (NOLOCK) on emlcoid = eeccoid AND emleeid = eeceeid 
WHERE (emllitworkincounty = '' or emllitworkincode = '' or emllitworkincounty is NULL or emllitworkincode is NULL OR EecLITResidentCounty IS NULL OR EecLITResidentCounty = '') 
  AND EecLITSDCode = 'KY107'
  AND eepdatetimecreated >= @createdate
  AND @Country = 'USA'

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Taxes'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00431'
		,ErrorMessage = 'Is EmpComp Tax = N for Federal Taxes for employee in US'
		,ErrorKeyLabel = 'Tax Code'
		,ErrorKeyFieldName= 'eettaxcode'
		,ErrorKeyValue = isnull(eettaxcode,'') 
		,Details = 'Tax Code is Empcomp:' + eetisempcomptaxcode
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
	-- select count(*)
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID AND CmpCountryCode = 'USA'
JOIN emptax (NOLOCK) on eeceeid = eeteeid AND eeccoid = eetcoid and eettaxcode like 'US%'
WHERE (eetisempcomptaxcode = 'N' or eetisempcomptaxcode is null) 
  AND @Country = 'USA'
  AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Taxes'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00432'
		,ErrorMessage = 'Is EmpComp Tax = N  for Local Work In tax code'
		,ErrorKeyLabel = 'Tax Code'
		,ErrorKeyFieldName= 'eettaxcode'
		,ErrorKeyValue = isnull(eettaxcode,'') 
		,Details = 'Tax Code is Empcomp:' + eetisempcomptaxcode
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
-- select count(*)
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID AND CmpCountryCode = 'USA'
JOIN Emptax (NOLOCK) on eeceeid = eeteeid AND eeccoid = eetcoid 
JOIN Empmloc (NOLOCK) on eeceeid = emleeid AND eeccoid = emlcoid AND emlisprimary = 'Y' AND eettaxcode = emllitworkincode 
WHERE (eetisempcomptaxcode = 'N' or eetisempcomptaxcode is null) 
  AND @Country = 'USA'
  AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Taxes'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00433'
		,ErrorMessage = 'Is EmpComp Tax = N  for Local Occupational tax code'
		,ErrorKeyLabel = 'Tax Code'
		,ErrorKeyFieldName= 'eettaxcode'
		,ErrorKeyValue = isnull(eettaxcode,'') 
		,Details = 'Tax Code is Empcomp:' + eetisempcomptaxcode
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
-- select count(*)
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID AND CmpCountryCode = 'USA'
JOIN Emptax (NOLOCK) on eeceeid = eeteeid AND eeccoid = eetcoid 
JOIN Empmloc (NOLOCK) on eeceeid = emleeid AND eeccoid = emlcoid AND emlisprimary = 'Y' AND eettaxcode = emllitocccode
WHERE (eetisempcomptaxcode = 'N' or eetisempcomptaxcode is null) 
  AND @Country = 'USA'
  AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Taxes'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00434'
		,ErrorMessage = 'Is EmpComp Tax = N  for Local Other tax code'
		,ErrorKeyLabel = 'Tax Code'
		,ErrorKeyFieldName= 'eettaxcode'
		,ErrorKeyValue = isnull(eettaxcode,'') 
		,Details = 'Tax Code is Empcomp:' + eetisempcomptaxcode
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
-- select count(*)
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID AND CmpCountryCode = 'USA'
JOIN Emptax (NOLOCK) on eeceeid = eeteeid AND eeccoid = eetcoid 
JOIN Empmloc (NOLOCK) on eeceeid = emleeid AND eeccoid = emlcoid AND emlisprimary = 'Y' AND eettaxcode = emlLITOtherCode
WHERE (eetisempcomptaxcode = 'N' or eetisempcomptaxcode is null) 
  AND @Country = 'USA'
  AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Taxes'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00435'
		,ErrorMessage = 'Is EmpComp Tax = N  for Local WCC tax code'
		,ErrorKeyLabel = 'Tax Code'
		,ErrorKeyFieldName= 'eettaxcode'
		,ErrorKeyValue = isnull(eettaxcode,'') 
		,Details = 'Tax Code is Empcomp:' + eetisempcomptaxcode
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
-- select count(*)
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID AND CmpCountryCode = 'USA'
JOIN Emptax (NOLOCK) on eeceeid = eeteeid AND eeccoid = eetcoid 
JOIN Empmloc (NOLOCK) on eeceeid = emleeid AND eeccoid = emlcoid AND emlisprimary = 'Y' AND eettaxcode = emlLITWCCCode
WHERE (eetisempcomptaxcode = 'N' or eetisempcomptaxcode is null) 
  AND @Country = 'USA'
  AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Taxes'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00436'
		,ErrorMessage = 'Is EmpComp Tax = N  for Local SD tax code'
		,ErrorKeyLabel = 'Tax Code'
		,ErrorKeyFieldName= 'eettaxcode'
		,ErrorKeyValue = isnull(eettaxcode,'') 
		,Details = 'Tax Code is Empcomp:' + eetisempcomptaxcode
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
-- select count(*)
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID AND CmpCountryCode = 'USA'
JOIN Emptax (NOLOCK) on eeceeid = eeteeid AND eeccoid = eetcoid AND eettaxcode = eeclitsdcode
JOIN Empmloc (NOLOCK) on eeceeid = emleeid AND eeccoid = emlcoid AND emlisprimary = 'Y'
WHERE (eetisempcomptaxcode = 'N' or eetisempcomptaxcode is null) 
  AND @Country = 'USA'
  AND eepdatetimecreated >= @createdate
 
INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Taxes'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00437'
		,ErrorMessage = 'Text NULL entered in SQL in EmpMLoc (TC to remove)'
		,ErrorKeyLabel = 'LIT Codes'
		,ErrorKeyFieldName= 'EMLLITOTHERCODE or emllitocccode or emllitwcccode or emllitworkincode'
		,ErrorKeyValue = ''
		,Details = 'emllitothercode: '+ EMLLITOTHERCODE +
				'   emllitocccode: ' + emllitocccode +
				'	emllitwcccode: ' + emllitwcccode +
				'   emllitworkincode: ' + emllitworkincode
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid=''
-- select count(*)
FROM EmpComp (NOLOCK)
JOIN EmpPers (NOLOCK) ON eepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCoID = EecCoID AND cmpcountrycode = 'USA'
JOIN EmpMLoc (NOLOCK) ON emlEEID = EecEEID AND emlCoID = EecCoID AND emlIsPrimary = 'Y'
WHERE ((EMLLITOTHERCODE = 'NULL') or (emllitocccode = 'NULL') or (emllitwcccode = 'NULL') or (emllitworkincode = 'NULL'))
  AND @Country = 'USA'
  AND eepdatetimecreated >= @createdate
ORDER BY CmpCompanyName, EepNameLast, EepNameFirst


INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Taxes'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00438'
		,ErrorMessage = 'Please correct Employee record to ensure proper SDI code is attached to the employee.'
		,ErrorKeyLabel = 'Tax Code'
		,ErrorKeyFieldName= 'eecStateSDI'
		,ErrorKeyValue = isnull(eecStateSDI,'') 
		,Details = 'AddressState = '+eepaddressstate+' - Work State Tax Code = '+EecSITWorkInStateCode
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
-- select count(*)
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
join location on eeclocation = loccode
WHERE substring(eecstatesdi, 1, 2) <> substring(locsitworkinstatecode, 1, 2)
  and substring(locsitworkinstatecode, 1, 2) in ('CA', 'HI', 'PR', 'NJ', 'NY', 'RI', 'DC', 'MA', 'WA')
  AND CmpCountryCode = 'USA'
  AND @Country = 'USA'
  AND eepdatetimecreated >= @createdate
  and eecemplstatus = 'A'

--INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
--SELECT CompanyCode = CmpCompanyCode 
 --       ,PayGroup = isnull(eecpaygroup, '')
--		,RecordType = 'Taxes'
--		,EmpNo = RTRIM(EecEmpNo)
--		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
--		,EmploymentStatus = EecEmplStatus
--		,DependentName = ''
--		,Severity = 'E'
--		,ErrorNumber='00438'
--		,ErrorMessage = 'Please correct Employee record to ensure proper SDI code is attached to the employee.'
--		,ErrorKeyLabel = 'Tax Code'
--		,ErrorKeyFieldName= 'eecStateSDI'
--		,ErrorKeyValue = isnull(eecStateSDI,'') 
--		,Details = 'SUI Tax Code ' + isnull(eecStateSUI,'')
--		,RoleToReview ='TC'
--		,EEID = EecEEID
--		,COID = EecCOID
--		,ConSystemid = ''
--FROM EmpComp (NOLOCK) 
--JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID
--JOIN Company (NOLOCK) ON CmpCOID = EecCOID
--WHERE left(eecstatesdi,2) <> left(eecstatesui,2) 
--  AND eecstatesdi <> ' ' 
--  AND eecstatesui <> ' ' 
--  AND eecstatesui is not null 
--  AND eecstatesdi is not null
--  AND CmpCountryCode = 'USA'
--  AND @Country = 'USA'
--  AND eepdatetimecreated >= @createdate
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
print getdate()
RAISERROR ('Employee QA thru 00499', 0, 1) WITH NOWAIT
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
--Pay History Validations

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'PayHistory'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00500'
		,ErrorMessage = 'Deduction found in Pay History but does not exist in EmpDed for this Employee'
		,ErrorKeyLabel = 'Ded Code'
		,ErrorKeyFieldName= 'PdhDedcode'
		,ErrorKeyValue = isnull(PdhDedcode,'') 
		,Details = 'Ded Code ' + isnull(PdhDedcode,'')+'' 
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN (select distinct pdhdedcode, pdhcoid, pdheeid FROM pdedhist (NOLOCK)) as PayDedHist on pdheeid = eeceeid AND pdhcoid = eeccoid
WHERE not exists (select 1 FROM empded (NOLOCK) WHERE eedeeid = pdheeid AND eedcoid = pdhcoid AND eeddedcode = pdhdedcode)
  AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'PayHistory'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00501'
		,ErrorMessage = 'Earning found in Pay History but does not exist in EmpEarn for this Employee'
		,ErrorKeyLabel = 'Earn Code'
		,ErrorKeyFieldName= 'PehEarncode'
		,ErrorKeyValue = isnull(PehEarncode,'') 
		,Details = 'Earn Code ' + isnull(PehEarncode,'')+'' 
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN (select distinct PehEarncode, pehcoid, peheeid FROM pearhist (NOLOCK)) as PayEarnHist on peheeid = eeceeid AND pehcoid = eeccoid 
WHERE not exists (select 1 FROM empearn (NOLOCK) WHERE eeeeeid = peheeid AND eeecoid = pehcoid AND eeeearncode = pehearncode)
  AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'PayHistory'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00502'
		,ErrorMessage = 'Tax Code found in Pay History but does not exist in EmpTax for this Employee'
		,ErrorKeyLabel = 'Tax Code'
		,ErrorKeyFieldName= 'PthTaxCode'
		,ErrorKeyValue = isnull(PthTaxCode,'') 
		,Details = 'Tax Code ' + isnull(PthTaxCode,'')+'' 
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN (select distinct PthTaxCode, pthcoid, ptheeid FROM ptaxhist (NOLOCK)) as PayTaxHist on ptheeid = eeceeid AND pthcoid = eeccoid 
WHERE not exists (select 1 FROM emptax (NOLOCK) WHERE eeteeid = ptheeid AND eetcoid = pthcoid AND eettaxcode = PthTaxCode)
  AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'PayHistory'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00503'
		,ErrorMessage = 'Pay History Deduction EE or ER amount is not 0; however, the company level AND employee level calculation rule is NONE. '
		,ErrorKeyLabel = 'Ded Code'
		,ErrorKeyFieldName= 'PdhDedCode'
		,ErrorKeyValue = isnull(PdhDedCode,'') 
		,Details = 'Ded Code ' + isnull(PdhDedCode,'')+', EE Calc Rule: '+DedEECalcRule+', Total EE Amt: ' +  ltrim(rtrim(isnull(convert(char(20),TotEECurAmt),'')))+', ER Calc Rule: '+DedERCalcRule+', Total ER Amt: ' +  ltrim(rtrim(isnull(convert(char(20),TotERCurAmt),'')))
		,RoleToReview ='TC\SC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN (select distinct pdhcoid, pdheeid, pdhdedcode, sum(pdheecuramt) as TotEECurAmt, sum(pdhercuramt) as TotERCurAmt FROM pdedhist (NOLOCK) group by pdhcoid, pdheeid, pdhdedcode) as PayDedHist on pdheeid = eeceeid AND pdhcoid = eeccoid 
JOIN DedCode (NOLOCK) ON DedDedCode = PdhDedCode
WHERE (DedEECalcRule = '99' AND TotEECurAmt > 0.00 AND DedEEUseEERule = 'N') OR (DedERCalcRule = '99' AND TotERCurAmt > 0.00 AND DedERUseEERule = 'N')

-- Exclude entries that are flagged as voided. PrgIsVoided <> 'Y'
	 
INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'PayHistory'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00504'
		,ErrorMessage = 'Pay Tax History found with a tax amount but no taxable wages'
		,ErrorKeyLabel = 'Tax Code'
		,ErrorKeyFieldName= 'PthTaxCode'
		,ErrorKeyValue = isnull(PthTaxCode,'') 
		,Details = 'Tax Code ' + isnull(PthTaxCode,'')+', Tax Amt: ' +  ltrim(rtrim(isnull(convert(char(20),PthCurTaxAmt),'')))+', Taxable Wages: '+ltrim(rtrim(isnull(convert(char(20),PthCurTaxablewages),'')))
							   + ', Pay Date: ' + ltrim(rtrim(isnull(CONVERT(varchar, prgpaydate, 101),''))) 
							   + ', PerControl: '+prgpercontrol
							   + ', DocNo: '+ prgdocno+ ''
							   + ', Gennumber: ' + prggennumber
		,RoleToReview = CASE WHEN CmpCountryCode = 'CAN' THEN 'SC Canada' ELSE 'TC' END
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN payreg (NOLOCK) on prgeeid = eeceeid AND prgcoid = eeccoid --AND PrgPerControl LIKE CONCAT(YEAR(@LIVEDATE), '%') 
JOIN ptaxhist (NOLOCK) on prggennumber = pthgennumber
WHERE pthcurtaxamt>0 AND pthcurtaxablewages=0 AND prgcheckaddmode not in ('T','Q')
 AND PrgPerControl LIKE CONCAT(YEAR(@LIVEDATE), '%')
 AND ISNULL(PrgIsVoided,'') <> 'Y'
 and cmpcountrycode = @Country 
 -- AND pthtaxcode not in ('USMEDEE','USMEDER','USSOCEE','USSOCER')

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'PayHistory'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00505'
		,ErrorMessage = 'Non State income tax has amount under W2 wages field'
		,ErrorKeyLabel = 'Tax Code'
		,ErrorKeyFieldName= 'PthTaxCode'
		,ErrorKeyValue = isnull(PthTaxCode,'') 
		,Details = 'Tax Code ' + isnull(PthTaxCode,'')+', Tax Amt: ' +  ltrim(rtrim(isnull(convert(char(20),PthCurTaxAmt),'')))+', Taxable Wages: '+ltrim(rtrim(isnull(convert(char(20),PthCurTaxablewages),'')))
							   + ', Pay Date: ' + ltrim(rtrim(isnull(CONVERT(varchar, prgpaydate, 101),''))) 
							   + ', PerControl: '+prgpercontrol
							   + ', DocNo: '+ prgdocno+ ''
							   + ', Gennumber: ' + prggennumber
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN payreg (NOLOCK) on prgeeid = eeceeid AND prgcoid = eeccoid 
JOIN ptaxhist (NOLOCK) on prggennumber = pthgennumber
WHERE pthtaxcode in ('TXSIT','TNSIT','AKSIT','FLSIT','NVSIT','SDSIT','WASIT','WYSIT')
  AND pthreportingtaxablewages > 0
  AND PrgPerControl LIKE CONCAT(YEAR(@LIVEDATE), '%')
	 
INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'PayHistory'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00506'
		,ErrorMessage = 'Records in PayReg have a bank ID that does not exist in the banks table at the company level.'
		,ErrorKeyLabel = 'Bank ID'
		,ErrorKeyFieldName= 'PrgCoBankID'
		,ErrorKeyValue = PrgCoBankID
		,Details = 'Pay Date: ' + ltrim(rtrim(isnull(CONVERT(varchar, prgpaydate, 101),''))) 
								+ ', PerControl: '+prgpercontrol
								+ ', DocNo: '+ prgdocno+ ''
								+ ', Gennumber: ' + prggennumber
		,RoleToReview ='SC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid=''
FROM PayReg (NOLOCK)
JOIN EmpComp (NOLOCK) on eeccoid = prgcoid AND eeceeid = prgeeid
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
WHERE PrgCoBankID NOT IN(SELECT BnkCoBankID FROM Bank (NOLOCK))
  AND PrgPerControl LIKE CONCAT(YEAR(@LIVEDATE), '%')
  
INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'PayHistory'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00507'
		,ErrorMessage = 'USFUTA Calculating for check that did not have SUI.'
		,ErrorKeyLabel = 'Gennumber'
		,ErrorKeyFieldName= 'prggennumber'
		,ErrorKeyValue = prggennumber
		,Details = 'USFUTA: ' + ltrim(rtrim(isnull(convert(char(20),pthcurtaxamt),''))) 
		+ ', Pay Date: ' + ltrim(rtrim(isnull(CONVERT(varchar, prgpaydate, 101),''))) 
		+ ', PerControl: '+prgpercontrol
		+ ', DocNo: '+ prgdocno+ ''
		+ ', Gennumber: ' + prggennumber
		,RoleToReview ='SC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid=''
FROM PayReg (NOLOCK)
JOIN EmpComp (NOLOCK) on eeccoid = prgcoid AND eeceeid = prgeeid
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN iptaxhist (NOLOCK) ON pthgennumber = prggennumber AND pthtaxcode = 'USFUTA'
WHERE NOT exists (select 'x' FROM iptaxhist (NOLOCK) WHERE pthtaxcode like '%SUI%' AND pthgennumber = prggennumber)
AND PrgIsTaxReconAdjustment = 'N'
AND pthcurtaxamt <> 0
AND PrgPerControl LIKE CONCAT(YEAR(@LIVEDATE), '%')
AND @Country = 'USA'

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'PayHistory'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00508'
		,ErrorMessage = 'Employee has either employee or employer Social Security taxable wage greater than max wage base for year. Verify taxable wages'
		,ErrorKeyLabel = 'Tax Code'
		,ErrorKeyFieldName= 'PthTaxCode'
		,ErrorKeyValue = isnull(PthTaxCode,'') 
		,Details = 'Employee Taxable wage: ' + cast(cast(SUM(PthCurTaxableWages) as bigint) as varchar(100)) +'' 
				+ ' is greater than Max Wage Base: ' +  cast(cast(isnull(a.MttIfWageBaseIsNotOver,0) as bigint) as varchar(100))
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM PTaxHist (NOLOCK)
JOIN EmpComp (NOLOCK) on eeccoid = pthcoid AND eeceeid = ptheeid
JOIN EmpPers (NOLOCK) on eepeeid = eeceeid
JOIN Company (NOLOCK) on cmpcoid = eeccoid
JOIN ULTIPRO_SYSTEM.dbo.[TxTbMast] a (NOLOCK) on mtttaxcode = PthTaxCode  
								  AND a.MttDateTimeCreated = (select max(a2.MttDateTimeCreated)
															    FROM ULTIPRO_SYSTEM.dbo.[TxTbMast] a2 (NOLOCK)
															WHERE a.mtttaxcode = a2.mtttaxcode
																  AND a2.MttDateTimeCreated < pthpaydate)
WHERE PthTaxCode like 'USSOCE%' AND PthPerControl LIKE CONCAT(YEAR(@LIVEDATE), '%')
AND @Country = 'USA'
GROUP BY cmpcompanycode, eecpaygroup, eeceeid, eeccoid, eecempno, eepnamelast, eepnamefirst, eecemplstatus, year(pthpaydate), a.MttIfWageBaseIsNotOver, PthEmpNo, PthCoID, PthTaxCode
HAVING SUM(PthCurTaxableWages) > a.MttIfWageBaseIsNotOver  

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'PayHistory'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'  
		,ErrorNumber='00509'
		,ErrorMessage = 'Employee has either employee or employer Social Security tax amount variance. Verify taxable wages or tax amounts.'
		,ErrorKeyLabel = 'Tax Code'
		,ErrorKeyFieldName= 'PthTaxCode'
		,ErrorKeyValue = isnull(PthTaxCode,'') 
		,Details = 'Employee tax amount: ' + cast(cast(SUM(PthCurTaxAmt) as money) as varchar(100)) +'' + ' does not match calculated tax using rate of ' +  cast(cast(a.MttTaxPercentOverBase as float) as varchar(100)) + ' for calculated tax of: ' +  cast(cast( (SUM(PthCurTaxableWages) * a.MttTaxPercentOverBase) as money) as varchar(100))
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM PTaxHist (NOLOCK)
JOIN EmpComp (NOLOCK) on eeccoid = pthcoid AND eeceeid = ptheeid
JOIN EmpPers (NOLOCK) on eepeeid = eeceeid
JOIN Company (NOLOCK) on cmpcoid = eeccoid
JOIN ULTIPRO_SYSTEM.dbo.[TxTbMast] a (NOLOCK) on mtttaxcode = PthTaxCode  
								  AND a.MttDateTimeCreated = (select max(a2.MttDateTimeCreated)
															    FROM ULTIPRO_SYSTEM.dbo.[TxTbMast] a2 (NOLOCK)
															WHERE a.mtttaxcode = a2.mtttaxcode
																  AND a2.MttDateTimeCreated < pthpaydate)
WHERE PthTaxCode like 'USSOCE%' AND PthPerControl LIKE CONCAT(YEAR(@LIVEDATE), '%')
AND @Country = 'USA'
GROUP BY cmpcompanycode, eecpaygroup, eeceeid, eeccoid, eecempno, eepnamelast, eepnamefirst, eecemplstatus, year(pthpaydate), a.MttTaxPercentOverBase, PthEmpNo, PthCoID, PthTaxCode
HAVING ABS(SUM(PthCurTaxAmt) - (SUM(PthCurTaxableWages) * a.MttTaxPercentOverBase)) > .05

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'PayHistory'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00510'
		,ErrorMessage = 'Employee has USFUTA taxable wage greater than max wage base for year. Verify taxable wages'
		,ErrorKeyLabel = 'Tax Code'
		,ErrorKeyFieldName= 'PthTaxCode'
		,ErrorKeyValue = isnull(PthTaxCode,'') 
		,Details = 'Employee Taxable wage: ' + cast(cast(SUM(PthCurTaxableWages) as bigint) as varchar(100)) +'' + ' is greater than Max Wage Base: ' +  cast(cast(isnull(a.MttIfWageBaseIsNotOver,0) as bigint) as varchar(100))
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM PTaxHist (NOLOCK)
JOIN EmpComp (NOLOCK) on eeccoid = pthcoid AND eeceeid = ptheeid
JOIN EmpPers (NOLOCK) on eepeeid = eeceeid
JOIN Company (NOLOCK) on cmpcoid = eeccoid
JOIN ULTIPRO_SYSTEM.dbo.[TxTbMast] a (NOLOCK) on mtttaxcode = PthTaxCode  
								  AND a.MttDateTimeCreated = (select max(a2.MttDateTimeCreated)
															    FROM ULTIPRO_SYSTEM.dbo.[TxTbMast] a2 (NOLOCK)
															WHERE a.mtttaxcode = a2.mtttaxcode
																  AND a2.MttDateTimeCreated < pthpaydate)
WHERE PthTaxCode ='USFUTA' AND PthPerControl LIKE CONCAT(YEAR(@LIVEDATE), '%')
AND @Country = 'USA'
GROUP BY cmpcompanycode, eecpaygroup, eeceeid, eeccoid, eecempno, eepnamelast, eepnamefirst, eecemplstatus, year(pthpaydate), a.MttIfWageBaseIsNotOver, PthEmpNo, PthCoID, PthTaxCode
HAVING SUM(PthCurTaxableWages) > a.MttIfWageBaseIsNotOver

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'PayHistory'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'  
		,ErrorNumber='00511'
		,ErrorMessage = 'Employee has USFUTA tax amount variance. Verify taxable wages or tax amount.'
		,ErrorKeyLabel = 'Tax Code'
		,ErrorKeyFieldName= 'PthTaxCode'
		,ErrorKeyValue = isnull(PthTaxCode,'') 
		,Details = 'Employee tax amount: ' + cast(cast(SUM(PthCurTaxAmt) as money) as varchar(100)) +'' + ' does not match calculated tax using rate of ' +  cast(cast(a.MttTaxPercentOverBase as float) as varchar(100)) + ' for calculated tax of: ' +  cast(cast( (SUM(PthCurTaxableWages) * a.MttTaxPercentOverBase) as money) as varchar(100))
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM PTaxHist (NOLOCK)
JOIN EmpComp (NOLOCK) on eeccoid = pthcoid AND eeceeid = ptheeid
JOIN EmpPers (NOLOCK) on eepeeid = eeceeid
JOIN Company (NOLOCK) on cmpcoid = eeccoid
JOIN ULTIPRO_SYSTEM.dbo.[TxTbMast] a (NOLOCK) on mtttaxcode = PthTaxCode  
								  AND a.MttDateTimeCreated = (select max(a2.MttDateTimeCreated)
															    FROM ULTIPRO_SYSTEM.dbo.[TxTbMast] a2 (NOLOCK)
															WHERE a.mtttaxcode = a2.mtttaxcode
																  AND a2.MttDateTimeCreated < pthpaydate)
WHERE PthTaxCode = 'USFUTA' AND PthPerControl LIKE CONCAT(YEAR(@LIVEDATE), '%')
AND @Country = 'USA'
GROUP BY cmpcompanycode, eecpaygroup, eeceeid, eeccoid, eecempno, eepnamelast, eepnamefirst, eecemplstatus, year(pthpaydate), a.MttTaxPercentOverBase, PthEmpNo, PthCoID, PthTaxCode
HAVING ABS(SUM(PthCurTaxAmt) - (SUM(PthCurTaxableWages) * a.MttTaxPercentOverBase)) > .05

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'PayHistory'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'  
		,ErrorNumber='00512'
		,ErrorMessage = 'There are orphan transactions in PTaxHist. Please have TC delete these transactions.'
		,ErrorKeyLabel = 'Tax Code'
		,ErrorKeyFieldName= 'PthGennumber AND PthTaxcode'
		,ErrorKeyValue = isnull(pthgennumber + ' AND ' + PthTaxcode,'') 
		,Details = 'Orphaned taxcode: ' + pthtaxcode +'' + ' on gennumber: ' +  pthgennumber
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM PTaxHist (NOLOCK)
JOIN EmpComp (NOLOCK) on eeccoid = pthcoid AND eeceeid = ptheeid
JOIN EmpPers (NOLOCK) on eepeeid = eeceeid
JOIN Company (NOLOCK) on cmpcoid = eeccoid
WHERE PthGenNumber NOT IN(SELECT PrgGenNumber FROM PayReg (NOLOCK))
  AND PthPerControl LIKE CONCAT(YEAR(@LIVEDATE), '%')

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'PayHistory'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'  
		,ErrorNumber='00513'
		,ErrorMessage = 'The following employees have ER H.S.A. amounts in the deduction instead of earnings'
		,ErrorKeyLabel = 'Deduction Code'
		,ErrorKeyFieldName= 'pdhdedcode'
		,ErrorKeyValue = isnull(pdhdedcode,'') 
		,Details = 	'Pay Date: ' + ltrim(rtrim(isnull(CONVERT(varchar, prgpaydate, 101),''))) 
					+ ', PerControl: '+prgpercontrol
					+ ', DocNo: '+ prgdocno+ ''
					+ ', Gennumber: ' + prggennumber
		,RoleToReview = 'TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM iPDedHIst (NOLOCK)
JOIN payreg (NOLOCK) on prggennumber = pdhgennumber
JOIN EmpComp (NOLOCK) on eeccoid = prgcoid AND eeceeid = prgeeid
JOIN EmpPers (NOLOCK) on eepeeid = eeceeid
JOIN Company (NOLOCK) on cmpcoid = eeccoid
JOIN earncode (NOLOCK) on ernearncode = pdhdedcode AND ErnUseDedOffset = 'Y' AND ErnTaxCategory like '%HSA%' 
WHERE PdhERcuramt > 0
AND PrgPerControl LIKE CONCAT(YEAR(@LIVEDATE), '%')
AND @Country = 'USA'

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'PayHistory'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'  
		,ErrorNumber='00514'
		,ErrorMessage = 'Box 12 DD has employee only deduction amounts with no employer amounts for the year.'
		,ErrorKeyLabel = 'Deduction Code'
		,ErrorKeyFieldName= 'pdhdedcode'
		,ErrorKeyValue = isnull(pdhdedcode,'') 
		,Details = 	'Pay Date: ' + ltrim(rtrim(isnull(CONVERT(varchar, prgpaydate, 101),''))) 
					+ ', PerControl: '+prgpercontrol
					+ ', DocNo: '+ prgdocno+ ''
					+ ', Gennumber: ' + prggennumber
					+ ', EE YTD Amt: ' + cast(cast(sum(pdhEEcuramt) as money) as varchar(100))
					+ ', ER YTD Amt: ' + cast(cast(sum(pdhERcuramt) as money) as varchar(100))
		,RoleToReview = 'SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM iPDedHIst (NOLOCK)
JOIN payreg (NOLOCK) on prggennumber = pdhgennumber
JOIN EmpComp (NOLOCK) on eeccoid = prgcoid AND eeceeid = prgeeid
JOIN EmpPers (NOLOCK) on eepeeid = eeceeid
JOIN Company (NOLOCK) on cmpcoid = eeccoid
WHERE exists (select deddedcode FROM dedcode (NOLOCK) WHERE DedW2HealthcareReporting = 'Y' AND deddedcode = PdhDedCode)
AND PrgPerControl LIKE CONCAT(YEAR(@LIVEDATE), '%')
AND @Country = 'USA'
group by CmpCompanyCode, EecPayGroup, EecEmpNo, EepNameLast, EepNameFirst, EecEmplStatus, pdhdedcode, prgpaydate, prgpercontrol, prgdocno, prggennumber, EecEEID, EecCOID, pdhEEcuramt, pdhERcuramt
having sum(pdhEEcuramt) > 0
   AND sum(pdhERcuramt) = 0

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'PayHistory'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00515'
		,ErrorMessage = 'Payroll transactions do not have a Bank ID'
		,ErrorKeyLabel = 'Co Bank Id'
		,ErrorKeyFieldName= 'PrgCoBankId'
		,ErrorKeyValue = prgcobankid
		,Details = 'Pay Date: ' + ltrim(rtrim(isnull(CONVERT(varchar, prgpaydate, 101),''))) 
		+ ', PerControl: '+prgpercontrol
		+ ', DocNo: '+ prgdocno+ ''
		+ ', Gennumber: ' + prggennumber
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid=''
FROM PayReg (NOLOCK)
JOIN EmpComp (NOLOCK) on eeccoid = prgcoid AND eeceeid = prgeeid
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
WHERE prgcobankid not in(select bnkcobankid FROM bank (NOLOCK))
AND PrgPerControl LIKE CONCAT(YEAR(@LIVEDATE), '%')

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'PayHistory'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00516'
		,ErrorMessage = 'No YTD amount for ER paid HSA'
		,ErrorKeyLabel = 'Earn Code'
		,ErrorKeyFieldName= 'PehEarnCode'
		,ErrorKeyValue = PehEarnCode
		,Details = ''
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid=''
FROM PayReg (NOLOCK)
JOIN Ipearhist (NOLOCK) ON PehGennumber = PrgGennumber
JOIN EmpComp (NOLOCK) on eeccoid = prgcoid AND eeceeid = prgeeid
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
WHERE PrgPerControl LIKE CONCAT(YEAR(@LIVEDATE), '%') AND 
   exists (select 'x' FROM earncode (NOLOCK)
					     JOIN ultipro_system..etaxcat (NOLOCK) on etctaxcategory = erntaxcategory 
				   	    WHERE EtcEarnTaxReportingBox = '12' 
					      AND EtcEarnTaxRepBoxLabel = 'W'
						  AND ErnEarnCode = PehEarnCode)
AND @Country = 'USA'
group by CmpCompanyCode, eecpaygroup, EecEmpNo, EepNameLast, EepNameFirst, EecEmplStatus, PehEarnCode, EecEEID, EecCOID
having Sum(PehCurAmt) <= 0 
INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'PayHistory'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00519'
		,ErrorMessage = 'Taxable Wage vs Calc Tax difference for USMEDEE'
		,ErrorKeyLabel = 'Tax Code'
		,ErrorKeyFieldName= 'PthTaxCode'
		,ErrorKeyValue = PthTaxCode
		,Details = 'Pay Date: ' + ltrim(rtrim(isnull(CONVERT(varchar, prgpaydate, 101),''))) 
		+ ', PerControl: '+prgpercontrol
		+ ', DocNo: '+ prgdocno+ ''
		+ ', Gennumber: ' + prggennumber
		+ ', Taxwage: ' +  convert(varchar(20), SUM(pthcurtaxablewages)) 
		+ ', Tax Amt: ' +  convert(varchar(20), ROUND(SUM(pthcurtaxamt),2))
		+ ', Calc Tax Amt: ' + convert(varchar(20), round(sum(PthCurTaxableWages *  @TaxRate_USMED),2))
		+ ', Calc Tax Sur Charge Amt: ' + convert(varchar(20), round(sum(case when pthcurtaxablewages > 200000 then (pthcurtaxablewages - 200000) * .009 else 0 end),2))
		+ ', Calc Tot Tax Amt: ' + convert(varchar(20), round(sum(PthCurTaxableWages *  @TaxRate_USMED) + round(sum(case when pthcurtaxablewages > 200000 then (pthcurtaxablewages - 200000) * .009 else 0 end),2),2))
		+ ', Difference: ' + convert(varchar(20), round(sum(PthCurTaxableWages *  @TaxRate_USMED) + round(sum(case when pthcurtaxablewages > 200000 then (pthcurtaxablewages - 200000) * .009 else 0 end),2) - ROUND(SUM(pthcurtaxamt),2),2))
		+ ', Wage Variance: ' + convert(varchar(20), round(round(sum(PthCurTaxableWages *  @TaxRate_USMED) + round(sum(case when pthcurtaxablewages > 200000 then (pthcurtaxablewages - 200000) * .009 else 0 end),2) - ROUND(SUM(pthcurtaxamt),2),2)/ @TaxRate_USMED,2)) 
		,RoleToReview ='SC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid=''
FROM PayReg (NOLOCK)
JOIN iPtaxHist (NOLOCK) on PthGennumber = PrgGennumber
JOIN EmpComp (NOLOCK) on eeccoid = prgcoid AND eeceeid = prgeeid
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
WHERE pthtaxcode='USMEDEE' 
  AND PrgDocNo like 'OB%'
  AND @Country = 'USA'
GROUP BY CmpCompanyCode, eecpaygroup, EecEmpNo, EepNameLast, EepNameFirst, EecEmplStatus, Pthtaxcode, EecEEID, EecCOID, prgpaydate, prgdocno, prggennumber, prgpercontrol
Having (abs((sum(pthcurtaxamt) + sum(pthuncollectedtax))-((sum(pthcurtaxablewages)* @TaxRate_USMED) + SUM(PthCurCalcAccum1) * .009)) > .10) 
--  HAVING abs(sum(PthCurTaxableWages *  @TaxRate_USMED) + round(sum(case when pthcurtaxablewages > 200000 then (pthcurtaxablewages - 200000) * .009 else 0 end),2) -  ROUND(SUM(pthcurtaxamt),2)) > .05  
  AND PrgPerControl LIKE CONCAT(YEAR(@LIVEDATE), '%')

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
print getdate()
RAISERROR ('Employee QA thru 00519', 0, 1) WITH NOWAIT
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
 

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'PayHistory'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00520'
		,ErrorMessage = 'Taxable Wage vs Calc Tax difference for USMEDEE'
		,ErrorKeyLabel = 'Tax Code'
		,ErrorKeyFieldName= 'PthTaxCode'
		,ErrorKeyValue = PthTaxCode
		,Details = 'Pay Date: ' + ltrim(rtrim(isnull(CONVERT(varchar, prgpaydate, 101),''))) 
		+ ', PerControl: '+prgpercontrol
		+ ', DocNo: '+ prgdocno+ ''
		+ ', Gennumber: ' + prggennumber
		+ ', Taxwage: ' +  convert(varchar(20), SUM(pthcurtaxablewages)) 
		+ ', Tax Amt: ' +  convert(varchar(20), ROUND(SUM(pthcurtaxamt),2))
		+ ', Calc Tax Amt: ' + convert(varchar(20), round(sum(PthCurTaxableWages *  @TaxRate_USMED),2))
		+ ', Calc Tax Sur Charge Amt: ' + convert(varchar(20), round(sum(case when pthcurtaxablewages > 200000 then (pthcurtaxablewages - 200000) * .009 else 0 end),2))
		+ ', Calc Tot Tax Amt: ' + convert(varchar(20), round(sum(PthCurTaxableWages *  @TaxRate_USMED) + round(sum(case when pthcurtaxablewages > 200000 then (pthcurtaxablewages - 200000) * .009 else 0 end),2),2))
		+ ', Difference: ' + convert(varchar(20), round(sum(PthCurTaxableWages *  @TaxRate_USMED) + round(sum(case when pthcurtaxablewages > 200000 then (pthcurtaxablewages - 200000) * .009 else 0 end),2) - ROUND(SUM(pthcurtaxamt),2),2))
		+ ', Wage Variance: ' + convert(varchar(20), round(round(sum(PthCurTaxableWages *  @TaxRate_USMED) + round(sum(case when pthcurtaxablewages > 200000 then (pthcurtaxablewages - 200000) * .009 else 0 end),2) - ROUND(SUM(pthcurtaxamt),2),2)/ @TaxRate_USMED,2)) 
		,RoleToReview ='SC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid=''
FROM PayReg (NOLOCK)
JOIN iPtaxHist (NOLOCK) on PthGennumber = PrgGennumber
JOIN EmpComp (NOLOCK) on eeccoid = prgcoid AND eeceeid = prgeeid
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
WHERE pthtaxcode='USMEDER' 
  AND PrgDocNo like 'OB%'
  AND @Country = 'USA'
GROUP BY CmpCompanyCode, eecpaygroup, EecEmpNo, EepNameLast, EepNameFirst, EecEmplStatus, Pthtaxcode, EecEEID, EecCOID, prgpaydate, prgdocno, prggennumber, prgpercontrol
Having (abs((sum(pthcurtaxamt) + sum(pthuncollectedtax))-((sum(pthcurtaxablewages)* @TaxRate_USMED))) > .10) 
--  HAVING abs(sum(PthCurTaxableWages *  @TaxRate_USMED) + round(sum(case when pthcurtaxablewages > 200000 then (pthcurtaxablewages - 200000) * .009 else 0 end),2) -  ROUND(SUM(pthcurtaxamt),2)) > .05  
  AND PrgPerControl LIKE CONCAT(YEAR(@LIVEDATE), '%')

 -- ***This is the correct script (added PtaxCode to the ""details"" field and update the WHERE statement to be PthReportingTaxableWages <> PthCurTaxableWages

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'PayHistory'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00525'
		,ErrorMessage = 'W2 Reporting Taxable not matching pay history cur taxable wages.'
		,ErrorKeyLabel = 'Gennumber'
		,ErrorKeyFieldName= 'prggennumber'
		,ErrorKeyValue = prggennumber
		,Details = 'Tax: '+PthTaxCode+' Amt:' + ltrim(rtrim(isnull(convert(char(20),pthcurtaxamt),''))) 
		+ ', Rpt Wages: '+ltrim(rtrim(isnull(convert(char(20),pthreportingtaxablewages),'')))  
		+ ', Cur Wages: '+ltrim(rtrim(isnull(convert(char(20),pthcurtaxablewages),'')))  
		+ ', Pay Date: ' + ltrim(rtrim(isnull(CONVERT(varchar, prgpaydate, 101),''))) 
		+ ', PerControl: '+prgpercontrol
		+ ', DocNo: '+ prgdocno+ ''
		+ ', Gennumber: ' + prggennumber
		,RoleToReview ='SC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid=''
FROM PayReg (NOLOCK)
JOIN EmpComp (NOLOCK) on eeccoid = prgcoid AND eeceeid = prgeeid
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN iptaxhist (NOLOCK) ON pthgennumber = prggennumber AND PthTaxCode NOT IN ('WASIT','FLSIT','NVSIT','TXSIT','WYSIT','NHSIT', 'SDSIT', 'AKSIT','TNSIT','NYSIT')
WHERE pthreportingtaxablewages <>pthcurtaxablewages 
  and pthtaxcode like '%IT'
  AND @Country = 'USA'
  AND PrgPerControl LIKE CONCAT(YEAR(@LIVEDATE), '%') 



INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'PayHistory'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00530'
		,ErrorMessage = 'PthCurGrossWages should be the same for ONEHER and ONPIT.'
		,ErrorKeyLabel = 'Gross Wages'
		,ErrorKeyFieldName= 'ONPIT PthCurGrossWages'
		,ErrorKeyValue = ONPIT.PthCurGrossWages
		,Details = 'ONEHER: ' + convert(varchar(20), ONEHER.PthCurGrossWages)
		,RoleToReview ='TC/SC Canada'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid=''
FROM PayReg (NOLOCK)
JOIN ipTaxhist ONEHER (NOLOCK) ON ONEHER.PthGennumber = PrgGennumber AND ONEHER.pthTaxcode = 'ONEHER'
JOIN ipTaxhist ONPIT  (NOLOCK) ON ONPIT.PthGennumber = PrgGennumber AND ONPIT.pthTaxcode = 'ONPIT'
JOIN EmpComp (NOLOCK) on eeccoid = prgcoid AND eeceeid = prgeeid
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
WHERE ONEHER.PthCurGrossWages <> ONPIT.PthCurGrossWages
  AND @Country = 'CAN'
  AND PrgPerControl LIKE CONCAT(YEAR(@LIVEDATE), '%')

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'PayHistory'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00531'
		,ErrorMessage = 'PthCurGrossWages should be the same for MBHPER and MBPIT.'
		,ErrorKeyLabel = 'Gross Wages'
		,ErrorKeyFieldName= 'MBPIT PthCurGrossWages'
		,ErrorKeyValue = MBPIT.PthCurGrossWages
		,Details = 'MBHPER: ' + convert(varchar(20), MBHPER.PthCurGrossWages)
		,RoleToReview ='TC/SC Canada'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid=''
FROM PayReg (NOLOCK)
JOIN ipTaxhist MBHPER (NOLOCK) ON MBHPER.PthGennumber = PrgGennumber AND MBHPER.pthTaxcode = 'MBHPER'
JOIN ipTaxhist MBPIT  (NOLOCK) ON MBPIT.PthGennumber = PrgGennumber AND MBPIT.pthTaxcode = 'MBPIT'
JOIN EmpComp (NOLOCK) on eeccoid = prgcoid AND eeceeid = prgeeid
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
WHERE MBHPER.PthCurGrossWages <> MBPIT.PthCurGrossWages
  AND @Country = 'CAN'
  AND PrgPerControl LIKE CONCAT(YEAR(@LIVEDATE), '%')

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'PayHistory'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00532'
		,ErrorMessage = 'PthCurGrossWages should be the same for NLHPER and NLPIT.'
		,ErrorKeyLabel = 'Gross Wages'
		,ErrorKeyFieldName= 'NLPIT PthCurGrossWages'
		,ErrorKeyValue = NLPIT.PthCurGrossWages
		,Details = 'NLHPER: ' + convert(varchar(20), NLHPER.PthCurGrossWages)
		,RoleToReview ='TC/SC Canada'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid=''
FROM PayReg (NOLOCK)
JOIN ipTaxhist NLHPER (NOLOCK) ON NLHPER.PthGennumber = PrgGennumber AND NLHPER.pthTaxcode = 'NLHPER'
JOIN ipTaxhist NLPIT  (NOLOCK) ON NLPIT.PthGennumber = PrgGennumber AND NLPIT.pthTaxcode = 'NLPIT'
JOIN EmpComp (NOLOCK) on eeccoid = prgcoid AND eeceeid = prgeeid
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
WHERE NLHPER.PthCurGrossWages <> NLPIT.PthCurGrossWages
  AND @Country = 'CAN'
  AND PrgPerControl LIKE CONCAT(YEAR(@LIVEDATE), '%')

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'PayHistory'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00532'
		,ErrorMessage = 'PthCurGrossWages should be the same for BCEHER and BCPIT.'
		,ErrorKeyLabel = 'Gross Wages'
		,ErrorKeyFieldName= 'BCPIT PthCurGrossWages'
		,ErrorKeyValue = BCPIT.PthCurGrossWages
		,Details = 'BCEHER: ' + convert(varchar(20), BCEHER.PthCurGrossWages)
		,RoleToReview ='TC/SC Canada'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid=''
FROM PayReg (NOLOCK)
JOIN ipTaxhist BCEHER (NOLOCK) ON BCEHER.PthGennumber = PrgGennumber AND BCEHER.pthTaxcode = 'BCEHER'
JOIN ipTaxhist BCPIT  (NOLOCK) ON BCPIT.PthGennumber = PrgGennumber AND BCPIT.pthTaxcode = 'BCPIT'
JOIN EmpComp (NOLOCK) on eeccoid = prgcoid AND eeceeid = prgeeid
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
WHERE BCEHER.PthCurGrossWages <> BCPIT.PthCurGrossWages
  AND @Country = 'CAN'
  AND PrgPerControl LIKE CONCAT(YEAR(@LIVEDATE), '%')
  
INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'PayHistory'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00533'
		,ErrorMessage = 'PthCurGrossWages should be the same for QCPIT, CNQPPEE, CNQPPER, QCCNTER, QCCTER, QCFNFMER, QCHSER, QCQPIPEE, QCQPIPER.'
		,ErrorKeyLabel = 'Gross Wages'
		,ErrorKeyFieldName= 'QCPIT PthCurGrossWages'
		,ErrorKeyValue = QCPIT.PthCurGrossWages
		,Details =	' CNQPPEE: ' + convert(varchar(20), CNQPPEE.PthCurGrossWages) +
					' CNQPPER: ' + convert(varchar(20), CNQPPER.PthCurGrossWages) +	
					' QCCNTER: ' + convert(varchar(20), QCCNTER.PthCurGrossWages) +	
					'  QCCTER: ' + convert(varchar(20), QCCTER.PthCurGrossWages) +	
					'QCFNFMER: ' + convert(varchar(20), QCFNFMER.PthCurGrossWages) +	
					'  QCHSER: ' + convert(varchar(20), QCHSER.PthCurGrossWages) +	
					'QCQPIPEE: ' + convert(varchar(20), QCQPIPEE.PthCurGrossWages) +	
					'QCQPIPER: ' + convert(varchar(20), QCQPIPER.PthCurGrossWages) 	
		,RoleToReview ='SC Canada'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid=''
FROM PayReg (NOLOCK)
JOIN ipTaxhist QCPIT  (NOLOCK) ON QCPIT.PthGennumber = PrgGennumber AND QCPIT.pthTaxcode = 'QCPIT'
LEFT JOIN ipTaxhist CNQPPEE (NOLOCK) ON CNQPPEE.PthGennumber = PrgGennumber AND CNQPPEE.pthTaxcode = 'CNQPPEE'
LEFT JOIN ipTaxhist CNQPPER (NOLOCK) ON CNQPPER.PthGennumber = PrgGennumber AND CNQPPER.pthTaxcode = 'CNQPPER'
LEFT JOIN ipTaxhist QCCNTER (NOLOCK) ON QCCNTER.PthGennumber = PrgGennumber AND QCCNTER.pthTaxcode = 'QCCNTER'
LEFT JOIN ipTaxhist QCCTER  (NOLOCK) ON QCCTER.PthGennumber = PrgGennumber AND QCCTER.pthTaxcode = 'QCCTER'
LEFT JOIN ipTaxhist QCFNFMER (NOLOCK) ON QCFNFMER.PthGennumber = PrgGennumber AND QCFNFMER.pthTaxcode = 'QCFNFMER'
LEFT JOIN ipTaxhist QCHSER (NOLOCK) ON QCHSER.PthGennumber = PrgGennumber AND QCHSER.pthTaxcode = 'QCHSER'
LEFT JOIN ipTaxhist QCQPIPEE (NOLOCK) ON QCQPIPEE.PthGennumber = PrgGennumber AND QCQPIPEE.pthTaxcode = 'QCQPIPEE'
LEFT JOIN ipTaxhist QCQPIPER (NOLOCK) ON QCQPIPER.PthGennumber = PrgGennumber AND QCQPIPER.pthTaxcode = 'QCQPIPER'
JOIN EmpComp (NOLOCK) on eeccoid = prgcoid AND eeceeid = prgeeid
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
WHERE (    (QCPIT.PthCurGrossWages <> isnull(CNQPPEE.PthCurGrossWages,0) AND CNQPPEE.PthCurGrossWages IS NOT NULL)
		OR (QCPIT.PthCurGrossWages <> isnull(CNQPPER.PthCurGrossWages,0) AND CNQPPER.PthCurGrossWages IS NOT NULL)
		OR (QCPIT.PthCurGrossWages <> isnull(QCCNTER.PthCurGrossWages,0) AND QCCNTER.PthCurGrossWages IS NOT NULL)
		OR (QCPIT.PthCurGrossWages <> isnull(QCCTER.PthCurGrossWages,0) AND QCCTER.PthCurGrossWages IS NOT NULL)
		OR (QCPIT.PthCurGrossWages <> isnull(QCFNFMER.PthCurGrossWages,0) AND QCFNFMER.PthCurGrossWages IS NOT NULL)
		OR (QCPIT.PthCurGrossWages <> isnull(QCHSER.PthCurGrossWages,0) AND QCHSER.PthCurGrossWages IS NOT NULL)
		OR (QCPIT.PthCurGrossWages <> isnull(QCQPIPEE.PthCurGrossWages,0) AND QCQPIPEE.PthCurGrossWages IS NOT NULL)
		OR (QCPIT.PthCurGrossWages <> isnull(QCQPIPER.PthCurGrossWages,0) AND QCQPIPER.PthCurGrossWages IS NOT NULL))
  AND @Country = 'CAN'
  AND PrgPerControl LIKE CONCAT(YEAR(@LIVEDATE), '%')

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'PayHistory'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00534'
		,ErrorMessage = 'CPP employee and employer amounts should match.'
		,ErrorKeyLabel = 'Tax Amount'
		,ErrorKeyFieldName= 'CNCPPEE PthCurtaxamt'
		,ErrorKeyValue = CNCPPEE.PthCurtaxamt
		,Details = 'CNCPPER: ' + convert(varchar(20), CNCPPER.PthCurtaxamt)
		,RoleToReview ='TC/SC Canada'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid=''
FROM PayReg (NOLOCK)
JOIN ipTaxhist CNCPPEE  (NOLOCK) ON CNCPPEE.PthGennumber = PrgGennumber AND CNCPPEE.pthTaxcode = 'CNCPPEE'
LEFT JOIN ipTaxhist CNCPPER (NOLOCK) ON CNCPPER.PthGennumber = PrgGennumber AND CNCPPER.pthTaxcode = 'CNCPPER'
JOIN EmpComp (NOLOCK) on eeccoid = prgcoid AND eeceeid = prgeeid
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
WHERE CNCPPER.PthCurtaxamt <> CNCPPEE.PthCurtaxamt
  AND @Country = 'CAN'
  AND PrgPerControl LIKE CONCAT(YEAR(@LIVEDATE), '%')

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'PayHistory'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00535'
		,ErrorMessage = 'CPP employee and employer amounts should match.'
		,ErrorKeyLabel = 'Tax Amount'
		,ErrorKeyFieldName= 'CNQPPEE PthCurtaxamt'
		,ErrorKeyValue = CNQPPEE.PthCurtaxamt
		,Details = 'CNQPPER: ' + convert(varchar(20), CNQPPER.PthCurtaxamt)
		,RoleToReview ='TC/SC Canada'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid=''
FROM PayReg (NOLOCK)
JOIN ipTaxhist CNQPPEE  (NOLOCK) ON CNQPPEE.PthGennumber = PrgGennumber AND CNQPPEE.pthTaxcode = 'CNQPPEE'
LEFT JOIN ipTaxhist CNQPPER (NOLOCK) ON CNQPPER.PthGennumber = PrgGennumber AND CNQPPER.pthTaxcode = 'CNQPPER'
JOIN EmpComp (NOLOCK) on eeccoid = prgcoid AND eeceeid = prgeeid
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
WHERE CNQPPER.PthCurtaxamt <> CNQPPEE.PthCurtaxamt
  AND @Country = 'CAN'
  AND PrgPerControl LIKE CONCAT(YEAR(@LIVEDATE), '%')

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'PayHistory'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00536'
		,ErrorMessage = 'PthCurGrossWages should be the same for CNEIEE and CNFIT.'
		,ErrorKeyLabel = 'Gross Wages'
		,ErrorKeyFieldName= 'CNFIT PthCurGrossWages'
		,ErrorKeyValue = CNFIT.PthCurGrossWages
		,Details = 'CNEIEE: ' + convert(varchar(20), CNEIEE.PthCurGrossWages)
		,RoleToReview ='TC/SC Canada'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid=''
FROM PayReg (NOLOCK)
JOIN ipTaxhist CNEIEE (NOLOCK) ON CNEIEE.PthGennumber = PrgGennumber AND CNEIEE.pthTaxcode = 'CNEIEE'
JOIN ipTaxhist CNFIT  (NOLOCK) ON CNFIT.PthGennumber = PrgGennumber AND CNFIT.pthTaxcode = 'CNFIT'
JOIN EmpComp (NOLOCK) on eeccoid = prgcoid AND eeceeid = prgeeid
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
WHERE CNEIEE.PthCurGrossWages <> CNFIT.PthCurGrossWages
  AND @Country = 'CAN'
  AND PrgPerControl LIKE CONCAT(YEAR(@LIVEDATE), '%')
  
INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'PayHistory'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00537'
		,ErrorMessage = 'PthCurGrossWages should be the same for CNEIER and CNFIT.'
		,ErrorKeyLabel = 'Gross Wages'
		,ErrorKeyFieldName= 'CNFIT PthCurGrossWages'
		,ErrorKeyValue = CNFIT.PthCurGrossWages
		,Details = 'CNEIER: ' + convert(varchar(20), CNEIER.PthCurGrossWages)
		,RoleToReview ='TC/SC Canada'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid=''
FROM PayReg (NOLOCK)
JOIN ipTaxhist CNEIER (NOLOCK) ON CNEIER.PthGennumber = PrgGennumber AND CNEIER.pthTaxcode = 'CNEIER'
JOIN ipTaxhist CNFIT  (NOLOCK) ON CNFIT.PthGennumber = PrgGennumber AND CNFIT.pthTaxcode = 'CNFIT'
JOIN EmpComp (NOLOCK) on eeccoid = prgcoid AND eeceeid = prgeeid
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
WHERE CNEIER.PthCurGrossWages <> CNFIT.PthCurGrossWages
  AND @Country = 'CAN'
  AND PrgPerControl LIKE CONCAT(YEAR(@LIVEDATE), '%')

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'PayHistory'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00538'
		,ErrorMessage = 'ArnID should not be blank or Null.'
		,ErrorKeyLabel = 'ArnId'
		,ErrorKeyFieldName= 'PrgArnId'
		,ErrorKeyValue = PrgArnId
		,Details = ''
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid=''
FROM PayReg (NOLOCK)
JOIN EmpComp (NOLOCK) on eeccoid = prgcoid AND eeceeid = prgeeid
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID AND CmpCountryCode = 'CAN'
WHERE PrgArnId is NULL
  AND PrgCheckAddMode <> 'N'
  AND PrgTransactionType <> 'E'
  AND @Country = 'CAN'
  AND PrgPerControl LIKE CONCAT(YEAR(@LIVEDATE), '%')

--Error can we exclude the tax codes below when PthCurDefComp <> 0
--   --https://ultimatesoftware.my.salesforce.com/kA40d000000L4ic?srPos=2&srKp=ka4&lang=en_US    

  
INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'PayHistory'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00539'
		,ErrorMessage = 'Employee has negative wages. Please review OB checks.'
		,ErrorKeyLabel = 'Tax Code'
		,ErrorKeyFieldName= 'pthtaxcode'
		,ErrorKeyValue = pthtaxcode
		,Details =  'PthTaxCalcGroupID: '+ PthTaxCalcGroupID
					+ '  ' +
					',  TaxQuart: ' + case
								when substring(PthPerControl,5,2) in ('01','02','03') then 'Q1'
								when substring(PthPerControl,5,2) in ('04','05','06') then 'Q2'
								when substring(PthPerControl,5,2) in ('07','08','09') then 'Q3'
								when substring(PthPerControl,5,2) in ('10','11','12') then 'Q4'
								else 'ERROR' end 
					+ '  ' +
					',  TaxYear: ' + left(PthPerControl,4)
					+ '  ' +
					',  pthtaxcode: ' + pthtaxcode
					+ '  ' +
',  Gross: ' + convert(varchar(20), SUM(PthCurGrossWages))
					+ '  ' +
',  Exempt: ' + convert(varchar(20), SUM(PthCurExemptWages))
					+ '  ' +
',  DC_Cur125DC: ' + convert(varchar(20), SUM(isnull(PthCurDepCare,0)+isnull(PthCurD125,0)))
					+ '  ' +
',  Housing: ' + convert(varchar(20), SUM(PthCurHousing))
					+ '  ' +
',  OtherWages: ' + convert(varchar(20), SUM(PthCurOtherWages))
					+ '  ' +
',  Sec125: ' + convert(varchar(20), SUM(PthCurSec125))
					+ '  ' +
',  TaxableGross: ' + convert(varchar(20), SUM(PthCurTaxableGross))
					+ '  ' +
',  TaxableWages: ' + convert(varchar(20), SUM(PthCurTaxableWages))
					+ '  ' +
',  Excess Wages: ' + convert(varchar(20), SUM(PthCurExcessWages))
					+ '  ' +
',  TaxableTips: ' + convert(varchar(20), SUM(PthCurTaxableTips))
					+ '  ' +
',  TaxAmt: ' + convert(varchar(20), SUM(PthCurTaxAmt))
					+ '  ' +
',  UncollectedTax: ' + convert(varchar(20), SUM(PthUncollectedTax))
					+ '  ' +
',  DefComp: ' + convert(varchar(20), SUM(PthCurDefComp))

		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid=''
from ptaxhist pth with (NOLOCK)
join company with (NOLOCK) on pthcoid = cmpcoid
join emppers on ptheeid = eepeeid
Join empcomp (NOLOCK) on eeccoid = pthcoid and eeceeid = ptheeid
WHERE left(PthPerControl,4) = year(@LIVEDATE)
  and @country = 'USA'
  and not exists 
        (select 1 from ptaxhist ptc
		  where ptc.PthCurDefComp < 0
		    and ptc.PthTaxCode in ('MAPFLEE','MAPMLEE','MAPFLEP','MAPPFLEE','MAPPFLEP','MAPMLER','MAPPMLEE','MAPPMLER')
			and ptc.ptheeid = pth.ptheeid
			and ptc.pthcoid = pth.pthcoid
			and ptc.pthtaxcode = pthtaxcode) 
Group by CmpCompanyCode, eecpaygroup,EecEEID, EecCOID, eepnamelast, eepnamefirst, eecemplstatus, EecEmpNo, PthTaxCalcGroupID, pthtaxcode,
case
when substring(PthPerControl,5,2) in ('01','02','03') then 'Q1'
when substring(PthPerControl,5,2) in ('04','05','06') then 'Q2'
when substring(PthPerControl,5,2) in ('07','08','09') then 'Q3'
when substring(PthPerControl,5,2) in ('10','11','12') then 'Q4'
else 'ERROR' end
,left(PthPerControl,4)
having
(SUM(PthCurDefComp) < 0 OR
SUM(isnull(PthCurDepCare,0)+isnull(PthCurD125,0)) < 0.00 OR
SUM(PthCurExcessWages) < 0.00 OR
SUM(PthCurGrossWages) < 0.00 OR
SUM(PthCurHousing) < 0.00 OR
SUM(PthCurOtherWages) < 0.00 or
SUM(PthCurTaxableGross) < 0.00 OR
SUM(PthCurTaxableTips) < 0.00 OR
SUM(PthCurTaxableWages) < 0.00 OR
SUM(PthCurTaxAmt) < 0.00)
order by eepnamelast, eepnamefirst, pthtaxcode, case
when substring(PthPerControl,5,2) in ('01','02','03') then 'Q1'
when substring(PthPerControl,5,2) in ('04','05','06') then 'Q2'
when substring(PthPerControl,5,2) in ('07','08','09') then 'Q3'
when substring(PthPerControl,5,2) in ('10','11','12') then 'Q4'
else 'ERROR' end


INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT   CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'PayHistory'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00525'
		,ErrorMessage = 'W2 Reporting Taxable not matching pay history taxable.'
		,ErrorKeyLabel = 'Gennumber'
		,ErrorKeyFieldName= 'prggennumber'
		,ErrorKeyValue = prggennumber
		,Details = PthTaxCode + ltrim(rtrim(isnull(convert(char(20),pthcurtaxamt),''))) 
		+ ', Pay Date: ' + ltrim(rtrim(isnull(CONVERT(varchar, prgpaydate, 101),''))) 
		+ ', PerControl: '+prgpercontrol
		+ ', DocNo: '+ prgdocno+ ''
		+ ', Gennumber: ' + prggennumber
		,RoleToReview ='SC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid=''
FROM PayReg (NOLOCK)
JOIN EmpComp (NOLOCK) on eeccoid = prgcoid AND eeceeid = prgeeid
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN iptaxhist (NOLOCK) ON pthgennumber = prggennumber 
                 AND PthTaxCode NOT IN ('WASIT','FLSIT','NVSIT','TXSIT','WYSIT','NHSIT', 'SDSIT', 'AKSIT','TNSIT','NYSIT')
WHERE pthreportingtaxablewages <>pthcurtaxablewages 
  and (pthtaxcode = 'USFIT'
        or pthtaxcode like '%SIT')
  AND @Country = 'USA'
     AND PrgPerControl LIKE CONCAT(YEAR(@LIVEDATE), '%')



INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'PayHistory'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00540'
		,ErrorMessage = 'Taxable Wages and Taxable Gross should match when employee not subject to tax'
		,ErrorKeyLabel = 'Gennumber'
		,ErrorKeyFieldName= 'prggennumber'
		,ErrorKeyValue = prggennumber
		,Details = pthtaxcode + ' ' 
		+ ', pthcurtaxablewages: ' + ltrim(rtrim(isnull(convert(char(20),pthcurtaxablewages),''))) 
		+ ', pthcurtaxablegross: ' + ltrim(rtrim(isnull(convert(char(20),pthcurtaxablegross),''))) 
		+ ', pthcurexcesswages: ' + ltrim(rtrim(isnull(convert(char(20),pthcurexcesswages),''))) 
		+ ', Pay Date: ' + ltrim(rtrim(isnull(CONVERT(varchar, prgpaydate, 101),''))) 
		+ ', PerControl: '+prgpercontrol
		+ ', DocNo: '+ prgdocno+ ''
		+ ', Gennumber: ' + prggennumber
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid=''
FROM PayReg (NOLOCK)
JOIN EmpComp (NOLOCK) on eeccoid = prgcoid AND eeceeid = prgeeid
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN iptaxhist (NOLOCK) ON pthgennumber = prggennumber 
WHERE PthIsEmployerTax = 'N'
  and pthnotsubjecttotax = 'Y'
  and pthcurtaxablewages = 0 
  and pthcurtaxablegross <> 0
  and pthcurexcesswages = 0
  AND @Country = 'USA'
  AND PrgPerControl LIKE CONCAT(YEAR(@LIVEDATE), '%')


 
 -- E 00541
-- Audit for missing LMW Jurisdiction in EmpMLoc.  This should be reviewed by TC.
-- Error - Employees are missing the LMW Jurisdiction in their EmpMLoc record when 
--   the corresponding company location configuration has an LMW Jurisdiction.
 

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
select   CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Employee'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00541'
		,ErrorMessage = 'Audit for missing LMW Jurisdiction in EmpMLoc'
		,ErrorKeyLabel = 'Gennumber'
		,ErrorKeyFieldName= 'emllmwjurisdiction'
		,ErrorKeyValue = emllmwjurisdiction
		, Details = 'Loc Info.'+loccode+','+loclmwjurisdiction+ 'Empmloc Info.'+emlcode+','+emllmwjurisdiction
		,RoleToReview ='TC'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid=''
		-- select cmpcoid,cmpcompanycode,eeceeid,eecempno,eepnamelast,eepnamefirst,eecemplstatus,loccode,loclmwjurisdiction,emlcode,emllmwjurisdiction
  from empcomp 
    join empmloc on emlcoid = eeccoid and emleeid = eeceeid
    join location on loccode = emlcode
    join company on eeccoid = cmpcoid
    join emppers on eeceeid = eepeeid
where  eepdatetimecreated >= @createdate
  and loclmwjurisdiction <> emllmwjurisdiction 

 

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
--Accrual Validations
INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Accruals'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00600'
		,ErrorMessage = 'Earned PTO exceeds maximum accrual allowed in PTO plan'
		,ErrorKeyLabel = 'Accrual Option'
		,ErrorKeyFieldName= 'EacAccrOption'
		,ErrorKeyValue = isnull(EacAccrOption,'') 
		,Details = 'Accrual Option ' + isnull(EacAccrOption,'')+', Earned Balance: ' +  ltrim(rtrim(isnull(convert(char(20),EacAccrAllowedCurBal),'')))+', Maximum Allowed: '+ltrim(rtrim(isnull(convert(char(20),ArrMaxAccruedAllowed),'')))
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
		--,datediff(Y, eecdateofseniority,@LIVEDATE), ArrMaxAccruedAllowed
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN EmpAccr (NOLOCK) on eaceeid = eeceeid AND eaccoid = eeccoid 
JOIN AccrRate (NOLOCK) ON ArrAccrOption = EacAccrOption and ArrLOSUnits = 'Y' and datediff(Y, eecdateofseniority,@LIVEDATE) >= isnull(ArrIfLOSGrThanOrEqTo,0) and datediff(Y, eecdateofseniority,@LIVEDATE) <= ArrIfLOSLessThan
WHERE EacAccrAllowedCurBal > ArrMaxAccruedAllowed
  AND isnull(ArrMaxAccruedAllowed,0) > 0
  AND eepdatetimecreated >= @createdate
  and eepaddresscountry =  @Country 

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Accruals'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='01600'
		,ErrorMessage = 'Earned PTO exceeds maximum accrual allowed in PTO plan'
		,ErrorKeyLabel = 'Accrual Option'
		,ErrorKeyFieldName= 'EacAccrOption'
		,ErrorKeyValue = isnull(EacAccrOption,'') 
		,Details = 'Accrual Option ' + isnull(EacAccrOption,'')+', Earned Balance: ' +  ltrim(rtrim(isnull(convert(char(20),EacAccrAllowedCurBal),'')))+', Maximum Allowed: '+ltrim(rtrim(isnull(convert(char(20),ArrMaxAccruedAllowed),'')))
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
		--,datediff(Y, eecdateofseniority,@LIVEDATE), ArrMaxAccruedAllowed
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN EmpAccr (NOLOCK) on eaceeid = eeceeid AND eaccoid = eeccoid 
JOIN AccrRate (NOLOCK) ON ArrAccrOption = EacAccrOption and ArrLOSUnits = 'D' and datediff(D, eecdateofseniority,@LIVEDATE) >= isnull(ArrIfLOSGrThanOrEqTo,0) and datediff(D, eecdateofseniority,@LIVEDATE) <= ArrIfLOSLessThan
WHERE EacAccrAllowedCurBal > ArrMaxAccruedAllowed
  AND isnull(ArrMaxAccruedAllowed,0) > 0
  AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Accruals'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='02600'
		,ErrorMessage = 'Earned PTO exceeds maximum accrual allowed in PTO plan'
		,ErrorKeyLabel = 'Accrual Option'
		,ErrorKeyFieldName= 'EacAccrOption'
		,ErrorKeyValue = isnull(EacAccrOption,'') 
		,Details = 'Accrual Option ' + isnull(EacAccrOption,'')+', Earned Balance: ' +  ltrim(rtrim(isnull(convert(char(20),EacAccrAllowedCurBal),'')))+', Maximum Allowed: '+ltrim(rtrim(isnull(convert(char(20),ArrMaxAccruedAllowed),'')))
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
		--,datediff(Y, eecdateofseniority,@LIVEDATE), ArrMaxAccruedAllowed
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN EmpAccr (NOLOCK) on eaceeid = eeceeid AND eaccoid = eeccoid 
JOIN AccrRate (NOLOCK) ON ArrAccrOption = EacAccrOption and ArrLOSUnits = 'M' and datediff(M, eecdateofseniority,@LIVEDATE) >= isnull(ArrIfLOSGrThanOrEqTo,0) and datediff(M, eecdateofseniority,@LIVEDATE) <= ArrIfLOSLessThan
WHERE EacAccrAllowedCurBal > ArrMaxAccruedAllowed
  AND isnull(ArrMaxAccruedAllowed,0) > 0
  AND eepdatetimecreated >= @createdate
 
INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Accruals'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00601'
		,ErrorMessage = 'Available PTO exceeds maximum available amount allowed in PTO plan'
		,ErrorKeyLabel = 'Accrual Option'
		,ErrorKeyFieldName= 'EacAccrOption'
		,ErrorKeyValue = isnull(EacAccrOption,'') 
		,Details = 'Accrual Option ' + isnull(EacAccrOption,'')+', Earned Balance: ' +  ltrim(rtrim(isnull(convert(char(20),EacAccrAllowedCurBal),'')))+', Taken Balance: '+ltrim(rtrim(isnull(convert(char(20),EacAccrTakenCurBal),'')))+', Current Available: '+ltrim(rtrim(isnull(convert(char(20),(EacAccrAllowedCurBal-EacAccrTakenCurBal)),'')))+', Maximum Available: '+ltrim(rtrim(isnull(convert(char(20),ArrMaxAccruedAvailable),'')))
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
		-- SELECT AccrRate.*
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN EmpAccr (NOLOCK) on eaceeid = eeceeid AND eaccoid = eeccoid 
JOIN AccrRate (NOLOCK) ON ArrAccrOption = EacAccrOption and ArrLOSUnits = 'Y' and datediff(Y, eecdateofseniority,@LIVEDATE) >= isnull(ArrIfLOSGrThanOrEqTo,0) and datediff(Y, eecdateofseniority,@LIVEDATE) <= ArrIfLOSLessThan
WHERE (EacAccrAllowedCurBal - EacAccrTakenCurBal) > ArrMaxAccruedAvailable
  AND ArrMaxAccruedAvailable > 0
  AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Accruals'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='01601'
		,ErrorMessage = 'Available PTO exceeds maximum available amount allowed in PTO plan'
		,ErrorKeyLabel = 'Accrual Option'
		,ErrorKeyFieldName= 'EacAccrOption'
		,ErrorKeyValue = isnull(EacAccrOption,'') 
		,Details = 'Accrual Option ' + isnull(EacAccrOption,'')+', Earned Balance: ' +  ltrim(rtrim(isnull(convert(char(20),EacAccrAllowedCurBal),'')))+', Taken Balance: '+ltrim(rtrim(isnull(convert(char(20),EacAccrTakenCurBal),'')))+', Current Available: '+ltrim(rtrim(isnull(convert(char(20),(EacAccrAllowedCurBal-EacAccrTakenCurBal)),'')))+', Maximum Available: '+ltrim(rtrim(isnull(convert(char(20),ArrMaxAccruedAvailable),'')))
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
		-- SELECT AccrRate.*
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN EmpAccr (NOLOCK) on eaceeid = eeceeid AND eaccoid = eeccoid 
JOIN AccrRate (NOLOCK) ON ArrAccrOption = EacAccrOption and ArrLOSUnits = 'D' and datediff(D, eecdateofseniority,@LIVEDATE) >= isnull(ArrIfLOSGrThanOrEqTo,0) and datediff(D, eecdateofseniority,@LIVEDATE) <= ArrIfLOSLessThan
WHERE (EacAccrAllowedCurBal - EacAccrTakenCurBal) > ArrMaxAccruedAvailable
  AND ArrMaxAccruedAvailable > 0
  AND eepdatetimecreated >= @createdate

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Accruals'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='02601'
		,ErrorMessage = 'Available PTO exceeds maximum available amount allowed in PTO plan'
		,ErrorKeyLabel = 'Accrual Option'
		,ErrorKeyFieldName= 'EacAccrOption'
		,ErrorKeyValue = isnull(EacAccrOption,'') 
		,Details = 'Accrual Option ' + isnull(EacAccrOption,'')+', Earned Balance: ' +  ltrim(rtrim(isnull(convert(char(20),EacAccrAllowedCurBal),'')))+', Taken Balance: '+ltrim(rtrim(isnull(convert(char(20),EacAccrTakenCurBal),'')))+', Current Available: '+ltrim(rtrim(isnull(convert(char(20),(EacAccrAllowedCurBal-EacAccrTakenCurBal)),'')))+', Maximum Available: '+ltrim(rtrim(isnull(convert(char(20),ArrMaxAccruedAvailable),'')))
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
		-- SELECT AccrRate.*
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN EmpAccr (NOLOCK) on eaceeid = eeceeid AND eaccoid = eeccoid 
JOIN AccrRate (NOLOCK) ON ArrAccrOption = EacAccrOption and ArrLOSUnits = 'M' and datediff(M, eecdateofseniority,@LIVEDATE) >= isnull(ArrIfLOSGrThanOrEqTo,0) and datediff(M, eecdateofseniority,@LIVEDATE) <= ArrIfLOSLessThan
WHERE (EacAccrAllowedCurBal - EacAccrTakenCurBal) > ArrMaxAccruedAvailable
  AND ArrMaxAccruedAvailable > 0
  AND eepdatetimecreated >= @createdate
------

DECLARE @Print_DatePTOEE CHAR(1) DECLARE @CurrentYear CHAR(4)
SET @CurrentYear = YEAR(GETDATE())

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Accruals'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00602'
		,ErrorMessage = 'Employee level PTO Date of Last Accrual AND Date of Rollover in the future of the next rollover date or more than a year in the past'
		,ErrorKeyLabel = 'EE Rollover Date & EEEarned Thru Date'
		,ErrorKeyFieldName= 'EacDateOfRollover & EacDateAccruedThru'
		,ErrorKeyValue = isnull(EacAccrOption,'') 
		,Details = 'Accrual Option ' + isnull(EacAccrOption,'')
				+', EE Rollover Date: ' + ltrim(rtrim(isnull(CONVERT(varchar, EacDateOfRollover, 101),'')))   
				+', Plan Rollover Date: ' + ltrim(rtrim(isnull(CONVERT(varchar, AccRolloverFixedDate, 101),''))) 
				+', EEEarned Thru Date: ' + ltrim(rtrim(isnull(CONVERT(varchar, EacDateAccruedThru, 101),''))) 
				+', Plan Earned Thru Date: ' + ltrim(rtrim(isnull(CONVERT(varchar, AccAccrFixedDate, 101),''))) 
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID AND eepdatetimecreated >= @createdate
JOIN Company (NOLOCK) ON CmpCOID = EecCOID
JOIN EmpAccr (NOLOCK) on eaceeid = eeceeid AND eaccoid = eeccoid 
    JOIN AccrOpts (NOLOCK) ON AccAccrOption = EacAccrOption 
						  AND ((LEFT(AccRolloverFixedDate, 2) ='12' AND (EacDateOfRollover <  DATEFROMPARTS((@CurrentYear - 1), LEFT(AccRolloverFixedDate, 2), RIGHT(AccRolloverFixedDate, 2)) OR 
																   EacDateOfRollover >  DATEFROMPARTS((@CurrentYear), LEFT(AccRolloverFixedDate, 2), RIGHT(AccRolloverFixedDate, 2)))
						  AND EacAccrOption IN(SELECT AccAccrOption FROM AccrOpts (NOLOCK) WHERE AccRolloverPer = 'F')) OR
						 (LEFT(AccRolloverFixedDate, 2) ='01' AND (EacDateOfRollover <  DATEFROMPARTS((@CurrentYear), LEFT(AccRolloverFixedDate, 2), RIGHT(AccRolloverFixedDate, 2)) OR 
																   EacDateOfRollover >  DATEFROMPARTS((@CurrentYear + 1), LEFT(AccRolloverFixedDate, 2), RIGHT(AccRolloverFixedDate, 2)))
						  AND EacAccrOption IN(SELECT AccAccrOption FROM AccrOpts (NOLOCK) WHERE AccRolloverPer = 'F')) OR
						 (LEFT(AccRolloverFixedDate, 2) ='12' AND (EacDateAccruedThru < DATEFROMPARTS((@currentYear - 1), LEFT(AccAccrFixedDate, 2), RIGHT(AccAccrFixedDate, 2)) OR 
																  (EacDateAccruedThru < DATEFROMPARTS((@currentYear - 1), LEFT(AccAccrFixedDate, 2), RIGHT(AccAccrFixedDate, 2))) 
						  AND EacAccrOption IN(SELECT AccAccrOption FROM AccrOpts (NOLOCK) WHERE AccAccrCalcRule = '07'))) OR
						 (LEFT(AccRolloverFixedDate, 2) ='01' AND (EacDateAccruedThru < DATEFROMPARTS((@currentYear), LEFT(AccAccrFixedDate, 2), RIGHT(AccAccrFixedDate, 2)) OR 
																  (EacDateAccruedThru < DATEFROMPARTS((@currentYear), LEFT(AccAccrFixedDate, 2), RIGHT(AccAccrFixedDate, 2))) 
						  AND EacAccrOption IN(SELECT AccAccrOption FROM AccrOpts (NOLOCK) WHERE AccAccrCalcRule = '07'))))
WHERE EecEmplStatus <> 'T'

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Accruals'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00603'
		,ErrorMessage = 'Employee has incorrect Accrual Option/Accrual Code Combination. Please correct before payroll processing.'
		,ErrorKeyLabel = 'Accrual Option'
		,ErrorKeyFieldName= 'EacAccrOption'
		,ErrorKeyValue = isnull(EacAccrOption,'') 
		,Details = 'Accrual code ' + isnull(eacaccrcode,'')+', Earned Balance: ' +  ltrim(rtrim(isnull(convert(char(20),EacAccrAllowedCurBal),'')))+', Maximum Allowed: '+ltrim(rtrim(isnull(convert(char(20),ArrMaxAccruedAllowed),'')))
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid = ''
FROM EmpComp (NOLOCK) 
JOIN EmpPers (NOLOCK) ON EepEEID = EecEEID 
JOIN Company (NOLOCK) ON CmpCOID = EecCOID AND CMPCOUNTRYCODE = 'USA'
JOIN EmpAccr (NOLOCK) on eaceeid = eeceeid AND eaccoid = eeccoid 
JOIN AccrRate (NOLOCK) ON ArrAccrOption = EacAccrOption
WHERE not exists (select 'x' from accropts (NOLOCK) where accaccrcode = eacaccrcode and accaccroption = eacaccroption)
  AND @Country = 'USA'
  AND eepdatetimecreated >= @createdate

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- Security

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = CmpCompanyCode 
        ,PayGroup = isnull(eecpaygroup, '')
		,RecordType = 'Security'
		,EmpNo = RTRIM(EecEmpNo)
		,EmployeeName = RTRIM(EepNameLast) + ', ' + RTRIM(EepNameFirst)
		,EmploymentStatus = EecEmplStatus
		,DependentName = ''
		,Severity = 'E'
		,ErrorNumber='00700'
		,ErrorMessage = 'Employee has a payroll role that is not qualified by pay group.'
		,ErrorKeyLabel = 'Role Name'
		,ErrorKeyFieldName= 'rolName'
		,ErrorKeyValue = rolName
		,Details = 'Role Name: ' + rolName + ' Employee Paygroup: ' + eecpaygroup
		,RoleToReview ='SC\Customer'
		,EEID = EecEEID
		,COID = EecCOID
		,ConSystemid=''
FROM RbsTypes 
JOIN RbsUserRoles (NOLOCK) ON rurRoleID = rotRoleID AND rotRoleType = 'PAYRL' 
JOIN EmpComp (NOLOCK) ON EecEEID = rurEEID 
JOIN EmpPers (NOLOCK) ON eepEEID = EecEEID 
JOIN Company (NOLOCK) ON EecCoID = CmpCoID 
JOIN RbsRoles (NOLOCK) ON rolID = rotRoleID 
WHERE NOT EXISTS (SELECT 1 
                  FROM RbsQualifiers (NOLOCK) 
                  WHERE  qalROLEID = rurRoleID AND rurUserID = qalUSERID AND qalFIELD = 'EecPaygroup') 
GROUP BY CmpCompanyName, EepNameLast, EepNameFirst, EecEmpNo, EecEmplStatus, rolName , eeccoid, eeceeid, CmpCompanyCode, eecpaygroup
ORDER BY CmpCompanyName, EepNameLast, EepNameFirst

-- W 00701 Warning - No employees have the HR360 role.  Please ensure at least one employee and no more than two have the HR360 role assigned.

--select count(rolDescription) as 'Count'
-- from rbsroles
--  where rolid in (select rurid from rbsuserroles)
--    and rolname = 'HR360'
--    having count(*) = 0 

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = 'None' 
        ,PayGroup = '' 
		,RecordType = 'Security'
		,EmpNo = 'None'
		,EmployeeName = 'None'
		,EmploymentStatus = 'N'
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='00701'
		,ErrorMessage = 'Employee HR360 role not assigned'
		,ErrorKeyLabel = 'Role Name'
		,ErrorKeyFieldName= 'rolName'
		,ErrorKeyValue = 'HR360'
		,Details = 'Role Name: ' + rolName  
		,RoleToReview ='SC'
		,EEID = 'None'
		,COID = 'None'
		,ConSystemid=''
 -- select *
FROM Rbsroles 
 left JOIN RbsUserRoles (NOLOCK) ON rurRoleID = RolID 
 where rolname = 'HR360'
   and rurroleid is null

   --W  01201
--WARNING: Historical 1095-C data has not been imported into UltiPro.  Please work with customer to complete the template.

INSERT #ACE_DataQualityCheck (CompanyCode, PayGroup, RecordType, EmpNo, EmployeeName, EmploymentStatus, DependentName, Severity, ErrorNumber, ErrorMessage, ErrorKeyLabel, ErrorKeyFieldName, ErrorKeyValue, Details, RoleToReview, EEID, COID, ConSystemID)
SELECT CompanyCode = 'None' 
        ,PayGroup =  '' 
		,RecordType = 'Misc - ACA'
		,EmpNo = 'None'
		,EmployeeName = 'None'
		,EmploymentStatus = 'N'
		,DependentName = ''
		,Severity = 'W'
		,ErrorNumber='01201'
		,ErrorMessage = 'WARNING: Historical 1095-C data has not been imported into UltiPro.  Please work with customer to complete the template.'
		,ErrorKeyLabel = 'ACA'
		,ErrorKeyFieldName= 'ACA'
		,ErrorKeyValue = 'ACA'
		,Details = 'No ACA imports done'  
		,RoleToReview ='SC'
		,EEID = 'None'
		,COID = 'None'
		,ConSystemid=''
 -- select COUNT(*) acacos ,  
        --acaimportcount =   (select COUNT (1) from ACA1095CImportFileInfo) 
  from ACAALEMemberComponents 
	where peryear= YEAR(@LIVEDATE) 
       having  (select COUNT (1) from ACA1095CImportFileInfo) = 0
 
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
--  list summary or warnings AND errors

/*  -- TC - Use his select to collect statistics
select CmmContractNo as ' ','.Empcount','','','',(select convert(varchar, count(*)) from empcomp (NOLOCK) as  Count)
from compmast (NOLOCK)
union all
select CmmContractNo as 'AR Number', severity as Severity, errornumber, errormessage as 'ErrorMessage', RoleToReview, count(*) as Count
FROM ace_DataQualityCheck
join compmast (NOLOCK) on 1=1
group by CmmContractNo, severity, errornumber, errormessage,RoleToReview
order by 1,2,3
*/

select severity as 'Severity', errornumber as 'Error Number', errormessage as 'Error Message', RoleToReview, count(*) as Count
FROM #ace_DataQualityCheck
join company on cmpcompanycode = companycode and cmpcountrycode = @Country
group by severity, errornumber, errormessage,RoleToReview
order by severity, RoleToReview, errornumber, errormessage

-- List details.  Can be copied and pasted into Excel
select '' as 'CompanyCode','' as 'PayGroup',''as'EmpNo',''as'EmployeeName',''as'EmploymentStatus',''as'Severity',''as'ErrorNumber',''as'ErrorMessage',''as'ErrorKeyFieldName',''as'ErrorKeyValue',''as'Details',''as'DependentName',''as'RoleToReview',''as'EEID',''as'COID'
union all
select 'User Running Employee QA: '+@LastUserRunningQA,'Date of Employee QA: ' + CONVERT(varchar, @LastDateRunningQA, 120), '','','','','','','','','','','','',''
union all
select '','','','','','','','','','','','','','',''
union all
select CompanyCode, PayGroup, EmpNo, EmployeeName, EmploymentStatus, Severity, ErrorNumber,	ErrorMessage, ErrorKeyFieldName, ErrorKeyValue,	Details, DependentName,	RoleToReview, EEID,	COID
FROM #ace_DataQualityCheck join company on cmpcompanycode = companycode and cmpcountrycode = @Country WHERE severity ='e'
union all
select CompanyCode, PayGroup, EmpNo, EmployeeName, EmploymentStatus, Severity, ErrorNumber,	ErrorMessage, ErrorKeyFieldName, ErrorKeyValue,	Details, DependentName,	RoleToReview, EEID,	COID
FROM #ace_DataQualityCheck
join company on cmpcompanycode = companycode and cmpcountrycode = @Country  
WHERE severity <>'e' order by 7, 4 


/************************************************************************************************************************************** 
-- TC - Use his select to collect statistics
select CmmContractNo as ' ','.Empcount','','','',(select convert(varchar, count(*)) from empcomp (NOLOCK) as  Count)
from compmast (NOLOCK)
union all
select CmmContractNo as 'AR Number', severity as Severity, errornumber, errormessage as 'ErrorMessage', RoleToReview, count(*) as Count
FROM #ace_DataQualityCheck
join compmast (NOLOCK) on 1=1
group by CmmContractNo, severity, errornumber, errormessage,RoleToReview
order by 1,2,3
***************************************************************************************************************************************/
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
Print getdate()
RAISERROR ('Employee QA Complete', 0, 1) WITH NOWAIT
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
set nocount off


