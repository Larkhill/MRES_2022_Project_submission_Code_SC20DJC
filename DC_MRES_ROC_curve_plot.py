#due difficulties installing libraries, it was easier to copy the 
#false positive rate and true postive rate into python and plot the curves with the 
#following code jupyter
plt.plot(fpr,tpr,label="Standard Weights, auc="+str(auc))
plt.plot(fpr,tpr,label="Adjusted weights, auc="+str(auc))

plt.legend()#(loc=4)
plt.show()