
--   This statement provides a summary of the errors for the session ID of CONV.  Run this first, and use the results
--   to show which error numbers you need to research.

SELECT count(*), IrrTableName,IrrFieldName, IrrMsgCode,IrrMessage FROM IMPERRS
WHERE SUBSTRING(IrrMsgCode,1,1) = 'E' AND IrrSessionID = 'CONV'
group BY IrrTableName,IrrFieldName,IrrMsgCode,IrrMessage ORDER BY IrrMsgCode

--------------------------------------------ERROR E0000: Floating point division by zero------------------------------------------------------------------
---This is a catchall error that usually means something big is wrong.  You also get it if validating from the Master Company.
---Description sourced from Quip
---Could be an issue with their workhours
---also Could also be a duplicate Empno in EmpComp

--View error Detail
SELECT 'E0000: Floating point division by zero..'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
--select two lines above are used for issue/assumption document.
, eepcobraisactive,eecscheduledworkhrs
, CASE 
  WHEN '1' = (select TOP 1 '1' FROM EMPPERS p 
			 JOIN EMPCOMP c ON c.EecEEID = p.EepEEID
			 JOIN COMPANY ON CmpCoID = c.EecCOID 
			 WHERE p.EEPSSN = lp.EEPSSN AND CmpCompanyCode <> LC.EecCompanyCode) THEN 'Employee already in UltiPro under different company, repost IN BO as Multi-Company-Rehire'
  WHEN '2' = (select TOP 1 '2' FROM EMPPERS p 
			 JOIN EMPCOMP c ON c.EecEEID = p.EepEEID
			 JOIN COMPANY ON CmpCoID = c.EecCOID 
			 WHERE p.EEPSSN = lp.EEPSSN AND CmpCompanyCode = LC.EecCompanyCode) THEN 'Employee already in UltiPro in this company, drop this occurance and list on IA'
  WHEN '3' = (select TOP 1 '3' FROM EMPCOMP c
			  JOIN EMPPERS p ON p.eepEEID = p.eepEEID
			  WHERE c.EecEmpno = lc.EecEmpno AND p.eepSSN <> lp.eepSSN) THEN 'Empno is already in use by another employee in UltiPro, change empno'
  WHEN EecScheduledWorkHrs	IS NULL THEN 'Scheduled Work Hours (EecScheduledWorkHrs) can not be null'		
  WHEN eepcobraisactive		IS NULL THEN 'COBRA is active (eepcobraisactive) can not be null'						 						
  ELSE 'Undetermined error' END
-- select distinct eepcobraisactive,eecscheduledworkhrs
FROM IMPERRS
JOIN LodEComp LC ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers LP ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN PAYGROUP on PgrPayGroup = EecPayGroup 
WHERE IrrMsgCode = 'E0000' AND IrrSessionID = 'CONV'
ORDER BY eepcobraisactive,eecscheduledworkhrs

-- sample updates  
UPDATE LODECOMP 
SET EecScheduledWorkHrs = pgrSchedHrs 
FROM IMPERRS
JOIN LodEComp lc ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers lp ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN PAYGROUP on PgrPayGroup = EecPayGroup 
WHERE IRRMSGCODE = 'E0000' AND IrrSessionID = 'CONV'
  AND EXISTS (select TOP 1 '2' FROM EMPPERS p 
			 JOIN EMPCOMP c ON c.EecEEID = p.EepEEID
			 JOIN COMPANY ON CmpCoID = c.EecCOID 
			 WHERE p.EEPSSN = lp.EEPSSN AND CmpCompanyCode = LC.EecCompanyCode)


UPDATE LODECOMP 
SET EecEmpno = '9'+substring(EecEmpno,2,5) -- adjust as needed.  consider empno length. 
FROM IMPERRS
JOIN LodEComp lc ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers lp ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN PAYGROUP on PgrPayGroup = EecPayGroup 
WHERE IRRMSGCODE = 'E0000' AND IrrSessionID = 'CONV'
  AND EXISTS (select TOP 1 '3' FROM EMPCOMP c
			  JOIN EMPPERS p ON p.eepEEID = p.eepEEID
			  WHERE c.EecEmpno = lc.EecEmpno AND p.eepSSN <> lp.eepSSN)

UPDATE LODECOMP 
SET EecScheduledWorkHrs = pgrSchedHrs 
FROM IMPERRS
JOIN LodEComp lc ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers lp ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN PAYGROUP on PgrPayGroup = EecPayGroup 
WHERE IRRMSGCODE = 'E0000' AND IrrSessionID = 'CONV'
AND EecScheduledWorkHrs	IS NULL


-------------------------------ERROR E0001: Invalid State code----------------------------------------------------
---Description sourced from Quip
---Invalid state code. May also need to update LodRsETx as well

--View error Detail
SELECT 'E0001: Invalid State Code.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
--select two lines above are used for issue/assumption document.
, EEPADDRESSSTATE as ADDRESSSTATE,EEPADDRESSCITY as ADDRESSCITY,EEPADDRESSZIPCODE as ADDRESSZIPCODE
, RETUFWADDRESSSTATE as ResidentTaxState
-- select distinct EEPADDRESSSTATE,EEPADDRESSCITY,EEPADDRESSZIPCODE, WETUFWFILINGSTATUSSITW as UFWFILINGSTATUSSITW, WETUFWSITWORKINCODE as UFWSITWORKINCODE
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN Lodrsetx ON retPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0001' AND IrrSessionID = 'CONV' 
ORDER BY EecEmplStatus, EepNameLast, EepNameFirst, EecEmpno

-- seldom see issue but WG state on lodeded
SELECT EEDPENDINGUPDATEID,EEDDEDCODE,* 
FROM IMPERRS 
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEDed ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID AND EEDRECID=IRRRECID
WHERE IRRMSGCODE = 'E0001' AND IrrSessionID = 'CONV' 

--Sample updates

UPDATE LODEPERS SET EEPADDRESSSTATE = 'TX' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN Lodrsetx ON retPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0001' AND IrrSessionID = 'CONV' 
--and  EEPPENDINGUPDATEID = '000052407'

-- Make Lodrsetx match lodepers
UPDATE Lodrsetx SET RETUFWADDRESSSTATE = EEPADDRESSSTATE = 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN Lodrsetx ON retPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0001' AND IrrSessionID = 'CONV' 

-- for WG state issue on lodeded
UPDATE LODEDED SET EEDWGASTATE = 'ON' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN Lodrsetx ON retPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEDed ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0001' AND IrrSessionID = 'CONV' 
  --and eeddedcode = 'XXXXX'
  --and EEPADDRESSCOUNTRY = 'CAN' 
  
-------------------------------------------------------ERROR E0002: Invalid Country-------------------------------------------
--Description 

--View error Detail
SELECT 'E0002: INVALID COUNTRY..'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
--select two lines above are used for issue/assumption document.
, EEPaddresscountry as Addresscountry,EEPADDRESSSTATE as ADDRESSSTATE
-- select distinct EEPaddresscountry,EEPADDRESSSTATE
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0002' AND IrrSessionID = 'CONV' 
ORDER BY EecEmplStatus, EepNameLast, EepNameFirst, EecEmpno

-- Sample Updates

update LODEPERS SET EEPADDRESSCOUNTRY = 'USA' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0002' and eecsessionid = 'CONV'
--AND EEPADDRESSCOUNTRY = 'US'

-----------------------------------------------------ERROR 0003: Invalid Ethnic code-------------------------------------------------------
---Description

--View error Detail
SELECT 'E0003: Invalid Ethnic Code..'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
--select two lines above are used for issue/assumption document.
, EEPethnicID as ethnicID
-- select distinct EEPethnicID
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0003' AND IrrSessionID = 'CONV' 
ORDER BY EecEmplStatus, EepNameLast, EepNameFirst, EecEmpno

-- Sample updates

UPDATE LODEPERS SET EEPETHNICID = 'Z'
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0003' AND IrrSessionID = 'CONV' 
AND EEPETHNICID = '0'


UPDATE LODEPERS 
SET EepethnicID = Case 
	when EepethnicID='A' then '6'
	when EepethnicID='B' then '2' 
	when EepethnicID='W' then '1'
	when EepethnicID='H' then '3' 
	when EepethnicID='T' then '8' 
	else 'Z' end
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0003' AND IrrSessionID = 'CONV' 

------------------------------------------------------ERROR E0004: Invalid Gender----------------------------------------
--Description

--View error Detail
SELECT 'E0004: Invalid Gender Code..'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
--select two lines above are used for issue/assumption document.
, EEPGENDER as GENDER
-- select distinct EEPGENDER
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0004' AND IrrSessionID = 'CONV' 
ORDER BY EecEmplStatus, EepNameLast, EepNameFirst, EecEmpno


-- Sample Updates
UPDATE LODEPERS SET EEPGENDER = 'F' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0004' AND IrrSessionID = 'CONV' 
AND EEPGENDER is null

----------------------------------------------------ERROR E0005: Invalid Home Company ID-----------------------------------------------------
--Description

--View error Detail
SELECT 'E0005: Invalid Home Company ID..'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
--select two lines above are used for issue/assumption document.
, EEPHOMECOID as HOMECOID
-- select distinct EEPHOMECOID
-- select distinct EEPCOMPANYCODE
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0005' AND IrrSessionID = 'CONV'
ORDER BY EecEmplStatus, EepNameLast, EepNameFirst, EecEmpno


-- Sample Updates
UPDATE LODEPERS SET EEPHOMECOID = eeccoid
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0005' AND IrrSessionID = 'CONV'

------------------------------------------------------ERROR E0006: Invalid I9 Verification-----------------------------------------------
--Description

--View error Detail
SELECT 'E0006: Invalid I9 Verification..'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
--select two lines above are used for issue/assumption document.
, EEPI9VERIFIED as I9VERIFIED
-- select distinct EEPI9VERIFIED
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0006' AND IrrSessionID = 'CONV'
ORDER BY EecEmplStatus, EepNameLast, EepNameFirst, EecEmpno

-- Sample Updates
UPDATE LODEPERS SET EEPI9VERIFIED = 'Y' 
FROM IMPERRS 
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0006' AND IrrSessionID = 'CONV'


-----------------------------------------------------ERROR 0007: Invalid Marital Status-----------------------------------------
--Description

--View error Detail
SELECT 'E0007: Invalid Marital Status..'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
--select two lines above are used for issue/assumption document.
, EEPMARITALSTATUS as MARITALSTATUS_Emp
, EEMUFWMARITALSTATUS as MARITALSTATUS_Tax
-- select distinct EEPMARITALSTATUS
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEEMst ON EEMPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0007' AND IrrSessionID = 'CONV'
ORDER BY EecEmplStatus, EepNameLast, EepNameFirst, EecEmpno


-- Sample Updates

UPDATE LODEPERS SET EEPMARITALSTATUS = 'S'
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEEMst ON EEMPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0007' AND IrrSessionID = 'CONV'
  and EEPPENDINGUPDATEID IN ('000051296','000051313')

update lodeemst set EEMUFWMARITALSTATUS = 'S' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEEMst ON EEMPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0007' AND IrrSessionID = 'CONV'
  and EEPPENDINGUPDATEID IN ('000051296','000051313')


-------------------------------------------------------ERROR 0008: Invalid Name Prefix-----------------------------------------------
--Description

--View error Detail
SELECT 'E0008: Invalid Name Prefix..'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
--select two lines above are used for issue/assumption document.
, EEPNAMEPREFIX as NAMEPREFIX
-- select distinct EEPNAMEPREFIX
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0008' AND IrrSessionID = 'CONV'
ORDER BY EecEmplStatus, EepNameLast, EepNameFirst, EecEmpno


-- Sample Updates
UPDATE LODEPERS SET EEPNAMEPREFIX = case when EEPNAMEPREFIX = 'dr.'  then 'Dr'
										 when EEPNAMEPREFIX = 'Mr.'  then 'Mr'
										 when EEPNAMEPREFIX = 'Mrs.' then 'Mrs'
										 when EEPNAMEPREFIX = 'Ms' then SUBSTRING(EEPNAMEPREFIX,1,2) = 'Ms'
										 when EEPNAMEPREFIX is null then 'Z'
										 else  EEPNAMEPREFIX end
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0008' AND IrrSessionID = 'CONV'


-------------------------------------------------ERROR E0009: Invalid Deduction code.------------------------------------------------
--Description
-- Could be that you have deductions that are untranslated and you need information 
-- from SC to translate to valid UltiPro deduction code.

-- Another cause could be deductions that we don't want to load 
-- into UltiPro.  (e.g. direct deposit stored in legacy system as deductions).
-- If this case you just want to delete the specific deduction from lodeded.

--View error Detail
SELECT 'E0009: Invalid Deduction code.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
--select two lines above are used for issue/assumption form.
, EedDedCode as DedCode, EedEEAmt as Amount 
, EedBenStartDate, EedStartDate, eedEEEligDate, eecdateofbenefitseniority 
-- select distinct EedDedCode
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEDed ON EEDPENDINGUPDATEID = IRRPENDINGUPDATEID AND EEDRECID=IRRRECID
WHERE IRRMSGCODE = 'E0009' AND IrrSessionID = 'CONV'
ORDER BY EecEmplStatus, EepNameLast, EepNameFirst, EecEmpno


-- Sample Updates
DELETE FROM LODEDED
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEDed ON EEDPENDINGUPDATEID = IRRPENDINGUPDATEID AND EEDRECID=IRRRECID 
WHERE IRRMSGCODE = 'E0009' AND IrrSessionID = 'CONV'
AND EEDDEDCODE IN ('OPT','AREPA','XK2')

UPDATE LODEDED SET EedDedcode = 'FSADC'
from imperrs
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEDed ON EEDPENDINGUPDATEID = IRRPENDINGUPDATEID AND EEDRECID=IRRRECID
WHERE IRRMSGCODE = 'E0009' AND IrrSessionID = 'CONV' 
AND EEDDEDCODE IN ('FASDC')

----------------------------------------------------ERROR E0010: Invalid Name Suffix---------------------------------------------------
--Description

--View error Detail
SELECT 'E0010: Invalid Name Suffix..'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
--select two lines above are used for issue/assumption document.
, EEPNAMESUFFIX as NAMESUFFIX
-- select distinct EEPNAMESUFFIX
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0010' AND IrrSessionID = 'CONV'
ORDER BY EecEmplStatus, EepNameLast, EepNameFirst, EecEmpno

-- Sample Updates

UPDATE LODEPERS SET EEPNAMESUFFIX = case when EEPNAMESUFFIX in ('Sr.',' Sr') then 'Sr'
										 when EEPNAMESUFFIX in ('Jr.',' Jr','  Jr.') then 'Jr'
										 when EEPNAMESUFFIX = '3rd' then 'III'
										 when EEPNAMESUFFIX is null then 'Z'
										 else EEPNAMESUFFIX end
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0010' AND IrrSessionID = 'CONV'

-----------------------------------------------------ERROR E0012: Invalid CoID---------------------------------------------------
--Description
--Be sure that you are running BO Validation from the Component Company and not the Master Company.
--Also make sure that if this is a vendor conversion that all rows are deleted from the lod tables for any employee not included on the Employee Workbook. 
--If this is Launch, then it's possible you may have ADP CoCode rather than UltiPro CoCode.  Use the Launch Process to update before continuing. 

--View error Detail
SELECT 'E0012: Invalid CoID..'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
--select two lines above are used for issue/assumption document.
, EECCOID as COID
-- select distinct EECCOID
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0012' AND IrrSessionID = 'CONV'
ORDER BY EecEmplStatus, EepNameLast, EepNameFirst, EecEmpno


----------------------------------------------------ERROR E0013: Invalid Deduction Group code---------------------------------------------------
--Description
--May be hidden characters in eecdedgroupcode.  Or you may need an update from customer

--View error Detail
SELECT 'E0013: Invalid Deduction Group Code.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
--select two lines above are used for issue/assumption form.
, EECDEDGROUPCODE as DEDGROUPCODE 
-- select distinct EECDEDGROUPCODE
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEDed ON EEDPENDINGUPDATEID = IRRPENDINGUPDATEID AND EEDRECID=IRRRECID
WHERE IRRMSGCODE = 'E0013' AND IrrSessionID = 'CONV'
ORDER BY EecEmplStatus, EepNameLast, EepNameFirst, EecEmpno

-- Sample Updates
UPDATE LODECOMP SET EECDEDGROUPCODE = 'NSCA' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEDed ON EEDPENDINGUPDATEID = IRRPENDINGUPDATEID AND EEDRECID=IRRRECID
WHERE IRRMSGCODE = 'E0013' AND IrrSessionID = 'CONV'
AND EECDEDGROUPCODE = 'NCSA'

UPDATE LODECOMP SET EECDEDGROUPCODE = 'NONE' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEDed ON EEDPENDINGUPDATEID = IRRPENDINGUPDATEID AND EEDRECID=IRRRECID
WHERE IRRMSGCODE = 'E0013' AND IrrSessionID = 'CONV'
AND  EECPENDINGUPDATEID = 'U4P012318'


----------------------------------------------------ERROR E0014: Invalid Employee Type in JobHistory---------------------------------------------------
--Description 

--View error Detail
SELECT 'E0014: Invalid Employee Type in Job History.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
--select two lines above are used for issue/assumption document.
, EECEETYPE as EETYPE
-- select distinct EECEETYPE, EECEMPLSTATUS
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0014' AND IrrSessionID = 'CONV'
ORDER BY EecEmplStatus, EepNameLast, EepNameFirst, EecEmpno

-- Sample Updates
UPDATE LODECOMP SET EECEETYPE = 'TRM'
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0014' AND IrrSessionID = 'CONV'
AND EECEETYPE = 'TEM'


------------------------------------------------ERROR E0015: Invalid Employee Status code---------------------------------------------------
--Description 
-- Missing Employee Status.  One option is to default to A, add to issues & assumptions 

--View error Detail
SELECT 'E0015: Invalid Employee Status..'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
--select two lines above are used for issue/assumption document.
, EEMUFWEMPLSTATUS as UFWEMPLSTATUS
-- select distinct EECEMPLSTATUS
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEEMST ON EEMPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0015' AND IrrSessionID = 'CONV'
ORDER BY EecEmplStatus, EepNameLast, EepNameFirst, EecEmpno


-- Sample Updates

UPDATE LODEEMST SET EEMUFWEMPLSTATUS = EECEMPLSTATUS 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEEMST ON EEMPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0015' AND IrrSessionID = 'CONV'

UPDATE LODEEMST SET EEMUFWEMPLSTATUS = 'A'
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEEMST ON EEMPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0015' AND IrrSessionID = 'CONV'
--AND EEMUFWEMPLSTATUS = 'P'


----------------------------------------------------ERROR E0016: Invalid FTPT Code---------------------------------------------------
--Description
--The filling statuses doesn't exist in the setup or wrong. It could be that they are in a location that has local taxes, but they didn't provide a local --filling status, so load tables defualted to whatever is in their Work SIT filling.



--View error Detail
SELECT 'E0016: Invalid FTPT Code..'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
--select two lines above are used for issue/assumption document.
,EECFULLTIMEORPARTTIME as FULLTIMEORPARTTIME
-- select distinct EECFULLTIMEORPARTTIME
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0016' AND IrrSessionID = 'CONV'
ORDER BY EecEmplStatus, EepNameLast, EepNameFirst, EecEmpno


-- Sample Updates

UPDATE LODECOMP SET EECFULLTIMEORPARTTIME = 'F' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0016' AND IrrSessionID = 'CONV'


----------------------------------------------------ERROR E0017: Invalid Hire Source---------------------------------------------------
--Description

SELECT 'E0017: Invalid Hire Source..'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
--select two lines above are used for issue/assumption document.
,EECHIRESOURCE as HIRESOURCE
-- select distinct EECHIRESOURCE
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0017' AND IrrSessionID = 'CONV'
ORDER BY EecEmplStatus, EepNameLast, EepNameFirst, EecEmpno

-- Sample Updates

update LODECOMP SET EECHIRESOURCE = 'Z' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0017' AND IrrSessionID = 'CONV'

update LODECOMP SET EECHIRESOURCE = 'PREMP' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0017' AND IrrSessionID = 'CONV' 
AND EECHIRESOURCE = 'PREEMP'

---------------------------ERROR E0018: Invalid Job Change Reason code------------------------------------
--Description 
--If found in MF, it probably because they have incorrect term reasons

SELECT 'E0018: Invalid Job Change Reason Code..'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
--select two lines above are used for issue/assumption document.
,EecJobCode as JOBCODE 
, eecjobchangereason as JOBCHANGEREASON , 
eecdateoftermination as DATEOFTERMINATION,  eectermreason as TERMREASON
-- select distinct EECJOBCHANGEREASON
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0018' AND IrrSessionID = 'CONV'
ORDER BY EecEmplStatus, EepNameLast, EepNameFirst, EecEmpno

-- Sample Updates 

UPDATE LodEComp set eecjobchangereason = 'Enter Correct code here'
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0018' AND IrrSessionID = 'CONV' 
and eecjobchangereason = 'Enter invalid code here'

----------------------------------------------------ERROR E0019: Invalid Job code.---------------------------------------------------
--Description

--View error Detail
SELECT 'E0019: Invalid Job code.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EecJobCode as JobCode
-- select distinct EecJobCode
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0019' AND IrrSessionID = 'CONV'
  and IrrTableName = 'LODECOMP'
ORDER BY EecEmplStatus, EepNameLast, EepNameFirst, EecEmpno

-- Sample Updates

UPDATE LODECOMP
SET EecJobCode = 'FSADC'
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0019' AND IrrSessionID = 'CONV'
  and IrrTableName = 'LODECOMP'
  and EecJobCode IN ('FASDC')

  -------------------------------------------------ERROR E0020: Jobgroupcode---------------------------------------------------
--Description

SELECT 'E0020: Jobgroupcode.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EecJobCode as JobCode, EECJOBGROUPCODE as JOBGROUPCODE, EECISMULTIPLEJOB as MULTIPLEJOB
-- select distinct EecJobCode, EECJOBGROUPCODE, EECISMULTIPLEJOB
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0020' AND IrrSessionID = 'CONV'
ORDER BY EecEmplStatus, EepNameLast, EepNameFirst, EecEmpno

-- Sample Updates

UPDATE LODECOMP SET EECJOBGROUPCODE = NULL,EECISMULTIPLEJOB = 'N' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0020' AND IrrSessionID = 'CONV'

-----------------------------------------------------ERROR E0021: Invalid Location Code---------------------------------------------------
-- Description 

SELECT 'E0021: Invalid Location Code.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECLOCATION as LOCATION,EECSITWORKINSTATECODE as SITWORKINSTATECODE,EECSTATESUI as STATESUI,EECWCSTATE as WCSTATE, EECLITWORKINCODE as LITWORKINCODE
-- select distinct eeccompanycode,EECLOCATION,EECSITWORKINSTATECODE,EECSTATESUI,EECWCSTATE,EECLITWORKINCODE ,EECEMPLSTATUS
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0021' AND IrrSessionID = 'CONV'
AND IRRTABLENAME = 'LODWKETX'
--AND EECEMPLSTATUS <> 'T' 
--AND WETPENDINGUPDATEID = 'U15052977'
--WHERE EECEMPNO = '098'
--AND WETUFWLOCATION IN ('111','XQSMNC')
--AND WETUFWSITWORKINCODE = 'PASIT' 
--AND WETUFWLOCATION = ' '
--AND EECLOCATION IN ('QSMNV','QSMNC')
--AND EECLOCATION NOT IN (SELECT LOCCODE FROM LOCATION)
ORDER BY EecEmplStatus, EepNameLast, EepNameFirst, EecEmpno

-- List of all valide location codes
SELECT LOCCODE,* FROM LOCATION ORDER BY LOCCODE

-- Sample Updates

UPDATE LODECOMP SET EECLOCATION = 'QSM' --, EecSITWorkInStateCode = 'CASIT'
--SELECT DISTINCT EECLOCATION
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0021' AND IrrSessionID = 'CONV'
AND IRRTABLENAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T' 
--AND WETPENDINGUPDATEID = 'U15052977'
--and EECEMPNO = '098'
--AND WETUFWLOCATION IN ('111','XQSMNC')
--AND WETUFWSITWORKINCODE = 'PASIT' AND WETUFWLOCATION = ' '
--AND WETUFWSITWORKINCODE = 'PASIT'
AND EECLOCATION IN ('QSMNV','QSMNC')
--AND EECLOCATION NOT IN (SELECT LOCCODE FROM LOCATION)

UPDATE LODWKETX SET EECLOCATION= EECLOCATION
--SELECT DISTINCT EECLOCATION
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0021' AND IrrSessionID = 'CONV'
AND IRRTABLENAME = 'LODWKETX'

---------------------------------------------------ERROR E0022: Invalid Org Level1 code---------------------------------------------------
--Description
--    If you have an error in OrgLvl 2,3, or 4, the system will give you this error as well, regardless of whether
--    your Org 1 codes are bad or not.  Error will disappear once other org levels are fixed.

SELECT 'E0022: Invalid Org Level 1 Code.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECORGLVL1 AS ORGLVL1, EECORGLVL2 AS ORGLVL2, EECORGLVL3 AS ORGLVL3, EECORGLVL4 AS ORGLVL4 
-- select distinct EECORGLVL1, EECORGLVL2, EECORGLVL3, EECORGLVL4
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0022' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
ORDER BY EecEmplStatus, EepNameLast, EepNameFirst, EecEmpno

-- Sample Updates

UPDATE LODECOMP SET EECORGLVL1 = 'CATHC' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0022' AND IrrSessionID = 'CONV'
AND EECORGLVL1 IN ('CATHCO')
--and irrtableNAME = 'LODECOMP'

UPDATE LODECOMP SET EECORGLVL1 = '0'+ EECORGLVL1
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0022' AND IrrSessionID = 'CONV'
AND EECORGLVL1 IN ('CATHCO')

----------------------------------------------------ERROR E0023: Invalid Org Level2 code---------------------------------------------------
--Description
--The error counts for Error 23,24, and 25 are usually twice what they really are.
--May set to NULL if it's not obvious which valid Orglvl2 they intended

SELECT 'E0023: Invalid Org Level 2 Code.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECORGLVL1 AS ORGLVL1, EECORGLVL2 AS ORGLVL2, EECORGLVL3 AS ORGLVL3, EECORGLVL4 AS ORGLVL4 
-- select distinct EECORGLVL1, EECORGLVL2, EECORGLVL3, EECORGLVL4
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0023' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
ORDER BY EecEmplStatus, EepNameLast, EepNameFirst, EecEmpno

-- Sample Updates

UPDATE LODECOMP SET EECORGLVL2 = 'CAT' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0023' AND IrrSessionID = 'CONV'
AND EECORGLVL2 IN ('CATH')

UPDATE LODECOMP SET EECORGLVL2 = '0'+ EECORGLVL2
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0022' AND IrrSessionID = 'CONV'


----------------------------------------------------ERROR E0024: Invalid Org Level 3---------------------------------------------------
--Description

SELECT 'E0024: Invalid Org Level 3 Code.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECORGLVL1 AS ORGLVL1, EECORGLVL2 AS ORGLVL2, EECORGLVL3 AS ORGLVL3, EECORGLVL4 AS ORGLVL4 
-- select distinct EECORGLVL1, EECORGLVL2, EECORGLVL3, EECORGLVL4
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0024' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
ORDER BY EecEmplStatus, EepNameLast, EepNameFirst, EecEmpno

-- Sample Updates

UPDATE LODECOMP SET EECORGLVL3 = 'TIGER' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0023' AND IrrSessionID = 'CONV'
AND EECORGLVL3 IN ('TAGER')

UPDATE LODECOMP SET EECORGLVL3 = '0'+ EECORGLVL3
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0022' AND IrrSessionID = 'CONV'


----------------------------------------------------ERROR E0025: INVALID Org Level 4--------------------------------------------------
--Description

SELECT 'E0025: Invalid Org Level 4 Code.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECORGLVL1 AS ORGLVL1, EECORGLVL2 AS ORGLVL2, EECORGLVL3 AS ORGLVL3, EECORGLVL4 AS ORGLVL4 
-- select distinct EECORGLVL1, EECORGLVL2, EECORGLVL3, EECORGLVL4
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0025' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
ORDER BY EecEmplStatus, EepNameLast, EepNameFirst, EecEmpno

-- Sample Updates

UPDATE LODECOMP SET EECORGLVL4 = 'FISH' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0023' AND IrrSessionID = 'CONV'
AND EECORGLVL4 IN ('FISHY')

UPDATE LODECOMP SET EECORGLVL4 = '0'+ EECORGLVL4
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0022' AND IrrSessionID = 'CONV'


----------------------------------------------------ERROR E0026: INVALID PAYGROUP--------------------------------------------------
--Description

SELECT 'E0026: Invalid Paygroup.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECPAYGROUP AS PAYGROUP, EECPAYPERIOD AS PAYPERIOD, EECCOMPANYCODE AS COMPANYCODE
-- select distinct EECPAYGROUP, EECPAYPERIOD, EECCOMPANYCODE
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0026' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND eecpaygroup is null
--AND EECEMPLSTATUS <> 'T'
--AND EECPAYPERIOD = 'B'
--AND EECCOMPANYCODE = 'LNCSL'
ORDER BY EecEmplStatus, EepNameLast, EepNameFirst, EecEmpno

-- Sample Updates

update lodecomp set eecpaygroup = 'EXEMPT'
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0026' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND eecpaygroup is null
--AND EECEMPLSTATUS <> 'T'
--AND EECPAYPERIOD = 'B'
--AND EECCOMPANYCODE = 'LNCSL'

UPDATE LODECOMP SET EECPAYGROUP = 'LNCMBW'
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0026' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND eecpaygroup is null
--AND EECEMPLSTATUS <> 'T'
AND EECPAYPERIOD = 'B'
AND EECCOMPANYCODE = 'LNCSL'


----------------------------------------------------ERROR E0027: INVALID PAYGROUP---------------------------------------------------
--Description

SELECT 'E0027: Invalid Paygroup.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECPAYGROUP AS PAYGROUP, EECPAYPERIOD AS PAYPERIOD, EECCOMPANYCODE AS COMPANYCODE
-- select distinct EECPAYGROUP, EECPAYPERIOD, EECCOMPANYCODE
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0027' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
--AND eecpaygroup is null
--AND EECEMPLSTATUS <> 'T'
--AND EECPAYPERIOD = 'B'
--AND EECCOMPANYCODE = 'LNCSL'
ORDER BY EecEmplStatus, EepNameLast, EepNameFirst, EecEmpno

-- Sample Updates

update LODECOMP SET EECPAYGROUP = 'BIWEEK',EECPAYPERIOD = 'B'
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0027' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
--AND eecpaygroup is null
--AND EECEMPLSTATUS <> 'T'
AND EECPAYPERIOD = 'S'
--AND EECCOMPANYCODE = 'LNCSL'

----------------------------------------------------ERROR E0031: Invalid Project Code------------------------------------------------
--Description

SELECT 'E0031: Invalid Project Code.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECPROJECT AS PROJECT
-- select distinct EECPROJECT
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0031' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
ORDER BY EecEmplStatus, EepNameLast, EepNameFirst, EecEmpno

-- Sample Updates

update LODECOMP SET EECPROJECT = NULL
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0031' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'

update LODECOMP SET EECPROJECT = RTRIM(EECPROJECT) 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0031' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'

----------------------------------------------------ERROR E0032: Invalid Salaryorhourly ---------------------------------------------------
--Description
--could also be an invalid jobcode

SELECT 'E0032: Invalid Hourlyorsalary.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECSALARYORHOURLY AS SALARYORHOURLY, EEJOBCODE AS JOBCODE
-- select distinct EECSALARYORHOURLY, EEJOBCODE
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0032' AND IrrSessionID = 'CONV'
AND EECEMPLSTATUS <> 'T'
ORDER BY EecEmplStatus, EepNameLast, EepNameFirst, EecEmpno

-- Sample Updates

update LODECOMP SET EECSALARYORHOURLY = 'H' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0032' AND IrrSessionID = 'CONV'
AND EECSALARYORHOURLY = ''
AND EECEMPLSTATUS <> 'T'

----------------------------------------------------ERROR E0033: Invalid Shift---------------------------------------------------
--Description

SELECT 'E0033: Invalid Shift.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECSHIFT AS SHIFT
-- select distinct EECSHIFT
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0033' AND IrrSessionID = 'CONV'
AND EECEMPLSTATUS <> 'T'
ORDER BY EecEmplStatus, EepNameLast, EepNameFirst, EecEmpno

-- Sample Updates

UPDATE LODECOMP SET EECSHIFT = '0' + EECSHIFT
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0033' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
ORDER BY EecEmplStatus, EepNameLast, EepNameFirst, EecEmpno


UPDATE LODECOMP SET EECSHIFT = 'Z' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0033' AND IrrSessionID = 'CONV'
AND EECSHIFT = '00'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
ORDER BY EecEmplStatus, EepNameLast, EepNameFirst, EecEmpno


----------------------------------------------------ERROR E0035: INVALID UNIONLOCAL---------------------------------------------------
--Description

SELECT 'E0035: Invalid UnionLocal.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECUNIONLOCAL as UNIONLOCAL, EECUNIONNATIONAL AS UNIONNATIONAL
-- select distinct EECUNIONLOCAL, EECUNIONNATIONAL 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0035' AND IrrSessionID = 'CONV'
AND EECEMPLSTATUS <> 'T'
ORDER BY EecEmplStatus, EepNameLast, EepNameFirst, EecEmpno

-- Sample Updates

UPDATE LODECOMP SET EECUNIONLOCAL = NULL
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0035' AND IrrSessionID = 'CONV'
AND EECUNIONLOCAL = 'NONE'
AND EECEMPLSTATUS <> 'T'

----------------------------------------------------ERROR E0036: Invalid Unionlocal, UnionNational---------------------------------------------------
--Description

SELECT 'E0036: Invalid UnionLocal, UnionNational.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECUNIONLOCAL as UNIONLOCAL, EECUNIONNATIONAL AS UNIONNATIONAL
-- select distinct EECUNIONLOCAL, EECUNIONNATIONAL 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0036' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
ORDER BY EecEmplStatus, EepNameLast, EepNameFirst, EecEmpno

-- Sample Updates

UPDATE LODECOMP SET EECUNIONNATIONAL = NULL
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0036' AND IrrSessionID = 'CONV'
AND EECUNIONLOCAL = 'NONE'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'


UPDATE LODECOMP SET EECUNIONNATIONAL = NULL
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0036' AND IrrSessionID = 'CONV'
--AND EECUNIONLOCAL = 'NONE'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'

----------------------------------------------------ERROR E0037: INVALID EARNGROUPCODE---------------------------------------------------
--Description

SELECT 'E0037: Invalid EarnGroupCode.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECEARNGROUPCODE as EARNGROUPCODE
-- select distinct EECEARNGROUPCODE
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0037' AND IrrSessionID = 'CONV'
--AND EECEARNGROUPCODE = 'EarnG'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
ORDER BY EecEmplStatus, EepNameLast, EepNameFirst, EecEmpno

-- Sample Updates

UPDATE LODECOMP SET EECEARNGROUPCODE = 'LNCSL' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0037' AND IrrSessionID = 'CONV'
AND EECEARNGROUPCODE = 'Z'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'

---------------------------------------------------------ERROR E0038: EARNING CODE NOT IN EARNINGS PROGRAM-------------------------------
--Description
--The employees are in a earngroup and are getting some sort of earning (i.e. GTL) but GTL is not in the earning group that they are in.

--The employee has an earnings group that does not allow benefits, so the system can't add GTL. However, their deduction group is a deduction 
--group that does allow benefits

SELECT 'E0038: Earnings Code is not in Earnings Program.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECEARNGROUPCODE as EARNGROUPCODE, eeeearncode AS EARNCODE
-- select distinct EECEARNGROUPCODE, EEEEARNCODE
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN Lodeearn ON EEePENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0038' AND IrrSessionID = 'CONV'
AND EEERECID = IRRRECID
--AND EEEEARNCODE NOT IN (SELECT CEPEARNCODE FROM EARNPROG WHERE CEPEARNGROUPCODE = 'ALL')
--AND EECEARNGROUPCODE = 'EarnG'
AND EECEMPLSTATUS <> 'T'
ORDER BY EecEmplStatus, EepNameLast, EepNameFirst, EecEmpno

/*
The following select will show you imputed earning codes in the deduction code setup.
The earning codes need to be in the earning group (they DO NOT have to be set to auto add).
*/

--Show Imputed Earning Codes
select DEDIMPUTEDEARN from dedcode 
where DedIncInImpInc = 'Y'

-- Sample Updates

UPDATE LODECOMP SET EECEARNGROUPCODE = 'SAL'
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN Lodeearn ON EEePENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0038' AND IrrSessionID = 'CONV'
AND EEERECID = IRRRECID
--AND EEEEARNCODE NOT IN (SELECT CEPEARNCODE FROM EARNPROG WHERE CEPEARNGROUPCODE = 'ALL')
--AND EECEARNGROUPCODE = 'EarnG'
AND EECEMPLSTATUS <> 'T'

DELETE FROM LODEEARN
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN Lodeearn ON EEePENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0038' AND IrrSessionID = 'CONV'
AND EEERECID = IRRRECID
--AND EEEEARNCODE NOT IN (SELECT CEPEARNCODE FROM EARNPROG WHERE CEPEARNGROUPCODE = 'ALL')
--AND EECEARNGROUPCODE = 'EarnG'
and EEEEARNCODE = 'ALL'


--Example Insert into EarnProg for Imputed Earning Codes.
-- Best approach is to work with SC to add earning codes to earning program.
-- This commented out approach is a last resort it you can't contact SC.  You 
-- need to add a note in the IA that you updated earning group.  Be specific about
-- what you updated (earncode and earning program
/*
begin tran
insert into EarnProg
(
CepAutoAdd,
CepEarnCode,
CepEarnGroupCode,
CepWaitingPeriod
)
select 
CepAutoAdd = 'N',
CepEarnCode = DedImputedEarn,
CepEarnGroupCode = CegEarnGroupCode,
CepWaitingPeriod = 0
from dedcode
cross join EarnGrp
where DedIncInImpInc = 'Y' and not exists (select 1 from earnprog where cepearncode = DedImputedEarn and CegEarnGroupCode = CepEarnGroupCode)
--rollback
--commit
*/

-------------------------------------------------ERROR E0039: NOT SURE-------------------------------------
--Description

SELECT 'E0039: NOT SURE OF ERROR MESSAGE.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EEDDEDCODE AS DEDCODE, EEDBENAMTCALCRULE AS BENAMTCALCRULE
-- select distinct EEDDEDCODE, EEDBENAMTCALCRULE
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0039' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'

SELECT DEDDEDCODE 
FROM DEDCODE 
WHERE DEDBENCALCRULE = '21'

SELECT CORBENOPTION,CORDEDCODE 
FROM OPTRATE 
WHERE CORBENOPTION = 'NONE' 
ORDER BY CORDEDCODE


-------------------------------------------------------------------ERROR E0040: Invalid Benefit Status-------------------------------------------------------------
--Description

SELECT 'E0040: INVALID BENEFIT STATUS.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EEDBENSTATUS AS BENSTATUS, EEDSTOPDATE AS STOPDATE
-- select distinct EEDBENSTATUS
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0040' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'

-- Sample Updates

update lodeded set eedbenstatus = 'A' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0040' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
AND eedbenstatus = 'L'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'


UPDATE LODEDED SET EEDBENSTATUS = 'T',EEDBENSTOPDATE = EEDBENSTARTDATE
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0040' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND eedbenstatus = 'L'
WHERE EEDDEDCODE = '401CU'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--EEDPENDINGUPDATEID = '259606607CM199S'


----------------------------------------------------------ERROR E0042: Invalid EEPerCapCalcRule----------------------------------------------------
--Description

SELECT 'E0042: INVALID PER CAP CALC RULE.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EEDDEDCODE AS DEDCODE,EedEEPerCapCalcRule AS EEPerCapCalcRule
-- select distinct EEDDEDCODE, EedEEPerCapCalcRule
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0042' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'

-- Sample Updates

UPDATE LODEDED SET EedEEPerCapCalcRule = NULL
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0042' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
AND EedEEPerCapCalcRule = 'NU'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'

------------------------------------------------------ERROR E0044: Invalid Benefit Option codes-----------------------------------------------
--Description

SELECT 'E0044: INVALID BENEFIT OPTION CODE.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EEDDEDCODE AS DEDCODE,EEDBENOPTION AS BENOPTION, EEDEEAMT AS EEAMT, eedeecalcrateorpct AS eecalcrateorpct
-- select distinct EEDDEDCODE,EEDBENOPTION
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0044' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'

-- Sample Updates

UPDATE LODEDED SET EEDBENOPTION = 'C10000' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0044' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
AND EEDBENOPTION = 'CL1000'
--AND eeddedcode = 'ADD'
--AND EEDBENOPTION NOT LIKE 'EE%'
AND EEDDEDCODE IN ('DENPH','DENPS','DENVH','DENVS','DEVUM','DEPUM','MEDH','MEDS','MEUM','SADDH','VISNH','VISNS')
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'

-- use if missing eedbenoption but eedeeamt was provided
UPDATE LodEDed
SET EedBenOption = CorBenOption
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN OptRate ON EedDedCode = CorDedCode AND EedEEAmt = CorEERate 
WHERE IRRMSGCODE = 'E0044' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID

DELETE LODEDED 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0044' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
AND EEDBENOPTION = 'CL1000'
--AND eeddedcode = 'ADD'
--AND EEDBENOPTION NOT LIKE 'EE%'
--AND EEDEEAMT = .63 
--AND EEDDEDCODE IN ('DENPH','DENPS','DENVH','DENVS','DEVUM','DEPUM','MEDH','MEDS','MEUM','SADDH','VISNH','VISNS')
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'


------------------------------------------ERROR E0045: DEDUCTION CODE NOT IN DEDUCTION PROGRAM-------------------------------
--Description
-- May add the deduction to the dedgroup, or delete the deduction from being loaded
--
-- Include in Issues & Assumptions

SELECT 'E0045: DEDUCTION CODE NOT IN DEDUCTION PROGRAM.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EEDDEDCODE AS DEDCODE,eecdedgroupcode as dedgroupcode
-- select distinct EEDDEDCODE,eecdedgroupcode
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0045' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--and eecdedgroupcode <> 'EXEC'
--and eeddedcode = '403B'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
--AND EEDDEDCODE NOT IN (SELECT CBPDEDCODE FROM BENPROG WHERE CBPBENGROUPCODE = 'BAP')
--AND EEDDEDCODE IN ('PMDH','PMDC','PMDHA','PMDB')
-- AND EECEMPNO = '000138'

-- Sample Updates

update lodeded set eeddedcode = 'E403B' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0045' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
and eecdedgroupcode <> 'EXEC'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
and eeddedcode = '403B'
--AND EEDDEDCODE NOT IN (SELECT CBPDEDCODE FROM BENPROG WHERE CBPBENGROUPCODE = 'BAP')
--AND EEDDEDCODE IN ('PMDH','PMDC','PMDHA','PMDB')
-- AND EECEMPNO = '000138'

delete lodeded 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0045' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
and eeddedcode = 'xxxxx'


------------------------------------------------------------ERROR E0046: INVALID PAYEEID-------------------------------------------
--Description:

SELECT 'E0046: INVALID PAYEEID.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EEDDEDCODE AS DEDCODE,EEDPAYEEID AS PAYEEID
-- select distinct EEDDEDCODE,EEDPAYEEID
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0046' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--and eecdedgroupcode <> 'EXEC'
--and eeddedcode = '403B'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEDDEDCODE NOT IN (SELECT CBPDEDCODE FROM BENPROG WHERE CBPBENGROUPCODE = 'BAP')
--AND EEDDEDCODE IN ('PMDH','PMDC','PMDHA','PMDB')
-- AND EECEMPNO = '000138'

-- Sample Updates

UPDATE LODEDED SET EEDPAYEEID = 'Z'
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0046' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
AND EEDPAYEEID = 'Y'
--and eecdedgroupcode <> 'EXEC'
--and eeddedcode = '403B'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEDDEDCODE NOT IN (SELECT CBPDEDCODE FROM BENPROG WHERE CBPBENGROUPCODE = 'BAP')
--AND EEDDEDCODE IN ('PMDH','PMDC','PMDHA','PMDB')
-- AND EECEMPNO = '000138'


UPDATE LODEDED SET EEDPAYEEID = REPLACE(EEDPAYEEID,'-','') 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0046' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EEDPAYEEID = 'Y'
--and eecdedgroupcode <> 'EXEC'
--and eeddedcode = '403B'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEDDEDCODE NOT IN (SELECT CBPDEDCODE FROM BENPROG WHERE CBPBENGROUPCODE = 'BAP')
--AND EEDDEDCODE IN ('PMDH','PMDC','PMDHA','PMDB')
-- AND EECEMPNO = '000138'


------------------------------------------------------ERROR E0047: INVALID JOBCODE FOR THE JOBGROUP-------------------------------
--Description:
--- May need to go into back office and add these jobs to the job group and included with issues and assumptions for the SC 

SELECT 'E0047: INVALID JOBCODE FOR THE JOBGROUP.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECJOBCODE AS JOBCODE,EECJOBGROUPCODE AS JOBGROUPCODE
-- select distinct EECJOBCODE ,EECJOBGROUPCODE
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0047' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'

-- Sample Updates

UPDATE LODECOMP SET EECJOBCODE = '06131' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0047' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'


---------------------------------------ERROR E0049: Employee date of birth is greater than the effective date------------------------------------------------------------
--Description:

SELECT 'E0049: Employee date of birth is greater than the effective date.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EEPDATEOFBIRTH AS DATEOFBIRTH, eecemplstatusstartdate AS EMPLSTATUSSTARTDATE
,eecdateoflasthire AS DATEOFLASTHIRE, eecdateoforiginalhire AS DATEOFORIGINALHIRE
-- select distinct EEPDATEOFBIRTH, eecemplstatusstartdate,,eecdateoflasthire, eecdateoforiginalhire
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0049' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODEPERS'
AND EECEMPLSTATUS <> 'T'
--AND eeppendingupdateid = '000052594'

-- Sample Updates

update lodepers set eepdateofbirth = '01/01/1950'
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0049' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODEPERS'
AND EECEMPLSTATUS <> 'T'
--AND eeppendingupdateid = '000052594'


UPDATE LODEPERS SET EEPDATEOFBIRTH = DATEADD(YEAR,-100,EEPDATEOFBIRTH)
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0049' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODEPERS'
AND EECEMPLSTATUS <> 'T'
--AND eeppendingupdateid = '000052594'


UPDATE LODECOMP SET EECDATEOFORIGINALHIRE = cast(month(EEPDATEOFBIRTH) as nvarchar(5))+'/'+ cast(day(EEPDATEOFBIRTH) as nvarchar(5))+'/1970'where EEPDATEOFBIRTH >getdate()
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0049' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODEPERS'
AND EECEMPLSTATUS <> 'T'
--AND eeppendingupdateid = '000052594'


----------------------------------------------------ERROR E0050: Effective date must be filled---------------------------------------------------
--Description:

SELECT 'E0050: Effective date must be filled.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECDATEOFLASTHIRE AS DATEOFLASTHIRE, EECDATEOFORIGINALHIRE AS DATEOFORIGINALHIRE, EECDATEOFTERMINATION AS DATEOFTERMINATION
-- select distinct EEECDATEOFLASTHIRE,EECDATEOFORIGINALHIRE,EECDATEOFTERMINATION
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0050' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND eecpendingupdateid = '000052594'

-- Sample Updates

UPDATE LODECOMP SET EECDATEOFLASTHIRE = '01/01/1994', EECDATEOFORIGINALHIRE = '01/01/1994' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0050' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND eecpendingupdateid = '000052594'
-- and EecDateOfLastHire is null and EecDateOfOriginalHire is null


-----------------------------------------------------E0052: INVALID DIRECT DEPOSIT AMOUNT OR PERCENT.---------------------------------------------------
--Description:

SELECT 'E0052: INVALID DIRECT DEPOSIT AMOUNT OR PERCENT.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EDDAMTORPCT as AMTORPCT,EDDDEPOSITRULE AS DEPOSITRULE
-- select distinct EDDAMTORPCT,EDDDEPOSITRULE
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEDep  ON EDDPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0052' AND IrrSessionID = 'CONV'
--AND eecpendingupdateid = '000052594'
--AND EDDAMTORPCT = 20 
--AND EDDPENDINGUPDATEID= 'HRP004669'
--AND EDDDEPOSITRULE = 'A'
--AND EDDDEPOSITRULE <> 'D'

-- Sample Updates

DELETE LODEDEP 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEDep  ON EDDPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0052' AND IrrSessionID = 'CONV'

UPDATE LODEDEP SET EDDAMTORPCT = .95,EDDDEPOSITRULE = 'P' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEDep  ON EDDPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0052' AND IrrSessionID = 'CONV'
--AND EDDAMTORPCT = 20 
AND EDDPENDINGUPDATEID= 'HRP004669'
AND EDDDEPOSITRULE = 'A'
--AND EDDDEPOSITRULE <> 'D'

UPDATE LODEDEP SET EDDAMTORPCT = EDDAMTORPCT/100 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEDep  ON EDDPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0052' AND IrrSessionID = 'CONV'
--AND EDDAMTORPCT = 20 
--AND EDDPENDINGUPDATEID= 'HRP004669'
AND EDDDEPOSITRULE = 'P'

-----------------------------------------------------ERROR 56--------------------------------------------------
--Description:

SELECT 'E0056: INVALID DEDUCTION GROUP CODE.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECCOMPANYCODE AS COMPANYCODE, EECDEDGROUPCODE AS DEDGROUPCODE, EECEARNGROUPCODE AS EARNCGROUPCODE
-- select distinct EECCOMPANYCODE, EECDEDGROUPCODE, EEDDEDCODE
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0056' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--and eecdedgroupcode <> 'EXEC'
--and eeddedcode = '403B'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEDDEDCODE NOT IN ('ALIFE','HELTH','LIFE')
--AND EEDDEDCODE IN ('PMDH','PMDC','PMDHA','PMDB')
-- AND EECEMPNO = '000138'
--AND EECDEDGROUPCODE IS NULL
--AND EECCOMPANYCODE = 'BJRET'
--AND EEDPENDINGUPDATEID IN ('GYN100452','PZN000065')

-- Sample Updates

UPDATE LODECOMP SET EECDEDGROUPCODE = 'LNCHR' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0056' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--and eecdedgroupcode <> 'EXEC'
--and eeddedcode = '403B'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEDDEDCODE NOT IN ('ALIFE','HELTH','LIFE')
--AND EEDDEDCODE IN ('PMDH','PMDC','PMDHA','PMDB')
-- AND EECEMPNO = '000138'
AND EECDEDGROUPCODE IS NULL
--AND EECCOMPANYCODE = 'BJRET'
--AND EEDPENDINGUPDATEID IN ('GYN100452','PZN000065')

DELETE LODEDED FROM LODEDED
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN U_CT_LODSTATUS ON STSPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0056' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--and eecdedgroupcode <> 'EXEC'
--and eeddedcode = '403B'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEDDEDCODE NOT IN ('ALIFE','HELTH','LIFE')
--AND EEDDEDCODE IN ('PMDH','PMDC','PMDHA','PMDB')
-- AND EECEMPNO = '000138'
AND EECDEDGROUPCODE IS NULL
--AND EECCOMPANYCODE = 'BJRET'
--AND EEDPENDINGUPDATEID IN ('GYN100452','PZN000065')
--AND STSPENDINGUPDATEID=IRRPENDINGUPDATEID
--AND EEDRECID=IRRRECID
--AND STSEMPLSTATUS <> 'T'

UPDATE LODEDED SET EEDDEDCODE = 'DEN23' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0056' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--and eecdedgroupcode <> 'EXEC'
--and eeddedcode = '403B'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
AND EEDDEDCODE NOT IN ('ALIFE','HELTH','LIFE')
--AND EEDDEDCODE IN ('PMDH','PMDC','PMDHA','PMDB')
-- AND EECEMPNO = '000138'
--AND EECDEDGROUPCODE IS NULL
--AND EECCOMPANYCODE = 'BJRET'
AND EEDPENDINGUPDATEID IN ('GYN100452','PZN000065')


----------------------------------------------------ERROR E0065: TaxCode is marked blocked however Extra Tax Dollars exist for "USFIT"---------------------------------------------------
--Description

SELECT 'E0065: TaxCode is marked blocked however Extra Tax Dollars exist for USFIT.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EEMUFWEXTRATAXDOLLARSFED as UFWEXTRATAXDOLLARSFED,EEMUFWBLOCKTAXAMTFED as UFWBLOCKTAXAMTFED
-- select distinct EEMUFWEXTRATAXDOLLARSFED,EEMUFWBLOCKTAXAMTFED
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0065' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'

-- Sample Updates

UPDATE LODEEMST SET EEMUFWBLOCKTAXAMTFED = 'N' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0065' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'


----------------------------------------------------ERROR E0066: UFW Company Code does not match Company Code in the Company table------------NO UPDATE FOR THIS ONE REVIEW---------------------------------------
--Description: 

SELECT 'E0066: UFW Company Code does not match Company Code in the Company table.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EEMUFWFILINGSTATUSFED as UFWFILINGSTATUSFED,EEMUFWCOMPANYCODE as UFWCOMPANYCODE, RETUFWCOMPANYCODE AS RTUFWCOMPANYCODE
-- select distinct EEMUFWFILINGSTATUSFED,EEMUFWCOMPANYCODE, RETUFWCOMPANYCODE
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODRSETX ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0066' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'


-----------------------------------------------ERROR EOO69: Invalid Federal Filing Status---------------------------------------------------
--Description: 

SELECT 'E0069: Invalid Federal Filing Status.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EEMUFWFILINGSTATUSFED as UFWFILINGSTATUSFED
-- select distinct EEMUFWFILINGSTATUSFED
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEEMst ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0069' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
-- AND EEMUFWFILINGSTATUSFED IN ( 'H')

-- Sample Updates

UPDATE LODEEMST SET EEMUFWFILINGSTATUSFED = 'S' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0069' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
-- AND EEMUFWFILINGSTATUSFED IN ( 'H')



----------------------------------------------------ERROR E0071: INVALID UFWOTHWgDolAmtFed---------------------------------------------------
--Description:

SELECT 'E0071: INVALID UFWOTHWgDolAmtFed.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EEMUFWCOMPANYCODE AS COMPANYCODE, EemUFWOTHWgTaxMethFed AS UFWOTHWgTaxMethFed ,EemUFWEXTRATAXDOLLARSFed AS UFWEXTRATAXDOLLARSFed,EemUFWOTHWgDolAmtFed AS UFWOTHWgDolAmtFed
-- select distinct EemUFWOTHWgDolAmtFed 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0071' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'

-- Sample Updates

UPDATE LODEEMST SET EemUFWOTHWgDolAmtFed = NULL 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0071' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'

-----------------------------------------------------ERROR E0072: INVALID UFWOTHWgTaxMethFed----------------------------------------------------
--Description:

SELECT 'E0072: INVALID UFWOTHWgTaxMethFed.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EEMUFWCOMPANYCODE AS COMPANYCODE, EemUFWOTHWgTaxMethFed AS UFWOTHWgTaxMethFed ,EemUFWEXTRATAXDOLLARSFed AS UFWEXTRATAXDOLLARSFed,EemUFWOTHWgDolAmtFed AS UFWOTHWgDolAmtFed
-- select distinct EemUFWOTHWgTaxMethFed
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0072' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'

-- Sample Updates

UPDATE LODEEMST SET EemUFWOTHWgTaxMethFed = 'D' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0072' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'

-----------------------------------------------------ERROR E0073: INVALID UFWREGWGTAXMETHFED---------------------------------------------------
--Description:

SELECT 'E0073: INVALID EEMUFWREGWGTAXMETHFED.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EEMUFWCOMPANYCODE AS COMPANYCODE, EemUFWOTHWgTaxMethFed AS UFWOTHWgTaxMethFed ,EemUFWEXTRATAXDOLLARSFed AS UFWEXTRATAXDOLLARSFed,EemUFWOTHWgDolAmtFed AS UFWOTHWgDolAmtFed
-- select distinct EemUFWOTHWgTaxMethFed
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0073' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'

-- Sample Updates

UPDATE LODEEMST SET EEMUFWREGWGTAXMETHFED = 'A'
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0073' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'

----------------------------------------------------ERROR E0074: INVALID EEMUFWSTATESUI / EEMUFWSTATESDI---------------------------------------------------
--Description:

SELECT 'E0074: INVALID EEMUFWREGWGTAXMETHFED.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EEMUFWCOMPANYCODE AS COMPANYCODE, EEMUFWSTATESUI AS UFWSTATESUI,EEMUFWSTATESDI AS UFWSTATESDI
, WETUFWLOCATION AS UFWLOCATION ,WETUFWSITWORKINCODE AS UFWSITWORKINCODE
-- select distinct EEMUFWSTATESUI,EEMUFWSTATESDI,WETUFWLOCATION,WETUFWSITWORKINCODE
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0074' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
--AND EEMPENDINGUPDATEID = 'USAPRC2005150'

-- Sample Updates

UPDATE LODEEMST SET EEMUFWSTATESUI = 'FLSUIER',EEMUFWSTATESDI = NULL 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0074' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
--AND EEMPENDINGUPDATEID = 'USAPRC2005150'


UPDATE LODEEMST SET EEMUFWSTATESDI = NULL,EEMPENDINGTRANSTYPESDI = NULL
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0074' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
--AND EEMPENDINGUPDATEID = 'USAPRC2005150'

--------------------------------ERROR E0075: StateSDI state does not match Primary SITWorkInCode State Code.---------------------------------------------------
--Description

SELECT 'E0075: StateSDI state does not match Primary SITWorkInCode State Code.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EEMUFWSTATESUI as UFWSTATESUI ,EEMUFWSTATESDI as UFWSTATESDI,
,WETUFWLOCATION as WTUFWLOCATION, WETUFWSITWORKINCODE as WTUFWSITWORKINCODE 
-- select distinct EEMUFWSTATESUI,EEMUFWSTATESDI, WETUFWLOCATION,WETUFWSITWORKINCODE
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0075' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
and EEMUFWSTATESUI = 'VASUIER'


-- Sample Updates

UPDATE LODEEMST SET /*EEMUFWSTATESUI = 'NYSUIER',*/EEMUFWSTATESDI = /*'HISDIEE'*/ NULL 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0075' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
AND EEMUFWSTATESUI = 'VASUIER'


----------------------------------------------------ERROR E0077: EEMUFWSTATESUI / EEMUFWSTATESDI---------------------------NO RESOLUTION-----------------
--Description:

SELECT 'E0077: EEMUFWSTATESUI / EEMUFWSTATESDI.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EEMUFWCOMPANYCODE AS COMPANYCODE, EEMUFWSTATESUI AS UFWSTATESUI,EEMUFWSTATESDI AS UFWSTATESDI
, WETUFWLOCATION AS UFWLOCATION ,WETUFWSITWORKINCODE AS UFWSITWORKINCODE
-- select distinct EEMUFWSTATESUI,EEMUFWSTATESDI,WETUFWLOCATION,WETUFWSITWORKINCODE
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0077' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
--AND EEMPENDINGUPDATEID = 'USAPRC2005150'



-------------------------------------------ERROR E0079: StateSUI state does not match Primary SITWorkInCode State Code---------
--Description

SELECT 'E0079: StateSUI state does not match Primary SITWorkInCode State Code.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
,EEMUFWCOMPANYCODE as UFWCOMPANYCODE,WETUFWLOCATION as UFWLOCATION,WETUFWSITWORKINCODE as UFWSITWORKINCODE
,eemufwstatesui as ufwstatesui,EEMUFWSTATEWC as UFWSTATEWC
-- select distinct EEMUFWCOMPANYCODE,WETUFWLOCATION,WETUFWSITWORKINCODE,eemufwstatesui ,EEMUFWSTATEWC
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0079' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
--AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'

-- Sample Updates

UPDATE LODEEMST SET EEMUFWSTATESUI=SUBSTRING(WETUFWSITWORKINCODE,1,2)+ 'SUIER'
,EEMUFWSTATEWC = SUBSTRING(WETUFWSITWORKINCODE,1,2),EEMUFWSTATESDI = NULL 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0079' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'

UPDATE LODEEMST SET EEMUFWSTATESDI = SUBSTRING(EEMUFWSTATESUI,1,2) + 'SDIEE' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0079' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'

UPDATE LODEEMST SET EEMUFWSTATESDI = NULL
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0079' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'

UPDATE LODECOMP SET EECSTATESUI = SUBSTRING(EECSITWORKINSTATECODE,1,2)+'SUIER', EECWCSTATE=SUBSTRING(EECSITWORKINSTATECODE,1,2)
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0079' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'

UPDATE LODEEMST SET EEMUFWSTATESUI = SUBSTRING(WETUFWSITWORKINCODE,1,2)+'SUIER', EEMUFWSTATEWC=SUBSTRING(WETUFWSITWORKINCODE,1,2)
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0079' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'


---------------------------------------------error E0082: SUIPlanType must be populated------------------------------------------------------------
--Description

SELECT 'E0082: SUIPlanType must be populated.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
,EEMUFWSUIPLANTYPE as UFWSUIPLANTYPE
-- select distinct EEMUFWSUIPLANTYPE
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0082' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
AND EEMUFWSTATESUI = 'CASUIER'
--AND EECPENDINGUPDATEID = '5Z9002168'

-- Sample Updates

UPDATE LODEEMST SET EEMUFWSUIPLANTYPE = 'S' WHERE EEMUFWSTATESUI = 'CASUIER'
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0082' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
AND EEMUFWSTATESUI = 'CASUIER'
--AND EECPENDINGUPDATEID = '5Z9002168'

---------------------------------------------ERROR E0086---------------------------------------------------
--Description
--Sometimes this happens after manually switching (manually mapping) the dedcode for a untranslated code.

SELECT 'E0086: Benefit status date is required.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECJOBCODE AS JOBCODE,EECJOBGROUPCODE AS JOBGROUPCODE
, EedDedCode as DedCode,  EedStartDate AS STARTDATE
, EedBenStartDate AS BENSTARTDATE 
, eedEEEligDate AS EEELIGDATE, eedbenstatusdate AS BENSTATUSDATE 
, eecdateofbenefitseniority AS dateofbenefitseniority 
, EedBenStatus as BenStatus 
-- select distinct EedDedCode,  EedStartDate
, EedBenStartDate,  eedEEEligDate
, eedbenstatusdate, eecdateofbenefitseniority
, EedBenStatus as BenStatus 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0086' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
--and EedBenStatusDate is null
--and dedisbenefit='Y'

-- Sample Updates

Update LodEDed
set EedBenStatus='A', EedBenStatusDate =EedStartDate
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0086' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
and EedBenStatusDate is null
and dedisbenefit='Y'



----------------------------------------------------ERROR E0087: NOT SURE OF ERROR MESSAGE---------------------------------------------------
--Description

SELECT 'E0087: NOT SURE OF ERROR MESSAGE.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, RETUFWEXTRATAXDOLLARSSITR as UFWEXTRATAXDOLLARSSITR,RETUFWBLOCKTAXAMTSITR AS UFWBLOCKTAXAMTSITR, EEMUFWCOMPANYCODE as UFWCOMPANYCODE, RETUFWCOMPANYCODE AS RTUFWCOMPANYCODE
-- select distinct RETUFWEXTRATAXDOLLARSSITR,RETUFWBLOCKTAXAMTSITR,EEMUFWCOMPANYCODE, RETUFWCOMPANYCODE
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODRSETX ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0087' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'

-- Sample Update

UPDATE LODRSETX SET RETUFWBLOCKTAXAMTSITR = 'N' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODRSETX ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0087' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'


----------------------------------------------ERROR E0088: NOT SURE OF ERROR MESSAGE---------------------------------------------------
--Description

SELECT 'E0088: NOT SURE OF ERROR MESSAGE.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, RETUFWFILINGSTATUSLITR AS UFWFILINGSTATUSLITR,RETUFWLITRESIDENTCODE AS UFWLITRESIDENTCODE,RETUFWSITRESIDENTCODE AS UFWSITRESIDENTCODE, EEMUFWCOMPANYCODE as UFWCOMPANYCODE, RETUFWCOMPANYCODE AS RTUFWCOMPANYCODE
-- select distinct RETUFWFILINGSTATUSLITR,RETUFWLITRESIDENTCODE,RETUFWSITRESIDENTCODE,EEMUFWCOMPANYCODE, RETUFWCOMPANYCODE
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODRSETX ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0088' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND RETUFWLITRESIDENTCODE = 'AL022'

-- Sample Updates

UPDATE LODRSETX SET RETUFWFILINGSTATUSLITR = retufwFILINGSTATUSSITR 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODRSETX ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0088' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND RETUFWLITRESIDENTCODE = 'AL022'


update lodrsetx set RETUFWLITRESIDENTCODE = NULL 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODRSETX ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0088' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
AND RETUFWLITRESIDENTCODE = 'AL022'


--------------------------------------------------ERROR E0089: Invalid Filing Status for LIT SD Code---------------------------------------------------
--Description

SELECT 'E0089: Invalid Filing Status for LIT SD Code.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, RETUFWFILINGSTATUSLITR AS UFWFILINGSTATUSLITR,RETUFWFILINGSTATUSLITS AS UFWFILINGSTATUSLITS,RETUFWLITSDCODE AS UFWLITSDCODE, RETUFWLITRESIDENTCODE AS UFWLITRESIDENTCODE,RETUFWSITRESIDENTCODE AS UFWSITRESIDENTCODE, EEMUFWCOMPANYCODE as UFWCOMPANYCODE, RETUFWCOMPANYCODE AS RTUFWCOMPANYCODE
-- select distinct RETUFWFILINGSTATUSLITR,RETUFWLITRESIDENTCODE,RETUFWSITRESIDENTCODE,EEMUFWCOMPANYCODE, RETUFWCOMPANYCODE
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODRSETX ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0089' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND RETUFWLITRESIDENTCODE = 'AL022'

-- Sample Updates

UPDATE LODRSETX SET RETUFWFILINGSTATUSLITS = retufwFILINGSTATUSSITR 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODRSETX ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0089' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND RETUFWLITRESIDENTCODE = 'AL022'

update lodrsetx set RETUFWLITRESIDENTCODE = NULL 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODRSETX ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0089' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND RETUFWLITRESIDENTCODE = 'AL022'

-------------------------------------------------ERROR E0090: Invalid Filing Status for SIT Resident Code----------------------------------------------------------------
--Description
--Can update to the location state for terminated employees 

--Usually AZ or NJ will have a filing of Status of S, M, when it should be A, B, C, etc. 
-- Have the customer correct, or set a default 

SELECT 'E0090: Invalid Filing Status for SIT Resident Code.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
,RETUFWFILINGSTATUSSITR AS UFWFILINGSTATUSSITR,RETUFWSITRESIDENTCODE AS UFWSITRESIDENTCODE
,wetufwsitworkincode AS WTUFWSITWORKINCODE, wetufwfilingstatussitw AS UFWFILINGSTATUSSITW
-- select distinct RETUFWFILINGSTATUSSITR,RETUFWSITRESIDENTCODE, wetufwsitworkincode, wetufwfilingstatussitw
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODRSETX ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
left outer join u_ct_lodstatus on retPENDINGUPDATEID=stsPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0090' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
--AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
-- AND RETUFWSITRESIDENTCODE in ('azsit','mssit')
--AND wetufwsitworkincode in ('azsit','mssit')
--AND RETUFWFILINGSTATUSSITR IN ('B')
--AND /*RETUFWSITRESIDENTCODE = 'SCSIT'

-- Sample Updates

update lodrsetx set RETUFWSITRESIDENTCODE = 'FLSIT' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODRSETX ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
left outer join u_ct_lodstatus on retPENDINGUPDATEID=stsPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0090' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
--AND RETUFWSITRESIDENTCODE <> 'FLSIT'
-- AND wetPENDINGUPDATEID = '660829'
-- AND RETUFWSITRESIDENTCODE in ('azsit','mssit')
--AND wetufwsitworkincode in ('azsit','mssit')
--AND RETUFWFILINGSTATUSSITR IN ('B')
--AND /*RETUFWSITRESIDENTCODE = 'SCSIT'

update lodrsetx set RETUFWFILINGSTATUSSITR = 'S' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODRSETX ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
left outer join u_ct_lodstatus on retPENDINGUPDATEID=stsPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0090' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
--AND RETUFWSITRESIDENTCODE <> 'FLSIT'
-- AND wetPENDINGUPDATEID = '660829'
-- AND RETUFWSITRESIDENTCODE in ('azsit','mssit')
--AND wetufwsitworkincode in ('azsit','mssit')
--AND RETUFWFILINGSTATUSSITR IN ('B')
--AND /*RETUFWSITRESIDENTCODE = 'SCSIT'

UPDATE LODRSETX SET RETUFWFILINGSTATUSSITR = EEMUFWFILINGSTATUSFED 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODRSETX ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
left outer join u_ct_lodstatus on retPENDINGUPDATEID=stsPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0090' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
--AND RETUFWSITRESIDENTCODE <> 'FLSIT'
-- AND wetPENDINGUPDATEID = '660829'
--AND RETUFWSITRESIDENTCODE in ('azsit','mssit')
--AND wetufwsitworkincode in ('azsit','mssit')
AND RETUFWFILINGSTATUSSITR IN ('B')

UPDATE LODRSETX SET RETUFWFILINGSTATUSSITR=WETUFWFILINGSTATUSSITW
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODRSETX ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
left outer join u_ct_lodstatus on retPENDINGUPDATEID=stsPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0090' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
--AND RETUFWSITRESIDENTCODE <> 'FLSIT'
-- AND wetPENDINGUPDATEID = '660829'
--AND RETUFWSITRESIDENTCODE in ('azsit','mssit')
--AND wetufwsitworkincode in ('azsit','mssit')
AND RETUFWFILINGSTATUSSITR IN ('B')

update LodRsEtx set RetUFWFilingStatusSITR = 'A' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODRSETX ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
left outer join u_ct_lodstatus on retPENDINGUPDATEID=stsPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0090' AND IrrSessionID = 'CONV'
  and RetUFWSITResidentCode ='AZSIT' 
  and RetUFWFilingStatusSITR = 'S'

update LodRsEtx set RetUFWFilingStatusSITR = 'B' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODRSETX ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
left outer join u_ct_lodstatus on retPENDINGUPDATEID=stsPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0090' AND IrrSessionID = 'CONV'
  and RetUFWSITResidentCode ='AZSIT' 
  and RetUFWFilingStatusSITR = 'M'


  -------------------------------------------------ERROR E0091: Linked SD TaxCode was not setup.----------------------------------------------------------
--Description

SELECT distinct 'E0091: Linked SD TaxCode was not setup.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, RETUFWLITRESIDENTCODE, RETUFWLITSDCODE, CTCTAXCODE, CtcLinkedOCCSD, CtcLinkedSD, CtcLocalType, CTCCOUNTY, retufwlitsdcode,  mtclinkedsd 
-- select distinct RETUFWLITRESIDENTCODE,RETUFWLITSDCODE, CTCTAXCODE,CtcLinkedOCCSD,CtcLinkedSD ,CtcLocalType,CTCCOUNTY
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN lodrsetx ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
left JOIN [Ultipro_System].dbo.txcdmast on [Ultipro_System].dbo.txcdmast.mtctaxcode = retufwlitresidentcode
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN TAXCODE ON CTCTAXCODE=RETUFWLITRESIDENTCODE
WHERE IRRMSGCODE = 'E0091' AND IrrSessionID = 'CONV'
--AND EECPENDINGUPDATEID = '5Z9002168'

-- Sample Updates

UPDATE lodrsetx 
SET    retufwlitsdcode = mtclinkedsd 
FROM   [Ultipro_System].dbo.txcdmast 
       JOIN (SELECT mtctaxcode, 
                    Max(auditkey) maxkey 
             FROM   [Ultipro_System].dbo.txcdmast 
             GROUP  BY mtctaxcode) X 
         ON maxkey = auditkey 
       JOIN lodrsetx 
         ON [Ultipro_System].dbo.txcdmast.mtctaxcode = retufwlitresidentcode 
       JOIN imperrs 
         ON irrpendingupdateid = retpendingupdateid 
WHERE  [Ultipro_System].dbo.txcdmast.mtclinkedsd IS NOT NULL 
       AND irrmsgcode = 'E0091' 

UPDATE LODRSETX SET RETUFWLITSDCODE = 'KY102',RETPENDINGTRANSTYPELITS = 'A' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN lodrsetx ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
left JOIN [Ultipro_System].dbo.txcdmast on [Ultipro_System].dbo.txcdmast.mtctaxcode = retufwlitresidentcode
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN TAXCODE ON CTCTAXCODE=RETUFWLITRESIDENTCODE
WHERE IRRMSGCODE = 'E0091' AND IrrSessionID = 'CONV'--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
AND RETUFWSITRESIDENTCODE <> 'FLSIT'
-- AND wetPENDINGUPDATEID = '660829'
-- AND RETUFWSITRESIDENTCODE in ('azsit','mssit')
--AND wetufwsitworkincode in ('azsit','mssit')
--AND RETUFWFILINGSTATUSSITR IN ('B')
--AND /*RETUFWSITRESIDENTCODE = 'SCSIT'
--AND RETUFWLITRESIDENTCODE = 'KY053'
--AND CTCTAXCODE=RETUFWLITRESIDENTCODE


SELECT * FROM TAXCODE WHERE CTCTAXCODE IN ('PA100822','KY053')

SELECT DISTINCT MTCTAXCODE,MTCTAXCODEDESC,MTCCOUNTY FROM TXCDMAST WHERE MTCSTATE = 'PA' --AND MTCLOCALTYPE = 'SD'
ORDER BY MTCTAXCODE

SELECT DISTINCT MTCTAXCODE,MTCTAXCODEDESC,MTCCOUNTY FROM TXCDMAST WHERE MTCTAXCODE IN ('PA100822','PA113620')


-------------------------------------------------ERROR E0092: INVALID RETUFWLITRESIDENTCODE----------------------------------------------------------
--Description

SELECT 'E0092: INVALID RETUFWLITRESIDENTCODE'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, RETUFWLITRESIDENTCODE as UFWLITRESIDENTCODE,RETUFWLITSDCODE as UFWLITSDCODE, CTCTAXCODE AS TAXCODE,CtcLinkedOCCSD AS LINKEDOCCSD,CtcLinkedSD AS LINKEDSD ,CtcLocalType AS LOCALTYPE,CTCCOUNTY AS COUNTY
-- select distinct RETUFWLITRESIDENTCODE,RETUFWLITSDCODE, CTCTAXCODE,CtcLinkedOCCSD,CtcLinkedSD ,CtcLocalType,CTCCOUNTY
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN lodrsetx ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
LEFT JOIN [Ultipro_System].dbo.txcdmast on [Ultipro_System].dbo.txcdmast.mtctaxcode = retufwlitresidentcode
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN TAXCODE ON CTCTAXCODE=RETUFWLITRESIDENTCODE
WHERE IRRMSGCODE = 'E0092' AND IrrSessionID = 'CONV'--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
AND RETUFWSITRESIDENTCODE <> 'FLSIT'
-- AND wetPENDINGUPDATEID = '660829'
-- AND RETUFWSITRESIDENTCODE in ('azsit','mssit')
--AND wetufwsitworkincode in ('azsit','mssit')
--AND RETUFWFILINGSTATUSSITR IN ('B')
--AND /*RETUFWSITRESIDENTCODE = 'SCSIT'
--AND RETUFWLITRESIDENTCODE = 'KY053'
--AND CTCTAXCODE=RETUFWLITRESIDENTCODE

-- Sample Updates

UPDATE LODRSETX SET RETUFWLITRESIDENTCODE = NULL 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN lodrsetx ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
LEFT JOIN [Ultipro_System].dbo.txcdmast on [Ultipro_System].dbo.txcdmast.mtctaxcode = retufwlitresidentcode
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN TAXCODE ON CTCTAXCODE=RETUFWLITRESIDENTCODE
WHERE IRRMSGCODE = 'E0092' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
AND RETUFWSITRESIDENTCODE <> 'FLSIT'
-- AND wetPENDINGUPDATEID = '660829'
-- AND RETUFWSITRESIDENTCODE in ('azsit','mssit')
--AND wetufwsitworkincode in ('azsit','mssit')
--AND RETUFWFILINGSTATUSSITR IN ('B')
--AND /*RETUFWSITRESIDENTCODE = 'SCSIT'
--AND RETUFWLITRESIDENTCODE = 'KY053'
--AND CTCTAXCODE=RETUFWLITRESIDENTCODE
--AND RETUFWLITRESIDENTCODE = 'AL022' AND RETUFWSITRESIDENTCODE <> 'ALSIT'


----------------------------------------------------ERROR E0093: INVALID RETUFWLITSDCODE---------------------------------------------------
--Description  -

SELECT distinct 'E0093: INVALID RETUFWLITSDCODE'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, RETUFWLITRESIDENTCODE, RETUFWLITSDCODE, CTCTAXCODE, CtcLinkedOCCSD, CtcLinkedSD, ctcLocalType, CTCCOUNTY
-- select distinct RETUFWLITRESIDENTCODE,RETUFWLITSDCODE, CTCTAXCODE,CtcLinkedOCCSD,CtcLinkedSD ,CtcLocalType,CTCCOUNTY
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN lodrsetx ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
LEFT JOIN [Ultipro_System].dbo.txcdmast on [Ultipro_System].dbo.txcdmast.mtctaxcode = retufwlitresidentcode
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN TAXCODE ON CTCTAXCODE=RETUFWLITRESIDENTCODE
WHERE IRRMSGCODE = 'E0093' AND IrrSessionID = 'CONV' and CtcLinkedSD = RETUFWLITSDCODE
--and RETUFWLITSDCODE = 'PA100702'
--AND EECEMPLSTATUS <> 'T'
--AND EECPENDINGUPDATEID = '5Z9002168'
--AND WETUFWLOCATION = 'FL'
--AND RETUFWSITRESIDENTCODE <> 'FLSIT'


-- Sample Update

UPDATE LODRSETX SET RETUFWLITSDCODE = NULL 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN lodrsetx ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
LEFT JOIN [Ultipro_System].dbo.txcdmast on [Ultipro_System].dbo.txcdmast.mtctaxcode = retufwlitresidentcode
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN TAXCODE ON CTCTAXCODE=RETUFWLITRESIDENTCODE
WHERE IRRMSGCODE = 'E0093' AND IrrSessionID = 'CONV' and CtcLinkedSD = RETUFWLITSDCODE


-------------------------------------------ERROR E0095: SIT Resident Code and SIT Resident WorkIn are the same and the Not Subject To Tax Field equals "Y"--------------------------------------------------
--Description sourced from Quip:

SELECT EecPendingUpdateId, EecCompanyCode, EecEmpno, EepNameLast, EepNameFirst, EecEmplStatus,  RetUFWSITResidentCode
, RetUFWNotSubjToTaxSITR
FROM LodEComp
JOIN LodEPers  ON EecPendingUpdateID = EepPendingUpdateID
JOIN LodWkEtx ON EecPendingUpdateID = WetPendingUpdateID
JOIN LodRsEtx ON EecPendingUpdateID = RetPendingUpdateID
WHERE EecSessionID = 'CONV'
AND ISNULL(WetPendingTransTypeSITW,'') IN ('A','U')
AND RetUFWNotSubjToTaxSITR = 'Y'
AND WetUFWNotSubjToTaxSITW = 'Y'
AND WetUFWSITWorkInCode = RetUFWSITResidentCode

-- Sample Update

-- None.  If you build an update, send to team lead.


-----------------------------------------------ERROR E0097: Benefit start date is required--------------------------------------------------
--Description

SELECT 'E0097: Benefit start date is required.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECJOBCODE AS JOBCODE,EECJOBGROUPCODE AS JOBGROUPCODE
, EedDedCode as DedCode,  EedStartDate AS STARTDATE
, EedBenStartDate AS BENSTARTDATE 
, eedEEEligDate AS EEELIGDATE, eedbenstatusdate AS BENSTATUSDATE 
, eecdateofbenefitseniority AS dateofbenefitseniority 
, EedBenStatus as BenStatus 
-- select distinct EedDedCode,  EedStartDate
, EedBenStartDate,  eedEEEligDate
, eedbenstatusdate, eecdateofbenefitseniority
, EedBenStatus as BenStatus 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0097' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
--and EedBenStatusDate is null
--AND EEDDEDCODE IN (SELECT DEDDEDCODE FROM DEDCODE WHERE DEDISBENEFIT = 'Y')
--AND EEDDEDCODE IN ('401K','DRADV','GSULI','FEE')

-- Sample Updates

UPDATE LODEDED SET EEDBENSTARTDATE = EEDSTARTDATE,EEDBENSTATUS = 'A',EEDBENSTATUSDATE = EEDSTARTDATE
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0097' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
and EedBenStatusDate is null
AND EEDDEDCODE IN (SELECT DEDDEDCODE FROM DEDCODE WHERE DEDISBENEFIT = 'Y')
--AND EEDDEDCODE IN ('401K','DRADV','GSULI','FEE')

UPDATE LODEDED SET EEDBENSTARTDATE = EECDATEOFBENEFITSENIORITY,EEDEEELIGDATE = EECDATEOFBENEFITSENIORITY,EEDBENSTATUS 
= 'A',EEDBENSTATUSDATE = EECDATEOFBENEFITSENIORITY 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0097' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
and EedBenStatusDate is null
AND EEDDEDCODE IN (SELECT DEDDEDCODE FROM DEDCODE WHERE DEDISBENEFIT = 'Y')
--AND EEDDEDCODE IN ('401K','DRADV','GSULI','FEE')
--EEDBENSTARTDATE IS NULL


UPDATE LODEDED SET EEDBENSTARTDATE = '01/01/2003',EEDEEELIGDATE = '01/01/2003',EEDBENSTATUS 
= 'A',EEDBENSTATUSDATE = '01/01/2003' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0097' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
and EedBenStatusDate is null
AND EEDDEDCODE IN (SELECT DEDDEDCODE FROM DEDCODE WHERE DEDISBENEFIT = 'Y')
--AND EEDDEDCODE IN ('401K','DRADV','GSULI','FEE')
--EEDBENSTARTDATE IS NULL
-- AND EEDDEDCODE IN ('BC1','BCP','COA','COC','CUL','DEC','DEN','DEP','DN1','EXL','GA2','GAR','GRW','GW2','MA2','MOA','NEN','PRV','SB1','SBP')


--------------------------------------------ERROR E0100: Eligibility date is required-----------------------------------
--Description
--For generic excel, this hasn't been getting populated because its not in the excel template. They can --add it as needed. If not, it should just default to the eecdateofsenority

SELECT 'E0100: Eligibility date is required.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECJOBCODE AS JOBCODE,EECJOBGROUPCODE AS JOBGROUPCODE
, EedDedCode as DedCode,  EedStartDate AS STARTDATE
, EedBenStartDate AS BENSTARTDATE 
, eedEEEligDate AS EEELIGDATE, eedbenstatusdate AS BENSTATUSDATE 
, eecdateofbenefitseniority AS dateofbenefitseniority 
, EedBenStatus as BenStatus 
-- select distinct EedDedCode,  EedStartDate
, EedBenStartDate,  eedEEEligDate
, eedbenstatusdate, eecdateofbenefitseniority
, EedBenStatus as BenStatus 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0100' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
--and EedBenStatusDate is null
--AND EEDDEDCODE IN (SELECT DEDDEDCODE FROM DEDCODE WHERE DEDISBENEFIT = 'Y')
----AND EEDDEDCODE IN ('401K','DRADV','GSULI','FEE')

-- Sample Updates

UPDATE LODEDED SET EEDEEELIGDATE = EEDBENSTARTDATE -- eedEEEligDate= eecdateofbenefitseniority
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0100' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID

---------------------------------------------ERROR E0101: INVALID RetUFWOTHWgPctAmtSITR---------------------------------------------------
--Description

SELECT 'E0101: INVALID RetUFWOTHWgPctAmtSITR'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, RETUFWOTHWGTAXMETHSITR AS UFWOTHWGTAXMETHSITR,RETUFWREGWGTAXMETHSITR AS UFWREGWGTAXMETHSITR
-- select distinct RETUFWOTHWGTAXMETHSITR,RETUFWREGWGTAXMETHSITR
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN ledrsetx ON retPENDINGUPDATEID=IRRPENDINGUPDATEID
LEFT JOIN [Ultipro_System].dbo.txcdmast on [Ultipro_System].dbo.txcdmast.mtctaxcode = retufwlitresidentcode
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN TAXCODE ON CTCTAXCODE=RETUFWLITRESIDENTCODE
left outer join u_ct_lodstatus on retPENDINGUPDATEID=stsPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0101' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
AND RETUFWSITRESIDENTCODE <> 'FLSIT'
-- AND wetPENDINGUPDATEID = '660829'
-- AND RETUFWSITRESIDENTCODE in ('azsit','mssit')
--AND wetufwsitworkincode in ('azsit','mssit')
--AND RETUFWFILINGSTATUSSITR IN ('B')
--AND /*RETUFWSITRESIDENTCODE = 'SCSIT'
--AND RETUFWLITRESIDENTCODE = 'KY053'
--AND CTCTAXCODE=RETUFWLITRESIDENTCODE
-- AND RETUFWLITSDCODE = 'OH1522'

-- Sample Updates

UPDATE LODRSETX SET RetUFWOTHWgPctAmtSITR = 0 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
LEFT JOIN [Ultipro_System].dbo.txcdmast on [Ultipro_System].dbo.txcdmast.mtctaxcode = retufwlitresidentcode
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN TAXCODE ON CTCTAXCODE=RETUFWLITRESIDENTCODE
left outer join u_ct_lodstatus on retPENDINGUPDATEID=stsPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0101' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
AND RETUFWSITRESIDENTCODE <> 'FLSIT'
-- AND wetPENDINGUPDATEID = '660829'
-- AND RETUFWSITRESIDENTCODE in ('azsit','mssit')
--AND wetufwsitworkincode in ('azsit','mssit')
--AND RETUFWFILINGSTATUSSITR IN ('B')
--AND /*RETUFWSITRESIDENTCODE = 'SCSIT'
--AND RETUFWLITRESIDENTCODE = 'KY053'
--AND CTCTAXCODE=RETUFWLITRESIDENTCODE
-- AND RETUFWLITSDCODE = 'OH1522'


---------------------------------------------------ERROR E0103: EEID IS REQUIRED----------------------------------------------
--Description

SELECT 'E0103: EEID Is Required.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEDed  ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0103' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
----and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
--and EEDPENDINGUPDATEID NOT IN (SELECT EECPENDINGUPDATEID FROM LODECOMP)

----------------------------------------------------ERROR E0105: INVALID RETUFWREGWGTAXMETHLITR---------------------------------------------------
--Description

SELECT 'E0105: INVALID RETUFWREGWGTAXMETHLITR'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, RETUFWLITRESIDENTCODE AS UFWLITRESIDENTCODE,RETUFWREGWGTAXMETHLITR AS UFWREGWGTAXMETHLITR
-- select distinct RETUFWLITRESIDENTCODE,RETUFWREGWGTAXMETHLITR 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN lodrsetx ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
LEFT JOIN [Ultipro_System].dbo.txcdmast on [Ultipro_System].dbo.txcdmast.mtctaxcode = retufwlitresidentcode
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN TAXCODE ON CTCTAXCODE=RETUFWLITRESIDENTCODE
WHERE IRRMSGCODE = 'E0105' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
AND RETUFWSITRESIDENTCODE <> 'FLSIT'
-- AND wetPENDINGUPDATEID = '660829'
-- AND RETUFWSITRESIDENTCODE in ('azsit','mssit')
--AND wetufwsitworkincode in ('azsit','mssit')
--AND RETUFWFILINGSTATUSSITR IN ('B')
--AND /*RETUFWSITRESIDENTCODE = 'SCSIT'
--AND RETUFWLITRESIDENTCODE = 'KY053'
--AND CTCTAXCODE=RETUFWLITRESIDENTCODE
-- AND RETUFWLITSDCODE = 'OH1522'

-- Sample Updates

UPDATE LODRSETX SET RETUFWREGWGTAXMETHLITR = 'A' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN lodrsetx ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
LEFT JOIN [Ultipro_System].dbo.txcdmast on [Ultipro_System].dbo.txcdmast.mtctaxcode = retufwlitresidentcode
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN TAXCODE ON CTCTAXCODE=RETUFWLITRESIDENTCODE
WHERE IRRMSGCODE = 'E0105' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
AND RETUFWSITRESIDENTCODE <> 'FLSIT'
-- AND wetPENDINGUPDATEID = '660829'
-- AND RETUFWSITRESIDENTCODE in ('azsit','mssit')
--AND wetufwsitworkincode in ('azsit','mssit')
--AND RETUFWFILINGSTATUSSITR IN ('B')
--AND /*RETUFWSITRESIDENTCODE = 'SCSIT'
--AND RETUFWLITRESIDENTCODE = 'KY053'
--AND CTCTAXCODE=RETUFWLITRESIDENTCODE
-- AND RETUFWLITSDCODE = 'OH1522'

----------------------------------------------------ERROR E0106: INVALID DEDUCTION START DATE---------------------------------------------------
--Description

SELECT 'E0106: INVALID DEDUCTION START DATE.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECJOBCODE AS JOBCODE,EECJOBGROUPCODE AS JOBGROUPCODE
, EedDedCode as DedCode,  EedStartDate AS STARTDATE
, EedBenStartDate AS BENSTARTDATE 
, eedEEEligDate AS EEELIGDATE, eedbenstatusdate AS BENSTATUSDATE 
, eecdateofbenefitseniority AS dateofbenefitseniority 
, EedBenStatus as BenStatus 
-- select distinct EedDedCode,  EedStartDate
, EedBenStartDate,  eedEEEligDate
, eedbenstatusdate, eecdateofbenefitseniority
, EedBenStatus as BenStatus 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0106' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
and EedBenStatusDate is null
AND EEDDEDCODE IN (SELECT DEDDEDCODE FROM DEDCODE WHERE DEDISBENEFIT = 'Y')
--AND EEDDEDCODE IN ('401K','DRADV','GSULI','FEE')

-- Sample Updates

UPDATE LODEDED SET EEDSTARTDATE=EECDATEOFLASTHIRE
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0106' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--and EedBenStatusDate is null
AND EEDDEDCODE IN (SELECT DEDDEDCODE FROM DEDCODE WHERE DEDISBENEFIT = 'Y')
--AND EEDDEDCODE IN ('401K','DRADV','GSULI','FEE')


----------------------------------------------------ERROR E0107: INVALID RETUFWREGWGTAXMETHSITR---------------------------------------------------
--Description

SELECT 'E0107: INVALID RETUFWREGWGTAXMETHSITR'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, RETUFWREGWGTAXMETHSITR AS UFWREGWGTAXMETHSITR,RETUFWSITRESIDENTCODE AS UFWSITRESIDENTCODE
-- select distinct RETUFWLITRESIDENTCODE,RETUFWREGWGTAXMETHSITR 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN lodrsetx ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID 
LEFT JOIN [Ultipro_System].dbo.txcdmast on [Ultipro_System].dbo.txcdmast.mtctaxcode = retufwlitresidentcode
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN TAXCODE ON CTCTAXCODE=RETUFWLITRESIDENTCODE
left outer join u_ct_lodstatus on retPENDINGUPDATEID=stsPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0107' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
AND RETUFWSITRESIDENTCODE <> 'FLSIT'
-- AND wetPENDINGUPDATEID = '660829'
-- AND RETUFWSITRESIDENTCODE in ('azsit','mssit')
--AND wetufwsitworkincode in ('azsit','mssit')
--AND RETUFWFILINGSTATUSSITR IN ('B')
--AND /*RETUFWSITRESIDENTCODE = 'SCSIT'
--AND RETUFWLITRESIDENTCODE = 'KY053'
--AND CTCTAXCODE=RETUFWLITRESIDENTCODE
-- AND RETUFWLITSDCODE = 'OH1522'

-- Sample Updates

UPDATE LODRSETX SET RETUFWREGWGTAXMETHSITR = 'A'
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN lodrsetx ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID 
LEFT JOIN [Ultipro_System].dbo.txcdmast on [Ultipro_System].dbo.txcdmast.mtctaxcode = retufwlitresidentcode
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN TAXCODE ON CTCTAXCODE=RETUFWLITRESIDENTCODE
left outer join u_ct_lodstatus on retPENDINGUPDATEID=stsPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0107' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
AND RETUFWSITRESIDENTCODE <> 'FLSIT'
-- AND wetPENDINGUPDATEID = '660829'
-- AND RETUFWSITRESIDENTCODE in ('azsit','mssit')
--AND wetufwsitworkincode in ('azsit','mssit')
--AND RETUFWFILINGSTATUSSITR IN ('B')
--AND /*RETUFWSITRESIDENTCODE = 'SCSIT'
--AND RETUFWLITRESIDENTCODE = 'KY053'
--AND CTCTAXCODE=RETUFWLITRESIDENTCODE
-- AND RETUFWLITSDCODE = 'OH1522'


---------------------------------------------------ERROR E0108: Date of benefit seniority is required---------------------------------------------------
--Description

SELECT 'E0108: Date of benefit seniority is required.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECDATEOFLASTHIRE AS DATEOFLASTHIRE, EECDATEOFORIGINALHIRE AS DATEOFORIGINALHIRE, eecdateoftermination AS DATEOFTERMINATION
, EedStartDate AS STARTDATE
, EedBenStartDate AS BENSTARTDATE 
, eedEEEligDate AS EEELIGDATE, eedbenstatusdate AS BENSTATUSDATE 
, eecdateofbenefitseniority AS dateofbenefitseniority 
, EedBenStatus as BenStatus 
-- select distinct EedDedCode,  EedStartDate
, EedBenStartDate,  eedEEEligDate
, eedbenstatusdate, eecdateofbenefitseniority
, EedBenStatus as BenStatus 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0108' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
--and EedBenStatusDate is null
--AND EEDDEDCODE IN (SELECT DEDDEDCODE FROM DEDCODE WHERE DEDISBENEFIT = 'Y')
--AND EEDDEDCODE IN ('401K','DRADV','GSULI','FEE')

-- Sample Updates

UPDATE LODECOMP SET EECDATEOFBENEFITSENIORITY = '01/01/1994',EECDATEOFORIGINALHIRE = '01/01/1994',EECDATEOFLASTHIRE = '01/01/1994' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0108' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
and EedBenStatusDate is null
AND EEDDEDCODE IN (SELECT DEDDEDCODE FROM DEDCODE WHERE DEDISBENEFIT = 'Y')
--AND EEDDEDCODE IN ('401K','DRADV','GSULI','FEE')

----------------------------------------------ERROR E0109: SIT Resident Code does not exist in Company TaxCode Table---------------------------------------------------
--Description
--Have the SC add the resident state tax to the company or default SITres to SITworkin 
This is safe if --they are all terminated employees.  If some are active, you may need a chat with the SC


SELECT 'E0109: SIT Resident Code does not exist in Company TaxCode Table.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
,RETUFWFILINGSTATUSSITR AS UFWFILINGSTATUSSITR,RETUFWSITRESIDENTCODE AS UFWSITRESIDENTCODE
,wetufwsitworkincode AS WTUFWSITWORKINCODE, wetufwfilingstatussitw AS WTUFWFILINGSTATUSSITW
-- select distinct RETUFWFILINGSTATUSSITR,RETUFWSITRESIDENTCODE,RETUFWCOMPANYCODE, wetufwsitworkincode, wetufwfilingstatussitw
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODRSETX ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0109' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
--AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
--AND RETUFWSITRESIDENTCODE <> 'FLSIT'
-- AND wetPENDINGUPDATEID = '660829'
-- AND RETUFWSITRESIDENTCODE in ('azsit','mssit')
--AND wetufwsitworkincode in ('azsit','mssit')
--AND RETUFWFILINGSTATUSSITR IN ('B')
--AND /*RETUFWSITRESIDENTCODE = 'SCSIT'
--AND RETUFWCOMPANYCODE = 'LNCMF'

-- Sample Updates

UPDATE LODRSETX SET RETUFWSITRESIDENTCODE = SUBSTRING(RETUFWSITRESIDENTCODE,1,2) + 'SIT'
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODRSETX ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
left outer join u_ct_lodstatus on retPENDINGUPDATEID=stsPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0109' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
AND RETUFWSITRESIDENTCODE <> 'FLSIT'
-- AND wetPENDINGUPDATEID = '660829'
-- AND RETUFWSITRESIDENTCODE in ('azsit','mssit')
--AND wetufwsitworkincode in ('azsit','mssit')
--AND RETUFWFILINGSTATUSSITR IN ('B')
--AND /*RETUFWSITRESIDENTCODE = 'SCSIT'
--AND RETUFWCOMPANYCODE = 'LNCMF'


UPDATE LODRSETX SET RETUFWSITRESIDENTCODE = 'COSIT' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODRSETX ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
left outer join u_ct_lodstatus on retPENDINGUPDATEID=stsPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0109' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
AND RETUFWSITRESIDENTCODE <> 'FLSIT'
-- AND wetPENDINGUPDATEID = '660829'
-- AND RETUFWSITRESIDENTCODE in ('azsit','mssit')
--AND wetufwsitworkincode in ('azsit','mssit')
--AND RETUFWFILINGSTATUSSITR IN ('B')
--AND /*RETUFWSITRESIDENTCODE = 'SCSIT'
--AND RETUFWCOMPANYCODE = 'LNCMF'


update lodRSetx set RETUFWFILINGSTATUSSITR = 'F' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODRSETX ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
left outer join u_ct_lodstatus on retPENDINGUPDATEID=stsPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0109' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
AND RETUFWSITRESIDENTCODE <> 'FLSIT'
-- AND wetPENDINGUPDATEID = '660829'
-- AND RETUFWSITRESIDENTCODE in ('azsit','mssit')
--AND wetufwsitworkincode in ('azsit','mssit')
--AND RETUFWFILINGSTATUSSITR IN ('B')
--AND /*RETUFWSITRESIDENTCODE = 'SCSIT'
--AND RETUFWCOMPANYCODE = 'LNCMF'

-- set taxes based on Location/SITworkin.  This would be a rare update since this is resident taxes.  Location is work-in.
update lodRSetx set RetUFWSITResidentCode= LocAddressState+'SIT',  retufwaddresscity=locaddresscity
, retufwaddressstate=locaddressstate, retufwsitresidentcode = LocAddressState+'SIT' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODRSETX ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN dbo.Location ON dbo.Location.LocCode = dbo.LodEComp.EecLocation 
WHERE IRRMSGCODE = 'E0109' AND IrrSessionID = 'CONV'


-----------------------------------ERROR E0110: More than one direct deposit record using available balance as a deposit rule were found---------------------------------------------------
--Description

SELECT 'E0110: More than one direct deposit record using available balance as a deposit rule were found.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EDDACCT AS ACCT,EDDAMTORPCT AS AMTORPCT,EDDEEBANKROUTE AS EEBANKROUTE,EDDDEPOSITRULE AS DEPOSITRULE,EDDSEQUENCE AS SEQUENCE
-- select distinct EDDACCT,EDDAMTORPCT,EDDEEBANKROUTE,EDDDEPOSITRULE,EDDSEQUENCE
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDEP ON EDDPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0110' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'

-- Sample Updates

DELETE LODEDEP 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDEP ON EDDPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0110' AND IrrSessionID = 'CONV'
--AND EDDRECID=IRRRECID
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
and EDDRECID in ('123','456')


----------------------------------------------------ERROR E0111: DIRECT DEPOSIT INFO ERROR---------------------------------------------------
--Description

SELECT 'E0111: DIRECT DEPOSIT INFO ERROR.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EDDACCT AS ACCT,EDDAMTORPCT AS AMTORPCT,EDDEEBANKROUTE AS EEBANKROUTE,EDDDEPOSITRULE AS DEPOSITRULE,EDDSEQUENCE AS SEQUENCE
-- select distinct EDDACCT,EDDAMTORPCT,EDDEEBANKROUTE,EDDDEPOSITRULE,EDDSEQUENCE
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDEP ON EDDPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0111' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
--AND EDDPENDINGUPDATEID IN ('NGI000162','XNGC011223','XNGC011622','XNGC002947')

-- Sample Updates

DELETE LODEDEP
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDEP ON EDDPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0111' AND IrrSessionID = 'CONV'
--AND EDDDEPOSITRULE = 'P'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
--AND EDDPENDINGUPDATEID IN ('NGI000162','XNGC011223','XNGC011622','XNGC002947')

----------------------------------------------------ERROR E0114: INVALID WETUFWBLOCKTAXAMTSITW---------------------------------------------------
--Description

SELECT 'E0114: INVALID WETUFWBLOCKTAXAMTSITW.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
,WETUFWBLOCKTAXAMTSITW AS WTUFWBLOCKTAXAMTSITW,WETUFWSITWORKINCODE AS WTUFWSITWORKINCODE,WETUFWEXTRATAXDOLLARSSITW AS WTUFWEXTRATAXDOLLARSSITW
-- select distinct WETPENDINGUPDATEID, WETUFWBLOCKTAXAMTSITW,WETUFWSITWORKINCODE,WETUFWEXTRATAXDOLLARSSITW
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODRSETX ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0114' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
AND RETUFWSITRESIDENTCODE <> 'FLSIT'
-- AND wetPENDINGUPDATEID = '660829'
-- AND RETUFWSITRESIDENTCODE in ('azsit','mssit')
--AND wetufwsitworkincode in ('azsit','mssit')
--AND RETUFWFILINGSTATUSSITR IN ('B')
--AND /*RETUFWSITRESIDENTCODE = 'SCSIT'
--AND RETUFWCOMPANYCODE = 'LNCMF'

-- Sample Updates

UPDATE LODWKETX SET WETUFWBLOCKTAXAMTSITW = 'N' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODRSETX ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0114' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
-- AND RETUFWSITRESIDENTCODE in ('azsit','mssit')
--AND wetufwsitworkincode in ('azsit','mssit')

-------------------------------------------ERROR E0115: Invalid Filing Status for LIT WCC Code--------------------------------------
--Description

SELECT 'E0115: Invalid Filing Status for LIT WCC Code.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
,WETUFWFILINGSTATUSLITc AS UFWFILINGSTATUSLITc, WETUFWFILINGSTATUSSITW AS UFWFILINGSTATUSSITW
-- select distinct WETUFWFILINGSTATUSLITc, WETUFWFILINGSTATUSSITW
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0115' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND WETUFWLOCATION = 'FL'
AND RETUFWSITRESIDENTCODE <> 'FLSIT'
-- AND wetPENDINGUPDATEID = '660829'
-- AND RETUFWSITRESIDENTCODE in ('azsit','mssit')
--AND wetufwsitworkincode in ('azsit','mssit')
--AND RETUFWFILINGSTATUSSITR IN ('B')
--AND /*RETUFWSITRESIDENTCODE = 'SCSIT'
--AND RETUFWCOMPANYCODE = 'LNCMF'

-- Sample Updates

UPDATE LODWKETX SET WETUFWFILINGSTATUSLITc = WETUFWFILINGSTATUSSITW
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0115' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
AND RETUFWSITRESIDENTCODE <> 'FLSIT'
-- AND wetPENDINGUPDATEID = '660829'
-- AND RETUFWSITRESIDENTCODE in ('azsit','mssit')
--AND wetufwsitworkincode in ('azsit','mssit')
--AND RETUFWFILINGSTATUSSITR IN ('B')
--AND /*RETUFWSITRESIDENTCODE = 'SCSIT'
--AND RETUFWCOMPANYCODE = 'LNCMF'

----------------------------------------------------ERROR E0116: Invalid Filing Status for LIT Other Code---------------------------------------------------
--Description
--The filling statuses doesn't exist in the setup or wrong. It could be that they are in a location 
--that has local taxes, but they didn't provide a local filling status, 
--so defualted to whatever is in their Work SIT filling.

SELECT 'E0116: Invalid Filing Status for LIT Other Code.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
,WETUFWFILINGSTATUSLITH AS UFWFILINGSTATUSLITH, WETUFWFILINGSTATUSSITW AS UFWFILINGSTATUSSITW
-- select distinct WETUFWFILINGSTATUSLITH, WETUFWFILINGSTATUSSITW
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0116' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
--AND wetufwsitworkincode in ('azsit','mssit')

-- Sample Updates

UPDATE LODWKETX SET WETUFWFILINGSTATUSLITH = WETUFWFILINGSTATUSSITW 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0116' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
--AND wetufwsitworkincode in ('azsit','mssit')

----------------------------------------------------ERROR E0117: Invalid Filing Status for LIT OCC Code---------------------------------------------------
--Description

SELECT 'E0117: Invalid Filing Status for LIT OCC Code.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
,WETUFWFILINGSTATUSLITO AS UFWFILINGSTATUSLITO ,WETUFWLITOCCCODE AS UFWLITOCCCODE
,WETUFWSITWORKINCODE AS UFWSITWORKINCODE,WETUFWFILINGSTATUSSITW AS UFWFILINGSTATUSSITW
-- select distinct WETUFWFILINGSTATUSLITO,WETUFWLITOCCCODE,WETUFWSITWORKINCODE ,WETUFWFILINGSTATUSSITW
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0117' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
--AND wetufwsitworkincode in ('azsit','mssit')

-- Sample Updates

UPDATE LODWKETX SET WETUFWFILINGSTATUSLITO = WETUFWFILINGSTATUSSITW 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0117' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
--AND wetufwsitworkincode in ('azsit','mssit')

UPDATE LODWKETX SET WETUFWFILINGSTATUSLITO = NULL 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0117' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
--AND wetufwsitworkincode in ('azsit','mssit')

----------------------------------------------------ERROR E0118: Invalid Filing Status for LIT WorkIn Code-------------------------------------
--Description
--The local tax filling status isn't setup in the local Tax setup.
--Go to BO, 
--select the correct compontent company, then Taxes. In the pull menu select Local, select the local tax code. 
--Select Details. You see the valid status code (i.e. M, S)

SELECT 'E0118: Invalid Filing Status for LIT WorkIn Code.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
,WETUFWFILINGSTATUSLITW AS UFWFILINGSTATUSLITW ,WETUFWLITWORKINCODE AS UFWLITWORKINCODE,WETUFWFILINGSTATUSSITW AS UFWFILINGSTATUSSITW
-- select distinct WETUFWFILINGSTATUSLITW,WETUFWLITWORKINCODE,WETUFWFILINGSTATUSSITW
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0118' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
--AND wetufwsitworkincode in ('azsit','mssit')

-- Sample Updates

UPDATE LODWKETX SET WETUFWFILINGSTATUSLITW = 'S',WETUFWFILINGSTATUSLITH = 'S'
,WETUFWFILINGSTATUSLITO = 'S',WETUFWFILINGSTATUSSITW = 'S' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0118' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
--AND wetufwsitworkincode in ('azsit','mssit')

update lodwketx set WETUFWFILINGSTATUSLITW = WETUFWFILINGSTATUSSITW 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0118' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
--AND wetufwsitworkincode in ('azsit','mssit')

---MB DONE---------------------------------ERROR E0119: Invalid Filing Status for SIT WorkIn Code---------------------------------------------------
---Description sourced from Quip
---Usually AZ or NJ will have a incoming filing of Status of S, M, when it should be A, B, C, etc. Have the customer correct,
---or set a default  (e.g.  S to A and M to B).   Fix the E0090 error first, then can set the 
---WetUFWFilingStatusSITW to match RetUFWFilingStatusSITR

--View error Detail
SELECT 'E0119: Invalid Filing Status for SIT WorkIn Code.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
--select two lines above are used for issue/assumption form.
, WETUFWFILINGSTATUSSITW as UFWFILINGSTATUSSITW, WETUFWSITWORKINCODE as UFWSITWORKINCODE
-- select distinct WETUFWFILINGSTATUSSITW as UFWFILINGSTATUSSITW, WETUFWSITWORKINCODE as UFWSITWORKINCODE
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodWketx ON WETPENDINGUPDATEID = IRRPENDINGUPDATEID --AND EEDRECID=IRRRECID
WHERE IRRMSGCODE = 'E0119' AND IrrSessionID = 'CONV'
ORDER BY EecEmplStatus, EepNameLast, EepNameFirst, EecEmpno

-- Sample Updates

UPDATE  LodWkEtx set WetUFWFilingStatusSITW = RetUFWFilingStatusSITR
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodWketx ON WETPENDINGUPDATEID = IRRPENDINGUPDATEID --AND EEDRECID=IRRRECID
WHERE IRRMSGCODE = 'E0119' AND IrrSessionID = 'CONV'   

-----------------------------------ERROR E0123: LIT WorkIn Code does not exist in Company TaxCode table------ON QUIP NOT ON SCRIPT FILE--------
---Description 

SELECT 'E0123: LIT WorkIn Code does not exist in Company TaxCode table'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, WetUFWLITWorkInCode, EecLITWorkInCode, WetRecID 
FROM LodEComp
JOIN LodEPers ON EecPendingUpdateID = EepPendingUpdateID
JOIN LodWkEtx ON EecPendingUpdateID = WetPendingUpdateID
left outer join Company on cmpcompanycode = eeccompanycode
WHERE EecSessionID = 'CONV'
AND ISNULL(WetPendingTransTypeLITW,'') IN ('A','U')
AND WetUFWLITWorkInCode <> ''
AND NOT EXISTS(SELECT 1 FROM (SELECT MtwTaxCode, MtwFilingStatus 
								FROM ULTIPRO_SYSTEM.DBO.TxCdMast
								JOIN ULTIPRO_SYSTEM.DBO.TxWhMast ON MtwDateTimeCreated = MtcDateTimeCreated AND MtwTaxCode = MtcTaxCode
								WHERE MtcHasBeenReplaced = 'N'
								AND MtcEffectiveDate <= GETDATE()
								AND MtcEffectiveStopDate > GETDATE()) as taxtable
								WHERE EecSessionID = 'CONV'
								AND CmpCompanyCode = WetUFWCompanyCode)

-- Sample Updates

Update LodEComp 
set EecLITWorkInCode='XXX'
FROM LodEComp
JOIN LodEPers ON EecPendingUpdateID = EepPendingUpdateID
JOIN LodWkEtx ON EecPendingUpdateID = WetPendingUpdateID
left outer join Company on cmpcompanycode = eeccompanycode
WHERE EecSessionID = 'CONV'
AND ISNULL(WetPendingTransTypeLITW,'') IN ('A','U')
AND WetUFWLITWorkInCode <> ''
AND NOT EXISTS(SELECT 1 FROM (SELECT MtwTaxCode, MtwFilingStatus 
								FROM ULTIPRO_SYSTEM.DBO.TxCdMast
								JOIN ULTIPRO_SYSTEM.DBO.TxWhMast ON MtwDateTimeCreated = MtcDateTimeCreated AND MtwTaxCode = MtcTaxCode
								WHERE MtcHasBeenReplaced = 'N'
								AND MtcEffectiveDate <= GETDATE()
								AND MtcEffectiveStopDate > GETDATE()) as taxtable
								WHERE EecSessionID = 'CONV'
								AND CmpCompanyCode = WetUFWCompanyCode)
and wetpendingupdateid = 'xkkxkxkxkkx'


Update LodWkEtx
 set WetUFWLITWorkInCode='XXX'
FROM LodEComp
JOIN LodEPers ON EecPendingUpdateID = EepPendingUpdateID
JOIN LodWkEtx ON EecPendingUpdateID = WetPendingUpdateID
left outer join Company on cmpcompanycode = eeccompanycode
WHERE EecSessionID = 'CONV'
AND ISNULL(WetPendingTransTypeLITW,'') IN ('A','U')
AND WetUFWLITWorkInCode <> ''
AND NOT EXISTS(SELECT 1 FROM (SELECT MtwTaxCode, MtwFilingStatus 
								FROM ULTIPRO_SYSTEM.DBO.TxCdMast
								JOIN ULTIPRO_SYSTEM.DBO.TxWhMast ON MtwDateTimeCreated = MtcDateTimeCreated AND MtwTaxCode = MtcTaxCode
								WHERE MtcHasBeenReplaced = 'N'
								AND MtcEffectiveDate <= GETDATE()
								AND MtcEffectiveStopDate > GETDATE()) as taxtable
								WHERE EecSessionID = 'CONV'
								AND CmpCompanyCode = WetUFWCompanyCode)
and wetpendingupdateid = 'xkkxkxkxkkx'

----------ERROR E0124: More than one location code exists for the same Source EmpNo and Company Code and the company is not setup to use Location for taxes------ON QUIP NOT ON SCRIPT FILE---NO UPDATE-----
---Description sourced from Quip
--More than one location code exists for the same Source EmpNo and Company Code and the company is not setup to use Location for taxes
--NO UPDATE

SELECT 'E0124: More than one location code exists for the same Source EmpNo and Company Code and the company is not setup to use Location for taxes'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EecLocation, CmmUseLocationForTaxes
FROM LodEComp
JOIN LodEPers 
    ON EecPendingUpdateID = EepPendingUpdateID
JOIN LodWkEtx 
    ON EecPendingUpdateID = WetPendingUpdateID
JOIN CompMast 
    ON CmmUseLocationForTaxes = 'Y'
WHERE EecSessionID = 'CONV'
  AND EecPendingUpdateID IN (SELECT EecPendingUpdateID
								FROM LodECOmp
								JOIN LodWkEtx
								   ON WetPendingUpdateID = EecPendingUpdateID
							   GROUP BY EecPendingUpdateID
							   HAVING COUNT(*) > 1)

----------ERROR E0125: More than one Primary Location code exists for the same SSN and same Company code------ON QUIP NOT ON SCRIPT FILE---NO UPDATE-----
---Description sourced from Quip
--More than one Primary Location code exists for the same SSN and same Company code

SELECT 'ERROR E0125: More than one Primary Location code exists for the same SSN and same Company code'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, WetUFWLocation
FROM LodEComp
JOIN LodEPers 
	ON EecPendingUpdateID = EepPendingUpdateID
JOIN LodWkEtx
	ON EecPendingUpdateID = WetPendingUpdateID
JOIN CompMast 
	ON CmmUseLocationForTaxes = 'Y'
WHERE EecSessionID = 'CONV'
  AND WetUFWIsPrimaryLocation = 'Y'
  AND EecPendingUpdateID IN (SELECT EecPendingUpdateID
								FROM LodEComp
								JOIN LodWkEtx
									ON WetPendingUpdateID = EecPendingUpdateID
								 AND WetUFWIsPrimaryLocation = 'Y'
							GROUP BY EecPendingUpdateId
							HAVING COUNT(*) > 1)

-------------------------------------ERROR E0134: SitWorkin Does not exist in the tax table---------------------------------------------------
--Description

SELECT 'E0134: SitWorkin Does not exist in the tax table.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
,WETUFWFILINGSTATUSLITW AS UFWFILINGSTATUSLITW ,WETUFWLITWORKINCODE AS UFWLITWORKINCODE,WETUFWFILINGSTATUSSITW AS UFWFILINGSTATUSSITW
,WETUFWLOCATION AS UFWLOCATION,WETUFWCOMPANYCODE AS UFWCOMPANYCODE
-- select distinct WETUFWFILINGSTATUSLITW,WETUFWLITWORKINCODE,WETUFWFILINGSTATUSSITW,WETUFWLOCATION,WETUFWCOMPANYCODE
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN dbo.[Location] ON [Location].LocCode =LodEComp.EecLocation 
WHERE IRRMSGCODE = 'E0134' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
--AND wetufwsitworkincode in ('azsit','mssit')
-- AND WETUFWCOMPANYCODE = 'LNCMF'

-- Sample Updates

UPDATE LODWKETX SET WETUFWSITWORKINCODE = 'COSIT' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN dbo.[Location] ON [Location].LocCode =LodEComp.EecLocation 
WHERE IRRMSGCODE = 'E0134' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
--AND wetufwsitworkincode in ('azsit','mssit')
-- AND WETUFWCOMPANYCODE = 'LNCMF'
 
UPDATE LODECOMP SET EECSITRESIDENTCODE = 'COSIT',EECSTATSUI = 'COSUIER'
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN dbo.[Location] ON [Location].LocCode =LodEComp.EecLocation 
WHERE IRRMSGCODE = 'E0134' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
--AND wetufwsitworkincode in ('azsit','mssit')
-- AND WETUFWCOMPANYCODE = 'LNCMF'

UPDATE LODWKETX SET WETUFWSITWORKINCODE = SUBSTRING(WETUFWSITWORKINCODE,1,2) + 'SIT'
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN dbo.[Location] ON [Location].LocCode =LodEComp.EecLocation 
WHERE IRRMSGCODE = 'E0134' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
--AND wetufwsitworkincode in ('azsit','mssit')
-- AND WETUFWCOMPANYCODE = 'LNCMF'

UPDATE LodWkEtx set WETUFWSITWORKINCODE = LocAddressState+'SIT' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN dbo.[Location] ON [Location].LocCode =LodEComp.EecLocation 
WHERE IRRMSGCODE = 'E0134' AND IrrSessionID = 'CONV'

----------------------------------------ERROR EO138: SIT WorkIn Code two digit state code does not match LIT WorkIn Code or LIT OCC Code, or LIT WCC Code, or LIT Other Code two digit state code---------------------------------------------------
--Description

SELECT 'E0138: WorkIn Code two digit state code does not match LIT WorkIn Code or LIT OCC Code, or LIT WCC Code, or LIT Other Code two digit state code'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
,WETUFWFILINGSTATUSLITW AS UFWFILINGSTATUSLITW ,WETUFWLITWORKINCODE AS UFWLITWORKINCODE,WETUFWFILINGSTATUSSITW AS UFWFILINGSTATUSSITW
,WETUFWLOCATION AS UFWLOCATION,WETUFWCOMPANYCODE AS UFWCOMPANYCODE, WETUFWSITWORKINCODE = UFWSITWORKINCODE
-- select distinct WETUFWFILINGSTATUSLITW,WETUFWLITWORKINCODE,WETUFWFILINGSTATUSSITW,WETUFWLOCATION,WETUFWCOMPANYCODE, WETUFWSITWORKINCODE
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0138' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
--AND wetufwsitworkincode in ('azsit','mssit')
-- AND WETUFWCOMPANYCODE = 'LNCMF'
--AND WETUFWLITWORKINCODE = '3912'
--AND EECLOCATION = 'INDANA'

-- Sample Updates

UPDATE LODWKETX SET WETUFWLITOCCCODE = 'PA100049',WETUFWLITWORKINCODE = 'PA100018' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0138' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
--AND wetufwsitworkincode in ('azsit','mssit')
-- AND WETUFWCOMPANYCODE = 'LNCMF'
--AND WETUFWLITWORKINCODE = '3912'
--AND EECLOCATION = 'INDANA'

UPDATE LODWKETX SET WetUFWLITOCCCode  = LocLITOCCCode
					, WetUFWLITWorkInCode = LocLITNonResWorkinCode 
					, WetUFWLITOtherCode = LocLITOtherCode
					, WetUFWLITWCCCode = LocLITWCCCode
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0138' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
--AND wetufwsitworkincode in ('azsit','mssit')
-- AND WETUFWCOMPANYCODE = 'LNCMF'
--AND WETUFWLITWORKINCODE = '3912'
--AND EECLOCATION = 'INDANA'

UPDATE LODWKETX SET WETUFWSITWORKINCODE ='OHSIT'
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0138' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
--AND wetufwsitworkincode in ('azsit','mssit')
-- AND WETUFWCOMPANYCODE = 'LNCMF'
--AND WETUFWLITWORKINCODE = '3912'
--AND EECLOCATION = 'INDANA'

UPDATE LODWKETX SET WETUFWlOCATION ='HENDRX'
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0138' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
--AND wetufwsitworkincode in ('azsit','mssit')
-- AND WETUFWCOMPANYCODE = 'LNCMF'
--AND WETUFWLITWORKINCODE = '3912'
--AND EECLOCATION = 'INDANA'

UPDATE LODECOMP SET EECLOCATION ='HENDRX'
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0138' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
--AND wetufwsitworkincode in ('azsit','mssit')
-- AND WETUFWCOMPANYCODE = 'LNCMF'
--AND WETUFWLITWORKINCODE = '3912'
AND EECLOCATION = 'INDANA'

UPDATE LODWKETX SET WETUFWLITWORKINCODE = NULL,WETUFWLITOCCCODE = NULL,WETUFWLITOTHERCODE = NULL 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0138' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
--AND wetufwsitworkincode in ('azsit','mssit')
-- AND WETUFWCOMPANYCODE = 'LNCMF'
--AND WETUFWLITWORKINCODE = '3912'
AND WETUFWLITWORKINCODE IN ('IN162','OH1255')
--AND EECLOCATION = 'INDANA'

-----------------------------------------------ERROR E0139: EDDddOrPrenote is incorrect---------------------------------------------------
--Description

SELECT 'E0139: EDDddOrPrenote is incorrect.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EDDddOrPrenote AS DDorPrenote, EDDACCT AS ACCT,EDDAMTORPCT AS AMTORPCT,EDDEEBANKROUTE AS EEBANKROUTE,EDDDEPOSITRULE AS DEPOSITRULE,EDDSEQUENCE AS SEQUENCE
-- select distinct EDDddOrPrenote, EDDACCT,EDDAMTORPCT,EDDEEBANKROUTE,EDDDEPOSITRULE,EDDSEQUENCE
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDEP ON EDDPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0139' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
AND EDDPENDINGUPDATEID IN ('NGI000162','XNGC011223','XNGC011622','XNGC002947')

-- Sample Updates

UPDATE LODEDEP SET EDDDDORPRENOTE = 'P'
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDEP ON EDDPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0139' AND IrrSessionID = 'CONV'


-------------------------------------ERROR E0143: WorkIn State Code does not match Location WorkIn State Code-----------------------------------------------------------
--Description

SELECT 'E0143: WorkIn State Code does not match Location WorkIn State Code'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECLOCATION, EECCOMPANYCODE, eecsitworkinstatecode
, WETUFWFILINGSTATUSLITW AS UFWFILINGSTATUSLITW ,WETUFWLITWORKINCODE AS UFWLITWORKINCODE,WETUFWFILINGSTATUSSITW AS UFWFILINGSTATUSSITW
, WETUFWLOCATION AS UFWLOCATION,WETUFWCOMPANYCODE AS UFWCOMPANYCODE, WETUFWSITWORKINCODE = UFWSITWORKINCODE
, LOCCODE, LocSITWorkInStateCode, LocLITResWorkInCode, LocLITNonResWorkInCode
-- select distinct WETUFWFILINGSTATUSLITW,WETUFWLITWORKINCODE,WETUFWFILINGSTATUSSITW,WETUFWLOCATION,WETUFWCOMPANYCODE, WETUFWSITWORKINCODE, LOCSITWORKINSTATECODE, EECLOCATION, EECCOMPANYCODE, eecsitworkinstatecode,LOCCODE,LocSITWorkInStateCode,LocLITResWorkInCode,LocLITNonResWorkInCode
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN [LOCATION] ON LOCCODE=EECLOCATION
WHERE IRRMSGCODE = 'E0143' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
--AND wetufwsitworkincode in ('azsit','mssit')
-- AND WETUFWCOMPANYCODE = 'LNCMF'
--AND WETUFWLITWORKINCODE = '3912'
--AND EECLOCATION = 'INDANA'
--AND LOCCODE IN ('AL0','AL2','AL4','AL5','AL7','ASH','BRA','GOS','OSN','NRM','HEB','MRY','MRD','MCW','HLD','GRN')
--AND WETUFWLOCATION IS NULL

-- Sample Updates

update lodecomp set eecsitworkinstatecode = LOCSITWORKINSTATECODE
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN [LOCATION] ON LOCCODE=EECLOCATION
WHERE IRRMSGCODE = 'E0143' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
--AND wetufwsitworkincode in ('azsit','mssit')
-- AND WETUFWCOMPANYCODE = 'LNCMF'
--AND WETUFWLITWORKINCODE = '3912'
--AND EECLOCATION = 'INDANA'
--AND LOCCODE IN ('AL0','AL2','AL4','AL5','AL7','ASH','BRA','GOS','OSN','NRM','HEB','MRY','MRD','MCW','HLD','GRN')
--AND WETUFWLOCATION IS NULL

update lodwketx set WETUFWSITWORKINCODE = LOCSITWORKINSTATECODE
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN [LOCATION] ON LOCCODE=EECLOCATION
WHERE IRRMSGCODE = 'E0143' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
--AND wetufwsitworkincode in ('azsit','mssit')
-- AND WETUFWCOMPANYCODE = 'LNCMF'
--AND WETUFWLITWORKINCODE = '3912'
--AND EECLOCATION = 'INDANA'
AND LOCCODE IN ('AL0','AL2','AL4','AL5','AL7','ASH','BRA','GOS','OSN','NRM','HEB','MRY','MRD','MCW','HLD','GRN')
--AND WETUFWLOCATION IS NULL

UPDATE LODWKETX SET WETUFWSITWORKINCODE = LOCSITWORKINSTATECODE 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LOCATION ON LOCCODE=EECLOCATION
WHERE IRRMSGCODE = 'E0143' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
--AND wetufwsitworkincode in ('azsit','mssit')
-- AND WETUFWCOMPANYCODE = 'LNCMF'
--AND WETUFWLITWORKINCODE = '3912'
--AND EECLOCATION = 'INDANA'
--AND LOCCODE IN ('AL0','AL2','AL4','AL5','AL7','ASH','BRA','GOS','OSN','NRM','HEB','MRY','MRD','MCW','HLD','GRN')
--AND WETUFWLOCATION IS NULL

UPDATE LODEEMST SET EEMUFWSTATESUI = SUBSTRING(LOCSITWORKINSTATECODE,1,2) + 'SUIER',EEMUFWSTATEWC = 
SUBSTRING(LOCSITWORKINSTATECODE,1,2) 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LOCATION ON LOCCODE=EECLOCATION
WHERE IRRMSGCODE = 'E0143' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
--AND wetufwsitworkincode in ('azsit','mssit')
-- AND WETUFWCOMPANYCODE = 'LNCMF'
--AND WETUFWLITWORKINCODE = '3912'
--AND EECLOCATION = 'INDANA'
--AND LOCCODE IN ('AL0','AL2','AL4','AL5','AL7','ASH','BRA','GOS','OSN','NRM','HEB','MRY','MRD','MCW','HLD','GRN')
--AND WETUFWLOCATION IS NULL

UPDATE LODWKETX SET WETUFWSITWORKINCODE = 'ALSIT' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LOCATION ON LOCCODE=EECLOCATION
WHERE IRRMSGCODE = 'E0143' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
--AND wetufwsitworkincode in ('azsit','mssit')
-- AND WETUFWCOMPANYCODE = 'LNCMF'
--AND WETUFWLITWORKINCODE = '3912'
--AND EECLOCATION = 'INDANA'
--AND LOCCODE IN ('AL0','AL2','AL4','AL5','AL7','ASH','BRA','GOS','OSN','NRM','HEB','MRY','MRD','MCW','HLD','GRN')
--AND WETUFWLOCATION IS NULL


UPDATE LODWKETX SET WETUFWLOCATION = 'NCSDAC'
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LOCATION ON LOCCODE=EECLOCATION
WHERE IRRMSGCODE = 'E0143' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
--AND wetufwsitworkincode in ('azsit','mssit')
-- AND WETUFWCOMPANYCODE = 'LNCMF'
--AND WETUFWLITWORKINCODE = '3912'
--AND EECLOCATION = 'INDANA'
--AND LOCCODE IN ('AL0','AL2','AL4','AL5','AL7','ASH','BRA','GOS','OSN','NRM','HEB','MRY','MRD','MCW','HLD','GRN')
--AND WETUFWLOCATION IS NULL


UPDATE LODECOMP SET EECLOCATION = 'NCSDAC' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LOCATION ON LOCCODE=EECLOCATION
WHERE IRRMSGCODE = 'E0143' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
--AND wetufwsitworkincode in ('azsit','mssit')
-- AND WETUFWCOMPANYCODE = 'LNCMF'
--AND WETUFWLITWORKINCODE = '3912'
--AND EECLOCATION = 'INDANA'
--AND LOCCODE IN ('AL0','AL2','AL4','AL5','AL7','ASH','BRA','GOS','OSN','NRM','HEB','MRY','MRD','MCW','HLD','GRN')
--AND WETUFWLOCATION IS NULL

UPDATE LODWKETX SET WETUFWLOCATION = 'NCSDAC'
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LOCATION ON LOCCODE=EECLOCATION
WHERE IRRMSGCODE = 'E0143' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
--AND wetufwsitworkincode in ('azsit','mssit')
-- AND WETUFWCOMPANYCODE = 'LNCMF'
--AND WETUFWLITWORKINCODE = '3912'
--AND EECLOCATION = 'INDANA'
--AND LOCCODE IN ('AL0','AL2','AL4','AL5','AL7','ASH','BRA','GOS','OSN','NRM','HEB','MRY','MRD','MCW','HLD','GRN')
--AND WETUFWLOCATION IS NULL

UPDATE LODEEMST SET EEMUFWSTATESUI = 'ALSUIER',EEMUFWSTATEWC = 'AL' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LOCATION ON LOCCODE=EECLOCATION
WHERE IRRMSGCODE = 'E0143' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
--AND wetufwsitworkincode in ('azsit','mssit')
-- AND WETUFWCOMPANYCODE = 'LNCMF'
--AND WETUFWLITWORKINCODE = '3912'
--AND EECLOCATION = 'INDANA'
--AND LOCCODE IN ('AL0','AL2','AL4','AL5','AL7','ASH','BRA','GOS','OSN','NRM','HEB','MRY','MRD','MCW','HLD','GRN')
--AND WETUFWLOCATION IS NULL


UPDATE LODEEMST SET EEMUFWSTATESUI = 'MASUIER',EEMUFWSTATEWC = 'MA' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LOCATION ON LOCCODE=EECLOCATION
WHERE IRRMSGCODE = 'E0143' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
--AND wetufwsitworkincode in ('azsit','mssit')
-- AND WETUFWCOMPANYCODE = 'LNCMF'
--AND WETUFWLITWORKINCODE = '3912'
--AND EECLOCATION = 'INDANA'
--AND LOCCODE IN ('AL0','AL2','AL4','AL5','AL7','ASH','BRA','GOS','OSN','NRM','HEB','MRY','MRD','MCW','HLD','GRN')
--AND WETUFWLOCATION IS NULL

---------------------------------Error E0144: WorkIn LIT Code does not match Location WorkIn LIT Code.---------------------------------------------------------------------------
--Description
--The LIT Workin doesn't match up to the local taxes setup for that location. 
--Look at the locations, tax tab, and then redient work-in tax and non-resident work-in- tax. 
--It should be one of those
-- In the location tax screen, they have to pick one of the two things, 
--Resident tax or non-resident tax. This goes into the LITworkintax. If it doesn't match, it needs to be updated. 
--It's hard to tell which they should have since its based on where they live.

SELECT 'E0144: WorkIn LIT Code does not match Location WorkIn LIT Code.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECLOCATION, eecsitworkinstatecode
, WETUFWFILINGSTATUSLITW AS UFWFILINGSTATUSLITW ,WETUFWLITWORKINCODE AS UFWLITWORKINCODE,WETUFWFILINGSTATUSSITW AS UFWFILINGSTATUSSITW
, WETUFWLOCATION AS UFWLOCATION,WETUFWCOMPANYCODE AS UFWCOMPANYCODE, WETUFWSITWORKINCODE = UFWSITWORKINCODE, LOCSITWORKINSTATECODE, EECLOCATION, EECCOMPANYCODE, eecsitworkinstatecode
, LOCCODE,LocSITWorkInStateCode,LocLITResWorkInCode,LocLITNonResWorkInCode
, RETUFWLITRESIDENTCODE
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODRSETX ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN [LOCATION] ON LOCCODE=EECLOCATION
WHERE IRRMSGCODE = 'E0144' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
--AND wetufwsitworkincode in ('azsit','mssit')
-- AND WETUFWCOMPANYCODE = 'LNCMF'
--AND WETUFWLITWORKINCODE = '3912'
--AND EECLOCATION = 'INDANA'
--AND LOCCODE IN ('AL0','AL2','AL4','AL5','AL7','ASH','BRA','GOS','OSN','NRM','HEB','MRY','MRD','MCW','HLD','GRN')
--AND WETUFWLOCATION IS NULL

-- Sample Updates

UPDATE LODWKETX SET WETUFWLITWORKINCODE = NULL,WETPENDINGTRANSTYPELITW = NULL 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODRSETX ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN [LOCATION] ON LOCCODE=EECLOCATION
WHERE IRRMSGCODE = 'E0144' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
--AND wetufwsitworkincode in ('azsit','mssit')
-- AND WETUFWCOMPANYCODE = 'LNCMF'
--AND WETUFWLITWORKINCODE = '3912'
--AND EECLOCATION = 'INDANA'
--AND LOCCODE IN ('AL0','AL2','AL4','AL5','AL7','ASH','BRA','GOS','OSN','NRM','HEB','MRY','MRD','MCW','HLD','GRN')
--AND WETUFWLOCATION IS NULL

UPDATE LODECOMP SET EECLOCATION= WETUFWLOCATION 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODRSETX ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN [LOCATION] ON LOCCODE=EECLOCATION
WHERE IRRMSGCODE = 'E0144' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
--AND wetufwsitworkincode in ('azsit','mssit')
-- AND WETUFWCOMPANYCODE = 'LNCMF'
--AND WETUFWLITWORKINCODE = '3912'
--AND EECLOCATION = 'INDANA'
--AND LOCCODE IN ('AL0','AL2','AL4','AL5','AL7','ASH','BRA','GOS','OSN','NRM','HEB','MRY','MRD','MCW','HLD','GRN')
--AND WETUFWLOCATION IS NULL

UPDATE LODWKETX SET WETUFWLOCATION = WETUFWLITWORKINCODE 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODRSETX ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN [LOCATION] ON LOCCODE=EECLOCATION
WHERE IRRMSGCODE = 'E0144' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
--AND wetufwsitworkincode in ('azsit','mssit')
-- AND WETUFWCOMPANYCODE = 'LNCMF'
--AND WETUFWLITWORKINCODE = '3912'
--AND EECLOCATION = 'INDANA'
--AND LOCCODE IN ('AL0','AL2','AL4','AL5','AL7','ASH','BRA','GOS','OSN','NRM','HEB','MRY','MRD','MCW','HLD','GRN')
--AND WETUFWLOCATION IS NULL

UPDATE LODWKETX SET WETUFWLITWORKINCODE= NULL 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODRSETX ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN [LOCATION] ON LOCCODE=EECLOCATION
WHERE IRRMSGCODE = 'E0144' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
--AND wetufwsitworkincode in ('azsit','mssit')
-- AND WETUFWCOMPANYCODE = 'LNCMF'
--AND WETUFWLITWORKINCODE = '3912'
--AND EECLOCATION = 'INDANA'
--AND LOCCODE IN ('AL0','AL2','AL4','AL5','AL7','ASH','BRA','GOS','OSN','NRM','HEB','MRY','MRD','MCW','HLD','GRN')
--AND WETUFWLOCATION IS NULL

---------------------------------------------------------ERROR 145------------------------------------------------

--DONE MHB----------------------------------------------ERROR 0145: Work In Location error------------------------------------------------
--Description

SELECT 'E0145: WorkIn LIT Code does not match Location WorkIn LIT Code.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECLOCATION, EECCOMPANYCODE
, eecsitworkinstatecode
, WETUFWFILINGSTATUSLITW AS UFWFILINGSTATUSLITW ,WETUFWLITWORKINCODE AS UFWLITWORKINCODE,WETUFWFILINGSTATUSSITW AS UFWFILINGSTATUSSITW
, WETUFWLOCATION AS UFWLOCATION,WETUFWCOMPANYCODE AS UFWCOMPANYCODE, WETUFWSITWORKINCODE = UFWSITWORKINCODE
, LOCCODE, LocSITWorkInStateCode, LocLITResWorkInCode, LocLITNonResWorkInCode, RETUFWLITRESIDENTCODE
-- select distinct WETUFWFILINGSTATUSLITW,WETUFWLITWORKINCODE,WETUFWFILINGSTATUSSITW,WETUFWLOCATION,WETUFWCOMPANYCODE, WETUFWSITWORKINCODE
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODRSETX ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN [LOCATION] ON LOCCODE=EECLOCATION
WHERE IRRMSGCODE = 'E0145' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
--AND wetufwsitworkincode in ('azsit','mssit')
-- AND WETUFWCOMPANYCODE = 'LNCMF'
--AND WETUFWLITWORKINCODE = '3912'
--AND EECLOCATION = 'INDANA'
--AND LOCCODE IN ('AL0','AL2','AL4','AL5','AL7','ASH','BRA','GOS','OSN','NRM','HEB','MRY','MRD','MCW','HLD','GRN')
--AND WETUFWLOCATION IS NULL
--AND WETUFWLOCATION IN ('WHQ')

-- Sample Updates

UPDATE LODWKETX SET WetUFWLITOCCCode  = LocLITOCCCode
					, WetUFWLITWorkInCode = LocLITNonResWorkinCode 
					, WetUFWLITOtherCode = LocLITOtherCode
					, WetUFWLITWCCCode = LocLITWCCCode
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODRSETX ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN [LOCATION] ON LOCCODE=EECLOCATION
WHERE IRRMSGCODE = 'E0145' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
--AND wetufwsitworkincode in ('azsit','mssit')
-- AND WETUFWCOMPANYCODE = 'LNCMF'
--AND WETUFWLITWORKINCODE = '3912'
--AND EECLOCATION = 'INDANA'
--AND LOCCODE IN ('AL0','AL2','AL4','AL5','AL7','ASH','BRA','GOS','OSN','NRM','HEB','MRY','MRD','MCW','HLD','GRN')
--AND WETUFWLOCATION IS NULL
--AND WETUFWLOCATION IN ('WHQ')

UPDATE LODWKETX SET WETUFWLITOTHERCODE = 'PA114264'
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODRSETX ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN [LOCATION] ON LOCCODE=EECLOCATION
WHERE IRRMSGCODE = 'E0145' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
--AND wetufwsitworkincode in ('azsit','mssit')
-- AND WETUFWCOMPANYCODE = 'LNCMF'
--AND WETUFWLITWORKINCODE = '3912'
--AND EECLOCATION = 'INDANA'
--AND LOCCODE IN ('AL0','AL2','AL4','AL5','AL7','ASH','BRA','GOS','OSN','NRM','HEB','MRY','MRD','MCW','HLD','GRN')
--AND WETUFWLOCATION IS NULL
--AND WETUFWLOCATION IN ('WHQ')

UPDATE LODECOMP SET EECLOCATION = 'CAMBL'
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODRSETX ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LOCATION ON LOCCODE=EECLOCATION
WHERE IRRMSGCODE = 'E0145' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
--AND wetufwsitworkincode in ('azsit','mssit')
-- AND WETUFWCOMPANYCODE = 'LNCMF'
--AND WETUFWLITWORKINCODE = '3912'
--AND EECLOCATION = 'INDANA'
--AND LOCCODE IN ('AL0','AL2','AL4','AL5','AL7','ASH','BRA','GOS','OSN','NRM','HEB','MRY','MRD','MCW','HLD','GRN')
--AND WETUFWLOCATION IS NULL
--AND WETUFWLOCATION IN ('WHQ')

UPDATE LODWKETX SET WETUFWLOCATION = 'CAMBL'
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODRSETX ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LOCATION ON LOCCODE=EECLOCATION
WHERE IRRMSGCODE = 'E0145' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
--AND wetufwsitworkincode in ('azsit','mssit')
-- AND WETUFWCOMPANYCODE = 'LNCMF'
--AND WETUFWLITWORKINCODE = '3912'
--AND EECLOCATION = 'INDANA'
--AND LOCCODE IN ('AL0','AL2','AL4','AL5','AL7','ASH','BRA','GOS','OSN','NRM','HEB','MRY','MRD','MCW','HLD','GRN')
--AND WETUFWLOCATION IS NULL
--AND WETUFWLOCATION IN ('WHQ')

------------------------------------------------ERROR 0147: Work In Location Error..WETUFWLITOTHERCODE, WETPENDINGTRANSTYPELITH--------------------------------------------------
--Description

SELECT 'E0147: Work In Location Error..WETUFWLITOTHERCODE, WETPENDINGTRANSTYPELITH.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
,WETUFWFILINGSTATUSLITW AS UFWFILINGSTATUSLITW ,WETUFWLITWORKINCODE AS UFWLITWORKINCODE,WETUFWFILINGSTATUSSITW AS UFWFILINGSTATUSSITW
,WETUFWLOCATION AS UFWLOCATION,WETUFWCOMPANYCODE AS UFWCOMPANYCODE, WETUFWSITWORKINCODE = UFWSITWORKINCODE, LOCSITWORKINSTATECODE, EECLOCATION, EECCOMPANYCODE, eecsitworkinstatecode
,LOCCODE,LocSITWorkInStateCode,LocLITResWorkInCode,LocLITNonResWorkInCode, loclitNONRESWORKINCODE, RETUFWLITRESIDENTCODE
-- select distinct WETUFWFILINGSTATUSLITW,WETUFWLITWORKINCODE,WETUFWFILINGSTATUSSITW,WETUFWLOCATION,WETUFWCOMPANYCODE, WETUFWSITWORKINCODE
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODRSETX ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LOCATION ON LOCCODE=EECLOCATION
WHERE IRRMSGCODE = 'E0147' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
--AND wetufwsitworkincode in ('azsit','mssit')
-- AND WETUFWCOMPANYCODE = 'LNCMF'
--AND WETUFWLITWORKINCODE = '3912'
--AND EECLOCATION = 'INDANA'
--AND LOCCODE IN ('AL0','AL2','AL4','AL5','AL7','ASH','BRA','GOS','OSN','NRM','HEB','MRY','MRD','MCW','HLD','GRN')
--AND WETUFWLOCATION IS NULL
--AND WETUFWLOCATION IN ('WHQ')

-- Sample Updates

UPDATE LODWKETX SET WETUFWLITOTHERCODE = LOCLITOTHERCODE 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODRSETX ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LOCATION ON LOCCODE=EECLOCATION
WHERE IRRMSGCODE = 'E0147' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
--AND wetufwsitworkincode in ('azsit','mssit')
-- AND WETUFWCOMPANYCODE = 'LNCMF'
--AND WETUFWLITWORKINCODE = '3912'
--AND EECLOCATION = 'INDANA'
--AND LOCCODE IN ('AL0','AL2','AL4','AL5','AL7','ASH','BRA','GOS','OSN','NRM','HEB','MRY','MRD','MCW','HLD','GRN')
--AND WETUFWLOCATION IS NULL
--AND WETUFWLOCATION IN ('WHQ')

UPDATE LODWKETX SET WETPENDINGTRANSTYPELITH = NULL,WETUFWLITOTHERCODE = NULL 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODRSETX ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN [LOCATION] ON LOCCODE=EECLOCATION
WHERE IRRMSGCODE = 'E0147' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
--AND wetufwsitworkincode in ('azsit','mssit')
-- AND WETUFWCOMPANYCODE = 'LNCMF'
--AND WETUFWLITWORKINCODE = '3912'
--AND EECLOCATION = 'INDANA'
--AND LOCCODE IN ('AL0','AL2','AL4','AL5','AL7','ASH','BRA','GOS','OSN','NRM','HEB','MRY','MRD','MCW','HLD','GRN')
--AND WETUFWLOCATION IS NULL
--AND WETUFWLOCATION IN ('WHQ')

-------------------------------------ERROR E0149: UFW SIT Resident Code does not exist but SRC SIT Resident Code does exist-------ON QUIP NOT ON SCRIPT-----------------------------------
--Description 
--The issues is RetSRCSITResidentCode <> RetUFWSITResidentCode in RetUFWSITResidentCode

SELECT 'E0149: UFW SIT Resident Code does not exist but SRC SIT Resident Code does exist.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, RetSRCSITResidentCode, RetUFWSITResidentCode 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODRSETX ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0149' AND IrrSessionID = 'CONV'

-- Sample Updates

update LodRsETx
set RetSRCSITResidentCode = RetUFWSITResidentCode 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODRSETX ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0149' AND IrrSessionID = 'CONV'

---DONE MHB----------------------------------------------ERROR E0157: EDDEEBANKID ERROR-----------------------------------------------------------
--Description

SELECT 'E0157: EDDEEBANKID ERROR.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EddEEBankID AS EEBANKID, ,EDDEEBANKROUTE AS EEBANKROUTE, EDDddOrPrenote AS DDorPrenote, EDDACCT AS ACCT,EDDAMTORPCT AS AMTORPCT,EDDDEPOSITRULE AS DEPOSITRULE,EDDSEQUENCE AS SEQUENCE
-- select distinct EDDEEBANKID, EDDEEBANKROUTE, EDDddOrPrenote, EDDACCT,EDDAMTORPCT,EDDEEBANKROUTE,EDDDEPOSITRULE,EDDSEQUENCE
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDEP ON EDDPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0157' AND IrrSessionID = 'CONV'
AND EDDRECID=IRRRECID
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
--AND EDDPENDINGUPDATEID IN ('NGI000162','XNGC011223','XNGC011622','XNGC002947')

-- Sample Updates

UPDATE LODEDEP SET EDDEEBANKID = NULL 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDEP ON EDDPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0157' AND IrrSessionID = 'CONV'
AND EDDRECID=IRRRECID
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
--AND EDDPENDINGUPDATEID IN ('NGI000162','XNGC011223','XNGC011622','XNGC002947')

--------------------------------------------------ERROR E0172: DATE OF LAST HIRE IS REQUIRED----------------------ON QUIP NOT ON SCRIPT/ NO QUERY / NO SOLUTION------------------------------------
--Description 

SELECT 'E0172: DATE OF LAST HIRE IS REQUIRED.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EecDateOfORiginalHire as DATEOFORIGINALHIRE, EecDateofLastHire as DATEOFLASTHIRE, EecDateOfSeniority as DATEOFSENIORITY, EecDateofBenefitSeniority as DATEOFBENEFITSECURITY
-- select distinct EecDateOfORiginalHire, EecDateofLastHire, EecDateOfSeniority, EecDateofBenefitSeniority
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0172' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EECPENDINGUPDATEID = '5Z9002168'

-- Sample Updates

UPDATE LODECOMP
SET EecDateofLastHire = EecDateOfORiginalHire
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0172' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EECPENDINGUPDATEID = '5Z9002168'

------------------------------------------------ERROR E0173: AMOUNT CANNOT BE NEGATIVE--------------------------------------------------
--DESCRIPTION
--AMOUNT CANNOT BE NEGATIVE
--Review and determine if this deduction should actually be loaded as an earning.

SELECT 'E0173: AMOUNT CANNOT BE NEGATIVE.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECDATEOFLASTHIRE AS DATEOFLASTHIRE, EECDATEOFORIGINALHIRE AS DATEOFORIGINALHIRE, eecdateoftermination AS DATEOFTERMINATION
, EedDedCode as DEDCODE,  EEDEEAMT AS EEAMT, EEDERAMT AS ERAMT,EedStartDate AS STARTDATE
, EedBenStartDate AS BEN STARTDATE 
, eedEEEligDate AS EEELIGDATE, eedbenstatusdate AS BENSTATUSDATE 
, eecdateofbenefitseniority AS dateofbenefitseniority 
, EedBenStatus as BenStatus 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0173' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
and EedBenStatusDate is null
AND EEDDEDCODE IN (SELECT DEDDEDCODE FROM DEDCODE WHERE DEDISBENEFIT = 'Y')
--AND EEDDEDCODE IN ('401K','DRADV','GSULI','FEE')

-- Sample Updates

UPDATE LODEDED SET EEDEEAMT = 0,EEDERAMT = 0 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0173' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
and EedBenStatusDate is null
AND EEDDEDCODE IN (SELECT DEDDEDCODE FROM DEDCODE WHERE DEDISBENEFIT = 'Y')
--AND EEDDEDCODE IN ('401K','DRADV','GSULI','FEE')


----------------------------------------------------ERROR E0176: ERROR IN ADDRESS----------------------------------------------------
--DESCRIPTION

SELECT 'E0176: ERROR IN ADDRESS.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECDATEOFLASTHIRE AS DATEOFLASTHIRE, EECDATEOFORIGINALHIRE AS DATEOFORIGINALHIRE, eecdateoftermination AS DATEOFTERMINATION
, EEPADDRESSZIPCODE AS ZIPCODE,EEPADDRESSCOUNTRY AS ADDRESSCOUNTRY ,EEPADDRESSSTATE AS ADDRESSSTATE
-- select distinct EEPADDRESSZIPCODE,EEPADDRESSCOUNTRY ,EEPADDRESSSTATE
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0176' AND IrrSessionID = 'CONV'
--AND EECEMPLSTATUS <> 'T'
--AND SUBSTRING(EEPADDRESSZIPCODE,6,1)= '-'
--and len(eepaddresszipcode) = 4
--AND EEPADDRESSZIPCODE = '52601]'

-- Sample Updates

UPDATE LODEPERS SET EEPADDRESSZIPCODE = SUBSTRING(EEPADDRESSZIPCODE,1,5)+SUBSTRING(EEPADDRESSZIPCODE,7,4)
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0176' AND IrrSessionID = 'CONV'
--AND EECEMPLSTATUS <> 'T'
AND SUBSTRING(EEPADDRESSZIPCODE,6,1)= '-'
--and len(eepaddresszipcode) = 4
--AND EEPADDRESSZIPCODE = '52601]'


UPDATE LODEPERS SET EEPADDRESSZIPCODE = '0' + SUBSTRING(EEPADDRESSZIPCODE,1,4) 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0176' AND IrrSessionID = 'CONV'
--AND EECEMPLSTATUS <> 'T'
--AND SUBSTRING(EEPADDRESSZIPCODE,6,1)= '-'
and len(eepaddresszipcode) = 4
--AND EEPADDRESSZIPCODE = '52601]'

UPDATE LODEPERS SET EEPADDRESSZIPCODE = '52601' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0176' AND IrrSessionID = 'CONV'
--AND EECEMPLSTATUS <> 'T'
--AND SUBSTRING(EEPADDRESSZIPCODE,6,1)= '-'
--and len(eepaddresszipcode) = 4
AND EEPADDRESSZIPCODE = '52601]'

------------------------------------------------------ERROR E0179: INCORRECT BLOODTYPE----------------------------------------------------
--DESCRIPTION

SELECT 'E0179: INCORRECT BLOODTYPE.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECDATEOFLASTHIRE AS DATEOFLASTHIRE, EECDATEOFORIGINALHIRE AS DATEOFORIGINALHIRE, eecdateoftermination AS DATEOFTERMINATION
, EEPHEALTHBLOODTYPE AS BLOODTYPE
-- select distinct EecPendingUpdateID,EEPHEALTHBLOODTYPE 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0179' AND IrrSessionID = 'CONV'
--AND EECEMPLSTATUS <> 'T'

-- Sample Updates

UPDATE LODEPERS SET EEPHEALTHBLOODTYPE = SUBSTRING(EEPHEALTHBLOODTYPE,1,1) + 'P' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0179' AND IrrSessionID = 'CONV'
--AND EECEMPLSTATUS <> 'T'

-----------------------------------------------------ERROR E0180: INCORRECT I9 DOCUMENT-------------------------------------------------------
--DESCRIPTION


SELECT 'E0180: INCORRECT I9 DOCUMENT.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EEPI9DOCA AS I9DOCA,EEPI9DOCB AS I9DOCB,EEPI9DOCC AS I9DOCC
-- select distinct EecPendingUpdateID,EEPI9DOCA,EEPI9DOCB,EEPI9DOCC
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0180' AND IrrSessionID = 'CONV'
--AND EECEMPLSTATUS <> 'T'

-- Sample Updates

UPDATE LODEPERS SET EEPI9DOCB = '0' + EEPI9DOCB 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0180' AND IrrSessionID = 'CONV'
--AND EECEMPLSTATUS <> 'T'
--AND EEPI9DOCB IS NOT NULL

UPDATE LODEPERS SET EEPI9DOCA = '0' + EEPI9DOCA 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0180' AND IrrSessionID = 'CONV'
--AND EECEMPLSTATUS <> 'T'
--AND EEPI9DOCA IS NOT NULL

UPDATE LODEPERS SET EEPI9DOCC = '0' + EEPI9DOCC 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0180' AND IrrSessionID = 'CONV'
--AND EECEMPLSTATUS <> 'T'
AND EEPI9DOCC IS NOT NULL AND EEPI9DOCC  IN ('1','3')

UPDATE LODEPERS SET EEPI9DOCA = NULL 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0180' AND IrrSessionID = 'CONV'
--AND EECEMPLSTATUS <> 'T'
AND EEPI9DOCA = '00'

---------------------------------------------ERROR E0181: INCORRECT I9DOCB-------------------NO UPDATE STATEMENT PLEASE REVIEW---------------
--DESCRIPTION

SELECT 'E0181: INCORRECT I9DOCB.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EEPI9DOCA AS I9DOCA,EEPI9DOCB AS I9DOCB,EEPI9DOCC AS I9DOCC
-- select distinct EecPendingUpdateID,EEPI9DOCA,EEPI9DOCB,EEPI9DOCC
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0181' AND IrrSessionID = 'CONV'
--AND EECEMPLSTATUS <> 'T'

--------------------------------------------------ERROR E0182: INCCORRECT I9 DOCS---------------------------------------
--DESCRIPTION

SELECT 'E0182: INCORRECT I9 DOCS.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EEPI9DOCA AS I9DOCA,EEPI9DOCB AS I9DOCB,EEPI9DOCC AS I9DOCC
-- select distinct EecPendingUpdateID,EEPI9DOCA,EEPI9DOCB,EEPI9DOCC
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0182' AND IrrSessionID = 'CONV'
--AND EECEMPLSTATUS <> 'T'

-- Sample Updates

SELECT DISTINCT EEPI9DOCC FROM LODEPERS WHERE EEPI9DOCC IS NOT NULL AND EEPI9DOCC <> '10'
UPDATE LODEPERS SET EEPI9DOCB = '0' + EEPI9DOCB
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0182' AND IrrSessionID = 'CONV'
--AND EECEMPLSTATUS <> 'T'
AND EEPI9DOCB IS NOT NULL

UPDATE LODEPERS SET EEPI9DOCA = '0' + EEPI9DOCA
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0182' AND IrrSessionID = 'CONV'
--AND EECEMPLSTATUS <> 'T'
AND (EEPI9DOCA IS NOT NULL AND EEPI9DOCA <> '10')

UPDATE LODEPERS SET EEPI9DOCC = '0' + EEPI9DOCC
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0182' AND IrrSessionID = 'CONV'
--AND EECEMPLSTATUS <> 'T'
AND (EEPI9DOCC IS NOT NULL AND EEPI9DOCC  IN ('1','3'))

---------------------------------------------------ERROR E0183: INCORRECT I9VISATYPE------------------------------------------
--DESCRIPTION

SELECT 'E0183: INCORRECT EEPI9VISATYPE.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EEPI9VISATYPE AS I9VISATYPE
-- select distinct EEPI9VISATYPE
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0183' AND IrrSessionID = 'CONV'
--AND EECEMPLSTATUS <> 'T'

-- Sample Updates

UPDATE LODEPERS SET EEPI9VISATYPE = NULL 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0183' AND IrrSessionID = 'CONV'
--AND EECEMPLSTATUS <> 'T'

----------------------------------------------------ERROR E0184 INCORRECT EEPI9WORKAUTH-------------------------------------------
--DESCRIPTION

SELECT 'E0184: INCORRECT EEPI9WORKAUTH.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EEPI9WORKAUTH AS I9WORKAUTH
-- select distinct EEPI9WORKAUTH
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0184' AND IrrSessionID = 'CONV'
--AND EECEMPLSTATUS <> 'T'

-- Sample Updates

UPDATE LODEPERS SET EEPI9WORKAUTH = NULL
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0184' AND IrrSessionID = 'CONV'
--AND EECEMPLSTATUS <> 'T'

------------------------------------------------------ERROR E0185: INCORRECT EEPMILITARYBRANCHSERVED--------------------------------------------
--DESCRIPTION

SELECT 'E0185: INORRECT EEPMILITARYBRANCHSERVED.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EEPMILITARYBRANCHSERVED AS MILITARYBRANCHSERVED
-- select distinct EEPMILITARYBRANCHSERVED
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0185' AND IrrSessionID = 'CONV'
--AND EECEMPLSTATUS <> 'T'

-- Sample Updates

UPDATE LODEPERS SET EEPMILITARYBRANCHSERVED = NULL 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0185' AND IrrSessionID = 'CONV'
--AND EECEMPLSTATUS <> 'T'
WHERE EEPMILITARYBRANCHSERVED = 'Y'

--------------------------------------------------------ERROR E0186: INCORRECT EEPMILITARYERA-------------------------------------------
--DESCRIPTION

SELECT 'E0186: INORRECT EEPMILITARYERA.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EEPMILITARYERA AS MILITARYERA
-- select distinct EEPMILITARYERA
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0186' AND IrrSessionID = 'CONV'
--AND EECEMPLSTATUS <> 'T'

-- Sample Updates

UPDATE LODEPERS SET EEPMILITARYERA = 'VIET'
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0186' AND IrrSessionID = 'CONV'
--AND EECEMPLSTATUS <> 'T'
AND EEPMILITARYERA = 'VIETNA'


UPDATE LODEPERS SET EEPMILITARYERA = NULL 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0186' AND IrrSessionID = 'CONV'
--AND EECEMPLSTATUS <> 'T'
AND EEPMILITARYERA = 'MIDDLE'

-----------------------ERROR E0193: Benefit start date must be greater than or equal to the eligibility date.--------------------------------------
--Description: 
--May need to update eedBenStartDate to match eligibility date or EECDATEOFBENEFITSENIORITY

SELECT 'E0193: Benefit start date must be greater than or equal to the eligibility date.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECDATEOFLASTHIRE AS DATEOFLASTHIRE, EECDATEOFORIGINALHIRE AS DATEOFORIGINALHIRE, eecdateoftermination AS DATEOFTERMINATION
, EedDedCode as DEDCODE,  EEDEEAMT AS EEAMT, EEDERAMT AS ERAMT,EedStartDate AS STARTDATE
, EedBenStartDate AS BEN STARTDATE 
, eedEEEligDate AS EEELIGDATE, eedbenstatusdate AS BENSTATUSDATE, eedDEDEFFSTARTDATE as DEDEFFSTARTDATE
, eecdateofbenefitseniority AS dateofbenefitseniority 
, EedBenStatus as BenStatus 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODCNTRL ON CNTPENDINGUPDATEID=IRRPENDINGUPDATEID
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0193' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
and EedBenStatusDate is null
AND EEDDEDCODE IN (SELECT DEDDEDCODE FROM DEDCODE WHERE DEDISBENEFIT = 'Y')
--AND EEDDEDCODE IN ('401K','DRADV','GSULI','FEE')
and eedDEDISBENEFIT = 'Y'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
--AND CNTSESSIONID = 'FCBOE'

-- Sample Updates

UPDATE DEDCODE SET DEDDEDEFFSTARTDATE = '01/01/1957'
FROM IMPERRS
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODCNTRL ON CNTPENDINGUPDATEID=IRRPENDINGUPDATEID
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0193' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
and EedBenStatusDate is null
AND EEDDEDCODE IN (SELECT DEDDEDCODE FROM DEDCODE WHERE DEDISBENEFIT = 'Y')
--AND EEDDEDCODE IN ('401K','DRADV','GSULI','FEE')
and eedDEDISBENEFIT = 'Y'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
--AND CNTSESSIONID = 'FCBOE'

UPDATE LODEDED SET /*EEDBENSTARTDATE = EECDATEOFBENEFITSENIORITY,*/EEDEEELIGDATE = EECDATEOFBENEFITSENIORITY
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODCNTRL ON CNTPENDINGUPDATEID=IRRPENDINGUPDATEID
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0193' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
and EedBenStatusDate is null
AND EEDDEDCODE IN (SELECT DEDDEDCODE FROM DEDCODE WHERE DEDISBENEFIT = 'Y')
--AND EEDDEDCODE IN ('401K','DRADV','GSULI','FEE')
and eedDEDISBENEFIT = 'Y'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
--AND CNTSESSIONID = 'FCBOE'

UPDATE LODEDED SET /*EEDBENSTARTDATE = EECDATEOFBENEFITSENIORITY,*/EEDBENSTARTDATE = EECDATEOFBENEFITSENIORITY
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODCNTRL ON CNTPENDINGUPDATEID=IRRPENDINGUPDATEID
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0193' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
and EedBenStatusDate is null
AND EEDDEDCODE IN (SELECT DEDDEDCODE FROM DEDCODE WHERE DEDISBENEFIT = 'Y')
--AND EEDDEDCODE IN ('401K','DRADV','GSULI','FEE')
and eedDEDISBENEFIT = 'Y'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
--AND CNTSESSIONID = 'FCBOE'

---------------------------ERROR 0194: Benefit start date must be greater than or equal to the benefit seniority date.-----------------------------------------
--Description: 
--The benefit start date must the same as the benefit seniority date or the dateoflasthire needs to be greater than benefitstartdate

SELECT 'E0194: Benefit start date must be greater than or equal to the benefit seniority date.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECDATEOFLASTHIRE AS DATEOFLASTHIRE, EECDATEOFORIGINALHIRE AS DATEOFORIGINALHIRE
, EedDedCode as DEDCODE, EedStartDate AS STARTDATE
, EedBenStartDate AS BENSTARTDATE 
--, eedEEEligDate AS EEELIGDATE --, eedbenstatusdate AS BENSTATUSDATE, eedDEDEFFSTARTDATE as DEDEFFSTARTDATE
, eecdateofbenefitseniority AS dateofbenefitseniority 
, EedBenStatus as BenStatus 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODCNTRL ON CNTPENDINGUPDATEID=IRRPENDINGUPDATEID
join dedcode on eeddedcode = deddedcode and dedisbenefit = 'Y'
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0194' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
--and EedBenStatusDate is null
--AND EEDDEDCODE IN (SELECT DEDDEDCODE FROM DEDCODE WHERE DEDISBENEFIT = 'Y')
--AND EEDDEDCODE IN ('401K','DRADV','GSULI','FEE')
--and eedDEDISBENEFIT = 'Y'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
--AND CNTSESSIONID = 'FCBOE'
--and eecdateoforiginalhire <> eecdateoflasthire
--AND EEDSTOPDATE IS NOT NULL

-- Sample Updates

update lodeded set eedbenstartdate = eecdateoflasthire, eedeeeligdate = eecdateoflasthire
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODCNTRL ON CNTPENDINGUPDATEID=IRRPENDINGUPDATEID
join dedcode on eeddedcode = deddedcode and dedisbenefit = 'Y'
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0194' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
--and EedBenStatusDate is null
--AND EEDDEDCODE IN (SELECT DEDDEDCODE FROM DEDCODE WHERE DEDISBENEFIT = 'Y')
--AND EEDDEDCODE IN ('401K','DRADV','GSULI','FEE')
--and eedDEDISBENEFIT = 'Y'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
--AND CNTSESSIONID = 'FCBOE'
--and eecdateoforiginalhire <> eecdateoflasthire
--AND EEDSTOPDATE IS NOT NULL
--AND EECSESSIONID = 'CONV'

--UPDATE LODEDED SET EEDBENSTARTDATE = EECDATEOFlastHIRE,EEDEEELIGDATE=EECDATEOFlastHIRE,EEDBENSTATUSDATE = EECDATEOFlastHIRE 
update lodeded set eedbenstartdate = eecdateoflasthire, eedeeeligdate = eecdateoflasthire
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODCNTRL ON CNTPENDINGUPDATEID=IRRPENDINGUPDATEID
join dedcode on eeddedcode = deddedcode where dedisbenefit = 'Y'
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0194' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
and EedBenStatusDate is null
AND EEDDEDCODE IN (SELECT DEDDEDCODE FROM DEDCODE WHERE DEDISBENEFIT = 'Y')
--AND EEDDEDCODE IN ('401K','DRADV','GSULI','FEE')
and eedDEDISBENEFIT = 'Y'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
--AND CNTSESSIONID = 'FCBOE'
--and eecdateoforiginalhire <> eecdateoflasthire
--AND EEDSTOPDATE IS NOT NULL
--AND EECSESSIONID = 'CONV'

DELETE LODEDED 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODCNTRL ON CNTPENDINGUPDATEID=IRRPENDINGUPDATEID
join dedcode on eeddedcode = deddedcode where dedisbenefit = 'Y'
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0194' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
and EedBenStatusDate is null
AND EEDDEDCODE IN (SELECT DEDDEDCODE FROM DEDCODE WHERE DEDISBENEFIT = 'Y')
--AND EEDDEDCODE IN ('401K','DRADV','GSULI','FEE')
and eedDEDISBENEFIT = 'Y'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
--AND CNTSESSIONID = 'FCBOE'
--and eecdateoforiginalhire <> eecdateoflasthire
--AND EEDSTOPDATE IS NOT NULL
--AND EECSESSIONID = 'CONV'

updATE LODECOMP SET EECDATEOFBENEFITSENIORITY=EEDBENSTARTDATE 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODCNTRL ON CNTPENDINGUPDATEID=IRRPENDINGUPDATEID
join dedcode on eeddedcode = deddedcode where dedisbenefit = 'Y'
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0194' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
and EedBenStatusDate is null
AND EEDDEDCODE IN (SELECT DEDDEDCODE FROM DEDCODE WHERE DEDISBENEFIT = 'Y')
--AND EEDDEDCODE IN ('401K','DRADV','GSULI','FEE')
and eedDEDISBENEFIT = 'Y'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
--AND CNTSESSIONID = 'FCBOE'
--and eecdateoforiginalhire <> eecdateoflasthire
--AND EEDSTOPDATE IS NOT NULL
--AND EECSESSIONID = 'CONV'


---DONE MB -------------------------------------------------ERROR 0195: Benefit start date must be greater than or equal to the company level effective date for the benefit-----------------------------------------------------
--Description
--In the Bo deduction setup (deduction plans), the effective date is set after the benefit is supposed to start.

SELECT 'E0195: Benefit start date must be greater than or equal to the company level effective date for the benefit.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECDATEOFLASTHIRE AS DATEOFLASTHIRE, EECDATEOFORIGINALHIRE AS DATEOFORIGINALHIRE, eecdateoftermination AS DATEOFTERMINATION
, EedDedCode as DEDCODE,  EEDEEAMT AS EEAMT, EEDERAMT AS ERAMT,EedStartDate AS STARTDATE
, EedBenStartDate AS BENSTARTDATE 
, eedEEEligDate AS EEELIGDATE, eedbenstatusdate AS BENSTATUSDATE, dedDEDEFFSTARTDATE as DEDEFFSTARTDATE
, eecdateofbenefitseniority AS dateofbenefitseniority 
, EedBenStatus as BenStatus 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODCNTRL ON CNTPENDINGUPDATEID=IRRPENDINGUPDATEID
join dedcode on eeddedcode = deddedcode and dedisbenefit = 'Y'
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0195' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
and EedBenStatusDate is null
AND EEDDEDCODE IN (SELECT DEDDEDCODE FROM DEDCODE WHERE DEDISBENEFIT = 'Y')
--AND EEDDEDCODE IN ('401K','DRADV','GSULI','FEE')
and eedDEDISBENEFIT = 'Y'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
--AND CNTSESSIONID = 'FCBOE'
--and eecdateoforiginalhire <> eecdateoflasthire
--AND EEDSTOPDATE IS NOT NULL
--AND EECSESSIONID = 'CONV'
--and DEDDEDCODE in ('HLIFE','HSTD','SLTD')

-- Sample Updates

UPDATE LODEDED SET EEDBENSTARTDATE = '1/1/1990',EEDBENSTATUSDATE = '1/1/1990',EEDEEELIGDATE = '1/1/1990',EEDSTARTDATE = '1/1/1990' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODCNTRL ON CNTPENDINGUPDATEID=IRRPENDINGUPDATEID
join dedcode on eeddedcode = deddedcode where dedisbenefit = 'Y'
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0195' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
and EedBenStatusDate is null
AND EEDDEDCODE IN (SELECT DEDDEDCODE FROM DEDCODE and DEDISBENEFIT = 'Y')
--AND EEDDEDCODE IN ('401K','DRADV','GSULI','FEE')
and eedDEDISBENEFIT = 'Y'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
--AND CNTSESSIONID = 'FCBOE'
--and eecdateoforiginalhire <> eecdateoflasthire
--AND EEDSTOPDATE IS NOT NULL
--AND EECSESSIONID = 'CONV'
--and DEDDEDCODE in ('HLIFE','HSTD','SLTD')

------------------------------------------------------ERROR 0196: Benefit stop date must be greater or equal to the benefit coverage start date---------------------------------------------------------
--Description

SELECT 'E0196: Benefit stop date must be greater or equal to the benefit coverage start date'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECDATEOFLASTHIRE AS DATEOFLASTHIRE, EECDATEOFORIGINALHIRE AS DATEOFORIGINALHIRE, eecdateoftermination AS DATEOFTERMINATION
, EedDedCode as DEDCODE,  EEDEEAMT AS EEAMT, EEDERAMT AS ERAMT,EedStartDate AS STARTDATE
, EedBenStartDate AS BEN STARTDATE 
, eedEEEligDate AS EEELIGDATE, eedbenstatusdate AS BENSTATUSDATE, eedDEDEFFSTARTDATE as DEDEFFSTARTDATE
, eecdateofbenefitseniority AS dateofbenefitseniority 
, EedBenStatus as BenStatus 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODCNTRL ON CNTPENDINGUPDATEID=IRRPENDINGUPDATEID
join dedcode on eeddedcode = deddedcode where dedisbenefit = 'Y'
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0196' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
and EedBenStatusDate is null
AND EEDDEDCODE IN (SELECT DEDDEDCODE FROM DEDCODE WHERE DEDISBENEFIT = 'Y')
--AND EEDDEDCODE IN ('401K','DRADV','GSULI','FEE')
and eedDEDISBENEFIT = 'Y'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
--AND CNTSESSIONID = 'FCBOE'
--and eecdateoforiginalhire <> eecdateoflasthire
--AND EEDSTOPDATE IS NOT NULL
--AND EECSESSIONID = 'CONV'
--and DEDDEDCODE in ('HLIFE','HSTD','SLTD')

-- Sample Updates

UPDATE LODEDED SET EEDBENSTOPDATE = '7/30/2004' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODCNTRL ON CNTPENDINGUPDATEID=IRRPENDINGUPDATEID
join dedcode on eeddedcode = deddedcode where dedisbenefit = 'Y'
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0196' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
and EedBenStatusDate is null
AND EEDDEDCODE IN (SELECT DEDDEDCODE FROM DEDCODE WHERE DEDISBENEFIT = 'Y')
--AND EEDDEDCODE IN ('401K','DRADV','GSULI','FEE')
and eedDEDISBENEFIT = 'Y'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
--AND CNTSESSIONID = 'FCBOE'
--and eecdateoforiginalhire <> eecdateoflasthire
--AND EEDSTOPDATE IS NOT NULL
--AND EECSESSIONID = 'CONV'
--and DEDDEDCODE in ('HLIFE','HSTD','SLTD')

---------------------------------------------------------ERROR E0198: Benefit Start Date must be blank for deductions. ---------------------------------------------------
--Description

SELECT 'E0198: Benefit Start Date must be blank for deductions'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECDATEOFLASTHIRE AS DATEOFLASTHIRE, EECDATEOFORIGINALHIRE AS DATEOFORIGINALHIRE, eecdateoftermination AS DATEOFTERMINATION
, EedDedCode as DEDCODE,  EEDEEAMT AS EEAMT, EEDERAMT AS ERAMT,EedStartDate AS STARTDATE
, EedBenStartDate AS BEN STARTDATE 
, eedEEEligDate AS EEELIGDATE, eedbenstatusdate AS BENSTATUSDATE, eedDEDEFFSTARTDATE as DEDEFFSTARTDATE
, eecdateofbenefitseniority AS dateofbenefitseniority 
, EedBenStatus as BenStatus 

FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODCNTRL ON CNTPENDINGUPDATEID=IRRPENDINGUPDATEID
join dedcode on eeddedcode = deddedcode where dedisbenefit = 'Y'
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0198' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
and EedBenStatusDate is null
AND EEDDEDCODE IN (SELECT DEDDEDCODE FROM DEDCODE WHERE DEDISBENEFIT = 'Y')
--AND EEDDEDCODE IN ('401K','DRADV','GSULI','FEE')
and eedDEDISBENEFIT = 'Y'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
--AND CNTSESSIONID = 'FCBOE'
--and eecdateoforiginalhire <> eecdateoflasthire
--AND EEDSTOPDATE IS NOT NULL
--AND EECSESSIONID = 'CONV'
--and DEDDEDCODE in ('HLIFE','HSTD','SLTD')


UPDATE LODEDED SET EEDBENSTARTDATE = NULL, EEDEEELIGDATE = NULL, EEDBENSTATUSDATE = NULL,EEDBENSTATUS = NULL 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODCNTRL ON CNTPENDINGUPDATEID=IRRPENDINGUPDATEID
join dedcode on eeddedcode = deddedcode where dedisbenefit = 'Y'
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0198' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
and EedBenStatusDate is null
AND EEDDEDCODE IN (SELECT DEDDEDCODE FROM DEDCODE WHERE DEDISBENEFIT = 'Y')
--AND EEDDEDCODE IN ('401K','DRADV','GSULI','FEE')
and eedDEDISBENEFIT = 'Y'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
--AND CNTSESSIONID = 'FCBOE'
--and eecdateoforiginalhire <> eecdateoflasthire
--AND EEDSTOPDATE IS NOT NULL
--AND EECSESSIONID = 'CONV'
--and DEDDEDCODE in ('HLIFE','HSTD','SLTD')

---------------------------------ERROR E0199: Benefit eligibility date must be greater than or equal to the benefit seniority date-------------------------------------------------------
--Description
--Might be an issue with the date of last hire

SELECT 'E0199: Benefit eligibility date must be greater than or equal to the benefit seniority date'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECDATEOFLASTHIRE AS DATEOFLASTHIRE, EECDATEOFORIGINALHIRE AS DATEOFORIGINALHIRE, eecdateoftermination AS DATEOFTERMINATION
, EedDedCode as DEDCODE,  EEDEEAMT AS EEAMT, EEDERAMT AS ERAMT,EedStartDate AS STARTDATE
, EedBenStartDate AS BEN STARTDATE 
, eedEEEligDate AS EEELIGDATE, eedbenstatusdate AS BENSTATUSDATE, eedDEDEFFSTARTDATE as DEDEFFSTARTDATE
, eecdateofbenefitseniority AS dateofbenefitseniority 
, EedBenStatus as BenStatus 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODCNTRL ON CNTPENDINGUPDATEID=IRRPENDINGUPDATEID
join dedcode on eeddedcode = deddedcode where dedisbenefit = 'Y'
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0199' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
and EedBenStatusDate is null
AND EEDDEDCODE IN (SELECT DEDDEDCODE FROM DEDCODE WHERE DEDISBENEFIT = 'Y')
--AND EEDDEDCODE IN ('401K','DRADV','GSULI','FEE')
and eedDEDISBENEFIT = 'Y'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
--AND CNTSESSIONID = 'FCBOE'
--and eecdateoforiginalhire <> eecdateoflasthire
--AND EEDSTOPDATE IS NOT NULL
--AND EECSESSIONID = 'CONV'
--and DEDDEDCODE in ('HLIFE','HSTD','SLTD')

-- Sample Updates
UPDATE LODEDED SET EEDBENSTARTDATE = EECDATEOFlastHIRE,EEDEEELIGDATE=EECDATEOFlastHIRE,EEDBENSTATUSDATE = EECDATEOFlastHIRE 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODCNTRL ON CNTPENDINGUPDATEID=IRRPENDINGUPDATEID
join dedcode on eeddedcode = deddedcode where dedisbenefit = 'Y'
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0199' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
and EedBenStatusDate is null
AND EEDDEDCODE IN (SELECT DEDDEDCODE FROM DEDCODE WHERE DEDISBENEFIT = 'Y')
--AND EEDDEDCODE IN ('401K','DRADV','GSULI','FEE')
and eedDEDISBENEFIT = 'Y'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
--AND CNTSESSIONID = 'FCBOE'
--and eecdateoforiginalhire <> eecdateoflasthire
--AND EEDSTOPDATE IS NOT NULL
--AND EECSESSIONID = 'CONV'
--and DEDDEDCODE in ('HLIFE','HSTD','SLTD')

update lodEded set eedeeeligdate = eecdateofbenefitseniority, eedstartdate = eecdateofbenefitseniority
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODCNTRL ON CNTPENDINGUPDATEID=IRRPENDINGUPDATEID
join dedcode on eeddedcode = deddedcode where dedisbenefit = 'Y'
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0199' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
and EedBenStatusDate is null
AND EEDDEDCODE IN (SELECT DEDDEDCODE FROM DEDCODE WHERE DEDISBENEFIT = 'Y')
--AND EEDDEDCODE IN ('401K','DRADV','GSULI','FEE')
and eedDEDISBENEFIT = 'Y'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
--AND CNTSESSIONID = 'FCBOE'
--and eecdateoforiginalhire <> eecdateoflasthire
--AND EEDSTOPDATE IS NOT NULL
--AND EECSESSIONID = 'CONV'
--and DEDDEDCODE in ('HLIFE','HSTD','SLTD')

---BELOW SOURCED FROM QUIP FOR E0199

-----------------------------------------------------ERROR E0200: Benefit eligibility date must be blank for deductions.------------------------------------------------------
--Description

SELECT 'E0200: Benefit eligibility date must be blank for deductions'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECDATEOFLASTHIRE AS DATEOFLASTHIRE, EECDATEOFORIGINALHIRE AS DATEOFORIGINALHIRE, eecdateoftermination AS DATEOFTERMINATION
, EedDedCode as DEDCODE,  EEDEEAMT AS EEAMT, EEDERAMT AS ERAMT,EedStartDate AS STARTDATE
, EedBenStartDate AS BEN STARTDATE 
, eedEEEligDate AS EEELIGDATE, eedbenstatusdate AS BENSTATUSDATE, eedDEDEFFSTARTDATE as DEDEFFSTARTDATE
, eecdateofbenefitseniority AS dateofbenefitseniority 
, EedBenStatus as BenStatus 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODCNTRL ON CNTPENDINGUPDATEID=IRRPENDINGUPDATEID
join dedcode on eeddedcode = deddedcode where dedisbenefit = 'Y'
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0200' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
and EedBenStatusDate is null
AND EEDDEDCODE IN (SELECT DEDDEDCODE FROM DEDCODE WHERE DEDISBENEFIT = 'Y')
--AND EEDDEDCODE IN ('401K','DRADV','GSULI','FEE')
and eedDEDISBENEFIT = 'Y'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
--AND CNTSESSIONID = 'FCBOE'
--and eecdateoforiginalhire <> eecdateoflasthire
--AND EEDSTOPDATE IS NOT NULL
--AND EECSESSIONID = 'CONV'
--and DEDDEDCODE in ('HLIFE','HSTD','SLTD')

-- Sample Updates

UPDATE LODEDED SET EEDEEELIGDATE = NULL,EEDBENSTARTDATE = NULL 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODCNTRL ON CNTPENDINGUPDATEID=IRRPENDINGUPDATEID
join dedcode on eeddedcode = deddedcode where dedisbenefit = 'Y'
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0200' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
and EedBenStatusDate is null
AND EEDDEDCODE IN (SELECT DEDDEDCODE FROM DEDCODE WHERE DEDISBENEFIT = 'Y')
--AND EEDDEDCODE IN ('401K','DRADV','GSULI','FEE')
and eedDEDISBENEFIT = 'Y'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
--AND CNTSESSIONID = 'FCBOE'
--and eecdateoforiginalhire <> eecdateoflasthire
--AND EEDSTOPDATE IS NOT NULL
--AND EECSESSIONID = 'CONV'
--and DEDDEDCODE in ('HLIFE','HSTD','SLTD')


----------------------------------ERROR E0201: Employee goal amount must be less than or equal to company level goal amount---------------------------------------------------
--Description

SELECT 'E0201: Employee goal amount must be less than or equal to company level goal amount'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECDATEOFLASTHIRE AS DATEOFLASTHIRE, EECDATEOFORIGINALHIRE AS DATEOFORIGINALHIRE, eecdateoftermination AS DATEOFTERMINATION
, EedDedCode as DEDCODE,  EEDEEAMT AS EEAMT, EEDERAMT AS ERAMT,EEDEEGOALAMT AS EEGOALAMT, EedStartDate AS STARTDATE
, EedBenStartDate AS BENSTARTDATE 
, eedEEEligDate AS EEELIGDATE, eedbenstatusdate AS BENSTATUSDATE --eedDEDEFFSTARTDATE as DEDEFFSTARTDATE
, eecdateofbenefitseniority AS dateofbenefitseniority 
, EedBenStatus as BenStatus 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODCNTRL ON CNTPENDINGUPDATEID=IRRPENDINGUPDATEID
join dedcode on eeddedcode = deddedcode AND dedisbenefit = 'Y'
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0201' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
--and EedBenStatusDate is null
--AND EEDDEDCODE IN (SELECT DEDDEDCODE FROM DEDCODE WHERE DEDISBENEFIT = 'Y')
--AND EEDDEDCODE IN ('401K','DRADV','GSULI','FEE')
--and eedDEDISBENEFIT = 'Y'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
--AND CNTSESSIONID = 'FCBOE'
--and eecdateoforiginalhire <> eecdateoflasthire
--AND EEDSTOPDATE IS NOT NULL
--AND EECSESSIONID = 'CONV'
--and DEDDEDCODE in ('HSA01','HSA05','HSA09')

-- Sample Updates

UPDATE LODEDED SET EEDEEGOALAMT = 19000.00 -- EEDEEGOALAMT =NULL 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODCNTRL ON CNTPENDINGUPDATEID=IRRPENDINGUPDATEID
join dedcode on eeddedcode = deddedcode AND dedisbenefit = 'Y'
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0201' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
--and EedBenStatusDate is null
--AND EEDDEDCODE IN (SELECT DEDDEDCODE FROM DEDCODE WHERE DEDISBENEFIT = 'Y')
--AND EEDDEDCODE IN ('401K','DRADV','GSULI','FEE')
--and eedDEDISBENEFIT = 'Y'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
--AND CNTSESSIONID = 'FCBOE'
--and eecdateoforiginalhire <> eecdateoflasthire
--AND EEDSTOPDATE IS NOT NULL
--AND EECSESSIONID = 'CONV'
--and DEDDEDCODE in ('HLIFE','HSTD','SLTD')

----------------------ERROR E0202: Deduction start date must be greater than or equal to the company level effective date for the deduction---------------------------------------------------
--Description

SELECT 'E0202: Deduction start date must be greater than or equal to the company level effective date for the deduction'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECDATEOFLASTHIRE AS DATEOFLASTHIRE, EECDATEOFORIGINALHIRE AS DATEOFORIGINALHIRE, eecdateoftermination AS DATEOFTERMINATION
, EedDedCode as DEDCODE,  EEDEEAMT AS EEAMT, EEDERAMT AS ERAMT,EEDEEGOALAMT AS EEGOALAMT, EedStartDate AS STARTDATE
, EedBenStartDate AS BEN STARTDATE 
, eedEEEligDate AS EEELIGDATE, eedbenstatusdate AS BENSTATUSDATE, eedDEDEFFSTARTDATE as DEDEFFSTARTDATE
, eecdateofbenefitseniority AS dateofbenefitseniority 
, EedBenStatus as BenStatus 
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODCNTRL ON CNTPENDINGUPDATEID=IRRPENDINGUPDATEID
join dedcode on eeddedcode = deddedcode and dedisbenefit = 'Y'
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0202' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
and EedBenStatusDate is null
AND EEDDEDCODE IN (SELECT DEDDEDCODE FROM DEDCODE WHERE DEDISBENEFIT = 'Y')
--AND EEDDEDCODE IN ('401K','DRADV','GSULI','FEE')
and eedDEDISBENEFIT = 'Y'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
--AND CNTSESSIONID = 'FCBOE'
--and eecdateoforiginalhire <> eecdateoflasthire
--AND EEDSTOPDATE IS NOT NULL
--AND EECSESSIONID = 'CONV'
--and DEDDEDCODE in ('HLIFE','HSTD','SLTD')

-- Sample Updates

UPDATE LODEDED SET EEDSTARTDATE = '01/01/1960' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODCNTRL ON CNTPENDINGUPDATEID=IRRPENDINGUPDATEID
join dedcode on eeddedcode = deddedcode and dedisbenefit = 'Y'
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0202' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
and EedBenStatusDate is null
AND EEDDEDCODE IN (SELECT DEDDEDCODE FROM DEDCODE WHERE DEDISBENEFIT = 'Y')
--AND EEDDEDCODE IN ('401K','DRADV','GSULI','FEE')
and eedDEDISBENEFIT = 'Y'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
--AND CNTSESSIONID = 'FCBOE'
--and eecdateoforiginalhire <> eecdateoflasthire
--AND EEDSTOPDATE IS NOT NULL
--AND EECSESSIONID = 'CONV'
--and DEDDEDCODE in ('HLIFE','HSTD','SLTD')

UPDATE DEDCODE SET DEDDEDEFFSTARTDATE = '01/01/1960' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODCNTRL ON CNTPENDINGUPDATEID=IRRPENDINGUPDATEID
join dedcode on eeddedcode = deddedcode and dedisbenefit = 'Y'
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0202' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
--and EedBenStatusDate is null
--AND EEDDEDCODE IN ('401K','DRADV','GSULI','FEE')
--and eedDEDISBENEFIT = 'Y'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
--AND CNTSESSIONID = 'FCBOE'
--and eecdateoforiginalhire <> eecdateoflasthire
--AND EEDSTOPDATE IS NOT NULL
--AND EECSESSIONID = 'CONV'
--and DEDDEDCODE in ('HLIFE','HSTD','SLTD')

UPDATE LODEDED SET EEDSTARTDATE = EECDATEOFLASTHIRE 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODCNTRL ON CNTPENDINGUPDATEID=IRRPENDINGUPDATEID
join dedcode on eeddedcode = deddedcode where dedisbenefit = 'Y'
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0202' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
--and EedBenStatusDate is null
----AND EEDDEDCODE IN ('401K','DRADV','GSULI','FEE')
--and eedDEDISBENEFIT = 'Y'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
--AND CNTSESSIONID = 'FCBOE'
--and eecdateoforiginalhire <> eecdateoflasthire
--AND EEDSTOPDATE IS NOT NULL
--AND EECSESSIONID = 'CONV'
--and DEDDEDCODE in ('HLIFE','HSTD','SLTD')

----------------------------------------------------ERROR E0203: INVALID BENSTATUSDATE---------------------------------------------------
--Description

SELECT 'E0203: INVALID BENSTATUSDATE'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECDATEOFLASTHIRE AS DATEOFLASTHIRE, EECDATEOFORIGINALHIRE AS DATEOFORIGINALHIRE, eecdateoftermination AS DATEOFTERMINATION
, EedDedCode as DEDCODE,  EEDEEAMT AS EEAMT, EEDERAMT AS ERAMT,EEDEEGOALAMT AS EEGOALAMT, EedStartDate AS STARTDATE
, EedBenStartDate AS BEN STARTDATE 
, eedEEEligDate AS EEELIGDATE, eedbenstatusdate AS BENSTATUSDATE, eedDEDEFFSTARTDATE as DEDEFFSTARTDATE
, eecdateofbenefitseniority AS dateofbenefitseniority 
, EedBenStatus as BenStatus 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODCNTRL ON CNTPENDINGUPDATEID=IRRPENDINGUPDATEID
join dedcode on eeddedcode = deddedcode and dedisbenefit = 'Y'
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0203' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
--and EedBenStatusDate is null
----AND EEDDEDCODE IN ('401K','DRADV','GSULI','FEE')
--and eedDEDISBENEFIT = 'Y'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
--AND CNTSESSIONID = 'FCBOE'
--and eecdateoforiginalhire <> eecdateoflasthire
--AND EEDSTOPDATE IS NOT NULL
--AND EECSESSIONID = 'CONV'
--and DEDDEDCODE in ('HLIFE','HSTD','SLTD')

-- Sample Updates

UPDATE LODEDED SET EEDbenstatusDATE = NULL 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODCNTRL ON CNTPENDINGUPDATEID=IRRPENDINGUPDATEID
join dedcode on eeddedcode = deddedcode where dedisbenefit = 'Y'
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0203' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
--and EedBenStatusDate is null
----AND EEDDEDCODE IN ('401K','DRADV','GSULI','FEE')
--and eedDEDISBENEFIT = 'Y'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
--AND CNTSESSIONID = 'FCBOE'
--and eecdateoforiginalhire <> eecdateoflasthire
--AND EEDSTOPDATE IS NOT NULL
--AND EECSESSIONID = 'CONV'
--and DEDDEDCODE in ('HLIFE','HSTD','SLTD')

----------------------------------------------------ERROR E0206: NOT SURE OF ERROR------------------
--Description
--NOT SURE OF ERROR  NO UPDATE PLEASE REVIEW

SELECT 'E0206: error?'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0206' AND IrrSessionID = 'CONV'
 AND IRRTABLENAME = 'LODECOMP'

-- Sample Updates
-- none yet

----------------------------------------------------ERROR EO207: Invalid LOA reason code---------------------------------------------------
--Description

SELECT 'E0207: Invalid LOA reason code'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECLEAVEREASON AS LEAVEREASON
-- select distinct EECLEAVEREASON
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0207' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
----AND EEDPENDINGUPDATEID = 'RSUI000007184'
--AND EECLEAVEREASON IN ('PI','NHA','NC')

-- Sample Update

UPDATE LODECOMP SET EECLEAVEREASON = '112' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0207' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
----AND EEDPENDINGUPDATEID = 'RSUI000007184'
--AND EECLEAVEREASON IN ('PI','NHA','NC')

----------------------------------ERROR E0209: ERROR DATEOFNEXTSALARYREVIEW/ DATEOFNEXTSALARYREVIEW---------------------------------------------------
--Description

SELECT 'E0209: INVALID DATEOFNEXTSALARYREVIEW/ DATEOFNEXTSALARYREVIEW'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECDATEOFLASTSALREVIEW AS DATEOFLASTSALREVIEW,EECDATEOFNEXTSALREVIEW AS DATEOFNEXTSALREVIEW,EECDATEOFLASTPERFREVIEW AS DATEOFLASTPERFREVIEW,EECDATEOFNEXTPERFREVIEW AS DATEOFNEXTPERFREVIEW
,EECDATEOFLASTHIRE AS DATEOFLASTHIRE
-- select distinct  EecPendingUpdateID, EECDATEOFLASTSALREVIEW,EECDATEOFNEXTSALREVIEW,EECDATEOFLASTPERFREVIEW,EECDATEOFNEXTPERFREVIEW,EECDATEOFLASTHIRE
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0209' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'

-- Sample Updates

update lodecomp set eecdateoflastsalreview = '04/16/2007',eecdateofnextsalreview = '04/16/2008',
eecdateoflastperfreview = '04/16/2007',eecdateofnextperfreview = '04/16/2008'
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0209' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
AND eecempno = '000051388'

UPDATE LODECOMP SET EECDATEOFNEXTSALREVIEW = DATEADD(YY,1,EECDATEOFLASTSALREVIEW),
 EECDATEOFNEXTPERFREVIEW = DATEADD(YY,1,EECDATEOFLASTPERFREVIEW)
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0209' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'

----------------------------------------------------ERROR E0210: PERF AND SAL REVIEW ---------------------------------------------------
--Description

SELECT 'E0210: PERF AND SAL REVIEW'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECDATEOFLASTSALREVIEW AS DATEOFLASTSALREVIEW,EECDATEOFNEXTSALREVIEW AS DATEOFNEXTSALREVIEW,EECDATEOFLASTPERFREVIEW AS DATEOFLASTPERFREVIEW,EECDATEOFNEXTPERFREVIEW AS DATEOFNEXTPERFREVIEW
,EECDATEOFLASTHIRE AS DATEOFLASTHIRE, EECDATEOFORIGINALHIRE AS ORIGINALHIRE, EECEMPLSTATUSSTARTDATE AS EESTATUSSTARTDATE,EECDATEOFSENIORITY AS DATEOFSENIORITY, 
,EECDATEOFBENEFITSENIORITY AS BENEFITSENIORITY
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0210' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'

-- Sample Updates

update lodecomp set EECDATEOFNEXTPERFREVIEW = null 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0210' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EECDATEOFNEXTPERFREVIEW = '01/01/1930'

UPDATE LODECOMP SET EECDATEOFNEXTPERFREVIEW = NULL
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0210' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'

UPDATE lodeCOMP SET EECDATEOFNEXTPERFREVIEW = '12/31/2006',eecdateofnextsalreview = '12/31/2006' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0210' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'

UPDATE lodeCOMP SET EECDATEOFORIGINALHIRE = '1/1/1990',EECDATEOFLASTHIRE = '1/1/1990',EECDATEOFBENEFITSENIORITY
= '1/1/1990',EECEMPLSTATUSSTARTDATE= '1/1/1990' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0210' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'

---------------------------------------------------ERROR E0211: EMPLOYEE STATUS START DATE------------------------------------------------------
--Description

SELECT 'E0211: EMPLOYEE STATUS START DATE'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status,eecdateofTERMINATION AS TERMINATIONDATE,EECTERMREASON AS TERMREASON
,EECTERMTYPE AS TERMTYPE,EECEMPLSTATUSSTARTDATE AS STATUSSTARTDATE
,EECDATEOFLASTHIRE AS DATEOFLASTHIRE, EECDATEOFORIGINALHIRE AS ORIGINALHIRE
-- select distinct  EecPendingUpdateID, EECDATEOFLASTHIRE, EECDATEOFORIGINALHIRE
,EECEMPLSTATUSSTARTDATE
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN EMPCOMP ON EECEMPNO = LODECOMP.EECEMPNO
WHERE IRRMSGCODE = 'E0211' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'

-- Sample Updates

UPDATE LODECOMP SET EECEMPLSTATUSSTARTDATE = '04/19/1996' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN EMPCOMP ON EECEMPNO = LODECOMP.EECEMPNO
WHERE IRRMSGCODE = 'E0211' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'

update empcomp set eecdateoflasthire=empcomp.eecdateoforiginalhire
,eecdateinjob = empcomp.eecdateoforiginalhire
,eecdateofseniority = empcomp.eecdateoforiginalhire
,eecdateofbenefitseniority = empcomp.eecdateoforiginalhire 
,eecemplstatusstartdate = empcomp.eecdateoforiginalhire
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN EMPCOMP ON EECEMPNO = LODECOMP.EECEMPNO
WHERE IRRMSGCODE = 'E0211' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'


----------------------------------------------ERROR 0212: Leave reason is required---------------on quip not on script------------------------------
--Description:

SELECT 'ERROR 0212: Leave reason is required'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status,eecdateofTERMINATION AS TERMINATIONDATE,EECTERMREASON AS TERMREASON
, EecLeaveReason='Z'
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN EMPCOMP ON EECEMPNO = LODECOMP.EECEMPNO
WHERE IRRMSGCODE = 'E0212' AND IrrSessionID = 'CONV'
  and EecEmplStatus='L'
--and irrtableNAME = 'LODECOMP'

-- Sample Updates

Update lodecomp  set EecLeaveReason='Z'   
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN EMPCOMP ON EECEMPNO = LODECOMP.EECEMPNO
WHERE IRRMSGCODE = 'E0212' AND IrrSessionID = 'CONV'
  and EecEmplStatus='L' 


Update lodecomp  set EecPlannedLeaveReason='Z'  
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN EMPCOMP ON EECEMPNO = LODECOMP.EECEMPNO
WHERE IRRMSGCODE = 'E0212' AND IrrSessionID = 'CONV'
  and EecEmplStatus='L'

----------------------------------------------ERROR E0218: Date of termination can not be less than the date of last hire--------------------------------------------------
--Description

SELECT 'E0218: Date of termination can not be less than the date of last hire'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECDATEOFLASTHIRE AS DATEOFLASTHIRE, EECDATEOFORIGINALHIRE AS DATEOFORIGINALHIRE, eecdateoftermination AS DATEOFTERMINATION
, EECTERMREASON AS TERMREASON,EECTERMTYPE AS TERMTYPE
-- select distinct EECTERMREASON,EECTERMTYPE,eecdateoftermination
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0218' AND IrrSessionID = 'CONV'
AND EEPRECID = IRRRECID
--and irrtableNAME = 'LODECOMP'
--AND EECEMPNO = '009482'
--AND EECCOID = '1LSEX'

-- Sample Updates

--If they have been terminated, you can change to termination date to date of last hire +1 and note in the issues and assumptions.
update lodecomp set eecdateoftermination = DATEADD(DD,1,EECDATEOFLASTHIRE) 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0218' AND IrrSessionID = 'CONV'
AND EEPRECID = IRRRECID
--and irrtableNAME = 'LODECOMP'
--AND EECEMPNO = '009482'
--AND EECCOID = '1LSEX'

UPDATE LODECOMP SET EECDATEOFTERMINATION = NULL 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0218' AND IrrSessionID = 'CONV'
AND EEPRECID = IRRRECID
--and irrtableNAME = 'LODECOMP'
--AND EECEMPNO = '009482'
--AND EECCOID = '1LSEX'


UPDATE LODECOMP SET EECEMPLSTATUSSTARTDATE = '05/17/1999' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0218' AND IrrSessionID = 'CONV'
AND EEPRECID = IRRRECID
--and irrtableNAME = 'LODECOMP'
--AND EECEMPNO = '009482'
--AND EECCOID = '1LSEX'

----------------------------------------------------ERROR E0219: INVALID EETERMTYPE---------------------------------------------------
--Description

SELECT 'E0219: INVALID EETERMTYPE'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECDATEOFLASTHIRE AS DATEOFLASTHIRE, EECDATEOFORIGINALHIRE AS DATEOFORIGINALHIRE, eecdateoftermination AS DATEOFTERMINATION
, EECTERMREASON AS TERMREASON,EECTERMTYPE AS TERMTYPE
-- select distinct EECTERMREASON,EECTERMTYPE,eecdateoftermination
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0219' AND IrrSessionID = 'CONV'
AND EEPRECID = IRRRECID
--and irrtableNAME = 'LODECOMP'

-- Sample Updates

UPDATE LODECOMP SET EECTERMTYPE = 'V' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0219' AND IrrSessionID = 'CONV'
AND EEPRECID = IRRRECID
--and irrtableNAME = 'LODECOMP'

----------------------------------------------------ERROR E0220: Invalid termination reason---------------------------------------------------
--Description

SELECT 'E0220: Invalid termination reason'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECDATEOFLASTHIRE AS DATEOFLASTHIRE, EECDATEOFORIGINALHIRE AS DATEOFORIGINALHIRE, eecdateoftermination AS DATEOFTERMINATION
, EECTERMREASON AS TERMREASON,EECTERMTYPE AS TERMTYPE
-- select distinct EECTERMREASON,EECTERMTYPE,eecdateoftermination
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0220' AND IrrSessionID = 'CONV'
AND EEPRECID = IRRRECID
--and irrtableNAME = 'LODECOMP'
--AND EECEMPNO = '009482'
--AND EECCOID = '1LSEX'
--AND EECTERMREASON = 'FPOORA'

-- Sample Updates

UPDATE LODECOMP SET EECTERMREASON = 'FPOOR',EECTERMTYPE = 'I' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0220' AND IrrSessionID = 'CONV'
AND EEPRECID = IRRRECID
--and irrtableNAME = 'LODECOMP'
--AND EECEMPNO = '009482'
--AND EECCOID = '1LSEX'
--AND EECTERMREASON = 'FPOORA'

----------------------------------------------------ERROR E0221: An inactive job code cannot be assigned---------------------------------------------------
--Description

SELECT 'E0221: inactive job code cannot be assigned'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECJOBCODE AS JOBCODE 
-- select distinct jobcode
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODCNTRL ON CNTPENDINGUPDATEID=IRRPENDINGUPDATEID
join dedcode on eeddedcode = deddedcode and dedisbenefit = 'Y'
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0221' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'

-- You will need to temporarily change the JobCode setup table to 
-- set all the jobcodes to active so you can then load employees.
-- Part 1 of the following routine will set to active.  
-- Important!  
-- After loading employees you need to return the previously inactive
-- jobcodes to inactive.  Part two of this routine will return in 
-- inactive.

--UPDATE JOBCODE SET JBCSTATUS = 'A' WHERE JBCSTATUS = 'I'

-- Part 1
drop table ace_inactivejob

select jbcjobcde into dbo.ace_inactivejob 
from jobcode 
where jbcstatus='I' 

update jobcode set jbcstatus ='A' 

-- Part 2
update jobcode set jbcstatus='I' 
where jbcjobcode in (select jbcjobcode from dbo.ace_inactivejob )

----------------------------------------------------ERROR E0226: INVALID SHIFTGROUP---------------------------------------------------
--Description

SELECT 'E0226: INVALID SHIFTGROUP'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status,EECSHIFTGROUP AS SHIFTGROUP
-- select distinct  EECSHIFTGROUP
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN EMPCOMP ON EECEMPNO = LODECOMP.EECEMPNO
WHERE IRRMSGCODE = 'E0226' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'

-- Sample Updates

UPDATE LODECOMP SET EECSHIFTGROUP = 'Z' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN EMPCOMP ON EECEMPNO = LODECOMP.EECEMPNO
WHERE IRRMSGCODE = 'E0226' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'

----------------------------------------------------ERROR E0227: INVALID PHONE NUMBER ---------------------------------------------------
--Description

SELECT 'E0227: INVALID PHONE NUMBER'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status,EEPPHONEHOMENUMBER AS PHONEHOMENUMBER
,EECPHONEBUSINESSNUMBER AS PHONEBUSINESSNUMBER
-- select distinct  EEPPHONEHOMENUMBER, EECPHONEBUSINESSNUMBER
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0227' AND IrrSessionID = 'CONV'

-- Sample Updates

UPDATE LODECOMP SET EECPHONEBUSINESSNUMBER = NULL 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0227' AND IrrSessionID = 'CONV'
and irrtableNAME = 'LODECOMP'
--AND EECPHONEBUSINESSNUMBER < '1'

UPDATE LODEPERS SET EEPPHONEHOMENUMBER = NULL
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0227' AND IrrSessionID = 'CONV'
and irrtableNAME = 'LODEPERS'

UPDATE LODEPERS SET EEPPHONEHOMENUMBER = 2165411605
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0227' AND IrrSessionID = 'CONV'
and irrtableNAME = 'LODEPERS'
--AND EEPPENDINGUPDATEID = 'PGV0006655'

------------------------------------------------ERROR E0232: INVALID EDDAMTORPCT---------------------------------------------------
--Description
--INVALID EDDAMTORPCT

SELECT 'E0232: INVALID EDDAMTORPCT'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status,EddAcct AS ACCT,EDDAMTORPCT AS AMTORPCT,EDDSEQUENCE AS SEQUENCE
,edddepositrule AS DEPOSITRULE 
-- select distinct EDDPENDINGUPDATEID,EddAcct,EDDAMTORPCT,EDDSEQUENCE,edddepositrule 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDEP ON EDDPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0232' AND IrrSessionID = 'CONV'
--AND IRRRECID=EDDRECID
-- and eddsequence = '99'

-- Sample Updates

update lodedep set eddamtorpct = 0 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDEP ON EDDPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0232' AND IrrSessionID = 'CONV'
--AND IRRRECID=EDDRECID
-- and eddsequence = '99'

----------------------------------------------------ERROR E0233: Date of last hire cannot be less than date of original hire---------------------------------------------------
--Description

SELECT 'E0233: Date of last hire cannot be less than date of original hire'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECDATEOFLASTHIRE AS DATEOFLASTHIRE, EECDATEOFORIGINALHIRE AS DATEOFORIGINALHIRE, eecdateoftermination AS DATEOFTERMINATION
-- select distinct ECDATEOFLASTHIRE,EECDATEOFORIGINALHIRE
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0233' AND IrrSessionID = 'CONV'
AND EEPRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'

-- Sample Updates

UPDATE LODECOMP SET EECDATEOFORIGINALHIRE = EECDATEOFLASTHIRE 
--UPDATE LODECOMP SET EECDATEOFLASTHIRE = EECDATEOFORIGINALHIRE
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0233' AND IrrSessionID = 'CONV'
AND EEPRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'

UPDATE LODECOMP SET EECDATEOFORIGINALHIRE = '6/7/2000' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0233' AND IrrSessionID = 'CONV'
AND EEPRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'

----------------------------------------------------ERROR E0246: iNVALID Benefit options---------------------------------------------------
--Description
--Issue:

 
--* Medical codes usually have benefits options.. what level of coverage do they get




--Solution:

 
--* Probably a mapping issue. They need lodeded.EedBenOption

--* Looking at the deduction  plans setup in BO, then rates tab. Look to see if they are setup. Look --for amounts that are same as the ones that are missing EedEEAmt



SELECT 'E0246: INVALID Benefit options'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECDATEOFLASTHIRE AS DATEOFLASTHIRE, EECDATEOFORIGINALHIRE AS DATEOFORIGINALHIRE, eecdateoftermination AS DATEOFTERMINATION
, EedDedCode as DEDCODE,  EEDBENOPTION as BENOPTION, EEDEEAMT AS EEAMT, EEDERAMT AS ERAMT,EEDEEGOALAMT AS EEGOALAMT, EedStartDate AS STARTDATE
, EedBenStartDate AS BEN STARTDATE 
, eedEEEligDate AS EEELIGDATE, eedbenstatusdate AS BENSTATUSDATE, eedDEDEFFSTARTDATE as DEDEFFSTARTDATE
, eecdateofbenefitseniority AS dateofbenefitseniority 
, EedBenStatus as BenStatus 
-- select distinct EedDedCode, EedBenOption
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
join dedcode on eeddedcode = deddedcode and dedisbenefit = 'Y'
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0246' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECEMPLSTATUS <> 'T'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'
--AND EEDSTOPDATE IS NOT NULL
--AND EECSESSIONID = 'CONV'
--and DEDDEDCODE in ('HLIFE','HSTD','SLTD')

-- Sample Updates

Update LodEDed set EedBenOption='EE'
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
join dedcode on eeddedcode = deddedcode and dedisbenefit = 'Y'
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0246' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--and EedDedCode='VIS' 
--and EedEEAmt=3.70 
--and EedBenOption is null

----------------------------------------------------ERROR E0247: EEDEECALCRATEORPCT, EEDEECALCRULE, EEDEEAMT ---------------------------------------------------
--Description
--INVALID Benefit options

SELECT 'E0247: EEDEECALCRATEORPCT, EEDEECALCRULE, EEDEEAMT'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECDATEOFLASTHIRE AS DATEOFLASTHIRE, EECDATEOFORIGINALHIRE AS DATEOFORIGINALHIRE, eecdateoftermination AS DATEOFTERMINATION
, EedDedCode as DEDCODE,  EEDEEAMT AS EEAMT, EEDEECALCRATEORPCT AS EECALCRATEORPCT
-- select distinct EedDedCode, EEDEECALCRATEORPCT,  EEDEEAMT
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
join dedcode on eeddedcode = deddedcode
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0247' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECEMPLSTATUS <> 'T'
--AND EEDDEDCODE IN (SELECT DEDDEDCODE FROM DEDCODE WHERE DEDISBENEFIT = 'Y')
--and eedDEDISBENEFIT = 'Y'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'
--AND EEDSTOPDATE IS NOT NULL
--AND EECSESSIONID = 'CONV'
--and DEDDEDCODE in ('HLIFE','HSTD','SLTD')
-- AND EEDDEDCODE IN ('651','661')
--AND EEDDEDCODE IN (SELECT DEDDEDCODE FROM DEDCODE WHERE DEDEECALCRULE <> '20')
--AND EEDEEAMT <> 0

-- Sample Updates

UPDATE LODEDED SET EEDEECALCRATEORPCT = EEDEEAMT/100,EEDEEAMT = 0 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
join dedcode on eeddedcode = deddedcode
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0247' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECEMPLSTATUS <> 'T'
--AND EEDDEDCODE IN (SELECT DEDDEDCODE FROM DEDCODE WHERE DEDISBENEFIT = 'Y')
--and eedDEDISBENEFIT = 'Y'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'
--AND EEDSTOPDATE IS NOT NULL
--AND EECSESSIONID = 'CONV'
--and DEDDEDCODE in ('HLIFE','HSTD','SLTD')
--AND EEDDEDCODE IN ('651','661')
--AND EEDDEDCODE IN (SELECT DEDDEDCODE FROM DEDCODE WHERE DEDEECALCRULE <> '20')
--AND EEDEEAMT <> 0

UPDATE LODEDED SET EEDEEAMT = 0 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
join dedcode on eeddedcode = deddedcode
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0247' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECEMPLSTATUS <> 'T'
--AND EEDDEDCODE IN (SELECT DEDDEDCODE FROM DEDCODE WHERE DEDISBENEFIT = 'Y')
--and eedDEDISBENEFIT = 'Y'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'
--AND EEDSTOPDATE IS NOT NULL
--AND EECSESSIONID = 'CONV'
--and DEDDEDCODE in ('HLIFE','HSTD','SLTD')
--AND EEDDEDCODE IN ('651','661')
--AND EEDDEDCODE IN (SELECT DEDDEDCODE FROM DEDCODE WHERE DEDEECALCRULE <> '20')
--AND EEDEEAMT <> 0

UPDATE LODEDED SET EEDEECALCRULE = '20' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
join dedcode on eeddedcode = deddedcode
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0247' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECEMPLSTATUS <> 'T'
--AND EEDDEDCODE IN (SELECT DEDDEDCODE FROM DEDCODE WHERE DEDISBENEFIT = 'Y')
--and eedDEDISBENEFIT = 'Y'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'
--AND EEDSTOPDATE IS NOT NULL
--AND EECSESSIONID = 'CONV'
--and DEDDEDCODE in ('HLIFE','HSTD','SLTD')
--AND EEDDEDCODE IN ('651','661')
--AND EEDDEDCODE IN (SELECT DEDDEDCODE FROM DEDCODE WHERE DEDEECALCRULE <> '20')
--AND EEDEEAMT <> 0


-----------------------------------------------ERROR E0248: EEDEECALCRATEORPCT, EEDEECALCRULE---------------------------------------------------
--Description
--INVALID Benefit options

SELECT 'E0248: EEDEECALCRATEORPCT, EEDEECALCRULE'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECDATEOFLASTHIRE AS DATEOFLASTHIRE, EECDATEOFORIGINALHIRE AS DATEOFORIGINALHIRE, eecdateoftermination AS DATEOFTERMINATION
, EedDedCode as DEDCODE,  EEDEEAMT AS EEAMT, EEDEECALCRATEORPCT AS EECALCRATEORPCT,  EEDEECALCRULE AS EECALCRULE
-- select distinct EedDedCode, EEDEECALCRATEORPCT,  EEDEEAMT,  EEDEECALCRULE
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
join dedcode on eeddedcode = deddedcode
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0248' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECEMPLSTATUS <> 'T'
--AND EEDDEDCODE IN (SELECT DEDDEDCODE FROM DEDCODE WHERE DEDISBENEFIT = 'Y')
--and eedDEDISBENEFIT = 'Y'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'
--AND EEDSTOPDATE IS NOT NULL
--AND EECSESSIONID = 'CONV'
--and DEDDEDCODE in ('HLIFE','HSTD','SLTD')
-- AND EEDDEDCODE IN ('651','661')
--AND EEDDEDCODE IN (SELECT DEDDEDCODE FROM DEDCODE WHERE DEDEECALCRULE <> '20')
--AND EEDEEAMT <> 0
-- AND  EEDDEDCODE = 'CHRTY'

-- Sample Updates

UPDATE LODEDED SET EEDEECALCRATEORPCT = 0 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
join dedcode on eeddedcode = deddedcode
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0248' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECEMPLSTATUS <> 'T'
--AND EEDDEDCODE IN (SELECT DEDDEDCODE FROM DEDCODE WHERE DEDISBENEFIT = 'Y')
--and eedDEDISBENEFIT = 'Y'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'
--AND EEDSTOPDATE IS NOT NULL
--AND EECSESSIONID = 'CONV'
--and DEDDEDCODE in ('HLIFE','HSTD','SLTD')
-- AND EEDDEDCODE IN ('651','661')
--AND EEDDEDCODE IN (SELECT DEDDEDCODE FROM DEDCODE WHERE DEDEECALCRULE <> '20')
--AND EEDEEAMT <> 0
-- AND  EEDDEDCODE = 'CHRTY'

UPDATE LODEDED SET EEDEECALCRULE = '60' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
join dedcode on eeddedcode = deddedcode
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0248' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECEMPLSTATUS <> 'T'
--AND EEDDEDCODE IN (SELECT DEDDEDCODE FROM DEDCODE WHERE DEDISBENEFIT = 'Y')
--and eedDEDISBENEFIT = 'Y'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'
--AND EEDSTOPDATE IS NOT NULL
--AND EECSESSIONID = 'CONV'
--and DEDDEDCODE in ('HLIFE','HSTD','SLTD')
-- AND EEDDEDCODE IN ('651','661')
--AND EEDDEDCODE IN (SELECT DEDDEDCODE FROM DEDCODE WHERE DEDEECALCRULE <> '20')
--AND EEDEEAMT <> 0
-- AND  EEDDEDCODE = 'CHRTY'

----------------------------------------------------ERROR E0250: EEDERCALCRULE---------------------------------------------------
--Description

SELECT 'E0250: EEDErCALCRULE'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECDATEOFLASTHIRE AS DATEOFLASTHIRE, EECDATEOFORIGINALHIRE AS DATEOFORIGINALHIRE, eecdateoftermination AS DATEOFTERMINATION
, EedDedCode as DEDCODE,  EEDEEAMT AS EEAMT, EEDErCALCRATEORPCT AS ErCALCRATEORPCT,  EEDErCALCRULE AS EECALCRULE
-- select distinct EEDDEDCODE,EEDErCALCRATEORPCT,EEDERCALCRULE
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
join dedcode on eeddedcode = deddedcode
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0250' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECEMPLSTATUS <> 'T'
--AND EEDDEDCODE IN (SELECT DEDDEDCODE FROM DEDCODE WHERE DEDISBENEFIT = 'Y')
--and eedDEDISBENEFIT = 'Y'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'
--AND EEDSTOPDATE IS NOT NULL
--AND EECSESSIONID = 'CONV'
--and DEDDEDCODE in ('HLIFE','HSTD','SLTD')
-- AND EEDDEDCODE IN ('651','661')
--AND EEDDEDCODE IN (SELECT DEDDEDCODE FROM DEDCODE WHERE DEDEECALCRULE <> '20')
--AND EEDEEAMT <> 0
-- AND  EEDDEDCODE = 'CHRTY'

-- Sample Updates

UPDATE LODEDED SET EEDERCALCRULE = NULL,EEDERCALCRATEORPCT = 0 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
join dedcode on eeddedcode = deddedcode
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0250' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECEMPLSTATUS <> 'T'
--AND EEDDEDCODE IN (SELECT DEDDEDCODE FROM DEDCODE WHERE DEDISBENEFIT = 'Y')
--and eedDEDISBENEFIT = 'Y'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'
--AND EEDSTOPDATE IS NOT NULL
--AND EECSESSIONID = 'CONV'
--and DEDDEDCODE in ('HLIFE','HSTD','SLTD')
-- AND EEDDEDCODE IN ('651','661')
--AND EEDDEDCODE IN (SELECT DEDDEDCODE FROM DEDCODE WHERE DEDEECALCRULE <> '20')
--AND EEDEEAMT <> 0
-- AND  EEDDEDCODE = 'CHRTY'

--------------------ERROR EO253: LIT WorkIn Code must match the location resident or nonresident workin code, when using locations for taxes.------------------------------------------------------------------------------
--Description

SELECT 'E0253: LIT WorkIn Code must match the location resident or nonresident workin code, when using locations for taxes.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
,WETUFWFILINGSTATUSLITW AS UFWFILINGSTATUSLITW ,WETUFWLITWORKINCODE AS UFWLITWORKINCODE,WETUFWFILINGSTATUSSITW AS UFWFILINGSTATUSSITW
,WETUFWLOCATION AS UFWLOCATION,WETUFWCOMPANYCODE AS UFWCOMPANYCODE, WETUFWSITWORKINCODE = UFWSITWORKINCODE, LOCSITWORKINSTATECODE, EECLOCATION, EECCOMPANYCODE, eecsitworkinstatecode
,LOCCODE,LocSITWorkInStateCode,LocLITResWorkInCode,LocLITNonResWorkInCode, loclitNONRESWORKINCODE, RETUFWLITRESIDENTCODE
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODRSETX ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN [LOCATION] ON LOCCODE=EECLOCATION
WHERE IRRMSGCODE = 'E0253' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
--AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
--AND wetufwsitworkincode in ('azsit','mssit')
-- AND WETUFWCOMPANYCODE = 'LNCMF'
--AND WETUFWLITWORKINCODE = '3912'
--AND EECLOCATION = 'INDANA'
--AND LOCCODE IN ('AL0','AL2','AL4','AL5','AL7','ASH','BRA','GOS','OSN','NRM','HEB','MRY','MRD','MCW','HLD','GRN')
--AND WETUFWLOCATION IS NULL
--AND LOCCODE=WETUFWLOCATION

-- Sample Updates

UPDATE LODWKETX SET WETUFWLITWORKINCODE = 'NY001',WETUFWLITOCCCODE = NULL
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODRSETX ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN [LOCATION] ON LOCCODE=EECLOCATION
WHERE IRRMSGCODE = 'E0253' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
--AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
--AND wetufwsitworkincode in ('azsit','mssit')
-- AND WETUFWCOMPANYCODE = 'LNCMF'
--AND WETUFWLITWORKINCODE = '3912'
--AND EECLOCATION = 'INDANA'
--AND LOCCODE IN ('AL0','AL2','AL4','AL5','AL7','ASH','BRA','GOS','OSN','NRM','HEB','MRY','MRD','MCW','HLD','GRN')
--AND WETUFWLOCATION IS NULL
--AND LOCCODE=WETUFWLOCATION


UPDATE LODWKETX SET WETUFWLOCATION = 'NY0000'
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODRSETX ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LOCATION ON LOCCODE=EECLOCATION
WHERE IRRMSGCODE = 'E0253' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
--AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
--AND wetufwsitworkincode in ('azsit','mssit')
-- AND WETUFWCOMPANYCODE = 'LNCMF'
--AND WETUFWLITWORKINCODE = '3912'
--AND EECLOCATION = 'INDANA'
--AND LOCCODE IN ('AL0','AL2','AL4','AL5','AL7','ASH','BRA','GOS','OSN','NRM','HEB','MRY','MRD','MCW','HLD','GRN')
--AND WETUFWLOCATION IS NULL
--AND LOCCODE=WETUFWLOCATION

UPDATE LODWKETX SET WETUFWLITWORKINCODE = 'ORWCEE',WETPENDINGTRANSTYPELITW = 'A',WETUFWFILINGSTATUSLITW = WETUFWFILINGSTATUSSITW
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODRSETX ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LOCATION ON LOCCODE=EECLOCATION
WHERE IRRMSGCODE = 'E0253' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
--AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
--AND wetufwsitworkincode in ('azsit','mssit')
-- AND WETUFWCOMPANYCODE = 'LNCMF'
--AND WETUFWLITWORKINCODE = '3912'
--AND EECLOCATION = 'INDANA'
--AND LOCCODE IN ('AL0','AL2','AL4','AL5','AL7','ASH','BRA','GOS','OSN','NRM','HEB','MRY','MRD','MCW','HLD','GRN')
--AND WETUFWLOCATION IS NULL
--AND LOCCODE=WETUFWLOCATION


UPDATE LODWKETX SET WETUFWLITWORKINCODE = NULL,WETPENDINGTRANSTYPELITW = ' '
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODRSETX ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN [LOCATION] ON LOCCODE=EECLOCATION
WHERE IRRMSGCODE = 'E0253' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
--AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
--AND wetufwsitworkincode in ('azsit','mssit')
-- AND WETUFWCOMPANYCODE = 'LNCMF'
--AND WETUFWLITWORKINCODE = '3912'
--AND EECLOCATION = 'INDANA'
--AND LOCCODE IN ('AL0','AL2','AL4','AL5','AL7','ASH','BRA','GOS','OSN','NRM','HEB','MRY','MRD','MCW','HLD','GRN')
--AND WETUFWLOCATION IS NULL
--AND LOCCODE=WETUFWLOCATION

UPDATE LOCATION SET LocLITWorkInCounty = NULL 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODRSETX ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN [LOCATION] ON LOCCODE=EECLOCATION
WHERE IRRMSGCODE = 'E0253' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
--AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
--AND wetufwsitworkincode in ('azsit','mssit')
-- AND WETUFWCOMPANYCODE = 'LNCMF'
--AND WETUFWLITWORKINCODE = '3912'
--AND EECLOCATION = 'INDANA'
--AND LOCCODE IN ('AL0','AL2','AL4','AL5','AL7','ASH','BRA','GOS','OSN','NRM','HEB','MRY','MRD','MCW','HLD','GRN')
--AND WETUFWLOCATION IS NULL
--AND LOCCODE=WETUFWLOCATION

--------------------ERROR EO257: Shift group cannot be set when shifts are not in use.------------------------------------------------------------------------------
--Description
	--If you have a client using position management 
	--then position management has to be turned off otherwise 
	--the new hire import will not work.

SELECT 'E0257: Shift group cannot be set when shifts are not in use.'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0257' AND IrrSessionID = 'CONV'


-----------------------------------------------------------ERROR E0260: Employee Goal Amount cannot be filled in if the goal amount rule is “NONE”-----------------------------------------------------
--Description:

SELECT 'E0260: Employee Goal Amount cannot be filled in if the goal amount rule is “NONE”'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECDATEOFLASTHIRE AS DATEOFLASTHIRE, EECDATEOFORIGINALHIRE AS DATEOFORIGINALHIRE, eecdateoftermination AS DATEOFTERMINATION
, EedDedCode as DEDCODE,  EEDBENOPTION as BENOPTION, EEDEEAMT AS EEAMT, EEDERAMT AS ERAMT,EEDEEGOALAMT AS EEGOALAMT, EedStartDate AS STARTDATE
, EedBenStartDate AS BENSTARTDATE 
, eedEEEligDate AS EEELIGDATE, eedbenstatusdate AS BENSTATUSDATE, eedDEDEFFSTARTDATE as DEDEFFSTARTDATE
, eecdateofbenefitseniority AS dateofbenefitseniority 
, EedBenStatus as BenStatus 
-- select distinct EedDedCode, Eedeegoalamt, --MAX(EEDEEGOALAMT)
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0260' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECEMPLSTATUS <> 'T'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'
--AND EEDSTOPDATE IS NOT NULL
--AND EECSESSIONID = 'CONV'
--AND EEDDEDCODE IN ('401KL','FNVEH','LIAB','UWAYD','VANLS')

-- Sample Updates

update lodeded set eedeegtdamt = 0 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0260' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECEMPLSTATUS <> 'T'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'
--AND EEDSTOPDATE IS NOT NULL
--AND EECSESSIONID = 'CONV'
--AND EEDDEDCODE IN ('401KL','FNVEH','LIAB','UWAYD','VANLS')

update lodeded set eedeegtdamt = NULL 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0260' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECEMPLSTATUS <> 'T'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'
--AND EEDSTOPDATE IS NOT NULL
--AND EECSESSIONID = 'CONV'
--AND EEDDEDCODE IN ('401KL','FNVEH','LIAB','UWAYD','VANLS')


-----------------------------------------------------ERROR E0261: Invalid location code for this tax location----------------------------------------------------------------
--Description: Invalid location code for this tax location
--The employees' location isn't setup for the company.


SELECT 'E0261: Invalid location code for this tax location'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
,WETUFWFILINGSTATUSLITW AS UFWFILINGSTATUSLITW ,WETUFWLITWORKINCODE AS UFWLITWORKINCODE,WETUFWFILINGSTATUSSITW AS UFWFILINGSTATUSSITW
,WETUFWLOCATION AS UFWLOCATION,WETUFWCOMPANYCODE AS UFWCOMPANYCODE, WETUFWSITWORKINCODE = UFWSITWORKINCODE, LOCSITWORKINSTATECODE, EECLOCATION, EECCOMPANYCODE, eecsitworkinstatecode
,LOCCODE,LocSITWorkInStateCode,LocLITResWorkInCode,LocLITNonResWorkInCode, loclitNONRESWORKINCODE, RETUFWLITRESIDENTCODE
-- select distinct WETUFWFILINGSTATUSLITW,WETUFWLITWORKINCODE,WETUFWFILINGSTATUSSITW,WETUFWLOCATION,WETUFWCOMPANYCODE, WETUFWSITWORKINCODE
, LOCSITWORKINSTATECODE, EECLOCATION, EECCOMPANYCODE, eecsitworkinstatecode,LOCCODE,LocSITWorkInStateCode,LocLITResWorkInCode,LocLITNonResWorkInCode
, loclitNONRESWORKINCODE, RETUFWLITRESIDENTCODE
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODRSETX ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODCNTRL ON CntPendingUpdateID=IRRPENDINGUPDATEID
JOIN COMPANY ON CmpCompanyCode = EepCompanyCode
JOIN [LOCATION] ON LOCCODE=EECLOCATION
WHERE IRRMSGCODE = 'E0261' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
--AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
--AND wetufwsitworkincode in ('azsit','mssit')
-- AND WETUFWCOMPANYCODE = 'LNCMF'
--AND WETUFWLITWORKINCODE = '3912'
--AND EECLOCATION = 'INDANA'
--AND LOCCODE IN ('AL0','AL2','AL4','AL5','AL7','ASH','BRA','GOS','OSN','NRM','HEB','MRY','MRD','MCW','HLD','GRN')
--AND WETUFWLOCATION IS NULL
--AND LOCCODE=WETUFWLOCATION
--AND (CntCoID <> CmpCoID OR CntCoID IS NULL)
--AND RETPENDINGUPDATEID IN ('237685483CM880S','240805214CM880S')

UPDATE LODEEMST SET EEMUFWCOMPANYCODE = 'CAS'
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODRSETX ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODCNTRL ON CntPendingUpdateID=IRRPENDINGUPDATEID
JOIN COMPANY ON CmpCompanyCode = EepCompanyCode
JOIN [LOCATION] ON LOCCODE=EECLOCATION
WHERE IRRMSGCODE = 'E0261' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
--AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
--AND wetufwsitworkincode in ('azsit','mssit')
-- AND WETUFWCOMPANYCODE = 'LNCMF'
--AND WETUFWLITWORKINCODE = '3912'
--AND EECLOCATION = 'INDANA'
--AND LOCCODE IN ('AL0','AL2','AL4','AL5','AL7','ASH','BRA','GOS','OSN','NRM','HEB','MRY','MRD','MCW','HLD','GRN')
--AND WETUFWLOCATION IS NULL
--AND LOCCODE=WETUFWLOCATION
--AND (CntCoID <> CmpCoID OR CntCoID IS NULL)
--AND RETPENDINGUPDATEID IN ('237685483CM880S','240805214CM880S')

UPDATE LODWKETX SET WETUFWCOMPANYCODE = 'WHO'  
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODRSETX ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODCNTRL ON CntPendingUpdateID=IRRPENDINGUPDATEID
JOIN COMPANY ON CmpCompanyCode = EepCompanyCode
JOIN [LOCATION] ON LOCCODE=EECLOCATION
WHERE IRRMSGCODE = 'E0261' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
--AND wetufwsitworkincode in ('azsit','mssit')
-- AND WETUFWCOMPANYCODE = 'LNCMF'
--AND WETUFWLITWORKINCODE = '3912'
--AND EECLOCATION = 'INDANA'
--AND LOCCODE IN ('AL0','AL2','AL4','AL5','AL7','ASH','BRA','GOS','OSN','NRM','HEB','MRY','MRD','MCW','HLD','GRN')
--AND WETUFWLOCATION IS NULL
--AND LOCCODE=WETUFWLOCATION
AND (CntCoID <> CmpCoID OR CntCoID IS NULL)
--AND RETPENDINGUPDATEID IN ('237685483CM880S','240805214CM880S')
--AND EEPPENDINGUPDATEID IN ('237685483CM880S','240805214CM880S')
--AND EEMPENDINGUPDATEID IN ('237685483CM880S','240805214CM880S')


UPDATE LODECOMP SET EECCOMPANYCODE = 'WHO' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODRSETX ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODCNTRL ON CntPendingUpdateID=IRRPENDINGUPDATEID
JOIN COMPANY ON CmpCompanyCode = EepCompanyCode
JOIN [LOCATION] ON LOCCODE=EECLOCATION
WHERE IRRMSGCODE = 'E0261' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
--AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
--AND wetufwsitworkincode in ('azsit','mssit')
-- AND WETUFWCOMPANYCODE = 'LNCMF'
--AND WETUFWLITWORKINCODE = '3912'
--AND EECLOCATION = 'INDANA'
--AND LOCCODE IN ('AL0','AL2','AL4','AL5','AL7','ASH','BRA','GOS','OSN','NRM','HEB','MRY','MRD','MCW','HLD','GRN')
--AND WETUFWLOCATION IS NULL
--AND LOCCODE=WETUFWLOCATION
AND (CntCoID <> CmpCoID OR CntCoID IS NULL)
--AND RETPENDINGUPDATEID IN ('237685483CM880S','240805214CM880S')
--AND EEPPENDINGUPDATEID IN ('237685483CM880S','240805214CM880S')
--AND EEMPENDINGUPDATEID IN ('237685483CM880S','240805214CM880S')

UPDATE LODEPERS SET EEPCOMPANYCODE = 'WHO' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODRSETX ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODCNTRL ON CntPendingUpdateID=IRRPENDINGUPDATEID
JOIN COMPANY ON CmpCompanyCode = EepCompanyCode
JOIN [LOCATION] ON LOCCODE=EECLOCATION
WHERE IRRMSGCODE = 'E0261' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
--AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
--AND wetufwsitworkincode in ('azsit','mssit')
-- AND WETUFWCOMPANYCODE = 'LNCMF'
--AND WETUFWLITWORKINCODE = '3912'
--AND EECLOCATION = 'INDANA'
--AND LOCCODE IN ('AL0','AL2','AL4','AL5','AL7','ASH','BRA','GOS','OSN','NRM','HEB','MRY','MRD','MCW','HLD','GRN')
--AND WETUFWLOCATION IS NULL
--AND LOCCODE=WETUFWLOCATION
--AND (CntCoID <> CmpCoID OR CntCoID IS NULL)
--AND RETPENDINGUPDATEID IN ('237685483CM880S','240805214CM880S')

UPDATE LODEEMST SET EEMUFWCOMPANYCODE = 'WHO' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODRSETX ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODCNTRL ON CntPendingUpdateID=IRRPENDINGUPDATEID
JOIN COMPANY ON CmpCompanyCode = EepCompanyCode
JOIN [LOCATION] ON LOCCODE=EECLOCATION
WHERE IRRMSGCODE = 'E0261' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
--AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
--AND wetufwsitworkincode in ('azsit','mssit')
-- AND WETUFWCOMPANYCODE = 'LNCMF'
--AND WETUFWLITWORKINCODE = '3912'
--AND EECLOCATION = 'INDANA'
--AND LOCCODE IN ('AL0','AL2','AL4','AL5','AL7','ASH','BRA','GOS','OSN','NRM','HEB','MRY','MRD','MCW','HLD','GRN')
--AND WETUFWLOCATION IS NULL
--AND LOCCODE=WETUFWLOCATION
--AND (CntCoID <> CmpCoID OR CntCoID IS NULL)
--AND RETPENDINGUPDATEID IN ('237685483CM880S','240805214CM880S')

UPDATE LODEDED SET EEDCOMPANYCODE = 'WHO' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEEMST ON EEmPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODRSETX ON RETPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODCNTRL ON CntPendingUpdateID=IRRPENDINGUPDATEID
JOIN COMPANY ON CmpCompanyCode = EepCompanyCode
JOIN [LOCATION] ON LOCCODE=EECLOCATION
WHERE IRRMSGCODE = 'E0261' AND IrrSessionID = 'CONV'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
--AND EEMUFWSTATEWC IS NULL
--AND EEMUFWSTATESUI IN ('NYSUIER','CASUIER','NJSUIER')
--AND EEMUFWSTATESUI NOT IN ('NYSUIER','CASUIER','NJSUIER')
--AND EECPENDINGUPDATEID = '5Z9002168'
--AND EEMUFWSTATESUI = 'INSUIER'
--AND WETUFWLOCATION = 'FL'
-- AND wetPENDINGUPDATEID = '660829'
--AND wetufwsitworkincode in ('azsit','mssit')
-- AND WETUFWCOMPANYCODE = 'LNCMF'
--AND WETUFWLITWORKINCODE = '3912'
--AND EECLOCATION = 'INDANA'
--AND LOCCODE IN ('AL0','AL2','AL4','AL5','AL7','ASH','BRA','GOS','OSN','NRM','HEB','MRY','MRD','MCW','HLD','GRN')
--AND WETUFWLOCATION IS NULL
--AND LOCCODE=WETUFWLOCATION
--AND (CntCoID <> CmpCoID OR CntCoID IS NULL)
--AND RETPENDINGUPDATEID IN ('237685483CM880S','240805214CM880S')

---------------ERROR E0262: Date of last performance review must be less than date of next performance review------------ON QUIP NOT ON SCRIPT--------
--Description: 
--The dates are backwards or the same. The client must fix these or if the dates are backwards you could flip them

SELECT 'E0262: Date of last performance review must be less than date of next performance review'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECDATEOFLASTHIRE AS DATEOFLASTHIRE, EECDATEOFORIGINALHIRE AS DATEOFORIGINALHIRE, eecdateoftermination AS DATEOFTERMINATION
, EECDATEOFLASTSALREVIEW AS DATEOFLASTSALREVIEW,EECDATEOFNEXTSALREVIEW AS DATEOFNEXTSALREVIEW,EECDATEOFLASTPERFREVIEW AS DATEOFLASTPERFREVIEW
,EECDATEOFNEXTPERFREVIEW AS DATEOFNEXTPERFREVIEW
-- select distinct ECDATEOFLASTHIRE,EECDATEOFORIGINALHIRE, EECDATEOFLASTSALREVIEW,EECDATEOFNEXTSALREVIEW,EECDATEOFLASTPERFREVIEW,EECDATEOFNEXTPERFREVIEW
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0262' AND IrrSessionID = 'CONV'
AND EEPRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'

-- Sample Updates

UPDATE LODECOMP 
SET EECDATEOFNEXTPERFREVIEW = '9/9/9999'
-- SET EECDATEOFNEXTPERFREVIEW = null
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0262' AND IrrSessionID = 'CONV'
AND EEPRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
--AND EEPPENDINGUPDATEID = 'RSUI000007184'
--AND EecDateOfLastPerfReview IS NOT NULL
--and EecDateOfLastPerfReview= EecDateOfNextPerfReview

--------------------------ERROR E0263: Date of last salary review must be less than date of next salary review------------ON QUIP NOT ON SCRIPT--------
--Description: 
--The dates are backwards or the same. The client must fix these or if the dates are backwards you could flip them

SELECT 'E0263: Date of last salary review must be less than date of next salary review'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECDATEOFLASTHIRE AS DATEOFLASTHIRE, EECDATEOFORIGINALHIRE AS DATEOFORIGINALHIRE, eecdateoftermination AS DATEOFTERMINATION
, EECDATEOFLASTSALREVIEW AS DATEOFLASTSALREVIEW,EECDATEOFNEXTSALREVIEW AS DATEOFNEXTSALREVIEW,EECDATEOFLASTPERFREVIEW AS DATEOFLASTPERFREVIEW
,EECDATEOFNEXTPERFREVIEW AS DATEOFNEXTPERFREVIEW
-- select distinct ECDATEOFLASTHIRE,EECDATEOFORIGINALHIRE, EECDATEOFLASTSALREVIEW,EECDATEOFNEXTSALREVIEW,EECDATEOFLASTPERFREVIEW,EECDATEOFNEXTPERFREVIEW
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0263' AND IrrSessionID = 'CONV'
AND EEPRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
--AND EEPPENDINGUPDATEID = 'RSUI000007184'

-- Sample Updates

UPDATE LODECOMP SET EECDATEOFNEXTSALREVIEW = '9/9/9999'
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0263' AND IrrSessionID = 'CONV'
AND EEPRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
--AND EEPPENDINGUPDATEID = 'RSUI000007184'

--Remove future reviews that are the same as the past date.
UPDATE LODECOMP set EecDateOfNextSalReview=NUll
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0263' AND IrrSessionID = 'CONV'
AND EEPRECID = IRRRECID
AND EecDateOfLastSalReview IS NOT NULL
and EecDateOfLastSalReview= EecDateOfNextSalReview


-----------------------------------------------ERROR E0267: Invalid Military Info---------------------------------------------------
--Description: 

SELECT 'E0267: Invalid Military Info'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EEPMILITARY AS MILITARY, EEPMILITARYBRANCHSERVED AS MILITARYBRANCHSERVED, EEPMILITARYERA AS MILITARYERA, EEPMILITARYISDISABLEDVET AS MILITARYDISABLEDVET
-- select distinct EEPMILITARY, EEPMILITARYBRANCHSERVED, EEPMILITARYERA, EEPMILITARYISDISABLEDVET
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0267' AND IrrSessionID = 'CONV'
AND EEPRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
--AND EEPPENDINGUPDATEID = 'RSUI000007184'

-- Sample Updates

UPDATE LODEPERS SET EEPMILITARY = 'Y' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0267' AND IrrSessionID = 'CONV'
AND EEPRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
--AND EEPPENDINGUPDATEID = 'RSUI000007184'

UPDATE LODEPERS SET EEPMILITARYBRANCHSERVED = NULL
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0267' AND IrrSessionID = 'CONV'
AND EEPRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
--AND EEPPENDINGUPDATEID = 'RSUI000007184'

----------------------------------------------------ERROR E0268: INVALID MILITARY INFO---------------------------------------------------
--Description: 

SELECT 'E0268: Invalid Military Info'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EEPMILITARY AS MILITARY, EEPMILITARYBRANCHSERVED AS MILITARYBRANCHSERVED, EEPMILITARYERA AS MILITARYERA, EEPMILITARYISDISABLEDVET AS MILITARYDISABLEDVET
-- select distinct EEPMILITARY, EEPMILITARYBRANCHSERVED, EEPMILITARYERA, EEPMILITARYISDISABLEDVET 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0268' AND IrrSessionID = 'CONV'
AND EEPRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
--AND EEPPENDINGUPDATEID = 'RSUI000007184'

-- Sample Updates

UPDATE LODEPERS SET EEPMILITARY = 'Y' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0268' AND IrrSessionID = 'CONV'
AND EEPRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
--AND EEPPENDINGUPDATEID = 'RSUI000007184'

----------------------------------------------------ERROR E0269: INVALID MILITARY INFO---------------------------------------------------
--Description: 

SELECT 'E0269: Invalid Military Info'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EEPMILITARY AS MILITARY, EEPMILITARYBRANCHSERVED AS MILITARYBRANCHSERVED, EEPMILITARYERA AS MILITARYERA, EEPMILITARYISDISABLEDVET AS MILITARYDISABLEDVET
-- select distinct EEPMILITARY, EEPMILITARYBRANCHSERVED, EEPMILITARYERA, EEPMILITARYISDISABLEDVET 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0269' AND IrrSessionID = 'CONV'
AND EEPRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
--AND EEPPENDINGUPDATEID = 'RSUI000007184'

-- Sample Updates

UPDATE LODEPERS SET EEPMILITARYERA = 'VIET',EEPMILITARY = 'A' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0269' AND IrrSessionID = 'CONV'
AND EEPRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
AND EEPPENDINGUPDATEID = 'RSUI000007184'

UPDATE LODEPERS SET EEPMILITARYISDISABLEDVET = 'N' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0269' AND IrrSessionID = 'CONV'
AND EEPRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
AND EEPPENDINGUPDATEID = 'RSUI000007184'

-----------------------------------------ERROR E0274------------------------------------------------------------------

SELECT 'E0274: ?'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EEPMILITARY AS MILITARY, EEPMILITARYBRANCHSERVED AS MILITARYBRANCHSERVED, EEPMILITARYERA AS MILITARYERA, EEPMILITARYISDISABLEDVET AS MILITARYDISABLEDVET
, WETUFWLOCATION,WETUFWSITWORKINCODE ,EECLOCATION,EECSITWORKINSTATECODE
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0274' AND IrrSessionID = 'CONV'
  --and eeclocation = 'Noodle'

-- Sample Updates

UPDATE LODECOMP SET EECLOCATION = 'ATL' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0274' AND IrrSessionID = 'CONV'
  --and eeclocation = 'Noodle'

UPDATE LODECOMP SET EECLOCATION=WETUFWLOCATION 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODWKETX ON WETPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0274' AND IrrSessionID = 'CONV'
  --and eeclocation = 'Noodle'



------------------------------------------------ERROR E0275: Logical fields must be "Y" or "N"-----------------------------------------------------------
--Description: 

SELECT 'E0275: Logical fields must be "Y" or "N"' , IrrFieldName
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, eepisdisabled, EEPISMULTIPAYGROUPEE, EEPMILITARY
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0275' AND IrrSessionID = 'CONV'
AND EEPRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'

-- Sample Updates
-- None yet

----------------------------------------------------ERROR E0277: INVALID PERFORMANCE REVIEW INFO---------------------------------------------------
--Description:

SELECT 'E0277: INVALID PERFORMANCE REVIEW INFO'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECDATEOFLASTHIRE AS DATEOFLASTHIRE, EECDATEOFORIGINALHIRE AS DATEOFORIGINALHIRE, eecdateoftermination AS DATEOFTERMINATION
, EECDATEOFLASTSALREVIEW AS DATEOFLASTSALREVIEW,EECDATEOFNEXTSALREVIEW AS DATEOFNEXTSALREVIEW,EECDATEOFLASTPERFREVIEW AS DATEOFLASTPERFREVIEW
,EECDATEOFNEXTPERFREVIEW AS DATEOFNEXTPERFREVIEW,EECREVIEWPERFRATING AS REVIEWPERFRATING,EECREVIEWSALARYRATING AS REVIEWSALARYRATING,eecreviewtypesalARY AS REVIEWTYPESALARY
-- select distinct ECDATEOFLASTHIRE,EECDATEOFORIGINALHIRE, EECDATEOFLASTSALREVIEW,EECDATEOFNEXTSALREVIEW,EECDATEOFLASTPERFREVIEW,EECDATEOFNEXTPERFREVIEW
--,EECREVIEWPERFRATING,EECREVIEWSALARYRATING, eecreviewtypesalARY
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0277' AND IrrSessionID = 'CONV'
AND EEPRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'

-- Sample Updates

UPDATE LODECOMP 
SET EECREVIEWPERFRATING = UPPER(EECREVIEWPERFRATING),EECREVIEWSALARYRATING = UPPER(EECREVIEWSALARYRATING)
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0277' AND IrrSessionID = 'CONV'
AND EEPRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'

UPDATE LODECOMP 
SET EECREVIEWPERFRATING = '6MONTH', EECREVIEWSALARYRATING = '6MONTH'
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0277' AND IrrSessionID = 'CONV'
AND EEPRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'
AND EECREVIEWPERFRATING IN ('6 - MO','6 MONT','63-MON','6-MONT','SIX MO')

UPDATE LODECOMP 
SET EECREVIEWPERFRATING = 'Z',EECREVIEWSALARYRATING= 'Z' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0277' AND IrrSessionID = 'CONV'
AND EEPRECID = IRRRECID
--AND EECJOBCODE = '006133'
--and irrtableNAME = 'LODECOMP'
--AND EECEMPLSTATUS <> 'T'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'
--AND EECREVIEWPERFRATING IN ('HELD')


--------------------------ERROR E0282: Benefit amount calculation rule cannot be changed at the employee level--------------------------
--Description:
-- Usually just a bug. It should be just Null if the deduction is setup not allow calucations on the EE deduction

SELECT 'E0282: Benefit amount calculation rule cannot be changed at the employee level'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECDATEOFLASTHIRE AS DATEOFLASTHIRE, EECDATEOFORIGINALHIRE AS DATEOFORIGINALHIRE, eecdateoftermination AS DATEOFTERMINATION
, EedDedCode as DEDCODE,  EEDBENOPTION as BENOPTION, EEDBENAMTCALCRULE AS BENAMTCALCRULE, EEDEEAMT AS EEAMT, EEDERAMT AS ERAMT,EEDEEGOALAMT AS EEGOALAMT, EedStartDate AS STARTDATE
, EedBenStartDate AS BEN STARTDATE 
, eedEEEligDate AS EEELIGDATE, eedbenstatusdate AS BENSTATUSDATE, eedDEDEFFSTARTDATE as DEDEFFSTARTDATE
, eecdateofbenefitseniority AS dateofbenefitseniority 
, EedBenStatus as BenStatus 
-- select distinct EedDedCode, Eedeegoalamt, EEDBENAMTCALCRULE, --MAX(EEDEEGOALAMT)
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0282' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECEMPLSTATUS <> 'T'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'
--AND EEDSTOPDATE IS NOT NULL
--AND EECSESSIONID = 'CONV'
--AND EEDDEDCODE IN ('401KL','FNVEH','LIAB','UWAYD','VANLS')

-- Sample Updates

UPDATE LODEDED SET EEDBENAMTCALCRULE = NULL WHERE EEDBENAMTCALCRULE = '0'
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0282' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECEMPLSTATUS <> 'T'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'
--AND EEDSTOPDATE IS NOT NULL
--AND EECSESSIONID = 'CONV'
--AND EEDDEDCODE IN ('401KL','FNVEH','LIAB','UWAYD','VANLS')

Update lodeded 
set EedBenAmtCalcRule = 
	CASE WHEN eedBenAmt > 0 THEN '30' 
	ELSE NULL 
	END
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0282' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECEMPLSTATUS <> 'T'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'
--AND EEDSTOPDATE IS NOT NULL
--AND EECSESSIONID = 'CONV'
--AND EEDDEDCODE IN ('401KL','FNVEH','LIAB','UWAYD','VANLS')


-----------------------------------------------------------ERROR E0283: INVALID BENAMT-------------------------------------------------------
--Description: 

SELECT 'E0283: INVALID BENAMT'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECDATEOFLASTHIRE AS DATEOFLASTHIRE, EECDATEOFORIGINALHIRE AS DATEOFORIGINALHIRE, eecdateoftermination AS DATEOFTERMINATION
, EedDedCode as DEDCODE, EEDBENAMT AS BENAMT, EEDBENOPTION as BENOPTION, EEDBENAMTCALCRULE AS BENAMTCALCRULE, EEDEEAMT AS EEAMT, EEDERAMT AS ERAMT,EEDEEGOALAMT AS EEGOALAMT, EedStartDate AS STARTDATE
, EedBenStartDate AS BEN STARTDATE 
, eedEEEligDate AS EEELIGDATE, eedbenstatusdate AS BENSTATUSDATE, eedDEDEFFSTARTDATE as DEDEFFSTARTDATE
, eecdateofbenefitseniority AS dateofbenefitseniority 
, EedBenStatus as BenStatus 
-- select distinct EedDedCode, EEDBENAMT, Eedeegoalamt, EEDBENAMTCALCRULE, --MAX(EEDEEGOALAMT)
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0283' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECEMPLSTATUS <> 'T'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'
--AND EEDSTOPDATE IS NOT NULL
--AND EECSESSIONID = 'CONV'
--AND EEDDEDCODE IN ('401KL','FNVEH','LIAB','UWAYD','VANLS')

-- Sample Update

UPDATE LODEDED SET EEDBENAMT = 0 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0283' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECEMPLSTATUS <> 'T'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'
--AND EEDSTOPDATE IS NOT NULL
--AND EECSESSIONID = 'CONV'
--AND EEDDEDCODE IN ('401KL','FNVEH','LIAB','UWAYD','VANLS')

------------------------------------------------------ERROR E0284: Invalid EedBenAmtRateOrPct-------------------------------------------------------------
--Description: 

SELECT 'E0284: Invalid EedBenAmtRateOrPct'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECDATEOFLASTHIRE AS DATEOFLASTHIRE, EECDATEOFORIGINALHIRE AS DATEOFORIGINALHIRE, eecdateoftermination AS DATEOFTERMINATION
, EedDedCode as DEDCODE, EEDBENAMT AS BENAMT, EEDBENOPTION as BENOPTION, EEDBENAMTCALCRULE AS BENAMTCALCRULE, EedBenAmtRateOrPct AS BENAMTRATEORPCT, EEDEEAMT AS EEAMT, EEDERAMT AS ERAMT,EEDEEGOALAMT AS EEGOALAMT, EedStartDate AS STARTDATE
, EedBenStartDate AS BEN STARTDATE 
, eedEEEligDate AS EEELIGDATE, eedbenstatusdate AS BENSTATUSDATE, eedDEDEFFSTARTDATE as DEDEFFSTARTDATE
, eecdateofbenefitseniority AS dateofbenefitseniority 
, EedBenStatus as BenStatus 
-- select distinct EedDedCode, EEDBENAMT, EedBenAmtRateOrPct, Eedeegoalamt, EEDBENAMTCALCRULE, --MAX(EEDEEGOALAMT)
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0284' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECEMPLSTATUS <> 'T'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'
--AND EEDSTOPDATE IS NOT NULL
--AND EECSESSIONID = 'CONV'
--AND EEDDEDCODE IN ('401KL','FNVEH','LIAB','UWAYD','VANLS')

-- Sample Updates

UPDATE LODEDED SET EedBenAmtRateOrPct = 0
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0284' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
--AND EECEMPLSTATUS <> 'T'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'
--AND EEDSTOPDATE IS NOT NULL
--AND EECSESSIONID = 'CONV'
--AND EEDDEDCODE IN ('401KL','FNVEH','LIAB','UWAYD','VANLS')


------------------------------------------ERROR E0293: Invalid EECPLANNEDSTATUSSTARTDATE / EECPLANNEDSTATUSENDDATE-------------------------------------
--Description: 

SELECT 'E0293: Invalid EECPLANNEDSTATUSSTARTDATE / EECPLANNEDSTATUSENDDATE'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECDATEOFLASTHIRE AS DATEOFLASTHIRE, EECDATEOFORIGINALHIRE AS DATEOFORIGINALHIRE, eecdateoftermination AS DATEOFTERMINATION
, EECPLANNEDSTATUSSTARTDATE AS PLANNEDSTATUSSTARTDATE, EECPLANNEDSTATUSENDDATE AS PLANNEDSTATUSENDDATE
-- select distinct EECPLANNEDSTATUSSTARTDATE,EECPLANNEDSTATUSENDDATE
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0293' AND IrrSessionID = 'CONV'
AND EECRECID = IRRRECID
--AND EECEMPLSTATUS <> 'T'
--AND EECSESSIONID = 'CONV'

-- Sample Updates

UPDATE LODECOMP SET 
 EECPLANNEDSTATUSSTARTDATE = NULL
,EECPLANNEDSTATUSENDDATE = NULL 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0293' AND IrrSessionID = 'CONV'
AND EECRECID = IRRRECID
--AND EECEMPLSTATUS <> 'T'
--AND EECSESSIONID = 'CONV'



------------------------------ ERROR E0302: Attempting to add an existing record-----------------------------
--Description: 
-- The sequence number is duplicate in the direct deposit.
-- Could also be an issues with duplicate deductions


-- Deductions (LodEDed)
SELECT 'E0302: Attempting to add an existing record', IrrTableName
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EEDDEDCODE,EEDEEAMT,eedbenoption, eedstartdate, eedstopdate, eedrecid 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN Lodeded ON  EEdPENDINGUPDATEID=IRRPENDINGUPDATEID and eeddedcode in (select eeddedcode from lodeded where irrrecid = eedrecid and IRRMSGCODE = 'E0302')
WHERE IRRMSGCODE = 'E0302' AND IrrSessionID = 'CONV'
  and IrrTableName = 'LODEDED'
order by eeccompanycode, eecempno, eeddedcode 

--Pick the recids you want to delete
/*delete from  lodeded where eedrecid in (13,16,26,45,53,93,9707)*/


-----

-- Deductions (LodEDep)
SELECT 'E0302: Attempting to add an existing record', IrrTableName
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EddAccountIsInActive, EddEeBankRoute, EddAcct, EddAcctType, EddAmtOrPct, EddDepositRule, EddSequence, eddrecid 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDEP ON  EddPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E0302' AND IrrSessionID = 'CONV'
  and IrrTableName = 'LODEDEP'
order by IrrTableName

--Pick the recids you want to delete
/*delete from  LODEDEP where eddrecid in (13,16,26,45,53,93,9707)*/

---------------------------------------------------ERROR E0304: INVALID COMPANY CODE -----------------------------------------------------
--Description: 

SELECT 'E0304: INVALID COMPANY CODE'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECDATEOFLASTHIRE AS DATEOFLASTHIRE, EECDATEOFORIGINALHIRE AS DATEOFORIGINALHIRE, eecdateoftermination AS DATEOFTERMINATION
, EecCompanyCode
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodCntrl ON CNTPENDINGUPDATEID=IRRPENDINGUPDATEID
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0304' AND IrrSessionID = 'CONV'
AND EECRECID = IRRRECID
--AND EECEMPLSTATUS <> 'T'
--and CNTSESSIONID = 'FCBOE'

-- Sample Updates

UPDATE LODECOMP SET EECCOMPANYCODE = 'FC01',EECCOID = 'ZPUD3'
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodCntrl ON CNTPENDINGUPDATEID=IRRPENDINGUPDATEID
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0293' AND IrrSessionID = 'CONV'
AND EECRECID = IRRRECID
--AND EECEMPLSTATUS <> 'T'

UPDATE LODCNTRL SET CNTCOID = 'ZPUD3' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodCntrl ON CNTPENDINGUPDATEID=IRRPENDINGUPDATEID
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0293' AND IrrSessionID = 'CONV'
AND EECRECID = IRRRECID
--AND EECEMPLSTATUS <> 'T'



-----------------------------------------------ERROR E0325: Invalid benefit option code---------------------------------------------------------
--Description: Invalid benefit option code
--Description sourced from Quip:
--Invalid benefit option code

SELECT 'E0325: Invalid benefit option code'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, EECDATEOFLASTHIRE AS DATEOFLASTHIRE, EECDATEOFORIGINALHIRE AS DATEOFORIGINALHIRE, eecdateoftermination AS DATEOFTERMINATION
, EedDedCode as DEDCODE,  EEDBENOPTION as BENOPTION, EEDBENAMTCALCRULE AS BENAMTCALCRULE, EEDEEAMT AS EEAMT, EEDERAMT AS ERAMT,EEDEEGOALAMT AS EEGOALAMT, EedStartDate AS STARTDATE
, EedBenStartDate AS BEN STARTDATE 
, eedEEEligDate AS EEELIGDATE, eedbenstatusdate AS BENSTATUSDATE, eedDEDEFFSTARTDATE as DEDEFFSTARTDATE
, eecdateofbenefitseniority AS dateofbenefitseniority 
, EedBenStatus as BenStatus 
-- select distinct EedDedCode, Eedeegoalamt, EEDBENAMTCALCRULE, --MAX(EEDEEGOALAMT)
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0325' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
AND EECEMPLSTATUS <> 'T'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'
--AND EEDSTOPDATE IS NOT NULL
--AND EECSESSIONID = 'CONV'
--AND EEDDEDCODE IN ('401KL','FNVEH','LIAB','UWAYD','VANLS')

update lodeded set eedbenoption = NULL 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LODEDED ON EEDPENDINGUPDATEID=IRRPENDINGUPDATEID
--JOIN EMPCOMP ON CNTCOID=EECCOID AND EECEEID=CNTEEID
WHERE IRRMSGCODE = 'E0325' AND IrrSessionID = 'CONV'
AND EEDRECID = IRRRECID
AND EECEMPLSTATUS <> 'T'
--AND EEDPENDINGUPDATEID = 'RSUI000007184'
--AND EEDSTOPDATE IS NOT NULL
--AND EECSESSIONID = 'CONV'
AND EEDDEDCODE IN ('401KL','FNVEH','LIAB','UWAYD','VANLS')
AND EEDBENOPTION = 'EMPSPS'

--BELOW SOURCED FROM QUIP: NONE

--------------------------ERROR E0600: Bank routing number specified is too short--------------ON QUIP NOT ON SCRIPT REVIEW------------
--Description sourced from Quip:
--Bank routing number specified is too short



SELECT EecPendingUpdateId, EecCompanyCode, EecEmpno, EepNameLast, EepNameFirst, EecEmplStatus, EddEeBankRoute, EddRecID

FROM LodEComp 

JOIN LodEPers
 ON EecPendingUpdateID = EepPendingUpdateID

JOIN LodEDep 
ON EecPendingUpdateID = EddPendingUpdateID

WHERE EecSessionID = 'CONV'
AND LEN(EddEeBankRoute) < 9

Update LodEDep
set EddEeBankRoute=right('000000000'+rtrim(EddEeBankRoute),9)

--Select right('000000000'+rtrim(EddEeBankRoute),9)

FROM LodEComp

JOIN LodEPers 
ON EecPendingUpdateID = EepPendingUpdateID

JOIN LodEDep
 ON EecPendingUpdateID = EddPendingUpdateID

WHERE EecSessionID = 'CONV'
AND LEN(EddEeBankRoute) < 9

 
--------------ERROR E9994: The following field is required...------------------------------------------------

--View error Detail
SELECT 'E9994: The following field is required'
, EecPendingUpdateID, EecCompanyCode as CoCode , EecEmpno as EmpNo , EepSSN as SSN
, EepNameLast as Lastname , EepNameFirst as FirstName, EecEmplStatus as Status
, IrrFieldName 
, EEPssn 
-- select distinct EedDedCode
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E9994' AND IrrSessionID = 'CONV' and IrrTableName = 'LodEPers' --and IrrFieldName = 'EepSSN'
ORDER BY EecEmplStatus, EepNameLast, EepNameFirst, EecEmpno

--Sample Updates
update lodepers set eepssn = '123456789' 
FROM IMPERRS
JOIN LodEComp ON EECPENDINGUPDATEID=IRRPENDINGUPDATEID
JOIN LodEPers ON EEPPENDINGUPDATEID=IRRPENDINGUPDATEID
WHERE IRRMSGCODE = 'E9994' AND IrrSessionID = 'CONV' and IrrTableName = 'LodEPers' and IrrFieldName = 'EepSSN'
  and  EepPendingUpdateID = 'XYZ200949'       







