select * from ACE_FEDDEPENDENTAMT  -- 218




--EEID From SSN EmpPers
update ACE_FEDDEPENDENTAMT  set eeid=eepeeid from emppers 
join  ACE_FEDDEPENDENTAMT  on right('000000000' + rtrim(replace(ssn , '-', '')), 9 )= eepssn

select * from ACE_FEDDEPENDENTAMT where eeid is null  -- 218

sp_geteeid '732162246' 


--COID From EmpComp
update ACE_FEDDEPENDENTAMT set coid=eeccoid  
select distinct eeccoid from empcomp 
join  ACE_FEDDEPENDENTAMT  on eeid=eeceeid and empno =eecempno 
 

 update ACE_FEDDEPENDENTAMT set coid='RERAE'    

 select * into dbo.ACEBkup_EmpTax_20231003 from empTax 

 select eettaxcode, eetDependentAmt  from emptax where eeteeid ='EXW16L014060' and eetcoid = 'RERAE'   and eettaxcode ='USFIT' 

 Begin Tran 
 update emptax 
		set eetDependentAmt = cast (FedDependentAmt as money) 
		--- select empno, eettaxcode ,eetDependentAmt , FedDependentAmt  
		from emptax 
		join ACE_FEDDEPENDENTAMT on eeteeid =eeid and   eetcoid = 'RERAE'  and taxcode = eettaxcode 
		where eetDependentAmt < cast (FedDependentAmt as money) 
		-- commit 