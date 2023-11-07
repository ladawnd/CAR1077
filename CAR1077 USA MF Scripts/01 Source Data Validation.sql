 --- Create and Verify the Data_Effective_Date 

create table dbo.ace_temp_data_effective_date (data_effective_date date) 
insert dbo.ace_temp_data_effective_date   select '08/04/2023'    -- The date the data was pulled from the source system. 
 

select * from dbo.ace_temp_data_effective_date     -- Verify the date is loaded 

-- Verify Count for each table 

Select     CoCode ,  EmpNo  ,   FirstName, LastName, [Status] as EmplStatus from DBO.ACE_EMP -- ##

Select CoCode ,  EmpNo  ,   FirstName, LastName, DeductionCode  from DBO.ACE_DED --##

Select  CoCode ,  EmpNo  ,   FirstName, LastName, Sequence  from DBO.ACE_DEP -- 2998

select * from ace_dep where eeid  is null -- 2998 
 
 update ace_dep set coid =cmpcoid from company join ace_dep on cocode =cmpcompanycode 

  
 update ace_dep set eeid  =eepeeid  from emppers  join ace_dep on ssn  =eepssn  

 select * from ace_dep where  eeid is null 

 /*CoCode	Empno	SSN	SIN	LastName	FirstName
101	01019550	531842919	NULL	Solitaire	Edward*/ 

select eecempno, eeceeid  from empcomp where eecempno like '%9550' 

sp_geteeid '531842919' 

delete from ace_dep where ssn = '531842919' 

select distinct DEP_id,  E.CoCode, E.EmpNo, E.SSN, E.FirstName, E.LastName, E.[Status], AcctType, AmtOrPct, AcctNo, Routing, DepositType, [Sequence] 
from ACE_EMP E Join ACE_DEP DEP on DEP.CoCode = E.CoCode and DEP.EmpNo = E.EmpNo join ACE_OneVal on ONECompanyCode = DEP.CoCode and ONEEmpNo = DEP.EmpNo and oneRecID = DEP.DEP_ID 
where ONEErrorCode= 'E0302' and ONEProcess = 'PDUSA' order by e.CoCode, e.EmpNo, dep.Sequence;


update  ace_dep  set  sequence   =     '2'          from  ace_dep     where   dep_id  =   87   
update  ace_dep  set  sequence   =     '2'          from  ace_dep     where   dep_id  =   305   
update  ace_dep  set  sequence   =     '2'          from  ace_dep     where   dep_id  =   454   
update  ace_dep  set  sequence   =     '2'          from  ace_dep     where   dep_id  =   463   
update  ace_dep  set  sequence   =     '2'          from  ace_dep     where   dep_id  =   505   
update  ace_dep  set  sequence   =     '2'          from  ace_dep     where   dep_id  =   704   
update  ace_dep  set  sequence   =     '2'          from  ace_dep     where   dep_id  =   828   
update  ace_dep  set  sequence   =     '2'          from  ace_dep     where   dep_id  =   841   
update  ace_dep  set  sequence   =     '2'          from  ace_dep     where   dep_id  =   857   
update  ace_dep  set  sequence   =     '3'          from  ace_dep     where   dep_id  =   858   
update  ace_dep  set  sequence   =     '2'          from  ace_dep     where   dep_id  =   877   
update  ace_dep  set  sequence   =     '2'          from  ace_dep     where   dep_id  =   995   
update  ace_dep  set  sequence   =     '2'          from  ace_dep     where   dep_id  =   1009   
update  ace_dep  set  sequence   =     '2'          from  ace_dep     where   dep_id  =   1062   
update  ace_dep  set  sequence   =     '2'          from  ace_dep     where   dep_id  =   1226   
update  ace_dep  set  sequence   =     '2'          from  ace_dep     where   dep_id  =   1288   
update  ace_dep  set  sequence   =     '2'          from  ace_dep     where   dep_id  =   1361   
update  ace_dep  set  sequence   =     '2'          from  ace_dep     where   dep_id  =   1618   
update  ace_dep  set  sequence   =     '2'          from  ace_dep     where   dep_id  =   1809   
update  ace_dep  set  sequence   =     '2'          from  ace_dep     where   dep_id  =   1947   
update  ace_dep  set  sequence   =     '2'          from  ace_dep     where   dep_id  =   2086   
update  ace_dep  set  sequence   =     '2'          from  ace_dep     where   dep_id  =   2390   
update  ace_dep  set  sequence   =     '2'          from  ace_dep     where   dep_id  =   2424   
update  ace_dep  set  sequence   =     '2'          from  ace_dep     where   dep_id  =   2547   
update  ace_dep  set  sequence   =     '2'          from  ace_dep     where   dep_id  =   2642   
update  ace_dep  set  sequence   =     '2'          from  ace_dep     where   dep_id  =   2664   
update  ace_dep  set  sequence   =     '2'          from  ace_dep     where   dep_id  =   2823   
update  ace_dep  set  sequence   =     '2'          from  ace_dep     where   dep_id  =   2900   
update  ace_dep  set  sequence   =     '2'          from  ace_dep     where   dep_id  =   2907   
update  ace_dep  set  sequence   =     '2'          from  ace_dep     where   dep_id  =   2915   


---========================================
  -- Run Source Validation in Launch 
  -- Run Pre-validation in Launch 


 exec ACEsp_OneVal  'PDUSA'
 

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
		where oneTable like 'ACE_DEP%' 
	 		order by TableName, ErrorCode, FieldName, ErrorDesc, ErrorSelect, ErrorUpdate;
 
  select * from lodedep 

  update lodepers set lodepers.eepeeid =emppers.eepeeid  from emppers 
  join lodepers on lodepers.eepssn =emppers.eepssn  

    update lodedep set lodedep.eddeeid =lodepers.eepeeid  from lodepers 
  join lodedep on eeppendingupdateid =eddpendingupdateid 

  select * from lodedep where eddcoid  is null 

     update lodedep set lodedep.eddcoid=cmpcoid   from company   
  join lodedep on EddCompanyCode =cmpCompanyCode  

  select * from empdirdp 

  SELECT 
	cmpcompanycode as CoCode, 
	eecempno as EmpNo, 
	eepnamelast as LastName, 
	eepnamefirst as FirstName, 
	eepssn as SSN, 
	eddacct as AcctNo, 
	eddaccttype as AcctType, 
	eddamtorpct as AmtorPct, 
	edddepositrule as DepositType, 
	eddeebankroute as Routing, 
	eddsequence as Sequence
-- INTO dbo.ACE_TEMP_MF3_Export
-- select *
FROM empdirdp 
JOIN empcomp ON eeceeid = eddeeid and eeccoid = eddcoid
JOIN emppers ON eepeeid = eddeeid 
JOIN company ON cmpcoid = eddcoid
order by eepnamelast, eepnamefirst 
 

 select  cmpcompanycode as CoCode
  , eecempno as EmpNo
  --, Eepssn as SSN
  , eepnamefirst as FirstName, eepnamelast as LastName
  , eecemplstatus as EmplStatus
   , eeddedcode as DedCode
    , eedbenoption as BenOption
   , eedbenstatus as BenStatus
, eedeeamt as EEAmt
, eederamt as ErAmt
, eedeecalcrateorpct as PCT
, EedEEGoalAmt
, EedBenAmt
, eedstartdate as StartDate
, eedbenstartdate as BenStartDate
, eedbenstatusdate as StatusDate
, eedstopdate as StopDate
, eedbenstopdate as BenStopDate
  , eepeeid as EEID
  , eeccoid as COID
from emppers 
join empcomp  on eepeeid=eeceeid 
join company on eeccoid=cmpcoid
join empded on eeceeid=eedeeid and eeccoid=eedcoid
 order by eepnamelast, eepnamefirst, eeddedcode