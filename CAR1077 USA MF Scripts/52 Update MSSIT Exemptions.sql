select * from  [dbo].[ACE_MSSITUPDATE] where eeid is null 

select * into dbo.ACE_EmpTax_20231006 from emptax 

update [ACE_MSSITUPDATE] set eeid=eeceeid ,  coid =eeccoid from empcomp 
join [ACE_MSSITUPDATE] on empno =eecempno 

sp_geteeid '01019384' 

select distinct cmpcompanycode as cocode ,  empno, eepnamefirst, eepnamelast,  taxcode, filingstatus, exemptions, eeteeid, eettaxcode, eetfilingstatus, eetexemptions 
from [ACEbkup_EmpTax_20230915_ExtraTaxDollars] 
join empcomp on eeccoid =eetcoid and eeccoid =eetcoid 
join emppers on eepeeid =eeteeid 
join company on eetcoid =cmpcoid
join [ACE_MSSITUPDATE] on eeid =eeteeid and coid =eetcoid and taxcode =eettaxcode 
where eettaxcode ='MSSIT' 
order by 4 , 3 

Begin Tran 
update emptax set EetFilingStatus = FilingStatus
--select eettaxcode, eetfilingstatus, FilingStatus
from emptax 
join [ACE_MSSITUPDATE] on eeid =eeteeid and coid =eetcoid and taxcode =eettaxcode 
where  EetFilingStatus <> FilingStatus  
-- commit 
[dbo].[ACEbkup_EmpTax_20230915_ExtraTaxDollars]

Begin Tran 
update emptax set eetexemptions = exemptions
--select eettaxcode, eetexemptions, exemptions
from emptax 
join [ACE_MSSITUPDATE] on eeid =eeteeid and coid =eetcoid and taxcode =eettaxcode 
where  eetexemptions <> exemptions  
-- commit 


select distinct cmpcompanycode as cocode ,  empno, eepnamefirst, eepnamelast,  taxcode, filingstatus, exemptions, eeteeid, eettaxcode, eetfilingstatus, eetexemptions 
from emptax 
join empcomp on eeccoid =eetcoid and eeccoid =eetcoid 
join emppers on eepeeid =eeteeid 
join company on eetcoid =cmpcoid
join [ACE_MSSITUPDATE] on eeid =eeteeid and coid =eetcoid and taxcode =eettaxcode 
where eettaxcode ='MSSIT' 
order by 4 , 3 
