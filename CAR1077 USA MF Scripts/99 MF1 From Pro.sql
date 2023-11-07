SELECT	rtrim(cmpcompanycode) +rtrim(eecempno) as PendingUpdateID   , 
	cmpcompanycode as CoCode, 
	eecempno as EmpNo, 
	eepnamelast as LastName, 
	eepnamefirst as FirstName, 
	eepssn as SSN, 
	isnull(eepnamemiddle,'') as MiddleName, 
	isnull(eepnamepreferred,'') as PreferredName,
	isnull(EepNameSuffix,'') as NameSuffix,
	eepaddresscountry as Country, 
	eepaddresszipcode as Zip, 
	eepaddressstate as State, 
	eepaddresscity as City, 
	eepaddressline1 as Address1, 
	isnull(eepaddressline2,'') as Address2, 
	isnull(eepaddressemail,'') as Email, 
	isnull(eepAddressEMailAlternate,'') as AddressEmailAlternate,
	convert(char(10), eepdateofbirth, 110) as DOB,
	eepgender as Gender, 
	eepmaritalstatus as MaritalStatus, 
	eepethnicid as EthnicID, 
	isnull(EepPhoneHomeCountry,'') as HomePhoneCountry,
	isnull(eepphonehomenumber,'') as HomePhone, 
	isnull(EecPhoneBusinessCountry,'') as BusinessPhoneCountry,
	isnull(EecPhoneBusinessNumber,'') as BusinessPhone,
	isnull(EecPhoneBusinessExt,'') as BusinessPhoneExt,
	eecemplstatus as StatusCode, 
	convert(char(10), eecdateoforiginalhire, 110) as DateofHire,        
	convert(char(10), eecdateoflasthire, 110) as DateofLastHire,        
	convert(char(10), eecdateofseniority, 110) as DateofSeniority, 
	convert(char(10), eecdateofbenefitseniority, 110) as DateofBenSeniority,        
	convert(char(10), eecdateofnextperfreview, 110) as DateofNexPerReview,        
	convert(char(10), eecdateofnextsalreview, 110) as DateofNextSalRev, 
	isnull(convert(char(10), eecdateoftermination, 110),'') as TermDate, 
	isnull(eectermreason,'') as TermReason,
	isnull(EecLeaveReason,'') as 'LeaveReason',
	case when isnull(eecleavereason,'') <> '' then convert(char(10),(select max(EshStatusStartDate) from emphstat where esheeid = eeceeid and eshcoid = eeccoid and eshemplstatus = 'L'), 110) else '' end as 'LOAStartDate',
	eecearngroupcode as EarnGroupCode, 
	eecdedgroupcode as DedGroupCode, 
	eeceetype as EmpType, 
	eecfulltimeorparttime as FTPT,        
	eecjobcode as JobCode,
	emlcode as LocationCode, 
	isnull(eecorglvl1,'') As OrgLvl1, 
	isnull(eecorglvl2,'') As OrgLvl2, 
	isnull(eecorglvl3,'') As OrgLvl3, 
	isnull(eecorglvl4,'') As OrgLvl4,        
	isnull(EecDistributionCenterCode,'') As DistCenterCode,
	isnull(EecProject,'') As Project,
	eecpaygroup as PayGroup,        
	eecscheduledworkhrs as SchedWorkHrs,        
	EecShift as ShiftCode,
	isnull(EecTimeclockID,'') As TimeclockID,
	eecsalaryorhourly as SalaryOrHourly,     
	eecisautopaid as AutoPay, 
	iif(EecSalaryOrHourly = 'S',EecAnnSalary,0) as AnnSalary,
	iif(EecSalaryOrHourly = 'H',EecHourlyPayRate,0) as HourlyPay,       
	isnull((select distinct eepSSN from emppers where eepeeid = eecsupervisorid),'') As 'SupervisorSSN', 
	-- Federal Taxes
	(SELECT eetfilingstatus 
	FROM   emptax 
	WHERE  eettaxcode = 'USFIT' 
			AND eeteeid = eeceeid 
			AND eetcoid = eeccoid) AS 'FedFilingStatus', 
	(SELECT eetexemptions 
	FROM   emptax 
	WHERE  eettaxcode = 'USFIT' 
			AND eeteeid = eeceeid 
			AND eetcoid = eeccoid) AS 'FedExemptions',     
	(SELECT eetexemptfromtax 
	FROM   emptax 
	WHERE  eettaxcode = 'USFIT' 
			AND eeteeid = eeceeid 
			AND eetcoid = eeccoid) AS 'FedExempt', 
	(SELECT eetblocktaxamt 
	FROM   emptax 
	WHERE  eettaxcode = 'USFIT' 
			AND eeteeid = eeceeid 
			AND eetcoid = eeccoid) AS 'FedBlock', 
	(SELECT eetextrataxdollars 
	FROM   emptax 
	WHERE  eettaxcode = 'USFIT' 
			AND eeteeid = eeceeid 
			AND eetcoid = eeccoid) AS 'AddlFedAmt', 
	(SELECT eetDependentAmt 
	FROM   emptax 
	WHERE  eettaxcode = 'USFIT' 
			AND eeteeid = eeceeid 
			AND eetcoid = eeccoid) AS 'FedDependentAmt', 
	(SELECT eetOtherIncome 
	FROM   emptax 
	WHERE  eettaxcode = 'USFIT' 
			AND eeteeid = eeceeid 
			AND eetcoid = eeccoid) AS 'FedOtherIncomeAmt', 
	(SELECT eetDeductionAmt 
	FROM   emptax 
	WHERE  eettaxcode = 'USFIT' 
			AND eeteeid = eeceeid 
			AND eetcoid = eeccoid) AS 'FedDeductionAmt', 
	-- SIT Residense Taxes
	eecsitresidentstatecode as SITRes, 
	(SELECT eetfilingstatus 
	FROM   emptax 
	WHERE  eettaxcode = eecsitresidentstatecode 
			AND eeteeid = eeceeid 
			AND eetcoid = eeccoid) AS 'SITResFilingStatus', 
	(SELECT eetexemptions 
	FROM   emptax 
	WHERE  eettaxcode = eecsitresidentstatecode 
			AND eeteeid = eeceeid 
			AND eetcoid = eeccoid) AS 'SITResExemptions', 
	(SELECT EetAddlExemptions 
	FROM   emptax 
	WHERE  eettaxcode = eecsitresidentstatecode 
			AND eeteeid = eeceeid 
			AND eetcoid = eeccoid) AS 'SITResAddlExemptions', 
	(SELECT eetextrataxdollars 
	FROM   emptax 
	WHERE  eettaxcode = eecsitresidentstatecode 
			AND eeteeid = eeceeid 
			AND eetcoid = eeccoid) AS 'AddlSITResAmt',    
	(SELECT eetDependentAmt 
	FROM   emptax 
	WHERE  eettaxcode = eecsitresidentstatecode 
			AND eeteeid = eeceeid 
			AND eetcoid = eeccoid) AS 'SITResDependentAmt',    
	(SELECT eetOtherIncome 
	FROM   emptax 
	WHERE  eettaxcode = eecsitresidentstatecode 
			AND eeteeid = eeceeid 
			AND eetcoid = eeccoid) AS 'SITResOtherIncomeAmt',    
	(SELECT eetDeductionAmt 
	FROM   emptax 
	WHERE  eettaxcode = eecsitresidentstatecode 
			AND eeteeid = eeceeid 
			AND eetcoid = eeccoid) AS 'SITResDeductionAmt',    
	(SELECT eetnotsubjecttotax   --- GPS 3/8/2022 Correction Judi D 
	FROM   emptax 
	WHERE  eettaxcode = eecsitresidentstatecode 
			AND eeteeid = eeceeid 
			AND eetcoid = eeccoid) AS 'NotSubjToTaxSITR',
	-- SIT Work Taxes
	emlsitworkinstatecode as SITWork, 
	(SELECT eetfilingstatus 
	FROM   emptax 
	WHERE  eettaxcode = emlsitworkinstatecode 
			AND eeteeid = eeceeid 
			AND eetcoid = eeccoid) AS 'SITWorkFilingStatus', 
	(SELECT eetexemptions 
	FROM   emptax 
	WHERE  eettaxcode = emlsitworkinstatecode 
			AND eeteeid = eeceeid 
			AND eetcoid = eeccoid) AS 'SITWorkExemptions', 
	(SELECT EetAddlExemptions 
	FROM   emptax 
	WHERE  eettaxcode = emlsitworkinstatecode 
			AND eeteeid = eeceeid 
			AND eetcoid = eeccoid) AS 'SITResWorkExemptions',         
	(SELECT eetextrataxdollars 
	FROM   emptax 
	WHERE  eettaxcode = emlsitworkinstatecode 
			AND eeteeid = eeceeid 
			AND eetcoid = eeccoid) AS 'AddlSITWorkAmt',        
	(SELECT eetDependentAmt 
	FROM   emptax 
	WHERE  eettaxcode = emlsitworkinstatecode 
			AND eeteeid = eeceeid 
			AND eetcoid = eeccoid) AS 'SITWorkDependentAmt',        
	(SELECT eetOtherIncome 
	FROM   emptax 
	WHERE  eettaxcode = emlsitworkinstatecode 
			AND eeteeid = eeceeid 
			AND eetcoid = eeccoid) AS 'SITWorkOtherIncomeAmt',        
	(SELECT eetDeductionAmt 
	FROM   emptax 
	WHERE  eettaxcode = emlsitworkinstatecode 
			AND eeteeid = eeceeid 
			AND eetcoid = eeccoid) AS 'SITWorkDeductionAmt',        
	(SELECT eetnotsubjecttotax   ---- GPS 3/8/2022 Correction Judi D
	FROM   emptax 
	WHERE  eettaxcode = emlsitworkinstatecode 
			AND eeteeid = eeceeid 
			AND eetcoid = eeccoid) AS 'NotSubjToTaxSITW',        
	-- Local Taxes
    '' as 'PSDCode',
    isnull(EecLITResidentCounty,'') as 'LITResCounty',
    isnull(eeclitresidentcode,'') as'LITRes', 
    isnull(eeclitsdcode,'') as'LITSD', 
    isnull(emlLITWorkInCounty,'') as'LITWorkCounty',        
    isnull(emllitworkincode,'') as'LITWork',
	'' as LITOtherCode,	
	'' as LITOccCode,	
	'' as LITWccCode 
	, eepNameFormer	
	, '' as 'DateDeceased'
	, '' as  HomePhoneIsPrivate
	, '' as DisabilityType	
	, 'N' as IsDisabled	
	, eepIsSmoker	as IsSmoker 
	,eepSuppressSSN as SuppressSSN
	, eecudfield01 as SrcCoCode 
	, eecudfield02 as SrcEmpNo
	, eeccoid as COID 
	, eecEEID as EEID

--into dbo.ACE_TEMP_MF1_Export
-- select *
FROM empcomp 
JOIN emppers ON eepeeid = eeceeid 
JOIN company ON cmpcoid = eeccoid 
join empmloc on eeceeid = emleeid and eeccoid = emlcoid and emlIsPrimary='y'
where CmpCountryCode='USA'  
Order by cmpCompanyCode, eecEmpNo