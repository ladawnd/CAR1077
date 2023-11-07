--=================================================
select * into dbo.ACE_TEMP_DataQualityCheck from #ACE_DataQualityCheck 

select * from  ACE_TEMP_DataQualityCheck

select severity, errornumber, errorkeylabel, count(*) Cnt from ACE_TEMP_DataQualityCheck
group by severity, errornumber, errorkeylabel
order by severity, errornumber


 