
 -------------------=======
-- Re run validation in BackOffice 

SELECT IrrMsgCode as [Code], IrrMessage as [Description], IrrTableName as [Table Name],IrrFieldName as [Column], count(*) as [Count] 
FROM IMPERRS  
WHERE SUBSTRING(IrrMsgCode,1,1) = 'E' AND IrrSessionID = 'CONV'
group BY IrrTableName,IrrFieldName,IrrMsgCode,IrrMessage ORDER BY IrrMsgCode


  