SELECT
	rtrim(cmpcompanycode) +rtrim(eecempno) as PendingUpdateID   
		,eecempno as EmpNo 
		, eeccoid as COID 
	, eecEEID as EEID
	, cmpcompanycode

	,eepnamelast as LastName
	,eepnamefirst as FirstName 
 FROM empcomp 
JOIN emppers ON eepeeid = eeceeid 
JOIN company ON cmpcoid = eeccoid 
join empmloc on eeceeid = emleeid and eeccoid = emlcoid and emlIsPrimary='y'
 Order by cmpCompanyCode, eecEmpNo


 select * into dbo.ACEBkup_EmpComp_20230907 from empcomp  -- (2660 rows affected)

 select * from ACEBkup_EmpComp_20230907 

 select * from ace_emptype 

begin Tran
update empcomp set eeceetype =Source_Data 
--select lastname, firstname, Source_Data, eeceetype
from ace_emptype
join empcomp on eeid =eeceeid and  coid =eeccoid
where  eeceetype <> Source_Data 
--(1273 rows affected) 
-- commit 