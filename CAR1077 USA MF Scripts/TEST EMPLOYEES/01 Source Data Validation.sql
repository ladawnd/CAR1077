 --- Create and Verify the Data_Effective_Date 

create table dbo.ace_temp_data_effective_date (data_effective_date date) 
insert dbo.ace_temp_data_effective_date   select 'DATE'    -- The date the data was pulled from the source system. 
 

select * from dbo.ace_temp_data_effective_date     -- Verify the date is loaded 

-- Verify Count for each table 

Select     CoCode ,  EmpNo  ,   FirstName, LastName, [Status] as EmplStatus from DBO.ACE_EMP -- 21
Select CoCode ,  EmpNo  ,   FirstName, LastName, DeductionCode  from DBO.ACE_DED --0

Select  CoCode ,  EmpNo  ,   FirstName, LastName, Sequence  from DBO.ACE_DEP -- 0


 select   eeccompanycode as CoCode, eecempno as EmpNo, Eepssn as SSN
, eepnamefirst as FirstName, eepnamelast as LastName
, eecemplstatus as EmplStatus  ,EecEEType as EEType
, EecJobCode 
from lodepers
join lodecomp on eeppendingupdateid=eecpendingupdateid
 where eecjobcode not in (select jbcjobcode from jobcode  where JbcCountryCode='USA') 


 MOB16H  

 select jbcjobcode, jbcdesc , JbcCountryCode from jobcode where JbcCountryCode='USA'  
 and jbcdesc   like '%Canada'
 order by 1 

 update lodecomp set EecJobCode ='MPH06H' from lodecomp where EecJobCode ='MOB16H'

 select * from ACE_OneVal 

select distinct CoCode, EmpNo, SSN, FirstName, LastName, [Status], SITResidentCode, SITResFilingStatus, SITWorkInCode, SitWorkFilingStatus  from ACE_EMP 
where SITResidentCode in ('TXSIT', 'FLSIT') 


select distinct CoCode, EmpNo, SSN, FirstName, LastName, [Status], SITResidentCode, SITResFilingStatus, SITResAddlAmt, SITWorkInCode, SitWorkFilingStatus , SITWorkAddlAmt from ACE_EMP 
where firstname in ('Underwood', 'FLSIT') 

Update ACE_EMP set SITResidentCode = left(AddressState, 2) + 'SIT' from ACE_EMP  where exists (select 1 from ACE_OneVal where oneRecID = Emp_ID and oneErrorCode = 'E1705' and oneProcess = 'PDUSA');
 
 
 
 SELECT Distinct empno, SITResidentCode, SITResFilingStatus from ACE_EMP join ACE_ONEVAL on CoCode = oneCompanyCode and EmpNo = oneEmpNo where ONEErrorCode = 'E0090' and oneTable = 'ACE_EMP'  and ONEProcess = 'PDUSA';
 
 update ace_emp set sitresfilingstatus ='A' from  ace_emp where empno ='01012122' 

  update ace_emp set sitresfilingstatus ='S' from  ace_emp where empno ='01018171' 

  Select
    mtcProStateCode as State,
    mtwTaxCode as TaxCode,
    mtwFilingStatus as 'Filing Status',
    IsNull(mtcDefaultFilingStatus, '') as 'Default Filing Status',
    mtwStatusDescription as 'Description'
from ULTIPRO_SYSTEM..txCDMast (nolock)
JOIN ULTIPRO_SYSTEM..txWHMast (nolock) ON mtwTaxCode = mtcTaxCode AND mtwDateTimeCreated = mtcDateTimeCreated
where mtcHasBeenReplaced = 'N'
and GetDate() BETWEEN mtcEffectiveDate and mtcEffectiveStopDate
 and GetDate() BETWEEN mtcEffectiveDate and mtcEffectiveStopDate
and mtcProStateCode is not NULL
and (mtwtaxcode LIKE '%SIT')
 and mtctaxcode in (select ctctaxcode from taxcode)
Order by 1, 2, 3
 

 UPDATE ACE_EMP SET SITWorkFilingStatus = CASE   WHEN SITWorkInCode = 'AZSIT' AND SITWorkFilingStatus = 'S' THEN 'A'  WHEN SITWorkInCode = 'AZSIT' AND SITWorkFilingStatus = 'M' THEN 'B'  WHEN SITWorkInCode = 'CTSIT' AND SITWorkFilingStatus = 'S' THEN 'A'  WHEN SITWorkInCode = 'CTSIT' AND SITWorkFilingStatus = 'M' THEN 'B'  WHEN SITWorkInCode = 'MSSIT' AND SITWorkFilingStatus = 'S' THEN 'A'  WHEN SITWorkInCode = 'MSSIT' AND SITWorkFilingStatus = 'M' THEN 'B'  WHEN SITWorkInCode = 'NJSIT' AND SITWorkFilingStatus = 'S' THEN 'A'  WHEN SITWorkInCode = 'NJSIT' AND SITWorkFilingStatus = 'M' THEN 'B'  WHEN SITWorkInCode = 'DCSIT' AND SITWorkFilingStatus = 'M' THEN 'Y'  ELSE SITWorkFilingStatus END FROM ACE_EMP join ACE_ONEVAL on oneRecID = EMP_ID where oneErrorCode = 'E0119' and oneProcess = 'PDUSA';
select CoCode, EmpNo, FirstName, LastName, Status, DateOfHire, DateOfLastHire, left(FedFilingStatus, 1) as FedFilingStatus from ACE_EMP where year(COALESCE(DateOfLastHire, '01/01/1900')) > 2019 and CHARINDEX(left(fedfilingstatus, 1), 'TUHVXYEFGIJKLON') = 0

Update ACE_EMP set FedFilingStatus = 'T' where   EmpNo in ('01002705')

Update ACE_EMP set FedFilingStatus = 'X' where   EmpNo in ('01017106')


select distinct SITWorkInCode, SitWorkFilingStatus from ACE_EMP join ACE_OneVal on ONECompanyCode = CoCode and ONEEmpNo = EmpNo where ONEErrorCode= 'E0119' and oneTable = 'ACE_EMP' and ONEProcess = 'PDUSA';

update ace_emp set  SITWorkFilingStatus='S' where SITWorkInCode='PASIT' and SITWorkFilingStatus='B'
update ace_emp set  SITWorkFilingStatus='S' where SITWorkInCode='VASIT' and SITWorkFilingStatus in ('A' , 'N', 'Y') 
 ---===========================================
 		select Distinct
			ErrorCode	= dbo.iex_fn_trim(oneErrorCode),
			TableName	= dbo.iex_fn_trim(oneTable),
			FieldName	= dbo.iex_fn_trim(oneField),
			ErrorDesc	= dbo.iex_fn_trim(oneDescription),
			ErrorVal	= ovcSQLValidation,
			ErrorSelect	= ovcSQLReview,
			ErrorUpdate	= ovcSQLUpdateExamples,
			ErrorNotes	= ovcNotes
		-- select *
		from dbo.ACE_OneVal
		left join dbo.ACE_OneVal_Catalog on ovcID = oneID --ovcProcess = oneProcess and ovcErrorCode = oneErrorCode and ovcTable = oneTable and ovcField = oneField
		where oneTable like 'ace%' 
	 		order by TableName, ErrorCode, FieldName, ErrorDesc, ErrorSelect, ErrorUpdate;

			select distinct SITWorkInCode, SitWorkFilingStatus from ACE_EMP join ACE_OneVal on ONECompanyCode = CoCode and ONEEmpNo = EmpNo where ONEErrorCode= 'E0119' and oneTable = 'ACE_EMP' and ONEProcess = 'PDUSA';

---========================================
  -- Run Source Validation in Launch 
   EXEC ACEsp_OneVal  'PDUSA'	
 
 
 -- Run Pre-validation in Launch 
  Exec dbo.ACEsp_OneVal_Detail 'PDLOD'	
  