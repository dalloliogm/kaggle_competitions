{
 "cells": [
  {
   "cell_type": "code",
   "execution_count": 1,
   "id": "69957cb3",
   "metadata": {
    "_execution_state": "idle",
    "_kg_hide-input": true,
    "_uuid": "051d70d956493feee0c6d64651c6a088724dca2a",
    "execution": {
     "iopub.execute_input": "2025-12-24T22:20:26.666469Z",
     "iopub.status.busy": "2025-12-24T22:20:26.664677Z",
     "iopub.status.idle": "2025-12-24T22:20:27.693400Z",
     "shell.execute_reply": "2025-12-24T22:20:27.692152Z"
    },
    "papermill": {
     "duration": 1.037837,
     "end_time": "2025-12-24T22:20:27.694954",
     "exception": false,
     "start_time": "2025-12-24T22:20:26.657117",
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
    }
   ],
   "source": [
    "# notebook to explore the data and biological meaning of the data\n",
    "# Sam Lycett\n",
    "# 22 Nov 2025\n",
    "\n",
    "# This is an R notebook\n",
    "\n",
    "########################################\n",
    "# Original notebook default set up\n",
    "########################################\n",
    "\n",
    "# This R environment comes with many helpful analytics packages installed\n",
    "# It is defined by the kaggle/rstats Docker image: https://github.com/kaggle/docker-rstats\n",
    "# For example, here's a helpful package to load\n",
    "\n",
    "library(tidyverse) # metapackage of all tidyverse packages\n",
    "\n",
    "# Input data files are available in the read-only \"../input/\" directory\n",
    "# For example, running this (by clicking run or pressing Shift+Enter) will list all files under the input directory\n",
    "\n",
    "# list.files(path = \"../input\")\n",
    "\n",
    "# You can write up to 20GB to the current directory (/kaggle/working/) that gets preserved as output when you create a version using \"Save & Run All\" \n",
    "# You can also write temporary files to /kaggle/temp/, but they won't be saved outside of the current session"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 2,
   "id": "7f0626c8",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-12-24T22:20:27.729611Z",
     "iopub.status.busy": "2025-12-24T22:20:27.707046Z",
     "iopub.status.idle": "2025-12-24T22:21:15.781085Z",
     "shell.execute_reply": "2025-12-24T22:21:15.779669Z"
    },
    "papermill": {
     "duration": 48.082237,
     "end_time": "2025-12-24T22:21:15.782899",
     "exception": false,
     "start_time": "2025-12-24T22:20:27.700662",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\n",
      "Attaching package: ‘seqinr’\n",
      "\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "The following object is masked from ‘package:dplyr’:\n",
      "\n",
      "    count\n",
      "\n",
      "\n"
     ]
    }
   ],
   "source": [
    "#########################################\n",
    "# Set up libraries\n",
    "#########################################\n",
    "\n",
    "outPath <- \"/kaggle/working/\"\n",
    "lib     <- paste0(outPath,\"R-site-library/\")\n",
    "\n",
    "# do this once\n",
    "if (!dir.exists(lib)) {\n",
    "    dir.create(lib)\n",
    "    install.packages(\"seqinr\",lib=lib)\n",
    "    install.packages(\"ontologyIndex\",lib=lib)\n",
    "    install.packages(\"ontologySimilarity\",lib=lib)    \n",
    "}\n",
    "\n",
    "# load packages\n",
    "library(knitr)\n",
    "library(seqinr,lib=lib)\n",
    "library(ontologyIndex,lib=lib)\n",
    "library(ontologySimilarity,lib=lib)\n",
    "\n",
    "#########################################\n",
    "# Set up paths\n",
    "#########################################\n",
    "\n",
    "dataPath = \"../input/cafa-6-protein-function-prediction/\"\n",
    "trainPath <- paste0(dataPath,\"Train/\")\n",
    "testPath  <- paste0(dataPath,\"Test/\")\n",
    "train_fnames <- dir(trainPath)\n",
    "test_fnames  <- dir(testPath)\n",
    "other_fnames <- dir(dataPath)\n",
    "other_fnames <- other_fnames[grep(\"tsv$\",other_fnames)]"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "e22fb30d",
   "metadata": {
    "papermill": {
     "duration": 0.005095,
     "end_time": "2025-12-24T22:21:15.794076",
     "exception": false,
     "start_time": "2025-12-24T22:21:15.788981",
     "status": "completed"
    },
    "tags": []
   },
   "source": [
    "# CAFA 6 Protein Data Shape\n",
    "\n",
    "Competition data from\n",
    "<https://www.kaggle.com/competitions/cafa-6-protein-function-prediction>\n",
    "\n",
    "The purpose of this R notebook is to explore the data from a biological perspective and calculate some statistics."
   ]
  },
  {
   "cell_type": "markdown",
   "id": "b8efe48e",
   "metadata": {
    "papermill": {
     "duration": 0.004932,
     "end_time": "2025-12-24T22:21:15.803934",
     "exception": false,
     "start_time": "2025-12-24T22:21:15.799002",
     "status": "completed"
    },
    "tags": []
   },
   "source": [
    "## Data files\n",
    "\n",
    "The data files in the competition dataset are:"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 3,
   "id": "872b17dc",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-12-24T22:21:15.816962Z",
     "iopub.status.busy": "2025-12-24T22:21:15.815494Z",
     "iopub.status.idle": "2025-12-24T22:21:15.836632Z",
     "shell.execute_reply": "2025-12-24T22:21:15.835446Z"
    },
    "papermill": {
     "duration": 0.029489,
     "end_time": "2025-12-24T22:21:15.838336",
     "exception": false,
     "start_time": "2025-12-24T22:21:15.808847",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "[1] \"- In top directory:\"\n"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "[1] \"IA.tsv\"                \"sample_submission.tsv\"\n"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "[1] \"- In train directory:\"\n"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "[1] \"go-basic.obo\"          \"train_sequences.fasta\" \"train_taxonomy.tsv\"   \n",
      "[4] \"train_terms.tsv\"      \n"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "[1] \"- In test directory:\"\n"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "[1] \"testsuperset-taxon-list.tsv\" \"testsuperset.fasta\"         \n"
     ]
    }
   ],
   "source": [
    "print(\"- In top directory:\")\n",
    "print(other_fnames)\n",
    "print(\"- In train directory:\")\n",
    "print(train_fnames)\n",
    "print(\"- In test directory:\")\n",
    "print(test_fnames)"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "9e88b27d",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-11-22T08:36:35.795759Z",
     "iopub.status.busy": "2025-11-22T08:36:35.794048Z",
     "iopub.status.idle": "2025-11-22T08:36:35.805912Z",
     "shell.execute_reply": "2025-11-22T08:36:35.804336Z"
    },
    "papermill": {
     "duration": 0.005058,
     "end_time": "2025-12-24T22:21:15.848884",
     "exception": false,
     "start_time": "2025-12-24T22:21:15.843826",
     "status": "completed"
    },
    "tags": []
   },
   "source": [
    "## Protein train terms"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 4,
   "id": "25a1ed3d",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-12-24T22:21:15.862969Z",
     "iopub.status.busy": "2025-12-24T22:21:15.861926Z",
     "iopub.status.idle": "2025-12-24T22:21:17.124424Z",
     "shell.execute_reply": "2025-12-24T22:21:17.123203Z"
    },
    "papermill": {
     "duration": 1.271169,
     "end_time": "2025-12-24T22:21:17.126554",
     "exception": false,
     "start_time": "2025-12-24T22:21:15.855385",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "[1] \"The train_terms.tsv data file contains 537027 entries, of which there are 82404 unique protein ids and 26125 unique GO terms\"\n"
     ]
    }
   ],
   "source": [
    "#########################################\n",
    "# load protein train terms\n",
    "#########################################\n",
    "\n",
    "train_terms <- read.csv(paste0(trainPath,\"train_terms.tsv\"),sep=\"\\t\")\n",
    "uids_tbl    <- table(train_terms$EntryID)\n",
    "uids        <- names(uids_tbl)\n",
    "uterms_tbl  <- table(train_terms$term)\n",
    "uterms      <- names(uterms_tbl)\n",
    "\n",
    "txt <- paste(\"The train_terms.tsv data file contains\",\n",
    "             length(train_terms[,1]),\"entries, of which there are\",\n",
    "             length(uids),\"unique protein ids and\",\n",
    "             length(uterms),\"unique GO terms\")\n",
    "print(txt)"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 5,
   "id": "6c3b0c32",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-12-24T22:21:17.140642Z",
     "iopub.status.busy": "2025-12-24T22:21:17.139423Z",
     "iopub.status.idle": "2025-12-24T22:21:17.153940Z",
     "shell.execute_reply": "2025-12-24T22:21:17.152878Z"
    },
    "papermill": {
     "duration": 0.023662,
     "end_time": "2025-12-24T22:21:17.155909",
     "exception": false,
     "start_time": "2025-12-24T22:21:17.132247",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "data": {
      "text/plain": [
       "\n",
       "\n",
       "Table: First 5 entries in train_terms.tsv\n",
       "\n",
       "|EntryID |term       |aspect |\n",
       "|:-------|:----------|:------|\n",
       "|Q5W0B1  |GO:0000785 |C      |\n",
       "|Q5W0B1  |GO:0004842 |F      |\n",
       "|Q5W0B1  |GO:0051865 |P      |\n",
       "|Q5W0B1  |GO:0006275 |P      |\n",
       "|Q5W0B1  |GO:0006513 |P      |"
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    }
   ],
   "source": [
    "kable(train_terms[1:5,],caption=\"First 5 entries in train_terms.tsv\")"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "19d8e38e",
   "metadata": {
    "papermill": {
     "duration": 0.005456,
     "end_time": "2025-12-24T22:21:17.167473",
     "exception": false,
     "start_time": "2025-12-24T22:21:17.162017",
     "status": "completed"
    },
    "tags": []
   },
   "source": [
    "There are 3 main ontologies (aspects) for the GO terms:  C = cellular compartment (CCO), F = molecular function (MFO), P = biological process (BPO).  These are distributed across the terms as follows:"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 6,
   "id": "29d89230",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-12-24T22:21:17.181263Z",
     "iopub.status.busy": "2025-12-24T22:21:17.180216Z",
     "iopub.status.idle": "2025-12-24T22:21:17.209828Z",
     "shell.execute_reply": "2025-12-24T22:21:17.208723Z"
    },
    "papermill": {
     "duration": 0.03839,
     "end_time": "2025-12-24T22:21:17.211359",
     "exception": false,
     "start_time": "2025-12-24T22:21:17.172969",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "data": {
      "text/plain": [
       "\n",
       "\n",
       "Table: Distribution of aspects in train_terms.tsv\n",
       "\n",
       "|      C|      F|      P|\n",
       "|------:|------:|------:|\n",
       "| 157770| 128452| 250805|"
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    }
   ],
   "source": [
    "kable(t(table(train_terms$aspect)),caption=\"Distribution of aspects in train_terms.tsv\")"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 7,
   "id": "caf7084d",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-12-24T22:21:17.224605Z",
     "iopub.status.busy": "2025-12-24T22:21:17.223667Z",
     "iopub.status.idle": "2025-12-24T22:21:17.241806Z",
     "shell.execute_reply": "2025-12-24T22:21:17.240577Z"
    },
    "papermill": {
     "duration": 0.02689,
     "end_time": "2025-12-24T22:21:17.244002",
     "exception": false,
     "start_time": "2025-12-24T22:21:17.217112",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "[1] \"For each unique id protein:\"                                      \n",
      "[2] \"maximum number of GO terms =  233\"                                \n",
      "[3] \"minimum number of GO terms =  1\"                                  \n",
      "[4] \"43.36 % of unique proteins have <=3 GO terms\"                     \n",
      "[5] \"Only 26 unique proteins (number not percent) have >=100 GO terms.\"\n",
      "[6] \"Only 2 unique proteins (number not percent) have >=200 GO terms.\" \n"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "[1] \"Proteins with >=200 GO terms:\"\n"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "[1] \"Q02248\" \"Q62226\"\n"
     ]
    }
   ],
   "source": [
    "txt2 <- c(\"For each unique id protein:\",\n",
    "          paste(\"maximum number of GO terms = \",\n",
    "              max(uids_tbl)),\n",
    "          paste(\"minimum number of GO terms = \",\n",
    "              min(uids_tbl)),\n",
    "          paste(format(100*length(which(uids_tbl<=3))/length(uids_tbl),digits=4),\"% of unique proteins have <=3 GO terms\"),\n",
    "          paste(\"Only\",length(which(uids_tbl>=100)),\"unique proteins (number not percent) have >=100 GO terms.\"),\n",
    "          paste(\"Only\",length(which(uids_tbl>=200)),\"unique proteins (number not percent) have >=200 GO terms.\")\n",
    "         ) \n",
    "print(txt2)\n",
    "\n",
    "print(\"Proteins with >=200 GO terms:\")\n",
    "print(names(which(uids_tbl>=200)))\n"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 8,
   "id": "32154112",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-12-24T22:21:17.257928Z",
     "iopub.status.busy": "2025-12-24T22:21:17.256902Z",
     "iopub.status.idle": "2025-12-24T22:21:17.481172Z",
     "shell.execute_reply": "2025-12-24T22:21:17.479905Z"
    },
    "papermill": {
     "duration": 0.233142,
     "end_time": "2025-12-24T22:21:17.483134",
     "exception": false,
     "start_time": "2025-12-24T22:21:17.249992",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "data": {
      "image/png": "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\nTvOi783B0NhhxOrr/5leg0XOeHkzi5G1YpfpFpvuG+TmPyOsDd8/PrfGgF9Th7Nd7DTcJD79\ntch4JWv49s+RzTvTYpftTxXoFIodsi/TYpcQdSZ1Avdv9qlHpvvhciPw3UhbN686/nWr+nga\nvv2oMrOvFaN8999r6idj1T+vpo5M8/Fk842LZdqnyLjYpTK1czIxePfhaOncODIp5Umz+jcj\n3YTpxkiKvV3T0Tx1vJG5Q2mvYhZp/pLlqzo09du+1GVUKAzUK8fIwtowzQe6oUm+ex//k6z5\n0z09tCc4OLixQ8qUjl7jg4OD9xx59rHZfp3HTD2llUvXDJ49XZXffg9rXeDnDCZbV9n57bIb\nhn/8e/101/zDnYMVb9dSHo/KLb5tU6eqZ+oi5/cbmzplBluRKk2xS30VrD/4FYgQwsDYKu2G\nZGJVVp03Sxv5h1I3QoVByhozy+OU9s+5obFjSHhclhY54+XNOEaWip0mW+yHb5CoR3/bGRmk\nmdjuwyPDslfsNN8kPv21yGAlZ+ntr/rkzTvjYpftTxXoGoodsi/TYpec9ObdJ1SFlP096X64\n/O5upx5j7zku9a/2k6NTUqccfPd16mwzLnbqT6iqzTqPnzRt2uTfwhOTMy12JtZeiw7dVKpU\niW+eTO387tj8estvqifWXrE7NrRc6shGQ5bGKFUqlSop5uGEb4qnju99NOzDZczr02nX5cdK\nlSoh8t7YxoVSx/e89e5bzg9l6ek0P8bOxSTlz22eorPeu2vqF3biA36rb729X5n6Z8yx1LoM\nnuJoj5KpD097iN570lvzSU0dU/auubeZn/B267qw5qfUGQ6+kFIOMtiKVP8tdiW++/1+RLxK\npTyxul+ahxgOWXIoVqlKigub2PDdi7L1Vawqixv5h1I3QiGEqV2FoON3klWqhMgnU36omDq+\nZI/DWVrkjJc34xhZKnZCgy32wzfIn9VcUrIZmveatycqKTlZGb1/wc9WaapPtopdFjaJT34t\nMlrJWXo/qj5588642GnyGkEvUOyQfZkXO+W788pmXOx6uVqnfEraVJw4f82FuymfRCE7dgQH\nBwcHB59O87c802JXb9aptDEyLXa9Dj1JM7mya8GUMDaFhqhHaa/Y1Xm7r8ux3IS0c1Ymvqjw\n9svH/F+t/3AZ971+t0Kin61IHV//8OMPX4hUWXo6zYtdibc/brAt/P6ujpwqdmlL1YYXsR+b\n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\n6poNjrtiL09l7uL4/gZFERFbRIs+/W8b1K9Ps7pBIqLozCNmrSlxXWrqiRdExBY9dNYz/7ct\nJbvU2XA7FeWoyz971hER/xtuvH3kPQ/eO65n81oiUqvzo26ft6c66hjYtmOo1RIaM/DOMYN6\ndQjQ6xRFGfnaL1cmrlyDL8e63C6n1B2grFOtursrtvAkq6o6v6GNu2JxvSHYAd5UXLBTVfXC\n7nmO+OIIdqqqbl86q1urmGA/g4joDLYHX9m6pmmNvx7sandcf/Crd+7oFRsSaDEHBLfqOfRf\nG48UHkle9onXHh8f27C21WisGR7dc/DE1buSCnfwMBDkpP42e9LwpvVCLQajLTSi34hHNh+5\nVLiDZ8FOVVX1zK5Ppo4fEhNR299kCKoe1qp73HOLPnc8iHhN/AN//yjRpf+5Pesfv++uVlHh\n1fxNJmtg3ejWd9038+u950tdkZqf+dSwTjY/o8kveOnZ9FJno6KCXX7OuddnTIiNrutn0hss\n/g1bdJr87OILxcU6VW0dYAoIm5idsufBuG6h1fyM1qDGnQYsWOP6eJRyDL4c6ypuOaXsAGWc\napVgB7ijqCq/bgW4ttjPnUjUh9YPsfC7z1GgTaD5YMCYS6ff0di6AJQVjzsBrjm60HqR3h4D\nAMAXcfMEAACARhDsAAAANIJr7AAAADSCM3YAAAAaQbADAADQCIIdAACARhDsAAAANIJgBwAA\noBEEOwAAAI0g2AEAAGgEwQ4AAEAjCHYAAAAaQbADAADQCIIdAACARhDsAAAANIJgBwAAoBEE\nOwAAAI0g2AEAAGgEwQ4AAEAjCHYAAAAaQbADAADQCIIdAACARhDsAAAANIJgBwAAoBEEOwAA\nAI0g2AEAAGgEwQ4AAEAj/h+13l05Q9I1lwAAAABJRU5ErkJggg=="
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
    "h <- hist(uids_tbl, breaks= (1:(max(uids_tbl)+1))-0.5, plot=FALSE )\n",
    "plot(h$mids,log10(h$count), pch=1, cex=0.5,\n",
    "     xlab=\"Number of GO terms per protein\", \n",
    "     ylab=\"Log10(Number of proteins)\",\n",
    "     main=\"Distribution of GO terms per unique protein\")"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "457412c7",
   "metadata": {
    "papermill": {
     "duration": 0.006536,
     "end_time": "2025-12-24T22:21:17.496520",
     "exception": false,
     "start_time": "2025-12-24T22:21:17.489984",
     "status": "completed"
    },
    "tags": []
   },
   "source": [
    "## Host species of proteins\n",
    "\n",
    "The file train_taxonomy.tsv contains the protein ids and the host species id (taxon) of these proteins."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 9,
   "id": "4ffecdae",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-12-24T22:21:17.512310Z",
     "iopub.status.busy": "2025-12-24T22:21:17.511187Z",
     "iopub.status.idle": "2025-12-24T22:21:17.610464Z",
     "shell.execute_reply": "2025-12-24T22:21:17.609215Z"
    },
    "papermill": {
     "duration": 0.109037,
     "end_time": "2025-12-24T22:21:17.612000",
     "exception": false,
     "start_time": "2025-12-24T22:21:17.502963",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "[1] \"There are 82404 entries for the unique proteins in train_taxonomy.tsv, and these match the list of unique proteins in train_terms.tsv.\"\n",
      "[2] \"The host species taxon code with the most entries has 17162 proteins, and this is taxon id= 9606\"                                      \n"
     ]
    }
   ],
   "source": [
    "#########################\n",
    "# load train taxonomy\n",
    "#########################\n",
    "\n",
    "train_taxonomy <- read.csv(paste0(trainPath,\"train_taxonomy.tsv\"),sep=\"\\t\",header=FALSE)\n",
    "\n",
    "tinds <- match(uids,train_taxonomy[,1])\n",
    "if (any(!is.finite(tinds))) {\n",
    "  print(\"Warning cannot find all of the unique protein ids\")\n",
    "} else {\n",
    "  if (all(uids==train_taxonomy[tinds,1])) {\n",
    "    uids_taxons <- train_taxonomy[tinds,2]\n",
    "  } else {\n",
    "    stop(\"Problem matching protein uids with train_taxonomy\")\n",
    "  }\n",
    "  taxon_tbl <- table(train_taxonomy[,2])\n",
    "}\n",
    "\n",
    "txt3 <- c(\n",
    "    paste(\"There are\",length(train_taxonomy[,1]),\n",
    "          \"entries for the unique proteins in train_taxonomy.tsv, and these match the list of unique proteins in train_terms.tsv.\"),\n",
    "    paste(\"The host species taxon code with the most entries has\",\n",
    "          max(taxon_tbl),\"proteins, and this is taxon id=\",\n",
    "          names(which.max(taxon_tbl)))\n",
    ")\n",
    "print(txt3)\n"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "c0e3ee7f",
   "metadata": {
    "papermill": {
     "duration": 0.00624,
     "end_time": "2025-12-24T22:21:17.626576",
     "exception": false,
     "start_time": "2025-12-24T22:21:17.620336",
     "status": "completed"
    },
    "tags": []
   },
   "source": [
    "Uniprot has a species list of taxon id and host organism names, this can be found at\n",
    "<https://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/complete/docs/speclist.txt>"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 10,
   "id": "5f339e67",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-12-24T22:21:17.641988Z",
     "iopub.status.busy": "2025-12-24T22:21:17.640901Z",
     "iopub.status.idle": "2025-12-24T22:21:19.958404Z",
     "shell.execute_reply": "2025-12-24T22:21:19.957065Z"
    },
    "papermill": {
     "duration": 2.327384,
     "end_time": "2025-12-24T22:21:19.960230",
     "exception": false,
     "start_time": "2025-12-24T22:21:17.632846",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [],
   "source": [
    "#################################################\n",
    "# finding additional species list data\n",
    "#################################################\n",
    "\n",
    "# additional data\n",
    "additionalPath    <- paste0(outPath,\"additional_data/\")\n",
    "species_list_file <- \"speclist.txt\"\n",
    "\n",
    "# do this once\n",
    "if (!dir.exists(additionalPath)) {\n",
    "  dir.create(additionalPath)\n",
    "}\n",
    "\n",
    "# do this once\n",
    "if (!file.exists(paste0(additionalPath,species_list_file))) {\n",
    "  # download file\n",
    "  species_url <- \"https://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/complete/docs/speclist.txt\"\n",
    "  species_txt <- readLines(species_url)\n",
    "  write(species_txt,file=paste0(additionalPath,species_list_file))\n",
    "}\n"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 11,
   "id": "cd33b908",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-12-24T22:21:19.975869Z",
     "iopub.status.busy": "2025-12-24T22:21:19.974680Z",
     "iopub.status.idle": "2025-12-24T22:21:22.206946Z",
     "shell.execute_reply": "2025-12-24T22:21:22.205658Z"
    },
    "papermill": {
     "duration": 2.241919,
     "end_time": "2025-12-24T22:21:22.208737",
     "exception": false,
     "start_time": "2025-12-24T22:21:19.966818",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [],
   "source": [
    "#################################################\n",
    "# processing additional species list data\n",
    "#################################################\n",
    "\n",
    "# now process the downloaded speclist\n",
    "# this creates the following smaller semi-colon (;) separated table files\n",
    "real_file    <- \"real_organism_codes.csv\"\n",
    "virtual_file <- \"virtual_organism_codes.csv\"\n",
    "codes_file   <- \"type_codes.csv\"\n",
    "\n",
    "# do this once\n",
    "# get organism codes\n",
    "if (!file.exists(paste0(additionalPath,real_file))) {\n",
    "  species_txt <- readLines(paste0(additionalPath,species_list_file))\n",
    "\n",
    "  is <- grep(\"(1) Real organism codes\",species_txt,fixed=TRUE)\n",
    "  ie <- grep(\"(2) \\\"Virtual\\\" codes\",species_txt,fixed=TRUE)\n",
    "  \n",
    "  # overall species type codes meaning\n",
    "  type_codes <- species_txt[grep(\"\\\\'[ABEVO]\\\\' for \",species_txt[1:is])]\n",
    "  type_codes <- gsub(\"  \\\\'\",\"\",type_codes)\n",
    "  type_codes <- gsub(\"\\\\' for \",\";\",type_codes)\n",
    "  type_codes <- gsub(\" \\\\(\",\";\",type_codes)\n",
    "  type_codes <- gsub(\"\\\\=\",\"\",type_codes)\n",
    "  type_codes <- gsub(\"\\\\)\",\"\",type_codes)\n",
    "  write(c(\"Type;Kingdom;Organisms\",type_codes),file=paste0(additionalPath,codes_file))\n",
    "  \n",
    "  # real\n",
    "  real_txt <- species_txt[(is+2):(ie-2)]\n",
    "  real_txt <- real_txt[which(real_txt!=\"\")]\n",
    "  s_regex  <- \"[A-Z0-9]+[ ]+[ABEVO][ ]+[0-9]+\"\n",
    "  taxon_is <- grep(s_regex,real_txt)\n",
    "  taxon_ie <- c(taxon_is[2:length(taxon_is)]-1,length(real_txt))\n",
    "  real_taxon <- matrix(0,length(taxon_is),6)\n",
    "  colnames(real_taxon) <- c(\"Code\",\"Type\",\"Taxon\",\"Scientfic_Name\",\"Common_Name\",\"Synonym\")\n",
    "  \n",
    "  # this is not fast, but dont really care\n",
    "  for (j in 1:length(taxon_is)) {\n",
    "    tlines     <- real_txt[taxon_is[j]:taxon_ie[j]]\n",
    "    els        <- strsplit(tlines[1],\" \")[[1]]\n",
    "    els        <- els[which(els!=\"\")]\n",
    "    taxon_code <- els[1]\n",
    "    taxon_type <- els[2]\n",
    "    taxon_num  <- gsub(\":\",\"\",els[3],fixed=TRUE)\n",
    "    \n",
    "    pos <- gregexpr(\"N\\\\=\",tlines)\n",
    "    ii  <- which(pos!=-1)\n",
    "    if (length(ii)==1) {\n",
    "      pos <- pos[ii][[1]][1]\n",
    "      taxon_name <- substring(tlines[ii],pos+2)\n",
    "    } else {\n",
    "      taxon_name <- \"\"\n",
    "    }\n",
    "    \n",
    "    pos <- gregexpr(\"C\\\\=\",tlines)\n",
    "    ii  <- which(pos!=-1)\n",
    "    if (length(ii)==1) {\n",
    "      pos <- pos[ii][[1]][1]\n",
    "      common_name <- substring(tlines[ii],pos+2)\n",
    "    } else {\n",
    "      common_name <- \"\"\n",
    "    }\n",
    "    \n",
    "    pos <- gregexpr(\"S\\\\=\",tlines)\n",
    "    ii  <- which(pos!=-1)\n",
    "    if (length(ii)==1) {\n",
    "      pos <- pos[ii][[1]][1]\n",
    "      synon_name <- substring(tlines[ii],pos+2)\n",
    "    } else {\n",
    "      synon_name <- \"\"\n",
    "    }\n",
    "    \n",
    "    real_taxon[j,] <- c(taxon_code,taxon_type,taxon_num,taxon_name,common_name,synon_name)\n",
    "  }\n",
    "  write.table(real_taxon,file=paste0(additionalPath,real_file),\n",
    "              row.names=FALSE,col.names=TRUE,sep=\";\")\n",
    "  \n",
    "  # virtual\n",
    "  is <- grep(\"(2) \\\"Virtual\\\" codes\",species_txt,fixed=TRUE)\n",
    "  ie <- length(species_txt)\n",
    "  virtual_txt <- species_txt[(is+2):(ie-2)]\n",
    "  virtual_txt <- virtual_txt[which(virtual_txt!=\"\")]\n",
    "  s_regex  <- \"[A-Z0-9]+[ ]+[ABEVO][ ]+[0-9]+\"\n",
    "  taxon_is <- grep(s_regex,virtual_txt)\n",
    "  taxon_ie <- c(taxon_is[2:length(taxon_is)]-1,length(virtual_txt))\n",
    "  virtual_taxon <- matrix(0,length(taxon_is),6)\n",
    "  colnames(virtual_taxon) <- c(\"Code\",\"Type\",\"Taxon\",\"Scientfic_Name\",\"Common_Name\",\"Synonym\")\n",
    "  \n",
    "  # this is not fast, but dont really care\n",
    "  for (j in 1:length(taxon_is)) {\n",
    "    tlines     <- virtual_txt[taxon_is[j]:taxon_ie[j]]\n",
    "    els        <- strsplit(tlines[1],\" \")[[1]]\n",
    "    els        <- els[which(els!=\"\")]\n",
    "    taxon_code <- els[1]\n",
    "    taxon_type <- els[2]\n",
    "    taxon_num  <- gsub(\":\",\"\",els[3],fixed=TRUE)\n",
    "    \n",
    "    pos <- gregexpr(\"N\\\\=\",tlines)\n",
    "    ii  <- which(pos!=-1)\n",
    "    if (length(ii)==1) {\n",
    "      pos <- pos[ii][[1]][1]\n",
    "      taxon_name <- substring(tlines[ii],pos+2)\n",
    "    } else {\n",
    "      taxon_name <- \"\"\n",
    "    }\n",
    "    \n",
    "    pos <- gregexpr(\"C\\\\=\",tlines)\n",
    "    ii  <- which(pos!=-1)\n",
    "    if (length(ii)==1) {\n",
    "      pos <- pos[ii][[1]][1]\n",
    "      common_name <- substring(tlines[ii],pos+2)\n",
    "    } else {\n",
    "      common_name <- \"\"\n",
    "    }\n",
    "    \n",
    "    pos <- gregexpr(\"S\\\\=\",tlines)\n",
    "    ii  <- which(pos!=-1)\n",
    "    if (length(ii)==1) {\n",
    "      pos <- pos[ii][[1]][1]\n",
    "      synon_name <- substring(tlines[ii],pos+2)\n",
    "    } else {\n",
    "      synon_name <- \"\"\n",
    "    }\n",
    "    \n",
    "    virtual_taxon[j,] <- c(taxon_code,taxon_type,taxon_num,taxon_name,common_name,synon_name)\n",
    "  }\n",
    "  write.table(virtual_taxon,file=paste0(additionalPath,virtual_file),\n",
    "              row.names=FALSE,col.names=TRUE,sep=\";\")\n",
    "  \n",
    "}\n",
    "\n",
    "# read in processed additional data from speclist\n",
    "real_taxon    <- read.csv(paste0(additionalPath,real_file),sep=\";\")\n",
    "virtual_taxon <- read.csv(paste0(additionalPath,virtual_file),sep=\";\")\n",
    "type_codes    <- read.csv(paste0(additionalPath,codes_file),sep=\";\")"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 12,
   "id": "a4b2e6f3",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-12-24T22:21:22.224324Z",
     "iopub.status.busy": "2025-12-24T22:21:22.223266Z",
     "iopub.status.idle": "2025-12-24T22:21:22.234648Z",
     "shell.execute_reply": "2025-12-24T22:21:22.233553Z"
    },
    "papermill": {
     "duration": 0.021032,
     "end_time": "2025-12-24T22:21:22.236503",
     "exception": false,
     "start_time": "2025-12-24T22:21:22.215471",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "data": {
      "text/plain": [
       "\n",
       "\n",
       "Table: Kingdom/Organism Type Codes\n",
       "\n",
       "|Type |Kingdom            |Organisms                    |\n",
       "|:----|:------------------|:----------------------------|\n",
       "|A    |archaea            |archaebacteria               |\n",
       "|B    |bacteria           |prokaryota or eubacteria     |\n",
       "|E    |eukaryota          |eukarya                      |\n",
       "|V    |viruses and phages |viridae                      |\n",
       "|O    |others             |such as artificial sequences |"
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    }
   ],
   "source": [
    "kable(type_codes,caption=\"Kingdom/Organism Type Codes\")"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 13,
   "id": "93569656",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-12-24T22:21:22.252002Z",
     "iopub.status.busy": "2025-12-24T22:21:22.250948Z",
     "iopub.status.idle": "2025-12-24T22:21:22.299702Z",
     "shell.execute_reply": "2025-12-24T22:21:22.298512Z"
    },
    "papermill": {
     "duration": 0.058038,
     "end_time": "2025-12-24T22:21:22.301337",
     "exception": false,
     "start_time": "2025-12-24T22:21:22.243299",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "data": {
      "text/plain": [
       "\n",
       "\n",
       "Table: Example 4 lines of real_taxon, these are specific species\n",
       "\n",
       "|Code  |Type |   Taxon|Scientfic_Name           |Common_Name          |Synonym              |\n",
       "|:-----|:----|-------:|:------------------------|:--------------------|:--------------------|\n",
       "|BLEOR |E    |   29606|Blechnopsis orientalis   |Fish fern            |Blechnum orientale   |\n",
       "|HUMAN |E    |    9606|Homo sapiens             |Human                |                     |\n",
       "|LARGL |E    |  119606|Larus glaucescens        |Glaucous-winged gull |                     |\n",
       "|NOTRU |E    | 1960652|Notamacropus rufogriseus |Red-necked wallaby   |Macropus rufogriseus |"
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    }
   ],
   "source": [
    "kable(real_taxon[grep(9606,real_taxon[,3])[1:4],],\n",
    "      row.names=FALSE,\n",
    "      caption=\"Example 4 lines of real_taxon, these are specific species\")"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 14,
   "id": "868c29ea",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-12-24T22:21:22.317222Z",
     "iopub.status.busy": "2025-12-24T22:21:22.316120Z",
     "iopub.status.idle": "2025-12-24T22:21:22.328918Z",
     "shell.execute_reply": "2025-12-24T22:21:22.327763Z"
    },
    "papermill": {
     "duration": 0.022803,
     "end_time": "2025-12-24T22:21:22.331031",
     "exception": false,
     "start_time": "2025-12-24T22:21:22.308228",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "data": {
      "text/plain": [
       "\n",
       "\n",
       "Table: Example 4 lines of virtual_taxon, these are species groups\n",
       "\n",
       "|Code  |Type | Taxon|Scientfic_Name |Common_Name |Synonym |\n",
       "|:-----|:----|-----:|:--------------|:-----------|:-------|\n",
       "|9ARCH |A    |  2157|Archaea        |            |        |\n",
       "|9CARN |E    | 33554|Carnivora      |            |        |\n",
       "|9CETA |E    | 91561|Artiodactyla   |            |        |\n",
       "|9PRIM |E    |  9443|Primates       |            |        |"
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    }
   ],
   "source": [
    "kable(virtual_taxon[c(24,56,64,230),], \n",
    "      row.names=FALSE,\n",
    "      caption=\"Example 4 lines of virtual_taxon, these are species groups\")"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 15,
   "id": "05ed8316",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-12-24T22:21:22.347846Z",
     "iopub.status.busy": "2025-12-24T22:21:22.346773Z",
     "iopub.status.idle": "2025-12-24T22:21:22.389297Z",
     "shell.execute_reply": "2025-12-24T22:21:22.387848Z"
    },
    "papermill": {
     "duration": 0.053094,
     "end_time": "2025-12-24T22:21:22.391119",
     "exception": false,
     "start_time": "2025-12-24T22:21:22.338025",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [],
   "source": [
    "#################################################\n",
    "# matching proteins to host species\n",
    "#################################################\n",
    "\n",
    "# real species full list\n",
    "tbl <- table(factor(real_taxon$Type, levels=type_codes$Type))\n",
    "tbl <- cbind(type_codes$Kingdom,tbl)\n",
    "\n",
    "# by protein\n",
    "colnames(train_taxonomy) <- c(\"Protein\",\"Organism\")\n",
    "tinds <- match(train_taxonomy$Organism, real_taxon$Taxon)\n",
    "if (any(is.na(tinds)) | !all(train_taxonomy$Organism==real_taxon$Taxon[tinds])) {\n",
    "  stop(\"Cannot match all train_taxonomy organisms to real_taxon$Taxon\")\n",
    "}\n",
    "train_org_types      <- factor(real_taxon$Type[tinds],levels=type_codes$Type)\n",
    "tbl_train_orgs_types <- table(train_org_types)\n",
    "train_host_names     <- real_taxon$Scientfic_Name[tinds]\n",
    "train_taxonomy_with_host <- cbind(train_taxonomy,train_host_names)\n",
    "colnames(train_taxonomy_with_host)[3] <- \"Scientfic_Name\"\n",
    "top_train_host_names <- sort(table(train_host_names),decreasing = TRUE)\n",
    "\n",
    "# by hosts in train\n",
    "uhosts_in_train <- unique(train_taxonomy$Organism)\n",
    "tinds           <- match(uhosts_in_train, real_taxon$Taxon)\n",
    "uhosts_org_types<- factor(real_taxon$Type[tinds],levels=type_codes$Type)\n",
    "tbl_uhosts_types <- table(uhosts_org_types)\n",
    "\n",
    "tbl <- cbind(tbl,tbl_uhosts_types,tbl_train_orgs_types)\n",
    "#colnames(tbl) <- c(\"Kingdom\",\"Number of real species\",\"Number of species in train\",\"Proteins per Kingdom in train\")\n",
    "colnames(tbl) <- c(\"Kingdom\",\"Num.Real Species\",\"Num.Species-Train\",\"Proteins per Kingdom\")"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "b203662f",
   "metadata": {
    "papermill": {
     "duration": 0.006958,
     "end_time": "2025-12-24T22:21:22.405685",
     "exception": false,
     "start_time": "2025-12-24T22:21:22.398727",
     "status": "completed"
    },
    "tags": []
   },
   "source": [
    "In the train_taxomony, the top 10 species and the number of proteins in the training set are:"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 16,
   "id": "a8c261bc",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-12-24T22:21:22.422630Z",
     "iopub.status.busy": "2025-12-24T22:21:22.421353Z",
     "iopub.status.idle": "2025-12-24T22:21:22.436128Z",
     "shell.execute_reply": "2025-12-24T22:21:22.434741Z"
    },
    "papermill": {
     "duration": 0.025053,
     "end_time": "2025-12-24T22:21:22.437704",
     "exception": false,
     "start_time": "2025-12-24T22:21:22.412651",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "data": {
      "text/plain": [
       "\n",
       "\n",
       "Table: Top 10 host species by number of proteins in train_taxonomy\n",
       "\n",
       "|train_host_names                                       |  Freq|\n",
       "|:------------------------------------------------------|-----:|\n",
       "|Homo sapiens                                           | 17162|\n",
       "|Mus musculus                                           | 12508|\n",
       "|Arabidopsis thaliana                                   | 11863|\n",
       "|Saccharomyces cerevisiae (strain ATCC 204508 / S288c)  |  5520|\n",
       "|Rattus norvegicus                                      |  4909|\n",
       "|Schizosaccharomyces pombe (strain 972 / ATCC 24843)    |  4636|\n",
       "|Escherichia coli (strain K12)                          |  3466|\n",
       "|Drosophila melanogaster                                |  3201|\n",
       "|Caenorhabditis elegans                                 |  2540|\n",
       "|Mycobacterium tuberculosis (strain ATCC 25618 / H37Rv) |  1530|"
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    }
   ],
   "source": [
    "kable(top_train_host_names[1:10],caption=\"Top 10 host species by number of proteins in train_taxonomy\")"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "df6af3e5",
   "metadata": {
    "papermill": {
     "duration": 0.006642,
     "end_time": "2025-12-24T22:21:22.451321",
     "exception": false,
     "start_time": "2025-12-24T22:21:22.444679",
     "status": "completed"
    },
    "tags": []
   },
   "source": [
    "The distribution of the species (taxon) in the real full species list, as compared to the train_taxonomy is in the following table.\n",
    "\n",
    "From this we can see that there are no Viruses, only one Archea, and a few Bacteria in the training set.  This may be problematic for the future performance (real world) against unknown proteins, since the unknown proteins could come from a metagenomic study of environmental samples which may contain archea, bacteria and possibly viruses (although depends on how the proteins/DNA/RNA are extracted), and there is alot of metagenomic 'dark matter'."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 17,
   "id": "309e6f1c",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-12-24T22:21:22.467402Z",
     "iopub.status.busy": "2025-12-24T22:21:22.466238Z",
     "iopub.status.idle": "2025-12-24T22:21:22.479294Z",
     "shell.execute_reply": "2025-12-24T22:21:22.478189Z"
    },
    "papermill": {
     "duration": 0.023005,
     "end_time": "2025-12-24T22:21:22.480850",
     "exception": false,
     "start_time": "2025-12-24T22:21:22.457845",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "data": {
      "text/plain": [
       "\n",
       "\n",
       "Table: Number of species taxon in the real species list compared to the training set\n",
       "\n",
       "|   |Kingdom            |Num.Real Species |Num.Species-Train |Proteins per Kingdom |\n",
       "|:--|:------------------|:----------------|:-----------------|:--------------------|\n",
       "|A  |archaea            |329              |1                 |76                   |\n",
       "|B  |bacteria           |4245             |19                |6251                 |\n",
       "|E  |eukaryota          |19807            |1361              |76077                |\n",
       "|V  |viruses and phages |3162             |0                 |0                    |\n",
       "|O  |others             |0                |0                 |0                    |"
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    }
   ],
   "source": [
    "kable(tbl, caption=\"Number of species taxon in the real species list compared to the training set\")"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "08a68a7f",
   "metadata": {
    "papermill": {
     "duration": 0.006946,
     "end_time": "2025-12-24T22:21:22.494654",
     "exception": false,
     "start_time": "2025-12-24T22:21:22.487708",
     "status": "completed"
    },
    "tags": []
   },
   "source": [
    "## Host species in test superset"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 18,
   "id": "87b7d513",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-12-24T22:21:22.513129Z",
     "iopub.status.busy": "2025-12-24T22:21:22.511890Z",
     "iopub.status.idle": "2025-12-24T22:21:22.570691Z",
     "shell.execute_reply": "2025-12-24T22:21:22.569168Z"
    },
    "papermill": {
     "duration": 0.069744,
     "end_time": "2025-12-24T22:21:22.572554",
     "exception": false,
     "start_time": "2025-12-24T22:21:22.502810",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "[1] \"The test superset taxon list contains 8453 entries\"\n",
      "[2] \"and 8453 unique Species\"                           \n"
     ]
    }
   ],
   "source": [
    "#################################################\n",
    "# read test superset\n",
    "#################################################\n",
    "\n",
    "test_taxonomy <- read.csv(paste0(testPath,\"testsuperset-taxon-list.tsv\"),sep=\"\\t\")\n",
    "\n",
    "txt5 <- c(paste(\"The test superset taxon list contains\",length(test_taxonomy$ID),\"entries\"),\n",
    "          paste(\"and\",length(unique(test_taxonomy$Species)),\"unique Species\"))\n",
    "print(txt5)"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 19,
   "id": "2b0d0ea7",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-12-24T22:21:22.590003Z",
     "iopub.status.busy": "2025-12-24T22:21:22.588743Z",
     "iopub.status.idle": "2025-12-24T22:21:22.601531Z",
     "shell.execute_reply": "2025-12-24T22:21:22.600359Z"
    },
    "papermill": {
     "duration": 0.022668,
     "end_time": "2025-12-24T22:21:22.603126",
     "exception": false,
     "start_time": "2025-12-24T22:21:22.580458",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "data": {
      "text/plain": [
       "\n",
       "\n",
       "Table: First 5 entries of test taxonomy\n",
       "\n",
       "|    ID|Species                      |\n",
       "|-----:|:----------------------------|\n",
       "|  9606|Homo sapiens                 |\n",
       "| 10116|Rattus norvegicus            |\n",
       "| 39947|Oryza sativa subsp. japonica |\n",
       "|  7955|Danio rerio                  |\n",
       "|  7227|Drosophila melanogaster      |"
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    }
   ],
   "source": [
    "kable(test_taxonomy[1:5,], caption=\"First 5 entries of test taxonomy\")"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 20,
   "id": "9adce4b7",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-12-24T22:21:22.620504Z",
     "iopub.status.busy": "2025-12-24T22:21:22.619081Z",
     "iopub.status.idle": "2025-12-24T22:21:22.643834Z",
     "shell.execute_reply": "2025-12-24T22:21:22.642185Z"
    },
    "papermill": {
     "duration": 0.035101,
     "end_time": "2025-12-24T22:21:22.645564",
     "exception": false,
     "start_time": "2025-12-24T22:21:22.610463",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "[1] \"The number of unique Organisms in the training data (proteins) which match those in the test superset are 1381\"\n",
      "[2] \"and the number of unique Organisms (from train) which are not in test superset are 0\"                          \n",
      "[3] \"There are 7072 unique listed Species (Organisms) in the test superset which are not in the training data.\"     \n"
     ]
    }
   ],
   "source": [
    "# checking contents\n",
    "match_train_organism_to_test_superset <- match(unique(train_taxonomy$Organism),unique(test_taxonomy$ID))\n",
    "num_train_organism_in_test_superset   <- length(which(is.finite(match_train_organism_to_test_superset)))  # 1381\n",
    "num_train_organism_not_in_test        <- length(which(!is.finite(match_train_organism_to_test_superset))) # 0\n",
    "match_test_superset_to_train_organism <- match(unique(test_taxonomy$ID), unique(train_taxonomy$Organism))\n",
    "num_test_superset_in_train_organism   <- length(which(is.finite(match_test_superset_to_train_organism)))  # 1381\n",
    "num_test_not_in_train_organism        <- length(which(!is.finite(match_test_superset_to_train_organism))) # 7072\n",
    "\n",
    "txt6 <- c(paste(\"The number of unique Organisms in the training data (proteins) which match those in the test superset are\",num_train_organism_in_test_superset),\n",
    "          paste(\"and the number of unique Organisms (from train) which are not in test superset are\",num_train_organism_not_in_test),\n",
    "          paste(\"There are\",num_test_not_in_train_organism,\"unique listed Species (Organisms) in the test superset which are not in the training data.\"))\n",
    "\n",
    "print(txt6)"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "cb361bb8",
   "metadata": {
    "papermill": {
     "duration": 0.006749,
     "end_time": "2025-12-24T22:21:22.659497",
     "exception": false,
     "start_time": "2025-12-24T22:21:22.652748",
     "status": "completed"
    },
    "tags": []
   },
   "source": [
    "## Host species in test proteins"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 21,
   "id": "a146eec5",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-12-24T22:21:22.676028Z",
     "iopub.status.busy": "2025-12-24T22:21:22.674785Z",
     "iopub.status.idle": "2025-12-24T22:21:35.036782Z",
     "shell.execute_reply": "2025-12-24T22:21:35.035600Z"
    },
    "papermill": {
     "duration": 12.372684,
     "end_time": "2025-12-24T22:21:35.038958",
     "exception": false,
     "start_time": "2025-12-24T22:21:22.666274",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "[1] \"There are 224309 protein sequences in the test data set; these have accession numbers and also the id of their host organisms in the sequence names\"\n",
      "[2] \"The unique host organisms are listed in the test superset (see above).\"                                                                             \n"
     ]
    },
    {
     "data": {
      "text/plain": [
       "\n",
       "\n",
       "Table: Top 10 host species by number of proteins in test proteins dataset\n",
       "\n",
       "|test_host_names                                       |  Freq|\n",
       "|:-----------------------------------------------------|-----:|\n",
       "|Homo sapiens                                          | 20420|\n",
       "|Mus musculus                                          | 17240|\n",
       "|Arabidopsis thaliana                                  | 16397|\n",
       "|Rattus norvegicus                                     |  8219|\n",
       "|Saccharomyces cerevisiae (strain ATCC 204508 / S288c) |  6733|\n",
       "|Bos taurus                                            |  6052|\n",
       "|Schizosaccharomyces pombe (strain 972 / ATCC 24843)   |  5123|\n",
       "|Escherichia coli (strain K12)                         |  4531|\n",
       "|Caenorhabditis elegans                                |  4493|\n",
       "|Oryza sativa subsp. japonica                          |  4195|"
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    }
   ],
   "source": [
    "###################################################\n",
    "# comparing proteins per species in train vs test\n",
    "###################################################\n",
    "\n",
    "# load test proteins details\n",
    "# do this once\n",
    "if (!file.exists(paste0(additionalPath,\"test_taxonomy_with_host.csv\"))) {\n",
    "    # install.packages(\"seqinr\")\n",
    "    # library(seqinr)\n",
    "    \n",
    "    # read in the test protein sequences\n",
    "    test_seqs     <- read.fasta(paste0(testPath,\"testsuperset.fasta\"),\n",
    "                        whole.header=TRUE,seqtype=\"AA\",as.string=TRUE)\n",
    "    num_test_seqs <- length(test_seqs)\n",
    "\n",
    "    # get the test taxa names of the sequences and split to accession number and host\n",
    "    test_taxa     <- attributes(test_seqs)$names # contains accn (space) host_id\n",
    "    test_taxa     <- t(matrix(unlist(strsplit(test_taxa,\" \")),2,num_test_seqs))\n",
    "    test_species  <- test_taxonomy$Species[match(test_taxa[,2],test_taxonomy$ID)]\n",
    "    test_taxonomy_with_host <- cbind(test_taxa,test_species)\n",
    "    colnames(test_taxonomy_with_host) <- c(\"Protein\",\"Organism\",\"Scientfic_Name\")\n",
    "    test_taxonomy_with_host <- as.data.frame(test_taxonomy_with_host)\n",
    "    write.table(test_taxonomy_with_host,\n",
    "        file=paste0(additionalPath,\"test_taxonomy_with_host.csv\"),\n",
    "        sep=\";\",row.names=FALSE,col.names=TRUE)\n",
    "}\n",
    "\n",
    "# read in details of test set (dont actually need the proteins at this point)\n",
    "test_taxonomy_with_host <- read.csv(paste0(additionalPath,\"test_taxonomy_with_host.csv\"),\n",
    "                                   sep=\";\")\n",
    "num_test_seqs <- length(test_taxonomy_with_host[,1])\n",
    "\n",
    "# the unique hosts in the test proteins are listed in the test superset\n",
    "# all(unique(test_taxonomy_with_host$Organism)==unique(test_taxonomy$ID))\n",
    "\n",
    "\n",
    "txt7 <- c(paste(\"There are\",num_test_seqs,\"protein sequences in the test data set; these have accession numbers and also the id of their host organisms in the sequence names\"),\n",
    "          \"The unique host organisms are listed in the test superset (see above).\")\n",
    "print(txt7)\n",
    "\n",
    "# real species full list (repeat from above in Train)\n",
    "tbl <- table(factor(real_taxon$Type, levels=type_codes$Type))\n",
    "tbl <- cbind(type_codes$Kingdom,tbl)\n",
    "\n",
    "# by protein of test\n",
    "tinds <- match(test_taxonomy_with_host$Organism, real_taxon$Taxon)\n",
    "if (any(is.na(tinds)) | !all(test_taxonomy_with_host$Organism==real_taxon$Taxon[tinds])) {\n",
    "  stop(\"Cannot match all test_taxonomy_with_host organisms to real_taxon$Taxon\")\n",
    "}\n",
    "test_org_types       <- factor(real_taxon$Type[tinds],levels=type_codes$Type)\n",
    "tbl_test_orgs_types  <- table(test_org_types)\n",
    "test_host_names      <- real_taxon$Scientfic_Name[tinds]\n",
    "\n",
    "# check these match\n",
    "xinds <- which(test_host_names!=test_taxonomy_with_host$Scientfic_Name)\n",
    "# there are some full stops differences, but otherwise OK\n",
    "\n",
    "top_test_host_names <- sort(table(test_host_names),decreasing = TRUE)\n",
    "\n",
    "# by hosts in test\n",
    "uhosts_in_test   <- unique(test_taxonomy_with_host$Organism)\n",
    "tinds            <- match(uhosts_in_test, real_taxon$Taxon)\n",
    "uhosts_org_types <- factor(real_taxon$Type[tinds],levels=type_codes$Type)\n",
    "tbl_uhosts_types <- table(uhosts_org_types)\n",
    "\n",
    "tbl <- cbind(tbl,tbl_uhosts_types,tbl_test_orgs_types)\n",
    "#colnames(tbl) <- c(\"Kingdom\",\"Number of real species\",\"Number of species in test\",\"Proteins per Kingdom in test\")\n",
    "colnames(tbl) <- c(\"Kingdom\",\"Num.Real Species\",\"Num.Species-Test\",\"Proteins per Kingdom\")\n",
    "\n",
    "kable(top_test_host_names[1:10],caption=\"Top 10 host species by number of proteins in test proteins dataset\")"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "cef08e72",
   "metadata": {
    "papermill": {
     "duration": 0.007997,
     "end_time": "2025-12-24T22:21:35.055082",
     "exception": false,
     "start_time": "2025-12-24T22:21:35.047085",
     "status": "completed"
    },
    "tags": []
   },
   "source": [
    "The distribution of the species (taxon) in the real full species list, as compared to the test data set is the following table.\n",
    "\n",
    "From this we can see that there are no Viruses, only one Archea, and a few Bacteria in the test set."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 22,
   "id": "23cb305b",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-12-24T22:21:35.072400Z",
     "iopub.status.busy": "2025-12-24T22:21:35.071125Z",
     "iopub.status.idle": "2025-12-24T22:21:35.086552Z",
     "shell.execute_reply": "2025-12-24T22:21:35.085186Z"
    },
    "papermill": {
     "duration": 0.026331,
     "end_time": "2025-12-24T22:21:35.088678",
     "exception": false,
     "start_time": "2025-12-24T22:21:35.062347",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "data": {
      "text/plain": [
       "\n",
       "\n",
       "Table: Number of species taxon in the real species list compared to the test set\n",
       "\n",
       "|   |Kingdom            |Num.Real Species |Num.Species-Test |Proteins per Kingdom |\n",
       "|:--|:------------------|:----------------|:----------------|:--------------------|\n",
       "|A  |archaea            |329              |1                |1787                 |\n",
       "|B  |bacteria           |4245             |23               |22982                |\n",
       "|E  |eukaryota          |19807            |8429             |199540               |\n",
       "|V  |viruses and phages |3162             |0                |0                    |\n",
       "|O  |others             |0                |0                |0                    |"
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    }
   ],
   "source": [
    "kable(tbl, caption=\"Number of species taxon in the real species list compared to the test set\")\n",
    "#print(tbl)"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 23,
   "id": "82f49d73",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-12-24T22:21:35.106556Z",
     "iopub.status.busy": "2025-12-24T22:21:35.105288Z",
     "iopub.status.idle": "2025-12-24T22:21:35.149944Z",
     "shell.execute_reply": "2025-12-24T22:21:35.148246Z"
    },
    "papermill": {
     "duration": 0.056399,
     "end_time": "2025-12-24T22:21:35.152684",
     "exception": false,
     "start_time": "2025-12-24T22:21:35.096285",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "data": {
      "text/plain": [
       "\n",
       "\n",
       "Table: Number of species in both the train and test sets compared to only the test set\n",
       "\n",
       "|   |Kingdom           |Num.Real Species|Num.Species Common|Num.Species in test only|\n",
       "|:--|:-----------------|:---------------|:-----------------|:-----------------------|\n",
       "|A  |archaea           |329             |1                 |0                       |\n",
       "|B  |bacteria          |4245            |19                |4                       |\n",
       "|E  |eukaryota         |19807           |1361              |7068                    |\n",
       "|V  |viruses and phages|3162            |0                 |0                       |\n",
       "|O  |others            |0               |0                 |0                       |"
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    }
   ],
   "source": [
    "# repeat of the test superset analysis as above\n",
    "uspecies_in_test     <- sort(unique(test_taxonomy_with_host$Organism))\n",
    "uspecies_in_train    <- sort(unique(train_taxonomy_with_host$Organism))\n",
    "common_species       <- intersect(uspecies_in_test,uspecies_in_train)   # 1381\n",
    "species_in_test_only <- setdiff(uspecies_in_test,uspecies_in_train)     # 0\n",
    "species_in_train_only<- setdiff(uspecies_in_train,uspecies_in_test)     # 7072\n",
    "\n",
    "# what are the organism types\n",
    "tinds_common        <- match(common_species, real_taxon$Taxon)\n",
    "common_types        <- factor(real_taxon$Type[tinds_common],levels=type_codes$Type)\n",
    "tbl_common_types    <- table(common_types)\n",
    "tinds_test          <- match(species_in_test_only, real_taxon$Taxon)\n",
    "test_only_types     <- factor(real_taxon$Type[tinds_test],levels=type_codes$Type)\n",
    "tbl_test_only_types <- table(test_only_types)\n",
    "\n",
    "# real species full list (repeat from above in Train)\n",
    "tbl <- table(factor(real_taxon$Type, levels=type_codes$Type))\n",
    "tbl <- cbind(type_codes$Kingdom,tbl,tbl_common_types,tbl_test_only_types)\n",
    "\n",
    "colnames(tbl) <- c(\"Kingdom\",\"Num.Real Species\",\"Num.Species Common\",\"Num.Species in test only\")\n",
    "\n",
    "kable(tbl, padding=0,\n",
    "      caption=\"Number of species in both the train and test sets compared to only the test set\")\n",
    "#print(tbl)"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "fdcd51cc",
   "metadata": {
    "papermill": {
     "duration": 0.006989,
     "end_time": "2025-12-24T22:21:35.167397",
     "exception": false,
     "start_time": "2025-12-24T22:21:35.160408",
     "status": "completed"
    },
    "tags": []
   },
   "source": [
    "## GO Terms\n",
    "\n",
    "The Gene Ontology terms (GO Terms) are within file go-basic.obo, this is a text based format, and can be read by R package ontologyIndex <https://cran.r-project.org/web/packages/ontologyIndex/> from paper Greene et al 2017 <https://doi.org/10.1093/bioinformatics/btw763>.\n",
    "\n",
    "There are 3 root terms in the ontology:\n",
    "<ul>\n",
    "<li>GO:0008150\tbiological_process\n",
    "<li>GO:0005575\tcellular_component\n",
    "<li>GO:0003674\tmolecular_function\n",
    "</ul>\n",
    "\n",
    "\n",
    "From the ontologyIndex R package description (\"Introduction to ontologyX\"), an ontology_index object (within R) is vector of lists, indexed by the IDs of the terms, and it has the following elements:\n",
    "<ul>\n",
    "<li>id\n",
    "<li>name\n",
    "<li>parents   (list of GO terms)\n",
    "<li>children  (list of GO terms)\n",
    "<li>ancestors (list of GO terms)\n",
    "<li>obsolete  (TRUE/FALSE)\n",
    "</ul>\n",
    "\n",
    "The numbers of direct parents, children and ancestors of a term can be large.  The ontologySimilarity R package has a useful function, descendants_IC, which \"calculates information content of terms based on frequency with which it is an ancestor of other terms\", and this is a useful measure of the \"depth\" (detailed-ness) of a term from the roots.\n"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 24,
   "id": "0ceebeff",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-12-24T22:21:35.184547Z",
     "iopub.status.busy": "2025-12-24T22:21:35.183366Z",
     "iopub.status.idle": "2025-12-24T22:21:45.095492Z",
     "shell.execute_reply": "2025-12-24T22:21:45.094188Z"
    },
    "papermill": {
     "duration": 9.923564,
     "end_time": "2025-12-24T22:21:45.097931",
     "exception": false,
     "start_time": "2025-12-24T22:21:35.174367",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [],
   "source": [
    "#######################################\n",
    "# read ontology file\n",
    "#######################################\n",
    "\n",
    "##    property     class\n",
    "## 1        id character\n",
    "## 2      name character\n",
    "## 3   parents      list\n",
    "## 4  children      list\n",
    "## 5 ancestors      list\n",
    "## 6  obsolete   logical\n",
    "\n",
    "#install.packages(\"ontologyIndex\")\n",
    "#install.packages(\"ontologySimilarity\")\n",
    "#library(ontologyIndex,lib=lib)\n",
    "#library(ontologySimilarity,lib=lib)\n",
    "\n",
    "# read ontology file\n",
    "ontology <- get_ontology(paste0(trainPath,\"go-basic.obo\"))\n",
    "\n",
    "# Get information content based on number of descendants each term has\n",
    "ontology_info <- descendants_IC(ontology)\n",
    "\n",
    "# define root terms for ontology\n",
    "#subontology_roots = {\n",
    "#    'BPO': 'GO:0008150',\n",
    "#    'CCO': 'GO:0005575',\n",
    "#    'MFO': 'GO:0003674'\n",
    "#}\n",
    "\n",
    "bpo_term <- \"GO:0008150\"\n",
    "cco_term <- \"GO:0005575\"\n",
    "mfo_term <- \"GO:0003674\"\n",
    "\n",
    "# define custom function for ease of printing go term information\n",
    "go_term_info_for_print <- function(gt, ontology, ontology_info, limitTerms=2) {\n",
    "  if (limitTerms>0) {\n",
    "    parTxt <- paste(ontology$parents[[gt]],  collapse=\" ; \")\n",
    "    numPar <- length(ontology$parents[[gt]])\n",
    "    if (numPar > limitTerms) {\n",
    "      parTxt <- paste(numPar,ontology$parents[[gt]][1],sep=\"+ \")\n",
    "    }\n",
    "    \n",
    "    childTxt <- paste(ontology$children[[gt]],  collapse=\" ; \")\n",
    "    numChild <- length(ontology$children[[gt]])\n",
    "    if (numChild > limitTerms) {\n",
    "      childTxt <- paste(numChild,ontology$children[[gt]][1],sep=\"+ \")\n",
    "    }\n",
    "    \n",
    "    ancTxt <- paste(ontology$ancestors[[gt]],collapse=\" ; \")\n",
    "    numAnc <- length(ontology$ancestors[[gt]])\n",
    "    if (numAnc > limitTerms) {\n",
    "      ancTxt <- paste(numAnc,ontology$ancestors[[gt]][1],sep=\"+ \")\n",
    "    }\n",
    "  }\n",
    "  \n",
    "  info_val_txt <- format(ontology_info[which(names(ontology_info)==gt)],digits=3) \n",
    "  \n",
    "  gt_details <- c(ontology$id[[gt]],ontology$name[[gt]],\n",
    "                  parTxt,\n",
    "                  childTxt,\n",
    "                  ancTxt,\n",
    "                  ontology$obsolete[[gt]],\n",
    "                  info_val_txt)\n",
    "  names(gt_details) <- c(\"id\",\"name\",\"parents\",\"children\",\"ancestors\",\"obsolete\",\"descendants_IC\")\n",
    "  return(gt_details)\n",
    "}\n",
    "\n",
    "# print the details of the selected terms, and include the descends info\n",
    "sel_terms  <- c(bpo_term,cco_term,mfo_term,train_terms$term[1],train_terms$term[2])\n",
    "sel_info   <- matrix(0,length(sel_terms),7)\n",
    "for (j in 1:length(sel_terms)) {\n",
    "  res <- go_term_info_for_print(sel_terms[j],ontology,ontology_info)\n",
    "  if (j==1) {\n",
    "    colnames(sel_info) <- names(res)\n",
    "    rownames(sel_info) <- sel_terms\n",
    "  }\n",
    "  sel_info[j,] <- res\n",
    "}"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 25,
   "id": "67b67668",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-12-24T22:21:45.115338Z",
     "iopub.status.busy": "2025-12-24T22:21:45.114144Z",
     "iopub.status.idle": "2025-12-24T22:21:45.127192Z",
     "shell.execute_reply": "2025-12-24T22:21:45.125665Z"
    },
    "papermill": {
     "duration": 0.023374,
     "end_time": "2025-12-24T22:21:45.129038",
     "exception": false,
     "start_time": "2025-12-24T22:21:45.105664",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "data": {
      "text/plain": [
       "\n",
       "\n",
       "Table: GO term information for 5 selected terms\n",
       "\n",
       "|id         |name                                   |parents    |children                |ancestors     |obsolete |descendants_IC |\n",
       "|:----------|:--------------------------------------|:----------|:-----------------------|:-------------|:--------|:--------------|\n",
       "|GO:0008150 |biological_process                     |           |18+ GO:0002376          |GO:0008150    |FALSE    |0.617          |\n",
       "|GO:0005575 |cellular_component                     |           |3+ GO:0032991           |GO:0005575    |FALSE    |2.48           |\n",
       "|GO:0003674 |molecular_function                     |           |32+ GO:0003774          |GO:0003674    |FALSE    |1.56           |\n",
       "|GO:0000785 |chromatin                              |GO:0110165 |4+ GO:0000791           |3+ GO:0005575 |FALSE    |7.84           |\n",
       "|GO:0004842 |ubiquitin-protein transferase activity |GO:0019787 |GO:0061630 ; GO:0061631 |8+ GO:0003674 |FALSE    |7.95           |"
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    }
   ],
   "source": [
    "kable(sel_info, caption=\"GO term information for 5 selected terms\", row.names=FALSE)"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 26,
   "id": "887231bb",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-12-24T22:21:45.146437Z",
     "iopub.status.busy": "2025-12-24T22:21:45.145384Z",
     "iopub.status.idle": "2025-12-24T22:21:46.858029Z",
     "shell.execute_reply": "2025-12-24T22:21:46.856560Z"
    },
    "papermill": {
     "duration": 1.724073,
     "end_time": "2025-12-24T22:21:46.860653",
     "exception": false,
     "start_time": "2025-12-24T22:21:45.136580",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [],
   "source": [
    "######################################################\n",
    "# make protein train terms with attached information\n",
    "######################################################\n",
    "\n",
    "# combine information\n",
    "# do this once\n",
    "if (!file.exists(paste0(additionalPath,\"train_terms_with_info.csv\"))) {\n",
    "  # matching terms into ontology_info for the descendants_IC\n",
    "  tinds1                 <- match(train_terms$term,names(ontology_info))\n",
    "  \n",
    "  # matching proteins in train terms to proteins in hosts\n",
    "  tinds2                 <- match(train_terms$EntryID,train_taxonomy_with_host$Protein)\n",
    "  \n",
    "  # combining with train_terms\n",
    "  train_terms_with_info <- cbind(train_terms,\n",
    "                                 ontology_info[tinds1],\n",
    "                                 ontology$name[train_terms$term],\n",
    "                                 train_taxonomy_with_host$Organism[tinds2],\n",
    "                                 train_taxonomy_with_host$Scientfic_Name[tinds2])\n",
    "  colnames(train_terms_with_info)[4] <- \"term_info\"\n",
    "  colnames(train_terms_with_info)[5] <- \"term_name\"\n",
    "  colnames(train_terms_with_info)[6] <- \"Organism\"\n",
    "  colnames(train_terms_with_info)[7] <- \"Scientific_Name\"\n",
    "  train_terms_with_info <- as.data.frame(train_terms_with_info)\n",
    "  \n",
    "  tinds3 <- match(train_terms_with_info$Organism,real_taxon$Taxon)\n",
    "  train_terms_with_info <- cbind(train_terms_with_info,real_taxon$Type[tinds3])\n",
    "  colnames(train_terms_with_info)[8] <- \"Type\"\n",
    "  write.table(train_terms_with_info, file=paste0(additionalPath,\"train_terms_with_info.csv\"),\n",
    "              row.names=FALSE, col.names=TRUE, sep=\";\")\n",
    "}"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 27,
   "id": "fe315bfe",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-12-24T22:21:46.897368Z",
     "iopub.status.busy": "2025-12-24T22:21:46.896117Z",
     "iopub.status.idle": "2025-12-24T22:21:48.879921Z",
     "shell.execute_reply": "2025-12-24T22:21:48.878785Z"
    },
    "papermill": {
     "duration": 2.013174,
     "end_time": "2025-12-24T22:21:48.881410",
     "exception": false,
     "start_time": "2025-12-24T22:21:46.868236",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "data": {
      "text/plain": [
       "\n",
       "\n",
       "Table: Protein training terms with additional information\n",
       "\n",
       "|EntryID |term       |aspect | term_info|term_name                              | Organism|Scientific_Name |Type |\n",
       "|:-------|:----------|:------|---------:|:--------------------------------------|--------:|:---------------|:----|\n",
       "|Q5W0B1  |GO:0000785 |C      |  7.836723|chromatin                              |     9606|Homo sapiens    |E    |\n",
       "|Q5W0B1  |GO:0004842 |F      |  7.947949|ubiquitin-protein transferase activity |     9606|Homo sapiens    |E    |\n",
       "|Q5W0B1  |GO:0051865 |P      | 10.781162|protein autoubiquitination             |     9606|Homo sapiens    |E    |\n",
       "|Q5W0B1  |GO:0006275 |P      |  7.067590|regulation of DNA replication          |     9606|Homo sapiens    |E    |\n",
       "|Q5W0B1  |GO:0006513 |P      | 10.781162|protein monoubiquitination             |     9606|Homo sapiens    |E    |"
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    }
   ],
   "source": [
    "######################################################\n",
    "# read in train terms with matched information\n",
    "######################################################\n",
    "\n",
    "train_terms_with_info <- read.csv(paste0(additionalPath,\"train_terms_with_info.csv\"),sep=\";\")\n",
    "\n",
    "kable(train_terms_with_info[1:5,], caption=\"Protein training terms with additional information\")"
   ]
  }
 ],
 "metadata": {
  "kaggle": {
   "accelerator": "none",
   "dataSources": [
    {
     "databundleVersionId": 14875579,
     "sourceId": 116062,
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
   "duration": 85.237114,
   "end_time": "2025-12-24T22:21:49.109005",
   "environment_variables": {},
   "exception": null,
   "input_path": "__notebook__.ipynb",
   "output_path": "__notebook__.ipynb",
   "parameters": {},
   "start_time": "2025-12-24T22:20:23.871891",
   "version": "2.6.0"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 5
}
