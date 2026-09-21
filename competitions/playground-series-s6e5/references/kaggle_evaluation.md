name        content                                                                                                                                                                                                                                                                                                                                                                                                                                    
----------  -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------  
Evaluation  Submissions are evaluated on [area under the ROC curve](http://en.wikipedia.org/wiki/Receiver_operating_characteristic) between the predicted probability and the observed target.


## Submission File
For each id in the test set, you must predict a probability for the `PitNextLap` target. The file should contain a header and have the following format:

    id,PitNextLap
    439140,0.2
    439141,0.3
    439142,0.9
    etc.  
