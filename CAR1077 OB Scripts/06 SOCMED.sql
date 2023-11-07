 
--Use this in place of the OB Toolkit to check for tax variances (just like the SOC/MED variance tool)
IF OBJECT_ID('tempdb..#MyTempTable') IS NOT NULL
   DROP TABLE #MyTempTable
create table #MyTempTable
(CmpCountryCode    varchar(3)
,OlmCompanyCode    varchar(5)
,SystemID    varchar(12)
,OlmEmpNo    varchar(9)
,OlmSSN    varchar(9)
,OlmNameLast    varchar(30)
,OlmNameFirst    varchar(30)
,USSOCEESRC    decimal(18,2)
,USSOCEECALC    decimal(18,2)
,USSOCEEDIFF    decimal(18,2)
,USMEDEESRC    decimal(18,2)
,USMEDEECALC    decimal(18,2)
,USMEDEEDIF    decimal(18,2)
,Earnings decimal(18,2)
,Deductions decimal(18,2)
,TaxSoc decimal(18,2)
,TaxMED decimal(18,2)
,NoSOC varchar(1)
,NoMed varchar(1)
)
insert into  #MyTempTable
exec [ACEsp_SOCMedVariance] ''
SELECT *
, cast(USSOCEESRC / 0.062 as money) AS [SOC Esimated Earn]
, cast(USSOCEECALC / 0.062 as money) AS [SOC Calc Earn]
, cast((USSOCEESRC / 0.062 ) -(USSOCEECALC / 0.062) as money) AS SOCEarningsDiff
,'|' as '|'
, cast(USMEDEESRC / 0.0145 as money) AS [MED Esimated Earn]
, cast(USMEDEECALC / 0.0145 as money) AS [MED Calc Earn]
, cast((USMEDEESRC / 0.0145 ) -(USSOCEECALC / 0.0145) as money) AS MEDEarningsDiff
FROM #MyTempTable
order by USSOCEEDIFF 

select * from #MyTempTable where USSOCEEDIFF <> 0 


 drop table ACE_TEMP_SOCMEDLAST

select systemid, olmcompanycode, olmempno, olmnamelast, olmnamefirst,  	 	USSOCEESRC,	USSOCEECALC,	USSOCEEDIFF, 99999999.99 as Amount, 'XXXXXX' as DedCode 
, 	USMEDEESRC,	USMEDEECALC,	USMEDEEDIF,	Earnings,	Deductions,	TaxSoc	,TaxMED	,NoSOC,	NoMed
into dbo.ACE_TEMP_SOCMEDLAST FROM #MyTempTable where USSOCEEDIFF <> 0


select * from ACE_TEMP_SOCMEDLAST order by USSOCEEDIFF

delete from ACE_TEMP_SOCMEDLAST where USSOCEEDIFF = 0 
delete  from ACE_TEMP_SOCMEDLAST where abs(USSOCEEDIFF) <  0.08
delete  from ACE_TEMP_SOCMEDLAST where USSOCEESRC= 0 

 select systemid	,olmcompanycode	,olmempno	,olmnamelast,	olmnamefirst,	Amount,	DedCode,	USSOCEESRC,	USSOCEECALC,	USSOCEEDIFF	
 ,USMEDEESRC	,USMEDEECALC,	USMEDEEDIF,	Earnings,	Deductions	,TaxSoc	,TaxMED,	NoSOC,	NoMed
 from ACE_TEMP_SOCMEDLAST order by olmnamelast 


 update ACE_TEMP_SOCMEDLAST set amount =   USSOCEEDIFF/0.062 
 
 update ACE_TEMP_SOCMEDLAST set dedcode =  '' 

 update ACE_TEMP_SOCMEDLAST set dedcode =   olddedcode from obldded
  join ACE_TEMP_SOCMEDLAST on systemid=oldobsystemid 
 where  
    abs(amount) <  OldEEYTDAmt + 0.50 
 and abs(amount) >  OldEEYTDAmt - 0.50 


 update ACE_TEMP_SOCMEDLAST set dedcode =   oleearncode from obldern
 join ACE_TEMP_SOCMEDLAST on systemid=oleobsystemid 
 where  abs(amount) <  OleYTDAmt + 0.50 
 and abs(amount) >  OleYTDAmt - 0.50 


 select * from ACE_TEMP_SOCMEDLAST

 select * from ace_dep 


 
 

 