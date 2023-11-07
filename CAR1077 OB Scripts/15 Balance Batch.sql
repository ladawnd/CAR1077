Select distinct mbtpaygroup, mbtiscalculated from m_batch order by mbtpaygroup, mbtiscalculated

-----------------------------------------------E_BATCH TOTALING QUERIES--------------------------------------------
SELECT CMPCOMPANYCODE, EBTEARNCODE, SUM(EBTCURAMT) as Amount, SUM(EBTCURHRS) as Hours FROM E_BATCH 
JOIN COMPANY ON EBTCOID=CMPCOID
GROUP BY CMPCOMPANYCODE,EBTEARNCODE ORDER BY CMPCOMPANYCODE,EBTEARNCODE


------------------------------------------------D_BATCH TOTALING QUERIES----------------------------------------------
SELECT CMPCOMPANYCODE, DbtDedCode, SUM(DBTEECURAMT) AS EE_YTD, SUM(DBTERCURAMT) AS ER_YTD
FROM D_BATCH 
JOIN COMPANY ON CMPCOID=DBTCOID
GROUP BY CMPCOMPANYCODE,DBTDEDCODE 
ORDER BY CMPCOMPANYCODE,DBTDEDCODE


--------------------------------------------T_BATCH QUERIES --------------------------------------------------------------------
SELECT CmpCompanyCode, TbtTaxCode, SUM(tbTcurTAXAMT)AS TOTAL_TAX_AMT
--,SUM(tbTcurGROSSWAGES) AS TOTAL_GROSS,SUM(tbTcurTAXABLEWAGES) AS TOTAL_TXWAGES
--,SUM(TBTCURTAXABLEGROSS) AS TOTAL_TXGROSS
FROM t_batch
JOIN COMPANY ON TBTCOID=CMPCOID
GROUP BY CmpCompanyCode, TBTTAXCODE 
ORDER BY CmpCompanyCode, TBTTAXCODE


sp_geteeid '01018735'  

select eeddedcode, eedstartdate, eedbenstatus, eedstopdate, eedbenstopdate from empded where eedeeid ='EXW23J00U060'


-- commit 

select distinct tbtgennumber, tbttaxcode, TbtNotSubjectToTax into #temp from t_batch where tbttaxcode in ('USMEDEE', 'USSOCEE') 
update #temp set tbttaxcode=  'USMEDER' where  tbttaxcode=  'USMEDEE' 
update #temp set tbttaxcode=  'USSOCER' where  tbttaxcode=  'USSOCEE' 
 
update t_batch set TbtNotSubjectToTax='Y' from t_batch 
join #temp on #temp.tbttaxcode= t_batch.tbttaxcode and #temp.tbtgennumber= t_batch.tbtgennumber