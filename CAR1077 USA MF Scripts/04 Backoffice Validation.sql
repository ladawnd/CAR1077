select   eeccompanycode as CoCode, eecempno as EmpNo, Eepssn as SSN
, eepnamefirst as FirstName, eepnamelast as LastName
, eecemplstatus as EmplStatus  ,EecEEType as EEType
, EecLocation ,  WetUFWLocation, IrrFieldName,IrrTableName
from IMPERRS
join lodecomp on irrpendingupdateid=eecpendingupdateid
join LodWkEtx on irrpendingupdateid = WetPendingUpdateID
join lodepers  on irrpendingupdateid=eeppendingupdateid  
join lodehjob--and wetRECID=irrRECID

where IrrMsgCode= 'E0021 '

select   eeccompanycode as CoCode, eecempno as EmpNo, Eepssn as SSN
, eepnamefirst as FirstName, eepnamelast as LastName
, eecemplstatus as EmplStatus  ,EecEEType as EEType
from lodepers
join lodecomp on eeppendingupdateid=eecpendingupdateid
join IMPERRS on eeppendingupdateid=irrpendingupdateid  -- and EEcRECID=irrRECID
where IrrMsgCode= 'E0000'

sp_geteeid '05057090 ' 

update empcomp set eecempno ='95057090 ' where eecempno ='05057090 ' 


SELECT MtwTaxCode, MtwFilingStatus
INTO #tmpTaxTables
FROM ULTIPRO_SYSTEM.DBO.TxCdMast
JOIN ULTIPRO_SYSTEM.DBO.TxWhMast
	ON MtwDateTimeCreated = MtcDateTimeCreated
	AND MtwTaxCode = MtcTaxCode
WHERE MtcHasBeenReplaced = 'N' 
	AND MtcEffectiveDate <= GETDATE()
	AND MtcEffectiveStopDate > GETDATE()

SELECT EecPendingUpdateId,  EecCompanyCode, EecEmpno, EepNameLast, EepNameFirst, EecEmplStatus, WetUFWFilingStatusLITO, WetUFWLITOCCCode
FROM LodEComp
JOIN LodEPers
	ON EecPendingUpdateID = EepPendingUpdateID
JOIN LodWkEtx
	ON EecPendingUpdateID = WetPendingUpdateID
WHERE  ISNULL(WetPendingTransTypeLITO,'') IN ('A','U')
	AND WetUFWLITOCCCode <> ''
	AND NOT EXISTS(SELECT 1
					FROM #tmpTaxTables
					WHERE MtwTaxCode = WetUFWLITOCCCode
						AND MtwFilingStatus = WetUFWFilingStatusLITO)


						Select
    mtcProStateCode as State,
    mtwTaxCode as TaxCode,
    mtwFilingStatus as 'Filing Status',
    IsNull(mtcDefaultFilingStatus, '') as 'Default Filing Status',
    mtwStatusDescription as 'Description'
from ULTIPRO_SYSTEM..txCDMast (nolock)
JOIN ULTIPRO_SYSTEM..txWHMast (nolock) ON mtwTaxCode = mtcTaxCode AND mtwDateTimeCreated = mtcDateTimeCreated
where mtcHasBeenReplaced = 'N'
and GetDate() BETWEEN mtcEffectiveDate and mtcEffectiveStopDate
 and GetDate() BETWEEN mtcEffectiveDate and mtcEffectiveStopDate
and mtcProStateCode is not NULL
and (mtwtaxcode LIKE 'CODEN%')
 and mtctaxcode in (select ctctaxcode from taxcode)
Order by 1, 2, 3


update LodWkEtx set WetUFWFilingStatusLITO ='S' from LodWkEtx  
JOIN IMPERRS ON irrPendingUpdateID = wetPendingUpdateID
WHERE IrrMsgCode = 'E0117' and   irrrecid=wetrecid and WetUFWFilingStatusLITO ='T'
-- Commit 


SELECT distinct    EecCompanyCode  , cmpcompanyname,  EecLocation  , CmpDefaultLocation
 FROM LodEComp
JOIN LodEPers    ON EecPendingUpdateID = EepPendingUpdateID
JOIN Company     ON EecCompanyCode = CmpCompanyCode
JOIN CompMast     ON 1 = 1
 join IMPERRS on irrpendingupdateid =eecpendingupdateid and irrrecid =eecrecid 
 where irrmsgcode ='E0261' 
 order by  EecCompanyCode , eeclocation 

 select cmpcompanycode, cmpcompanyname from company 
 -------------------=======
-- Re run validation in BackOffice 

SELECT IrrMsgCode as [Code], IrrMessage as [Description], IrrTableName as [Table Name],IrrFieldName as [Column], count(*) as [Count] 
FROM IMPERRS  
WHERE SUBSTRING(IrrMsgCode,1,1) = 'E' AND IrrSessionID = 'CONV'
group BY IrrTableName,IrrFieldName,IrrMsgCode,IrrMessage ORDER BY IrrMsgCode


  Emp. No.: 99999  Name: Shelton, Dwayne .Company: MC - Mazak Corporation  You must correct the employee number to continue.