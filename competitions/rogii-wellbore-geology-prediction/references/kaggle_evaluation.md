name        content                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       
----------  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------  
Evaluation  Submissions are scored on the **root mean squared error**. RMSE is defined as:

$$ \text{RMSE} = \sqrt{\frac{1}{n} \sum\_{i=1}^{n} (y\_i - \hat{y}\_i)^2} $$

where \\( \hat{y} \\) is the predicted value, \\( y \\) is the original value, and \\( n \\) is the number of rows in the test data.

## Submission File
For each row in the test set, you must predict the value of the target `tvt` as described on the data tab, each on a separate row in the submission file. The file should contain a header and have the following format:

```
id,tvt
000d7d20_1442,0.0
000d7d20_1443,0.0
000d7d20_1444,0.0
000d7d20_1445,0.0
...
```  
