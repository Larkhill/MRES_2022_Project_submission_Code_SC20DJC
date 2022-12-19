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


%matplotlib inline
warnings.filterwarnings("ignore")
rcParams['figure.figsize'] = 20,10
rcParams['font.size'] = 30
sns.set()
np.random.seed(8)


def plot_distribution(inp):
    plt.figure()
    ax = sns.distplot(inp)
    plt.axvline(np.mean(inp), color="k", linestyle="dashed", linewidth=5)
    _, max_ = plt.ylim()
    plt.text(
        inp.mean() + inp.mean() / 10,
        max_ - max_ / 10,
        "Mean: {:.2f}".format(inp.mean()),
    )
    return plt.figure



CASU_Reporting = pd.DataFrame(SQL_Query)
Age1 = pd.Series(CASU_Reporting['AGE']).array
plot_distribution(Age1)

## Split CVD to NoCVD
CASU_CVD = CASU_Reporting[(CASU_Reporting.First_CVD_in_1819 == 1)]
CASU_NoCVD = CASU_Reporting[(CASU_Reporting.First_CVD_in_1819 == 0)]
AgeCVD = pd.Series(CASU_CVD['AGE']).array
AgeNoCVD = pd.Series(CASU_NoCVD['AGE']).array

##plot age distribution
plt.figure()
ax1 = sns.distplot(AgeCVD, color='b')
ax2 = sns.distplot(AgeNoCVD, color = 'orange')
plt.axvline(np.mean(AgeCVD), color='b', linestyle='dashed', linewidth=5)
plt.axvline(np.mean(AgeNoCVD), color='orange', linestyle='dashed', linewidth=5)


###Age summary stats
print("Avg age, CVD:", AgeCVD.median(), "Avg age, NoCVD:",AgeNoCVD.median(), "Avg age, All:", AgeAll.median())
q75, q25 = np.percentile(AgeCVD, [75 ,25])
iqrCVD = q75 - q25
q75, q25 = np.percentile(AgeNoCVD, [75 ,25])
iqrNoCVD = q75 - q25
q75, q25 = np.percentile(AgeAll, [75 ,25])
iqrAll = q75 - q25

print(iqrCVD,iqrNoCVD, iqrAll)


###Diabetes Duration summary stats
DDCVD = CASU_CVD['DIABETES_DURATION']
DDCVD = DDCVD[DDCVD > 0].dropna()
DDNoCVD = CASU_NoCVD['DIABETES_DURATION']
DDNoCVD = DDNoCVD[DDNoCVD > 0].dropna()
DDCVD = pd.Series(DDCVD).array
DDNoCVD = pd.Series(DDNoCVD).array

print("Avg dur, CVD:", DDCVD.median(), "Avg durage, NoCVD:",DDNoCVD.median())

q75, q25 = np.percentile(DDCVD, [75 ,25])
iqrCVD = q75 - q25
q75, q25 = np.percentile(DDNoCVD, [75 ,25])
iqrNoCVD = q75 - q25

print(iqrCVD,iqrNoCVD)



#CASU_CVD[['AGE','Ethnicity_Cat']].groupby('Ethnicity_Cat').count()
#CASU_NoCVD[['AGE','Ethnicity_Cat']].groupby('Ethnicity_Cat').count()
CASU_Reporting[['AGE','Ethnicity_Cat']].groupby('Ethnicity_Cat').count()

CASU_Reporting[['IMD_QUINTILE','AGE']].groupby('IMD_QUINTILE').count()

CASU_Reporting[['clean_sex','AGE']].groupby('clean_sex').count()

CASU_Reporting.iloc[:,23:].describe()
CASU_CVD.iloc[:,23:].describe()
CASU_Age = CASU_Reporting[['AGE', 'clean_sex']]

CASU_NoCVD[['Clean_Smoking_Value','AGE']].groupby('Clean_Smoking_Value').count()
CASU_Reporting[['statin_flag','AGE']].groupby('statin_flag').count()

CASU_Reporting[['Systolic_Cat','AGE']].groupby('Systolic_Cat').count()
CASU_CVD[['Mean_Systolic_Cat','AGE']].groupby('Mean_Systolic_Cat').count()



plt.close();
sns.set_style("whitegrid");
sns.pairplot(CASU, hue="First_CVD_in_1819", height=3);
plt.show()