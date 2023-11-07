select coid , eeid from ace_DED --4466

update ace_ded set coid =cmpcoid from company 
join ace_ded on cocode =cmpcompanycode 


update ace_ded set eeid =eepeeid from emppers  
join  ace_ded on right('000000000' + rtrim(replace(ssn , '-', '')), 9 )= eepssn 

 
 ---  EEAmt <> eedeeamt 
 
select  cmpcompanycode as CoCode
  , eecempno as EmpNo
  --, Eepssn as SSN
  , eepnamelast as LastName
  , eepnamefirst as FirstName
  , eecemplstatus as SrcEmplStatus
  , eecemplstatus as EmplStatus
   , eeddedcode as DedCode
 ,   isnull (EEAmt,0) as SrcEEAMT
,  isnull (ErAmt,0)  as SrcERAMT
,  isnull (eecalcrateorpct,0)    as SrcPct
, isnull(GoalAmount, 0)  as SrcGoal 
 , eedeeamt 
, eederamt 
, eedeecalcrateorpct 
, eedeegoalamt 
   , eedbenstatus as BenStatus
  , 'EEAmt does not match,  due to rounding' as [Additional Information] 
 from emppers 
join empcomp  on eepeeid=eeceeid 
join company on eeccoid=cmpcoid
join empded on eeceeid=eedeeid and eeccoid=eedcoid
join ace_ded on coid =eedcoid and eeid =eedeeid and eeddedcode =deductioncode 
  where eeamt <> EedEEAmt
order by cmpcompanycode,   eepnamelast, eepnamefirst, eeddedcode

 ---  PCT <> eedeecalcrateorpct 

select  cmpcompanycode as CoCode
  , eecempno as EmpNo
  --, Eepssn as SSN
  , eepnamelast as LastName
  , eepnamefirst as FirstName
  , eecemplstatus as SrcEmplStatus
  , eecemplstatus as EmplStatus
   , eeddedcode as DedCode
    ,   isnull(EEAmt, 0) as SrcEEAMT
,   isnull(ErAmt, 0) as SrcERAMT
,  eecalcrateorpct as SrcPct
, isnull(GoalAmount, 0)  as SrcGoal 
 , eedeeamt 
, eederamt 
, eedeecalcrateorpct 
, eedeegoalamt 
   , eedbenstatus as BenStatus
  , 'EEPCT does not match, probably due to duplicate' as [Additional Information] 
 from emppers 
join empcomp  on eepeeid=eeceeid 
join company on eeccoid=cmpcoid
join empded on eeceeid=eedeeid and eeccoid=eedcoid
 join ace_ded on coid =eedcoid and eeid =eedeeid and eeddedcode =deductioncode 
 where eedeecalcrateorpct <> eecalcrateorpct
order by cmpcompanycode,   eepnamelast, eepnamefirst, eeddedcode


 
 
 --- dedcode missing 


  select  CoCode  
  ,   EmpNo
  --,  SSN
  ,  LastName
  ,  FirstName
  , eecemplstatus as SrcEmplStatus
  , eecemplstatus as EmplStatus
   , DeductionCode as SrcDedCode
   , eeddedcode 
 ,   EEAmt  as SrcEEAMT
 , EECalcRateOrPct as SrcPCT 
, eedeeamt 
  , 'Missing Deduction' as [Additional Information] 
 from ace_ded  
  join empcomp  on coid =eeccoid and eeid =eeceeid 
left outer join empded on eeceeid=eedeeid and eeccoid=eedcoid and DeductionCode = eeddedcode 
   where  eeddedcode is null 

