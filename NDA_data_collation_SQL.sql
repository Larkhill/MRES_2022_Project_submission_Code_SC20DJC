

---Generate a cohort based on the 2018-19 audit year.
---Selecting people whose heart failure was in 2018-19.
---Using fixed features from the 2018-19 audit year, e.g. ethncity.
---Reclaculate age and diabetes duration to time of first CVD event.
---Then going back through the audit years to establish an average reading for various measures.


----------------This code identifies the first admission for CVD using 3 different sources
  drop table #First_CVD_admission_date
  select distinct a.ID, min(a.ADMIDATE) as 'ADMIDATE' , 'DC_MRES_COMPS' as 'Origin' 
  into #First_CVD_admission_date
  FROM [XXXXXXX].[XXXXX].[DC_MRES_COMPS] as a 
  group by a.ID

  union 
  select b.ID, MIN(b.admidate) as 'ADMIDATE', 'MASTER_COMPS_HESPEDW' as 'Origin'
  FROM [XXXXXXX].[XXXXX].[MASTER_COMPS_HESPEDW] as b
  where b.COUNTRY = 'England'	and 
	b.COMPLICATION not in ('DKA','Major Amputation','Minor Amputation','RRT','Mortality_DKA_FirstEver',
							'Mortality_DKA','Mortality_DKA_PrimaryFirstEver','Mortality_DKA_Primary')
  group by b.ID

  union 

  select cast(c.NHS_Number as varchar), c.Clean_IHD_Date, 'NDA_1819' as 'Origin'
  FROM [XXXXXXX].[XXXXX]..[NDA_ANALYSIS_DATA_1819_v7] as c
  where c.Clean_IHD_Date is not null



  ----Identify the first ever CVD admission (from all sources)
  DROP TABLE #First_CVD_admission
  select a.ID as 'nhs_number', min(a.ADMIDATE) as 'Min_admidate'
  into #First_CVD_admission
  from #First_CVD_admission_date as a
  group by a.ID



----------------------------------------------------------------------------------------------
------------------------STAGE COMPLETE--------------------------------------------------------
----------------------------------------------------------------------------------------------

--Identify those with type 1 diabetes in the 2018-19 audit year (will be re-used later)
---Type 1 Diabetes 2018-19
---NHS Number only
drop table #1819_Type1_NHS
select NHS_Number
into #1819_Type1_NHS
from [[XXXXXXX].[XXXXX].[NDA_ANALYSIS_DATA_1819_v7] where Clean_Diabetes_Type = 1

---Type 1 Diabetes 2018-19
---Relevant fields
drop table #1819_Type1
select *
into #1819_Type1
from [XXXXXXX].[XXXXX].[NDA_ANALYSIS_DATA_1819_v7] as a where Clean_Diabetes_Type = 1



--Recalculate age to be age of CVD onset.
drop table #1819_Type1_
select a.*, b.nhs_number as 'NHS_Num',
case when b.nhs_number is null then 0 else 1 end as 'First_CVD_in_1819',
case when b.nhs_number is not null then DATEDIFF(year,a.Clean_Diagnosis_Date, b.Min_admidate ) else null end as 'Diab_diag_to_CVD',
case when b.nhs_number is not null then DATEDIFF(year,a.Clean_Birth_Date, b.Min_admidate ) else null end as 'Age_at_CVD',
case 
	when b.nhs_number is not null then DATEDIFF(year,a.Clean_Diagnosis_Date, b.Min_admidate ) 
	when b.nhs_number is null then DATEDIFF(year, a.Clean_Diagnosis_Date, '2019-03-31')
	else null end as 'Diab_diag_to_Outcome', --age to cvd or survival
case 
	when b.nhs_number is not null then DATEDIFF(year,a.Clean_Birth_Date, b.Min_admidate ) 
	when b.nhs_number is null then DATEDIFF(year, a.Clean_Birth_Date, '2019-03-31')
	else null end as 'Age_at_Outcome' --age to cvd or survival
into #1819_Type1_
from #1819_Type1 as a 
left join 
	(select * from #First_CVD_admission
	where Min_admidate between '2018-01-01' and '2019-03-31'
	----125k rows, all types diabetes
	)as b
on a.nhs_number = b.nhs_number 
---269K rows of type 1 diabetes
---

--Recalculate diabetes duration to onset of CVD.
--select count(a.First_CVD_in_1819), sum(a.First_CVD_in_1819) from #1819_Type1_ as a 



---Identify NHS Numbers where CVD prior to 2018-19
drop table #CVD_Pre_1819
select *
into #CVD_Pre_1819
from #First_CVD_admission as a
	where Min_admidate < '2018-01-01'

---Identify NHS Numbers where CVD after 2018-19
drop table #CVD_Post_1819
select *
into #CVD_Post_1819
from #First_CVD_admission as a
	where Min_admidate >= '2019-04-01'


---count how any had a pre 01-04-2018 admission
select count(*) from #CVD_Pre_1819 as a
inner join
(select a.NHS_Number from #1819_Type1_ as a) as b
on a.nhs_number = cast(b.NHS_Number as varchar)
---79K

---count how any had a pre 01-04-2018 admission
select count(*) from #CVD_Post_1819 as a
inner join
(select a.NHS_Number from #1819_Type1_ as a) as b
on a.nhs_number = cast(b.NHS_Number as varchar)
---8K

----Collate all multiple readings - remove the first 6 months. generate a window of up to 4 years. 



---------------------------------------
-----BMI-------------------------------
drop table #multi_bmi
SELECT  --'2016-17' as 'Audit_year',
	[nhs_number]
	,[bmi_date]
	,[bmi_value]
into #multi_bmi
FROM [XXXXXXX].[XXXXX].[multiple_readings_BMI_1617]
where nhs_number in (select * from #1819_Type1_NHS)

union
SELECT --audit_year,
[nhs_number]
	,[bmi_date]
	,[bmi_value]
FROM [XXXXXXX].[XXXXX].[multiple_readings_BMI_1718]
where nhs_number in (select * from #1819_Type1_NHS)

union
SELECT --audit_year,
[nhs_number]
	,[bmi_date]
	,[bmi_value]
FROM [XXXXXXX].[XXXXX].[multiple_readings_BMI_1819]
where nhs_number in (select * from #1819_Type1_NHS)
-------------------------------------------------------------------

--select top 10 * from #multi_bmi as a order by a.nhs_number

-------------BMI table----------------
-------------Bring in CVD_info--------------
drop table #bmi_all_dates
Select a.*, b.nhs_number as 'NHS_Num_2' ,b.Min_admidate,
case when  b.nhs_number is not null then 1 else 0 end as 'cvd_admin',
case when  b.nhs_number is not null
	and a.bmi_date < DATEADD(month, -6, b.Min_admidate)
	and a.bmi_date > DATEADD(year, -5, b.Min_admidate)
	then 1 --is cvd and in the window
	when b.nhs_number is null 
	and a.bmi_date < DATEADD(month, -6, '2019-03-31')
	and a.bmi_date > DATEADD(year, -5, '2019-03-31')
	then 2 --is not cvd but in equivalent period
	else 0 ---we don't want to retain the ZEROs in analysis, so exclude from the mean calcuations
	end as bmi_window_cvd --this is a bmi reading for someone with cvd in the relevant window.
into #bmi_all_dates
from #multi_bmi as a
left join #First_CVD_admission as b
on cast(a.nhs_number as varchar) = b.nhs_number  --and 
--a.bmi_date < DATEADD(month, -6, b.Min_admidate)
--and a.bmi_date > DATEADD(year, -5, b.Min_admidate)	

---
--select * from #bmi_all_dates as a where a.NHS_Num_2 is not null---

------------Select ALL BMI dates---------------------
-----No need to select Max date for BMI Reading------
----Just Select average date per person--------------



-------------------------------------------
---------BP--------------------------------
drop table #BP_multi 
SELECT --'2016-17' as 'Audit_year',
	  [NHS_Number]
      ,[Systolic_Date] as 'BP_DATE'
      ,[systolic_value]
      ,[diastolic_value]
into #BP_multi 
FROM [XXXXXXX].[XXXXX].[multiple_readings_BP_1617]

union
SELECT --[audit_year],
      [NHS_number]
      ,[BP_DATE]
      ,[SYSTOLIC_VALUE]
      ,[DIASTOLIC_VALUE]
FROM [XXXXXXX].[XXXXX].[multiple_readings_BP_1718]

union
SELECT --[audit_year],
	  [NHS_Number]
      ,[BP_DATE]
      ,[SYSTOLIC_VALUE]
      ,[DIASTOLIC_VALUE]
FROM [XXXXXXX].[XXXXX].[multiple_readings_BP_1819]
-------------------------------------------------------------------

--select top 100 * from #BP_multi


-------------Join BP to----------------
-------------CVD_1st_Admis--------------
drop table #BP_all_dates
Select a.*, b.nhs_number as 'NHS_Num_2' ,b.Min_admidate,
case when  b.nhs_number is not null then 1 else 0 end as 'cvd_admin',
case when  b.nhs_number is not null
	and a.bp_date < DATEADD(month, -6, b.Min_admidate)
	and a.bp_date > DATEADD(year, -5, b.Min_admidate)
	then 1 --is cvd and in the window
	when b.nhs_number is null 
	and a.bp_date < DATEADD(month, -6, '2019-03-31')
	and a.bp_date > DATEADD(year, -5, '2019-03-31')
	then 2 --is not cvd but in equivalent period
	else 0 ---we don't want to retain the ZEROs in analysis, so exclude from the mean calcuations
	end as BP_window_cvd
into #BP_all_dates
from #BP_multi as a
left join #First_CVD_admission as b
on cast(a.nhs_number as varchar) = b.nhs_number 
--and a.BP_DATE < DATEADD(month, -6, b.Min_admidate)
--and a.BP_DATE > DATEADD(year, -5, b.Min_admidate)


--select top 10 * from #bp_all_dates as a where a.NHS_Num_2 is not null
------BP_ALL_DATES is the table to use-----------




-----------------------------------------------
-------------Cholesterol-----------------------
DROP TABLE #Chol_multi
SELECT --'2016-17' as 'Auidt_year',
	  [nhs_number]
      ,[cholesterol_date]
      ,[cholesterol_value]
into #Chol_multi
FROM [XXXXXXX].[XXXXX].[multiple_readings_chol_1617]

union
SELECT --[audit_year],
      [NHS_NUMBER]
      ,[CHOLESTEROL_DATE]
      ,[chol_value]
FROM [XXXXXXX].[XXXXX].[multiple_readings_chol_1718]

union
SELECT --[audit_year],
       [NHS_NUMBER]
      ,[CHOLESTEROL_DATE]
      ,[chol_value]
FROM [XXXXXXX].[XXXXX].[multiple_readings_chol_1819]
---------------------------------------------------------------------

-------------Join Chol to----------------
-------------CVD_1st_Admis--------------
drop table #Chol_all_dates
Select a.*, b.nhs_number as 'NHS_Num_2' ,b.Min_admidate,
case when  b.nhs_number is not null then 1 else 0 end as 'cvd_admin',
case when  b.nhs_number is not null
	and a.cholesterol_date < DATEADD(month, -6, b.Min_admidate)
	and a.cholesterol_date > DATEADD(year, -5, b.Min_admidate)
	then 1 --is cvd and in the window
	when b.nhs_number is null 
	and a.cholesterol_date < DATEADD(month, -6, '2019-03-31')
	and a.cholesterol_date > DATEADD(year, -5, '2019-03-31')
	then 2 --is not cvd but in equivalent period
	else 0 ---we don't want to retain the ZEROs in analysis, so exclude from the mean calcuations
	end as chol_window_cvd
into #Chol_all_dates
from #Chol_multi as a
left join #First_CVD_admission as b
on cast(a.nhs_number as varchar) = b.nhs_number 
--and a.cholesterol_date < DATEADD(month, -6, b.Min_admidate)
--and a.cholesterol_date > DATEADD(year, -5, b.Min_admidate)


--select top 10 * from #Chol_all_dates as a where a.NHS_Num_2 is not null




-----------------------------------------------
-------------------HbA1c-----------------------
drop table #HbA1C_multi
SELECT --'2016-17' as 'Audit_year',
	  [nhs_number]
      ,[HBA1c_Date]
      ,[hbA1c_mmol_value]
      ,[HbA1c_%_Value]
	  into #HbA1C_multi
FROM [XXXXXXX].[XXXXX]..[multiple_readings_HbA1c_1617]
union

SELECT --[audit_year],
      [NHS_NUMBER]
      ,[HbA1c_DATE]
      ,[HbA1c_mmol_value]
      ,[HbA1c_%_value]
FROM [XXXXXXX].[XXXXX].[multiple_readings_HbA1c_1718]
union

SELECT --[audit_year],
      [NHS_NUMBER]
      ,[HbA1c_DATE]
      ,[HbA1c_mmol_value]
      ,[HbA1c_%_value]
FROM [XXXXXXX].[XXXXX].[multiple_readings_HbA1c_1819]
---------------------------------------------------------------------


-------------Join HbA1c to----------------
-------------CVD_1st_Admis----------------
drop table #HbA1C_all_dates
Select a.*, b.nhs_number as 'NHS_Num_2' ,b.Min_admidate,
case when  b.nhs_number is not null then 1 else 0 end as 'cvd_admin',
case when  b.nhs_number is not null
	and a.HBA1c_Date < DATEADD(month, -6, b.Min_admidate)
	and a.HBA1c_Date > DATEADD(year, -5, b.Min_admidate)
	then 1 --is cvd and in the window
	when b.nhs_number is null 
	and a.HBA1c_Date < DATEADD(month, -6, '2019-03-31')
	and a.HBA1c_Date > DATEADD(year, -5, '2019-03-31')
	then 2 --is not cvd but in equivalent period
	else 0 ---we don't want to retain the ZEROs in analysis, so exclude from the mean calcuations
	end as hba1c_window_cvd
into #HbA1C_all_dates
from #HbA1C_multi as a
left join #First_CVD_admission as b
on cast(a.nhs_number as varchar) = b.nhs_number 
--and a.HBA1c_Date < DATEADD(month, -6, b.Min_admidate)
--and a.HBA1c_Date > DATEADD(year, -5, b.Min_admidate)

select top 10 * from #HbA1C_all_dates as a where a.NHS_Num_2 is not null



-----check tables
--select top 10 * from #BP_all_dates as a --where a.[diastolic_value] is null
--select top 10 * from #bmi_all_dates
--select top 10 * from #Chol_all_dates
--select top 10 * from #HbA1C_all_dates as a --where a.[HbA1c_%_Value] is not null


--select * from #HbA1C_all_dates where [HbA1c_%_Value] is not null



--select * from #bmi_all_dates --where [DIASTOLIC_VALUE] is null

------------Calc mean BMI over the 4.5 year prediction window--------
drop table #mean_bmi
select a.nhs_number, a.Min_admidate, a.bmi_window_cvd,a.cvd_admin,  AVG(a.bmi_value) as mean_bmi
into #mean_bmi
from #bmi_all_dates as a 
where a.bmi_window_cvd > 0
group by 
	a.nhs_number, 
	a.Min_admidate,
	a.bmi_window_cvd,
	a.cvd_admin


------------Calc mean BP over the 4.5 year prediction window---------
drop table #mean_bp
select a.nhs_number, a.Min_admidate, a.bp_window_cvd, a.cvd_admin, AVG(a.diastolic_value) as mean_diastolic, AVG(a.systolic_value) as mean_systolic
into #mean_bp
from #BP_all_dates as a 
where a.BP_window_cvd > 0
group by 
	a.nhs_number, 
	a.Min_admidate,
	a.bp_window_cvd,
	a.cvd_admin

------------Calc mean HbA1c over the 4.5 year prediction window---------
drop table #mean_HbA1c
select a.nhs_number, a.Min_admidate, a.hba1c_window_cvd, a.cvd_admin, AVG(a.hbA1c_mmol_value) as mean_hba1c_mmol, AVG(a.[HbA1c_%_Value]) as mean_hba1c_percent
into #mean_HbA1c
from #HbA1C_all_dates as a 
where a.hba1c_window_cvd > 0
group by 
	a.nhs_number,
	a.Min_admidate,
	a.hba1c_window_cvd,
	a.cvd_admin



------------Calc mean Chol over the 4.5 year prediction window---------
drop table #mean_chol
select a.nhs_number, a.Min_admidate, a.chol_window_cvd, a.cvd_admin, AVG(a.cholesterol_value) as mean_chol
into #mean_chol
from #Chol_all_dates as a 
where a.chol_window_cvd > 0
group by 
	a.nhs_number, 
	a.Min_admidate,
	a.chol_window_cvd,
	a.cvd_admin

--select * from (
--select a.nhs_number, count(*) as 'counts' from #mean_chol as a 
--group by a.NHS_Number) as b
--where b.counts > 1
--select top 10 * from #mean_BMI
	
--select top 20 * from [XXXXXXX].[XXXXX] as a 

---Pull together all the last readings before the 
drop table #Mean_Readings_for_FirstCVD
select a.* , b.mean_bmi, b.bmi_window_cvd,
c.mean_diastolic, c.mean_systolic, c.BP_window_cvd,
d.mean_hba1c_mmol, d.mean_hba1c_percent, d.hba1c_window_cvd
, e.mean_chol, e.chol_window_cvd
into #Mean_Readings_for_FirstCVD
from #1819_Type1_ as a 
left join #mean_BMI as b on a.nhs_number = b.nhs_number
left join #mean_BP as c on a.nhs_number = c.nhs_number 
left join #mean_HbA1C as d on a.nhs_number = d.nhs_number
left join #mean_CHOL as e on a.nhs_number = e.nhs_number
----for 2018-19 only
--where a.Min_admidate between '2018-01-01' and '2019-03-31'
----date restriction rmeoved as it does not apply 


--select count(*) from #Mean_Readings_for_FirstCVD as a where a.NHS_Num is null
--5K cases where 1st CVD is in 2018-19.
--265 cases where no CVD in 2018-19

---DROP cases where 1st CVD happened before (not after) 2018-19
--delete from #Mean_Readings_for_FirstCVD where [NHS_Number] in (select b.nhs_number from  #CVD_Post_1819 as b)
delete from #Mean_Readings_for_FirstCVD where cast([NHS_Number] as varchar) in (select b.nhs_number from  #CVD_Pre_1819 as b)

---TEST successfully removed (passed, i.e. returned blank)
select count(*) from #Mean_Readings_for_FirstCVD as a 
--where a.NHS_Number in (select b.nhs_number from  #CVD_Post_1819 as b)
---190k remaining

---TEST successfully removed (passed, ie. returned blank)
select * from #Mean_Readings_for_FirstCVD as a 
where cast(a.NHS_Number as varchar) in (select b.nhs_number from  #CVD_Pre_1819 as b)
--where Min_admidate between '2018-01-01' and '2019-03-31'
--80K rows removed becuase had CVD prior to 2018-19 (1-jAN 2018-19) 


--select top 10 * from #Mean_Readings_for_FirstCVD


--Add in the Diabetes duration categories

DROP TABLE #DC_Readings_for_FirstCVD_1819
select *, 
case when 
	a.Diab_diag_to_CVD < 1 then '<1'
	when a.Diab_diag_to_CVD < 5 then '1-4'
	when a.Diab_diag_to_CVD < 10 then '5-9'
	when a.Diab_diag_to_CVD < 20 then '10-19'
	when a.Diab_diag_to_CVD < 30 then '20-29'
	when a.Diab_diag_to_CVD < 40 then '30-39'
	when a.Diab_diag_to_CVD < 50 then '40-49'
	when a.Diab_diag_to_CVD >= 50 then '50+'
	when a.Diab_diag_to_CVD is null then 'n/a'
	else 'other'
	end as 'Diab_Durat_to_CVD_cat',
case when 
	a.DIABETES_DURATION < 5 then '0-4'
	when a.DIABETES_DURATION < 10 then '5-9'
	when a.DIABETES_DURATION < 20 then '10-19'
	when a.DIABETES_DURATION < 30 then '20-29'
	when a.DIABETES_DURATION < 40 then '30-39'
	when a.DIABETES_DURATION < 50 then '40-49'
	when a.DIABETES_DURATION >= 50 then '50+'
	when a.DIABETES_DURATION is null then 'n/a'
	else 'other'
	end as 'Diab_Durat_CAT',
case when 
	a.Age_at_CVD < 20 then '<20'
	when a.Age_at_CVD < 25 then '20-24'
	when a.Age_at_CVD < 30 then '25-29'
	when a.Age_at_CVD < 35 then '30-34'
	when a.Age_at_CVD < 40 then '35-39'
	when a.Age_at_CVD < 45 then '40-44'
	when a.Age_at_CVD < 50 then '45-49'
	when a.Age_at_CVD < 55 then '50-54'
	when a.Age_at_CVD < 60 then '55-59'
	when a.Age_at_CVD < 65 then '60-64'
	when a.Age_at_CVD < 70 then '65-69'
	when a.Age_at_CVD < 75 then '70-74'
	when a.Age_at_CVD < 80 then '75-79'
	when a.Age_at_CVD >= 80 then '80+'
	when a.Age_at_CVD is null then 'n/a'
	else 'other'
	end as 'Age_to_CVD_cat',
case when 
	a.AGE < 20 then '<20'
	when a.AGE < 25 then '20-24'
	when a.AGE < 30 then '25-29'
	when a.AGE < 35 then '30-34'
	when a.AGE < 40 then '35-39'
	when a.AGE < 45 then '40-44'
	when a.AGE < 50 then '45-49'
	when a.AGE < 55 then '50-54'
	when a.AGE < 60 then '55-59'
	when a.AGE < 65 then '60-64'
	when a.AGE < 70 then '65-69'
	when a.AGE < 75 then '70-74'
	when a.AGE < 80 then '75-79'
	when a.AGE >= 80 then '80+'
	when a.AGE is null then 'n/a'
	else 'other'
	end as 'AGE_CAT',
case when
	a.Clean_Ethnicity in ('A', 'B', 'C', 'T') then 'White'
	when a.Clean_Ethnicity in ('H', 'J', 'K', 'L','R') then 'Asian'
	when a.Clean_Ethnicity in ('M', 'N', 'P') then 'Black'
	when a.Clean_Ethnicity in ('D', 'E', 'F', 'G') then 'Mixed'
	when a.clean_ethnicity in ('S','W') then 'Other'
	else 'unknown'
	end as 'Ethnicity_Cat',
case 
	when a.mean_hba1c_mmol <= 48 then 'HbA1c<=48'
	when a.mean_hba1c_mmol <= 53 then 'HbA1c48-53'
	when a.mean_hba1c_mmol <= 58 then 'HbA1c53-58'
	when a.mean_hba1c_mmol <= 70 then 'HbA1c58-70'
	when a.mean_hba1c_mmol <= 86 then 'HbA1c70-86'
	when a.mean_hba1c_mmol > 86 then 'HbA1c>86'
	when a.mean_hba1c_mmol is null then 'Unknown HbA1c'
	end as 'meanHbA1c_Cat',
case 
	when a.HbA1c_mmol_Value <= 48 then 'HbA1c<=48'
	when a.HbA1c_mmol_Value <= 53 then 'HbA1c48-53'
	when a.HbA1c_mmol_Value <= 58 then 'HbA1c53-58'
	when a.HbA1c_mmol_Value <= 70 then 'HbA1c58-70'
	when a.HbA1c_mmol_Value <= 86 then 'HbA1c70-86'
	when a.HbA1c_mmol_Value > 86 then 'HbA1c>86'
	when a.HbA1c_mmol_Value is null then 'Unknown HbA1c'
	end as 'HbA1c_Cat_1819',
case 
	when a.mean_bmi >= 40 then 'Severe_Obese'
	when a.mean_bmi >= 30 then 'Obese'
	when a.mean_bmi >=25 then 'Overweight'
	when a.mean_bmi >=18.5 then 'Healthy'
	when a.mean_bmi < 18.5 then 'Underweight'
	else 'other'
	end as 'meanBMI_CAT',
case 
	when a.bmi >= 40 then 'Severe_Obese'
	when a.bmi >= 30 then 'Obese'
	when a.bmi >=25 then 'Overweight'
	when a.bmi >=18.5 then 'Healthy'
	when a.bmi < 18.5 then 'Underweight'
	else 'other'
	end as 'BMI_CAT_1819'
into #DC_Readings_for_FirstCVD_1819
from #Mean_Readings_for_FirstCVD as a


