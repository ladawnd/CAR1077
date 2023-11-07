 
   update  ace_ded set coid =cmpcoid from company 
   join ace_ded on cocode =cmpcompanycode 

      update  ace_ded set eeid  =eepeeid  from emppers  
   join ace_ded on ssn =eepssn  
   -- (10985 rows affected)

   select * from ace_ded 

   select distinct  coid as eeccoid, eeid as eeceeid, deductioncode as Dedcode 
   into #NeedDed from ace_ded where not exists (select 1 from empded where coid=eedcoid and eeid =eedeeid and deductioncode=eeddedcode) 


   declare @COID char(5), @EEID char(12), @DedCode char(5)
declare needDedCsr cursor for
 select eecCOID, eecEEID, DedCode from #NeedDed
open needDedCsr
fetch next from needDedCsr into @COID, @EEID, @DedCode
while @@fetch_status = 0
 begin
   exec dbo.ACEsp_OBCodes_AddEmpDedRecord @EEID, @COID, @DedCode -- Inserts into EmpDed, EmpHDed, EmpVaHs
   fetch next from needDedCsr into @COID, @EEID, @DedCode
 end
close needDedCsr
deallocate needDedCsr

---========================================
  -- Run Source Validation in Launch 
  -- Run Pre-validation in Launch 
 exec ACEsp_OneVal  'PDUSA'  -- ACE_EMP Tables

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
		where oneTable like 'ACE%' 
	 		order by TableName, ErrorCode, FieldName, ErrorDesc, ErrorSelect, ErrorUpdate;
