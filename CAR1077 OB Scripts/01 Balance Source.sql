
-- Run Source Validation in Launch then 

EXEC ACEsp_OneVal  'OBUSA' 

-- Check for missing employees 

exec  DBO.ACEsp_GenericExcel_MissingEEs 
 
 select rtrim(ernearncode) as EarnCode, ernlongdesc from earncode 

--ACE_OBERN 
SELECT   ace_obern.CoCode
       , EARNCODE   
	  -- , SUM(cast(QTDHRS as float)) as QTDHrs
	--   ,  round(SUM(cast(QTDEarnAmt as float)) , 2)  as QTDAmt
	   ,  SUM(cast(YTDHRS as float)) as YTDHrs  
	   , round(SUM(cast(YTDEarnAmt as float)) , 2)  as YTDAmt
from ACE_OBERN 
  GROUP BY   ace_obern.CoCode,  ace_obern.EARNCODE  
ORDER BY ace_obern.CoCode, ace_obern.EARNCODE

select YTDEarnAmt from ace_obern where earncode ='3023' 

update ace_obern set YTDEarnAmt = '2038.72' where YTDEarnAmt = '-2038.72'
update ace_obern set YTDEarnAmt = '5451.13' where YTDEarnAmt = '-5451.13'

 update ACE_OBERN set YTDHRS = 0 where YTDHRS is null
update ACE_OBERN set YTDEarnAmt = 0 where YTDEarnAmt is null


 update ACE_OBERN set QTDHRS = 0 where QTDHRS is null
update ACE_OBERN set QTDEarnAmt = 0 where QTDEarnAmt is null



 update ACE_OBDED set ERYTDAmt = 0 where ERYTDAmt is null
update ACE_OBDED set EEYTDAmt = 0 where EEYTDAmt is null

update ACE_OBDED set ERQTDAmt = 0 where ERQTDAmt is null
update ACE_OBDED set EEQTDAmt = 0 where EEQTDAmt is null

 


--ACE_OBDED
SELECT ace_obded.CoCode, DEDCODE , dedlongdesc
 
	  	    , SUM(cast(ERYTDAmt as float)) as ERYtdAmt  
	   	   , round(SUM(cast(EEYTDAmt as float)) , 2)  as EEYTDAmt
	FROM ace_obded 
	join dedcode on dedcode =deddedcode 
 GROUP BY  ace_obded.CoCode, DEDCODE, dedlongdesc  
ORDER BY ace_obded.CoCode, DEDCODE 



select * from ace_obded where isnumber(EEYTDAmt 
 
 
update ACE_OBTax set QTDTaxAmt = 0 where QTDTaxAmt is null 
update ACE_OBTax set YTDTaxAmt = 0 where YTDTaxAmt is null 

--ACE_OBTax
SELECT  ace_obtax.CoCode,  taxcode 
, round (SUM(cast(YTDTaxAmt as float)) , 2) as YTDTaxAmt  
 FROM ACE_OBTAX
 
GROUP BY ace_obtax.CoCode, taxcode   
order by ace_obtax.CoCode, taxcode 
 

 
 select lastname, taxcode, ytdtaxamt from ace_obtax where taxcode='CASDIEE' 

 select oltempno, olttaxcode, OltYTDTaxAmt from obldtax 

 delete from obldmas 

  
 

 
 
  