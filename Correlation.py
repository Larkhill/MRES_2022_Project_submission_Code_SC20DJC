import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns
import warnings
from pylab import rcParams
from scipy.stats import f_oneway
from scipy.stats import ttest_ind

import pyodbc 
from datetime import datetime

CASU_Reporting = pd.DataFrame(SQL_Query)
CASU_X = CASU_Reporting[["AGE","DIABETES_DURATION"]].dropna()
AGE_array = CASU_X[["AGE"]].to_numpy()
Diab_Dur_array = CASU_X[["DIABETES_DURATION"]].to_numpy()
CASU_X["AGE"].corr(CASU_X["DIABETES_DURATION"], method='pearson')



For_Matrix = CASU_Reporting[['All_8_CARE_PROCESSES','All_9_CARE_PROCESSES','All_three_TT','First_CVD_in_1819',
                          #'Clean_Creatinine_Value',
                          'DIABETES_DURATION','AGE','mean_diastolic','mean_systolic',
                          'BPunderOneFortyEight','Clean_Smoking_Value','statin_flag','IMD_QUINTILE','clean_sex',
                          'mean_hba1c_mmol','mean_hba1c_percent','mean_bmi','mean_chol','CholunderFour']]

import seaborn as sn
import matplotlib.pyplot as plt

corr_matrix = For_Matrix.corr()
print(corr_matrix)

sn.heatmap(corr_matrix, annot=True)
plt.show()