#Chi-Sqaured

library(DBI)
library(dplyr)
library(dbplyr)
library(odbc)


CASU_2019_v2 <- dbGetQuery(    conn = connection,    "select [clean_sex], [Clean_Birth_Date],[DERIVED_CLEAN_BIRTH_YEAR], 
[AGE], [Clean_Ethnicity], [Clean_Diabetes_Type],
[Clean_Diagnosis_Year], [DIABETES_DURATION] , [IMD_QUINTILE], [Diastolic_Value],[BMI],
[Cholesterol_Value], [HbA1c_mmol_Value], [HbA1c_%_Value], [Clean_Creatinine_Value], [First_CVD_in_1819],
[Diab_diag_to_CVD], [Age_at_CVD], [Diab_diag_to_Outcome], [Age_at_Outcome], [mean_bmi], [bmi_window_cvd], [Chol < 4] as 'CholunderFour',
[mean_diastolic], [BP_window_cvd], [mean_hba1c_mmol],  [mean_hba1c_percent],[hba1c_window_cvd], [BP <= 140/80 TT] as 'BPunderOneFortyEight',

[Systolic_Value],
case when Systolic_Value < 130 then '<130'
when Systolic_Value < 140 then '130-<140'
when Systolic_Value < 150 then '140-<150'
when Systolic_Value > 150 then '>150'
else 'other'
end as 'Systolic_Cat'

,[mean_systolic]
,case when [mean_systolic] < 130 then '<130'
when [mean_systolic] < 140 then '130-<140'
when [mean_systolic] < 150 then '140-<150'
when [mean_systolic] > 150 then '>150'
else 'other'
end as 'Mean_Systolic_Cat',

[mean_chol], 
case when [mean_chol] < 3 then '<3'
when [mean_chol] < 4 then '3to4'
when [mean_chol] < 5 then '4to5'
when [mean_chol]> 5 then '>5'
else 'other'
end as 'Mean_Chol_Cat',

[chol_window_cvd], [Diab_Durat_to_CVD_cat], [Diab_Durat_CAT], [Age_to_CVD_cat], [AGE_CAT],
[Ethnicity_Cat], [meanHbA1c_Cat], [HbA1c_Cat_1819], [meanBMI_CAT], [BMI_CAT_1819],
[Clean_Smoking_Value], [Clean_ED_Review_Value], [Clean_ED_Offer_Value], [Clean_ED_Attend_Value]
  ,[IMD_QUINTILE]  
  ,case when statin_flag is null then 0 else statin_flag end as 'statin_flag'
  ,[All 3 TT] as 'All_three_TT' ,[All_9_CARE_PROCESSES] ,[All_8_CARE_PROCESSES]

from XXXXXXXXXXXXXXXXXXXXX
                            WHERE AGE between 20 and 79 and country = 'England' and clean_sex in (1,2) ")

head(CASU_2019)
colnames(CASU_2019_v2)
str(CASU_2019_v2)


###CHI SQAURED FOR EACH FEATURE

chi_test_sex <- chisq.test(table(CASU_2019_v2$First_CVD_in_1819, CASU_2019_v2$clean_sex))
chi_test_systolic <- chisq.test(table(CASU_2019_v2$First_CVD_in_1819, CASU_2019_v2$Mean_Systolic_Cat))
chi_test_BMI <- chisq.test(table(CASU_2019_v2$First_CVD_in_1819, CASU_2019_v2$meanBMI_CAT))
chi_test_glucose <- chisq.test(table(CASU_2019_v2$First_CVD_in_1819, CASU_2019_v2$meanHbA1c_Cat))
chi_test_ethnic <- chisq.test(table(CASU_2019_v2$First_CVD_in_1819, CASU_2019_v2$Ethnicity_Cat))
chi_test_diab_dur <- chisq.test(table(CASU_2019_v2$First_CVD_in_1819, CASU_2019_v2$Diab_Durat_CAT))
chi_test_IMD <- chisq.test(table(CASU_2019_v2$First_CVD_in_1819, CASU_2019_v2$IMD_QUINTILE))
chi_test_age <- chisq.test(table(CASU_2019_v2$First_CVD_in_1819, CASU_2019_v2$AGE_CAT))
chi_test_smoking <- chisq.test(table(CASU_2019_v2$First_CVD_in_1819, CASU_2019_v2$Clean_Smoking_Value))
chi_test_all_three <- chisq.test(table(CASU_2019_v2$First_CVD_in_1819, CASU_2019_v2$All_three_TT))
chi_test_all_nine <- chisq.test(table(CASU_2019_v2$First_CVD_in_1819, CASU_2019_v2$All_9_CARE_PROCESSES))
chi_test_all_eight <- chisq.test(table(CASU_2019_v2$First_CVD_in_1819, CASU_2019_v2$All_8_CARE_PROCESSES))
chi_test_bp_under <- chisq.test(table(CASU_2019_v2$First_CVD_in_1819, CASU_2019_v2$BPunderOneFortyEight))
chi_test_ED_rev <- chisq.test(table(CASU_2019_v2$First_CVD_in_1819, CASU_2019_v2$Clean_ED_Review_Value))
chi_test_ED_offer <- chisq.test(table(CASU_2019_v2$First_CVD_in_1819, CASU_2019_v2$Clean_ED_Offer_Value))
chi_test_ED_attend <- chisq.test(table(CASU_2019_v2$First_CVD_in_1819, CASU_2019_v2$Clean_ED_Attend_Value))
chi_test_statin <- chisq.test(table(CASU_2019_v2$First_CVD_in_1819, CASU_2019_v2$statin_flag))
chi_test_Chol <- chisq.test(table(CASU_2019_v2$First_CVD_in_1819, CASU_2019_v2$Mean_Chol_Cat))



chi_test_age$p.value
chi_test_sex$p.value
chi_test_systolic$p.value
chi_test_BMI$p.value
chi_test_ethnic$p.value
chi_test_diab_dur$p.value
chi_test_IMD$p.value
chi_test_smoking$p.value
chi_test_all_three$p.value
chi_test_all_eight$p.value
chi_test_all_nine$p.value
chi_test_bp_under$p.value
chi_test_ED_rev$p.value
chi_test_ED_offer$p.value
chi_test_ED_attend$p.value
chi_test_statin$p.value
chi_test_Chol$p.value


Pvalues <- c(chi_test_age$p.value, chi_test_sex$p.value, chi_test_systolic$p.value, 
             chi_test_BMI$p.value,chi_test_ethnic$p.value, chi_test_diab_dur$p.value, 
             chi_test_IMD$p.value,chi_test_smoking$p.value, chi_test_all_three$p.value, 
             chi_test_all_eight$p.value, chi_test_all_nine$p.value, chi_test_bp_under$p.value, 
             chi_test_ED_rev$p.value,chi_test_ED_offer$p.value, chi_test_ED_attend$p.value, 
             chi_test_statin$p.value, chi_test_Chol$p.value)


Features <- c('Age', 'Sex', 'Systolic', 'BMI', 'Ethnicity', 'Duration', 'IMD', 'Smoking', 
              'All 3 TT', '8 care processes', '9 care processes', 'BP<140/80', 
              'ED_rev', 'ED_offer', 'ED_attend', 'Statin', 'Choelsterol')


barplot(Pvalues, main="Chi squared, CVD vs No CVD",
        xlim = c(0, 0.2),
        horiz=TRUE, names.arg=Features, cex.names=0.8,
        xlab="P-value",
        #ylab="Feature"
        )
abline(v=0.05, lty=2)





chi_test_sex 
chi_test_systolic
chi_test_BMI 
chi_test_glucose 
chi_test_ethnic 
chi_test_diab_dur 
chi_test_IMD 
chi_test_age 
chi_test_smoking 
chi_test_all_three 
chi_test_all_nine 
chi_test_all_eight 
chi_test_bp_under 
chi_test_ED_rev 
chi_test_ED_offer 
chi_test_ED_attend 
chi_test_statin 
chi_test_Chol 