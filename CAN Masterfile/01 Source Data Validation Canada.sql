 --- Create and Verify the Data_Effective_Date 

create table dbo.ace_temp_data_effective_date (data_effective_date date) 
insert dbo.ace_temp_data_effective_date   select '10/14/2022'    -- The date the data was pulled from the source system. 
 

select * from dbo.ace_temp_data_effective_date     -- Verify the date is loaded 
update ace_temp_data_effective_date set data_effective_date='09/25/2023'
-- Verify Count for each table 

Select     CoCode ,  EmpNo  ,   FirstName, LastName, [Status] as EmplStatus from DBO.ACE_CANEMP --  296

Select CoCode ,  EmpNo  ,   FirstName, LastName, DeductionCode  from DBO.ACE_CANDED -- 0

Select  CoCode ,  EmpNo  ,   FirstName, LastName, acctno, routing, Sequence  from DBO.ACE_CANDEP --  300


UPDATE ACE_CANDEP SET acctno = replace(acctno, '-', '') from ACE_CANDEP
where acctno like '%-%' 
  -- (9 rows affected)

  update ace_canemp set MaritalStatus='Z' where MaritalStatus='C' 

    update ace_canemp set unionlocal =NULL, UnionNational=NULL 


 
UPDATE ACE_CANEMP SET SINExpirationDate = '01/01/2024'  from ace_canemp 
join ACE_OneVal on oneempno =empno and oneerrorcode ='E1316' 

select * from ACE_OneVal

select * from ace_canemp 
alter table ace_cane

Update ACE_CANEMP Set DateOfNextSalRev =   '07/01/2024'    --   ,  DateOfLastSalReview  = dateofseniority   
from ACE_CANEMP

select * from location where loccode ='0020' -- ONPIT 

 ---====acctno====================
  -- Run Source Validation in Launch 
  -- Run Pre-validation in Launch 


 exec ACEsp_OneVal  'PDCAN'


 EXEC ACEsp_OneVal_Detail 'PDCAN'	

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
		where oneTable like 'ACE_CAN%' 
	 		order by TableName, ErrorCode, FieldName, ErrorDesc, ErrorSelect, ErrorUpdate;


			update ace_canemp set pitcode ='ONPIT' where empno ='01013085' 
 
 
  