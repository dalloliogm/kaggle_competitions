{
 "cells": [
  {
   "cell_type": "code",
   "execution_count": 1,
   "id": "885d023e",
   "metadata": {
    "_execution_state": "idle",
    "_uuid": "051d70d956493feee0c6d64651c6a088724dca2a",
    "execution": {
     "iopub.execute_input": "2025-09-14T17:07:11.906788Z",
     "iopub.status.busy": "2025-09-14T17:07:11.904673Z",
     "iopub.status.idle": "2025-09-14T17:07:13.153566Z",
     "shell.execute_reply": "2025-09-14T17:07:13.151946Z"
    },
    "papermill": {
     "duration": 1.25896,
     "end_time": "2025-09-14T17:07:13.155803",
     "exception": false,
     "start_time": "2025-09-14T17:07:11.896843",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "── \u001b[1mAttaching core tidyverse packages\u001b[22m ──────────────────────── tidyverse 2.0.0 ──\n",
      "\u001b[32m✔\u001b[39m \u001b[34mdplyr    \u001b[39m 1.1.4     \u001b[32m✔\u001b[39m \u001b[34mreadr    \u001b[39m 2.1.5\n",
      "\u001b[32m✔\u001b[39m \u001b[34mforcats  \u001b[39m 1.0.0     \u001b[32m✔\u001b[39m \u001b[34mstringr  \u001b[39m 1.5.1\n",
      "\u001b[32m✔\u001b[39m \u001b[34mggplot2  \u001b[39m 3.5.1     \u001b[32m✔\u001b[39m \u001b[34mtibble   \u001b[39m 3.2.1\n",
      "\u001b[32m✔\u001b[39m \u001b[34mlubridate\u001b[39m 1.9.3     \u001b[32m✔\u001b[39m \u001b[34mtidyr    \u001b[39m 1.3.1\n",
      "\u001b[32m✔\u001b[39m \u001b[34mpurrr    \u001b[39m 1.0.2     \n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "── \u001b[1mConflicts\u001b[22m ────────────────────────────────────────── tidyverse_conflicts() ──\n",
      "\u001b[31m✖\u001b[39m \u001b[34mdplyr\u001b[39m::\u001b[32mfilter()\u001b[39m masks \u001b[34mstats\u001b[39m::filter()\n",
      "\u001b[31m✖\u001b[39m \u001b[34mdplyr\u001b[39m::\u001b[32mlag()\u001b[39m    masks \u001b[34mstats\u001b[39m::lag()\n",
      "\u001b[36mℹ\u001b[39m Use the conflicted package (\u001b[3m\u001b[34m<http://conflicted.r-lib.org/>\u001b[39m\u001b[23m) to force all conflicts to become errors\n"
     ]
    },
    {
     "data": {
      "text/html": [
       "'playground-series-s5e9'"
      ],
      "text/latex": [
       "'playground-series-s5e9'"
      ],
      "text/markdown": [
       "'playground-series-s5e9'"
      ],
      "text/plain": [
       "[1] \"playground-series-s5e9\""
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    }
   ],
   "source": [
    "# This R environment comes with many helpful analytics packages installed\n",
    "# It is defined by the kaggle/rstats Docker image: https://github.com/kaggle/docker-rstats\n",
    "# For example, here's a helpful package to load\n",
    "\n",
    "library(tidyverse) # metapackage of all tidyverse packages\n",
    "\n",
    "# Input data files are available in the read-only \"../input/\" directory\n",
    "# For example, running this (by clicking run or pressing Shift+Enter) will list all files under the input directory\n",
    "\n",
    "list.files(path = \"../input\")\n",
    "\n",
    "# You can write up to 20GB to the current directory (/kaggle/working/) that gets preserved as output when you create a version using \"Save & Run All\" \n",
    "# You can also write temporary files to /kaggle/temp/, but they won't be saved outside of the current session"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 2,
   "id": "ee644185",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-09-14T17:07:13.199580Z",
     "iopub.status.busy": "2025-09-14T17:07:13.167793Z",
     "iopub.status.idle": "2025-09-14T17:07:16.238285Z",
     "shell.execute_reply": "2025-09-14T17:07:16.236386Z"
    },
    "papermill": {
     "duration": 3.079915,
     "end_time": "2025-09-14T17:07:16.240937",
     "exception": false,
     "start_time": "2025-09-14T17:07:13.161022",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [],
   "source": [
    "pacman::p_load(tidyverse,\n",
    "               tidymodels,\n",
    "               bonsai)"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 3,
   "id": "c8bf073f",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-09-14T17:07:16.255256Z",
     "iopub.status.busy": "2025-09-14T17:07:16.253137Z",
     "iopub.status.idle": "2025-09-14T17:07:17.791506Z",
     "shell.execute_reply": "2025-09-14T17:07:17.789657Z"
    },
    "papermill": {
     "duration": 1.548619,
     "end_time": "2025-09-14T17:07:17.794609",
     "exception": false,
     "start_time": "2025-09-14T17:07:16.245990",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[1mRows: \u001b[22m\u001b[34m524164\u001b[39m \u001b[1mColumns: \u001b[22m\u001b[34m11\u001b[39m\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[36m──\u001b[39m \u001b[1mColumn specification\u001b[22m \u001b[36m────────────────────────────────────────────────────────\u001b[39m\n",
      "\u001b[1mDelimiter:\u001b[22m \",\"\n",
      "\u001b[32mdbl\u001b[39m (11): id, RhythmScore, AudioLoudness, VocalContent, AcousticQuality, Ins...\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\n",
      "\u001b[36mℹ\u001b[39m Use `spec()` to retrieve the full column specification for this data.\n",
      "\u001b[36mℹ\u001b[39m Specify the column types or set `show_col_types = FALSE` to quiet this message.\n"
     ]
    }
   ],
   "source": [
    "train <- read_csv(\"/kaggle/input/playground-series-s5e9/train.csv\")"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 4,
   "id": "da168f5d",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-09-14T17:07:17.808532Z",
     "iopub.status.busy": "2025-09-14T17:07:17.807056Z",
     "iopub.status.idle": "2025-09-14T17:07:18.194208Z",
     "shell.execute_reply": "2025-09-14T17:07:18.192366Z"
    },
    "papermill": {
     "duration": 0.396035,
     "end_time": "2025-09-14T17:07:18.196396",
     "exception": false,
     "start_time": "2025-09-14T17:07:17.800361",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[1mRows: \u001b[22m\u001b[34m174722\u001b[39m \u001b[1mColumns: \u001b[22m\u001b[34m10\u001b[39m\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[36m──\u001b[39m \u001b[1mColumn specification\u001b[22m \u001b[36m────────────────────────────────────────────────────────\u001b[39m\n",
      "\u001b[1mDelimiter:\u001b[22m \",\"\n",
      "\u001b[32mdbl\u001b[39m (10): id, RhythmScore, AudioLoudness, VocalContent, AcousticQuality, Ins...\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\n",
      "\u001b[36mℹ\u001b[39m Use `spec()` to retrieve the full column specification for this data.\n",
      "\u001b[36mℹ\u001b[39m Specify the column types or set `show_col_types = FALSE` to quiet this message.\n"
     ]
    }
   ],
   "source": [
    "test <- read_csv(\"/kaggle/input/playground-series-s5e9/test.csv\")"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 5,
   "id": "c10c0919",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-09-14T17:07:18.210945Z",
     "iopub.status.busy": "2025-09-14T17:07:18.209377Z",
     "iopub.status.idle": "2025-09-14T17:07:18.253878Z",
     "shell.execute_reply": "2025-09-14T17:07:18.250810Z"
    },
    "papermill": {
     "duration": 0.054918,
     "end_time": "2025-09-14T17:07:18.256828",
     "exception": false,
     "start_time": "2025-09-14T17:07:18.201910",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [],
   "source": [
    "my_recipe <- train %>% \n",
    "  select(-id) %>% \n",
    "  recipe(BeatsPerMinute~.) %>% \n",
    "  step_normalize(all_numeric_predictors())"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 6,
   "id": "a78f7313",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-09-14T17:07:18.271490Z",
     "iopub.status.busy": "2025-09-14T17:07:18.269905Z",
     "iopub.status.idle": "2025-09-14T17:07:18.292511Z",
     "shell.execute_reply": "2025-09-14T17:07:18.289626Z"
    },
    "papermill": {
     "duration": 0.033065,
     "end_time": "2025-09-14T17:07:18.295480",
     "exception": false,
     "start_time": "2025-09-14T17:07:18.262415",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [],
   "source": [
    "my_model <- boost_tree(trees = 200, min_n = tune(), tree_depth = tune(), learn_rate = tune(), loss_reduction = tune()) %>%\n",
    "  set_mode(\"regression\") %>%\n",
    "  set_engine(\"lightgbm\",\n",
    "    metric = \"rmse\"\n",
    "  )"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 7,
   "id": "caedef9f",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-09-14T17:07:18.310290Z",
     "iopub.status.busy": "2025-09-14T17:07:18.308665Z",
     "iopub.status.idle": "2025-09-14T17:07:18.328972Z",
     "shell.execute_reply": "2025-09-14T17:07:18.327197Z"
    },
    "papermill": {
     "duration": 0.030853,
     "end_time": "2025-09-14T17:07:18.332056",
     "exception": false,
     "start_time": "2025-09-14T17:07:18.301203",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [],
   "source": [
    "my_wf <- workflow() %>% \n",
    "  add_recipe(my_recipe) %>% \n",
    "  add_model(my_model)"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 8,
   "id": "e02d0395",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-09-14T17:07:18.346530Z",
     "iopub.status.busy": "2025-09-14T17:07:18.345004Z",
     "iopub.status.idle": "2025-09-14T17:07:19.029354Z",
     "shell.execute_reply": "2025-09-14T17:07:19.027577Z"
    },
    "papermill": {
     "duration": 0.694731,
     "end_time": "2025-09-14T17:07:19.032410",
     "exception": false,
     "start_time": "2025-09-14T17:07:18.337679",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [],
   "source": [
    "my_cv <- train %>% vfold_cv(v = 3)"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 9,
   "id": "bd73307e",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-09-14T17:07:19.046844Z",
     "iopub.status.busy": "2025-09-14T17:07:19.045428Z",
     "iopub.status.idle": "2025-09-14T17:07:19.059288Z",
     "shell.execute_reply": "2025-09-14T17:07:19.057792Z"
    },
    "papermill": {
     "duration": 0.023598,
     "end_time": "2025-09-14T17:07:19.061957",
     "exception": false,
     "start_time": "2025-09-14T17:07:19.038359",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [],
   "source": [
    "my_control <- control_grid(verbose = T,allow_par = T,parallel_over = \"everything\")"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 10,
   "id": "294b39da",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-09-14T17:07:19.075459Z",
     "iopub.status.busy": "2025-09-14T17:07:19.074126Z",
     "iopub.status.idle": "2025-09-14T17:07:19.110772Z",
     "shell.execute_reply": "2025-09-14T17:07:19.109074Z"
    },
    "papermill": {
     "duration": 0.046476,
     "end_time": "2025-09-14T17:07:19.113738",
     "exception": false,
     "start_time": "2025-09-14T17:07:19.067262",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [],
   "source": [
    "my_grid <- grid_latin_hypercube(min_n(range = c(2,40)),\n",
    "                              tree_depth(range = c(1,15)),\n",
    "                              learn_rate(range = c(-10,-1)),\n",
    "                              loss_reduction(range = c(-10,1.5)),size = 10)"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 11,
   "id": "ea6ea1ea",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-09-14T17:07:19.127863Z",
     "iopub.status.busy": "2025-09-14T17:07:19.126413Z",
     "iopub.status.idle": "2025-09-14T17:08:53.588541Z",
     "shell.execute_reply": "2025-09-14T17:08:53.586829Z"
    },
    "papermill": {
     "duration": 94.472316,
     "end_time": "2025-09-14T17:08:53.591530",
     "exception": false,
     "start_time": "2025-09-14T17:07:19.119214",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold1: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold1: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold1: preprocessor 1/1, model 1/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold1: preprocessor 1/1, model 1/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold1: preprocessor 1/1, model 1/10 (extracts)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold1: preprocessor 1/1, model 1/10 (predictions)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold1: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold1: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold1: preprocessor 1/1, model 2/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold1: preprocessor 1/1, model 2/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold1: preprocessor 1/1, model 2/10 (extracts)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold1: preprocessor 1/1, model 2/10 (predictions)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold1: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold1: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold1: preprocessor 1/1, model 3/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold1: preprocessor 1/1, model 3/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold1: preprocessor 1/1, model 3/10 (extracts)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold1: preprocessor 1/1, model 3/10 (predictions)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold1: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold1: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold1: preprocessor 1/1, model 4/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold1: preprocessor 1/1, model 4/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold1: preprocessor 1/1, model 4/10 (extracts)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold1: preprocessor 1/1, model 4/10 (predictions)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold1: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold1: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold1: preprocessor 1/1, model 5/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold1: preprocessor 1/1, model 5/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold1: preprocessor 1/1, model 5/10 (extracts)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold1: preprocessor 1/1, model 5/10 (predictions)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold1: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold1: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold1: preprocessor 1/1, model 6/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold1: preprocessor 1/1, model 6/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold1: preprocessor 1/1, model 6/10 (extracts)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold1: preprocessor 1/1, model 6/10 (predictions)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold1: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold1: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold1: preprocessor 1/1, model 7/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold1: preprocessor 1/1, model 7/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold1: preprocessor 1/1, model 7/10 (extracts)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold1: preprocessor 1/1, model 7/10 (predictions)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold1: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold1: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold1: preprocessor 1/1, model 8/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold1: preprocessor 1/1, model 8/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold1: preprocessor 1/1, model 8/10 (extracts)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold1: preprocessor 1/1, model 8/10 (predictions)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold1: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold1: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold1: preprocessor 1/1, model 9/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold1: preprocessor 1/1, model 9/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold1: preprocessor 1/1, model 9/10 (extracts)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold1: preprocessor 1/1, model 9/10 (predictions)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold1: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold1: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold1: preprocessor 1/1, model 10/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold1: preprocessor 1/1, model 10/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold1: preprocessor 1/1, model 10/10 (extracts)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold1: preprocessor 1/1, model 10/10 (predictions)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold2: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold2: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold2: preprocessor 1/1, model 1/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold2: preprocessor 1/1, model 1/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold2: preprocessor 1/1, model 1/10 (extracts)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold2: preprocessor 1/1, model 1/10 (predictions)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold2: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold2: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold2: preprocessor 1/1, model 2/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold2: preprocessor 1/1, model 2/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold2: preprocessor 1/1, model 2/10 (extracts)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold2: preprocessor 1/1, model 2/10 (predictions)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold2: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold2: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold2: preprocessor 1/1, model 3/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold2: preprocessor 1/1, model 3/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold2: preprocessor 1/1, model 3/10 (extracts)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold2: preprocessor 1/1, model 3/10 (predictions)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold2: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold2: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold2: preprocessor 1/1, model 4/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold2: preprocessor 1/1, model 4/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold2: preprocessor 1/1, model 4/10 (extracts)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold2: preprocessor 1/1, model 4/10 (predictions)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold2: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold2: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold2: preprocessor 1/1, model 5/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold2: preprocessor 1/1, model 5/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold2: preprocessor 1/1, model 5/10 (extracts)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold2: preprocessor 1/1, model 5/10 (predictions)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold2: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold2: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold2: preprocessor 1/1, model 6/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold2: preprocessor 1/1, model 6/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold2: preprocessor 1/1, model 6/10 (extracts)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold2: preprocessor 1/1, model 6/10 (predictions)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold2: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold2: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold2: preprocessor 1/1, model 7/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold2: preprocessor 1/1, model 7/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold2: preprocessor 1/1, model 7/10 (extracts)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold2: preprocessor 1/1, model 7/10 (predictions)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold2: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold2: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold2: preprocessor 1/1, model 8/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold2: preprocessor 1/1, model 8/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold2: preprocessor 1/1, model 8/10 (extracts)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold2: preprocessor 1/1, model 8/10 (predictions)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold2: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold2: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold2: preprocessor 1/1, model 9/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold2: preprocessor 1/1, model 9/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold2: preprocessor 1/1, model 9/10 (extracts)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold2: preprocessor 1/1, model 9/10 (predictions)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold2: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold2: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold2: preprocessor 1/1, model 10/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold2: preprocessor 1/1, model 10/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold2: preprocessor 1/1, model 10/10 (extracts)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold2: preprocessor 1/1, model 10/10 (predictions)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold3: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold3: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold3: preprocessor 1/1, model 1/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold3: preprocessor 1/1, model 1/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold3: preprocessor 1/1, model 1/10 (extracts)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold3: preprocessor 1/1, model 1/10 (predictions)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold3: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold3: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold3: preprocessor 1/1, model 2/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold3: preprocessor 1/1, model 2/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold3: preprocessor 1/1, model 2/10 (extracts)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold3: preprocessor 1/1, model 2/10 (predictions)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold3: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold3: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold3: preprocessor 1/1, model 3/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold3: preprocessor 1/1, model 3/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold3: preprocessor 1/1, model 3/10 (extracts)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold3: preprocessor 1/1, model 3/10 (predictions)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold3: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold3: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold3: preprocessor 1/1, model 4/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold3: preprocessor 1/1, model 4/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold3: preprocessor 1/1, model 4/10 (extracts)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold3: preprocessor 1/1, model 4/10 (predictions)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold3: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold3: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold3: preprocessor 1/1, model 5/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold3: preprocessor 1/1, model 5/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold3: preprocessor 1/1, model 5/10 (extracts)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold3: preprocessor 1/1, model 5/10 (predictions)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold3: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold3: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold3: preprocessor 1/1, model 6/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold3: preprocessor 1/1, model 6/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold3: preprocessor 1/1, model 6/10 (extracts)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold3: preprocessor 1/1, model 6/10 (predictions)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold3: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold3: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold3: preprocessor 1/1, model 7/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold3: preprocessor 1/1, model 7/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold3: preprocessor 1/1, model 7/10 (extracts)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold3: preprocessor 1/1, model 7/10 (predictions)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold3: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold3: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold3: preprocessor 1/1, model 8/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold3: preprocessor 1/1, model 8/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold3: preprocessor 1/1, model 8/10 (extracts)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold3: preprocessor 1/1, model 8/10 (predictions)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold3: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold3: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold3: preprocessor 1/1, model 9/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold3: preprocessor 1/1, model 9/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold3: preprocessor 1/1, model 9/10 (extracts)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold3: preprocessor 1/1, model 9/10 (predictions)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold3: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold3: preprocessor 1/1\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold3: preprocessor 1/1, model 10/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✓\u001b[39m \u001b[30mFold3: preprocessor 1/1, model 10/10\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold3: preprocessor 1/1, model 10/10 (extracts)\u001b[39m\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[34mi\u001b[39m \u001b[30mFold3: preprocessor 1/1, model 10/10 (predictions)\u001b[39m\n",
      "\n"
     ]
    }
   ],
   "source": [
    "my_tune <- tune_grid(\n",
    "  object = my_wf,\n",
    "  resamples = my_cv,\n",
    "  grid = my_grid,\n",
    "  control = my_control,\n",
    "  metrics = metric_set(rmse)\n",
    ")"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 12,
   "id": "237b5dfc",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-09-14T17:08:53.628778Z",
     "iopub.status.busy": "2025-09-14T17:08:53.627245Z",
     "iopub.status.idle": "2025-09-14T17:08:53.670577Z",
     "shell.execute_reply": "2025-09-14T17:08:53.668863Z"
    },
    "papermill": {
     "duration": 0.063321,
     "end_time": "2025-09-14T17:08:53.672848",
     "exception": false,
     "start_time": "2025-09-14T17:08:53.609527",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [],
   "source": [
    "my_tune %>% select_best(metric = \"rmse\") -> my_params"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 13,
   "id": "e8e71be1",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-09-14T17:08:53.704944Z",
     "iopub.status.busy": "2025-09-14T17:08:53.703482Z",
     "iopub.status.idle": "2025-09-14T17:08:53.748004Z",
     "shell.execute_reply": "2025-09-14T17:08:53.746338Z"
    },
    "papermill": {
     "duration": 0.063324,
     "end_time": "2025-09-14T17:08:53.750672",
     "exception": false,
     "start_time": "2025-09-14T17:08:53.687348",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [],
   "source": [
    "my_wf %>% finalize_workflow(parameters = my_params) -> final_wf"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 14,
   "id": "cf6c2442",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-09-14T17:08:53.783893Z",
     "iopub.status.busy": "2025-09-14T17:08:53.782343Z",
     "iopub.status.idle": "2025-09-14T17:08:57.464228Z",
     "shell.execute_reply": "2025-09-14T17:08:57.461848Z"
    },
    "papermill": {
     "duration": 3.701439,
     "end_time": "2025-09-14T17:08:57.466767",
     "exception": false,
     "start_time": "2025-09-14T17:08:53.765328",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [],
   "source": [
    "final_wf %>% fit(data = train) -> final_fit"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 15,
   "id": "57b137c4",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-09-14T17:08:57.502680Z",
     "iopub.status.busy": "2025-09-14T17:08:57.501135Z",
     "iopub.status.idle": "2025-09-14T17:08:58.090039Z",
     "shell.execute_reply": "2025-09-14T17:08:58.087842Z"
    },
    "papermill": {
     "duration": 0.609146,
     "end_time": "2025-09-14T17:08:58.093363",
     "exception": false,
     "start_time": "2025-09-14T17:08:57.484217",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [],
   "source": [
    "final_pred <- final_fit %>% predict(new_data = test)"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 16,
   "id": "522c59cf",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-09-14T17:08:58.130144Z",
     "iopub.status.busy": "2025-09-14T17:08:58.128522Z",
     "iopub.status.idle": "2025-09-14T17:08:58.249403Z",
     "shell.execute_reply": "2025-09-14T17:08:58.246401Z"
    },
    "papermill": {
     "duration": 0.142028,
     "end_time": "2025-09-14T17:08:58.253435",
     "exception": false,
     "start_time": "2025-09-14T17:08:58.111407",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[1mRows: \u001b[22m\u001b[34m174722\u001b[39m \u001b[1mColumns: \u001b[22m\u001b[34m2\u001b[39m\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[36m──\u001b[39m \u001b[1mColumn specification\u001b[22m \u001b[36m────────────────────────────────────────────────────────\u001b[39m\n",
      "\u001b[1mDelimiter:\u001b[22m \",\"\n",
      "\u001b[32mdbl\u001b[39m (2): id, BeatsPerMinute\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\n",
      "\u001b[36mℹ\u001b[39m Use `spec()` to retrieve the full column specification for this data.\n",
      "\u001b[36mℹ\u001b[39m Specify the column types or set `show_col_types = FALSE` to quiet this message.\n"
     ]
    }
   ],
   "source": [
    "sample_submission <- read_csv(\"/kaggle/input/playground-series-s5e9/sample_submission.csv\")"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 17,
   "id": "4f84b8cc",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-09-14T17:08:58.289230Z",
     "iopub.status.busy": "2025-09-14T17:08:58.287663Z",
     "iopub.status.idle": "2025-09-14T17:08:58.300476Z",
     "shell.execute_reply": "2025-09-14T17:08:58.298921Z"
    },
    "papermill": {
     "duration": 0.032323,
     "end_time": "2025-09-14T17:08:58.302882",
     "exception": false,
     "start_time": "2025-09-14T17:08:58.270559",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [],
   "source": [
    "sample_submission$BeatsPerMinute <- final_pred$.pred"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 18,
   "id": "6b66951b",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-09-14T17:08:58.335920Z",
     "iopub.status.busy": "2025-09-14T17:08:58.334408Z",
     "iopub.status.idle": "2025-09-14T17:08:58.361670Z",
     "shell.execute_reply": "2025-09-14T17:08:58.359957Z"
    },
    "papermill": {
     "duration": 0.046013,
     "end_time": "2025-09-14T17:08:58.363853",
     "exception": false,
     "start_time": "2025-09-14T17:08:58.317840",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "data": {
      "text/html": [
       "<table class=\"dataframe\">\n",
       "<caption>A tibble: 6 × 2</caption>\n",
       "<thead>\n",
       "\t<tr><th scope=col>id</th><th scope=col>BeatsPerMinute</th></tr>\n",
       "\t<tr><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th></tr>\n",
       "</thead>\n",
       "<tbody>\n",
       "\t<tr><td>524164</td><td>119.0375</td></tr>\n",
       "\t<tr><td>524165</td><td>118.9598</td></tr>\n",
       "\t<tr><td>524166</td><td>119.1122</td></tr>\n",
       "\t<tr><td>524167</td><td>119.0664</td></tr>\n",
       "\t<tr><td>524168</td><td>119.0661</td></tr>\n",
       "\t<tr><td>524169</td><td>119.0839</td></tr>\n",
       "</tbody>\n",
       "</table>\n"
      ],
      "text/latex": [
       "A tibble: 6 × 2\n",
       "\\begin{tabular}{ll}\n",
       " id & BeatsPerMinute\\\\\n",
       " <dbl> & <dbl>\\\\\n",
       "\\hline\n",
       "\t 524164 & 119.0375\\\\\n",
       "\t 524165 & 118.9598\\\\\n",
       "\t 524166 & 119.1122\\\\\n",
       "\t 524167 & 119.0664\\\\\n",
       "\t 524168 & 119.0661\\\\\n",
       "\t 524169 & 119.0839\\\\\n",
       "\\end{tabular}\n"
      ],
      "text/markdown": [
       "\n",
       "A tibble: 6 × 2\n",
       "\n",
       "| id &lt;dbl&gt; | BeatsPerMinute &lt;dbl&gt; |\n",
       "|---|---|\n",
       "| 524164 | 119.0375 |\n",
       "| 524165 | 118.9598 |\n",
       "| 524166 | 119.1122 |\n",
       "| 524167 | 119.0664 |\n",
       "| 524168 | 119.0661 |\n",
       "| 524169 | 119.0839 |\n",
       "\n"
      ],
      "text/plain": [
       "  id     BeatsPerMinute\n",
       "1 524164 119.0375      \n",
       "2 524165 118.9598      \n",
       "3 524166 119.1122      \n",
       "4 524167 119.0664      \n",
       "5 524168 119.0661      \n",
       "6 524169 119.0839      "
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    }
   ],
   "source": [
    "sample_submission %>% head()"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 19,
   "id": "5df7d787",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-09-14T17:08:58.396951Z",
     "iopub.status.busy": "2025-09-14T17:08:58.395446Z",
     "iopub.status.idle": "2025-09-14T17:08:58.465303Z",
     "shell.execute_reply": "2025-09-14T17:08:58.462847Z"
    },
    "papermill": {
     "duration": 0.090254,
     "end_time": "2025-09-14T17:08:58.468851",
     "exception": false,
     "start_time": "2025-09-14T17:08:58.378597",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [],
   "source": [
    "sample_submission %>% write_csv(\"submission.csv\")"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 20,
   "id": "be4ee6cf",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-09-14T17:08:58.520034Z",
     "iopub.status.busy": "2025-09-14T17:08:58.518018Z",
     "iopub.status.idle": "2025-09-14T17:08:58.533723Z",
     "shell.execute_reply": "2025-09-14T17:08:58.532048Z"
    },
    "papermill": {
     "duration": 0.044451,
     "end_time": "2025-09-14T17:08:58.536216",
     "exception": false,
     "start_time": "2025-09-14T17:08:58.491765",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [],
   "source": [
    "final_wf %>% extract_spec_parsnip() %>% update(trees = 400) -> new_model"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 21,
   "id": "9e675ec6",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-09-14T17:08:58.570338Z",
     "iopub.status.busy": "2025-09-14T17:08:58.568732Z",
     "iopub.status.idle": "2025-09-14T17:08:58.582647Z",
     "shell.execute_reply": "2025-09-14T17:08:58.580978Z"
    },
    "papermill": {
     "duration": 0.033369,
     "end_time": "2025-09-14T17:08:58.584979",
     "exception": false,
     "start_time": "2025-09-14T17:08:58.551610",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [],
   "source": [
    "final_wf %>% update_model(spec = new_model) -> new_wf"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 22,
   "id": "33c0c511",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-09-14T17:08:58.618460Z",
     "iopub.status.busy": "2025-09-14T17:08:58.616851Z",
     "iopub.status.idle": "2025-09-14T17:09:05.372064Z",
     "shell.execute_reply": "2025-09-14T17:09:05.369681Z"
    },
    "papermill": {
     "duration": 6.776579,
     "end_time": "2025-09-14T17:09:05.376513",
     "exception": false,
     "start_time": "2025-09-14T17:08:58.599934",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [],
   "source": [
    "new_wf %>% fit(data = train) -> new_fit"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 23,
   "id": "e632b719",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-09-14T17:09:05.412856Z",
     "iopub.status.busy": "2025-09-14T17:09:05.411335Z",
     "iopub.status.idle": "2025-09-14T17:09:07.428936Z",
     "shell.execute_reply": "2025-09-14T17:09:07.426601Z"
    },
    "papermill": {
     "duration": 2.037412,
     "end_time": "2025-09-14T17:09:07.431499",
     "exception": false,
     "start_time": "2025-09-14T17:09:05.394087",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [],
   "source": [
    "new_fit %>% predict(new_data = test) -> new_pred"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 24,
   "id": "dbca339e",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-09-14T17:09:07.467511Z",
     "iopub.status.busy": "2025-09-14T17:09:07.465967Z",
     "iopub.status.idle": "2025-09-14T17:09:07.479436Z",
     "shell.execute_reply": "2025-09-14T17:09:07.477805Z"
    },
    "papermill": {
     "duration": 0.032396,
     "end_time": "2025-09-14T17:09:07.481650",
     "exception": false,
     "start_time": "2025-09-14T17:09:07.449254",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [],
   "source": [
    "sample_submission$BeatsPerMinute <- new_pred$.pred"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 25,
   "id": "bf54adf7",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-09-14T17:09:07.515231Z",
     "iopub.status.busy": "2025-09-14T17:09:07.513617Z",
     "iopub.status.idle": "2025-09-14T17:09:07.539683Z",
     "shell.execute_reply": "2025-09-14T17:09:07.537401Z"
    },
    "papermill": {
     "duration": 0.046144,
     "end_time": "2025-09-14T17:09:07.542445",
     "exception": false,
     "start_time": "2025-09-14T17:09:07.496301",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "data": {
      "text/html": [
       "<table class=\"dataframe\">\n",
       "<caption>A tibble: 6 × 2</caption>\n",
       "<thead>\n",
       "\t<tr><th scope=col>id</th><th scope=col>BeatsPerMinute</th></tr>\n",
       "\t<tr><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th></tr>\n",
       "</thead>\n",
       "<tbody>\n",
       "\t<tr><td>524164</td><td>119.0869</td></tr>\n",
       "\t<tr><td>524165</td><td>118.9250</td></tr>\n",
       "\t<tr><td>524166</td><td>119.2257</td></tr>\n",
       "\t<tr><td>524167</td><td>119.1085</td></tr>\n",
       "\t<tr><td>524168</td><td>119.0771</td></tr>\n",
       "\t<tr><td>524169</td><td>119.1857</td></tr>\n",
       "</tbody>\n",
       "</table>\n"
      ],
      "text/latex": [
       "A tibble: 6 × 2\n",
       "\\begin{tabular}{ll}\n",
       " id & BeatsPerMinute\\\\\n",
       " <dbl> & <dbl>\\\\\n",
       "\\hline\n",
       "\t 524164 & 119.0869\\\\\n",
       "\t 524165 & 118.9250\\\\\n",
       "\t 524166 & 119.2257\\\\\n",
       "\t 524167 & 119.1085\\\\\n",
       "\t 524168 & 119.0771\\\\\n",
       "\t 524169 & 119.1857\\\\\n",
       "\\end{tabular}\n"
      ],
      "text/markdown": [
       "\n",
       "A tibble: 6 × 2\n",
       "\n",
       "| id &lt;dbl&gt; | BeatsPerMinute &lt;dbl&gt; |\n",
       "|---|---|\n",
       "| 524164 | 119.0869 |\n",
       "| 524165 | 118.9250 |\n",
       "| 524166 | 119.2257 |\n",
       "| 524167 | 119.1085 |\n",
       "| 524168 | 119.0771 |\n",
       "| 524169 | 119.1857 |\n",
       "\n"
      ],
      "text/plain": [
       "  id     BeatsPerMinute\n",
       "1 524164 119.0869      \n",
       "2 524165 118.9250      \n",
       "3 524166 119.2257      \n",
       "4 524167 119.1085      \n",
       "5 524168 119.0771      \n",
       "6 524169 119.1857      "
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    }
   ],
   "source": [
    "sample_submission %>% head()"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 26,
   "id": "5a7a8e82",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-09-14T17:09:07.576602Z",
     "iopub.status.busy": "2025-09-14T17:09:07.575081Z",
     "iopub.status.idle": "2025-09-14T17:09:07.586545Z",
     "shell.execute_reply": "2025-09-14T17:09:07.584955Z"
    },
    "papermill": {
     "duration": 0.030654,
     "end_time": "2025-09-14T17:09:07.588840",
     "exception": false,
     "start_time": "2025-09-14T17:09:07.558186",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [],
   "source": [
    "#sample_submission %>% write_csv(\"submission.csv\")"
   ]
  }
 ],
 "metadata": {
  "kaggle": {
   "accelerator": "none",
   "dataSources": [
    {
     "databundleVersionId": 13345277,
     "sourceId": 91720,
     "sourceType": "competition"
    }
   ],
   "dockerImageVersionId": 30749,
   "isGpuEnabled": false,
   "isInternetEnabled": true,
   "language": "r",
   "sourceType": "notebook"
  },
  "kernelspec": {
   "display_name": "R",
   "language": "R",
   "name": "ir"
  },
  "language_info": {
   "codemirror_mode": "r",
   "file_extension": ".r",
   "mimetype": "text/x-r-source",
   "name": "R",
   "pygments_lexer": "r",
   "version": "4.4.0"
  },
  "papermill": {
   "default_parameters": {},
   "duration": 119.055513,
   "end_time": "2025-09-14T17:09:07.827148",
   "environment_variables": {},
   "exception": null,
   "input_path": "__notebook__.ipynb",
   "output_path": "__notebook__.ipynb",
   "parameters": {},
   "start_time": "2025-09-14T17:07:08.771635",
   "version": "2.6.0"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 5
}
