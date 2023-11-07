select * from [dbo].[ACE_707XDED]
where   exists (select * from empded where DedutionCode=eeddedcode and eedeeid =eeid and eedcoid =coid) 
 

update [ACE_707XDED] set coid =cmpcoid from company 
join [ACE_707XDED] on cocode=cmpcompanycode --823



 
--EEID FROM Empno EmpComp
update [ACE_707XDED] set eeid=eeceeid from empcomp
join  [ACE_707XDED] on  empno =eecempno and COID=eeccoid


sp_geteeid 'Vasicek' 
/*COID	EEID	CoCode	EmpNo	empStat	StatusDate	EEName	eepSSN	PayGroup	TaxCalcGroupID
RERAE	EXW15Q000060	101  	01000015 	A	20130529	Vasicek,Alan	366605285  	UW    	USTAX
                                01000015
RERAE	EXW2IM000060	101  	05093488 	A	19910513	Vasicek,Frank	452399997  	UB    	USTAX*/ 


SELECT
	cmpcompanycode as CoCode, 
	eecempno as EmpNo, 
	eepnamelast as LastName, 
	eepnamefirst as FirstName, 
	eepssn as SSN
	--eeddedcode as DeductionCode, 
	--isnull(convert(char(10),eedstartdate, 101),'') as DedStartDate,
	--isnull(eedbenoption,'') as BenOption,
	--eedeeamt  
	, DedutionCode, EEAmount
 FROM [ACE_707XDED] 
JOIN empcomp ON eeid = eeceeid and eeccoid = coid
join emppers on eeid =eepeeid 
--JOIN empded  ON eepeeid = eedeeid 
JOIN company ON cmpcoid = coid 
--JOIN ACE_TEMP_MF1_Export on cmpCompanyCode = CoCode and eepSSN = SSN
join dedcode on deddedcode =DedutionCode 
 where DedIsDedOffSet ='N'  
 -- 813 

update [ACE_707XDED] set eeid ='DONE'  FROM empded 
JOIN empcomp ON eedeeid = eeceeid and eeccoid = eedcoid
JOIN emppers ON eepeeid = eedeeid 
JOIN company ON cmpcoid = eedcoid 
--JOIN ACE_TEMP_MF1_Export on cmpCompanyCode = CoCode and eepSSN = SSN
join dedcode on deddedcode =eeddedcode 
join [ACE_707XDED] on DedutionCode=eeddedcode and eedeeid =eeid and eedcoid =coid 
where DedIsDedOffSet ='N'  and EedEEAmt = eeamount 


drop table #NeedDed

select eeid as eeceeid, coid as eeccoid ,  DedutionCode as  DedCode 
into #NeedDed 
from [ACE_707XDED]  
join emppers on eeid =eepeeid 

 
 
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

-- commit 

-- Remove Stop Date - Edit the DedCodes 
begin tran
update EmpDedFull
set EedBenStatus = 'A'
	, EedBenStatusDate =   EedBenStartDate  
	, EedBenStopDate = NULL -- coverage stop date field in BackOffice
	, EedStopDate = NULL -- deduction stop date field in BackOffice
	--select * 
	from EmpDedFull
where exists (select 1 from empcomp  where EedCoID =  eecCoID and EedEEID =  eecEEID and EedStopDate is not null and  eecemplstatus <> 'T'  and EedNotes like 'PBADD'
	and EedDedCode in (select DedutionCode from [ACE_707XDED]) 
	and EedTVEndDate = '2079-06-06 00:00:00' and EedDeleted = 0)
--commit  --124

select * from [ACE_707XDED] 
 
begin tran
update EmpDed 
set   EedEEAmt=  (select cast(EEAmount as money)  from [ACE_707XDED] where eeid =eedeeid and eeddedcode = DedutionCode   )           
         from EmpDed 
where exists    (select 1  from [ACE_707XDED] where eeid =eedeeid and eeddedcode = DedutionCode   )    
 -- commit 819 

 SELECT distinct 
	cmpcompanycode as CoCode, 
	eecempno as EmpNo, 
	eepnamelast as LastName, 
	eepnamefirst as FirstName, 
 
	 DedutionCode, EEAmount
	 , eedeeamt, eeddedcode, eedstartdate, eedbenstatus, eedbenstatusdate, eedbenstartdate, eedstopdate, eedbenstopdate 
 FROM [ACE_707XDED] 
JOIN empcomp ON eeid = eeceeid and eeccoid = coid
join emppers on eeid =eepeeid 
JOIN empded  ON eeid = eedeeid and eeddedcode = DedutionCode and eedcoid =coid 
JOIN company ON cmpcoid = coid 
order by 3, 4, 5
 
 -- 813  

 sp_geteeid '01018631 ' 