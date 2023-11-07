select eecCompanyCode as CoCode, eecempno as EmpNo, Eepssn as SSN, eepnamefirst as FirstName, eepnamelast as LastName, eecemplstatus as EmplStatus, EecPayGroup, EecScheduledWorkHrs, pgrschedhrs from lodepers INNER JOIN lodecomp on eeppendingupdateid=eecpendingupdateid INNER JOIN Paygroup on pgrPaygroup = EecPaygroup INNER JOIN ACE_ONEVal  on ONEPENDINGUPDATEID =eepPENDINGUPDATEID and ONErecid=eecrecid WHERE ONEErrorCODE  = 'W1100' and ONEProcess = 'PDLOD';



select retpendingupdateid, eecCompanyCode as CoCode, eecempno as EmpNo, Eepssn as SSN, eepnamefirst as FirstName, eepnamelast as LastName
,  EepAddressState, eecemplstatus as EmplStatus, eecdateoflasthire, RetSRCSITResidentCode, RetUFWFilingStatusSITR
, oneField, WetUFWSITWorkInCode, WetUFWFilingStatusSITW, eemufwfilingstatusfed 
from lodepers 
INNER JOIN  lodecomp   on eeppendingupdateid=eecpendingupdateid 
INNER JOIN  lodeemst on eeppendingupdateid=eempendingupdateid 
INNER JOIN  dbo.Location ON dbo.Location.LocCode = dbo.LodEComp.EecLocation 
INNER JOIN   dbo.LodWkEtx ON dbo.LodWkEtx.WetPendingUpdateID = dbo.LodEComp.EecPendingUpdateID 
INNER JOIN dbo.LodRsEtx ON dbo.LodRsEtx.RetPendingUpdateID = dbo.LodEComp.EecPendingUpdateID 
INNER JOIN ACE_ONEVal on ONEPENDINGUPDATEID=wETPENDINGUPDATEID and ONErecid=wetrecid 
WHERE ONEErrorCODE = 'E0119' and oneTable = 'LodWkEtx' and ONEProcess = 'PDLOD' order by eecemplstatus;


			          
update   LodWkEtx  set WetUFWFilingStatusSITW ='S' from LodWkEtx where wetpendingupdateid ='10199999915         '


select distinct wetpendingupdateid, eepcompanycode as CoCode, eecempno as EmpNo, Eepssn as SSN, eepnamefirst as FirstName, eepnamelast as LastName
,  eecemplstatus as EmplStatus , eeclocation,  WetUFWSITWorkInCode, WetUFWLITWorkInCode 
, locdesc, LocSITWorkInStateCode
from LODWKETX 
join lodepers on wetpendingupdateid=eeppendingupdateid 
join lodecomp on eeppendingupdateid=eecpendingupdateid 
join ACE_ONEVal on wetpendingupdateid=ONEpendingupdateid  
join location on eeclocation =LocCode 
and wetrecid=ONErecid where ONEErrorCode= 'E0138' 
and oneTable = 'LodWkEtx'  and ONEProcess = 'PDLOD';


update LodWkEtx set WetUFWSITWorkInCode = 'INSIT' from LodWkEtx where wetpendingupdateid='10199999917         '

Update LodEEMst Set EemUFWStateSUI = 'INSUIER'
from lodeemst where   eempendingupdateid='10199999917         '

 ---------=======
 
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
		where oneTable like 'LOD%' 
	 		order by TableName, ErrorCode, FieldName, ErrorDesc, ErrorSelect, ErrorUpdate;