select distinct d.empno, D.DedCode from ACE_OBDED D Join ACE_OneVal on ONECompanyCode = D.CoCode and ONEEmpNo = D.EmpNo and OneRecID = D.OBDED_ID where ONEErrorCode= 'E1401' and ONEProcess = 'OBUSA' order by d.DedCode;

select eeceeid, eecempno  from empcomp where eecempno like '%1016120' 
-- 706N 
sp_Geteeid 'EXW1RZ016060' 
select eeddedcode, dedlongdesc  from empded 
join dedcode on eeddedcode = deddedcode where eedeeid ='EXW1RZ016060' and eeddedcode like '7%' 

update ACE_OBDED set DedCode = '706E' from ACE_OBDED where dedcode ='706N'  

-- Fix SSN  for 101	1015062	610410182	Luis	Carrillo Garcia 

 
 

 SELECT DISTINCT D.CoCode, D.EmpNo, D.SSN, D.FirstName, D.LastName, D.WorkState, D.ResState, D.WorkLocal, D.ResLocal, d.[Sequence], EEQTDAmt, ERQTDAmt, EEYTDAMT, ERYTDAmt FROM ACE_OBDED D JOIN ACE_OneVal ON OneRecID = D.OBDED_ID WHERE ONEErrorCode = 'E1406' AND ONEProcess = 'OBUSA' ORDER BY D.CoCode, D.EmpNo, D.SSN, D.FirstName, D.LastName, D.WorkState, D.ResState, D.WorkLocal, D.ResLocal, D.[Sequence];

 select distinct t.CoCode, T.TaxCode from ACE_OBTAX T Join ACE_OneVal on ONECompanyCode = T.CoCode and ONEEmpNo = T.EmpNo and OneRecID = T.OBTAX_ID where ONEErrorCode= 'E1480' and ONEProcess = 'OBUSA' Order by TaxCode;


 update ace_obtax set taxcode ='CASDIEE' where taxcode ='CASDI'

  SELECT Distinct E.CoCode, E.EmpNo, E.LastName, E.FirstName, E.SSN from dbo.ace_obern as E left outer join ace_translations as T on E.cocode = t.CoCode and transtype = 'COCODE' left outer join emppers on eepssn = E.ssn left outer join company on cmpcompanycode = isnull(ultiprocode1, E.CoCode) left outer join empcomp on eeceeid = eepeeid and eeccoid = cmpcoid where eeceeid is null order by E.CoCode, E.EmpNo;


  sp_geteeid 'Tapia' 

 update ace_obern set ssn='610129367' where empno ='1009975'
  update ace_obded set ssn='610129367' where empno ='1009975'
   update ace_obtax set ssn='610129367' where empno ='1009975'
---============================
-- Run Source Validation in Launch then 

EXEC ACEsp_OneVal  'OBUSA' 

-- Check for missing employees 

exec  DBO.ACEsp_GenericExcel_MissingEEs 

select * from ACE_OneVal

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
		where OneProcess = 'OBUSA'
	 		order by TableName, ErrorCode, FieldName, ErrorDesc, ErrorSelect, ErrorUpdate;
