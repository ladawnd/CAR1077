select * from optrate where cordedcode in ('D5600', 'M5600', 'M2075', 'D2075') 

select * from ACE_OneVal where oneprocess ='PDLOD' and oneCompanyCode='107' and onetable ='LODEDED' 

select  empno, dedgroupcode from ace_canemp where dedgroupcode ='ALL' 

update ace_canemp set dedgroupcode = eecdedgroupcode from empcomp 
join ace_canemp on eecempno = empno 


update ace_canded set eeid = eeceeid from empcomp 
join ace_canded on eecempno = empno 


update ace_canded set coid = CmpCoID from company 
join ace_canded on CoCode  = CmpCompanyCode 

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
		 where oneprocess ='PDLOD' and oneCompanyCode='107' and onetable ='LODEDED' 
	 		order by TableName, ErrorCode, FieldName, ErrorDesc, ErrorSelect, ErrorUpdate;

			delete from ace_canded where eed


			SELECT 'E0246', 'PDCAN',  D.COCODE, D.EmpNo, D.LastName, D.FirstName, d.DeductionCode, E.[Status], NULL, DED_ID, 'DedCode: ' + D.DeductionCode + ' - BenOption: ' + BenOption
			, 'Benefit option code is required','ACE_CANDED','BenOption' FROM ACE_CANDED D Inner Join ACE_CANEMP E ON E.CoCode = D.CoCode 
			and E.EmpNo = D.EmpNo Inner Join DedCode Ded On D.DeductionCode = Ded.DedDedCode WHERE Ded.DedEECalcRule = 21 And ISNULL(D.BenOption,'') = '';


select coid, eeid, cocode, empno , lastname, firstname  from ace_canded where eeid is null 

update ace_canded set coid =cmpcoid from company 
join ace_canded on cocode =cmpcompanycode 

update ace_canded set eeid =eeceeid  from empcomp 
join ace_canded on eecempno =empno  


select * from ace_canded
-- Fix Duplicates 

SELECT   CoCode
       , Empno
	   , LastName 
	   , FirstName 
	   , [SIN]
	   , DeductionCode
	   , isnull(DedStartDate, '') as DedStartDate
	   , isnull(BenOption , '') as BenOption 
	   ,  SUM(cast(isnull(eeamt,           '0') as float)) as EEAmt
	   	   ,  SUM(cast(isnull(EECalcRateOrPct, '0') as float)) as PCT
	   ,  SUM(cast(isnull(eramt,           '0') as float)) as ERAmt

	   
from ace_canded  
  GROUP BY     CoCode
       , Empno
	   , LastName 
	   , FirstName 
	   , [SIN]
	   , DeductionCode	   , isnull(DedStartDate, '') 
	   , isnull(BenOption , '') 
 

 -- Ben Eligibility 


 select * from ACE_OneVal where oneTable

 Update LodEDed Set EedEEEligDate = EecDateOfLastHire 
 --select Distinct EedPendingUpdateID,   eecempno,  EecDateOfLastHire , eedDedcode, EedEEEligDate, eedrecid, ACE_OneVal.*
 From LODEDED 
 JOIN empcomp   on eeceeid =eedeeid   and eeccoid =eedcoid 
 join ACE_OneVal   on eecempno = OneEmpno and oneCompanyCode=left(EedPendingUpdateID, 3) and oneTable='LodEDed' and onefield='EedEEEligDate' 
 and EedEEEligDate <> EecDateOfLastHire 

 where onetable ='LodeDed' and oneCompanyCode='107' 


 where oneErrorCode ='E0199'


 select * from LODEDED

 select distinct coid, empno  from ace_canded 

 select eedpendingupdateid, SUBSTRING(eedpendingupdateid, 4, 9) from lodeded 

 update lodeded set eedcoid ='TGELS' from lodeded where left(eedpendingupdateid , 3) ='107'

  update lodeded set eedeeid  = eeceeid  from lodeded
  join empcomp on SUBSTRING(eedpendingupdateid, 4, 9) =eecempno 


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
		 where oneprocess ='PDLOD' and oneCompanyCode='107' and onetable ='LODEDED' 
	 		order by TableName, ErrorCode, FieldName, ErrorDesc, ErrorSelect, ErrorUpdate;


			 Update LodEDed Set EedBenStartDate= EecDateOfLastHire 
 --select Distinct EedPendingUpdateID,   eecempno,  EecDateOfLastHire , eedDedcode, EedEEEligDate, eedrecid, ACE_OneVal.*
 From LODEDED 
 JOIN empcomp   on eeceeid =eedeeid   and eeccoid =eedcoid 
 join ACE_OneVal   on eecempno = OneEmpno and oneCompanyCode=left(EedPendingUpdateID, 3) and oneTable='LodEDed' and onefield='EedBenStartDate' 
 and EedEEEligDate <> EecDateOfLastHire 

 where onetable ='LodeDed' and oneCompanyCode='107' 


  Update lodeded  set EedBenAmtCalcRule =   NULL  from LodEDed 
  JOIN ACE_ONEVal  ON ONEPendingUpdateID = EedPendingUpdateID  AND EedRecID = ONERecID  AND ONEErrorCode = 'E0282' and oneTable = 'LodEDed'  and ONEProcess = 'PDLOD';

    Update lodeded  set EedBenStartDate =   EedEEEligDate  from LodEDed 
  JOIN ACE_ONEVal  ON ONEPendingUpdateID = EedPendingUpdateID  AND EedRecID = ONERecID  AND ONEErrorCode = 'E0193' and oneTable = 'LodEDed'  and ONEProcess = 'PDLOD';

   select distinct  eedcoid as eeccoid, eedeeid as eeceeid, eeddedcode  as Dedcode 
   into #NeedDed from lodeded where EedPendingUpdateID like '107%'  -- 1156 

   select * from ace_canded where eeid is not null --1156 

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
	--nd EedDedCode = '401R' 
	and EedTVEndDate = '2079-06-06 00:00:00' and EedDeleted = 0)
--commit  --124


begin tran
update EmpDed 
set EedStartDate =  (select cast(DedStartDate as date)  from ACE_CANDED where eeid =eedeeid and eeddedcode = deductioncode   ) 
    , EedEEAmt=  (select cast(EEAmt as money)  from ACE_CANDED where eeid =eedeeid and eeddedcode = deductioncode   )           
        , EedBenAmt   = (select cast( Benamt as money) from ACE_CANDED where eeid =eedeeid and eeddedcode = deductioncode  ) 
        , EedEECalcRateOrPct   =    (select cast( EECalcRateOrPct as money) from ACE_CANDED where eeid =eedeeid and eeddedcode = deductioncode  )   
           , EedERAmt   = (select cast( eramt as money) from ACE_CANDED where eeid =eedeeid and eeddedcode = deductioncode  ) 
		       , EedBenOption   = (select BenOption from ACE_CANDED where eeid =eedeeid and eeddedcode = deductioncode  ) 
 	--select eedeeid, eeddedcode, eedBenOption, EedEEAmt, EedEECalcRateOrPct, eedstopdate, eedbenstatus 
        from EmpDed 
where exists   (select 1 from ACE_CANDED  where eeid =eedeeid and eeddedcode = deductioncode  ) 
 -- commit 
 
 select empno, deductioncode, dedstartdate, eecdateoflasthire from ACE_CANDED 
 join empcomp on eecempno =empno 
 where  cast(DedStartDate as date) > eecdateoflasthire 
 

 begin tran
update EmpDed 
set EedStartDate =  (select eecdateoflasthire from empcomp where eeceeid =eedeeid and eeccoid =eedcoid ) 
  	--select eedeeid, eedstartdate, eeddedcode, eedBenOption, EedEEAmt, EedEECalcRateOrPct, eedstopdate, eedbenstatus 
        from EmpDed 
where exists   (select 1 from ACE_CANDED  where eeid =eedeeid and eeddedcode = deductioncode  ) and EedStartDate is null 
 -- commit 


--  NOT NEEDED begin tran
--update EmpDed 
--set EedBenStartDate =  EedStartDate
  	--
	select eedeeid, eedstartdate, eeddedcode, eedBenOption, EedEEAmt, EedEECalcRateOrPct, eedstopdate, eedbenstatus 
        from EmpDed 
join dedcode on eeddedcode=deddedcode 
where DedIsBenefit ='Y' and 
exists   (select 1 from ACE_CANDED  where eeid =eedeeid and eeddedcode = deductioncode  ) and EedBenStartDate is null 
 -- commit 

 select * from dedcode 
 
