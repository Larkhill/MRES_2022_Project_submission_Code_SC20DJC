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

from XXXXXXXXXXXXXXXXXXX
                            WHERE AGE between 20 and 79 and country = 'England' and clean_sex in (1,2) ")

head(CASU_2019)
colnames(CASU_2019_v2)
str(CASU_2019_v2)

#Select only those categorical columns need for the analysis.
select.me <- c('clean_sex','IMD_QUINTILE', "First_CVD_in_1819","Diab_Durat_CAT", "AGE_CAT", 
               "Ethnicity_Cat", "meanHbA1c_Cat","HbA1c_Cat_1819"  , "meanBMI_CAT",  "BMI_CAT_1819", "Mean_Systolic_Cat",
               'BPunderOneFortyEight', 'CholunderFour', 'Systolic_Cat', 'Mean_Chol_Cat','Clean_Smoking_Value', 'Clean_ED_Review_Value',
               'Clean_ED_Offer_Value', 'Clean_ED_Attend_Value', 'IMD_QUINTILE'  , 'statin_flag' , 'All_three_TT' , 'All_9_CARE_PROCESSES' ,
               'All_8_CARE_PROCESSES')
CASU_2019_Cat <- CASU_2019_v2[,select.me]


CASU_2019_Cat
str(CASU_2019_Cat)


# create grid of all possible combinations of true/false values for 5 variables
input <- expand.grid(data.frame(matrix(rep(c(TRUE, FALSE), 14), nrow = 2)))



names <- c("as.factor(clean_sex)","as.factor(IMD_QUINTILE)","as.factor(Diab_Durat_CAT)","as.factor(AGE_CAT)",
           "as.factor(Ethnicity_Cat)", "as.factor(meanHbA1c_Cat)",  "as.factor(meanBMI_CAT)", 
           "as.factor(Mean_Chol_Cat)", "as.factor(Mean_Systolic_Cat)",
           "as.factor(Clean_Smoking_Value)", "as.factor(Clean_ED_Attend_Value)", "statin_flag",
           "as.factor(All_three_TT)", "as.factor(All_8_CARE_PROCESSES)")

names(input) <- names

#input <-input[-16384,]

#lmlist <- apply(input, 1, function(x) {as.formula(paste(c("as.factor(First_CVD_in_1819) ~", names[x]), collapse = "+"))} ) 

# run each linear model (using generated data) in the list and record model AIC
#AICall <- sapply(lmlist, function(x) {AIC(glm(x, data = CASU_2019_Cat, family = binomial))} )


# display minimum AIC & which model number produced it
#min(AICall); which(AICall == min(AICall))

# display model formula that produces minimum AIC
#lmlist[[which(AICall == min(AICall))]]

best_mod <- glm(as.factor(First_CVD_in_1819) ~ +as.factor(IMD_QUINTILE) + as.factor(Diab_Durat_CAT) + 
                      as.factor(AGE_CAT) + as.factor(Ethnicity_Cat) + as.factor(meanHbA1c_Cat) + 
                      as.factor(meanBMI_CAT) + as.factor(Mean_Chol_Cat) + as.factor(Mean_Systolic_Cat) + 
                      as.factor(Clean_Smoking_Value) + statin_flag + as.factor(All_8_CARE_PROCESSES)
                    , data = CASU_2019_Cat, family = binomial)



CASU_2019_Cat2 <- CASU_2019_Cat

CASU_2019_Cat2$IMD_QUINTILE <- as.factor(CASU_2019_Cat$IMD_QUINTILE)
CASU_2019_Cat2$Diab_Durat_CAT <- as.factor(CASU_2019_Cat$Diab_Durat_CAT)
CASU_2019_Cat2$clean_sex <- as.factor(CASU_2019_Cat$clean_sex)
CASU_2019_Cat2$AGE_CAT <- as.factor(CASU_2019_Cat$AGE_CAT)
CASU_2019_Cat2$Ethnicity_Cat <- as.factor(CASU_2019_Cat$Ethnicity_Cat)
CASU_2019_Cat2$meanHbA1c_Cat <- as.factor(CASU_2019_Cat$meanHbA1c_Cat)
CASU_2019_Cat2$Mean_Chol_Cat <- as.factor(CASU_2019_Cat$Mean_Chol_Cat)
CASU_2019_Cat2$Mean_Systolic_Cat <- as.factor(CASU_2019_Cat$Mean_Systolic_Cat)
CASU_2019_Cat2$meanBMI_CAT <- as.factor(CASU_2019_Cat$meanBMI_CAT)
CASU_2019_Cat2$Clean_Smoking_Value <- as.factor(CASU_2019_Cat$Clean_Smoking_Value)




###Relevel the reference factors for log model
CASU_2019_Cat2$IMD_QUINTILE <- relevel(CASU_2019_Cat2$IMD_QUINTILE, ref = "5")
CASU_2019_Cat2$Diab_Durat_CAT <- relevel(CASU_2019_Cat2$Diab_Durat_CAT, ref = "20-29")
#CASU_2019_Cat2$clean_sex <- relevel(CASU_2019_Cat2$clean_sex, ref = "3")
CASU_2019_Cat2$AGE_CAT <- relevel(CASU_2019_Cat2$AGE_CAT, ref = "40-44")
CASU_2019_Cat2$Ethnicity_Cat <- relevel(CASU_2019_Cat2$Ethnicity_Cat, ref = "White")
CASU_2019_Cat2$meanHbA1c_Cat <- relevel(CASU_2019_Cat2$meanHbA1c_Cat, ref = "HbA1c48-53")
CASU_2019_Cat2$Mean_Chol_Cat <- relevel(CASU_2019_Cat2$Mean_Chol_Cat, ref = "3to4")
CASU_2019_Cat2$Mean_Systolic_Cat <- relevel(CASU_2019_Cat2$Mean_Systolic_Cat, ref = "140-<150")
CASU_2019_Cat2$meanBMI_CAT <- relevel(CASU_2019_Cat2$meanBMI_CAT, ref = "Healthy")
CASU_2019_Cat2$clean_Smoking_Value <- relevel(CASU_2019_Cat2$Clean_Smoking_Value, ref = "4")


#weights_col <- [0.9, 9.5]   ##https://stackoverflow.com/questions/60398838/how-can-i-incorporate-the-prior-weight-in-to-my-glm-function

best_mod <- glm(as.factor(First_CVD_in_1819) ~ +as.factor(IMD_QUINTILE) + as.factor(Diab_Durat_CAT) + 
                  as.factor(AGE_CAT) + as.factor(Ethnicity_Cat) + as.factor(meanHbA1c_Cat) + 
                  as.factor(meanBMI_CAT) + as.factor(Mean_Chol_Cat) + as.factor(Mean_Systolic_Cat) + 
                  as.factor(Clean_Smoking_Value) + statin_flag + as.factor(All_8_CARE_PROCESSES)
                , data = CASU_2019_Cat2, family = binomial
                #,weights = weights_col
                )


#test and train split:
  # set seed so simulations are reproducible
  set.seed(71)

# select 75K random numbers from 1:142K
select <- sample(c(1:142K), 114K, replace = FALSE)

# use random numbers to select 114k observations for training data
train <- CASU_2019_Cat2[select, ]

# use remaining 30k observations for test data
test <- CASU_2019_Cat2[-select, ]


##run on the train data, validate on the test data: 

pred_test <- predict(best_mod, test, type="response")
#pred_test <- predict(test_mod, test, type="response")

#library(caret)
#library(InformationValue)
#library(ISLR)
getwd()


#write.csv(pred_test, ".\\y_pred.csv")
#write.csv(test$First_CVD_in_1819, ".\\test_actual.csv")
          
#ConfusionMatrix(test$First_CVD_in_1819, predicted)

#library(caTools)
#y_pred = ifelse (pred_test > 0.5, 1, 0)
#cm = table (test[, 3], y_pred > 0.5)
#cm

####To Generate an AUC-ROC cureve for the model.
#https://www.projectpro.io/recipes/plot-auc-roc-curve-r
library(caTools)
#install.packages('pROC')
library(pROC)
test_roc = roc(test$First_CVD_in_1819 ~ pred_test, plot = TRUE, print.auc = TRUE)
as.numeric(test_roc$auc)


##To understand an AUC-ROC curve
#https://www.youtube.com/watch?v=4jRBRDbJemM&vl=en

#https://www.digitalocean.com/community/tutorials/plot-roc-curve-r-programming
install.packages("caret")
err_metric=function(CM)
{
  TN =CM[1,1]
  TP =CM[2,2]
  FP =CM[1,2]
  FN =CM[2,1]
  precision =(TP)/(TP+FP)
  recall_score =(FP)/(FP+TN)
  f1_score=2*((precision*recall_score)/(precision+recall_score))
  accuracy_model  =(TP+TN)/(TP+TN+FP+FN)
  False_positive_rate =(FP)/(FP+TN)
  False_negative_rate =(FN)/(FN+TP)
  print(paste("Precision value of the model: ",round(precision,2)))
  print(paste("Accuracy of the model: ",round(accuracy_model,2)))
  print(paste("Recall value of the model: ",round(recall_score,2)))
  print(paste("False Positive rate of the model: ",round(False_positive_rate,2)))
  print(paste("False Negative rate of the model: ",round(False_negative_rate,2)))
  print(paste("f1 score of the model: ",round(f1_score,2)))
}

pred_test <- predict(best_mod, test, type="response")
#pred_test <- ifelse(pred_test > 0.5,1,0) # Probability check
CM= table(test$First_CVD_in_1819 , pred_test)
print(CM)
err_metric(CM)


library(pscl)
#hitmiss(best_mod, digits = 0)
hitmiss(best_mod, digits = 0)
#hitmiss(pred_test, digits = 0)

###Get the co-efficients
# coefficients presented on the log-odds scale - not easily interpretable
summary(best_mod)

summary(best_mod)$coefficients
names(summary(best_mod))
#summary(test_mod)$coefficients


best_mod_coef <- exp(cbind(OR = coef(best_mod), confint(best_mod)))
#test_mod_coef <- exp(cbind(OR = coef(test_mod), confint(test_mod)))

#typeof(test_mod_coef)

model_outputs <- data.table::as.data.table(best_mod_coef, .keep.rownames = TRUE)
#model_outputs <- data.table::as.data.table(test_mod_coef, .keep.rownames = TRUE)
model_outputs <-model_outputs[2:53,]






############Make a list of y-labels:
Labels_List <- c(
  'IMD - 1',
  'IMD - 2',
  'IMD - 3',
  'IMD - 4',
  'Diabetes Duration - 0-4',
  #'Diabetes Duration - 1-4',
  'Diabetes Duration - 10-19',
  #'Diabetes Duration - 20-29',
  'Diabetes Duration - 30-39',
  'Diabetes Duration - 40-49',
  'Diabetes Duration - 5-9',
  'Diabetes Duration - 50+',
  'Diabetes Duration - n/a',
  'Age - 20-24',
  'Age - 25-29',
  'Age - 30-34',
  'Age - 35-39',
  #'Age - 40-44',
  'Age - 45-49',
  'Age - 50-54',
  'Age - 55-59',
  'Age - 60-64',
  'Age - 65-69',
  'Age - 70-74',
  'Age - 75-79',
  'Ethnicity - Asian',
  'Ethnicity - Black',
  'Ethnicity - Mixed',
  'Ethnicity - Other',
  'Ethnicity - unknown',
  #'Ethnicity - White',
  'HbA1c<=48',
  'HbA1c >86',
  #'HbA1c - HbA1c 48-53',
  'HbA1c 53-58',
  'HbA1c 58-70',
  'HbA1c 70-86',
  'Unknown HbA1c',
  'BMI - Obese',
  'BMI - other',
  'BMI - Overweight',
  'BMI - Severe_Obese',
  'BMI - Underweight',
  'Cholesterol - <3',
  'Cholesterol - >5',
  #'Cholesterol - 3 to 4',
  'Cholesterol - 4 to 5',
  'Cholesterol - other',
  'Systolic - <130',
  'Systolic - >150',
  'Systolic - 130-<140',
  #'Systolic - 140-<150',
  'Systolic - other',
  'Smoking - 2',
  'Smoking - 3',
  'Smoking - 4',
  'Smoking - 9',
  'statin_flag',
  'All_8_CARE_PROCESSES - 1'
)

model_outputs$Y_labels <- Labels_List

model_outputs

###################################################################################
#Try a forest plot - example
#load ggplot2
###THIS WORKS
###https://www.statology.org/forest-plot-in-r/
library(ggplot2)


#df <- data.frame(study=Best_mod_Coeffs_2$Item,
#                 index=1:53,
#                 effect=Best_mod_Coeffs_2$OR,
#                 lower=Best_mod_Coeffs_2$X2.50.,
#                 upper=Best_mod_Coeffs_2$X97.50.)


#create forest plot
#ggplot(data=model_outputs, aes(y=1:53, x=OR, xmin=`2.5 %`, xmax=`97.5 %`)) +
#  geom_point() + 
#  geom_errorbarh(height=.1) +
#  scale_y_continuous(name = "Feature", breaks=1:nrow(model_outputs), labels=model_outputs$Y_labels)
 

#forest plot with vertical line for odds of 1
sp <- ggplot(data=model_outputs, aes(y=1:52, x=OR, xmin=`2.5 %`, xmax=`97.5 %`)) +
  geom_point() + 
  geom_errorbarh(height=.1) +
  scale_x_log10(name = 'Odds Ratio') +  
  scale_y_continuous(name = "Feature", breaks=1:nrow(model_outputs), labels=model_outputs$Y_labels)

sp + geom_vline(xintercept=1, linetype="dashed", color = "red")





####################################################
#TRY SMOTE: https://www.statology.org/smote-in-r/







####################################################################################################
##Try a forest plot 2
#library(forestplot)
#library(dplyr)

###################################################################################################
#Below code is adapted from the open code, here: https://www.guru99.com/r-generalized-linear-model.html


# plot observed vs. predicted outcomes using test dataset
predict_best <- predict(best_mod, test, type = 'response')


table_mat <- table(test$First_CVD_in_1819, predict_best > 0.5)

table_mat


#accuracy 
accuracy_Test <- sum(diag(table_mat)) / sum(table_mat)
accuracy_Test



#Precision
precision <- function(matrix) {
  # True positive
  tp <- matrix[2, 2]
  # false positive
  fp <- matrix[1, 2]
  return (tp / (tp + fp))
}



#Recall
recall <- function(matrix) {
  # true positive
  tp <- matrix[2, 2]# false positive
  fn <- matrix[2, 1]
  return (tp / (tp + fn))
}


#retrieve  precision and recall
prec <- precision(table_mat)
prec
rec <- recall(table_mat)
rec



#F1 score - based on precision and recall
f1 <- 2 * ((prec * rec) / (prec + rec))
f1



#ROC plot for Best Pred
###This bit didn't work
library(ROCR)
ROCRpred <- prediction(predict_best, test$First_CVD_in_1819)
ROCRperf <- performance(ROCRpred, 'tpr', 'fpr')
plot(ROCRperf, colorize = TRUE, text.adj = c(-0.2, 1.7))





