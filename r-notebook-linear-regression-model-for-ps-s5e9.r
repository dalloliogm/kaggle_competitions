{
 "cells": [
  {
   "cell_type": "code",
   "execution_count": 1,
   "id": "ddc0ddaf",
   "metadata": {
    "_execution_state": "idle",
    "_uuid": "051d70d956493feee0c6d64651c6a088724dca2a",
    "execution": {
     "iopub.execute_input": "2025-09-18T12:38:35.725616Z",
     "iopub.status.busy": "2025-09-18T12:38:35.723403Z",
     "iopub.status.idle": "2025-09-18T12:38:37.173477Z",
     "shell.execute_reply": "2025-09-18T12:38:37.171596Z"
    },
    "papermill": {
     "duration": 1.460689,
     "end_time": "2025-09-18T12:38:37.176029",
     "exception": false,
     "start_time": "2025-09-18T12:38:35.715340",
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
       "<style>\n",
       ".list-inline {list-style: none; margin:0; padding: 0}\n",
       ".list-inline>li {display: inline-block}\n",
       ".list-inline>li:not(:last-child)::after {content: \"\\00b7\"; padding: 0 .5ex}\n",
       "</style>\n",
       "<ol class=list-inline><li>'bpm-prediction-challenge'</li><li>'playground-series-s5e9'</li></ol>\n"
      ],
      "text/latex": [
       "\\begin{enumerate*}\n",
       "\\item 'bpm-prediction-challenge'\n",
       "\\item 'playground-series-s5e9'\n",
       "\\end{enumerate*}\n"
      ],
      "text/markdown": [
       "1. 'bpm-prediction-challenge'\n",
       "2. 'playground-series-s5e9'\n",
       "\n",
       "\n"
      ],
      "text/plain": [
       "[1] \"bpm-prediction-challenge\" \"playground-series-s5e9\"  "
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
   "id": "19ae19bf",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-09-18T12:38:37.221930Z",
     "iopub.status.busy": "2025-09-18T12:38:37.188982Z",
     "iopub.status.idle": "2025-09-18T12:38:37.450490Z",
     "shell.execute_reply": "2025-09-18T12:38:37.448544Z"
    },
    "papermill": {
     "duration": 0.27163,
     "end_time": "2025-09-18T12:38:37.453169",
     "exception": false,
     "start_time": "2025-09-18T12:38:37.181539",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [],
   "source": [
    "library(readr)\n",
    "library(jtools)"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 3,
   "id": "dda4beaa",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-09-18T12:38:37.468339Z",
     "iopub.status.busy": "2025-09-18T12:38:37.466232Z",
     "iopub.status.idle": "2025-09-18T12:38:54.943171Z",
     "shell.execute_reply": "2025-09-18T12:38:54.941323Z"
    },
    "papermill": {
     "duration": 17.488187,
     "end_time": "2025-09-18T12:38:54.946883",
     "exception": false,
     "start_time": "2025-09-18T12:38:37.458696",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [],
   "source": [
    "train <- read.table(\"/kaggle/input/playground-series-s5e9/train.csv\",sep=\",\",header=TRUE, stringsAsFactors=FALSE)\n",
    "org <- read.table(\"/kaggle/input/bpm-prediction-challenge/Train.csv\",sep=\",\",header=TRUE, stringsAsFactors=FALSE)\n",
    "test <- read.table(\"/kaggle/input/playground-series-s5e9/test.csv\",sep=\",\",header=TRUE, stringsAsFactors=FALSE)\n",
    "submission<-read.table(\"/kaggle/input/playground-series-s5e9/sample_submission.csv\",sep=\",\",header=TRUE, stringsAsFactors=FALSE)\n",
    "\n",
    "train <- train[, -1]\n",
    "test <- test[,-1]"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 4,
   "id": "8476bc5d",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-09-18T12:38:54.961606Z",
     "iopub.status.busy": "2025-09-18T12:38:54.960002Z",
     "iopub.status.idle": "2025-09-18T12:38:54.981181Z",
     "shell.execute_reply": "2025-09-18T12:38:54.978591Z"
    },
    "papermill": {
     "duration": 0.032742,
     "end_time": "2025-09-18T12:38:54.985310",
     "exception": false,
     "start_time": "2025-09-18T12:38:54.952568",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "data": {
      "text/html": [
       "TRUE"
      ],
      "text/latex": [
       "TRUE"
      ],
      "text/markdown": [
       "TRUE"
      ],
      "text/plain": [
       "[1] TRUE"
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    }
   ],
   "source": [
    "is.data.frame(test)"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 5,
   "id": "27bc978f",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-09-18T12:38:55.001299Z",
     "iopub.status.busy": "2025-09-18T12:38:54.999681Z",
     "iopub.status.idle": "2025-09-18T12:38:55.040071Z",
     "shell.execute_reply": "2025-09-18T12:38:55.038070Z"
    },
    "papermill": {
     "duration": 0.051132,
     "end_time": "2025-09-18T12:38:55.042598",
     "exception": false,
     "start_time": "2025-09-18T12:38:54.991466",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "data": {
      "text/html": [
       "<style>\n",
       ".list-inline {list-style: none; margin:0; padding: 0}\n",
       ".list-inline>li {display: inline-block}\n",
       ".list-inline>li:not(:last-child)::after {content: \"\\00b7\"; padding: 0 .5ex}\n",
       "</style>\n",
       "<ol class=list-inline><li>524164</li><li>10</li></ol>\n"
      ],
      "text/latex": [
       "\\begin{enumerate*}\n",
       "\\item 524164\n",
       "\\item 10\n",
       "\\end{enumerate*}\n"
      ],
      "text/markdown": [
       "1. 524164\n",
       "2. 10\n",
       "\n",
       "\n"
      ],
      "text/plain": [
       "[1] 524164     10"
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    },
    {
     "data": {
      "text/html": [
       "<style>\n",
       ".list-inline {list-style: none; margin:0; padding: 0}\n",
       ".list-inline>li {display: inline-block}\n",
       ".list-inline>li:not(:last-child)::after {content: \"\\00b7\"; padding: 0 .5ex}\n",
       "</style>\n",
       "<ol class=list-inline><li>174722</li><li>9</li></ol>\n"
      ],
      "text/latex": [
       "\\begin{enumerate*}\n",
       "\\item 174722\n",
       "\\item 9\n",
       "\\end{enumerate*}\n"
      ],
      "text/markdown": [
       "1. 174722\n",
       "2. 9\n",
       "\n",
       "\n"
      ],
      "text/plain": [
       "[1] 174722      9"
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    },
    {
     "data": {
      "text/html": [
       "<style>\n",
       ".list-inline {list-style: none; margin:0; padding: 0}\n",
       ".list-inline>li {display: inline-block}\n",
       ".list-inline>li:not(:last-child)::after {content: \"\\00b7\"; padding: 0 .5ex}\n",
       "</style>\n",
       "<ol class=list-inline><li>174722</li><li>2</li></ol>\n"
      ],
      "text/latex": [
       "\\begin{enumerate*}\n",
       "\\item 174722\n",
       "\\item 2\n",
       "\\end{enumerate*}\n"
      ],
      "text/markdown": [
       "1. 174722\n",
       "2. 2\n",
       "\n",
       "\n"
      ],
      "text/plain": [
       "[1] 174722      2"
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    },
    {
     "data": {
      "text/html": [
       "<style>\n",
       ".list-inline {list-style: none; margin:0; padding: 0}\n",
       ".list-inline>li {display: inline-block}\n",
       ".list-inline>li:not(:last-child)::after {content: \"\\00b7\"; padding: 0 .5ex}\n",
       "</style>\n",
       "<ol class=list-inline><li>14633</li><li>10</li></ol>\n"
      ],
      "text/latex": [
       "\\begin{enumerate*}\n",
       "\\item 14633\n",
       "\\item 10\n",
       "\\end{enumerate*}\n"
      ],
      "text/markdown": [
       "1. 14633\n",
       "2. 10\n",
       "\n",
       "\n"
      ],
      "text/plain": [
       "[1] 14633    10"
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    }
   ],
   "source": [
    "dim(train)\n",
    "dim(test)\n",
    "dim(submission)\n",
    "dim(org)"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 6,
   "id": "fd1af18f",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-09-18T12:38:55.058733Z",
     "iopub.status.busy": "2025-09-18T12:38:55.056947Z",
     "iopub.status.idle": "2025-09-18T12:38:55.086614Z",
     "shell.execute_reply": "2025-09-18T12:38:55.084318Z"
    },
    "papermill": {
     "duration": 0.040472,
     "end_time": "2025-09-18T12:38:55.089263",
     "exception": false,
     "start_time": "2025-09-18T12:38:55.048791",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "data": {
      "text/html": [
       "FALSE"
      ],
      "text/latex": [
       "FALSE"
      ],
      "text/markdown": [
       "FALSE"
      ],
      "text/plain": [
       "[1] FALSE"
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    },
    {
     "data": {
      "text/html": [
       "FALSE"
      ],
      "text/latex": [
       "FALSE"
      ],
      "text/markdown": [
       "FALSE"
      ],
      "text/plain": [
       "[1] FALSE"
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    },
    {
     "data": {
      "text/html": [
       "FALSE"
      ],
      "text/latex": [
       "FALSE"
      ],
      "text/markdown": [
       "FALSE"
      ],
      "text/plain": [
       "[1] FALSE"
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    }
   ],
   "source": [
    "is.null(train)\n",
    "is.null(org)\n",
    "is.null(test)"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 7,
   "id": "e7742984",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-09-18T12:38:55.105911Z",
     "iopub.status.busy": "2025-09-18T12:38:55.104259Z",
     "iopub.status.idle": "2025-09-18T12:38:55.123248Z",
     "shell.execute_reply": "2025-09-18T12:38:55.121405Z"
    },
    "papermill": {
     "duration": 0.030483,
     "end_time": "2025-09-18T12:38:55.126124",
     "exception": false,
     "start_time": "2025-09-18T12:38:55.095641",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "data": {
      "text/html": [
       "<style>\n",
       ".list-inline {list-style: none; margin:0; padding: 0}\n",
       ".list-inline>li {display: inline-block}\n",
       ".list-inline>li:not(:last-child)::after {content: \"\\00b7\"; padding: 0 .5ex}\n",
       "</style>\n",
       "<ol class=list-inline><li>'RhythmScore'</li><li>'AudioLoudness'</li><li>'VocalContent'</li><li>'AcousticQuality'</li><li>'InstrumentalScore'</li><li>'LivePerformanceLikelihood'</li><li>'MoodScore'</li><li>'TrackDurationMs'</li><li>'Energy'</li><li>'BeatsPerMinute'</li></ol>\n"
      ],
      "text/latex": [
       "\\begin{enumerate*}\n",
       "\\item 'RhythmScore'\n",
       "\\item 'AudioLoudness'\n",
       "\\item 'VocalContent'\n",
       "\\item 'AcousticQuality'\n",
       "\\item 'InstrumentalScore'\n",
       "\\item 'LivePerformanceLikelihood'\n",
       "\\item 'MoodScore'\n",
       "\\item 'TrackDurationMs'\n",
       "\\item 'Energy'\n",
       "\\item 'BeatsPerMinute'\n",
       "\\end{enumerate*}\n"
      ],
      "text/markdown": [
       "1. 'RhythmScore'\n",
       "2. 'AudioLoudness'\n",
       "3. 'VocalContent'\n",
       "4. 'AcousticQuality'\n",
       "5. 'InstrumentalScore'\n",
       "6. 'LivePerformanceLikelihood'\n",
       "7. 'MoodScore'\n",
       "8. 'TrackDurationMs'\n",
       "9. 'Energy'\n",
       "10. 'BeatsPerMinute'\n",
       "\n",
       "\n"
      ],
      "text/plain": [
       " [1] \"RhythmScore\"               \"AudioLoudness\"            \n",
       " [3] \"VocalContent\"              \"AcousticQuality\"          \n",
       " [5] \"InstrumentalScore\"         \"LivePerformanceLikelihood\"\n",
       " [7] \"MoodScore\"                 \"TrackDurationMs\"          \n",
       " [9] \"Energy\"                    \"BeatsPerMinute\"           "
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    }
   ],
   "source": [
    "column_names <- colnames(org)\n",
    "column_names"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 8,
   "id": "82d1b2ab",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-09-18T12:38:55.143846Z",
     "iopub.status.busy": "2025-09-18T12:38:55.142148Z",
     "iopub.status.idle": "2025-09-18T12:38:55.161561Z",
     "shell.execute_reply": "2025-09-18T12:38:55.159667Z"
    },
    "papermill": {
     "duration": 0.032387,
     "end_time": "2025-09-18T12:38:55.165707",
     "exception": false,
     "start_time": "2025-09-18T12:38:55.133320",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "data": {
      "text/html": [
       "<style>\n",
       ".list-inline {list-style: none; margin:0; padding: 0}\n",
       ".list-inline>li {display: inline-block}\n",
       ".list-inline>li:not(:last-child)::after {content: \"\\00b7\"; padding: 0 .5ex}\n",
       "</style>\n",
       "<ol class=list-inline><li>'RhythmScore'</li><li>'AudioLoudness'</li><li>'VocalContent'</li><li>'AcousticQuality'</li><li>'InstrumentalScore'</li><li>'LivePerformanceLikelihood'</li><li>'MoodScore'</li><li>'TrackDurationMs'</li><li>'Energy'</li><li>'BeatsPerMinute'</li></ol>\n"
      ],
      "text/latex": [
       "\\begin{enumerate*}\n",
       "\\item 'RhythmScore'\n",
       "\\item 'AudioLoudness'\n",
       "\\item 'VocalContent'\n",
       "\\item 'AcousticQuality'\n",
       "\\item 'InstrumentalScore'\n",
       "\\item 'LivePerformanceLikelihood'\n",
       "\\item 'MoodScore'\n",
       "\\item 'TrackDurationMs'\n",
       "\\item 'Energy'\n",
       "\\item 'BeatsPerMinute'\n",
       "\\end{enumerate*}\n"
      ],
      "text/markdown": [
       "1. 'RhythmScore'\n",
       "2. 'AudioLoudness'\n",
       "3. 'VocalContent'\n",
       "4. 'AcousticQuality'\n",
       "5. 'InstrumentalScore'\n",
       "6. 'LivePerformanceLikelihood'\n",
       "7. 'MoodScore'\n",
       "8. 'TrackDurationMs'\n",
       "9. 'Energy'\n",
       "10. 'BeatsPerMinute'\n",
       "\n",
       "\n"
      ],
      "text/plain": [
       " [1] \"RhythmScore\"               \"AudioLoudness\"            \n",
       " [3] \"VocalContent\"              \"AcousticQuality\"          \n",
       " [5] \"InstrumentalScore\"         \"LivePerformanceLikelihood\"\n",
       " [7] \"MoodScore\"                 \"TrackDurationMs\"          \n",
       " [9] \"Energy\"                    \"BeatsPerMinute\"           "
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    }
   ],
   "source": [
    "column_names <- colnames(train)\n",
    "column_names"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 9,
   "id": "66e1192a",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-09-18T12:38:55.183969Z",
     "iopub.status.busy": "2025-09-18T12:38:55.182246Z",
     "iopub.status.idle": "2025-09-18T12:38:55.201903Z",
     "shell.execute_reply": "2025-09-18T12:38:55.200037Z"
    },
    "papermill": {
     "duration": 0.031031,
     "end_time": "2025-09-18T12:38:55.204450",
     "exception": false,
     "start_time": "2025-09-18T12:38:55.173419",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "data": {
      "text/html": [
       "<style>\n",
       ".list-inline {list-style: none; margin:0; padding: 0}\n",
       ".list-inline>li {display: inline-block}\n",
       ".list-inline>li:not(:last-child)::after {content: \"\\00b7\"; padding: 0 .5ex}\n",
       "</style>\n",
       "<ol class=list-inline><li>'RhythmScore'</li><li>'AudioLoudness'</li><li>'VocalContent'</li><li>'AcousticQuality'</li><li>'InstrumentalScore'</li><li>'LivePerformanceLikelihood'</li><li>'MoodScore'</li><li>'TrackDurationMs'</li><li>'Energy'</li></ol>\n"
      ],
      "text/latex": [
       "\\begin{enumerate*}\n",
       "\\item 'RhythmScore'\n",
       "\\item 'AudioLoudness'\n",
       "\\item 'VocalContent'\n",
       "\\item 'AcousticQuality'\n",
       "\\item 'InstrumentalScore'\n",
       "\\item 'LivePerformanceLikelihood'\n",
       "\\item 'MoodScore'\n",
       "\\item 'TrackDurationMs'\n",
       "\\item 'Energy'\n",
       "\\end{enumerate*}\n"
      ],
      "text/markdown": [
       "1. 'RhythmScore'\n",
       "2. 'AudioLoudness'\n",
       "3. 'VocalContent'\n",
       "4. 'AcousticQuality'\n",
       "5. 'InstrumentalScore'\n",
       "6. 'LivePerformanceLikelihood'\n",
       "7. 'MoodScore'\n",
       "8. 'TrackDurationMs'\n",
       "9. 'Energy'\n",
       "\n",
       "\n"
      ],
      "text/plain": [
       "[1] \"RhythmScore\"               \"AudioLoudness\"            \n",
       "[3] \"VocalContent\"              \"AcousticQuality\"          \n",
       "[5] \"InstrumentalScore\"         \"LivePerformanceLikelihood\"\n",
       "[7] \"MoodScore\"                 \"TrackDurationMs\"          \n",
       "[9] \"Energy\"                   "
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    }
   ],
   "source": [
    "column_names <- colnames(test)\n",
    "column_names"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 10,
   "id": "e1cb0bf6",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-09-18T12:38:55.222092Z",
     "iopub.status.busy": "2025-09-18T12:38:55.220366Z",
     "iopub.status.idle": "2025-09-18T12:38:55.341393Z",
     "shell.execute_reply": "2025-09-18T12:38:55.339534Z"
    },
    "papermill": {
     "duration": 0.132717,
     "end_time": "2025-09-18T12:38:55.344049",
     "exception": false,
     "start_time": "2025-09-18T12:38:55.211332",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "data": {
      "text/html": [
       "<table class=\"dataframe\">\n",
       "<caption>A matrix: 10 × 10 of type dbl</caption>\n",
       "<thead>\n",
       "\t<tr><th></th><th scope=col>RhythmScore</th><th scope=col>AudioLoudness</th><th scope=col>VocalContent</th><th scope=col>AcousticQuality</th><th scope=col>InstrumentalScore</th><th scope=col>LivePerformanceLikelihood</th><th scope=col>MoodScore</th><th scope=col>TrackDurationMs</th><th scope=col>Energy</th><th scope=col>BeatsPerMinute</th></tr>\n",
       "</thead>\n",
       "<tbody>\n",
       "\t<tr><th scope=row>RhythmScore</th><td> 1.0000</td><td>-0.0174</td><td> 0.0087</td><td> 0.0282</td><td> 0.0110</td><td> 0.0315</td><td>-0.0089</td><td>-0.0176</td><td>-0.1473</td><td> 0.0054</td></tr>\n",
       "\t<tr><th scope=row>AudioLoudness</th><td>-0.0174</td><td> 1.0000</td><td>-0.0094</td><td>-0.0130</td><td> 0.0038</td><td>-0.0216</td><td>-0.0273</td><td> 0.0045</td><td> 0.1924</td><td>-0.0033</td></tr>\n",
       "\t<tr><th scope=row>VocalContent</th><td> 0.0087</td><td>-0.0094</td><td> 1.0000</td><td> 0.0094</td><td>-0.0177</td><td>-0.1203</td><td> 0.0587</td><td> 0.0182</td><td> 0.0161</td><td> 0.0049</td></tr>\n",
       "\t<tr><th scope=row>AcousticQuality</th><td> 0.0282</td><td>-0.0130</td><td> 0.0094</td><td> 1.0000</td><td> 0.0032</td><td> 0.0097</td><td> 0.0370</td><td>-0.0225</td><td>-0.4182</td><td>-0.0008</td></tr>\n",
       "\t<tr><th scope=row>InstrumentalScore</th><td> 0.0110</td><td> 0.0038</td><td>-0.0177</td><td> 0.0032</td><td> 1.0000</td><td>-0.0024</td><td> 0.0047</td><td> 0.0093</td><td>-0.0198</td><td> 0.0019</td></tr>\n",
       "\t<tr><th scope=row>LivePerformanceLikelihood</th><td> 0.0315</td><td>-0.0216</td><td>-0.1203</td><td> 0.0097</td><td>-0.0024</td><td> 1.0000</td><td> 0.0155</td><td> 0.0052</td><td>-0.2663</td><td> 0.0035</td></tr>\n",
       "\t<tr><th scope=row>MoodScore</th><td>-0.0089</td><td>-0.0273</td><td> 0.0587</td><td> 0.0370</td><td> 0.0047</td><td> 0.0155</td><td> 1.0000</td><td>-0.0148</td><td>-0.2417</td><td> 0.0071</td></tr>\n",
       "\t<tr><th scope=row>TrackDurationMs</th><td>-0.0176</td><td> 0.0045</td><td> 0.0182</td><td>-0.0225</td><td> 0.0093</td><td> 0.0052</td><td>-0.0148</td><td> 1.0000</td><td> 0.0486</td><td> 0.0066</td></tr>\n",
       "\t<tr><th scope=row>Energy</th><td>-0.1473</td><td> 0.1924</td><td> 0.0161</td><td>-0.4182</td><td>-0.0198</td><td>-0.2663</td><td>-0.2417</td><td> 0.0486</td><td> 1.0000</td><td>-0.0044</td></tr>\n",
       "\t<tr><th scope=row>BeatsPerMinute</th><td> 0.0054</td><td>-0.0033</td><td> 0.0049</td><td>-0.0008</td><td> 0.0019</td><td> 0.0035</td><td> 0.0071</td><td> 0.0066</td><td>-0.0044</td><td> 1.0000</td></tr>\n",
       "</tbody>\n",
       "</table>\n"
      ],
      "text/latex": [
       "A matrix: 10 × 10 of type dbl\n",
       "\\begin{tabular}{r|llllllllll}\n",
       "  & RhythmScore & AudioLoudness & VocalContent & AcousticQuality & InstrumentalScore & LivePerformanceLikelihood & MoodScore & TrackDurationMs & Energy & BeatsPerMinute\\\\\n",
       "\\hline\n",
       "\tRhythmScore &  1.0000 & -0.0174 &  0.0087 &  0.0282 &  0.0110 &  0.0315 & -0.0089 & -0.0176 & -0.1473 &  0.0054\\\\\n",
       "\tAudioLoudness & -0.0174 &  1.0000 & -0.0094 & -0.0130 &  0.0038 & -0.0216 & -0.0273 &  0.0045 &  0.1924 & -0.0033\\\\\n",
       "\tVocalContent &  0.0087 & -0.0094 &  1.0000 &  0.0094 & -0.0177 & -0.1203 &  0.0587 &  0.0182 &  0.0161 &  0.0049\\\\\n",
       "\tAcousticQuality &  0.0282 & -0.0130 &  0.0094 &  1.0000 &  0.0032 &  0.0097 &  0.0370 & -0.0225 & -0.4182 & -0.0008\\\\\n",
       "\tInstrumentalScore &  0.0110 &  0.0038 & -0.0177 &  0.0032 &  1.0000 & -0.0024 &  0.0047 &  0.0093 & -0.0198 &  0.0019\\\\\n",
       "\tLivePerformanceLikelihood &  0.0315 & -0.0216 & -0.1203 &  0.0097 & -0.0024 &  1.0000 &  0.0155 &  0.0052 & -0.2663 &  0.0035\\\\\n",
       "\tMoodScore & -0.0089 & -0.0273 &  0.0587 &  0.0370 &  0.0047 &  0.0155 &  1.0000 & -0.0148 & -0.2417 &  0.0071\\\\\n",
       "\tTrackDurationMs & -0.0176 &  0.0045 &  0.0182 & -0.0225 &  0.0093 &  0.0052 & -0.0148 &  1.0000 &  0.0486 &  0.0066\\\\\n",
       "\tEnergy & -0.1473 &  0.1924 &  0.0161 & -0.4182 & -0.0198 & -0.2663 & -0.2417 &  0.0486 &  1.0000 & -0.0044\\\\\n",
       "\tBeatsPerMinute &  0.0054 & -0.0033 &  0.0049 & -0.0008 &  0.0019 &  0.0035 &  0.0071 &  0.0066 & -0.0044 &  1.0000\\\\\n",
       "\\end{tabular}\n"
      ],
      "text/markdown": [
       "\n",
       "A matrix: 10 × 10 of type dbl\n",
       "\n",
       "| <!--/--> | RhythmScore | AudioLoudness | VocalContent | AcousticQuality | InstrumentalScore | LivePerformanceLikelihood | MoodScore | TrackDurationMs | Energy | BeatsPerMinute |\n",
       "|---|---|---|---|---|---|---|---|---|---|---|\n",
       "| RhythmScore |  1.0000 | -0.0174 |  0.0087 |  0.0282 |  0.0110 |  0.0315 | -0.0089 | -0.0176 | -0.1473 |  0.0054 |\n",
       "| AudioLoudness | -0.0174 |  1.0000 | -0.0094 | -0.0130 |  0.0038 | -0.0216 | -0.0273 |  0.0045 |  0.1924 | -0.0033 |\n",
       "| VocalContent |  0.0087 | -0.0094 |  1.0000 |  0.0094 | -0.0177 | -0.1203 |  0.0587 |  0.0182 |  0.0161 |  0.0049 |\n",
       "| AcousticQuality |  0.0282 | -0.0130 |  0.0094 |  1.0000 |  0.0032 |  0.0097 |  0.0370 | -0.0225 | -0.4182 | -0.0008 |\n",
       "| InstrumentalScore |  0.0110 |  0.0038 | -0.0177 |  0.0032 |  1.0000 | -0.0024 |  0.0047 |  0.0093 | -0.0198 |  0.0019 |\n",
       "| LivePerformanceLikelihood |  0.0315 | -0.0216 | -0.1203 |  0.0097 | -0.0024 |  1.0000 |  0.0155 |  0.0052 | -0.2663 |  0.0035 |\n",
       "| MoodScore | -0.0089 | -0.0273 |  0.0587 |  0.0370 |  0.0047 |  0.0155 |  1.0000 | -0.0148 | -0.2417 |  0.0071 |\n",
       "| TrackDurationMs | -0.0176 |  0.0045 |  0.0182 | -0.0225 |  0.0093 |  0.0052 | -0.0148 |  1.0000 |  0.0486 |  0.0066 |\n",
       "| Energy | -0.1473 |  0.1924 |  0.0161 | -0.4182 | -0.0198 | -0.2663 | -0.2417 |  0.0486 |  1.0000 | -0.0044 |\n",
       "| BeatsPerMinute |  0.0054 | -0.0033 |  0.0049 | -0.0008 |  0.0019 |  0.0035 |  0.0071 |  0.0066 | -0.0044 |  1.0000 |\n",
       "\n"
      ],
      "text/plain": [
       "                          RhythmScore AudioLoudness VocalContent\n",
       "RhythmScore                1.0000     -0.0174        0.0087     \n",
       "AudioLoudness             -0.0174      1.0000       -0.0094     \n",
       "VocalContent               0.0087     -0.0094        1.0000     \n",
       "AcousticQuality            0.0282     -0.0130        0.0094     \n",
       "InstrumentalScore          0.0110      0.0038       -0.0177     \n",
       "LivePerformanceLikelihood  0.0315     -0.0216       -0.1203     \n",
       "MoodScore                 -0.0089     -0.0273        0.0587     \n",
       "TrackDurationMs           -0.0176      0.0045        0.0182     \n",
       "Energy                    -0.1473      0.1924        0.0161     \n",
       "BeatsPerMinute             0.0054     -0.0033        0.0049     \n",
       "                          AcousticQuality InstrumentalScore\n",
       "RhythmScore                0.0282          0.0110          \n",
       "AudioLoudness             -0.0130          0.0038          \n",
       "VocalContent               0.0094         -0.0177          \n",
       "AcousticQuality            1.0000          0.0032          \n",
       "InstrumentalScore          0.0032          1.0000          \n",
       "LivePerformanceLikelihood  0.0097         -0.0024          \n",
       "MoodScore                  0.0370          0.0047          \n",
       "TrackDurationMs           -0.0225          0.0093          \n",
       "Energy                    -0.4182         -0.0198          \n",
       "BeatsPerMinute            -0.0008          0.0019          \n",
       "                          LivePerformanceLikelihood MoodScore TrackDurationMs\n",
       "RhythmScore                0.0315                   -0.0089   -0.0176        \n",
       "AudioLoudness             -0.0216                   -0.0273    0.0045        \n",
       "VocalContent              -0.1203                    0.0587    0.0182        \n",
       "AcousticQuality            0.0097                    0.0370   -0.0225        \n",
       "InstrumentalScore         -0.0024                    0.0047    0.0093        \n",
       "LivePerformanceLikelihood  1.0000                    0.0155    0.0052        \n",
       "MoodScore                  0.0155                    1.0000   -0.0148        \n",
       "TrackDurationMs            0.0052                   -0.0148    1.0000        \n",
       "Energy                    -0.2663                   -0.2417    0.0486        \n",
       "BeatsPerMinute             0.0035                    0.0071    0.0066        \n",
       "                          Energy  BeatsPerMinute\n",
       "RhythmScore               -0.1473  0.0054       \n",
       "AudioLoudness              0.1924 -0.0033       \n",
       "VocalContent               0.0161  0.0049       \n",
       "AcousticQuality           -0.4182 -0.0008       \n",
       "InstrumentalScore         -0.0198  0.0019       \n",
       "LivePerformanceLikelihood -0.2663  0.0035       \n",
       "MoodScore                 -0.2417  0.0071       \n",
       "TrackDurationMs            0.0486  0.0066       \n",
       "Energy                     1.0000 -0.0044       \n",
       "BeatsPerMinute            -0.0044  1.0000       "
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    }
   ],
   "source": [
    "#find correlation\n",
    "round(cor(train),4)"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 11,
   "id": "3ea87d2a",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-09-18T12:38:55.362666Z",
     "iopub.status.busy": "2025-09-18T12:38:55.360983Z",
     "iopub.status.idle": "2025-09-18T12:38:55.461153Z",
     "shell.execute_reply": "2025-09-18T12:38:55.457007Z"
    },
    "papermill": {
     "duration": 0.116316,
     "end_time": "2025-09-18T12:38:55.468118",
     "exception": false,
     "start_time": "2025-09-18T12:38:55.351802",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "data": {
      "text/plain": [
       "\n",
       "Call:\n",
       "lm(formula = BeatsPerMinute ~ RhythmScore + AudioLoudness + VocalContent + \n",
       "    AcousticQuality + InstrumentalScore + LivePerformanceLikelihood + \n",
       "    MoodScore + TrackDurationMs + Energy, data = org)\n",
       "\n",
       "Residuals:\n",
       "    Min      1Q  Median      3Q     Max \n",
       "-72.058 -18.124  -0.257  17.791  86.384 \n",
       "\n",
       "Coefficients:\n",
       "                            Estimate Std. Error t value Pr(>|t|)    \n",
       "(Intercept)                1.184e+02  1.660e+00  71.335   <2e-16 ***\n",
       "RhythmScore               -2.219e-01  1.261e+00  -0.176    0.860    \n",
       "AudioLoudness              4.437e-02  4.719e-02   0.940    0.347    \n",
       "VocalContent              -1.737e+00  3.774e+00  -0.460    0.645    \n",
       "AcousticQuality            5.454e-01  9.977e-01   0.547    0.585    \n",
       "InstrumentalScore         -1.121e+00  1.388e+00  -0.808    0.419    \n",
       "LivePerformanceLikelihood  1.739e+00  1.729e+00   1.006    0.315    \n",
       "MoodScore                  4.834e-01  9.363e-01   0.516    0.606    \n",
       "TrackDurationMs            3.619e-06  3.282e-06   1.103    0.270    \n",
       "Energy                    -4.799e-01  9.071e-01  -0.529    0.597    \n",
       "---\n",
       "Signif. codes:  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1\n",
       "\n",
       "Residual standard error: 26.57 on 14623 degrees of freedom\n",
       "Multiple R-squared:  0.0003868,\tAdjusted R-squared:  -0.0002284 \n",
       "F-statistic: 0.6287 on 9 and 14623 DF,  p-value: 0.7735\n"
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    }
   ],
   "source": [
    "model1 <- lm(BeatsPerMinute ~  RhythmScore + AudioLoudness + VocalContent + AcousticQuality + InstrumentalScore + LivePerformanceLikelihood + MoodScore + TrackDurationMs + Energy ,data = org)\n",
    "summary(model1)"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 12,
   "id": "e1db4591",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-09-18T12:38:55.514270Z",
     "iopub.status.busy": "2025-09-18T12:38:55.512520Z",
     "iopub.status.idle": "2025-09-18T12:38:57.083893Z",
     "shell.execute_reply": "2025-09-18T12:38:57.079777Z"
    },
    "papermill": {
     "duration": 1.599234,
     "end_time": "2025-09-18T12:38:57.089967",
     "exception": false,
     "start_time": "2025-09-18T12:38:55.490733",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [],
   "source": [
    "prediction_train <- predict(model1, newdata = train, interval=\"prediction\")\n",
    "prediction_test <- predict(model1, newdata = test, interval=\"prediction\")\n",
    "\n",
    "train$Score <- prediction_train[, \"fit\"]\n",
    "train$ScoreUpper <- prediction_train[, \"upr\"]\n",
    "train$ScoreLower <- prediction_train[, \"lwr\"]\n",
    "\n",
    "train <- train[, c(1,2,3,4,5,6,7,8,9,11,12,13,10)]\n",
    "\n",
    "test$Score <- prediction_test[, \"fit\"]\n",
    "test$ScoreUpper <- prediction_test[, \"upr\"]\n",
    "test$ScoreLower <- prediction_test[, \"lwr\"]"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 13,
   "id": "f8a0393e",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-09-18T12:38:57.120306Z",
     "iopub.status.busy": "2025-09-18T12:38:57.118653Z",
     "iopub.status.idle": "2025-09-18T12:38:57.150087Z",
     "shell.execute_reply": "2025-09-18T12:38:57.148423Z"
    },
    "papermill": {
     "duration": 0.043536,
     "end_time": "2025-09-18T12:38:57.152514",
     "exception": false,
     "start_time": "2025-09-18T12:38:57.108978",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "data": {
      "text/html": [
       "<table class=\"dataframe\">\n",
       "<caption>A data.frame: 2 × 13</caption>\n",
       "<thead>\n",
       "\t<tr><th></th><th scope=col>RhythmScore</th><th scope=col>AudioLoudness</th><th scope=col>VocalContent</th><th scope=col>AcousticQuality</th><th scope=col>InstrumentalScore</th><th scope=col>LivePerformanceLikelihood</th><th scope=col>MoodScore</th><th scope=col>TrackDurationMs</th><th scope=col>Energy</th><th scope=col>Score</th><th scope=col>ScoreUpper</th><th scope=col>ScoreLower</th><th scope=col>BeatsPerMinute</th></tr>\n",
       "\t<tr><th></th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th></tr>\n",
       "</thead>\n",
       "<tbody>\n",
       "\t<tr><th scope=row>1</th><td>0.6036097</td><td> -7.636942</td><td>0.0235000</td><td>0.00000536</td><td>0.00000107</td><td>0.05138546</td><td>0.4098663</td><td>290715.6</td><td>0.8262667</td><td>118.8280</td><td>170.9180</td><td>66.73805</td><td>147.5302</td></tr>\n",
       "\t<tr><th scope=row>2</th><td>0.6394512</td><td>-16.267598</td><td>0.0715195</td><td>0.44492907</td><td>0.34941424</td><td>0.17052233</td><td>0.6510103</td><td>164519.5</td><td>0.1454000</td><td>118.3984</td><td>170.4921</td><td>66.30462</td><td>136.1596</td></tr>\n",
       "</tbody>\n",
       "</table>\n"
      ],
      "text/latex": [
       "A data.frame: 2 × 13\n",
       "\\begin{tabular}{r|lllllllllllll}\n",
       "  & RhythmScore & AudioLoudness & VocalContent & AcousticQuality & InstrumentalScore & LivePerformanceLikelihood & MoodScore & TrackDurationMs & Energy & Score & ScoreUpper & ScoreLower & BeatsPerMinute\\\\\n",
       "  & <dbl> & <dbl> & <dbl> & <dbl> & <dbl> & <dbl> & <dbl> & <dbl> & <dbl> & <dbl> & <dbl> & <dbl> & <dbl>\\\\\n",
       "\\hline\n",
       "\t1 & 0.6036097 &  -7.636942 & 0.0235000 & 0.00000536 & 0.00000107 & 0.05138546 & 0.4098663 & 290715.6 & 0.8262667 & 118.8280 & 170.9180 & 66.73805 & 147.5302\\\\\n",
       "\t2 & 0.6394512 & -16.267598 & 0.0715195 & 0.44492907 & 0.34941424 & 0.17052233 & 0.6510103 & 164519.5 & 0.1454000 & 118.3984 & 170.4921 & 66.30462 & 136.1596\\\\\n",
       "\\end{tabular}\n"
      ],
      "text/markdown": [
       "\n",
       "A data.frame: 2 × 13\n",
       "\n",
       "| <!--/--> | RhythmScore &lt;dbl&gt; | AudioLoudness &lt;dbl&gt; | VocalContent &lt;dbl&gt; | AcousticQuality &lt;dbl&gt; | InstrumentalScore &lt;dbl&gt; | LivePerformanceLikelihood &lt;dbl&gt; | MoodScore &lt;dbl&gt; | TrackDurationMs &lt;dbl&gt; | Energy &lt;dbl&gt; | Score &lt;dbl&gt; | ScoreUpper &lt;dbl&gt; | ScoreLower &lt;dbl&gt; | BeatsPerMinute &lt;dbl&gt; |\n",
       "|---|---|---|---|---|---|---|---|---|---|---|---|---|---|\n",
       "| 1 | 0.6036097 |  -7.636942 | 0.0235000 | 0.00000536 | 0.00000107 | 0.05138546 | 0.4098663 | 290715.6 | 0.8262667 | 118.8280 | 170.9180 | 66.73805 | 147.5302 |\n",
       "| 2 | 0.6394512 | -16.267598 | 0.0715195 | 0.44492907 | 0.34941424 | 0.17052233 | 0.6510103 | 164519.5 | 0.1454000 | 118.3984 | 170.4921 | 66.30462 | 136.1596 |\n",
       "\n"
      ],
      "text/plain": [
       "  RhythmScore AudioLoudness VocalContent AcousticQuality InstrumentalScore\n",
       "1 0.6036097    -7.636942    0.0235000    0.00000536      0.00000107       \n",
       "2 0.6394512   -16.267598    0.0715195    0.44492907      0.34941424       \n",
       "  LivePerformanceLikelihood MoodScore TrackDurationMs Energy    Score   \n",
       "1 0.05138546                0.4098663 290715.6        0.8262667 118.8280\n",
       "2 0.17052233                0.6510103 164519.5        0.1454000 118.3984\n",
       "  ScoreUpper ScoreLower BeatsPerMinute\n",
       "1 170.9180   66.73805   147.5302      \n",
       "2 170.4921   66.30462   136.1596      "
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    }
   ],
   "source": [
    "head(train,n=2)"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 14,
   "id": "4335ec08",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-09-18T12:38:57.172426Z",
     "iopub.status.busy": "2025-09-18T12:38:57.169926Z",
     "iopub.status.idle": "2025-09-18T12:38:57.230808Z",
     "shell.execute_reply": "2025-09-18T12:38:57.228925Z"
    },
    "papermill": {
     "duration": 0.074021,
     "end_time": "2025-09-18T12:38:57.233846",
     "exception": false,
     "start_time": "2025-09-18T12:38:57.159825",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "data": {
      "text/html": [
       "<table class=\"dataframe\">\n",
       "<caption>A data.frame: 2 × 12</caption>\n",
       "<thead>\n",
       "\t<tr><th></th><th scope=col>RhythmScore</th><th scope=col>AudioLoudness</th><th scope=col>VocalContent</th><th scope=col>AcousticQuality</th><th scope=col>InstrumentalScore</th><th scope=col>LivePerformanceLikelihood</th><th scope=col>MoodScore</th><th scope=col>TrackDurationMs</th><th scope=col>Energy</th><th scope=col>Score</th><th scope=col>ScoreUpper</th><th scope=col>ScoreLower</th></tr>\n",
       "\t<tr><th></th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th></tr>\n",
       "</thead>\n",
       "<tbody>\n",
       "\t<tr><th scope=row>1</th><td>0.4100130</td><td>-16.79497</td><td>0.023500</td><td>0.2329096</td><td>0.01268883</td><td>0.27158546</td><td>0.6643215</td><td>302901.5</td><td>0.4248667</td><td>119.3200</td><td>171.4137</td><td>67.22629</td></tr>\n",
       "\t<tr><th scope=row>2</th><td>0.4630707</td><td> -1.35700</td><td>0.141818</td><td>0.0577253</td><td>0.25794192</td><td>0.09762371</td><td>0.8295523</td><td>221995.7</td><td>0.8460000</td><td>118.6998</td><td>170.7944</td><td>66.60520</td></tr>\n",
       "</tbody>\n",
       "</table>\n"
      ],
      "text/latex": [
       "A data.frame: 2 × 12\n",
       "\\begin{tabular}{r|llllllllllll}\n",
       "  & RhythmScore & AudioLoudness & VocalContent & AcousticQuality & InstrumentalScore & LivePerformanceLikelihood & MoodScore & TrackDurationMs & Energy & Score & ScoreUpper & ScoreLower\\\\\n",
       "  & <dbl> & <dbl> & <dbl> & <dbl> & <dbl> & <dbl> & <dbl> & <dbl> & <dbl> & <dbl> & <dbl> & <dbl>\\\\\n",
       "\\hline\n",
       "\t1 & 0.4100130 & -16.79497 & 0.023500 & 0.2329096 & 0.01268883 & 0.27158546 & 0.6643215 & 302901.5 & 0.4248667 & 119.3200 & 171.4137 & 67.22629\\\\\n",
       "\t2 & 0.4630707 &  -1.35700 & 0.141818 & 0.0577253 & 0.25794192 & 0.09762371 & 0.8295523 & 221995.7 & 0.8460000 & 118.6998 & 170.7944 & 66.60520\\\\\n",
       "\\end{tabular}\n"
      ],
      "text/markdown": [
       "\n",
       "A data.frame: 2 × 12\n",
       "\n",
       "| <!--/--> | RhythmScore &lt;dbl&gt; | AudioLoudness &lt;dbl&gt; | VocalContent &lt;dbl&gt; | AcousticQuality &lt;dbl&gt; | InstrumentalScore &lt;dbl&gt; | LivePerformanceLikelihood &lt;dbl&gt; | MoodScore &lt;dbl&gt; | TrackDurationMs &lt;dbl&gt; | Energy &lt;dbl&gt; | Score &lt;dbl&gt; | ScoreUpper &lt;dbl&gt; | ScoreLower &lt;dbl&gt; |\n",
       "|---|---|---|---|---|---|---|---|---|---|---|---|---|\n",
       "| 1 | 0.4100130 | -16.79497 | 0.023500 | 0.2329096 | 0.01268883 | 0.27158546 | 0.6643215 | 302901.5 | 0.4248667 | 119.3200 | 171.4137 | 67.22629 |\n",
       "| 2 | 0.4630707 |  -1.35700 | 0.141818 | 0.0577253 | 0.25794192 | 0.09762371 | 0.8295523 | 221995.7 | 0.8460000 | 118.6998 | 170.7944 | 66.60520 |\n",
       "\n"
      ],
      "text/plain": [
       "  RhythmScore AudioLoudness VocalContent AcousticQuality InstrumentalScore\n",
       "1 0.4100130   -16.79497     0.023500     0.2329096       0.01268883       \n",
       "2 0.4630707    -1.35700     0.141818     0.0577253       0.25794192       \n",
       "  LivePerformanceLikelihood MoodScore TrackDurationMs Energy    Score   \n",
       "1 0.27158546                0.6643215 302901.5        0.4248667 119.3200\n",
       "2 0.09762371                0.8295523 221995.7        0.8460000 118.6998\n",
       "  ScoreUpper ScoreLower\n",
       "1 171.4137   67.22629  \n",
       "2 170.7944   66.60520  "
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    }
   ],
   "source": [
    "head(test,n=2)"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 15,
   "id": "4f12417d",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-09-18T12:38:57.252665Z",
     "iopub.status.busy": "2025-09-18T12:38:57.251062Z",
     "iopub.status.idle": "2025-09-18T12:38:58.262198Z",
     "shell.execute_reply": "2025-09-18T12:38:58.260396Z"
    },
    "papermill": {
     "duration": 1.023193,
     "end_time": "2025-09-18T12:38:58.264808",
     "exception": false,
     "start_time": "2025-09-18T12:38:57.241615",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "data": {
      "text/plain": [
       "\n",
       "Call:\n",
       "lm(formula = BeatsPerMinute ~ RhythmScore + AudioLoudness + VocalContent + \n",
       "    AcousticQuality + InstrumentalScore + LivePerformanceLikelihood + \n",
       "    MoodScore + TrackDurationMs + Energy + Score + ScoreUpper + \n",
       "    ScoreLower, data = train)\n",
       "\n",
       "Residuals:\n",
       "    Min      1Q  Median      3Q     Max \n",
       "-72.862 -17.993  -0.292  17.666  87.788 \n",
       "\n",
       "Coefficients: (2 not defined because of singularities)\n",
       "                            Estimate Std. Error t value Pr(>|t|)\n",
       "(Intercept)                1.190e+03  1.253e+03   0.950    0.342\n",
       "RhythmScore               -4.792e-01  1.598e+00  -0.300    0.764\n",
       "AudioLoudness              2.630e-01  3.248e-01   0.810    0.418\n",
       "VocalContent              -8.302e+00  1.267e+01  -0.655    0.512\n",
       "AcousticQuality            3.252e+00  4.071e+00   0.799    0.424\n",
       "InstrumentalScore         -6.649e+00  8.194e+00  -0.812    0.417\n",
       "LivePerformanceLikelihood  1.172e+01  1.285e+01   0.912    0.362\n",
       "MoodScore                  3.807e+00  3.569e+00   1.067    0.286\n",
       "TrackDurationMs            2.577e-05  2.657e-05   0.970    0.332\n",
       "Energy                    -3.146e+00  3.475e+00  -0.905    0.365\n",
       "Score                             NA         NA      NA       NA\n",
       "ScoreUpper                -6.296e+00  7.350e+00  -0.857    0.392\n",
       "ScoreLower                        NA         NA      NA       NA\n",
       "\n",
       "Residual standard error: 26.47 on 524153 degrees of freedom\n",
       "Multiple R-squared:  0.0001763,\tAdjusted R-squared:  0.0001572 \n",
       "F-statistic: 9.242 on 10 and 524153 DF,  p-value: 1.776e-15\n"
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    }
   ],
   "source": [
    "model1 <- lm(BeatsPerMinute ~  RhythmScore + AudioLoudness + VocalContent + AcousticQuality + InstrumentalScore + LivePerformanceLikelihood + MoodScore + TrackDurationMs + Energy + Score + ScoreUpper + ScoreLower ,data = train)\n",
    "summary(model1)"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 16,
   "id": "d6d27332",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-09-18T12:38:58.284440Z",
     "iopub.status.busy": "2025-09-18T12:38:58.282830Z",
     "iopub.status.idle": "2025-09-18T12:38:59.745226Z",
     "shell.execute_reply": "2025-09-18T12:38:59.740322Z"
    },
    "papermill": {
     "duration": 1.478899,
     "end_time": "2025-09-18T12:38:59.751901",
     "exception": false,
     "start_time": "2025-09-18T12:38:58.273002",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [],
   "source": [
    "prediction <- predict(model1, newdata = test)"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 17,
   "id": "183d0337",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-09-18T12:38:59.808224Z",
     "iopub.status.busy": "2025-09-18T12:38:59.804101Z",
     "iopub.status.idle": "2025-09-18T12:38:59.844275Z",
     "shell.execute_reply": "2025-09-18T12:38:59.839531Z"
    },
    "papermill": {
     "duration": 0.074809,
     "end_time": "2025-09-18T12:38:59.850992",
     "exception": false,
     "start_time": "2025-09-18T12:38:59.776183",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "data": {
      "text/html": [
       "<style>\n",
       ".dl-inline {width: auto; margin:0; padding: 0}\n",
       ".dl-inline>dt, .dl-inline>dd {float: none; width: auto; display: inline-block}\n",
       ".dl-inline>dt::after {content: \":\\0020\"; padding-right: .5ex}\n",
       ".dl-inline>dt:not(:first-of-type) {padding-left: .5ex}\n",
       "</style><dl class=dl-inline><dt>1</dt><dd>119.145230502971</dd><dt>2</dt><dd>119.076544275178</dd><dt>3</dt><dd>119.552318886577</dd></dl>\n"
      ],
      "text/latex": [
       "\\begin{description*}\n",
       "\\item[1] 119.145230502971\n",
       "\\item[2] 119.076544275178\n",
       "\\item[3] 119.552318886577\n",
       "\\end{description*}\n"
      ],
      "text/markdown": [
       "1\n",
       ":   119.1452305029712\n",
       ":   119.0765442751783\n",
       ":   119.552318886577\n",
       "\n"
      ],
      "text/plain": [
       "       1        2        3 \n",
       "119.1452 119.0765 119.5523 "
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    }
   ],
   "source": [
    "head(prediction,n=3)"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 18,
   "id": "b38bbdb1",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-09-18T12:38:59.875143Z",
     "iopub.status.busy": "2025-09-18T12:38:59.873450Z",
     "iopub.status.idle": "2025-09-18T12:38:59.935519Z",
     "shell.execute_reply": "2025-09-18T12:38:59.932906Z"
    },
    "papermill": {
     "duration": 0.07531,
     "end_time": "2025-09-18T12:38:59.938913",
     "exception": false,
     "start_time": "2025-09-18T12:38:59.863603",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "data": {
      "text/html": [
       "174722"
      ],
      "text/latex": [
       "174722"
      ],
      "text/markdown": [
       "174722"
      ],
      "text/plain": [
       "[1] 174722"
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    }
   ],
   "source": [
    "length(prediction)"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 19,
   "id": "e43c74f4",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-09-18T12:38:59.958989Z",
     "iopub.status.busy": "2025-09-18T12:38:59.957264Z",
     "iopub.status.idle": "2025-09-18T12:38:59.977202Z",
     "shell.execute_reply": "2025-09-18T12:38:59.974589Z"
    },
    "papermill": {
     "duration": 0.033339,
     "end_time": "2025-09-18T12:38:59.980221",
     "exception": false,
     "start_time": "2025-09-18T12:38:59.946882",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "data": {
      "text/html": [
       "<style>\n",
       ".list-inline {list-style: none; margin:0; padding: 0}\n",
       ".list-inline>li {display: inline-block}\n",
       ".list-inline>li:not(:last-child)::after {content: \"\\00b7\"; padding: 0 .5ex}\n",
       "</style>\n",
       "<ol class=list-inline><li>174722</li><li>2</li></ol>\n"
      ],
      "text/latex": [
       "\\begin{enumerate*}\n",
       "\\item 174722\n",
       "\\item 2\n",
       "\\end{enumerate*}\n"
      ],
      "text/markdown": [
       "1. 174722\n",
       "2. 2\n",
       "\n",
       "\n"
      ],
      "text/plain": [
       "[1] 174722      2"
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    }
   ],
   "source": [
    "dim(submission)"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 20,
   "id": "76ad5938",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-09-18T12:39:00.000219Z",
     "iopub.status.busy": "2025-09-18T12:38:59.998306Z",
     "iopub.status.idle": "2025-09-18T12:39:00.477607Z",
     "shell.execute_reply": "2025-09-18T12:39:00.475772Z"
    },
    "papermill": {
     "duration": 0.4923,
     "end_time": "2025-09-18T12:39:00.480541",
     "exception": false,
     "start_time": "2025-09-18T12:38:59.988241",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [],
   "source": [
    "submission$BeatsPerMinute <- prediction\n",
    "\n",
    "write.csv(submission, file = \"submission.csv\", row.names = FALSE)"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 21,
   "id": "70c25624",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-09-18T12:39:00.501241Z",
     "iopub.status.busy": "2025-09-18T12:39:00.499660Z",
     "iopub.status.idle": "2025-09-18T12:39:00.523156Z",
     "shell.execute_reply": "2025-09-18T12:39:00.521334Z"
    },
    "papermill": {
     "duration": 0.036418,
     "end_time": "2025-09-18T12:39:00.525856",
     "exception": false,
     "start_time": "2025-09-18T12:39:00.489438",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "data": {
      "text/html": [
       "<table class=\"dataframe\">\n",
       "<caption>A data.frame: 5 × 2</caption>\n",
       "<thead>\n",
       "\t<tr><th></th><th scope=col>id</th><th scope=col>BeatsPerMinute</th></tr>\n",
       "\t<tr><th></th><th scope=col>&lt;int&gt;</th><th scope=col>&lt;dbl&gt;</th></tr>\n",
       "</thead>\n",
       "<tbody>\n",
       "\t<tr><th scope=row>1</th><td>524164</td><td>119.1452</td></tr>\n",
       "\t<tr><th scope=row>2</th><td>524165</td><td>119.0765</td></tr>\n",
       "\t<tr><th scope=row>3</th><td>524166</td><td>119.5523</td></tr>\n",
       "\t<tr><th scope=row>4</th><td>524167</td><td>119.4980</td></tr>\n",
       "\t<tr><th scope=row>5</th><td>524168</td><td>119.1408</td></tr>\n",
       "</tbody>\n",
       "</table>\n"
      ],
      "text/latex": [
       "A data.frame: 5 × 2\n",
       "\\begin{tabular}{r|ll}\n",
       "  & id & BeatsPerMinute\\\\\n",
       "  & <int> & <dbl>\\\\\n",
       "\\hline\n",
       "\t1 & 524164 & 119.1452\\\\\n",
       "\t2 & 524165 & 119.0765\\\\\n",
       "\t3 & 524166 & 119.5523\\\\\n",
       "\t4 & 524167 & 119.4980\\\\\n",
       "\t5 & 524168 & 119.1408\\\\\n",
       "\\end{tabular}\n"
      ],
      "text/markdown": [
       "\n",
       "A data.frame: 5 × 2\n",
       "\n",
       "| <!--/--> | id &lt;int&gt; | BeatsPerMinute &lt;dbl&gt; |\n",
       "|---|---|---|\n",
       "| 1 | 524164 | 119.1452 |\n",
       "| 2 | 524165 | 119.0765 |\n",
       "| 3 | 524166 | 119.5523 |\n",
       "| 4 | 524167 | 119.4980 |\n",
       "| 5 | 524168 | 119.1408 |\n",
       "\n"
      ],
      "text/plain": [
       "  id     BeatsPerMinute\n",
       "1 524164 119.1452      \n",
       "2 524165 119.0765      \n",
       "3 524166 119.5523      \n",
       "4 524167 119.4980      \n",
       "5 524168 119.1408      "
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    }
   ],
   "source": [
    "head(submission,n=5)"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 22,
   "id": "bb5325fc",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-09-18T12:39:00.547036Z",
     "iopub.status.busy": "2025-09-18T12:39:00.545279Z",
     "iopub.status.idle": "2025-09-18T12:39:00.558646Z",
     "shell.execute_reply": "2025-09-18T12:39:00.556859Z"
    },
    "papermill": {
     "duration": 0.026957,
     "end_time": "2025-09-18T12:39:00.561196",
     "exception": false,
     "start_time": "2025-09-18T12:39:00.534239",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [],
   "source": [
    "#Detect Heteroscedasticity\n",
    "#Heteroscedasticity occurs when the variance of the error terms is not constant across all levels of the independent variables. "
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 23,
   "id": "517b432c",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-09-18T12:39:00.582112Z",
     "iopub.status.busy": "2025-09-18T12:39:00.580490Z",
     "iopub.status.idle": "2025-09-18T12:39:28.741434Z",
     "shell.execute_reply": "2025-09-18T12:39:28.739090Z"
    },
    "papermill": {
     "duration": 28.177275,
     "end_time": "2025-09-18T12:39:28.746795",
     "exception": false,
     "start_time": "2025-09-18T12:39:00.569520",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "data": {
      "image/png": "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\n3zyAZaPvBEE/INJB5VhZxgGvqTkgMUDK8wAw7fx9QRDu/DlBzvPOSpl/1wXzhiVxvLx7hJOd\ne4CltRUAaAKrR4SHuthaAIBGrdC4Nd++ffvZhc054GTa2js2rupR3dHCpmZGkZ5di0Gf19nP\nCgBqf5/+H71chBDyuuzZswcAvvjii9d9ImWgYPdkFOzeZWfOnKlSpQrP/6tsOy4u7uzZsy/3\nQPv371coFAAgl8ujoqIiIiLc3NyUSiUesXXr1gaD4cqldDc3V3YaocNmDh8+3N3dnS0ZdyVH\nHP7k/nOzzw8CgA7H7+RcHosx7iMrCScJMehyPTgAjrt799aZMxfbOat9W/+0KdrFymvc+fPn\nh9Wr4aeWc1J7rnRXHMce/kMt4dwrulvY1BMEoST/L62Ur/fd/2e4bUOqOVQZ7KmQvlHBLjc3\nd+LEiVFRUYGBgZGRkYMHD87KyipzS51O98cff3zyySddu3YdPXr08ePH2aqHDx+mpaVt3779\nv4v4hJA33Jsc7KRPKtEj5N313XffderUSa/XW1hYBAUFAcDZs2dLSkrS0tKio6N3794dERHx\nUg6k1+u7dOlSXFys1WqtrKwOHDggl8vd3d0tLS0LCgoAYO3atatXr16wYMHt23eWL1/esWNH\nAHBLaDuptuvIkSNbNq20bedVAPiladiU83f9Qqu36PHptH4N9ff3c5wCAP7nbfVgzx6O4y7M\nHLD8oV6AC5VCq98DAEFwdHA1CAAAmgOjuty+k6MbHxSUWnpe2ewMVVb2s2dMHtGrR2axXuA4\nThAe6YVH524ovevoBJAqg8Z4aqd8fhDa+wHA3aPTm36ZMfrrarO7CTnnj5SUeMpkMgAQBOGv\nv/7Kysqys7OrUKGCRCIp89V4+PDhzp07L1++LJPJwsPD7ezsTpw4UVBQYDAYNBqNQqEIDg4O\nDAw0faIgCDdu3CgoKHBxcbG0tDRau2LFiu7duxcXF7MlR44cmTlz5rhx40aOHCnecsOGDd26\ndbt79y5b8umnn/r6+s6ZM2f58uVr164tKfmn24q/v//YsWM7dOjwpP9w2c6dOzd//vw///zz\n3r17rq6udevW7dWrl6urq+mW6enp33///fbt27OysiwtLatVq9a+ffsaNWrg2oyMjG3btt28\nebOwsDAnJyc7O5vneW9vbzc3N5lMJpVKLSws8vLyioqK3NzcfH19K1WqZDAYLly4kJOTk5eX\n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\nwIEDZNEUkuHR0dFjxozhL6PMoWla60hqgUCg1pwsEolomq5Tp86qVas2bty4du3aQ4cOFRYW\n3r9/f/LkyWFhYWTJ+bFjx/Jbv+bPn1/ap46Pj3/58iUAJCUlsSwrl8vJ7VmF5uN99eoVTdO9\nevXif5EBoGfPnnl5ed999x0AjBo1qlOnTiQO7tix461bt/SqIViWZcn3vVevXjdv3iRbbt68\nSfr2dejQQe/TFhcXX7p06cSJExkZVd9/6X2Agd27U5R9iHyBy3k8mbCxPLgqDBm8rKysuXPn\nhoeHOzg4eHp6du/eff/+/SzLnjp1asyYMTExMVFRUUlJSaTnTSWv9fvvv8fHx5MgTCqVtmnT\nRscteGZmpqmpqb29PfcEVu33kltKXK0jeVhYWFhYWGBgoJmZGdfgVKdOnSNHjgwcODAkJMTf\n379Dhw78ddtomuYijCZNmjx48ICfktOnTxsZGXFXsbCwIPOjMgwTEBDAzcDi6Oj45Zdfnj17\nVqFQkKkfGjVqpJny0gbYWlpakjmc165dSx6Im5ubkz6F74yHh8eOHTtI2tTaRKVSKQlQGIYJ\nDw9PTEz84osvzM3NZTLZwoULHz58SD6so6OjjljNzs6OC8HL85CXLG/ApY38Ry153AFc3/8q\nRIIVqVRqamrKX9U0NTWVoqjQ0FCapvkhGvdnjYiI6N69e0xMDJnEccaMGTdu3Jg0aZLWII+m\n6YiICGtra6lUevHixYp+rVq1aiUQCBo3bmxnZ2dvbx8SEpKcnEza3YOCggAgKSlp0aJFgYGB\nANC2bduKLk4YGRlpZGTEfSnkcnliYiIAWFpaWllZMQzDfanHjx9f0cSrycvL4xaqtra25saw\nJyQk5OXlVfLkSG8Y2L07KkXuqVOnuHXcy1SeFjvS4q05izdCVSg/P788h+3atYus2E16fHOz\nH1MURdqBSMe+zZs37969mzylIj+07du3HzFiBL+xRG25IXJy8oORkpLStWvXuLi4ESNG/PLL\nL1rjVzI589y5cx89eqRUKlUq1c6dO7t06eLt7U3mjJ06derr16+54zMyMhwcHMiKbRRFLVy4\n8MyZM1yLjo2NjeazY4lEEh8f/+eff27fvp0M8jA2Nn769Clp9zI2NiZPh9WedZqampqYmKht\n5J+cW6utcePGJP7g5osmsRHJosjIyB07dsjl8j179pC8jY+P57rt8y1fvpz7mKdPn+bGAnMx\n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"
     },
     "metadata": {
      "image/png": {
       "height": 420,
       "width": 420
      }
     },
     "output_type": "display_data"
    }
   ],
   "source": [
    "#Scale-Location Plot (Square Root of Standardized Residuals vs. Fitted Values)\n",
    "library(ggplot2)\n",
    "plot(model1, which = 3)"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 24,
   "id": "9b18b4c2",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-09-18T12:39:28.776951Z",
     "iopub.status.busy": "2025-09-18T12:39:28.775180Z",
     "iopub.status.idle": "2025-09-18T12:39:30.093607Z",
     "shell.execute_reply": "2025-09-18T12:39:30.089500Z"
    },
    "papermill": {
     "duration": 1.340264,
     "end_time": "2025-09-18T12:39:30.100407",
     "exception": false,
     "start_time": "2025-09-18T12:39:28.760143",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "Loading required package: zoo\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\n",
      "Attaching package: ‘zoo’\n",
      "\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "The following objects are masked from ‘package:base’:\n",
      "\n",
      "    as.Date, as.Date.numeric\n",
      "\n",
      "\n"
     ]
    }
   ],
   "source": [
    "#BP test\n",
    "#The Breusch-Pagan (BP) test is used in R to detect heteroscedasticity in a linear regression model.\n",
    "\n",
    "library(lmtest)\n",
    "result=bptest(model1) #Breusch-Pagan Test"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 25,
   "id": "8e094939",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-09-18T12:39:30.184112Z",
     "iopub.status.busy": "2025-09-18T12:39:30.182579Z",
     "iopub.status.idle": "2025-09-18T12:39:30.200308Z",
     "shell.execute_reply": "2025-09-18T12:39:30.198640Z"
    },
    "papermill": {
     "duration": 0.056314,
     "end_time": "2025-09-18T12:39:30.202866",
     "exception": false,
     "start_time": "2025-09-18T12:39:30.146552",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "data": {
      "text/plain": [
       "\n",
       "\tstudentized Breusch-Pagan test\n",
       "\n",
       "data:  model1\n",
       "BP = 58.604, df = 10, p-value = 6.65e-09\n"
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    }
   ],
   "source": [
    "result"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "71475fc4",
   "metadata": {
    "papermill": {
     "duration": 0.012663,
     "end_time": "2025-09-18T12:39:30.228420",
     "exception": false,
     "start_time": "2025-09-18T12:39:30.215757",
     "status": "completed"
    },
    "tags": []
   },
   "source": [
    "\n",
    "As p-value is less than 0.05 (significance lavel), reject the null hypothesis of homoscedasticity (the variance of the residuals is constant across all levels of the independent variables) i.e. variance of the error term is not constant across all levels of the independent variables\n",
    "\n",
    "Heteroscedasticity is present in the model, and the standard errors of  regression coefficients may be unreliable."
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
    },
    {
     "datasetId": 8025996,
     "sourceId": 12699678,
     "sourceType": "datasetVersion"
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
   "duration": 58.292777,
   "end_time": "2025-09-18T12:39:30.467285",
   "environment_variables": {},
   "exception": null,
   "input_path": "__notebook__.ipynb",
   "output_path": "__notebook__.ipynb",
   "parameters": {},
   "start_time": "2025-09-18T12:38:32.174508",
   "version": "2.6.0"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 5
}
