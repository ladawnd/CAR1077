 SELECT CegEarnGroupCode FROM EarnGrp

 /*SR ACCO 
OD811E  
MECHANI 
SM#02E  */ 

select jbcjobcode, jbclongdesc from jobcode where jbcjobcode like '%SRA%' 



select Distinct eepcompanycode as CoCode , EepAddressState, EecLocation from lodepers join lodecomp on eeppendingupdateid=eecpendingupdateid join ACE_ONEVal on eecpendingupdateid=ONEpendingupdateid and EEcRECID=ONERECID where ONEErrorCode = 'E0021' and oneTable = 'LodEComp' and ONEProcess = 'PDLOD';
 


 select distinct eepcompanycode as CoCode   ,    EecSITWorkInStateCode, EecLocation  , locsitworkinstatecode
 from LODWKETX join lodepers on wetpendingupdateid=eeppendingupdateid 
 join lodecomp on eeppendingupdateid=eecpendingupdateid
 join ACE_ONEVal on wetpendingupdateid=ONEpendingupdateid 
 join location on eeclocation =loccode 
 and wetrecid=ONErecid where ONEErrorCode= 'E0143' and oneTable = 'LodWkEtx LodEComp'  and ONEProcess = 'PDLOD';

 select loccode from location where loccode ='0091'


select distinct eepcompanycode as CoCode, eecempno as EmpNo, Eepssn as SSN, eepnamefirst as FirstName, eepnamelast as LastName
,  eecemplstatus as EmplStatus  , EecSITWorkInStateCode, EecLocation , locsitworkinstatecode 
from LODWKETX join lodepers on wetpendingupdateid=eeppendingupdateid 
join lodecomp on eeppendingupdateid=eecpendingupdateid 
join ACE_ONEVal on wetpendingupdateid=ONEpendingupdateid  and wetrecid=ONErecid   
  join location on eeclocation =loccode
where ONEErrorCode= 'E0143' and oneTable = 'LodWkEtx LodEComp'  and ONEProcess = 'PDLOD';

--- Invalid Job Code 

 select Distinct eepcompanycode as CoCode, eecempno as EmpNo, eepnamefirst as FirstName, eepnamelast as LastName,  eecemplstatus as EmplStatus, eeCJobCode as InvalidJobCode from lodepers join lodecomp on eeppendingupdateid=eecpendingupdateid join ACE_ONEVal on eecpendingupdateid=ONEpendingupdateid and EEcRECID=ONERECID where ONEErrorCode = 'E0019' and oneTable = 'LodEComp' and ONEProcess = 'PDLOD' and eecjobcode not in (select jbcjobcode from jobcode);


--101 01013935 Stephanie Jones A SR ACCO - Should be ACTS2E

Begin Tran 
Update LodEComp Set EecJobCode = 'ACTS2E' Where EecJobCode = 'SR ACCO'; 

update ace_emp set jobcode = 'ACTS2E' Where  JobCode = 'SR ACCO'; 
-- commit 
 
--101 01017864 Harrison Rabenold A OD811E - Should be SV801E
update ace_emp set jobcode = 'SV801E' Where  JobCode = 'OD811E';
--101 01019375 Daniel Fernandez A MECHANI - Should be MBH06H
update ace_emp set jobcode = 'MBH06H' Where  JobCode = 'MECHANI';
--101 01019498 Shuralee Lamb A SM#02E - Should be MGO01E
update ace_emp set jobcode = 'MGO01E' Where  JobCode = 'SM#02E';


--- Invalid Location Code 
select Distinct eepcompanycode as CoCode, eecempno as EmpNo, eepnamefirst as FirstName, eepnamelast as LastName,  eecemplstatus as EmplStatus, EepAddressState, EecLocation from lodepers join lodecomp on eeppendingupdateid=eecpendingupdateid join ACE_ONEVal on eecpendingupdateid=ONEpendingupdateid and EEcRECID=ONERECID where ONEErrorCode = 'E0021' and oneTable = 'LodEComp' and ONEProcess = 'PDLOD';

update lodecomp set eeclocation ='0097R ' from lodecomp where eeclocation ='097R'

update ace_emp set LocationCode = '0097R' Where  LocationCode ='097R'
select loccode from location where loccode like '%97R' 


select  retpendingupdateid, eecCompanyCode as CoCode, eecempno as EmpNo, Eepssn as SSN, eepnamefirst as FirstName, eepnamelast as LastName
,    EepAddressState, eecemplstatus as EmplStatus, EemUFWStateSDI, Locsitworkinstatecode, RetSRCSITResidentCode, RetUFWFilingStatusSITR, WetUFWFilingStatusSITW
, eemufwfilingstatusfed, oneField, ONEFieldValue from lodepers INNER JOIN  lodecomp   on eeppendingupdateid=eecpendingupdateid  
INNER JOIN  lodeemst   on eeppendingupdateid=eempendingupdateid  
INNER JOIN  dbo.Location    ON dbo.Location.LocCode = dbo.LodEComp.EecLocation
INNER JOIN   dbo.LodWkEtx ON dbo.LodWkEtx.WetPendingUpdateID = dbo.LodEComp.EecPendingUpdateID 
INNER JOIN  dbo.LodRsEtx ON dbo.LodRsEtx.RetPendingUpdateID = dbo.LodEComp.EecPendingUpdateID 
INNER JOIN ACE_ONEVal on ONEPENDINGUPDATEID=RETPENDINGUPDATEID 
WHERE  ONEErrorCODE = 'E0075' and oneTable = 'LodEEMst LodWkEtx'  and ONEProcess = 'PDLOD' order by eecemplstatus;

 

update lodeemst set EemUFWStateSDI = 'CASDIEE' from lodeemst INNER JOIN ACE_ONEVal on ONEPENDINGUPDATEID=eempENDINGUPDATEID and ONErecid=eemrecid WHERE   ONEErrorCODE = 'E0075'  and oneTable = 'LodEEMst LodWkEtx'  and ONEProcess = 'PDLOD' and EemUFWStateWC='CA';  update lodeemst set EemUFWStateSDI = NULL from lodeemst INNER JOIN ACE_ONEVal on ONEPENDINGUPDATEID=eempENDINGUPDATEID and ONErecid=eemrecid WHERE   ONEErrorCODE = 'E0075'  and oneTable = 'LodEEMst LodWkEtx'  and ONEProcess = 'PDLOD' and EemUFWStateWC in ('NV', 'AZ');


SELECT eecpendingupdateid as PendingUpdateID , eecCompanyCode as CoCode, eecempno as EmpNo, Eepssn as SSN, eepnamefirst as FirstName, eepnamelast as LastName, eecemplstatus as EmplStatus, EecDateOfLastHire, EecDateOfOriginalHire FROM LODEPERS JOIN ACE_ONEVal ON ONEPENDINGUPDATEID=EEPPENDINGUPDATEID JOIN LODECOMP ON eepPENDINGUPDATEID=EECPENDINGUPDATEID WHERE EECRECID = ONERECID AND ONEErrorCODE = 'E0233' and oneTable = 'LodEComp' and ONEProcess = 'PDLOD'

;

update lodecomp set EecDateOfOriginalHire='9/26/2013', EecDateOfLastHire='8/27/2022' where eecpendingupdateid='10101002705         '

update ace_emp  set DateOfHire='9/26/2013', DateOfLastHire='8/27/2022' where empno ='01002705         '
 update ace_emp set SITWorkInCode =locsitworkinstatecode  from ace_emp 
 join location on loccode =ace_emp.locationcode 
 where SITWorkInCode <> locsitworkinstatecode

 update ace_emp set SITResidentCode='UTSIT'  from ace_emp where SITResidentCode='USSIT' 

 
 

  select distinct D.DeductionCode from ACE_DED D join ACE_OneVal on ONECompanyCode = D.CoCode and ONEEmpNo = D.EmpNo and ONEREcID = D.DED_ID where ONEErrorCode= 'E0009' and oneTable = 'ACE_DED' and ONEProcess = 'PDUSA' order by DeductionCode;
  update    ACE_DED set DeductionCode = '709E' where  DeductionCode = '709F'
  select distinct E.DedGroupCode, DED.DeductionCode from ACE_EMP E Join ACE_DED DED on DED.CoCode = E.CoCode and DED.EmpNo = E.EmpNo join ACE_OneVal on ONECompanyCode = DED.CoCode and ONEEmpNo = DED.EmpNo and oneRecID = DED.DED_ID where ONEErrorCode= 'E0045' and ONEProcess = 'PDUSA' order by DedGroupCode, DeductionCode;
 


 select Ded.Ded_ID, E.CoCode, E.EmpNo,   E.FirstName, E.LastName, E.[Status], DED.DeductionCode , ded.eeamt, ded.eecalcrateorpct as PCT from ACE_EMP E Join ACE_DED DED on DED.CoCode = E.CoCode and DED.EmpNo = E.EmpNo join ACE_OneVal on ONECompanyCode = DED.CoCode and ONEEmpNo = DED.EmpNo and oneRecID = DED.DED_ID where ONEErrorCode= 'E1001' and oneTable = 'ACE_DED' and ONEProcess = 'PDUSA';
 delete  from  ace_ded    where   ded_id  =  '561'       

delete  from  ace_ded    where   ded_id  =  '563'       

delete  from  ace_ded    where   ded_id  =  '565'       

delete  from  ace_ded    where   ded_id  =  '567'       

delete  from  ace_ded    where   ded_id  =  '2433'       

delete  from  ace_ded    where   ded_id  =  '2435'       

delete  from  ace_ded    where   ded_id  =  '2437'       

delete  from  ace_ded    where   ded_id  =  '2439'       

delete  from  ace_ded    where   ded_id  =  '12255'       

delete  from  ace_ded    where   ded_id  =  '12257'       

delete  from  ace_ded    where   ded_id  =  '12259'       

delete  from  ace_ded    where   ded_id  =  '12261'       

delete  from  ace_ded    where   ded_id  =  '12263'       

delete  from  ace_ded    where   ded_id  =  '12265'       


Drop table if exists dbo.ACE_TEMP_BenStartDate;  SELECT  d.CoCode,  d.EmpNo,  d.LastName,  d.FirstName,  e.Status,   d.DeductionCode as DedCode
,  CONVERT(DATETIME, CASE WHEN isnull(d.DedStartDate, '') = '' THEN e.DateOfBenSeniority ELSE d.DedStartDate END) as StartDate
,   CASE WHEN DedCode.DedIsBenefit = 'Y' THEN CONVERT(DATETIME,CASE WHEN BenStartDate <> '' THEN BenStartDate ELSE DateOfBenSeniority END)         
ELSE DateOfBenSeniority END as BenStartDate,   CASE WHEN DedCode.DedIsBenefit = 'Y' THEN CONVERT(DATETIME,CASE WHEN EEEligDate <> '' 
THEN EEEligDate ELSE DateOfBenSeniority END)       ELSE DateOfBenSeniority END as EEEligDate,  Convert(DateTime, DateOfLastHire) as DateOfLastHire Into dbo.ACE_TEMP_BenStartDate
from ACE_Ded as d JOIN ACE_OneVal ON oneRecID = d.DED_ID  
join ACE_EMP as e on e.CoCode = d.CoCode and e.SSN = d.SSN 
LEFT OUTER JOIN dbo.DedCode ON DedDedCode = DeductionCode WHERE oneErrorCode = 'E0194' and oneProcess = 'PDUSA' ORDER BY Status

 
BEGIN TRAN UPDATE D set  BenStartDate = DateofLastHire,  EEEligDate  = DateOfLastHire 
from ACE_Ded as D JOIN ACE_OneVal ON oneRecID = d.DED_ID  
join ACE_EMP as e on e.CoCode = d.CoCode and e.SSN = d.SSN 
LEFT OUTER JOIN dbo.DedCode ON DedDedCode = DeductionCode
WHERE oneErrorCode = 'E0194' and oneProcess = 'PDUSA';
/* Commit/Rollback */  /* Run after posting People Data   Select CoCode, EmpNo, DedCode, eedDedCode, StartDate, eedStartDate, BenStartDate, eedBenStartDate, eedBenStatusDate, DateOfLastHire, eecDateOfLastHire from EmpDedFull join Company on cmpCoID = eedCoID join EmpComp on eecCoID = eedCoID and eecEEID = eedEEID join ACE_TEMP_BenStartDate on CoCode = cmpCompanyCode and dbo.ACEfn_PadL(EMPNO,(select cmmempnosize from compmast),'0') = eecEmpNo and eedDedCode = DedCode and eedDeleted = 0  */ Update EmpDedfull set   eedBenStartDate  = BenStartDate,   eedBenStatusDate = BenStartDate,  eedEEEligDate  = EEEligDate from EmpDedFull join Company on cmpCoID = eedCoID join EmpComp on eecCoID = eedCoID and eecEEID = eedEEID join ACE_TEMP_BenStartDate on CoCode = cmpCompanyCode and dbo.ACEfn_PadL(EMPNO,(select cmmempnosize from compmast),'0') = eecEmpNo and eedDedCode = DedCode and eedDeleted = 0;


-- Re run validation in Launch or 
 exec ACEsp_OneVal    'PDUSA'
  exec ACEsp_OneVal_detail    'PDLOD'

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
		where oneTable like 'ACE_DED%' 
	 		order by TableName, ErrorCode, FieldName, ErrorDesc, ErrorSelect, ErrorUpdate;
