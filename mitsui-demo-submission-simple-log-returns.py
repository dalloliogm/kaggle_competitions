# %% [code]
# %% [code]
# %% [code]
# %% [code]
"""
The evaluation API requires that you set up a server which will respond to inference requests.
We have already defined the server; you just need write the predict function.
When we evaluate your submission on the hidden test set the client defined in `mitsui_gateway` will run in a different container
with direct access to the hidden test set and hand off the data timestep by timestep.

Your code will always have access to the published copies of the competition files.
"""

import os

import pandas as pd
import polars as pl
import numpy as np
import numpy
import math
import random as rd

import kaggle_evaluation.mitsui_inference_server



class mparam():
    h=0.01
    f1 = lambda x : numpy.log(1+numpy.log(1+0.5*(1+math.erf(1/math.sqrt(2)*x))*x))
    f2 = lambda x : -numpy.log(numpy.log(1+numpy.exp(2-x)))
    g1 = lambda x : (0.5+0.5*math.erf(1/math.sqrt(2)*x)+1/math.sqrt(2*math.pi)*numpy.exp(-0.5*pow(x,2))*x)/((1+numpy.log(1+0.5*(1+math.erf(1/math.sqrt(2)*x))*x))*(1+0.5*(1+math.erf(1/math.sqrt(2)*x))*x))
    g2 = lambda x : numpy.exp(2-x)/(numpy.log(1+numpy.exp(2-x))*(1+numpy.exp(2-x)))
    l = lambda x : pow(x,2)
class model():
    def __init__(self,N,M):
        self.entries=M
        self.numberfeatures=N
        self.loss=mparam.l
        self.T1=numpy.random.uniform(-mparam.h,mparam.h,[self.numberfeatures,self.numberfeatures])
        self.T2=numpy.random.uniform(-mparam.h,mparam.h,[self.numberfeatures,1])
        self.activate1=numpy.vectorize(mparam.f1)
        self.activate2=numpy.vectorize(mparam.f2)
        self.dactivate1=numpy.vectorize(mparam.g1)
        self.dactivate2=numpy.vectorize(mparam.g2)
    def update(self,X,S,alpha):
        dE1,dE2=model.dE(self,X,S)
        T1temp,T2temp=self.T1-alpha*dE1,self.T2-alpha*dE2
        self.T1,self.T2=T1temp,T2temp
    def run(self,X,S,alpha,i):
        j=0
        while j<i:
            model.update(self,X,S,alpha)
            j=j+1
    def forward(M,X):
        X1=numpy.matmul(X,M.T1)
        Y1=M.activate1(X1)
        X2=numpy.matmul(Y1,M.T2)
        Y2=M.activate2(X2)
        return Y2
    def forward_compute(M,X):
        X1=numpy.matmul(X,M.T1)
        Y1=M.activate1(X1)
        H1=M.dactivate1(X1)
        X2=numpy.matmul(Y1,M.T2)
        Y2=M.activate2(X2)
        H2=M.dactivate2(X2)
        return Y1,Y2,H1,H2
    def dE(M,X,S):
        Y1,Y2,H1,H2=model.forward_compute(M,X)
        E2=numpy.multiply((Y2-S),H2)
        dE2=numpy.matmul(numpy.transpose(Y1),E2)
        E1=numpy.multiply(numpy.transpose(numpy.matmul(M.T2,numpy.transpose(E2))),H1)
        dE1=numpy.matmul(numpy.transpose(X),E1)
        return dE1,dE2
    def error(M,X,S):
        Y=model.forward(M,X)
        return float(sum(M.loss(Y-S)))


def normalize(X):
    return (X-X.mean())/X.std()
    
def zip(X,Y):
    n=len(X)
    q=len(Y)
    if n!=q:
        print("ERROR")
        return[]
    res=[]
    for j in range(n):
        res.append(X[j])
        res.append(Y[j])
    return res
df_train=pl.read_csv("/kaggle/input/mitsui-commodity-prediction-challenge/train.csv")
df_target=pl.read_csv("/kaggle/input/mitsui-commodity-prediction-challenge/target_pairs.csv")
df_labels=pl.read_csv("/kaggle/input/mitsui-commodity-prediction-challenge/train_labels.csv")
ASSET1_LIST=[]
ASSET2_LIST=[]
MEAN_LIST1=[]
STD_LIST1=[]
MEAN_LIST2=[]
STD_LIST2=[]
DATA_LIST=[]
MODEL_LIST=[]
LABELS=df_labels.columns[1:]
def train():
    for LABEL in LABELS:
        k=int(LABEL.split(sep="_")[1])
        L=df_target.row(k)[2].split(sep="-")
        if len(L)>0:
            ASSET1=L[0].replace(" ", "")
            ASSET1_LIST.append(ASSET1)
        if len(L)>1:
            ASSET2=df_target.row(k)[2].split(sep="-")[1].replace(" ", "")
            ASSET2_LIST.append(ASSET2)
            print("TRAIN",ASSET1,ASSET2)
            df1=df_train.get_column(ASSET1)
            df2=df_train.get_column(ASSET2)
            XFULL1=df1.to_numpy()
            XFULL2=df2.to_numpy()
        else:
            ASSET2_LIST.append("NONE")
            print("TRAIN",ASSET1)
            df1=df_train.get_column(ASSET1)
            XFULL1=df1.to_numpy()
            XFULL2=numpy.array([0 for w in range(df1.len())])

        XFULL1=XFULL1[len(XFULL1)-100:]
        XFULL2=XFULL2[len(XFULL2)-100:]
        XFULL1=numpy.nan_to_num(XFULL1, nan=0)
        XFULL2=numpy.nan_to_num(XFULL2, nan=0)
        MEAN_LIST1.append(XFULL1.mean())
        STD_LIST1.append(XFULL1.std())
        MEAN_LIST2.append(XFULL2.mean())
        STD_LIST2.append(XFULL2.std())
        if STD_LIST1[-1]!=0:
            XFULL1=normalize(XFULL1)
        if STD_LIST2[-1]!=0:
            XFULL2=normalize(XFULL2)
        
        target=df_labels.get_column(LABEL)
        YFULL=target.to_numpy()
        YFULL=YFULL[len(YFULL)-100:]
        YFULL=np.nan_to_num(YFULL, nan=0)
        N=len(YFULL)
        #print(N)
        H=16
        X=[]
        Y=[]
        for h in range(N-H):
            X.append(zip(XFULL1[h:h+H],XFULL2[h:h+H]))
            Y.append([YFULL[h+H]])
        h=N-H
        X0=np.array([zip(XFULL1[h:h+H],XFULL2[h:h+H])])
        DATA_LIST.append(X0)
        #print(X)
        X=np.array(X)
        Y=np.array(Y)
        NN=model(2*H,2*(N-H))
        for i in range(10):
            NN.run(X,Y,0.01,50)
            print(model.error(NN,X,Y))
        MODEL_LIST.append(NN)
        
    
    
NUM_TARGET_COLUMNS = 424

def predict(
    test: pl.DataFrame,
    label_lags_1_batch: pl.DataFrame,
    label_lags_2_batch: pl.DataFrame,
    label_lags_3_batch: pl.DataFrame,
    label_lags_4_batch: pl.DataFrame,
) -> pl.DataFrame | pd.DataFrame:
    """Replace this function with your inference code.
    You can return either a Pandas or Polars dataframe, though Polars is recommended for performance.
    Each batch of predictions (except the very first) must be returned within 5 minutes of the batch features being provided.
    """
    if len(MODEL_LIST) == 0:
        print("firstRUN")
        train()
    PREDICTIONS=[]
    print(test.get_column("date_id"))
    for k in range(NUM_TARGET_COLUMNS):
        #print(test.get_column(ASSET1_LIST[k]))
        x1=test.get_column(ASSET1_LIST[k]).to_numpy()[0]
        if ASSET2_LIST[k]!="NONE":
            x2=test.get_column(ASSET2_LIST[k]).to_numpy()[0]
        else:
            x2=0
        if STD_LIST1[k]!=0:
            x1=(x1-MEAN_LIST1[k])/STD_LIST1[k]
        if STD_LIST2[k]!=0:
            x2=(x2-MEAN_LIST2[k])/STD_LIST2[k]
        DATA=np.nan_to_num(np.array([list(DATA_LIST[k][0][2:])+[x1,x2]]),nan=0)
        DATA_LIST[k]=DATA
        R=model.forward(MODEL_LIST[k],DATA)
        r=np.nan_to_num(R, nan=0)[0][0]
        PREDICTIONS.append(r)
    
    predictions = pl.DataFrame({f'target_{i}': PREDICTIONS[i] for i in range(NUM_TARGET_COLUMNS)})
    #predictions = pl.DataFrame({f'target_{i}': 0 for i in range(NUM_TARGET_COLUMNS)})

    assert isinstance(predictions, (pd.DataFrame, pl.DataFrame))
    assert len(predictions) == 1
    return predictions


# When your notebook is run on the hidden test set, inference_server.serve must be called within 15 minutes of the notebook starting
# or the gateway will throw an error. If you need more than 15 minutes to load your model you can do so during the very
# first `predict` call, which does not have the usual 1 minute response deadline.
inference_server = kaggle_evaluation.mitsui_inference_server.MitsuiInferenceServer(predict)

if os.getenv('KAGGLE_IS_COMPETITION_RERUN'):
    inference_server.serve()
else:
    inference_server.run_local_gateway(('/kaggle/input/mitsui-commodity-prediction-challenge/',))
