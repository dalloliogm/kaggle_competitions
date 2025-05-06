{
 "cells": [
  {
   "cell_type": "markdown",
   "id": "7fafc7f6",
   "metadata": {
    "papermill": {
     "duration": 0.006918,
     "end_time": "2025-05-06T17:27:32.908116",
     "exception": false,
     "start_time": "2025-05-06T17:27:32.901198",
     "status": "completed"
    },
    "tags": []
   },
   "source": [
    "\n",
    "# <div align=\"center\"> Stanford RNA 3D Folding \n",
    "    \n",
    "\n",
    "<div align=\"center\"> <img src=\"https://www.kaggle.com/competitions/87793/images/header\" width=\"300\"></div><br>\n",
    "\n",
    "**From the competition material**: For each sequence in the test set, you can predict <ins>five structures</ins>. Your notebook should look for a file test_sequences.csv and output submission.csv. This file should contain x, y, z coordinates of the C1' atom in each residue across your predicted structures 1 to 5:\n",
    "\n",
    "\n",
    "**ID**,**resname**,**resid**,**x_1**,**y_1**,**z_1**,... **x_5**,**y_5**,**z_5** <br>\n",
    "R1107_1,G,1,-7.561,9.392,9.361,... -7.301,9.023,8.932<br>\n",
    "R1107_2,G,1,-8.02,11.014,14.606,... -7.953,10.02,12.127<br>\n",
    "etc.<br>\n",
    "\n",
    "\n",
    "**Evaluation**: Submissions are scored using <ins>TM-score</ins> (\"template modeling\" score), which goes from 0.0 to 1.0 (higher is better):\n"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "d254537f",
   "metadata": {
    "papermill": {
     "duration": 0.005598,
     "end_time": "2025-05-06T17:27:32.919509",
     "exception": false,
     "start_time": "2025-05-06T17:27:32.913911",
     "status": "completed"
    },
    "tags": []
   },
   "source": [
    "# 📚 Libraries"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 1,
   "id": "4f1e0e77",
   "metadata": {
    "_execution_state": "idle",
    "_kg_hide-input": true,
    "_kg_hide-output": true,
    "_uuid": "051d70d956493feee0c6d64651c6a088724dca2a",
    "collapsed": true,
    "execution": {
     "iopub.execute_input": "2025-05-06T17:27:32.933959Z",
     "iopub.status.busy": "2025-05-06T17:27:32.932293Z",
     "iopub.status.idle": "2025-05-06T17:27:40.060938Z",
     "shell.execute_reply": "2025-05-06T17:27:40.058583Z"
    },
    "jupyter": {
     "outputs_hidden": true
    },
    "papermill": {
     "duration": 7.13859,
     "end_time": "2025-05-06T17:27:40.063694",
     "exception": false,
     "start_time": "2025-05-06T17:27:32.925104",
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
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\n",
      "----------------------------------------------------------------------\n",
      "\n",
      "Your next step is to start H2O:\n",
      "    > h2o.init()\n",
      "\n",
      "For H2O package documentation, ask for help:\n",
      "    > ??h2o\n",
      "\n",
      "After starting H2O, you can use the Web UI at http://localhost:54321\n",
      "For more information visit https://docs.h2o.ai\n",
      "\n",
      "----------------------------------------------------------------------\n",
      "\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\n",
      "Attaching package: ‘h2o’\n",
      "\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "The following objects are masked from ‘package:lubridate’:\n",
      "\n",
      "    day, hour, month, week, year\n",
      "\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "The following objects are masked from ‘package:stats’:\n",
      "\n",
      "    cor, sd, var\n",
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
      "    &&, %*%, %in%, ||, apply, as.factor, as.numeric, colnames,\n",
      "    colnames<-, ifelse, is.character, is.factor, is.numeric, log,\n",
      "    log10, log1p, log2, round, signif, trunc\n",
      "\n",
      "\n"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\n",
      "H2O is not running yet, starting it now...\n",
      "\n",
      "Note:  In case of errors look at the following log files:\n",
      "    /tmp/RtmpxNdUkH/filed2b743be8/h2o_UnknownUser_started_from_r.out\n",
      "    /tmp/RtmpxNdUkH/filed28726428/h2o_UnknownUser_started_from_r.err\n",
      "\n",
      "\n",
      "Starting H2O JVM and connecting: .... Connection successful!\n",
      "\n",
      "R is connected to the H2O cluster: \n",
      "    H2O cluster uptime:         2 seconds 445 milliseconds \n",
      "    H2O cluster timezone:       Etc/UTC \n",
      "    H2O data parsing timezone:  UTC \n",
      "    H2O cluster version:        3.44.0.3 \n",
      "    H2O cluster version age:    1 year, 4 months and 16 days \n",
      "    H2O cluster name:           H2O_started_from_R_root_zcr263 \n",
      "    H2O cluster total nodes:    1 \n",
      "    H2O cluster total memory:   7.50 GB \n",
      "    H2O cluster total cores:    4 \n",
      "    H2O cluster allowed cores:  4 \n",
      "    H2O cluster healthy:        TRUE \n",
      "    H2O Connection ip:          localhost \n",
      "    H2O Connection port:        54321 \n",
      "    H2O Connection proxy:       NA \n",
      "    H2O Internal Security:      FALSE \n",
      "    R Version:                  R version 4.4.0 (2024-04-24) \n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "Warning message in h2o.clusterInfo():\n",
      "“\n",
      "Your H2O cluster version is (1 year, 4 months and 16 days) old. There may be a newer version available.\n",
      "Please download and install the latest version from: https://h2o-release.s3.amazonaws.com/h2o/latest_stable.html”\n"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\n"
     ]
    }
   ],
   "source": [
    "library(tidyverse) # metapackage of all tidyverse packages\n",
    "library(h2o)\n",
    "h2o.init()"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "46bfe9ee",
   "metadata": {
    "papermill": {
     "duration": 0.010375,
     "end_time": "2025-05-06T17:27:40.086463",
     "exception": false,
     "start_time": "2025-05-06T17:27:40.076088",
     "status": "completed"
    },
    "tags": []
   },
   "source": [
    "# 🔍 Exploratory Data Analysis (EDA)"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 2,
   "id": "41994b15",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-05-06T17:27:40.134203Z",
     "iopub.status.busy": "2025-05-06T17:27:40.107115Z",
     "iopub.status.idle": "2025-05-06T17:27:41.034761Z",
     "shell.execute_reply": "2025-05-06T17:27:41.033310Z"
    },
    "papermill": {
     "duration": 0.938869,
     "end_time": "2025-05-06T17:27:41.036615",
     "exception": false,
     "start_time": "2025-05-06T17:27:40.097746",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [],
   "source": [
    "# Reading in the competition material\n",
    "train_sequences <- read.csv('/kaggle/input/stanford-rna-3d-folding/train_sequences.csv') \n",
    "train_labels <- read.csv('/kaggle/input/stanford-rna-3d-folding/train_labels.csv') \n",
    "validation_sequences <- read.csv('/kaggle/input/stanford-rna-3d-folding/validation_sequences.csv') \n",
    "validation_labels <- read.csv('/kaggle/input/stanford-rna-3d-folding/validation_labels.csv') "
   ]
  },
  {
   "cell_type": "markdown",
   "id": "c3279775",
   "metadata": {
    "papermill": {
     "duration": 0.006053,
     "end_time": "2025-05-06T17:27:41.049020",
     "exception": false,
     "start_time": "2025-05-06T17:27:41.042967",
     "status": "completed"
    },
    "tags": []
   },
   "source": [
    "### train_sequences.csv"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 3,
   "id": "03d5e3a3",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-05-06T17:27:41.064063Z",
     "iopub.status.busy": "2025-05-06T17:27:41.062805Z",
     "iopub.status.idle": "2025-05-06T17:27:41.088780Z",
     "shell.execute_reply": "2025-05-06T17:27:41.087676Z"
    },
    "papermill": {
     "duration": 0.035371,
     "end_time": "2025-05-06T17:27:41.090264",
     "exception": false,
     "start_time": "2025-05-06T17:27:41.054893",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "[1] \"train_sequences has 844 rows and 5 columns\"\n"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "[1] \"train_sequences has 0 NAs.\"\n"
     ]
    },
    {
     "data": {
      "text/html": [
       "<table class=\"dataframe\">\n",
       "<caption>A data.frame: 3 × 5</caption>\n",
       "<thead>\n",
       "\t<tr><th></th><th scope=col>target_id</th><th scope=col>sequence</th><th scope=col>temporal_cutoff</th><th scope=col>description</th><th scope=col>all_sequences</th></tr>\n",
       "\t<tr><th></th><th scope=col>&lt;chr&gt;</th><th scope=col>&lt;chr&gt;</th><th scope=col>&lt;chr&gt;</th><th scope=col>&lt;chr&gt;</th><th scope=col>&lt;chr&gt;</th></tr>\n",
       "</thead>\n",
       "<tbody>\n",
       "\t<tr><th scope=row>1</th><td>1SCL_A</td><td><span style=white-space:pre-wrap>GGGUGCUCAGUACGAGAGGAACCGCACCC     </span></td><td>1995-01-26</td><td><span style=white-space:pre-wrap>THE SARCIN-RICIN LOOP, A MODULAR RNA                                                                 </span></td><td><span style=white-space:pre-wrap>&gt;1SCL_1|Chain A|RNA SARCIN-RICIN LOOP|Rattus norvegicus (10116)\n",
       "GGGUGCUCAGUACGAGAGGAACCGCACCC\n",
       "                                        </span></td></tr>\n",
       "\t<tr><th scope=row>2</th><td>1RNK_A</td><td>GGCGCAGUGGGCUAGCGCCACUCAAAAGGCCCAU</td><td>1995-02-27</td><td><span style=white-space:pre-wrap>THE STRUCTURE OF AN RNA PSEUDOKNOT THAT CAUSES EFFICIENT FRAMESHIFTING IN MOUSE MAMMARY TUMOR VIRUS  </span></td><td><span style=white-space:pre-wrap>&gt;1RNK_1|Chain A|RNA PSEUDOKNOT|null\n",
       "GGCGCAGUGGGCUAGCGCCACUCAAAAGGCCCAU\n",
       "                                                               </span></td></tr>\n",
       "\t<tr><th scope=row>3</th><td>1RHT_A</td><td><span style=white-space:pre-wrap>GGGACUGACGAUCACGCAGUCUAU          </span></td><td>1995-06-03</td><td>24-MER RNA HAIRPIN COAT PROTEIN BINDING SITE FOR BACTERIOPHAGE R17 (NMR, MINIMIZED AVERAGE STRUCTURE)</td><td>&gt;1RHT_1|Chain A|RNA (5'-R(P*GP*GP*GP*AP*CP*UP*GP*AP*CP*GP*AP*UP*CP*AP*CP*GP*CP*AP*GP*UP*CP*UP*AP*U)-3')|null\n",
       "GGGACUGACGAUCACGCAGUCUAU\n",
       "</td></tr>\n",
       "</tbody>\n",
       "</table>\n"
      ],
      "text/latex": [
       "A data.frame: 3 × 5\n",
       "\\begin{tabular}{r|lllll}\n",
       "  & target\\_id & sequence & temporal\\_cutoff & description & all\\_sequences\\\\\n",
       "  & <chr> & <chr> & <chr> & <chr> & <chr>\\\\\n",
       "\\hline\n",
       "\t1 & 1SCL\\_A & GGGUGCUCAGUACGAGAGGAACCGCACCC      & 1995-01-26 & THE SARCIN-RICIN LOOP, A MODULAR RNA                                                                  & >1SCL\\_1\\textbar{}Chain A\\textbar{}RNA SARCIN-RICIN LOOP\\textbar{}Rattus norvegicus (10116)\n",
       "GGGUGCUCAGUACGAGAGGAACCGCACCC\n",
       "                                        \\\\\n",
       "\t2 & 1RNK\\_A & GGCGCAGUGGGCUAGCGCCACUCAAAAGGCCCAU & 1995-02-27 & THE STRUCTURE OF AN RNA PSEUDOKNOT THAT CAUSES EFFICIENT FRAMESHIFTING IN MOUSE MAMMARY TUMOR VIRUS   & >1RNK\\_1\\textbar{}Chain A\\textbar{}RNA PSEUDOKNOT\\textbar{}null\n",
       "GGCGCAGUGGGCUAGCGCCACUCAAAAGGCCCAU\n",
       "                                                               \\\\\n",
       "\t3 & 1RHT\\_A & GGGACUGACGAUCACGCAGUCUAU           & 1995-06-03 & 24-MER RNA HAIRPIN COAT PROTEIN BINDING SITE FOR BACTERIOPHAGE R17 (NMR, MINIMIZED AVERAGE STRUCTURE) & >1RHT\\_1\\textbar{}Chain A\\textbar{}RNA (5'-R(P*GP*GP*GP*AP*CP*UP*GP*AP*CP*GP*AP*UP*CP*AP*CP*GP*CP*AP*GP*UP*CP*UP*AP*U)-3')\\textbar{}null\n",
       "GGGACUGACGAUCACGCAGUCUAU\n",
       "\\\\\n",
       "\\end{tabular}\n"
      ],
      "text/markdown": [
       "\n",
       "A data.frame: 3 × 5\n",
       "\n",
       "| <!--/--> | target_id &lt;chr&gt; | sequence &lt;chr&gt; | temporal_cutoff &lt;chr&gt; | description &lt;chr&gt; | all_sequences &lt;chr&gt; |\n",
       "|---|---|---|---|---|---|\n",
       "| 1 | 1SCL_A | GGGUGCUCAGUACGAGAGGAACCGCACCC      | 1995-01-26 | THE SARCIN-RICIN LOOP, A MODULAR RNA                                                                  | &gt;1SCL_1|Chain A|RNA SARCIN-RICIN LOOP|Rattus norvegicus (10116)\n",
       "GGGUGCUCAGUACGAGAGGAACCGCACCC\n",
       "                                         |\n",
       "| 2 | 1RNK_A | GGCGCAGUGGGCUAGCGCCACUCAAAAGGCCCAU | 1995-02-27 | THE STRUCTURE OF AN RNA PSEUDOKNOT THAT CAUSES EFFICIENT FRAMESHIFTING IN MOUSE MAMMARY TUMOR VIRUS   | &gt;1RNK_1|Chain A|RNA PSEUDOKNOT|null\n",
       "GGCGCAGUGGGCUAGCGCCACUCAAAAGGCCCAU\n",
       "                                                                |\n",
       "| 3 | 1RHT_A | GGGACUGACGAUCACGCAGUCUAU           | 1995-06-03 | 24-MER RNA HAIRPIN COAT PROTEIN BINDING SITE FOR BACTERIOPHAGE R17 (NMR, MINIMIZED AVERAGE STRUCTURE) | &gt;1RHT_1|Chain A|RNA (5'-R(P*GP*GP*GP*AP*CP*UP*GP*AP*CP*GP*AP*UP*CP*AP*CP*GP*CP*AP*GP*UP*CP*UP*AP*U)-3')|null\n",
       "GGGACUGACGAUCACGCAGUCUAU\n",
       " |\n",
       "\n"
      ],
      "text/plain": [
       "  target_id sequence                           temporal_cutoff\n",
       "1 1SCL_A    GGGUGCUCAGUACGAGAGGAACCGCACCC      1995-01-26     \n",
       "2 1RNK_A    GGCGCAGUGGGCUAGCGCCACUCAAAAGGCCCAU 1995-02-27     \n",
       "3 1RHT_A    GGGACUGACGAUCACGCAGUCUAU           1995-06-03     \n",
       "  description                                                                                          \n",
       "1 THE SARCIN-RICIN LOOP, A MODULAR RNA                                                                 \n",
       "2 THE STRUCTURE OF AN RNA PSEUDOKNOT THAT CAUSES EFFICIENT FRAMESHIFTING IN MOUSE MAMMARY TUMOR VIRUS  \n",
       "3 24-MER RNA HAIRPIN COAT PROTEIN BINDING SITE FOR BACTERIOPHAGE R17 (NMR, MINIMIZED AVERAGE STRUCTURE)\n",
       "  all_sequences                                                                                                                           \n",
       "1 >1SCL_1|Chain A|RNA SARCIN-RICIN LOOP|Rattus norvegicus (10116)\\nGGGUGCUCAGUACGAGAGGAACCGCACCC\\n                                        \n",
       "2 >1RNK_1|Chain A|RNA PSEUDOKNOT|null\\nGGCGCAGUGGGCUAGCGCCACUCAAAAGGCCCAU\\n                                                               \n",
       "3 >1RHT_1|Chain A|RNA (5'-R(P*GP*GP*GP*AP*CP*UP*GP*AP*CP*GP*AP*UP*CP*AP*CP*GP*CP*AP*GP*UP*CP*UP*AP*U)-3')|null\\nGGGACUGACGAUCACGCAGUCUAU\\n"
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    }
   ],
   "source": [
    "print(paste('train_sequences has', dim(train_sequences)[1], 'rows and', dim(train_sequences)[2], 'columns'))\n",
    "print(paste('train_sequences has', sum(is.na(train_sequences)), 'NAs.'))\n",
    "\n",
    "# Quick look at the data\n",
    "train_sequences %>% head(3)\n",
    "\n",
    "# There are no NAs in this dataset"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "ee445496",
   "metadata": {
    "papermill": {
     "duration": 0.006157,
     "end_time": "2025-05-06T17:27:41.103004",
     "exception": false,
     "start_time": "2025-05-06T17:27:41.096847",
     "status": "completed"
    },
    "tags": []
   },
   "source": [
    "### Let's focus on the sequence column...specifically the length of the sequences."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 4,
   "id": "33b388ea",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-05-06T17:27:41.118146Z",
     "iopub.status.busy": "2025-05-06T17:27:41.116959Z",
     "iopub.status.idle": "2025-05-06T17:27:41.704749Z",
     "shell.execute_reply": "2025-05-06T17:27:41.703502Z"
    },
    "papermill": {
     "duration": 0.597511,
     "end_time": "2025-05-06T17:27:41.706690",
     "exception": false,
     "start_time": "2025-05-06T17:27:41.109179",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "data": {
      "image/png": "iVBORw0KGgoAAAANSUhEUgAABwgAAAPACAIAAACuBbobAAAABmJLR0QA/wD/AP+gvaeTAAAg\nAElEQVR4nOzdd2CdVf0/8HNHdtp00dJCKbSU2QJlySogQ0Flg4hCAcXxZfgFqQwRAZmilqEg\nfFHEAaI/FESGsgQHKCAgyhIoSzYdadOsO57fH7cNadqkt5AmIef1+qv39NxzPs95zn2SvPPk\n3lSSJAEAAAAAICbp/i4AAAAAAKCvCUYBAAAAgOgIRgEAAACA6AhGAQAAAIDoCEYBAAAAgOgI\nRgEAAACA6AhGAQAAAIDoCEYBAAAAgOgMnmB04SvnppaRzlSNGL32rvt/8cZH3+mvwh7/1lap\nVGrX377YXwU0v/HHI3fdYlR95ZiNv9ZfNQxK/X5ml/XsT3ZMpVI7/uTZfpl9AC5ISXvj/ZNq\nKs55bM57eO4/Tt0slUrted9r3XXo3zXvTpdzscKj6EVJcdE+o+v2u+LffTAXAAAAvB+DJxgt\nSWfq1u1kwhojF815+Z4b/+/ArdY+645X+7u6ciXFRX/961///vArvTLaGdP3v+aeRyrWn77H\njpN7ZUAGiN7dJ4PYJZ84sGnKeV/fbOT7H2pgrvmAqiqVrvvBrw793Zd3+fOC9v6uBQAAAHqS\n7e8CellVw87PPntL55b2+bO//aWPff2Xz5x3wN4zGx+uS6f6q7by5Vv+s8MOOwxd6/TGl775\nfsdK2i95vrGidsPnH7qr9oNw7JSvN/fJ4DXnX2ed9JfXv/Wfz7+3p6990NnXbDB3jQ2Glx4O\nzDVfYVVdjmJVG7fz5fs0/PzQT//qpVsO7ZsZAQAA4D0YbHeMLqty2MRTf/6X8VXZ9qZHfvDa\nov4up68lxZZcklTUbiwVJU7fP+R7dWMOO2nysPf29JGb73X44YfvNqamd6vqY31+FJnzzt/6\nlduPun1ea1/NCAAAACtt8AejIYR0dtSuw6pCCHPyhVU0RbG9tZCsorEpU3FRa76/a1hZH8Sa\nP0ha5tx41pNzNz75pP4uZFBI2t7KFcvsO/GQWdnQftJZj67SigAAAOD9iCIYTfJz72lsS6Wr\nDhxV26m5eN/Pz997x01WG1ZfWdewzpTtjj7jqtfaFienbfPuW7M6W1E94a+d3iavmHtzt5E1\n6Wztj55tDCEct8aQippJuYVPnLDPtg21dRWZ7PAx4z96yLF3P7tgRRX1NPX1G46qrN88hLDg\n5bNTqdTI9X/83sYJIdy154R0dlgIofmdG1Kp1JA1jutuoLn/vvXLh+yx7tiRVRWVDSPXnP6J\nI6//+xvLdnvpL9cdse/Oa4weXlU7bPLUrY4+64rnmpfK9ZLCwuvOP367jdYeWlM1YuyEPT9z\n7O3/nvvgCVNTqdRtS+4de+B/NkqlUgc8NWfpJzamUqm61Q5aqelKn3vzuWfnPfyz06asOay+\npiJbVbfOJtO/fuWdS9Wd5O/84Zl7bLPhiCHVdcNGb/bh/Wfd8PB7OLpy9FrNoXD7ZafuOGWd\nIVXVo8dveMTJP2wpho3rKoeMXfwn4T3vk4XP33nUfjuOGTm0orpu7anbf+3yP/RQ8237rpNK\npbY8/59d2l+9+5OpVGrE+meVHiaFxuu+O3PXrTca2VCXraxZbfx6e37my394urG7Ycs/0eWs\nW5lbtIunLz07SZITDp1Uevjt9UekUqlDH3qro0Pj7FNKH9R2/DPzOhrf+ednU6lUw1onhxAe\nO2uLjo8t6sU1X2IFL+FQxjKWc8XofBQdVrjmT1+5fSqVOvb5+U0v3fap6RvVV9b+7K3m0n+t\n8HRU1E07flz9s9ec5BdGAAAADFzJYLHg5XNCCDUjPt6lvX3hSxd8ZsMQwoYzruvcfslhm4YQ\nUqnUmIlTd9x2y+EVmRBCw7p7P7EoV+rw9NUHhRDG7nBOx1NuPWZKCGH7M/5cenjsuPpM5dgZ\n6w0LIWRrV9t02gb12XQIIVM5+nsPvtXxrH9esGUIYZebXihz6sdmffOkE48MIVQN3f6UU075\n5ncf7u6QV3gIz159wSknHR9CqKhd/5RTTjnjvN8ud5y3/zFrWDYdQhgxceMddtpho7UbQgjp\nTP2lT87t3O2Bi2ZkUqlUKjVm7Y22/9Cmo+qyIYS6NXa5+83mUodibs7R240p7avR60zZaK2R\nIYR0pu4jm48MIdw6t6XU7f4vbRhC2P/JdzoPXszPDyHUjjqw/OmSJPnPNdNDCLt+54hUKlU3\ndt1d99pnh83XLhXwiUv+taRX/vyDNigd0bRtpm81dXI2lQoh7DjzNyt1dMta9sz2Xs3JZTOm\nhBBS6er1pm27wfgRIYQ1dj56fFW2fvWjSh2Wu09Kg085+fQ1qjL14ybvttc+0zdfa8ng/+7u\nQOY+fUoIoW71z3Vpv3zaaiGEA257OUmSYn7B57ceHUJIZ4dtuuW2O2231drDq0IImcqxN7/d\n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\nVKMAAAAAQHQEowAAAABAdASjAAAAAEB0BKMAAAAAQHQEowAAAABAdASjAAAAAEB0BKMAAAAA\nQHQEowAAAABAdLL9XQDv17nnnrto0aJeGWrs2LHHHXdcrwwFAAAAAAOZYPQD75577mlsbOyV\nodZbbz3BKAAAAAAxEIwOEuuss87YsWNDCI888khra2upsbq6evPNNy/n6S+++OJrr722CusD\nAAAAgIFEMDpI7Lvvvp/5zGdCCHvvvXdHxDlixIhLL720nKfPmjXruuuuW4X1AQAAAMBA4sOX\nAAAAAIDoCEYBAAAAgOgIRgEAAACA6AhGAQAAAIDoCEYBAAAAgOgIRgEAAACA6AhGAQAAAIDo\nCEYBAAAAgOgIRgEAAACA6AhGAQAAAIDoCEYBAAAAgOgIRgEAAACA6AhGAQAAAIDoCEYBAAAA\ngOgIRgEAAACA6AhGAQAAAIDoCEYBAAAAgOgIRgEAAACA6AhGAQAAAIDoCEYBAAAAgOgIRgEA\nAACA6AhGAQAAAIDoCEYBAAAAgOgIRgEAAACA6AhGAQAAAIDoCEYBAAAAgOgIRgEAAACA6AhG\nAQAAAIDoCEYBAAAAgOgIRgEAAACA6AhGAQAAAIDoCEYBAAAAgOgIRgEAAACA6AhGAQAAAIDo\nCEYBAAAAgOgIRgEAAACA6AhGAQAAAIDoCEYBAAAAgOgIRgEAAACA6AhGAQAAAIDoCEYBAAAA\ngOgIRgEAAACA6AhGAQAAAIDoCEYBAAAAgOgIRgEAAACA6AhGAQAAAIDoCEYBAAAAgOgIRgEA\nAACA6AhGAQAAAIDoCEYBAAAAgOgIRgEAAACA6AhGAQAAAIDoCEYBAAAAgOgIRgEAAACA6AhG\nAQAAAIDoCEYBAAAAgOgIRgEAAACA6AhGAQAAAIDoCEYBAAAAgOgIRgEAAACA6AhGAQAAAIDo\nCEYBAAAAgOgIRgEAAACA6AhGAQAAAIDoCEYBAAAAgOgIRgEAAACA6AhGAQAAAIDoCEYBAAAA\ngOgIRgEAAACA6AhGAQAAAIDoCEYBAAAAgOgIRgEAAACA6AhGAQAAAIDoCEYBAAAAgOgIRgEA\nAACA6GT7u4BekCRJc3Nzf1exyiVJEkJob28vFArLtveKYrG4aNGi3hqNvlcsFtva2rrsEOhQ\nLBZDCLlcziud7hQKhWKx2ItfWRhkSl9i8vm8ywjdyefzSZLYIXQnn8+HEAqFgk1Cd3K5nMsI\n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\nNiMYDYJgxaKFha27Hfq1bumHX8z8/IsgCIKgX79+uS4MAAAAACBfsg1Gq5a9+q2jhv3P9BUb\nfTaVSuWuJAAAAACA/Mo2GH3gtHNenrH2lEt/eMK+PQqcPQ8AAAAA7MyyDUZ/OnVpr2F/euHe\nQXmtBgAAAABgG4hmM1IqsXZpbaL7sH3zXQ0AAAAAwDaQVTAaiZX/x24lsx99L9/VAAAAAABs\nA1kFo0EQ+f2LN9e8fPb5Nz/21fp4fisCAAAAAMizbK8xeuYPn+uwe+FjN57/m5subN2xY2ns\n/9yAacGCBXmoDQAAAAAgL7INRtu2bdu27fHd989rMQAAAAAA20K2wegzzzyT1zoAAAAAALaZ\nbIPRtOmvPfm7P78zf8mKo8fc/5+Fk6Ys3nfAPu3zVBkAAAAAQJ5kH4ym7h151OWPTko/KLvh\n7pPX3X3MAS8e/e1fvjru8oJI5mkBAAAAAHYgWd6VPpj1xBmXPzrpuMt//sGMRekhrfqOvfWi\nI9588LuD7v8sb+UBAAAAAORetsHoT6/6a+s9f/jqPf+9b59O6SEFZXv88P63f9y/zZujbs5b\neQAAAAAAuZdtMPr0sg29zx/eePjp5/aqWv5CTksCAAAAAMivbIPRbsWxtTPWNB6+8uPVseJO\nOS0JAAAAACC/sg1Grz2s/czHz528rKr+wMrFr498cnbbA67JQ2EAAAAAAPmS7V3pz3jygRu7\nnzag5/7nXzw8CIKPf//Izas+fPjeJxYld//9U0M3c6HJN35/7wsT/r5gbWyPfQ49/79G9irb\naBlZjsbOZ8GCBRMnTly7dm3Hjh1LSkqmTp36/vvvl5aWnnDCCa1atfr000/j8Xj//v0LCwtn\nzpzZtm3btm3bzpo1Kx6Pt2vXrm3btn379i0rK/v8888rKyuj0ejs2bMTicTBBx/cv3//aDTb\nrD+zZDI5c+bMadOmVVVV9e3bd/Xq1dOnTy8uLu7cuXO/fv2Kiormz5+fSCRSqVR5eXmLFi2W\nLVtWWlraq1evt956a9KkSe3atTvttNMqKioazLampmbmzJmLFy/u3Llz3759Cwry1aTj8fiM\nGTMWLVrUqVOnPn36FBUVNR5n4cKFs2bNKi0tLS0tXbZsWd3L6dOnz8qVKxcsWNC+ffuKiori\n4uI8FbmVVqxYMWPGjOrq6j59+nTqtLMet55IJGbMmLFw4cIMa6opixcvnjlzZnFxcd++fVu3\nbr1lBeRkJuw4VqxY8fnnn9fU1FRUVHTs2HGT49fW1s6YMWPx4sXNmjVLdwKtW7det27d+vXr\nO3funEqlFi9enEgkgiAoLS2NxWILFiyIx+O9e/cuLy+fNm3a+vXrDz/88AMOOCD/r2zbSXf4\nGzZs6NOnT+fOneuGx+PxmTNnZvlpnT9//qxZs5o3b96vX7/mzZtvbg2pVGr27Nnz5s3bbbfd\nCgoKli5d2r59+759+5aUlGzJS8pozpw5c+fObdmyZb9+/Zo1a5bz+cNOKh6Pv/POO++//36H\nDh2OPvrobHrUOundyAULFrRr166ioiIfn9zNVb8Ha9++/Zw5c9avX9+rV69u3boFQVBdXT1h\nwoSJEycWFRWddNJJBx544BYvaN26ddOnT1+zZk2vXr26d++eq/prampmzJjxxRdfdOnSpW/f\nvrFYLFdzJoPKysrp06evXLmye/fuvXr1ikQi27sitsSCBQtmzZpVVla2xx57tGjRIj1w7ty5\nc+bMadGiRb9+/crLy/O0aJ/cnKj7vlZRUdGqVavsJ1y0aNHMmTNLS0srKip22223Bs/WRRPW\nTpB9MFra7qR/fPD8JRdf9dBdo4IgeOP6q96MxPY+Zugz99x7yu6btxs9+4/X/+zJeWdf/t0L\nWsVfGver666oeWLc5Y3TrCxHY+eybNmy66+//r333tvos59++mnd/0899VSG+USj0WQy2WBg\n27Ztx4wZs99++21lkZ988slNN900Z86crZnJk08+2bNnz8cee6ysrCw95O233x49evQXX3yR\nfti1a9cf/ehHhx566FZW29i777576623Lly4MP1w9913v+aaa4466qi6EZYsWXL77bf/7W9/\n2+Ss2rRpc9VVV33jG9/IeZFbo6amZty4cU888UQ8Hg+CIBKJfOMb37jqqqt2ulzv73//+y23\n3DJv3rz0ww4dOlxzzTVHH330JidcsWLFnXfe+Ze//CWVSgVBUFBQMGLEiIsvvnizctUVK1bc\nddddf/7zn+tmMnz48EsuuWSzZsKOo7q6+r777vvd736XzjEjkciJJ5545ZVXNt4NqjN58uTb\nbrtt0aJFW7Pchx9+uEOHDr/4xS/69OmzNfPZESQSiYceeuixxx6rqalJDzn22GOvvvrq9u3b\nT5s27ZZbbpk/f356eMeOHX/wgx9s9NO6aNGi0aNHv/POO+mHJSUlF1100dlnn53973YzZ868\n9dZbP/zwwwbDc94hz5s377bbbqvbIjdr1uySSy75z//8T1994W9/+9uoUaPWr1+ffnj77bcf\nc8wxP/3pT7PZRH788ce33HLL559/nn7YunXrK6+88oQTTshjuZvSoAeLRCLpTX8QBEceeeRh\nhx32y1/+sra2Nj3k2WefbdWq1a9+9avGP/BnlkqlHn/88XHjxlVV/esUw8MOO+xHP/pRly5d\ntrL+N954Y+zYsUuWLEk/7NGjx3XXXbeL/Sa3A/rTn/509913r1u3Lv1w3333ve6663r37r19\nq2KzfPnll2PGjJk4cWL6YXFx8ciRIwcOHDh69OipU6emB5aWll5yySXDhw/P+db/zTffHDNm\nTP1P7rXXXrs1v7uE0PLly++4446//vWv6YeFhYVnn332RRddVFhYmHnCZcuW3X777a+99lrd\nhOeee+53vvOdugOzJkyYMHbs2C+//DL9sHv37tdee+1BBx2Un9exE/jf7WKWNiyd8/GsxfFY\naZe+e3fZbfMPJUvVfHfYsKIz77hraO8gCKpXvTXk3LFD7vvdOZ2bbcloYbJ8+fL0AX0NfnY+\n7rjjVq9efcUVV4wYMSIIgkGDBi1evDj9VKdOnZ5//vlsZn7XXXeNHz++oqJi/PjxOa+8Tm1t\n7ZlnnrmVX8IzKygoePzxx7fm+/mCBQvOOuusul26rdSxY8cXX3wxCIKpU6dedtllkUikLs+N\nRqPRaPShhx7aZ599crKsIAhWrVo1a9asyy+/PJlM1l9QKpW67777Dj744CAIampqhg0btmjR\nosbJcmPpDeSYMWOOPfbYXBW59X7yk580aNiRSKSiouI3v/nNTvRL16effnrBBRckEon6ayoI\ngrvvvvvwww/PMGEikTjnnHNmzJjRoPceNGjQjTfemHmhK1euTCQSZWVlxcXF55133vTp0xvM\n5NRTT73pppu25PWwvV1//fWvvPJK/a+7kUhk7733fuSRRzYayb3//vsXX3xxKpXKpivYpKKi\noldffbXud6Cd1O233/7kk0/Wfw+j0Wi3bt1uuOGGSy65pMGnNZVK3XPPPYcddlj9Oaxfv37I\nkCHLli2rGzM9t4suuuiiiy7KpoalS5cOHTp0/fr1jddLeqGjR48+5p5b2AAAIABJREFU7rjj\ntup1BkEQBKtXrx4yZMjKlSvrN5hUKvW9733v3HPPzTxhbW1tcXHxFhwJS0ikk5T8HYKUbx99\n9NHIkSMbf0X62te+dvfdd2eedv78+cOHD6+pqanfXSSTyVtvvXV7/cz8ySefXHjhhfV7sGwU\nFha+9tprm9WrP/TQQ/fff3+DLrRNmzZPPfVUg8awdu3a6urqwsLCli1bbnK2b7/99hVXXBEE\nQf23NBaLPfbYY5sb3ZK9p556asyYMQ3WZnl5+R/+8Ie2bdtugwIqKyvj8Xjd4Y1sgaqqqmHD\nhi1evLjBhr6srKyqqqrBjspll112wQUX5HDpkyZN+v73vx/U++TGYrFoNProo4/269dv6+df\nWVlZWVkZi8U26wjKnUs8Hh8xYsTs2bMbrMEzzjjj2muvzTBhbW3tWWedNW/evAYbsiFDhlxz\nzTVBEEyePPl73/te0KhffeSRR/bcc8+8vJjtoaqqqqqqKsMxIvVt9iGYpe16Hnz4kYcfcuCW\npKJBUL16wvyqxMCB/zo3rXi3ow4oL5r2xpdbNho7l1deeSWvqWgQBPF4/KGHHtqaOTz22GPV\n1dW5qufLL7/8+9//HgTB/fffH9TretL/J5PJBx54IFfLSnvkkUfqp6LpBUUikXvvvTf98MUX\nX1ywYEGWO8epVCoSifzyl7/MbZFbY/78+S+88EKDgalUavr06XW/ie0UHnrooQbfUtL//+pX\nv8o84Wuvvfb55583/sL2wgsv1B0Mskmvv/76Z5991ngmL774YvYzYccxe/bsV155JQiC+us0\nlUp99NFHEyZM2Ogk48aNy1UqGgRBTU3NL37xi5zMantZsmTJH/7wh+D/vofJZHLu3Lljxoxp\n/Gmt36/W+dOf/rRkyZL6Y6Z70V//+td1B91k9sQTT6xbt26j6yW90Fx1yE8++eSKFSsaNJgg\nCB544IEcbgRhZzR69OiNHjgyadKkTW4iH3300fqpaPDvT+4999yT4yqz1nh/Ixu1tbV33XVX\n9uNXVlY+8sgjQaMudOnSpU8//fRmLbqBdE/b4C1NH+C/NbMlg0Qicd9999VPRYMgSCaTa9eu\nfeKJJ7ZjYWyW559/ftGiRY039JWVlY13VB5++OENGzbkcOn33Xdfg/3MRCIRj8cffPDBHC5l\n1/aXv/xl1qxZjdfgM888U3ck3Ea98sorc+fObbwh++Mf/5g+RPS+++4LNtavhnntZHsq/erV\nqzM8m83PfWk16z8MgmCvsv899HfPsoJXPlwdjNiS0dKSyeSKFSuyLGBn9/LLLzf4llt3ms/W\nW7x4cfon2TyZMWNG/mZeZ8qUKcuWLdviyd99993NPYw6s2effbZLly4ffvhh49kmk8lp06Zt\nTbWNffDBB433fZPJ5D//+c+vvvoqFotNmTKlwY5OZslkcsGCBTNnzszyx5Z8e/vtt5sqfvLk\nyTvR2RnTpk3b6Jr67LPPFi9enOFkvcmTJ290eCqVeuutt7I5IKWysrLuPN8tngk7lLfeequp\npyZNmtT4sPRUKvX+++/nKhVNe/fdd3Pbm21jkyZN2mjfkr6S9UY/rZ988skXX3xR/2ymKVOm\nNL7SSyqVqq2tfeedd7I58fPdd9/N8GwymVy4cGFOOuSpU6du9KI0VVVVU6ZM2WuvvTJPXl1d\nLT8ls1ydfLPtzZw5s6mn3nzzzRNPPDHDtBvdjUxfr3n69Olt2rTJTYmbY6P7G9mYOnVq9r36\nP//5z7qLkNQXjUanTJlyyimnNH6qtrZ2k/OvqqqaPn164+HJZHKzymOzzJ07d82aNRt9ahtv\n663irbHRfZKNSqVS1dXVU6ZMydWJjDU1NRs9AiOVSr333ns5XK2JRGIXbiSTJ0/e6Nf2VCo1\nceLEDOcPNTVhMpl8++23v/a1r33yyScbfTa3a2cHUfeKMh9fnG0wmnkXfDNClur1QRC0Kfjf\nI1XbFsbi6xruOWU5WgjNmzev7iohObdu3br8zXybqbtG0naZvLH169fH4/GmPiO1tbXJZDJX\n94xKf/3O8FQsFqupqdmsYDRtozu720VTlUQikZ3rO1iGNVVdXZ0hGM2wBrPPKWpra5uayc71\nNpKW4RO60adSqVT6UqQ5lL7m784rw8enqS8VqVSqpqamfjCaYQuSZS9aU1Ozyf45J4lkdXV1\nhg3T1s8fdl4ZusfKysrM02b4CG+vT9YW78JtVq++uZuhLGV40/RU+dPUKkvvo27jYthim/sZ\nyeHKzdAT7jhfKnd8Gb6vZX4bM0xYXV2dIZoI89rJNhgdNWrU/3mcii+e/cmzTz63ItJ51H23\nZr+8aFFpEAQr48nyf18KcHltIrZbwwggy9HSIpFIGC50tW7dulQq1adPnwZXe5w4cWKu9gya\nN29+yCGH5GRWGzV37tzZs2fnb/5pPXv23Jr20Lt372XLluXwoNGDDz64TZs2HTp0WLJkSYPZ\nRiKR7t27Z3/A9SatX7++a9eu8+fPb/A1PhKJtG/fvl27dkEQ9O3bd3Pj72bNmvXo0WMHuXzn\nHnvssdHhqVSqoqJiJ+oKevToMWPGjMaBS5s2bTp16pRhwr59+6ZPmm5szz33zPwOpC9cmL4H\n/csvv7xlM2EHlOFqTU19Ljp37rxw4cIc9nVdu3bdqVtOU31LMpls3bp1/WtxpkUikdatWze4\nUXXv3r2nTZu20fnstdde2bw/ffr0adyH119oaWlpjx496q6dv8V69+5d/4aHdaLRaOZOoLKy\nMpFIFBQUlJaWbmUN7KrSP7DtCLdi3zJt2rRp6pCZ/fbbL/MHuXfv3o27iyAI0p/cTd4uIx96\n9Ogxc+bMLejtu3Xrln2vnmH3rE+fPg3ms2HDhng8HovFNnkN0/Ly8latWq1atapxD7yVO/xk\nUFFREYvFGv9CEI1GG6/NPKmurk4mkzY0W6NPnz6TJk3KcuRIJJLljko2ysvLW7du3fik3mg0\nmqtPbk1NTXV1dTQabdZsl70JTZ8+fepuu9RA5l21Pn36vP76601N2L59+zZt2jS4nlKQ07Wz\ng6itra2pqalrIZlvL5btjvVGb8fx89unHFcx4Oe/mHbdyI2d4r4xhc36B8GE6RviXYv/FbLM\n2BBveVTDw1GzHC0tEokUF2/JBU93LunLkx1//PENzkZJ33wpJ4vYfffdx44dm5NZbdRXX311\n2mmn5fuoorPOOmtr2sOQIUOaOlV5CxQUFAwZMqSgoGDYsGGNL9ifSqWGDh2aw9a7YcOGM844\no/E1oeovaPDgwb/97W8z/FLU2BlnnLHj3FPlkEMO6dmz57x58+oHB9FotLi4+NRTT92JuoKh\nQ4fefPPNjYcPGTIk86s49dRTH3zwwQaXMItGo927dz/00EMzH32cPtQlFoudcsopDz74YHqn\ns/5MunXrduihh+4gITjZO+KII7p27drgpmqRSKRZs2YnnXTSRlvU0KFD77zzzhzW8N3vfncn\n+gA2tu++++61116ffvpp/b4xGo0WFBQMHz688fUBU6nUsGHDGrzkM8888+mnn06lUvVnEolE\nDjvssJ49e2ZTxpAhQ1599dWmfudPX3E/J98BhgwZ8tJLLzVeyoABAzL/NlNVVZVIJGKx2E69\nusmr9A/2O28LGTFixEYvmtyqVatNbmeHDBlSd6/n+k4//fTtdTeqoUOH3nLLLVsw4Wb16t27\nd//a1772zjvvNOj9giA488wzG8ynpqYmHo+nd942OechQ4Y0viJ/znehqa+4uPib3/zmyy+/\n3GAbsS3f9vT1KK3irXH66aePHz8+kUg0+FSmLyraYOCRRx7ZtWvXHC59yJAh48aNazAwmUw2\n3nfaMungftcOggYNGvTrX/+6wSk+0Wi0d+/eBx54YIaN0WmnnfbYY4+lz0ytP2FFRcX+++8f\niUSGDRvW+EL5yWRyF+tXU6lU9t3IVp3AW9rhsAd/sv+yD3725upsj7su2e2YTkWxP7+1JP2w\ndv37766tOfD4jls2GjuXDh06jB07NsM5wlspEokMHz78pJNO2pqZDBgw4NJLL83Jue2RSORn\nP/tZ+ries88+e9CgQZFIJBKJRKPR9N+hQ4eeeeaZW7+g+gYPHjx06NC6BaXLGDRo0DnnnJMe\noVOnTrfccks66Mzws0m6yCAIjjnmmEsvvTS3RW6NaDR6xx13dO7cOf1/+jWWl5ePHTt2u1y6\na4sNGjRo+PDh6frr2ttJJ500cuTIzBO2bt369ttvT3+/qnsHOnfufMcdd2Tfblu3bj127Nj0\nT4J1M+nUqdMdd9whFd0ZFRQU3HnnnbvvvntQb4W2bNly7NixTV0JZ9iwYd/61rfSfUXjZzP/\nptrYt7/97U1elXIHF4lERo8e3aNHj/T/6fewrKzs1ltvPe+88xp/Wk855ZTzzjuvwUx69eo1\natSo9B5YLBZLv4177LHHj3/84yzLOOigg6688sr0hqNuLdT9c8wxx1x22WVb9Tr/ba+99vrh\nD3+Y3iLXdfj77rvv9ddfn5P5w87r7LPP/o//+I8GA5s1azZu3LhNbmePPfbYiy66qK67SH+y\nBgwYcPnll+en2E0bPHhw4x6s7v+SkpJ0v9fAhRdeuPfee2/WgkaNGpXeENRthoqKim688ca+\nfftuRfnBBRdcUHdd17pXcc4552z0uqXkyg9+8IODDjooqLdBLCwsvPLKK3eiq/nTtWvXm2++\nOX3UbV131Lt37+9///vprX/6NvFBEOy9994bPQxua4wcObLuW3ndJ3fEiBGnnnpqbhe0C2vX\nrt3o0aMbfOnr2rXr2LFjM2+MOnTocNttt6W/79et+m7duo0ZMyb9/3nnnXfyySenR65bO8OH\nDx88eHCeX9OOa7MvNdjAnD8e23vIhMXVNR0Ls/1CPvP3P/p/Ty+5/Ec/2LtV7fO/GvO3dQeP\nH/ff0SCY/fTjb1a2HHnuqZlHC63ly5enUqny8vIGpyaljxi94oorRowYEQTBoEGD6m5S1qlT\np+effz6bmd91113jx4+vqKgYP358zitvYNWqVQ8//PDkyZMrKysLCwuLiormzZuXSCTSP/h0\n7Nhx5cqVyWSyVatWBQUFGzZsKCwsjEajNTU1VVVV5eXl3bt332+//crKymbMmLF06dKlS5em\nbz9VUVHx7W9/u6KiIidFzp49++mnn546dWoikWjevPn69evTh+W2atXqwAMPTCQSq1atWrFi\nRTQa7dChQ1VVVUFBQfPmzQsLC996660VK1YUFxfvs88+Y8aMabCy3n///TfffHPRokVdunQ5\n7rjjNnePc5NWrVpVUlJSUlLy0Ucfvf766wsXLuzSpcuAAQP222+/BmOuWLHiueeemzFjRiwW\nS5/ytnz58lgs1rlz5/bt28fj8YULF3bs2PHII4887LDDcltkTtTW1r7wwgsff/xxVVVVv379\nBg8e3KJFi+1d1Jb49NNPX3311QULFnTq1Onoo4/OfndzzZo1zz777PTp00tKSvbZZ59TTjkl\nmxP0Vq5cmUgkysrK0lvK9Ew+//zzdIvNcibssGpqatKfi9ra2vTnYpMHKH344YdvvPHG/Pnz\n051t8+bNI5FIYWHhunXrWrZsGYlElixZsnr16vR509XV1elTRHv06LFy5coVK1ZUV1f37t37\n6quvzu1RBttRIpF46aWX/vnPf65fv76iomLw4MF1yfInn3zy2muvLViwoHPnzkcffXSGOykt\nWbLk+eefnz17dnl5+UEHHTRw4MDN/bFtwYIFL7300ty5c2OxWPo0iw4dOuSjQ/7yyy+ff/75\nOXPmtGzZ8pBDDjn22GM3mYmvXr26tra2uLh4VzrZitxKn+S0vQ6QzJWpU6c+9NBDCxcubN68\n+RFHHHHZZZdlv4mcPXv2yy+/PH/+/A4dOhxxxBFHHHFEXkvNRl0P1qlTp+Li4pUrV65bt65P\nnz6nnXZamzZtJk6ceM8993zxxReRSKRv37433XTTlvXqyWTy1VdfnTZt2po1a3r37j1o0KD2\n7ds3Hm3t2rXV1dWFhYXZX07qvffemzhx4hdffNGtW7eBAwdmuIAMOfTGG2+8++67K1as6Nmz\n58knn9ylS5dttujKysp4PL6T7t7vUFasWPHss8/OnDmzvLx8//33P+GEE6LR6FdfffXcc8/N\nmTOnRYsWBx988PHHH7+5v4hnadq0aRMnTly8eHHXrl0HDhzY1DU3tkBlZWVlZWXm2+nsGtLf\n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\nAKrzf4pNWGoii4egAAAAAElFTkSuQmCC"
     },
     "metadata": {
      "image/png": {
       "height": 480,
       "width": 900
      }
     },
     "output_type": "display_data"
    }
   ],
   "source": [
    "options(repr.plot.width=15, repr.plot.height=8)\n",
    "train_sequences %>% select(sequence) %>% mutate(length = str_count(sequence)) %>% \n",
    "    ggplot(aes(x=length)) + geom_boxplot() + \n",
    "    xlab(\"Sequence length\") + ylab(\"Sequence\") + ggtitle(\"Boxplot of sequence length values (with outliers)\") + theme_minimal()\n",
    "\n",
    "# That's kind of messy...let's filter out some of the outliers"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 5,
   "id": "919df48b",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-05-06T17:27:41.723701Z",
     "iopub.status.busy": "2025-05-06T17:27:41.722476Z",
     "iopub.status.idle": "2025-05-06T17:27:42.120959Z",
     "shell.execute_reply": "2025-05-06T17:27:42.119202Z"
    },
    "papermill": {
     "duration": 0.409131,
     "end_time": "2025-05-06T17:27:42.123142",
     "exception": false,
     "start_time": "2025-05-06T17:27:41.714011",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "data": {
      "image/png": "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\ndAkA0JlMJuNup9vU19fX19ebc4pNY2NjY2OjZUlRqa+vb21tdcGk2DQ0NDQ3N1uWRcJnjAIA\nAAAA0RGMAgAAAADREYwCAAAAANERjAIAAAAA0RGMAgAAAADREYwCAAAAANERjAIAAAAA0RGM\nAgAAAADREYwCAAAAANERjAIAAAAA0RGMAgAAAADREYwCAAAAANERjAIAAAAA0RGMAgAAAADR\nEYwCAAAAANERjAIAAAAA0RGMAgAAAADREYwCAAAAANERjAIAAAAA0RGMAgAAAADREYwCAAAA\nANERjAIAAAAA0RGMAgAAAADREYwCAAAAANERjAIAAAAA0RGMAgAAAADREYwCAAAAANERjAIA\nAAAA0RGMAgAAAADREYwCAAAAANERjAIAAAAA0RGMAgAAAADREYwCAAAAANERjAIAAAAA0RGM\nAgAAAADREYwCAAAAANERjAIAAAAA0RGMAgAAAADREYwCAAAAANERjAIAAAAA0RGMAgAAAADR\nEYwCAAAAANERjAIAAAAA0RGMAgAAAADREYwCAAAAANERjAIAAAAA0RGMAgAAAADREYwCAAAA\nANERjAIAAAAA0RGMAgAAAADREYwCAAAAANERjAIAAAAA0RGMAgAAAADREYwCAAAAANERjAIA\nAAAA0RGMAgAAAADREYwCAAAAANERjAIAAAAA0RGMAgAAAADREYwCAAAAANERjAIAAAAA0RGM\nAgAAAADREYwCAAAAANERjAIAAAAA0RGMAgAAAADREYwCAAAAANERjAIAAAAA0RGMAgAAAADR\nEYwCAAAAANERjAIAAAAA0RGMAgAAAADREYwCAAAAANERjAIAAAAA0RGMAgAAAADREYwCAAAA\nANERjAIAAAAA0RGMAgAAAADREYwCAAAAANERjAIAAAAA0RGMAgAAAADREYwCAAAAANERjAIA\nAAAA0RGMAgAAAADREYwCAAAAANERjAIAAAAA0RGMAgAAAADREYwCAAAAANERjAIAAAAA0RGM\nAgAAAADREYwCAAAAANERjAIAAAAA0RGMAgAAAADREYwCAAAAANERjAIAAAAA0RGMAgAAAADR\nEYwCAAAAANERjAIAAAAA0SnpiUFzj9x6zZ/+9sy7s7Lrjt7iiOOOHN5rEWWkrdPuuOH6+x57\nfkpjZvDQUXsf9u3dxq7a/bUCAAAAACufHnjF6MTbv3fp7x7fcv9vnH38+Oo3HzrzhOtzi+p2\n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\nYII="
     },
     "metadata": {
      "image/png": {
       "height": 480,
       "width": 900
      }
     },
     "output_type": "display_data"
    }
   ],
   "source": [
    "options(repr.plot.width=15, repr.plot.height=8)\n",
    "train_sequences %>% select(sequence) %>% mutate(length = str_count(sequence)) %>% \n",
    "    ggplot(aes(x=length)) + geom_boxplot(outliers = FALSE) + \n",
    "    xlab(\"Sequence length\") + ylab(\"Sequence\") + ggtitle(\"Boxplot of sequence length values (without outliers)\") + theme_minimal()\n",
    "\n",
    "# By using the outliers = FALSE argument within geom_boxplot(), we can create something a little easier to make sense of"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "5ff860de",
   "metadata": {
    "papermill": {
     "duration": 0.007598,
     "end_time": "2025-05-06T17:27:42.138576",
     "exception": false,
     "start_time": "2025-05-06T17:27:42.130978",
     "status": "completed"
    },
    "tags": []
   },
   "source": [
    "### Let's look at the temporal_cutoff column and see how the length of published sequences has evolved over time"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 6,
   "id": "994e2615",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-05-06T17:27:42.164294Z",
     "iopub.status.busy": "2025-05-06T17:27:42.162982Z",
     "iopub.status.idle": "2025-05-06T17:27:43.408918Z",
     "shell.execute_reply": "2025-05-06T17:27:43.407677Z"
    },
    "papermill": {
     "duration": 1.262218,
     "end_time": "2025-05-06T17:27:43.411048",
     "exception": false,
     "start_time": "2025-05-06T17:27:42.148830",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "data": {
      "image/png": "iVBORw0KGgoAAAANSUhEUgAABwgAAAPACAIAAACuBbobAAAABmJLR0QA/wD/AP+gvaeTAAAg\nAElEQVR4nOzdeXxcdbn48Weyp0nbpA0tbWlL25RNFkFBdkRQQZFNUbkqgoob6EVBQL0Ibsjl\np4goi1cv7tt133ABFFDABQVRFmnaQllb0qbpkn1mfn8cCGmbpJNkJjNt3u+/kjMz5zyZzAT6\neX3PnFQ2mw0AAAAAgImkrNgDAAAAAACMN2EUAAAAAJhwhFEAAAAAYMIRRgEAAACACUcYBQAA\nAAAmHGEUAAAAAJhwhFEAAAAAYMIRRgEAAACACWf7DKPZzMZdJlWlUqmy8qq7NvQWe5xxde9/\n759KpY766cPFHuQ5S752eCqVOvxrSwq0/46nfn/GUS9oqq+a+bwPFegQA71nzuRUKvVgZ98w\n99nst/C3Dz4/lUode+sTuR+l0E9aRHx2UWMqlbqhratwh6BkjeI1CQAAANuZ7TOMrv7nhUs6\neyMim+k9/0cPF3uciSWb2Xj77bf/+a5Hx+2IFx928ld/9/fKXQ875vDF43ZQ2IaM/7sSAAAA\nSl9FsQcoiFvO+0lEzH7FwiduWPb3i78Sp11a7IkmkL7Ohw499NAp8y5qf+Rj43G8bM/nlrZX\nTtp96V9vmlSWGo8jjtzOp3z8q7utmbNbY7EHYYLa8l3pNQkAAADbYRjN9K055w9PplJl//M/\nPzhl3gvWPXL5H9ddcuiUqmLPRUFkM5292eykSc8r2SoaEdP3e9Wb9yv2EDCA1yQAAABsh6fS\nr/rr+x/vTk+ee84r5+x7yS6N2Wz6g99dNh4Hznav6s2Mx4EKLrOxa7gP0NzWZXq60tliD8E4\n2c5fzJvI05+gbLqjsyc99v0AAABAidsOw+hvzvttROz30XdExCmf2D8i/vGJL/bfesOJC1Kp\n1As/9Y/NHvX4za9NpVLTdv1o/5ZH/vjt00988ZwZjdWTGhbvtf+7P3pdS8cmheXBLx6SSqXO\nXrp2wyM3vP6wPeqrJn1jVUdEZNPt3/7MeUcdsMf0qXUVVbU7zN3l2De89zcPtm96wPSvrv7g\n4XsumFxdM2Pu7qdf8OXOTDyvrmryrDM3G2yrY+RiqztJLvXz1iVtd33jw3vu1FBfW1lRXbdg\n78P+64s3jmjs7+7eVFW/X0SsW/HxVCo1fdevDHzw+qU3vu2kw2dOn1JZU7fzXod86Jrf5DB7\n5tZvfur4w/feoaG+qm7qgj0PfvfFX3qi+5lqc9Ox88sqGiKio/UHqVRq8pz3DLWX98yZXFm7\nqHf9fe874aCpk+oqyysaZ859+aln37xkXf997nzXHqlU6tUPrB74wGy6PZVK1e1wymY7zGYz\nv/7ChYftsfPkmqrGGTsd9Zq3/+Le1TGEez76gs0udLPmX79876nHNM+aXl1ZNXX6Tocdd8Z3\n//zUoI/d6pOWyysk07vqSxe9Y/9d5tZXVzfNXnjymR/+59qeoaYd6ZBbHSCbXv/tT51z8B47\nT6mtnjZr/rFvOPtX/1rzl/ftNfDST7k/+Xl7MWf7bvzyJcccuPu0yTV1DTOef+TJV/zgrlH8\ndIMZ7kU7Dn+CNjPou3Kz1+QzT9q/V335gpNn1E+dVF1R3zjjsJPe+ZfWroj0DZ8/76Dd59VX\nV05pmn/s6R9asumVx/LyNwoAAACKILt9SXc/Nr2yPFVW/ff1PdlstmfDvdVlqVSq7Ka2ruQO\nax68MCLqdnzrZg+8Zt8dIuLVN6xIvr3zs6eVp1KpVGrmznsc8qJ9muoqIqJuzktuXtnR/5AH\nrjs4It729988f0pV7cxdjn7Fq366ujPTt+7MA2ZERFlFwz4vPOiIg/ffubE6IsqrZv3s6ece\ne/Vpe0ZEqqxml30P2m3utIiY8+J3z62uqN/xbQOnymWMzfzjshdGxEt+snxEO3noq4dFxFGf\nPj2VStXNaj7qVSccut/OySvkuM/9M/ex77niY+efe0ZEVE855MILL/zYZ+7q3/meF1w0p7q8\nfvbio191wmH7zXt25/8a/hf6uTftExGpVGrmwr0OP+iFjZXlETG1+fj7NvZms9kl11924fnn\nRETlpF0vvPDCiy/96VD7OXt2fXnVrNN2aYiIikk77LPvbvUVZRFRXjXj839ZldznjnfuHhEn\n39868IGZvrURManpNQN3FRGfPHPfiKisn/n8fXetqyiLiLKKKR//7WOD/hbuvmS/iDjmlseT\nb5/+2xUNFWURMW3h8w494tA9dp4aEWXl9Vfdv2az38hWn7Rcfrl9XQ+/bvfG/qdxtzlTI6Jm\n2iFvnlkXEb9c0znoM5bLkLkMkOld/e6DZyaTz1iw5x7zpkdEWXndy/abPvDoOT75+Xsx933q\nlN2Sn2jfAw/bf6/FFalURBx+3o9G9NMNavgXbaH/BG05z6Dvys1ek8mTttuJu0bEgn0OOeEV\n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\nL9GeHfwoqSF2lSqrHeTem6qf/6qb/r3yr7/94c9uuPG2P97x19t+8Zff//yzHz3/VRf+4KeX\nbrJodJgnLcdfbipZNjnYL3baEMErxyFzGSDdkR7q6MMe/FkDnvz8v5jLh/vrN9o3YI4v2gL+\nCRo3efkbBQAAAEW0/YTR3o33XPJQWypV/tPf33rg5KqBN/Wsu2NSw6EbV37t+63XntJUGxF7\nffC98fl3/OPj34o3X/KtD/0lVVZ5xbueOV20ombRDpXlazIdl37qU0OWlaGd9Ypzlm3ofd+3\n/3rFqc+dlLru4T/3f11V/8KI6Fr7u4hLBj6wq/33A78d4xh53Ekix7HzqGryi8pTqa62X6cj\nNouvy25ZGRGz9xxySeBQfr6y48hnL/uTWHv/7yOibu5uQzwiejuXDLr9Z6s6D9r0ZdZ23+8j\nYurzhtzVJlJV+7/81P1ffmpEpDtX3fyDL7/xrR/5+WUnfft9G/9jh62n1cj5l1u/8/Mifvv0\nnXdFHLrZTTe1dY1lyFwGWPPgvIgY7OiZn63e2tE3ffLz+WKecmDEtZ2tN0ds8tEKfZ0Pfu9H\nf6uectBrXrVwdIfL/UVbuD9B42ZbmRMAAACGsv18xugjPzm3O5OdMv8Dm1XRiKiacvB7d6qP\niMuu/neypW7W209qqm1f/qm/PnXnx5eunbb7Jw6d8uyjUpUX7NqQ7ln14T+v2nQ3mbP3WTRr\n1qyfDh10sun2/1vVUVE9b2AVjYh1Dz33uZOV9fu+pmlSd/sfvvToJmcx/+2y/9tkX2MYI887\nGdHY+VNes+i0mZP6Olsu+NPKgdv7Oh96/99bU2VV5+464jOIf3TuLzbdkP38e++IiP3OfV7/\npo0rN3lOHv/t4B8U8L3zf73phsyV77k9Il78gT2Gn6Fj1TcXL16894Hv799SXjvjZW/60FWL\nG7PZ7I1bjZX9cvvlTt7pfdMqy9Yu/dCNm/6u1/zz0tvau8c0ZA4DTJn3vpqy1JZHf/qvH75n\nwyCrdId78vP3Yp60w6l71lVufPK6X7Z2Dty+7DvveOMb3/jB7z426sPl/qIt0J+gcbWtzAkA\nAABD2H7C6PUX/S0i9vnIGYPe+rYP7BkRD179qf4tF717t2ym5w3ve1NvJvvyz79x4J1P+8o7\nI+IzR7/0u395MtmSTa//xnlHXX3vsu4prz1hes1QM6TKJy+oKU/3PHr9fW39G//6gyuOPukX\nEZHu7Eu2/PfVJ0XE+S8964F1z3zG4rKbPnvSlx6KiEg99xsZ9Rh5+Vm2lOPYzx4lDx8veNHn\nXhURXzj2hBseWJts6du47IPHHflYd9/cY647YPJIr94TK355xjuuvTmdTNjXfv15R13+YFtV\n/b5fOmZuPPuplH9+xyUre585g7vt/p+86s03DLqrh3/8hrO/dGtyv0xf2/+cc8QVD62t3eGY\nL2x61Z0t1TS+bO0jy//1l6s+8tN/9W9sve8XFy9vT6UqTtvio0uHkcsvt7x67tdObc6mO197\n8Gl3PrbxmZ/rgV+dcOQnxj7kVgeomLTntS+fu9nRV9//y+NffuVmR8zlyc/bizlV+bULDshm\n+0578Tv+ufqZOtx23y+Pf8+dqVTq3Z94/lgOl/uLthB/goaXl3flQAWaEwAAAMZJ4S98Px66\n2/9QnkqlUuW3t3cPeofO1b9Mft6vrdyYbOl4+vvJloqaBat7M5vd/8fnvzS5dee9DzjqyEMW\nNdVERPXUfW94amP/fR647uCIOOyrDw184B0fOSIiysrrDn3Zq1574jH77DKzrLz+1AsujIjy\nqlmnv+usjnQmm81e9+a9I6KscvKeBxy+18KZEXHcJ66NiMlzPzDSMTbzj8teGBEv+cnyEe3k\noa8eFhEHX/fAZnvbY1JledWs/m9zGTvd21pdlkqlKl/+6te/9eyb+ne+2ROVzWYX1lRU1Cwc\n6gfJZrPZbOaKN+wVEalU+U677nf4/nvUV5RFxNTmEx7o6H3mHn1rI2JS02uG3U/27Nn1EfHe\n0w+OiKqpc154wF6N1eURUV45/TN/fCq5T3f77TvXVERETdMerzjplCMP2LO2LFVVv/dedZUD\n93/27PqK6nkHz6iNiOqGOfvvv+fUqvKIqKjZ+Wv3tyX32ey3cPcl+0XEMbc8nnx750dflvxG\nZjTv85Kjj9p/7+ayVCoijr7wN/1HyfFJy+WX29f18Gt3a0iexjm77LtP846pVKq64YDPnb44\nIn65pnPQZyyXIXMZoGfDPS+dU//c0RftmEqlapte/NYd6wYePccnP18v5kx643lHz42IVHnt\nLs8/5JAXPC+5gtBB7/m/Ef10g9n6izZRoD9Bg9ryXbnZa3LQJ+13Jy6IiLc8tGbgxk/uPHXg\nL25UTxEAAACUhO0kjN5/7SERMWX++cPc54wd6yJinwvv6t+SpJlFr/31oPe/+2dXn/LSA3Zo\n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\npHFo61jBpgoOISIi01HV20p5eFshIiJU/bZS5v4VH0JEdYHBKBE1Anpd4bI5Wywf+78t704M\ncrUyrLdyfNRTZvbLyXRhUV0Q8U+eqlP/5hVsquAQIiIyEdW4rZSHtxUiIqrqbaW8/Ss4pN4e\nC5GpYVd6ImoECtN3RRaqx4bJz587Z1hpbt2qQ6jjzBeCZ+1Y9KvH7FAn9aGPPpB7PDba2xYA\nJLLyNpV7CBERmYbq3FbKU/7thoiITERVbyuFd7aWtz9vK0T1TKLX641dAxFRJe6cXDBx9ZVS\nK+195n/9UQ/otcd2bvj22D+ZCklA+0femD6hlc39j3zK21TBIUREZAKqeVsBAGhVyUNfmPTS\ntm9GusuLV/G2QkRk2qp6W6lof/C2QlSvGIwSERERERERERGRyeEYo0RERERERERERGRyGIwS\nERERERERERGRyWEwSkRERERERERERCaHwSgRERERERERERGZHAajREREREREREREZHIYjBIR\nEREREREREZHJYTBKREREREREREREJofBKBEREREREREREZkcBqNERERETcSvT7WQVGh/ZpGx\na6yR9QFOcpdBFeyg02TuWTvriR5t3BxtzS1tPALavTR50fm7ijqt6tuFr/i42bq2eq3MxZIu\nbXhCIpF4Pry2jMrVd3o4WJmZ2x9MK6zTaomIiIjIwNzYBRARERFR7Wjxwusz22YLX+vU6es2\n7pS7D500OsCwQ2trCyOVVh/UeRde6tLvYEyud/tHB7/S30JxNzry3HdbFh/csXtP5IXnW9iK\nOUl6+MJx71+at+v7h+xlYvYvuLP15WXftBwyc+0LAx5cLKX9//0wYn2zXSdmzT8zannPZiU3\nhS95JvyestPsX4Y0k4u5LhERERHVnESv1xu7BiIiIiKqZeqCizLbTu4dDqddrKiJZeOyPsBp\nQU6vwswfy9imV0/t7Pnh5YLZX/6+ckR3w+qbR5e1HfSOZYvXcuO2ibnErR8e8xty/PuMwudc\nrMXsn3FliFu7H5Yl3pvvY/fg4oNyore4h0yxcH36TuphOzOJsFKZ+6enW79Cm94J6b+7W7BH\nFxEREVE94RsvIiIiIvovvUqpqcJn53qtSluzj9p1mhxtjU6AlD/e3Hgxo/u7x0umogBaPbXg\nmwG+9+I/33A7v2ZXKJtepwNgKZWUufggx6BJe8cGFt49MmhdhGHlV6+MzlLrXv9+T+2mojV/\n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\nRK5CYII="
     },
     "metadata": {
      "image/png": {
       "height": 480,
       "width": 900
      }
     },
     "output_type": "display_data"
    }
   ],
   "source": [
    "options(repr.plot.width=15, repr.plot.height=8)\n",
    "train_sequences %>% mutate(cutoff_year = lubridate::year(ymd(temporal_cutoff)), sequence_length = str_count(sequence)) %>% \n",
    "    group_by(cutoff_year) %>% summarize(avg_sequence_length = mean(sequence_length)) %>% \n",
    "    ggplot(aes(x=cutoff_year, y=avg_sequence_length)) + geom_smooth(method = \"lm\", formula = y ~ poly(x, 3), se = FALSE) + geom_line() +\n",
    "    xlab(\"Temporal Cutoff Year\") + ylab(\"Average Sequence Length discovered\") + ggtitle(\"Average length of published sequence over time\") + theme_minimal()\n",
    "\n",
    "# The black line is actual sequence length and the blue line is smoothed.  Both show a gradual increase in published sequence length \n",
    "# since 2000, with significant published sequence lengths since 2014 timeframe."
   ]
  },
  {
   "cell_type": "markdown",
   "id": "1637ae41",
   "metadata": {
    "papermill": {
     "duration": 0.009917,
     "end_time": "2025-05-06T17:27:43.431206",
     "exception": false,
     "start_time": "2025-05-06T17:27:43.421289",
     "status": "completed"
    },
    "tags": []
   },
   "source": [
    "### Focussing on the target_id...from the competition material:\n",
    ">\"In train_sequences.csv, this is formatted as pdb_id_chain_id, where pdb_id is the id of the entry in the Protein Data Bank and chain_id is the chain id of the monomer in the pdb file"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "d458c570",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-03-02T22:06:18.772152Z",
     "iopub.status.busy": "2025-03-02T22:06:18.770555Z",
     "iopub.status.idle": "2025-03-02T22:06:18.78293Z",
     "shell.execute_reply": "2025-03-02T22:06:18.781167Z"
    },
    "papermill": {
     "duration": 0.009922,
     "end_time": "2025-05-06T17:27:43.451169",
     "exception": false,
     "start_time": "2025-05-06T17:27:43.441247",
     "status": "completed"
    },
    "tags": []
   },
   "source": [
    "#### Let's first look at how many unique pdb_id's and chain_id's there are in the train_sequences"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 7,
   "id": "15b6c11e",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-05-06T17:27:43.473796Z",
     "iopub.status.busy": "2025-05-06T17:27:43.472642Z",
     "iopub.status.idle": "2025-05-06T17:27:43.501972Z",
     "shell.execute_reply": "2025-05-06T17:27:43.500837Z"
    },
    "papermill": {
     "duration": 0.0425,
     "end_time": "2025-05-06T17:27:43.503577",
     "exception": false,
     "start_time": "2025-05-06T17:27:43.461077",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "[1] \"There are  735 unique pdb_id's in the dataset.\"\n"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "[1] \"There are  99 unique pdb_id's in the dataset.\"\n"
     ]
    }
   ],
   "source": [
    "pdb_id_count <- train_sequences %>% mutate(pdb_id = str_split(target_id, \"_\", simplify = TRUE)[ , 1], chain_id = str_split(target_id, \"_\", simplify = TRUE)[ , 2]) %>% \n",
    "    select(pdb_id) %>% unique() %>% count() %>% pull()\n",
    "\n",
    "chain_id_count <- train_sequences %>% mutate(pdb_id = str_split(target_id, \"_\", simplify = TRUE)[ , 1], chain_id = str_split(target_id, \"_\", simplify = TRUE)[ , 2]) %>% \n",
    "    select(chain_id) %>% unique() %>% count() %>% pull()\n",
    "\n",
    "print(paste(\"There are \",pdb_id_count,\"unique pdb_id's in the dataset.\"))\n",
    "print(paste(\"There are \",chain_id_count,\"unique pdb_id's in the dataset.\"))"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "408dff1e",
   "metadata": {
    "papermill": {
     "duration": 0.009936,
     "end_time": "2025-05-06T17:27:43.523627",
     "exception": false,
     "start_time": "2025-05-06T17:27:43.513691",
     "status": "completed"
    },
    "tags": []
   },
   "source": [
    "### Now let's look at which pdb_id's are repeated in the train_sequences"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 8,
   "id": "796419f5",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-05-06T17:27:43.546885Z",
     "iopub.status.busy": "2025-05-06T17:27:43.545646Z",
     "iopub.status.idle": "2025-05-06T17:27:43.579527Z",
     "shell.execute_reply": "2025-05-06T17:27:43.578306Z"
    },
    "papermill": {
     "duration": 0.047358,
     "end_time": "2025-05-06T17:27:43.581055",
     "exception": false,
     "start_time": "2025-05-06T17:27:43.533697",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "data": {
      "text/html": [
       "<table class=\"dataframe\">\n",
       "<caption>A tibble: 10 × 2</caption>\n",
       "<thead>\n",
       "\t<tr><th scope=col>pdb_id</th><th scope=col>total</th></tr>\n",
       "\t<tr><th scope=col>&lt;chr&gt;</th><th scope=col>&lt;int&gt;</th></tr>\n",
       "</thead>\n",
       "<tbody>\n",
       "\t<tr><td>4V5Z</td><td>11</td></tr>\n",
       "\t<tr><td>2OM7</td><td> 7</td></tr>\n",
       "\t<tr><td>1ZC8</td><td> 6</td></tr>\n",
       "\t<tr><td>2R1G</td><td> 6</td></tr>\n",
       "\t<tr><td>3DEG</td><td> 5</td></tr>\n",
       "\t<tr><td>4V6W</td><td> 5</td></tr>\n",
       "\t<tr><td>4V6X</td><td> 5</td></tr>\n",
       "\t<tr><td>4V7E</td><td> 5</td></tr>\n",
       "\t<tr><td>6ZVK</td><td> 5</td></tr>\n",
       "\t<tr><td>2NR0</td><td> 4</td></tr>\n",
       "</tbody>\n",
       "</table>\n"
      ],
      "text/latex": [
       "A tibble: 10 × 2\n",
       "\\begin{tabular}{ll}\n",
       " pdb\\_id & total\\\\\n",
       " <chr> & <int>\\\\\n",
       "\\hline\n",
       "\t 4V5Z & 11\\\\\n",
       "\t 2OM7 &  7\\\\\n",
       "\t 1ZC8 &  6\\\\\n",
       "\t 2R1G &  6\\\\\n",
       "\t 3DEG &  5\\\\\n",
       "\t 4V6W &  5\\\\\n",
       "\t 4V6X &  5\\\\\n",
       "\t 4V7E &  5\\\\\n",
       "\t 6ZVK &  5\\\\\n",
       "\t 2NR0 &  4\\\\\n",
       "\\end{tabular}\n"
      ],
      "text/markdown": [
       "\n",
       "A tibble: 10 × 2\n",
       "\n",
       "| pdb_id &lt;chr&gt; | total &lt;int&gt; |\n",
       "|---|---|\n",
       "| 4V5Z | 11 |\n",
       "| 2OM7 |  7 |\n",
       "| 1ZC8 |  6 |\n",
       "| 2R1G |  6 |\n",
       "| 3DEG |  5 |\n",
       "| 4V6W |  5 |\n",
       "| 4V6X |  5 |\n",
       "| 4V7E |  5 |\n",
       "| 6ZVK |  5 |\n",
       "| 2NR0 |  4 |\n",
       "\n"
      ],
      "text/plain": [
       "   pdb_id total\n",
       "1  4V5Z   11   \n",
       "2  2OM7    7   \n",
       "3  1ZC8    6   \n",
       "4  2R1G    6   \n",
       "5  3DEG    5   \n",
       "6  4V6W    5   \n",
       "7  4V6X    5   \n",
       "8  4V7E    5   \n",
       "9  6ZVK    5   \n",
       "10 2NR0    4   "
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    }
   ],
   "source": [
    "train_sequences %>% mutate(pdb_id = str_split(target_id, \"_\", simplify = TRUE)[ , 1], chain_id = str_split(target_id, \"_\", simplify = TRUE)[ , 2]) %>% \n",
    "    group_by(pdb_id) %>% summarize(total = n()) %>% filter(total > 1) %>% arrange(desc(total)) %>% head(10)\n",
    "\n",
    "# In total, there are 60 pdb_id's that are repeated in train_sequences, with the top 10 most repeated shown below"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "db0215e5",
   "metadata": {
    "papermill": {
     "duration": 0.010482,
     "end_time": "2025-05-06T17:27:43.602280",
     "exception": false,
     "start_time": "2025-05-06T17:27:43.591798",
     "status": "completed"
    },
    "tags": []
   },
   "source": [
    "### train_labels.csv"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 9,
   "id": "6e823a84",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-05-06T17:27:43.626670Z",
     "iopub.status.busy": "2025-05-06T17:27:43.625494Z",
     "iopub.status.idle": "2025-05-06T17:27:43.651634Z",
     "shell.execute_reply": "2025-05-06T17:27:43.650297Z"
    },
    "papermill": {
     "duration": 0.040201,
     "end_time": "2025-05-06T17:27:43.653214",
     "exception": false,
     "start_time": "2025-05-06T17:27:43.613013",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "[1] \"train_labels has 137095 rows and 6 columns\"\n"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "[1] \"train_labels has 18435 NAs.\"\n"
     ]
    },
    {
     "data": {
      "text/html": [
       "<table class=\"dataframe\">\n",
       "<caption>A data.frame: 3 × 6</caption>\n",
       "<thead>\n",
       "\t<tr><th></th><th scope=col>ID</th><th scope=col>resname</th><th scope=col>resid</th><th scope=col>x_1</th><th scope=col>y_1</th><th scope=col>z_1</th></tr>\n",
       "\t<tr><th></th><th scope=col>&lt;chr&gt;</th><th scope=col>&lt;chr&gt;</th><th scope=col>&lt;int&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th></tr>\n",
       "</thead>\n",
       "<tbody>\n",
       "\t<tr><th scope=row>1</th><td>1SCL_A_1</td><td>G</td><td>1</td><td>13.760</td><td>-25.974</td><td>0.102</td></tr>\n",
       "\t<tr><th scope=row>2</th><td>1SCL_A_2</td><td>G</td><td>2</td><td> 9.310</td><td>-29.638</td><td>2.669</td></tr>\n",
       "\t<tr><th scope=row>3</th><td>1SCL_A_3</td><td>G</td><td>3</td><td> 5.529</td><td>-27.813</td><td>5.878</td></tr>\n",
       "</tbody>\n",
       "</table>\n"
      ],
      "text/latex": [
       "A data.frame: 3 × 6\n",
       "\\begin{tabular}{r|llllll}\n",
       "  & ID & resname & resid & x\\_1 & y\\_1 & z\\_1\\\\\n",
       "  & <chr> & <chr> & <int> & <dbl> & <dbl> & <dbl>\\\\\n",
       "\\hline\n",
       "\t1 & 1SCL\\_A\\_1 & G & 1 & 13.760 & -25.974 & 0.102\\\\\n",
       "\t2 & 1SCL\\_A\\_2 & G & 2 &  9.310 & -29.638 & 2.669\\\\\n",
       "\t3 & 1SCL\\_A\\_3 & G & 3 &  5.529 & -27.813 & 5.878\\\\\n",
       "\\end{tabular}\n"
      ],
      "text/markdown": [
       "\n",
       "A data.frame: 3 × 6\n",
       "\n",
       "| <!--/--> | ID &lt;chr&gt; | resname &lt;chr&gt; | resid &lt;int&gt; | x_1 &lt;dbl&gt; | y_1 &lt;dbl&gt; | z_1 &lt;dbl&gt; |\n",
       "|---|---|---|---|---|---|---|\n",
       "| 1 | 1SCL_A_1 | G | 1 | 13.760 | -25.974 | 0.102 |\n",
       "| 2 | 1SCL_A_2 | G | 2 |  9.310 | -29.638 | 2.669 |\n",
       "| 3 | 1SCL_A_3 | G | 3 |  5.529 | -27.813 | 5.878 |\n",
       "\n"
      ],
      "text/plain": [
       "  ID       resname resid x_1    y_1     z_1  \n",
       "1 1SCL_A_1 G       1     13.760 -25.974 0.102\n",
       "2 1SCL_A_2 G       2      9.310 -29.638 2.669\n",
       "3 1SCL_A_3 G       3      5.529 -27.813 5.878"
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    }
   ],
   "source": [
    "print(paste('train_labels has', dim(train_labels)[1], 'rows and', dim(train_labels)[2], 'columns'))\n",
    "print(paste('train_labels has', sum(is.na(train_labels)), 'NAs.'))\n",
    "# Quick look at the data\n",
    "train_labels %>% head(3)"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 10,
   "id": "7e1de6cb",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-05-06T17:27:43.677680Z",
     "iopub.status.busy": "2025-05-06T17:27:43.676267Z",
     "iopub.status.idle": "2025-05-06T17:27:43.715457Z",
     "shell.execute_reply": "2025-05-06T17:27:43.712649Z"
    },
    "papermill": {
     "duration": 0.054258,
     "end_time": "2025-05-06T17:27:43.718220",
     "exception": false,
     "start_time": "2025-05-06T17:27:43.663962",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "data": {
      "text/html": [
       "<table class=\"dataframe\">\n",
       "<caption>A data.frame: 3 × 6</caption>\n",
       "<thead>\n",
       "\t<tr><th></th><th scope=col>ID</th><th scope=col>resname</th><th scope=col>resid</th><th scope=col>x_1</th><th scope=col>y_1</th><th scope=col>z_1</th></tr>\n",
       "\t<tr><th></th><th scope=col>&lt;chr&gt;</th><th scope=col>&lt;chr&gt;</th><th scope=col>&lt;int&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th></tr>\n",
       "</thead>\n",
       "<tbody>\n",
       "\t<tr><th scope=row>411</th><td>1ZDI_S_1</td><td>A</td><td>1</td><td>NA</td><td>NA</td><td>NA</td></tr>\n",
       "\t<tr><th scope=row>412</th><td>1ZDI_S_2</td><td>C</td><td>2</td><td>NA</td><td>NA</td><td>NA</td></tr>\n",
       "\t<tr><th scope=row>413</th><td>1ZDI_S_3</td><td>A</td><td>3</td><td>NA</td><td>NA</td><td>NA</td></tr>\n",
       "</tbody>\n",
       "</table>\n"
      ],
      "text/latex": [
       "A data.frame: 3 × 6\n",
       "\\begin{tabular}{r|llllll}\n",
       "  & ID & resname & resid & x\\_1 & y\\_1 & z\\_1\\\\\n",
       "  & <chr> & <chr> & <int> & <dbl> & <dbl> & <dbl>\\\\\n",
       "\\hline\n",
       "\t411 & 1ZDI\\_S\\_1 & A & 1 & NA & NA & NA\\\\\n",
       "\t412 & 1ZDI\\_S\\_2 & C & 2 & NA & NA & NA\\\\\n",
       "\t413 & 1ZDI\\_S\\_3 & A & 3 & NA & NA & NA\\\\\n",
       "\\end{tabular}\n"
      ],
      "text/markdown": [
       "\n",
       "A data.frame: 3 × 6\n",
       "\n",
       "| <!--/--> | ID &lt;chr&gt; | resname &lt;chr&gt; | resid &lt;int&gt; | x_1 &lt;dbl&gt; | y_1 &lt;dbl&gt; | z_1 &lt;dbl&gt; |\n",
       "|---|---|---|---|---|---|---|\n",
       "| 411 | 1ZDI_S_1 | A | 1 | NA | NA | NA |\n",
       "| 412 | 1ZDI_S_2 | C | 2 | NA | NA | NA |\n",
       "| 413 | 1ZDI_S_3 | A | 3 | NA | NA | NA |\n",
       "\n"
      ],
      "text/plain": [
       "    ID       resname resid x_1 y_1 z_1\n",
       "411 1ZDI_S_1 A       1     NA  NA  NA \n",
       "412 1ZDI_S_2 C       2     NA  NA  NA \n",
       "413 1ZDI_S_3 A       3     NA  NA  NA "
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    }
   ],
   "source": [
    "# There are a decent number of NAs in train_labels...here are a few:\n",
    "train_labels[rowSums(is.na(train_labels)) > 0,] %>% head(3)"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "2940bcda",
   "metadata": {
    "papermill": {
     "duration": 0.012529,
     "end_time": "2025-05-06T17:27:43.745399",
     "exception": false,
     "start_time": "2025-05-06T17:27:43.732870",
     "status": "completed"
    },
    "tags": []
   },
   "source": [
    "### Let's create a boxplot of the coordinate values for x, y, & z "
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 11,
   "id": "d2db505d",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-05-06T17:27:43.770901Z",
     "iopub.status.busy": "2025-05-06T17:27:43.769282Z",
     "iopub.status.idle": "2025-05-06T17:27:45.107270Z",
     "shell.execute_reply": "2025-05-06T17:27:45.105352Z"
    },
    "papermill": {
     "duration": 1.353242,
     "end_time": "2025-05-06T17:27:45.109524",
     "exception": false,
     "start_time": "2025-05-06T17:27:43.756282",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "Warning message:\n",
      "“\u001b[1m\u001b[22mRemoved 18435 rows containing non-finite outside the scale range\n",
      "(`stat_boxplot()`).”\n"
     ]
    },
    {
     "data": {
      "image/png": "iVBORw0KGgoAAAANSUhEUgAABwgAAAPACAIAAACuBbobAAAABmJLR0QA/wD/AP+gvaeTAAAg\nAElEQVR4nOzdd5xcZb0/8GfK9k0PoYQQBBLpvUkRJTaUrqgo9V5Er4KKchEUKRJUvFJUUMCr\nqPci6E+ko3JFighKRw29QyCQkO1tdmbO748Ja9jGZrPZ2TPn/f4jr+x5Zs75zjPPnPPsZ8+c\nk4qiKAAAAAAAJEm63AUAAAAAAIw3wSgAAAAAkDiCUQAAAAAgcQSjAAAAAEDiCEYBAAAAgMQR\njAIAAAAAiSMYBQAAAAASRzAKAAAAACROxQajbS+enRognamZPmvDBQd/+uoHl5WrsL+fs1Mq\nlVpw7XPlKqBzya1HL9hhZmP12lt8tVw1jNr5G09LpVI3NXWXfrz/lG1TqdQ+t79c3qrGQdmH\nzcomZrevuapG0fnHz56USqUe68qXZesAAADASGTLXcCalc40bPS2dft+zPd0vLz4hT9dfelt\n111+2k2Pn/6+2WWsbeSiYsdddz+Urdlglx3nrP7aTt/z4J891bzO9nu/b+d5q7+2SjW2fc6g\ndDIAAABQRhUejNZMedeTT96w8pJc8zP/9ZkPnvqrx7/54f1PbLmvIZ0qV20jl+96Yo899pi8\nwddbnv/G6q4ryn3v6Zaq+s2evveP9XF47cPb8JCzfrbp8tmbThvzNY9ln1ecser2se3kNTcY\nAAAAgIpU4cHoQNVTNzrlf++85Jp1X2x/4Ecvd5y4fmO5KxpXUbGrN4rq67eogFQ0hDBj+/2O\n3L7cRSTPxOz2iVkVAAAAMGFV7DVGh5HOzlwwtSaE8Hq+sIY2Ucx1F6I1tO5KF/W81lscixUV\nO7rH4AqPrKIx7XaDAQAAAFhjkhiMRvnlf2rpSaVrPjKzfqXFxdv/91v7v3PrtaY2VjdMeduW\nu3329B+/3LMiOe1pun392mxV7dy/tOb+9YTeV98zoy6drf/Jky0hhONnT6qq27i3bdEJB7xj\nSn1DVSY7be057z/0uFuebH2riobb9JWbzaxu3D6E0PrCWalUasbbLxvdekIIf9xnbjo7NYTQ\nuew3qVRq0uzjh+mj//vvMz6w62bTJ9U2TJ217bsPPu83963q5kb4mMcu2T2VSh33dHP78zd9\nfM/NG6vr/+e1zhBCsfe1H3/90zvNn9NYUzNzvY0O/tTX/tGce/PKw0Nn7rDy/Xae/Pk7U6nU\n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\nN+f2OeSRJyak5serLns/hLBhYW79yAaFOU+/vzgcvpKZY7HYggUr37M1hLBw4cJEnrG0tLTu\nxp1/eSEnJ7tJaQFIkg+nfRVCiMVi8+fPT3ypaDS64vz5+fnt27df6fw1NTWLFy9e6aR4PJ7g\nU5eXlyeeEICWVFNT06TPkerq6hXnLywsLCwsXOn8lZWV9d8mllNbW5vgU1dWtpaTrwGwnMrK\nyiZ9jlRUVFRUVCw32L59+/z8/GbN9YN27dp169YthLBkyZKqqqomLZufn9+hQ4cQQt1/E3HB\nb/vt8qdbw0nXfPP87xbn9h+/ebemBk6thIrReHTp3JrooEM2SXaahsSqykIIXXJ+PCNq19zs\n2tKW2FZ49IE3WuBZAAAA6u25556bb755qlNAM3j00UdnzJgxYMCA/fbbL9VZoHn06NEj1REa\nM3z48OHDh4cQzjjjjMmTJzdp2W233faqq65q0iIbnn5K6fhjX1x8+X9Of7H3fvcXZ6fB2QaW\nlVAxGsku/kVJwed3vRX26Z3kPCuXldcuhLCwNlac/cPOm/NrotkleSudORKJrLgTUG1tbV09\nX1xcnMjuyl27du3Tp8/PCt3cYrFYJBJJi/NZrCgW++FaWVlZTbveVytRdwaGNA0fQvjuu+/K\ny8sLCwvXWmutVGdZHWn9+tefviOtf39bW/iuXbs2tLPncqqqqqqrq7OysoqKlj+FTXZ2g0cD\nZGdnr/j41dXVVVVVkUikuLg4kaeu+/Nv5eKlz539p0TmB6AF1JSWhwbe51eqsrKypqYmJyen\nXbt2y03KyWnwm1Rubu6Kj1/3UCv9SFqpLbfcMpHZWkwsFisrK0vwy1QrVFpaGo/H8/Pz8/JW\n/i2ylauurq6trW1oJ+VWbsqUKTNmzOjateuee+6Zppv05eXlubm5ubm5q5619anbiE38zae1\nicfjpaWl6fvmU1ZWFovF8vLyVtw5NE3XqBUVrXXU3p1PPvOOh9/9eMGfnt461XGaLMFD6SP3\nP3nxZrv8ZtTFZX867fA1ixI9AL+55BYNCuGlGRW1vfJ/+B47s6K24/YlK505EomsuMJFIpG6\nYjQvLy+R9+KhQ4cOHTr056VuZgsXLiwsLEzSjtbJVlpaWllZmZub27Fjx1RnWR3RaHThwoVd\nunRJ0/fiU0455dVXX91iiy2uvvrqVGdZHRUVFTU1NYnvyd+q1NbWLlq0KITQqVOnRpq41mzR\n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\nSQAakZPqAEASTZ48+dxzz62srKy7O2TIkCuvvLKkpCS1qQBo/SKRSKojAJDG5s2b19Ckb775\npiWTADTCHqPQZt16661nnHFGfSsaQpg6deoee+yx7AgArJRiFICfIzc3dzUmAbQwxSi0TbFY\n7JZbbllxvKam5uSTT275PAAAQOYYMmRIQ5O23377lkwC0AjFKLRNTz75ZEOT3n333ZZMAkA6\n6tixY6ojAJDGzjzzzJUefBCJRMaOHdvyeQBWSjEKbdNTTz3V0CQXzQBglTp16tTQpOzs7JZM\nAkA66tat29lnn71cN5qVlfXHP/6xuLg4VakAluPiS9A2NXKycwBYpa5duzY0qaCgoCWTAJCm\n9ttvvx122GH8+PEffPBBdnb2pptuetpppzkiAWhVFKPQNtXW1qY6AgBpLCurweOK7DEKQIK6\ndu168cUXL1q0KITQqVMnnyBAa+NQemibli5dmuoIAKSxoqKihiY5JQsAAG2DYhTaJt9aAfg5\nlixZkuoIAACQXIpRaJsauWgGAKxSfn5+Q5McCAkAQNugGIW2qUOHDqmOAEAa22ijjRqatM46\n67RkEgAASBLFKLRN8+fPT3UEANLYAQcc0ND1l0aOHNnCYQAAIBkUo9A2tW/fPtURAEhjRUVF\np5566orjO+6447Bhw1o+DwAANDvFKLRNm266aUOTIpFISyYBIE0ddthh999///rrr19QUJCb\nm9u9e/dLL7306quvTnUuAABoHjmpDgAkxdprr93QJBesByBB/fr1mzhxYt3pWTp06JCXl5fq\nRAAA0GwUo9A2LV68ONURAACAjFZdXT1hwoS33norEolsvfXWxx13XG5ubqpDAfxIMQpt09Sp\nU1MdAQAAyFwvvPDCWWedFY1G6+5+9NFHEydOvO6667bccsvUBgOo5xyj0DZ9+eWXqY4AAABk\nqCVLlowbN66+Fa1TU1MzZsyYysrKVKUCWI5iFNqm7OzsVEcAAAAy1BVXXLHSaxvEYrHrr7++\n5fMArJRiFNqm9u3bpzoCAACQoV577bWGJk2ePLkFgwA0RjEKbVNRUVGqIwAAABlqyZIlDU1a\nsGBBSyYBaIRiFNqm6urqVEcAAABYXk1NTaojAPxAMQptU+fOnVMdAQAAAKD1UoxC2zR48OBU\nRwAAAFie68QCrYdiFNqmDh06NDQpEom0ZBIAACDTFBcXNzSppKSkJZMANEIxCm3Te++919Ck\n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\nPvqmz29Umak9d58x1yw8b/f9Xzpml8mT0g0v33Xd9cUltfMu7PPDTwEAIBuJTMZH1wMA5Jzu\njte+f/FFN93xy7++uKQlldxo0813mzbztLlf++hG734b+9Lf3PLVc7/7wJN/bexMTtjmo0f+\n9znnHL3n6neynh0WbFn7pWVT2uofXOP/ffKWC8/41vd//+yrieHjPjnr9Bu+sffwYdsc/o8V\nN2856sKJNRe1H9K09NoQwm1bjz56yVbtjb/uveHLd0+dOOOhny5vnVlbEUJoeW3hSSec+eDv\nn2kq2XiHHf9j9jcv26Xtup32nbekq+qlFUs36npm5u4zHvzz6yMnn73kz+eEEBqfu//00y+6\ne9HTKztLJ22xzayTzjzr2P16vs+p7a3fnn7q3LsX/m7JypaKkeN22G3al+d+Y8b2tQM/6AAA\nxIlgFAAAAACIHZ8xCgAAAADEjmAUAAAAAIgdwSgAAAAAEDuCUQAAAAAgdgSjAAAAAEDsCEYB\nAAAAgNgRjAIAAAAAsSMYBQAAAABiRzAKAAAAAMSOYBQAAAAAiB3BKAAAAAAQO4JRAAAAACB2\nBKMAAAAAQOz8PwDaaInhMTxnAAAAAElFTkSuQmCC"
     },
     "metadata": {
      "image/png": {
       "height": 480,
       "width": 900
      }
     },
     "output_type": "display_data"
    }
   ],
   "source": [
    "options(repr.plot.width=15, repr.plot.height=8)\n",
    "train_labels %>% select(x_1, y_1, z_1) %>% \n",
    "    pivot_longer(everything(), names_to = \"coordinate\", values_to = \"value\") %>% \n",
    "    ggplot(aes(x=value, fill = coordinate)) + geom_boxplot() + facet_grid(cols=vars(coordinate)) + \n",
    "    coord_flip() + scale_fill_brewer(palette = \"YlGnBu\") + \n",
    "    xlab(\"Coordinate Values\") + ylab(\"Coordinates\") + ggtitle(\"Boxplot of coordinate values in train_labels\") + theme_minimal()"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "2a45c5c4",
   "metadata": {
    "papermill": {
     "duration": 0.040934,
     "end_time": "2025-05-06T17:27:45.162467",
     "exception": false,
     "start_time": "2025-05-06T17:27:45.121533",
     "status": "completed"
    },
    "tags": []
   },
   "source": [
    "### Resname occurrences in train_labels"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 12,
   "id": "0aceb97c",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-05-06T17:27:45.188669Z",
     "iopub.status.busy": "2025-05-06T17:27:45.187480Z",
     "iopub.status.idle": "2025-05-06T17:27:45.466953Z",
     "shell.execute_reply": "2025-05-06T17:27:45.465103Z"
    },
    "papermill": {
     "duration": 0.294946,
     "end_time": "2025-05-06T17:27:45.469094",
     "exception": false,
     "start_time": "2025-05-06T17:27:45.174148",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "data": {
      "image/png": "iVBORw0KGgoAAAANSUhEUgAABwgAAAPACAIAAACuBbobAAAABmJLR0QA/wD/AP+gvaeTAAAg\nAElEQVR4nOzdZ2BUVd4H4DOZ9ELvCiIiIoodFMXeey8sqNgb+lqwl9XVVdfu2iu69u66ir27\n6trLKoqdFRFEQwJJyCSZeT8EMaaQIYQEvM/zKXPOvWf+Z+6dmeSXW2KpVCoAAAAAAERJRnsX\nAAAAAADQ1gSjAAAAAEDkCEYBAAAAgMgRjAIAAAAAkSMYBQAAAAAiRzAKAAAAAESOYBQAAAAA\niBzBKAAAAAAQOZEORmf/76+xBjLiOV169N98t8MeeX9mWxbz0d+GxWKxzf/5bVs+aT3lP754\nwOZrdyvM7rnKae1YBiysd09dIxaLbfvyD+1dyO8svqpa9nFx9DJFsVjss4rq9ioAAAAAliiZ\n7V1A+8uIFwxYvvf8h9WVZT9MnfLCIze+9NhdZ038/M9bLdOOtTUrlSx7/Y0PMnP6rbtO30Uf\n7c8b7nbbl7N6rbXZVsNXXPTRYKnTum8oAAAAYEkmGA05HTf54ovH67YkZn198eHbnXHf5+fv\nvtP4kncKMmLtVVuzqismjxw5skO/M0u++8uijpVKXPlVSVb+yl+9/Vz+EjxlaKj/nufeNviX\nZQZ3XsRxWvMN1XpVAQAAAIuDYLQR2Z0GnHrnazc82vt/c9677oey8csWtndFbSGVrKhKpfLz\nV5GKstTputaO+6/V3kU0sGRWBQAAANSK9DVGFyAjs9vmnXJCCD9X17R8lFTljKpkvbZkYm5N\nalFKW5I0NsFWkiyb2wpXQgwhpGrKKxKLsBH/AJraTC3ffK22ddpEq1bbavv80vUaAgAAwB+Q\nYLRxqepfXiipjGXk7NEt/7fGmpK7Lx2/+fAhXTsWZGbnde87aNvRxzz9Wcn8BT67YYNYLDbu\nq1lzvpu4z4ZDCrPz75hRHkI4epmirLwVqmZ/ctzOIzrmF2TFMzv37Lv1qHHPf1G6wCqSL995\nwU4brda9U2F2QcflV13/yD/f9EPlbxnfvSt3yy5cK4RQOuXcWCzWdaUJLR7quW2Xy8jsFEIo\nn/lgLBYrWuboRkdpaoIhhO9eu3vsLpss06NzTn6nFYcOO/Kc678sr5/7/PLfJ44Ztc3A3l1z\nsrI7dl12wx0OuPc/P87v/eL2jWKx2EFfFL9zx+mrLtupMC8rM6dg+dU2POOGZ+uN0+yGmDfU\n5zNuPnm3HoUd83MyCzv32HDXw9+aOTeEmolXjR+xcr/CnKwO3ZbbduxpXzS4F006c2nBixxC\nCKnqZ28+e5v1Vu5SlFvQqccam+522YPv1B9mgcu8ccSQWCy2+6Sf670gsVisoPuetQ+b2kyL\nsvnS3TrpTDCNp1vwrtLQB+esXfc2R+nvS3U1+oZawIvW7H7YKlWlqdliflsylXzq6lM2HNK/\nKDe7c49lN9/j0Mc/+rneMi14CyzsJgMAAID2l4qw0innhRDyumxfrz0x+7sLR68cQlh5v7vn\nNyarSw8Z3iOEkJHZafV1Rmy8/rD+nXNCCPHs3o/9VF67zKTr1w8hHPze02t0yM7rOWiL7Xb8\n588VqVRqXJ/CeHbv/QZ1CiFk5ndffc3BhZkZIYR4do+r3ppRu+6HF64TQtjs0W/mP+OV+64e\nQojFYj0HDN1oxDqds+IhhI4Dd/qkrKp2gQ8u+8tJJxwQQsjpsMEpp5zyl0vfaWqmzQ71xa0X\nnnLSsSGErPyVTjnllD+f/89Gx2lqgm9cvl88FovFYj37D9lg3dW7FWSGEAqW2ez56eXz1/3p\n3cs6ZWaEELoMWGXkxiOH9O8YQsiIF/79019qF5h824YhhM0vGRuLxQp6D9x8x51HrtW/di/d\n4cqPF2pD1A41eJeVQgjLr77Bzttt1jcvM4RQ0Hvnqw5cI5aRteq6m++4xQaF8YwQQs8RF9Sd\nYzpzadmLnEpVX7Dn4NpZr7nehsOGrpgZi4UQNhr/cJ1hmlnm9cNXDiHs9unMuk+drJ4VQsjv\ntseCN9OibL70tk46E2z+6ZrdVRp6/+y1QgjbvDR1Yaqtr9E3VFMvWjr7YatU1ah6HxfpFJNK\npcb1KQwh/PWQNUMIWYU911hzpYLMjBBCRmaHc5/5Pv0N1LCAFmwyAAAAaHeC0ZARLxxcx4oD\n+uZlxEIIWx539ezq5PyFp764ZwihqN8en/0yt7YlWT37hgMGhRCGjn+rtqU2Q+mxfOFmp95d\nXvPburV5RCyWMfaKiZXJVCqVqqmced249UMIOR1H/lKVTDUIGr55aEwIIafjsH9+NC8CS8ye\nfPwmvUMIy+1w+/yRE3PeCyF06HfmAqaZ5lD1wrVGNTrBkq+vzcmIZRcOvfG5L2tbaqpmXjdu\nvRBCx4GH1vy67vjlOoQQ9r3p9V8bav51+rohhB5r3Vz7uDY2CiFscPw/Kn5d7ZW/7xRCyOu6\n4/wa0tkQtUPFYlkn3/l2bUvFjDf652aGEOJZ3a974bvaxp/evTYrFovF4t/MrV6oubTsRf7s\nxp1CCB0H7vn2rwHT9PceGpCbGYvFb/1hTprLpB+MNtwPF2XzpbN10plgOk/X7K7SUKMRZLP7\nUkMN31BNvZjp7IetVVVD9T4u0ikm9dsHUfyQq59JzPsg+umao0aEELLyV54ytzqV9v5Qr4AW\nbDIAAABod4LRJuV2W+Xcez+av/CXdxy7yy67nPrc1LojzPp6fAih3zbP1j6szVDyu+9dL0Gr\nzSP6bnPr75trxg3oGELY+/nvUw2ChoP7FIYQjvv3j3VXqCqf1CcnHsvI/WBOorYlnWA0zaHS\nD0brTXDCyN4hhCNf+uF3iyar9u1ZEEK4ftq8RGzFvKwQwhcV8w+fTCXmvH/22Weff8mjtQ9r\nY6P8brslknXHmdslKyOe02d+QzobonaoPhvdXneZB9bqEUJY5ZjX6jbu17MghPDkLxULNZeG\n0nmRN++UG4vF7p76u0E+OH/tEMLwy+YdMNjsMukHow33w0XZfOlsnXQmmM7TNburNNRoBNns\nvtRQU8Fowxcznf2wtapqqN7HRTrFpH79IFpupzt/P9i8D6JtH/o6lfb+UK+AFmwyAAAAaHeu\nMdrIqfSl07995vZzOpZ+dtaoNU99aVrtYiuMufyRRx45f/M+81esLJ7y4N+fajhgv52PafRl\n3fWKXX7fkDH+iuEhhDcvm1RvyZq530yYVpaZt8JFI3rWbc/MG3zJ0G6p5NxLv2zk0oGNasWh\n5vv9BJN/eeeneFa3yzbq/buFYplH7dk/hHDPy/OuM7hrn4IQwpa7HTvxjU8TqRBCyCpY489/\n/vOpJ+xcd73l9hifFas7Tk6vrHhI/Xa/qoXYEHusU/dh134FIYShhw2u27hSXmYI4deb6aQ7\nl3rSeZHn/vL487Pm5vcYM6pPQd1lho5/6ttvv31k3xVDCOksk76m9sOWbb5aC9g66RWf1tOl\nuas0q9l9KX0NX8z098PFV1XLitnrku1/3zDvg+jDKz5t8VugtTYZAAAAtKXM9i5gSVTUY7kt\n9zvr5apXBx/83DX7XXzBlMtq26vLv73rpjte/s/7X3z59bffffv9jMYjxc5rd260faee+fVa\nuqyxaQjPln7+WQhb1G1PzH6zJpUq7LxtZqzeGmHFzXqGd6Z/98mssHq3dObSikPNV3eCNXO/\n+WZudQgzczMaPEEIIYTST+fdYOrM5//x7pb7Pf/kNds/eU1WYY81h607cuNNd9l7/w0Hd6m7\nfKehnZotIM0NkZHdSDCYn9XkPwPSn0s96bzIlUUvhBDyuu1Uv8isbsstN+/1r5zV/DLpa2o/\nbNnmq7WArZNO8Wk+XZq7SrPS2ZfS1OiLmeZ+uPiqalkxuzTxQVQ+9bOauYNb9hZorU0GAAAA\nbUkw2qTldjshHPxc2bRbQrgshPDzezcP3/jIr+dUdVtx7U3WG77RDqMGDhqy6oCXhq97Wb0V\nM/Maf1UbRg2xjOwQQiqZaLBsk4ePxeKxEEIykWxqgcU51Dx1J5hKVYUQMnP7jz92n0YX7rVu\n99ofCpfb8bnPp7/9zEOPTXz2lddef/uVx9968V+Xn3PSjqc8+M/zfzusrLaqBUh/Qyys9OfS\ncNWmxpz/IqeSc0MIsfiC3nHpLNPUmg3bmtoPW7b5ai1g66Q1wfSeLs1dpVnN7kvpa/hitng/\nbMWqWlZMrIkPolhGXovfAq21yQAAAKAtCUablBEvDOG3yOmo7Y79ek7VcXe/fdmo307QLv32\nP+kP+K/p5Zt2zKnbMuvTF0MIBX0H11syu2jdeCw2t/ipmhDiv+/6+qXpIYQ+q6Z70FkrDtWo\nzNwVumfFf0mWn3/BBc3nPbHsYVuPGrb1qBBCTcWM5x+8ecxBZ/3rwl3vPq7sT93z0nzGRd8Q\nTVm4udSRzouc3WG9EK6rmPl8CL+7okJ1xWf3PfxuTocRe+w4IJ1lGi2gquKLhan3Ny2eckPp\nFL8QT9cau8pitfj2w8VdzGMzKkYUZddtKf7kxRBCx1UGL9L+sMRvMgAAAKjHNUab9NPb14UQ\n8rrtGkJI1ZTcP6M8M6df3dwhhFA6+dP0B3z4hMd/35C66pjXQwhrnbBKvSXjuSvs1zO/uuLL\nk9+cXre9umLy8e/NjGVkn7BS42dJN9SKQzUulnXySp1qEjNO/8+M33ckx62+Qu/evf/589wQ\nQvmMO1dcccXV1jv+t8Lyemy172l/X7FzKpV6tnhums/WKhuiSenNpaF0XuT87qNWLcgqm3b9\nEzMr6i7z9T2HjRkz5tR7vw8hpLNMrbLpv6tk6jPnt2C6IbR8yg2lVXwaT9dau8pitXj3w8Vc\nzH0n1bv2aPKKo/8dQtjkxCEt2x+Wik0GAAAADQlGG/f9Ow/tuttDIYTVjh8fQojFi5bPjdck\n/nfrJ8Xzl3n7wcu22PXxEEJNRXU6Y0554oDDrnu+JoQQQqq65Nbxm1/0WXF24Zo3bdO34cJn\nXrljCOHqbXeeOGlWbUt12den7rDp95XVfbe5fnhRVt2FUzWNX/ivBUO1wH4TDg8hXLrFlve+\nNe3XembfMX7zaz76urLDXjt3zQ0h5HbeatZ33/z3rb+f9c//zl9x5ieP//mbklgsc78GFz1s\nSqtsiEWcS6Oaf5FjWbefPDyVqt5vk8M+/rmydpniT57Y6eg3YrHYkeetEUJIZ5naK1T+57Cz\np1fNO5a5+NNHd9x/YttPub50JpjG07XWrrIoFvyGCot/P1woC1vMt4+MHnfTy7V7T7K6+MZj\nN75s8qy87ttcPaJnaNH+sCRsMgAAAGiJxX/j+yVX6ZTzQggZ8cLBv7dMl3knfnYZuu8vVcna\nhV8/a+MQQka8YORWO+61yzarD+qZES8cdfIpIYR4du+xRxxVXpOcdP36IYQNb5tc74nG9SkM\nIRwzdv0QQnbHZdYZPrRzTjyEEM/qeulrP9Yu8+GF64QQNnv0m19XSl42emgIIRaLL7vSWhsN\nG1KYmRFC6Dhw50nlVfNHrqmamZMRi8Wytt59n4PGPdfERNMaKlk9K4SQ322PBbxiTU3wkZO2\nrH3F+q82fPNNN1ihW24IIafjmhN/LJu/zBvnbFW7TI+Bq2+2xebDVhuYEYuFELY45enaBSbf\ntmEIYf3rJ9UbfEh+Vjy79/yH6WyIRod6YZflQwgHTv6lbuNf+3cMITzxS8VCzaUxzb/IyZqy\n8Vv0DSHE4nmD1thgg7VXqb3FzYij7/9tlOaWqSz5d//czBBCbrch2+2656bDV83LiGUXrja0\nIGv+tmtqMy3K5ktn66QzwXSertldpaH3z14rhLDNS1PTr7ZRDd9QTb1o6eyHrVVVQ/U+LtIp\nJpVKjetTmJnTb/0eeSGEnE7LDBu2asfseAghM7f/7Z8Wzx88nf2hXgEt2GQAAADQ7gSjjYhn\n5/ceuOYBp149LVFTZ/Gax688ecQq/fKy44Wde6y//ZhHP/o5lUpdvf/GHXMzC7r2La1uJhh9\nb07i1RtOGjG4b0F2ZodufTbf8/AnP/ktjGgQjKZSqZrnbz9v+w1W7VKUl5lb1G/l9Q4/64ap\nlTX1Bn/5wkOW69ExIzN70Mb3p5rU/FCLEoymUqn3H7tmzy2Hd+9cmJmV23PAan/6v79+Mquy\n3jL/vuuinTZcq3vHgnhGZlGXPutvtc81j74/vzft2Kj5DbEowWiac2lMGi9yTfnDV560yRoD\nOuRl5RR0XHX9bS78xyv1Rml2meJP/3XADuv36DAvvi/su+E9nxTv0S2/xcFoOlNOc+ukM8F0\nnm7Bu0ojA7ZeBFnvDdX0i9b8fthmwWg6xaRSqXF9CnM6bFA158tLjt9vtf698rKyOvdcbof9\nTvj3/+bUG7/ZDdTw82phNxkAAAC0u1gq1eQNtWktRy9TdPUPc96bk1izYFHPW4f5qst+/mZq\n+YBBfePNLwsAAADA77grPSytMgu6rjioa3tXAQAAALBUEowCLBGqSn78YVZlOksut9xyi7sY\nAAAA+MMTjAIsET65Yvs1z34vnSVdAgUAAAAWnWuMtoU37vnHp+VVu+x/QNfMjPauBQAAAAAQ\njAIAAAAA0eMARgAAAAAgcgSjAAAAAEDkCEYBAAAAgMgRjAIAAAAAkSMYBQAAAAAiRzAKAAAA\nAESOYBQAAAAAiBzBKAAAAAAQOZntXQAsXtXV1WVlZSGEDh06xGKx9i4HlhplZWXV1dXZ2dl5\neXntXQssNWpqaubMmRNCKCoqysjw72dIV3l5eVVVVVZWVn5+fnvXAkuNZDI5e/bsEEJhYWE8\nHm/vcmCpUVFRkUgkMjMzCwoK2rsW2p9glD+4ZDJZVVUVQkilUoJRSF91dXVVVZVfsmGhpFKp\n+V867V0LLE1qv3T8OwEWii8daJnaL532roIlhV8+AAAAAIDIEYwCAAAAAJEjGAUAAAAAIkcw\nCgAAAABEjmAUAAAAAIgcwSgAAAAAEDmCUQAAAAAgcgSjAAAAAEDkCEYBAAAAgMgRjAIAAAAA\nkSMYBQAAAAAiRzAKAAAAAESOYBQAAAAAiBzBKAAAAAAQOYJRAAAAACByBKMAAAAAQOQIRgEA\nAACAyBGMAgAAALA0uXX0BkPXPbqp3jfPPGL8LV8sYPU7D9m6/uqpRFFmPPZ7GfH8+f3VFV9d\nMG7fdVdZLrew82qb7PaP135Y5EnQ/jLbuwAAAAAASNd3jxxx0N2v53fr02hvTeL7sZfdkrHf\nfpcctGKjC/zviRPHPfCf/G596zZWlrw8pybZa6OdNunzWxgay8iq/SFVM3vM6mvf/9Xc7cce\nftKOqYkTbjpgk5V+fu+741br0kpzon0IRgEAAABYOlTOenXTP93caFcyUfrpu/++7oyDPy+v\nWrmp1Ute3+WwOxu2z/1lYghhuxsn3LJSI1nnF7ftcd8XJbvf+smDBwwJIZxx6r6r9B7x5x1P\nOe67G1s6D5YITqUHAAAAYGmQqjpt092K++2/a7e8ej3VFZNz8zoNXX+7a19o+iT3VNU5248u\nWXbvHbrm1usp/vCjEML2DYatdfNf3swqWOWO/YfUPszuuM4tfxo4e8pND82saPFUWBIIRgEA\nAABYCrx10bZXfhL7x8t/L8ion2jFc5Z98plnn3vuuace+/sCVr9uUuyaxy5ouPq0p6fFMnI2\nz/v5sfv/ceXlV9356Iu/VCfn9aUSN/4wp0P/8Xl1VhpyzLAQwoRPi1tjWrQbp9IDAAAAsKQr\n+XLCZqe/uNM1H+3YK//+Br2xjPzNN988hJCYnd9w3fmrb3fpG1v3yPtXg96vXvsplpEzvM8K\nk0sStS15Pda8buKz+6/dNTH7rZLq5IprrVB3+bweG4Zwx7QXZ4SNGr/UKUsFR4wCAAAAsERL\nVs0Ys+HRReud+dBhqyzK6nce2PjVR5/+qSJVM3uV/5vwfXHZnBnfPXnjiYXFHx2y8cZfVFTX\nVE4NIeQv87u8NZ69TAihYppT6ZdujhgFAAAAYIn2wOGbPF267L+fPC22qKtXNrrAIbc/sG/O\nClttOiiEEEK/bQ656NX4h4MPeubge79+aodUCCE09sTJqmQjrSw9HDEKAAAAwJJr+htnjJrw\n2eH3PzusKHsxrb7RNtv+morOs/ye54YQvrj5q3jOMiGEudPm1u2tSUwNIeT1bvxmTSwtBKMA\nAAAALLmmv/J0KpW6aod+sV/dOaOsfOaDsVissOe+C7V6hw4dunfvft9P5c2unpk3MISQrKzO\nLlq3Q2bGz+98Ubd37s+vhxB6bdpjkSdHe3IqPQAAAABLrl4jDz377B3qtjx88fmTUgNPP2mv\n7ILVFmr1ysrKmpqaJ66+YnL4bfWyH2/YZMebVx1/34S9B8xfa+7Pj4QQem+3TIhlH9mn8JIv\nz6lIjp1/Y/qvbnknhDB2ta6tM0PaSSyVSrV3DbAYJRKJ0tLSEEKXLl0yMhwiDekqKSmpqqrK\nzc0tLCxs71pgqVFdXT1r1qwQQufOnePxeHuXA0uN0tLSRCKRk5NTVFTU3rXAUqOmpqa4uDiE\n0KlTp8xMxzwROfv2LHw4uW3ZTw807ErMfiOnw/orH/76p9eNaNg7e/bsysrKcUOW+1dqu/mr\nJ6t+Wr6oz4yCTT6e+tTA3HgIIVUz5+Idh5zy1LT7ppfu2T1v8oStVzrwmdG3f3bnfiuFEGoq\nv1uv+6DPO44u/d+ti3OWLHY+PQEAAACIroys7k/9fcwqh9++ev/hB+67XedQ/MaTdz/3SfE2\nZz2/Z/e8EMKK+967z3n97zloRPzdozcYVPSva89/tzx++csXt3fhLCrBKAAAAACRtvKhEz7p\nu+4Zl9x0z42XlVZlDlhtxEX3nHPiPuvW9sYyO//jo7cGjDvh9rsuv6c8NnDNTW58/pqD13Qe\n/VLPqfT8wTmVHlrGqfTQAk6lh5ZxKj20gFPpoWVqT6XPysrq2LFje9dC+5MTAQAAAACRIxgF\nAAAAACJHMAoAAAAARI5gFAAAAACIHMEoAAAAABA5bl0HAAAA0D7GPTKpvUuIrB/au4BouXrX\nldu7hEY4YhQAAAAAiBzBKAAAAAAQOYJRAAAAACByBKMAAAAAQOQIRgEAAACAyBGMAgAAAACR\nIxgFAAAAACJHMAoAAAAARI5gFAAAAACIHMEoAAAAABA5glEAAAAAIHIEowAAAABA5AhGAQAA\nAIDIEYwCAAAAAJEjGAUAAAAAIkcwCgAAAABEjmAUAAAAAIgcwSgAAAAAEDmCUQAAAAAgcgSj\nAAAAAEDkCEYBAAAAgMhph2B07qzi8mSq7Z8XAAAAAKBWZhs/39yf3zjo4As3uu7uw3oVhBBC\nSL5077X/euW9/82OD151+NijDxiQP7+kproWth0AAAAA4Hfa9IjRVLLi2lOunF3z2+GiXz90\nxuX3vbHebof8+dj9Cr96/vTjbkg217Ww7QAAAAAA9bRpMPr+bae/33GT3x6nEpfdN2mFUX/Z\nc4sRq6y94f9dNK5s2tN3TS1bUNfCtgMAAAAANNB2J5uXfPnw+U/NPf+W3cePnljbUlnyypS5\nNUdsuUztw5xOI9csvOLdl37cd/QKTXXttf03C9W+7+gVGi0mmUwmk44ojYSampraH6qrqzMy\n3G0M0pVKpUIIyWSyurq6vWuBpcb8L52ampraNxGQjtr3SyqV8qUD6Zv/J+38bx+AJVl7fcvH\nYrF4PN5UbxsFo8nEtL+eedc2J9+wYv5vpSTKPgohDMnPmt+ycn7mUx+VhNFNdiU2Wbj2MLrx\nehKJxJw5c1ppciwdSktL27sEWPokEolEItHeVcDSx5cOtIAvHWiZ2bNnt3cJAM2bNWtWuzxv\nPB7v3LlzU71tdADdkxedOWutow5eu1vdxmRlWQiha+ZvNXTLilfPmbuAroVtX0zTAQAAAACW\nam1xxOiMN6+ZMKnX9bdtUq89IzsvhFBcnSz89YjWn6tq4p2yF9C1sO1NlZSdnd2pU6dWmyFL\nsKqqqrKyshBChw4dnEoP6ZszZ051dXV2dnZ+fn571wJLjZqamtrDdnzpwEIpKyurqqrypQML\nJZlM1p6gUFRUtICzRFka/NTeBUBbaK8gLhaLLaC3LYLRn179KDF72oG77zK/5YlDRz1bsPqd\n144M4ZXPK6r75sz7EP+iorrjyE4hhKyCoY12LWx7UyVlZGT4cyUi5l95JzMz00aH9NV+eWRk\nZGRmtt3VqOEPIx6P+xsV0lf7pROLxXzpQPrmX1o0Ho977wBLviXzk6otcqIV9jvtsl9desnZ\nIYQNTv/rRecfkdtp0z7Z8adfm1G7WFXZB2/NTqy1Ra8QQlNdC9veBrMDAAAAAJY6bRHW5vZc\nbmDPeT+naopDCJ2WGzCgV0EIYfweg0+87eznep+0Sueqx665NL/35vstWxhCCLHsproWth0A\nAAAAoJ52Pop14N7nHVl5xb2Xn/Xz3NgKq2983l8OyWiua2HbAQAAAADqiaVSqfauARajRCJR\ne0nyLl26uMYopK+kpKSqqio3N7ew0NH3kK7q6upZs2aFEDp37uwao5C+0tLSRCKRk5NTVFTU\n3rXAUqOmpqa4uDiE0KlTpyXzyn2kadwjk9q7BGgLV++6cnuX0Ag5EQAAAAAQOYJRAAAAACBy\nBKMAAAAAQOQIRgEAAACAyBGMAgAAAACRIxgFAAAAACJHMAoAAAAARI5gFAAAAACIHMEoAAAA\nABA5glEAAAAAIHIEowAAAABA5AhGAQAAAIDIEYwCAAAAAJEjGAUAAAAAIkcwCgAAAABEjmAU\nAAAAAIgcwSgAAAAAEDmCUQAAAAAgcgSjAAAAAEDkCEYBAAAAgMgRjAIAAAAAkSMYBQAAAAAi\nRzAKAAAAAESOYBQAAAAAiBzBKAAAAAAQOYJRAAAAACByBKMAAAAAQOQIRgEAAACAyBGMAgAA\nAACRIxgFAAAAACJHMAoAAAAARI5gFAAAAACIHMEoAAAAABA5glEAAAAAIHIEowAAAABA5AhG\nAQAAAIDIEYwCAAAAAJEjGAUAAAAAIkcwCgAAAABEjmAUAAAAAIgcwSgAAFegAwUAACAASURB\nVAAAEDmCUQAAAAAgcgSjAAAAAEDkCEYBAAAAgMgRjAIAAAAAkSMYBQAAAAAiRzAKAAAAAESO\nYBQAAAAAiBzBKAAAAAAQOYJRAAAAACByBKMAAAAAQOQIRgEAAACAyBGMAgAAAACRIxgFAAAA\nACJHMAoAAAAARI5gFAAAAACIHMEoAAAAABA5glEAAAAAIHIEowAAAABA5AhGAQAAAIDIEYwC\nAAAAAJEjGAUAAAAAIkcwCgAAAABEjmAUAAAAAIgcwSgAAAAAEDmCUQAAAAAgcgSjAAAAAEDk\nCEYBAAAAgMgRjAIAAAAAkSMYBQAAAAAiRzAKAAAAAESOYBQAAAAAiBzBKAAAAAAQOYJRAAAA\nACByBKMAAAAAQOQIRgEAAACAyBGMAgAAAACRIxgFAAAAACJHMAoAAAAARI5gFAAAAACIHMEo\nAAAAABA5glEAAAAAIHIEowAAAABA5AhGAQAAAIDIEYwCAAAAAJEjGAUAAAAAIkcwCgAAAABE\nTmZ7F9A+Kisry8vL27sK2kIqlar9YdasWbFYrH2LgaVIMpkMIVRWVlZVVbV3LbD0KSkp8aUD\n6av90kkkEsXFxe1dC7SRr5+79czLb3vjoy/KqjP7DV5zz4NOOmnMyDR7QwizJj115rlXPf3G\nh6VV2Sussf4hJ/517MbLpbN65axnew/Yu9GS8rvv9f3n1y+GuQKEEEJ7fctnZGR07Nixqd6I\nBqOZmZn5+fntXQVtobq6uqKiIoSQn5/vb1RIX3l5eU1NTWZmZm5ubnvXAkuNZDJZVlYWQsjL\ny8vIcF4OpKuioqK6utqXDtHx4ytnr7f337K6rjbm0ON7xme//ODtFx6z03slrz924lrN9oYQ\nfvn4xmGbHFcS77PrPmOXyS596aEHT9h9+C8TJ5+xSe9mV89K9d9rr73qF5SqeuShRwv7r+XP\nZGDxaa9PmAVnQbH5x9PBH1IikSgtLQ0hdOnSxd+okL6SkpKqqqrc3NzCwsL2rgWWGtXV1bNm\nzQohdO7cOR6Pt3c5sNQoLS1NJBI5OTlFRUXtXQu0hSOW7XDLrP4fTH93SEFWCCFZNX3LHv1f\nmdurtOzrvIzYgntDCH/qXXj/L0VPfP752oWJEEJB5oy9Bw97tmpkycyns2PNDN5oPf+9dvs1\njv/wmR++3KyLf060g3GPTGrvEqAtXL3ryu1dQiPkRAAAANBGklXTb/phTo9hF9QGlyGEjKye\np4/sVT3329dLEwvuDSFUzHzwnh/LBo65d4u+BbULZBUOuvqWTef+8sxFU0qbXb2hypJXtjju\n6W2ueEYqCkRQRE+lBwAAgPaQccuECR0HDqvb9FNxZSwje8W8zOZ6Q2XJqyGEXlssW3eBzqtv\nGMITT7/w42ljOi949YZu2P1P5b32ffiwIa0yN4Cli2AUAAAA2khGVvf999+/9ufykl9+njnt\nzYm3HvDmjyuNurNfTjyEBfeGzLwVQggz3/gp7NV//pjlUz8KIcx8fWbGAYMWvHo9v3x8/v89\nP/Ws9y7OdjsGIJIEowAAANAODhvU784ZZSGEniOOevP2Uen0FvQ6ePXCEz+9ZexHZ7/fN4QQ\nQjLxw+ljJoYQKn+am/7gtc7c5aLOK51yzprdWnVaAEsNwSgAAAC0g2NuvWub6T9MeueZS2+4\ndpUtsz9/7tKCOvdHarQ3lpH/8M0HDRp1/YgV1t17r827Zsx6/bEHPiscEsLb8d+fLL/gwUMI\nMz847dqvS457+/g2mi3Aksdd6fmDc1d6aBl3pYcWcFd6aBl3pYcPrtxozWNf/dOLU+/apE86\nvZ89dtWJl9/5zvsfzs7ovMkuR1//1wF9+4waOv6tjy4els7qtS5bs8fp3w6d/cvzmc6jb1fu\nSk9EuCs9AAAARFr5j8/dfvvt//79PeIHjToshPDx41MX3Du/ZfBORz/63Osff/n9t5M/fvTG\nk/JnvRhC6LN17zRXDyFUlrx88oczBx95sVQUiDLBKAAAALSRRNk/x44de/qT/6vbWFM5JYSQ\n0zVnwb21D++4+abb7vlv3QU+vOTlEMLxa3dPZ/VaX91xanUqNe7olVprXgBLI8EoAAAAtJGi\nZU/qnhV/94QzZlX/el27VNXt424IIYwavfyCe2sbJv/tpEMO2PY/JfMOCy374ekxd33Zfe3z\ntuqck87qtR6+fFJ24RoH9ipYvLMFWLK5+RIAAAC0kXhO38fP22Ldk+/tN2jaoWM2K6oqfuup\nuyZ+8NOq+918fL+iEIoW2BtCCMfef9ql65y8xcojxozaKvbT588++uTMrJUmPnl8GoPPk6ya\nefGU0s5rnOw0eiDi3HyJPzg3X4KWcfMlaAE3X4KWcfMlIujft5977jV3vjVpypyarOWHrL3X\nQePPOWL7jPR6Qwjfv3bXuJMvfu2jSYmcbhtsu9c5l54/vEdemoOHEIonH99lpcvXvfy/bx67\nShtMlgVz8yUiYsm8+ZJglD84wSi0jGAUWkAwCi0jGIUWqKmpKS4uDiF06tQpM9PJoEsxwSgR\nsWQGo3IiAAAAACByBKMAAAAAQOQIRgEAAACAyBGMAgAAAACRIxgFAAAAACLHresAAABoBRPe\nntLeJURTeXsXEDkHDOvX3iUArcMRowAAAABA5AhGAQAAAIDIEYwCAAAAAJEjGAUAAAAAIkcw\nCgAAAABEjmAUAAAAAIgcwSgAANBCXz553c4brdGlKC87r2jQ2pv+5ZaX6vbO/uaFo0Zt3a9X\n1+ysvF4DVj/iwntm16R+604lijLjsVisY8eO3bt379ChQywWy4jnp7v67906eoOh6x7d+jME\nAP64Mtu7AAAAYKk07aUzVt7+/Kxuq+9/+Pie8dkv3X/rnw/e9I2f3nnylLVDCOXTn1htyC5T\nqgt23H/smr0z33vunutP/dPDj/5n6htXZMZCCKGy5OU5NcleG+20QfesZDIZj8czMzNjGVm1\ngze7el3fPXLEQXe/nt+tT5vOHwBYyglGAQCAlvjLmL/H8ld955u3hhRkhRCS5566ZY/+z52z\nR8VJX+dlxO7b/ZDvKlMXvvrZSRv0CiGEc/92096DDr3/yoNfO/m2DXuHEOb+MjGEsN2NEy7v\nnZlIJHJycoqKiuYP3uzq81XOenXTP93cdtMGAP4onEoPAAAstGTV9Jt+mNNj2AW1qWgIISOr\n5+kje1XP/fb10kQI4fIPZhb0PmJerBlCCPF9r7sqhPDKpZNqHxd/+FEIYftueY2O3+zq86Sq\nTtt0t+J+++/axDgAAE1xxCgAANACGbdMmNBx4LC6TT8VV8YyslfMywzJimS/gWuutsfvVsjq\nFkKomlNd+3Da09NiGTmb5/088YEnvv5fcY8Vhu6257ZdMjNCCOmsXuuti7a98pPYI1P+fv/q\n94Zk608SAPgDE4wCAAALLSOr+/7771/7c3nJLz/PnPbmxFsPePPHlUbd2S8nHkLefz/9tN4q\nX957RghhtSNXrH341Ws/xTJyhvdZYXJJorblmGPXvG7is/uv3TVkNL96CKHkywmbnf7iTtd8\ntGOv/PsXwxwBgD82p9IDAACL5LBB/foNXHWvYy7rMPzIN28f1egyHz98wcgjny/otf0dO/Wv\nbXn6p4pUzexV/m/CpCk/fvfZ+w///f8Kiz86ZOONv6ioTmf1ZNWMMRseXbTemQ8dtspimRUA\n8EcnGAUAABbJMbfedect155+xC4l/7l2lS1PKEum6vaWT3v7hN3XWW3306qX3eLxDx/o8utN\n5Q+5/YGnnv/s4XP+1KdjXn7XZbcYe+6r129eVfbJwfd+nc7qDxy+ydOlyz725GkN7lEPAJAW\nwSgAALBIhm2/8+gDjzjv2kfeuGzk1BcvP/SVab/2pJ688pgB/Udc8dhXo0+7/uvJT27S47db\nJG20zbZbbTqo7jjL73luCOGLm79qdvXpb5wxasJnh9//7LCi7MU9OwDgj0owCgAALLTyH5+7\n/fbb/12aqNs4aNRhIYSPH58aQgip6ktHr77dsVcVbXr4q199f+dfD+uW1cxfH5l5A0MIycrq\nZlef/srTqVTqqh36xX5154yy8pkPxmKxwp77tvJUAYA/KDdfAgAAFlqi7J9jx169ce7Il/Ze\nYX5jTeWUEEJO15wQwocXbzP+7o+3OOX+py/Ys2EgWvbjDZvsePOq4++bsPeA+Y1zf34khNB7\nu2WaXb3XyEPPPnuHui0PX3z+pNTA00/aK7tgtdaaIwDwxxZLpVLNLwVLrUQiUVpaGkLo0qVL\nRoZDpCFdJSUlVVVVubm5hYWF7V0LLDWqq6tnzZoVQujcuXM8Hm/vcmDxqqn8X++i5St67Pm/\nb+/uVHvdz1TV1busePRj3136Xenxy2YNKerwfdfDZk25qtHfwJJVPy1f1GdGwSYfT32qR6Is\nkUhkZ1Zf/6fhpzw17b7ppXt2jS149Yb27Vn4cHLbsp8eaL0pstAmvD2lvUuAtnDAsH6tONq4\nRya14miwxLp615Xbu4RGOGIUAABYaPGcvo+ft8W6J9/bb9C0Q8dsVlRV/NZTd0384KdV97v5\n+H5FFT/dPam8quOy3xx0wAH1Vuw18rQLDloxI6v7U38fs8rht6/ef/iYvTcvqvnlvRceenHS\nrG3Oen7P7nnNrt5WswQA/sgEowAAQEsMP+mp13qee+41d956+QVzarKWH7L2GdeOP+eI7UMI\nc4tfCCGUTH7itsn111opHFybbK586IRP+q57xiU3PTjh6tlVmf1XHX7RPX89cZ9101wdAGAR\nOZWePzin0kPLOJUeWsCp9NAypaWliUQiJyenqKiovWthkTiVnohwKj20wJJ5Kr2cCAAAAACI\nHMEoAAAAABA5glEAAAAAIHIEowAAAABA5AhGAQAAAIDIyWzvAgAAYMnyxpez2ruECMoMoSZM\n98q3qREDO7V3CQDQnhwxCgAAAABEjmAUAAAAAIgcwSgAAAAAEDmCUQAAAAAgcgSjAAAAAEDk\nCEYBAAAAgMgRjAIAAAAAkSMYBQAAAAAiRzAKAAAAAESOYBQAAAAAiBzBKAAAAAAQOYJRAAAA\nACByBKMAAAAAQOQIRgEAAACAyBGMAgAAAACRIxgFAAAAACJHMAoAAAAARI5gFAAAAACIHMEo\nAAAAABA5glEAAAAAIHIEowAAAABA5AhGAQAAAIDIEYwCAAAAAJEjGAUAAAAAIkcwCgAAAABE\njmAUAAAAAIgcwSgAAAAAEDmCUQAAAAAgcgSjAAAAAEDkCEYBAAAAgMgRjAIAAAAAkSMYBQAA\nAAAiRzAKAAAAAESOYBQAAAAAiBzBKAAAAAAQOYJRAAAAACByBKMAAAAAQOQIRgEAAACAyBGM\nAgAAAACRIxgFAAAAACJHMAoAAAAARI5gFAAAAACInDYKRhOlk6897+Qxe++xx5/2P/70v/37\nuzm/9iRfuvfqE448cK99Dznrbzd9XV5dZ6Wmuha2HQCgGbO/eeGoUVv369U1Oyuv14DVj7jw\nntk1qboLFP/3XwfttFHPzoU5hV2GbrzrDc9/0+g471xw4p/v+rpuy9ziibEmFPbct3aZks8m\nHr7bloOX65GdVzRwrU3Ovun5VGODAwAArSizTZ4lde3xZ71TuO5RZxzYLaPsxfuuumT8ySvd\nfVW3rIyvHzrj8vu+G3PUuAM7Vz9xwzWnH5e464ajasPaproWth0AYMHKpz+x2pBdplQX7Lj/\n2DV7Z7733D3Xn/qnhx/9z9Q3rsiMhRDCLx9dt9I6R8+KL7PP2MP75ZQ8ddedR2z1xLRnvz17\nsz51x6lJfH/0dXdl7L1X3cZ4dp999tmn/lOmqh564OHC/muEEMp+eGDIGqNmhJ57jx29V6fU\nW4/fec6hW7z47Usv/3XjxTprAACIuLYIRitLXnxhRvlxlx45omNOCGH5U058fJ9T7vup/Kje\n2ZfdN2mFUZfsucUKIYSBF8X23O+iu6aO3XeZgpBKNN7VJ2vh2pcpaIMJAgBLtft2P+S7ytSF\nr3520ga9Qgjh3L/dtPegQ++/8uDXTr5tw94hhHFbn1gc6/7k5E+37FsQQjj7vPG7D1zrb3se\ncNrMp7NjIYSQTJR++u6/rzn94C8rqgb9fvCsgjXuueeees/432u3f+DRPnc/eVQIYeLo46Yl\nUrd/OWnfAR1CCOH8Cw5Zvtetf9vxu7OKl8uJL+65AwBAZLXFIZUZmd0OPPDAdYuy5z2OZYYQ\n8uMZlSWvTJlbs+WWy9Q253QauWZh9rsv/RhCaKprYdvbYHYAwNLu8g9mFvQ+Yl4qGkII8X2v\nuyqE8Mqlk0IIFTMfvOfHsoFj7q1NRUMIWYUrXX3LpnN/eeaiKaUhhOqKybl5nYauv931L/6Q\nztNVlryyxXFPb3PFM5t1yQ0hvDi5JKtgjXmpaAghI+/gXfoma2Y/Uzy3VWcJAAD8TlscMZpV\nsNouu6wWQij+4D/vTZv23vMPdV9lx3175Ff88FEIYUh+1vwlV87PfOqjkjA6JMoa70pssnDt\nYXTjJSUSiYqKiladJUuoZDJZ+0NpaWksFmvfYmApUl1dHUJIJBIlJSXtXQssZsm5VcsOGLrK\ntnX39kRFbgihclZJSUlJyffPhxC6rd+x7gLxAcNCeOKJJ744evTAVLLDg488GkKoKv9sj1En\nhxBmz569gC+d63fep6zH3hP2WaZ2wLWWL7z+9Y8e+mr6Ft1yawu6/6mpGZkd1orNLSlxzXRg\nMfItDy3jvQMt0F5vnIyMjKKioqZ62+Yao/NMf+2Fp76c+t13FSN26x9CSFaWhRC6Zv521Gq3\nrHj1nLkL6FrY9qYqSSaTVVVVrTYxlga1KQ+wUJLJ5Pz/LsAfV/zV114LIdT93WDy/eeGEIaM\nXa6qqiqV2S+E8PObP1btvOz8BUqnfBxC+PmNGVV7LRdC5vrrrx9CSMyZ9z/aBXzpFE+64pSX\np41/4c+x6nnPt+2Em9fbeK/Rwzc75JA9+3ZIvv/0Xfd9OXfsZU8tF0/5daX9tOkvydBefMhA\ny3jvQAu01xsnHl/Qxana9He+weNOvTiE8h/eOmzc+ef0HnLS4LwQQnF1svDXEn+uqol3yg4h\nZGQ33rWw7U1VEo/Hc3JyFtM0WaLMD8Gzs7MdMQrpq6qqSiaT8Xg8M1M6QOR88tilO5z0Sn7P\nrW/ZeWBOZiy770FDC87+7K5jJp/9xtAO2SGEZGLahUc+F0JIFNf87jeKxLxgdAFfOhfvd1Wn\nFY8/a53e81tyeo38vyO32ufMR6/+2zm1LV2GHnDo7qvm5DT5mwyLX017FwBtYTH8TVTe2gPC\nkkieAC3QXm+cBWdBbfHnbumXr776Vc72Ww+vfZjfZ/iOXXKfePrHrLWHhvDK5xXVfX+9scAX\nFdUdR3YKIWQVNN61sO1NlZSVlZWVldVUL38kiUSiNhgtLCzMyGiLi+rCH0NJSUkymczKyios\nLGzvWqDtlE97+8xxR1z28LtF/bd64j+P9OucF0IIoejRWw4aNOr6zVbdbP/9t++eUfz8fXdM\nKhwSwttZRR3qnpgTr649Fz4UFBQ0+q/pmR+cdtO3pce9fUrdtSaeOHKfS/690wnX/O3oPft3\nTr777F1HjD11i3WnffzV48vnuvlSO5k+q70rgLawgFMLW6q4tQeEJdFieO/AH9+S+cZpi5yo\nquLlG6+/fGbVrydjpmo+Ka/O75ef22nTPtnxp1+bMW+xsg/emp1Ya4teIYSmuha2vQ1mBwD8\nIaSevPKYAf1HXPHYV6NPu/7ryU9u0iNvft+Ava/976NXbrVm3uO3X37l7Y912/aM/750fAgh\nb9m8pgdsxD8OuDm302YXrd19fkvVnLf3uOz13hte989Ljhy8XPfcDj032P34Z58+tOyHp/a9\n8fPWmhsAANBQWwSjnQcftkJ25SkX3PLufz//ctKH9/39xA8qcsaMGRBi2eP3GPzlbWc/9+7n\n077+761nXZrfe/P9li0MITTZtbDtAADNSlVfOnr17Y69qmjTw1/96vs7/3pYt6z6vyMN3uno\nx154c2pxxeyfp/7r5lPyZ70YQuizde/GhmtcZcnLJ384c/CRF2fWOZunbPodFcnUoKO2rLtk\n92GnhxC+uvPrFk8IAABoVlucSp+R1f28y0679oa7L/3L09VZRf36Dz72wrM26JwTQhi493lH\nVl5x7+Vn/Tw3tsLqG5/3l0Pm/xXSVNfCtgMALNiHF28z/u6Ptzjl/qcv2LPR3x/uuPmmmoIR\nY0et+tsql7wcQji+zrGfzfrqjlOrU6lxR69UtzGe3TuEMHvy7LqNVeWfhxBye+anPzgAALCw\nYqlUqr1rgMUokUiUlpaGELp06eIao5C+kpKSqqqq3Nxc1xjljy85d0hRh++7HjZrylVNfU+c\nuWLnC/9X+Or0r9brmB1CKPvhqUEDdqha9ZwZ75xed7Hy4tcKumw4aOzET2/equE1Rs9bofO5\nM/rPnf1+3cu/p2pmr9Gx2+fxdf7z7Qurd669IH3y7iOHjr7u0yPe+PHa9Xq22jRZGG986Rqj\nRMKIgU3elaFlJrw9pXUHhCXTAcP6teJo4x6Z1IqjwRLr6l1Xbu8SGuFewwBApFX8/PCk8qqO\ny35z0AEH1OvqNfK0Cw5aMYRw7P2nXbrOyZsNWveQA3eOzfj0X/c+OjNrpYlPHp/+sySrZl48\npbTzGifXuylmLF70r7uOGbTbpcP6rjp6/136d6p574X7Hnvzh/7bnXu1VBQAABYnwSgAEGlz\ni18IIZRMfuK2yfW7VgoH1wajXdc8cfLLfY4+5ZJ7rrmwMrf7Brsffc8l5w3vvhB3Xir55vzS\n6uTKo4c27Oq388VfvbTGyX+9+ok7rymuzFhmxdWPv+Ty84/fy2kOAACwWDmVnj84p9JDyziV\nHlqgurp61qxZIYTOnTs3PJWepYhT6YkIp9JDyziVHlpgyTyVXk4EAAAAAESOYBQAAAAAiBzB\nKAAAAAAQOYJRAAAAACByBKMAAAAAQOQIRgEAAACAyMls7wIAgMVlrXNfaO8SoC28d+Zm7V0C\nAABLH0eMAgAAAACRIxgFAAAAACJHMAoAAAAARI5gFAAAAACIHMEoAAAAABA5glEAAAAAIHIE\nowAAAABA5AhGAQAAAIDIEYwCAAAAAJEjGAUAAAAAIkcwCgAAAABEjmAUAAAAAIgcwSgAAAAA\nEDmCUQAAAAAgcgSjAAAAAEDkCEYBAAAAgMgRjAIAAAAAkSMYBQAAAAAiRzAKAAAAAP/P3p0H\nxlnWCRx/J3fTtE3LYaEtKAUKKCAISIWKQHFhRWQ5ZcvRikA5BUVFymVBEKSCi7JccuNSEBAB\nAUHAwlrlEtGlIAhIQc7SJr2SmcnM/hEpV3M6kzfJ7/P5a/K8yZtfCs8k+eadGcIRRgEAAACA\ncIRRAAAAACAcYRQAAAAACEcYBQAAAADCEUYBAAAAgHCEUQAAAAAgHGEUAAAAAAhHGAUAAAAA\nwhFGAQAAAIBwhFEAAAAAIBxhFAAAAAAIRxgFAAAAAMIRRgEAAACAcIRRAAAAACAcYRQAAAAA\nCEcYBQAAAADCEUYBAAAAgHCEUQAAAAAgHGEUAAAAAAhHGAUAAAAAwhFGAQAAAIBwhFEAAAAA\nIBxhFAAAAAAIRxgFAAAAAMIRRgEAAACAcIRRAAAAACAcYRQAAAAACEcYBQAAAADCEUYBAAAA\ngHCEUQAAAAAgHGEUAAAAAAhHGAUAAAAAwhFGAQAAAIBwhFEAAAAAIBxhFAAAAAAIRxgFAAAA\nAMIRRgEAAACAcIRRAAAAACAcYRQAAAAACEcYBQAAAADCEUYBAAAAgHCEUQAAAAAgHGEUAAAA\nAAhHGAUAAAAAwhFGAQAAAIBwhFEAAAAAIBxhFAAAAAAIRxgFAAAAAMIRRgEAAACAcIRRAAAA\nACAcYRQAAAAACEcYBQAAAADCEUYBAAAAgHCEUQAAAAAgHGEUAAAAAAhHGAUAAAAAwhFGAQAA\nAIBwhFEAAAAAIJyqtAdIR1tbWy6XS3sK+kI+n2+/0dramslk0h0GBpBCoZAkSVtbW0tLS9qz\nAHTBPRX0jr0DvWPvQC+ktXEymUxtbW1HR4OG0Xw+744siGKx2H6jpaVFGIXuE0aBAcQ9FfSO\nvQO9Y+9AL6S1cSoqKoTRD6qtre3kH4XBJJvNNjc3J0kyYsSIigrPHQHd1dTUlMvlampqGhoa\n0p4FoAuNjY0lPuNbi0p8QuiXSr93kuZSnxD6o1LvnVdLejbop8rwTacEdCIAAAAAIBxhFAAA\nAAAIRxgFAAAAAMIRRgEAAACAcIRRAAAAACAcYRQAAAAACEcYBQAAAADCEUYBAAAAgHCEUQAA\nAAAgHGEUAAAAAAhHGAUAAAAAwhFGAQAAAIBwhFEAAAAAIBxhFAAAAAAIRxgFAAAAAMIRRgEA\nAACAcIRRAAAAACAcYRQAAAAACEcYBQAAAADCEUYBAAAAgHCEUQAAAAAgHGEUAAAAAAhHGAUA\nAAAAwhFGAQAAAIBwhFEAAAAAIBxhFAAAAAAIRxgFAAAAAMIRRgEAAACAcIRRAAAAACAcYRQA\nAAAACEcYBQAAAADCEUYBAAAAgHCEUQAAAAAgHGEUAAAAAAhHGAUAAAAAwhFGAQAAAIBwhFEA\nAAAAIBxhFAAAAAAIRxgFAAAAAMIRRgEAAACAcIRRAAAAACAcYRQAAAAACEcYBQAAAADCEUYB\nAAAAgHCEUQAAAAAgHGEUAAAAAAhHGAUAAAAAwhFGAQAAAIBwhFEAAAAAIBxhFAAAAAAIRxgF\nAAAAAMIRRgEAAACAcIRRAAAAACAcYRQAAAAACKe7YXTixInnvrzkw+uv/e6YSTscUNKRAAAA\nAADKq6rzw80vPPdqti1Jkt///vfrzJv3zNLh7z9e/Msdc3734Ivlmg4AAAAAoAy6CKM37fzp\nr/z17fbbP/v8Vj9b2fsM/+iRpZ4KAAAAAKCMugijn5n5w4sWtSRJVcnUBgAAIABJREFUMn36\n9O1OP2+/1YZ84B0qqodN3HOvck0HAAAAAFAGXYTRCfseNCFJkiS5/vrrd//KVw9bs6EPZgIA\nAAAAKKsuwugK999/f1nnAAAAAADoM90No+3efvn5N5fmPrw+YcKEEs0DAAAAAFB23Q2jLW/d\nu+e2+/7qmbdXerRYLJZuJAAAAACA8upuGL3kSwfc+eziXQ8/YedNPlqVKetIAAAAAADl1d0w\nesYjb66z7823XbhbWacBAAAAAOgDFd15p2Lb4jdzbWvvu0m5pwEAAAAA6APdCqOZyobPNdY9\nf+Wj5Z4GAAAAAKAPdCuMJknm+ttPz965/9TTr3p9ab68EwEAAAAAlFl3n2N0rxNu/cga1Ved\nMvXqUw8eNXr0kMr3vQDT/PnzyzAbAAAAAEBZdDeMrrrqqquuOnntT5Z1GAAAAACAvtDdMHrL\nLbeUdQ4AAAAAgD7T3TDa1NTUydERI0aUYhgAAAAAgL7Q3TDa2NjYydFisViKYQAAAAAA+kJ3\nw+hpp532vreL+X88/9QvZt/6dmbMaf99ZsnHAgAAAAAon+6G0VNPPfXDi+f/4A87rr/d+T96\nbMa0KSWdCgAAAACgjCr+lQ8e8pFPXzrzk2/96bzfNrWWaiAAAAAAgHL7l8JokiT1Y+szmcoJ\n9dUlmQYAAAAAoA/8S2G0kHvzvJOfqG7YbHT1vxpYAQAAAAD6THefY3TixIkfWiu8+uyTf1/Q\nssVJPy7tTAAAAAAAZdXdMLoyFeM23mH3Hfc/Z8anSzYOAAAAAED5dTeMzp07t6xzAAAAAAD0\nGc8NCgAAAACE07OH0i975Ymf33rPU8//Y1lb1RrrfPzzu+/1qXENZZoMAAAAAKBMehBGbzrl\ny1O+d0NrobhiZcax0/eecd3smXuWYTAAAAAAgHLp7kPpX7hxyl6nz159u6/MvucPr7yxYOGb\n/3jkvp8f/LmP3HD6Xgfc/GI5JwQAAAAAKLHuXjF67rG/bBgz9el7L62vyLSvbLH9np/abpfC\n2qNvOHpWsscFZZsQAAAAAKDEunvF6PVvLlv/0K+tqKLtMhX1XztqwvI3/6cMgwEAAAAAlEt3\nw2hDRUXL6y0fXm95vSVT6fWXAAAAAICBpLsPpT92vREnXH3Eo2fM3WJk7YrFbNPjR1321xHr\nfr/LDy/mF95y6cV3/u5PC1oq1hi33m4HTP+3zUYnSZIkhQeuv/C2OY/PX1y5wSe2mnr0tHXq\nV4zU0aGergMAAAAAvE93rxid9vOZtcv/tM1HNz18xtnXzr7p57OvPfukIzZd+zOPLav57o3T\nuvzwX595/HW/fX23acecffq3dxjfeuFpR/5i/pIkSZ6/6aTzZs/deo9DTj32wIa//WbGcRcX\n3vmQjg71dB0AAAAA4AO6e01l44Qjnrqnav8jTrzozBMuemdx1ITP/uQn10zfoLHzj21rnX/R\nY29td+a5X/z4yCRJ1ttg41cf3vcXF/5l9zM3/+HseeP3O3fvyeOTJFn3nMzeB55z3StTDxgz\nNClmV35ozeqerY8Z2rt/FwAAAABgEOvuFaNJkozd/tAH5r05f94jd91+66233/XIUy+9+fRv\np++4Vpcf2Nby4tof+9i/rzP8nYXMZiNqc4uWtDbNeamlbaedxrSv1jZuu1lDzWMPvJYkSUeH\nerre/a8OAAAAAIijW1eMPvuHe55bc+Iu4xqSJDN2gy0ah//o6DPmT9qpbsMJY4e+/3XqV6pm\nxKTzz5+04s3ckqcv/8eStadNyC69MUmSjeqrVxzasL7qriebkilJdumTKz2U/VzP1pMpKx+p\nUCi0tbV152tnoMvn8+03crlcRUUP/hIAwRWLxSRJCoVCLpdLexaALringt6xd6B37B3ohRQ3\nTnV1dUeHugijzc/eduA+h936xKs73fXSLuP++erzuaVPXvnfl1/537OOW+ezl936i70/MbL7\no/z90V/9148uz62zy4ydx+b/vjRJklWq3m1Vq1ZX5pe0JElSaF35oZ6udzRGNptdsmRJ98dm\nEFi8eHHaI8DAk81ms9ls2lMAdKGpqanUp/QanoRQhr0DIdg70AtpbZzKysqRIztMl51dQJdt\n/t8tN93zl0++vfthM76xySor1hvXOe+Jh351yvQvtbz44JSttv5dc7d+Z84ufOaimUce871r\nxux8+CVnHzK0MlNRMyRJkoX5d18kaUGurXJITZIkHR3q6Xp3BgMAAAAAounsj+H3T5/6bEv+\n5Lte+O7n137veqZy+Kbb7LLpNrtM/cI3x+82a9oxDz1z5Q6df5rFf//NN47/ceXGu5xz6YET\nVq1rX6weunGSzHlmeX5cbWX7yrPL8yO2bezkUE/XO5qntra2tra285kZHLLZbPu1oiNHjvRQ\neui+5ubmXC5XV1c3dKhXsQP6u1VWWaXrd+qJZxe5FIgQSr53kheWlfiE0C+Veu+8WdKzQT9V\n+m86pdBZGJ1118sNax77gSr6Xh/b9QdfH3fJhbefnySdhdFiYdn3vn1h7Y7H/Nf07d/7jKR1\n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\nefdDb7S/mVv6xMOLs5tPHt3JoZ6u9/nXBAAAAAAMAKleQJepOX6vDZ678rR7H3vm1ef/cvkp\ns+rX2PHAsQ2dHerpOgAAAADAh6T8cPJ19z3jiNbzrz/vlAUtmfGbbnfGzEMqujrU03UAAAAA\ngA/IFIvFtGeAMspms83NzUmSjBo1ynOMQvc1NTXlcrm6urqGBlffD2Cbn35f2iNAX3j85B1K\ne8K5z3mOUUKYuG6Hr8rQO1c88lJpTwj907Qt1yrh2Y66ZV4Jzwb91o//Y8O0R1gJnQgAAAAA\nCEcYBQAAAADCEUYBAAAAgHCEUQAAAAAgHGEUAAAAAAhHGAUAAAAAwhFGAQAAAIBwhFEAAAAA\nIBxhFAAAAAAIRxgFAAAAAMIRRgEAAACAcIRRAAAAACAcYRQAAAAACEcYBQAAAADCEUYBAAAA\ngHCEUQAAAAAgHGEUAAAAAAhHGAUAAAAAwhFGAQAAAIBwhFEAAAAAIBxhFAAAAAAIRxgFAAAA\nAMIRRgEAAACAcIRRAAAAACAcYRQAAAAACEcYBQAAAADCEUYBAAAAgHCEUQAAAAAgHGEUAAAA\nAAhHGAUAAAAAwhFGAQAAAIBwhFEAAAAAIBxhFAAAAAAIRxgFAAAAAMIRRgEAAACAcIRRAAAA\nACAcYRQAAAAACEcYBQAAAADCEUYBAAAAgHCEUQAAAAAgHGEUAAAAAAhHGAUAAAAAwhFGAQAA\nAIBwhFEAAAAAIBxhFAAAAAAIRxgFAAAAAMIRRgEAAACAcIRRAAAAACAcYRQAAAAACEcYBQAA\nAADCEUYBAAAAgHCEUQAAAAAgHGEUAAAAAAhHGAUAAAAAwhFGAQAAAIBwhFEAAAAAIBxhFAAA\nAAAIRxgFAAAAAMIRRgEAAACAcIRRAAAAACAcYRQAAAAACEcYBQAAAADCEUYBAAAAgHCEUQAA\nAAAgHGEUAAAAAAhHGAUAAAAAwhFGAQAAAIBwhFEAAAAAIBxhFAAAAAAIRxgFAAAAAMIRRgEA\nAACAcIRRAAAAACAcYRQAAAAACEcYBQAAAADCEUYBAAAAgHCEUQAAAAAgHGEUAAAAAAhHGAUA\nAAAAwhFGAQAAAIBwhFEAAAAAIBxhFAAAAAAIRxgFAAAAAMIRRgEAAACAcIRRAAAAACAcYRQA\nAAAACEcYBQAAAADCEUYBAAAAgHCq0h4gHfl8vrW1Ne0p6AttbW3tN5YtW5bJZNIdBgaQ9r2T\nz+eXLl2a9iwAXXBPBb1j70Dv2DvQC2ltnIqKiiFDhnR0NGgYLRaLhUIh7SnoC8Visf1GoVAQ\nRqGn3FsCA4J7Kugdewd6x96BXkhr46zoQisVNIxWV1dXV1enPQV9IZvN5nK5JEkaGhoqKjx3\nBHRXU1NToVCorq5uaGhIexaALgwbNqzEZ3x9UYlPCP1S6fdOsrDUJ4T+qAx7Bwa//rlxdCIA\nAAAAIBxhFAAAAAAIRxgFAAAAAMIRRgEAAACAcIRRAAAAACAcYRQAAAAACEcYBQAAAADCEUYB\nAAAAgHCEUQAAAAAgHGEUAAAAAAhHGAUAAAAAwhFGAQAAAIBwhFEAAAAAIBxhFAAAAAAIRxgF\nAAAAAMIRRgEAAACAcIRRAAAAACAcYRQAAAAACEcYBQAAAADCEUYBAAAAgHCEUQAAAAAgHGEU\nAAAAAAhHGAUAAAAAwhFGAQAAAIBwhFEAAAAAIBxhFAAAAAAIRxgFAAAAAMIRRgEAAACAcIRR\nAAAAACAcYRQAAAAACEcYBQAAAADCEUYBAAAAgHCEUQAAAAAgHGEUAAAAAAhHGAUAAAAAwhFG\nAQAAAIBwhFEAAAAAIBxhFAAAAAAIRxgFAAAAAMIRRgEAAACAcIRRAAAAACAcYRQAAAAACEcY\nBQAAAADCEUYBAAAAgHCEUQAAAAAgHGEUAAAAAAhHGAUAAAAAwhFGAQAAAIBwhFEAAAAAIBxh\nFAAAAAAIRxgFAAAAAMIRRgEAAACAcIRRAAAAACAcYRQAAAAACEcYBQAAAADCEUYBAAAAgHCE\nUQAAAAAgHGEUAAAAAAhHGAUAAAAAwhFGAQAAAIBwhFEAAAAAIBxhFAAAAAAIRxgFAAAAAMIR\nRgEAAACAcIRRAAAAACAcYRQAAAAACEcYBQAAAADCEUYBAAAAgHCEUQAAAAAgHGEUAAAAAAhH\nGAUAAAAAwhFGAQAAAIBwhFEGrcUv3Hfkfv82ftwaa64xdqNPbXfE2dcvbiumPRQMMNccPHnj\nTx+d9hQAAABQelVpDwBlsez1OzbZaPeX8kO/cMABG44sPDnn5otPnHLLrQ+/Mvf8qkzaw8EA\nMf+Obx5xwx/qVx2X9iAAAABQesIog9PsPQ/5e2vx+w8+feyWo5qbm5PvnHLzEZ857MYfffWh\nb185aY20p4MBoLVp7u6HXZv2FAAAAFAuHkrP4HTeE28NXePwb20z+p2Fyv0v/K8kSebMmpfi\n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\nH/tRNPeHPzvaAAAAAElFTkSuQmCC"
     },
     "metadata": {
      "image/png": {
       "height": 480,
       "width": 900
      }
     },
     "output_type": "display_data"
    }
   ],
   "source": [
    "options(repr.plot.width=15, repr.plot.height=8)\n",
    "train_labels %>% group_by(resname) %>% summarize(total = n()) %>% \n",
    "    ggplot(aes(x=reorder(resname, total), y=total)) + geom_col(aes(fill=resname)) + geom_text(aes(label = total), vjust = -0.5) +  scale_fill_brewer(palette = \"Blues\") + \n",
    "    xlab(\"Resname\") + ylab(\"Count\") + ggtitle(\"Barplot of resname occurrences in train_labels\") + guides(fill=\"none\") + theme_minimal()\n",
    "\n",
    "# There are 2 x resnames with 'x' and four that are missing...the rest come from U, A, C, & G."
   ]
  },
  {
   "cell_type": "markdown",
   "id": "dbfdb56a",
   "metadata": {
    "papermill": {
     "duration": 0.012094,
     "end_time": "2025-05-06T17:27:45.493551",
     "exception": false,
     "start_time": "2025-05-06T17:27:45.481457",
     "status": "completed"
    },
    "tags": []
   },
   "source": [
    "### validation_sequences.csv"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 13,
   "id": "465a9683",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-05-06T17:27:45.520586Z",
     "iopub.status.busy": "2025-05-06T17:27:45.519420Z",
     "iopub.status.idle": "2025-05-06T17:27:45.545473Z",
     "shell.execute_reply": "2025-05-06T17:27:45.544075Z"
    },
    "papermill": {
     "duration": 0.041718,
     "end_time": "2025-05-06T17:27:45.547458",
     "exception": false,
     "start_time": "2025-05-06T17:27:45.505740",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "[1] \"validation_sequences has 12 rows and 5 columns\"\n"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "[1] \"validation_sequences has 0 NAs.\"\n"
     ]
    },
    {
     "data": {
      "text/html": [
       "<table class=\"dataframe\">\n",
       "<caption>A data.frame: 3 × 5</caption>\n",
       "<thead>\n",
       "\t<tr><th></th><th scope=col>target_id</th><th scope=col>sequence</th><th scope=col>temporal_cutoff</th><th scope=col>description</th><th scope=col>all_sequences</th></tr>\n",
       "\t<tr><th></th><th scope=col>&lt;chr&gt;</th><th scope=col>&lt;chr&gt;</th><th scope=col>&lt;chr&gt;</th><th scope=col>&lt;chr&gt;</th><th scope=col>&lt;chr&gt;</th></tr>\n",
       "</thead>\n",
       "<tbody>\n",
       "\t<tr><th scope=row>1</th><td>R1107</td><td><span style=white-space:pre-wrap>GGGGGCCACAGCAGAAGCGUUCACGUCGCAGCCCCUGUCAGCCAUUGCACUCCGGCUGCGAAUUCUGCU                                                                                        </span></td><td>2022-05-28</td><td><span style=white-space:pre-wrap>CPEB3 ribozyme\n",
       "Human\n",
       "human CPEB3 HDV-like ribozyme                                                          </span></td><td><span style=white-space:pre-wrap>&gt;7QR4_1|Chain A|U1 small nuclear ribonucleoprotein A|Homo sapiens (9606)\n",
       "RPNHTIYINNLNEKIKKDELKKSLHAIFSRFGQILDILVSRSLKMRGQAFVIFKEVSSATNALRSMQGFPFYDKPMRIQYAKTDSDIIAKM\n",
       "&gt;7QR4_2|Chain B|RNA CPEB3 ribozyme|Homo sapiens (9606)\n",
       "GGGGGCCACAGCAGAAGCGUUCACGUCGCAGCCCCUGUCAGCCAUUGCACUCCGGCUGCGAAUUCUGCU                  </span></td></tr>\n",
       "\t<tr><th scope=row>2</th><td>R1108</td><td><span style=white-space:pre-wrap>GGGGGCCACAGCAGAAGCGUUCACGUCGCGGCCCCUGUCAGCCAUUGCACUCCGGCUGCGAAUUCUGCU                                                                                        </span></td><td>2022-05-27</td><td><span style=white-space:pre-wrap>CPEB3 ribozyme\n",
       "Chimpanzee\n",
       "Chimpanzee CPEB3 HDV-like ribozyme                                                </span></td><td>&gt;7QR3_1|Chains A, B|U1 small nuclear ribonucleoprotein A|Homo sapiens (9606)\n",
       "RPNHTIYINNLNEKIKKDELKKSLHAIFSRFGQILDILVSRSLKMRGQAFVIFKEVSSATNALRSMQGFPFYDKPMRIQYAKTDSDIIAKM\n",
       "&gt;7QR3_2|Chains C, D|chimpanzee CPEB3 ribozyme|Pan troglodytes (9598)\n",
       "GGGGGCCACAGCAGAAGCGUUCACGUCGCGGCCCCUGUCAGCCAUUGCACUCCGGCUGCGAAUUCUGCU</td></tr>\n",
       "\t<tr><th scope=row>3</th><td>R1116</td><td>CGCCCGGAUAGCUCAGUCGGUAGAGCAGCGGCUAAAACAGCUCUGGGGUUGUACCCACCCCAGAGGCCCACGUGGCGGCUAGUACUCCGGUAUUGCGGUACCCUUGUACGCCUGUUUUAGCCGCGGGUCCAGGGUUCAAGUCCCUGUUCGGGCGCCA</td><td>2022-06-04</td><td>Cloverleaf RNA\n",
       "Poliovirus\n",
       "Crystal Structure of Poliovirus (type 1 Mahoney) cloverleaf RNA with tRNA scaffold</td><td><span style=white-space:pre-wrap>&gt;8S95_1|Chain A[auth C]|Lysine tRNA scaffold,Poliovirus cloverleaf RNA|Homo sapiens (9606)\n",
       "CGCCCGGAUAGCUCAGUCGGUAGAGCAGCGGCUAAAACAGCUCUGGGGUUGUACCCACCCCAGAGGCCCACGUGGCGGCUAGUACUCCGGUAUUGCGGUACCCUUGUACGCCUGUUUUAGCCGCGGGUCCAGGGUUCAAGUCCCUGUUCGGGCGCCA                                                             </span></td></tr>\n",
       "</tbody>\n",
       "</table>\n"
      ],
      "text/latex": [
       "A data.frame: 3 × 5\n",
       "\\begin{tabular}{r|lllll}\n",
       "  & target\\_id & sequence & temporal\\_cutoff & description & all\\_sequences\\\\\n",
       "  & <chr> & <chr> & <chr> & <chr> & <chr>\\\\\n",
       "\\hline\n",
       "\t1 & R1107 & GGGGGCCACAGCAGAAGCGUUCACGUCGCAGCCCCUGUCAGCCAUUGCACUCCGGCUGCGAAUUCUGCU                                                                                         & 2022-05-28 & CPEB3 ribozyme\n",
       "Human\n",
       "human CPEB3 HDV-like ribozyme                                                           & >7QR4\\_1\\textbar{}Chain A\\textbar{}U1 small nuclear ribonucleoprotein A\\textbar{}Homo sapiens (9606)\n",
       "RPNHTIYINNLNEKIKKDELKKSLHAIFSRFGQILDILVSRSLKMRGQAFVIFKEVSSATNALRSMQGFPFYDKPMRIQYAKTDSDIIAKM\n",
       ">7QR4\\_2\\textbar{}Chain B\\textbar{}RNA CPEB3 ribozyme\\textbar{}Homo sapiens (9606)\n",
       "GGGGGCCACAGCAGAAGCGUUCACGUCGCAGCCCCUGUCAGCCAUUGCACUCCGGCUGCGAAUUCUGCU                  \\\\\n",
       "\t2 & R1108 & GGGGGCCACAGCAGAAGCGUUCACGUCGCGGCCCCUGUCAGCCAUUGCACUCCGGCUGCGAAUUCUGCU                                                                                         & 2022-05-27 & CPEB3 ribozyme\n",
       "Chimpanzee\n",
       "Chimpanzee CPEB3 HDV-like ribozyme                                                 & >7QR3\\_1\\textbar{}Chains A, B\\textbar{}U1 small nuclear ribonucleoprotein A\\textbar{}Homo sapiens (9606)\n",
       "RPNHTIYINNLNEKIKKDELKKSLHAIFSRFGQILDILVSRSLKMRGQAFVIFKEVSSATNALRSMQGFPFYDKPMRIQYAKTDSDIIAKM\n",
       ">7QR3\\_2\\textbar{}Chains C, D\\textbar{}chimpanzee CPEB3 ribozyme\\textbar{}Pan troglodytes (9598)\n",
       "GGGGGCCACAGCAGAAGCGUUCACGUCGCGGCCCCUGUCAGCCAUUGCACUCCGGCUGCGAAUUCUGCU\\\\\n",
       "\t3 & R1116 & CGCCCGGAUAGCUCAGUCGGUAGAGCAGCGGCUAAAACAGCUCUGGGGUUGUACCCACCCCAGAGGCCCACGUGGCGGCUAGUACUCCGGUAUUGCGGUACCCUUGUACGCCUGUUUUAGCCGCGGGUCCAGGGUUCAAGUCCCUGUUCGGGCGCCA & 2022-06-04 & Cloverleaf RNA\n",
       "Poliovirus\n",
       "Crystal Structure of Poliovirus (type 1 Mahoney) cloverleaf RNA with tRNA scaffold & >8S95\\_1\\textbar{}Chain A{[}auth C{]}\\textbar{}Lysine tRNA scaffold,Poliovirus cloverleaf RNA\\textbar{}Homo sapiens (9606)\n",
       "CGCCCGGAUAGCUCAGUCGGUAGAGCAGCGGCUAAAACAGCUCUGGGGUUGUACCCACCCCAGAGGCCCACGUGGCGGCUAGUACUCCGGUAUUGCGGUACCCUUGUACGCCUGUUUUAGCCGCGGGUCCAGGGUUCAAGUCCCUGUUCGGGCGCCA                                                             \\\\\n",
       "\\end{tabular}\n"
      ],
      "text/markdown": [
       "\n",
       "A data.frame: 3 × 5\n",
       "\n",
       "| <!--/--> | target_id &lt;chr&gt; | sequence &lt;chr&gt; | temporal_cutoff &lt;chr&gt; | description &lt;chr&gt; | all_sequences &lt;chr&gt; |\n",
       "|---|---|---|---|---|---|\n",
       "| 1 | R1107 | GGGGGCCACAGCAGAAGCGUUCACGUCGCAGCCCCUGUCAGCCAUUGCACUCCGGCUGCGAAUUCUGCU                                                                                         | 2022-05-28 | CPEB3 ribozyme\n",
       "Human\n",
       "human CPEB3 HDV-like ribozyme                                                           | &gt;7QR4_1|Chain A|U1 small nuclear ribonucleoprotein A|Homo sapiens (9606)\n",
       "RPNHTIYINNLNEKIKKDELKKSLHAIFSRFGQILDILVSRSLKMRGQAFVIFKEVSSATNALRSMQGFPFYDKPMRIQYAKTDSDIIAKM\n",
       "&gt;7QR4_2|Chain B|RNA CPEB3 ribozyme|Homo sapiens (9606)\n",
       "GGGGGCCACAGCAGAAGCGUUCACGUCGCAGCCCCUGUCAGCCAUUGCACUCCGGCUGCGAAUUCUGCU                   |\n",
       "| 2 | R1108 | GGGGGCCACAGCAGAAGCGUUCACGUCGCGGCCCCUGUCAGCCAUUGCACUCCGGCUGCGAAUUCUGCU                                                                                         | 2022-05-27 | CPEB3 ribozyme\n",
       "Chimpanzee\n",
       "Chimpanzee CPEB3 HDV-like ribozyme                                                 | &gt;7QR3_1|Chains A, B|U1 small nuclear ribonucleoprotein A|Homo sapiens (9606)\n",
       "RPNHTIYINNLNEKIKKDELKKSLHAIFSRFGQILDILVSRSLKMRGQAFVIFKEVSSATNALRSMQGFPFYDKPMRIQYAKTDSDIIAKM\n",
       "&gt;7QR3_2|Chains C, D|chimpanzee CPEB3 ribozyme|Pan troglodytes (9598)\n",
       "GGGGGCCACAGCAGAAGCGUUCACGUCGCGGCCCCUGUCAGCCAUUGCACUCCGGCUGCGAAUUCUGCU |\n",
       "| 3 | R1116 | CGCCCGGAUAGCUCAGUCGGUAGAGCAGCGGCUAAAACAGCUCUGGGGUUGUACCCACCCCAGAGGCCCACGUGGCGGCUAGUACUCCGGUAUUGCGGUACCCUUGUACGCCUGUUUUAGCCGCGGGUCCAGGGUUCAAGUCCCUGUUCGGGCGCCA | 2022-06-04 | Cloverleaf RNA\n",
       "Poliovirus\n",
       "Crystal Structure of Poliovirus (type 1 Mahoney) cloverleaf RNA with tRNA scaffold | &gt;8S95_1|Chain A[auth C]|Lysine tRNA scaffold,Poliovirus cloverleaf RNA|Homo sapiens (9606)\n",
       "CGCCCGGAUAGCUCAGUCGGUAGAGCAGCGGCUAAAACAGCUCUGGGGUUGUACCCACCCCAGAGGCCCACGUGGCGGCUAGUACUCCGGUAUUGCGGUACCCUUGUACGCCUGUUUUAGCCGCGGGUCCAGGGUUCAAGUCCCUGUUCGGGCGCCA                                                              |\n",
       "\n"
      ],
      "text/plain": [
       "  target_id\n",
       "1 R1107    \n",
       "2 R1108    \n",
       "3 R1116    \n",
       "  sequence                                                                                                                                                     \n",
       "1 GGGGGCCACAGCAGAAGCGUUCACGUCGCAGCCCCUGUCAGCCAUUGCACUCCGGCUGCGAAUUCUGCU                                                                                        \n",
       "2 GGGGGCCACAGCAGAAGCGUUCACGUCGCGGCCCCUGUCAGCCAUUGCACUCCGGCUGCGAAUUCUGCU                                                                                        \n",
       "3 CGCCCGGAUAGCUCAGUCGGUAGAGCAGCGGCUAAAACAGCUCUGGGGUUGUACCCACCCCAGAGGCCCACGUGGCGGCUAGUACUCCGGUAUUGCGGUACCCUUGUACGCCUGUUUUAGCCGCGGGUCCAGGGUUCAAGUCCCUGUUCGGGCGCCA\n",
       "  temporal_cutoff\n",
       "1 2022-05-28     \n",
       "2 2022-05-27     \n",
       "3 2022-06-04     \n",
       "  description                                                                                                   \n",
       "1 CPEB3 ribozyme\\nHuman\\nhuman CPEB3 HDV-like ribozyme                                                          \n",
       "2 CPEB3 ribozyme\\nChimpanzee\\nChimpanzee CPEB3 HDV-like ribozyme                                                \n",
       "3 Cloverleaf RNA\\nPoliovirus\\nCrystal Structure of Poliovirus (type 1 Mahoney) cloverleaf RNA with tRNA scaffold\n",
       "  all_sequences                                                                                                                                                                                                                                                                                                         \n",
       "1 >7QR4_1|Chain A|U1 small nuclear ribonucleoprotein A|Homo sapiens (9606)\\nRPNHTIYINNLNEKIKKDELKKSLHAIFSRFGQILDILVSRSLKMRGQAFVIFKEVSSATNALRSMQGFPFYDKPMRIQYAKTDSDIIAKM\\n>7QR4_2|Chain B|RNA CPEB3 ribozyme|Homo sapiens (9606)\\nGGGGGCCACAGCAGAAGCGUUCACGUCGCAGCCCCUGUCAGCCAUUGCACUCCGGCUGCGAAUUCUGCU                  \n",
       "2 >7QR3_1|Chains A, B|U1 small nuclear ribonucleoprotein A|Homo sapiens (9606)\\nRPNHTIYINNLNEKIKKDELKKSLHAIFSRFGQILDILVSRSLKMRGQAFVIFKEVSSATNALRSMQGFPFYDKPMRIQYAKTDSDIIAKM\\n>7QR3_2|Chains C, D|chimpanzee CPEB3 ribozyme|Pan troglodytes (9598)\\nGGGGGCCACAGCAGAAGCGUUCACGUCGCGGCCCCUGUCAGCCAUUGCACUCCGGCUGCGAAUUCUGCU\n",
       "3 >8S95_1|Chain A[auth C]|Lysine tRNA scaffold,Poliovirus cloverleaf RNA|Homo sapiens (9606)\\nCGCCCGGAUAGCUCAGUCGGUAGAGCAGCGGCUAAAACAGCUCUGGGGUUGUACCCACCCCAGAGGCCCACGUGGCGGCUAGUACUCCGGUAUUGCGGUACCCUUGUACGCCUGUUUUAGCCGCGGGUCCAGGGUUCAAGUCCCUGUUCGGGCGCCA                                                             "
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    }
   ],
   "source": [
    "print(paste('validation_sequences has', dim(validation_sequences)[1], 'rows and', dim(validation_sequences)[2], 'columns'))\n",
    "print(paste('validation_sequences has', sum(is.na(validation_sequences)), 'NAs.'))\n",
    "\n",
    "# Quick look at the data\n",
    "validation_sequences %>% head(3)\n",
    "\n",
    "# This dataset has the same number of columns as train_sequences, and it also has 0 NA's."
   ]
  },
  {
   "cell_type": "markdown",
   "id": "2a816785",
   "metadata": {
    "papermill": {
     "duration": 0.012605,
     "end_time": "2025-05-06T17:27:45.572974",
     "exception": false,
     "start_time": "2025-05-06T17:27:45.560369",
     "status": "completed"
    },
    "tags": []
   },
   "source": [
    "### Let's recreate the boxplot of the sequence lengths we used in train_sequences, using outliers = FALSE"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 14,
   "id": "ca778880",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-05-06T17:27:45.601176Z",
     "iopub.status.busy": "2025-05-06T17:27:45.600003Z",
     "iopub.status.idle": "2025-05-06T17:27:45.794294Z",
     "shell.execute_reply": "2025-05-06T17:27:45.792479Z"
    },
    "papermill": {
     "duration": 0.210671,
     "end_time": "2025-05-06T17:27:45.796325",
     "exception": false,
     "start_time": "2025-05-06T17:27:45.585654",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "data": {
      "image/png": "iVBORw0KGgoAAAANSUhEUgAABwgAAAPACAIAAACuBbobAAAABmJLR0QA/wD/AP+gvaeTAAAg\nAElEQVR4nOzdZ4BcVd0H4HO312RTSEhCCCSEmgChSW8BAaUXEYUAguWl+IJEqghIFTX0JopY\nQPRFQaQoTVAEpYPSBEIz9JRNsnV2574fJgmbTbI7IZudTc7zfMqcPXPO/55752bnt3fuJGma\nBgAAAACAmBQVugAAAAAAgN4mGAUAAAAAoiMYBQAAAACiIxgFAAAAAKIjGAUAAAAAoiMYBQAA\nAACiIxgFAAAAAKIjGAUAAAAAorPyBKNz3jk/WURRcfnAIWtM3P/rtz3zcaEKe/77mydJMvEP\nbxaqgMb3/3LkxE0H15QN3eD0QtWwUir4nl3Uqz/fPkmS7X/+akFm74MLktNa/+iYytLznp3+\nKZ771GkbJ0myx8PvLqlDYde8UDrt625Xqaek2YZ9hlTvd+2/l/dEAAAAxGDlCUZzioqr1+pg\n1IhBDdPffvC2Hx+4+Rrn3Dut0NXlK802/P3vf//nk+/0yGhnbbf/jQ8+XbrOdrtvP7ZHBqSP\n6NnjZCV22Z4Hzh13wXc2HrTsQ/WFNe/lGvrCJi+QFFVf89tD//jNnf82u7XQtQAAALDCW9mC\n0fL+O77awRtvvztn+mvnHbxOtr3hggP2bsimhS4wL21N/9l2220/e8D1PTBW2nrZ6/WlVeu9\n/sT9P7/myB4YkD6jJ4+Tldf0f51z8iPvnXTzVz/d09c46Nwbb7zxpHUH5B72hTXv5Rryma7T\nKi1Xw3e8ep/+DYd+6be9MBcAAAArt5UtGF1UWd3o0371yMjykta5T1/zbkOhy+ltabYpk6al\nVRtUFSWFrgUK4MpDrqgeetjJY+s+3dMHbbLX4YcfvsvQyp6taiXTu6tUfMGFW7xzz9H3zGzu\nlekAAABYaa38wWgIoahk8MS68hDC9Lb25TRFtrW5fcW4GnUllm1obit0DUtrRax5RdI0/bZz\nXpyxwSknF7oQupO2fJjJ5tl39CFTSkLryec8s1wrAgAAYKUXRTCats14sL4lKSo/cHBVh+bs\nw7+6cO/tN1ylrqasuv+a47Y+5qzr322Zl5y2zHx4tYqS0opRf+9wJ7ts5oNdBlUWlVT99NX6\nEMLxI2pLK8dk5rxw4j5b9a+qLi0uGTB05G6HHPfAq7O7q6irqW9Zb3BZzSYhhNlvn5skyaB1\nfvbpxgkh3L/HqKKSuhBC48e3JklSO+L4JQ004993ffOQ3dcaNqi8tKz/oNW22/PIW/75/qLd\n3nrk5iP23XHEkAHlVXVjx29+zDnXvta4UK6Xts+5+cITtl5/jX6V5QOHjdrjy8fd8+8Zj584\nPkmSu+df3vXY/6yfJMkBL01f+In1SZJUr3LQUk2X+96bo16d+eQvzxi3Wl1NZWlJefWaG273\nnevuW6jutO2+n5y9+5brDaytqK4bsvFO+0+59clPsXX56LGaQ/s9V522/bg1a8srhoxc74hT\nftKUDRtUl9UOm/eR8K6Pkzmv33f0ftsPHdSvtKJ6jfHbnH71n7uo+e5910ySZLMLn+vUPu2B\nLyRJMnCdc3IP0/b6m380eeIW6w/qX11SVrnKyLX3+PI3//xy/ZKGzX9H57NueR6inbx8+blp\nmp546Jjcwx+sMzBJkkOf+HBBh/qpp+a+qO2EV2YuaPz4ua8kSdJ/9VNCCM+es+mCrxVa5jXv\n5gWbz4r14PkhnxnznK7jKi3Q9T59+bptkiQ57vVZc9+6+4vbrV9TVvXLDxtzP+p2X5dWTzhh\neM2rN57sr1EAAAAsk3RlMfvt80IIlQM/36m9dc5bF315vRDCepNu7th+2WEbhRCSJBk6evz2\nW202oLQ4hNB/rb1faMjkOrx8w0EhhGHbnrfgKXcdOy6EsM1Zf8s9PG54TXHZsElr14UQSqpW\n2WjCujUlRSGE4rIhVzz+4YJnPXfRZiGEnW9/I8+pn53yvZNPOjKEUN5vm1NPPfV7P3pySZvc\n7Sa8esNFp558QgihtGqdU0899awL/rDYcT56akpdSVEIYeDoDbbdYdv11+gfQigqrrn8xRkd\nuz12yaTiJEmSZOga62/zmY0GV5eEEKpH7PzAB425DtnM9GO2Hpo7roasOW791QeFEIqKqz+7\nyaAQwl0zmnLdHv3GeiGE/V/8uOPg2bZZIYSqwQfmP12apv+5cbsQwsQfHpEkSfWwtSbutc+2\nm6yRK2DPy/41v1fbhQetm9uiCVtut/n4sSVJEkLYfvLvl2rrFrXonu25mtOrJo0LISRFFWtP\n2GrdkQNDCCN2PGZkeUnNqkfnOiz2OMkNPu6UM0eUF9cMH7vLXvtst8nq8wf/95I2ZMbLp4YQ\nqlc9qlP71RNWCSEccPfbaZpm22Z/dYshIYSikrqNNttqh603X2NAeQihuGzYHR81LnZB8tzR\n+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\nAADAyq+kl+drbXg+hLB+VemClvWqSv70fH34cuee2db3zj/zpt1PuW5sVXHXY6ZpWl9f39OV\nssKYPXt2oUuAbrS3t4cQWltbZ82aVehaoCtpmqZp6kCl78tmsyGEpqamlpaWQtcCXclms86r\nrEAaGhoaG329B32a8ypLq6ioqF+/fkv6aW8Ho9mWhhDCoJJPrlQdXFrcNrd50Z73XHzmrE2O\nPXrTwWn7zK7HTNO0ra2bb3BiJWbvs6LIZrO5d/LQxzmvsqJwXmVF4bzKiiL353zo+5xXyV9x\ncVcXXPZ2MFpUVhlCmNmWrZlf1vRMe3FdWaduH/7jqp+9tOq1N+6Yz5hJklRWVvZomawY0jRt\nbm6uqKhIkqTQtUBXWlpastlsSUlJaWlp972hcLLZbEtLi/9V6fuam5vTNC0tLS0p6e3fZmGp\ntLW1tbe3l5eXF7oQ6EZTU1MIoaysrOsEAQouk8mkaVpW1jlHgiUpKurqPqK9/atkafX4EP76\nSlPbyPJ5Z9tXm9r6b1vXqdtHf3u+dc57Xzlg3wUtd33tkPuqN7r11+cuOmaSJNXV1cuvZvqs\nbDbb3NxcVVXV9VEOBdfW1pYLRp2s6OMymUxra6sDlb6vpaUl96ZIjk8f19zc3Nzc7LxKH5em\naS4YraiokDfRxzU0NGSzWedVekpvB6MVdTsNL7v2z498uMueI0MImYZnH5/Tuv8uq3bqNmbS\n6VP2y+T+nWZnnzT57G3OOP+gIYN6uVoAAAAAYKXU6x8+SsomH7jut288+/5hJ28wIHPHVT+q\nGjZx0mo1IYSpt/7q4cb+R07aK4RQMXTUWkPnPSN3j9G6UaNHr+oPAgAAAABADyjAXZnWOvi8\nY1ouveWS705vTsZstMN53/tq7lPQ0x68584Zq+WCUQAAAACA5SdJ07TQNcCnlM1mZ8yYMXDg\nQPcYpY+rr6/PZDIVFRU1NTWFrgW6kslkZs+ePWiQe9fQ182YMSN3fzH3GKWPy91jtK6u83cq\nQJ+Spun06dNDCP369XOPUfq43D1Ga2trC10IKwlxEgAAAAAQHcEoAAAAABAdwSgAAAAAEB3B\nKAAAAAAQHcEoAAAAABAdwSgAAAAAEB3BKAAAAAAQHcEoAAAAABAdwSgAAAAAEB3BKAAAAAAQ\nHcEoAAAAABAdwSgAAAAAEB3BKAAAAAAQHcEoAAAAABAdwSgAAAAAEB3BKADlOYkAACAASURB\nVAAAAAAQHcEoAAAAABAdwSgAAAAAEJ2SQhcAwNK5++67H3nkkUJXwcopm822tbWVlZUVuhDo\nRmtra5qmJSUlxcXFha4FutLe3p7NZktLSwtdSJ8wefLkgQMHFroKAPiEYBRgBfPKK6/ce++9\nha4CAGDpHHPMMYJRAPoUwSjACqmqqmrjjTcudBUrpKeffrq5uTn374qKik022aSw9QDAym3O\nnDn/+te/Cl0FACyGYBRghTRixIjLL7+80FWskPbee+9333039++BAwdaRgBYrp577rmjjjqq\n0FUAwGL48iUAAAAAIDqCUQAAAAAgOoJRAAAAACA6glEAAAAAIDqCUQAAAAAgOoJRAAAAACA6\nglEAAAAAIDqCUQAAAAAgOoJRAAAAACA6glEAAAAAIDqCUQAAAAAgOoJRAAAAACA6glEAAAAA\nIDqCUQAAAAAgOoJRAAAAACA6glEAAAAAIDqCUQAAAAAgOoJRAAAAACA6glEAAAAAIDqCUQAA\nAAAgOoJRAAAAACA6glEAAAAAIDqCUQAAAAAgOoJRAAAAACA6glEAAAAAIDqCUQAAAAAgOoJR\nAAAAACA6glEAAAAAIDqCUQAAAAAgOoJRAAAAACA6glEAAAAAIDqCUQAAAAAgOoJRAAAAACA6\nglEAAAAAIDqCUQAAAAAgOoJRAAAAACA6glEAAAAAIDqCUQAAAAAgOoJRAAAAACA6glEAAAAA\nIDqCUQAAAAAgOoJRAAAAACA6glEAAAAAIDqCUQAAAAAgOoJRAAAAACA6glEAAAAAIDqCUQAA\nAAAgOoJRAAAAACA6glEAAAAAIDqCUQAAAAAgOoJRAAAAACA6glEAAAAAIDqCUQAAAAAgOoJR\nAAAAACA6glEAAAAAIDqCUQAAAAAgOoJRAAAAACA6glEAAAAAIDqCUQAAAAAgOoJRAAAAACA6\nglEAAAAAIDqCUQAAAAAgOoJRAAAAACA6glEAAAAAIDqCUQAAAAAgOoJRAAAAACA6glEAAAAA\nIDqCUQAAAAAgOoJRAAAAACA6glEAAAAAIDqCUQAAAAAgOoJRAAAAACA6glEAAAAAIDqCUQAA\nAAAgOoJRAAAAACA6JYUuoAekadrY2FjoKiiANE1DCI2NjUmSFLoW6Ep7e3sIoa2traGhYdlH\ny2Qyyz4IAEAva2pq6pHfhVh+mpub/apJH5fJZNI0dTIhf0VFRZWVlUv66coQjIYQstlsoUug\nAHLBaDabFYyyQkjTtEdOVrkjHwBgxZLNZr1x6+N66vdVWH7SNHWgslS6fge9MgSjSZLU1tYW\nugoKIJvNzpgxo6ampqjITSHo0+rr67PZbGlpaU1NzbKPVlZWtuyDAAD0surqam/c+qY0TVta\nWkIIlZWVftWkj2toaMhms04m9BRxEgAAAAAQHcEoAAAAABAdwSgAAAAAEB3BKAAAAAAQHcEo\nAAAAABAdwSgAAAAAEB3BKAAAAAAQHcEoAAAAABAdwSgAAAAAEB3BKAAAAAAQHcEoAAAAABAd\nwSgAAAAAEB3BKAAAAAAQHcEoAAAAABAdwSgAAAAAEB3BKAAAAAAQHcEoAAAAABAdwSgAAAAA\nEB3BKAAAAAAQHcEoAAAAABAdwSgAAAAAEB3BKAAAAAAQHcEoAAAAABAdwSgAAAAAEB3BKAAA\nAAAQHcEoAAAAABAdwSgAAAAAEB3BKAAAAAAQHcEoAAAAABAdwSgAAAAAEB3BKAAAAAAQHcEo\nAAAAABAdwSgAAAAAEB3BKAAAAAAQHcEoAAAAABAdwSgAAAAAEB3BKAAAAAAQHcEoAAAAABAd\nwSgAAAAAEB3BKAAAAAAQHcEoAAAAABAdwSgAAAAAEB3BKAAAAAAQHcEoAAAAABAdwSgAAAAA\nEB3BKAAAAAAQHcEoAAAAABAdwSgAAAAAEB3BKAAAAAAQHcEoAAAAABAdwSgAAAAAEB3BKAAA\nAAAQHcEoAAAAABAdwSgAAAAAEB3BKAAAAAAQHcEoAAAAABAdwSgAAAAAEB3BKAAAAAAQHcEo\nAAAAABAdwSgAAAAAEB3BKAAAAAAQHcEoAAAAABAdwSgAAAAAEB3BKAAAAAAQHcEoAAAAABAd\nwSgAAAAAEB3BKAAAAAAQHcEoAAAAABAdwSgAAAAAEB3BKAAAAAAQHcEoAAAAABAdwSgAAAAA\nEB3BKAAAAAAQHcEoAAAAABAdwSgAAAAAEB3BKAAAAAAQHcEoAAAAABAdwSgAAAAAEB3BKAAA\nAAAQHcEoAAAAABAdwSgAAAAAEB3BKAAAAAAQHcEoAAAAABAdwSgAAAAAEB3BKAAAAAAQHcEo\nAAAAABAdwSgAAAAAEB3BKAAAAAAQHcEoAAAAABAdwSgAAAAAEB3BKAAAAAAQHcEoAAAAABAd\nwSgAAAAAEB3BKAAAAAAQHcEoAAAAABAdwSgAAAAAEB3BKAAAAAAQnZJCTJp96Jar//jXp9+Z\nU7zuuC2OOP7I0VWLKSNtm3nb9dfd8+hz05uLho0cu/dh39htwqq9XysAAAAAsPIpwBWjU3/3\nnUt+89iW+3/1rBMm1bz+wBknXpddXLd7L5h808Mf7H3kN79/7ik7j2m5+uxjb39nbm/XCgAA\nAACsjHr9itG0dcpvXhpzyA8P2mVMCGGti5ODJl1807QjDhtR3bFXe8s71z718Q4X/HCvDQaE\nEMauO/69xw++/ep/73vhlr1dMAAAAACw0untK0Zb6v/6dnP7rruOyD0sr9t2Qk3ZUw+936lb\ne/Obo9Zc83Oj+81vSCb0L8/McsUoAAAAANADevuK0daG50MI61eVLmhZr6rkT8/Xhy8v1K2s\n/3aXXrrdgoeZuS/f8O7cUUeus9gx0zRtaWlZLuXSt6VpGkJoaWlJkqTQtUBXstlsCKG9vb25\nuXnZR2tra1v2QQAAellLS0uP/C5Ej8u9sQohZDKZ3C+u0Ge1tbWlaepkQv6SJCkvL1/ST3s7\nGM22NIQQBpV8cqXq4NLitrldHdBvPXn35ZfdkBm9xxm7r7bYDmmazp3rYtJ4NTQ0FLoEyEsm\nk8lkMj0yzrIPAgDQyxobG71x6+OampoKXQLkxcmE/BUXF/ehYLSorDKEMLMtW1NcnGuZnmkv\nritbbOfWma/ccMXl9zwzY4cD/+f8L+1cseSrAl0wGK00Te19+r4Ff4TvkcPVMQ8ArIiSJPFr\nTJ+V+33VDqLvc6yytLo+Wno7GC2tHh/CX19pahtZPi8YfbWprf+2dYv2nPPWAydNvrJ4/B4X\nXz9pncEVXYxZVFQ0aNCg5VIufVs2m50xY8aAAQOKinr7brmwVOrr6zOZTEVFRU1NzbKPVlHR\n1SkRAKBvqqur88atb0rTdPr06SGE2trasrLFX7cEfURDQ0M2m62trS10IawkejtOqqjbaXhZ\n8Z8f+TD3MNPw7ONzWjfZZdVO3dJs4/mnXF0+8ZtXf/drXaeiAAAAAABLq7evGA1J2eQD1/32\njWffP+zkDQZk7rjqR1XDJk5arSaEMPXWXz3c2P/ISXuFEBo/vOnFxsyR46ueevLJT2qtXGvj\nDRZzbSkAAAAAwFLp9WA0hLUOPu+YlktvueS705uTMRvtcN73vpq7bHXag/fcOWO1XDA657U3\nQwg/+/75HZ/Yb+Tpv7pqy94vGAAAAABYyRQgGA1J8a6Hn7Tr4Z2bt7v6pu3m/3vVbc+/Y9ve\nrQoAAAAAiIavrAEAAAAAoiMYBQAAAACiIxgFAAAAAKIjGAUAAAAAoiMYBQAAAACiIxgFAAAA\nAKIjGAUAAAAAoiMYBQAAAACiIxgFAAAAAKIjGAUAAAAAoiMYBQAAAACiIxgFAAAAAKIjGAUA\nAAAAoiMYBQAAAACiIxgFAAAAAKIjGAUAAAAAoiMYBQAAAACiIxgFAAAAAKIjGAUAAAAAoiMY\nBQAAAACiIxgFAAAAAKIjGAUAAAAAoiMYBQAAAACiIxgFAAAAAKIjGAUAAAAAoiMYBQAAAACi\nIxgFAAAAAKIjGAUAAAAAoiMYBQAAAACiIxgFAAAAAKIjGAUAAAAAoiMYBQAAAACiIxgFAAAA\nAKIjGAUAAAAAoiMYBQAAAACiIxgFAAAAAKIjGAUAAAAAoiMYBQAAAACiIxgFAAAAAKIjGAUA\nAAAAoiMYBQAAAACiIxgFAAAAAKIjGAUAAAAAoiMYBQAAAACiIxgFAAAAAKIjGAUAAAAAoiMY\nBQAAAACiIxgFAAAAAKIjGAUAAAAAoiMYBQAAAACiIxgFAAAAAKIjGAUAAAAAoiMYBQAAAACi\nIxgFAAAAAKIjGAUAAAAAoiMYBQAAAACiIxgFAAAAAKIjGAUAAAAAoiMYBQAAAACiIxgFAAAA\nAKIjGAUAAAAAoiMYBQAAAACiIxgFAAAAAKIjGAUAAAAAoiMYBQAAAACiIxgFAAAAAKIjGAUA\nAAAAoiMYBQAAAACiIxgFAAAAAKIjGAUAAAAAoiMYBQAAAACiIxgFAAAAAKIjGAUAAAAAoiMY\nBQAAAACiIxgFAAAAAKIjGAUAAAAAoiMYBQAAAACiIxgFAAAAAKIjGAUAAAAAoiMYBQAAAACi\nIxgFAAAAAKIjGAUAAAAAoiMYBQAAAACiIxgFAAAAAKIjGAUAAAAAoiMYBQAAAACiIxgFAAAA\nAKIjGAUAAAAAoiMYBQAAAACiIxgFAAAAAKIjGAUAAAAAoiMYBQAAAACiIxgFAAAAAKIjGAUA\nAAAAoiMYBQAAAACiIxgFAAAAAKIjGAUAAAAAolNS6AJ6Rnt7e6FLoACy2WwIob29PU3TQtcC\nXckdomma9sjJygEPAKyI2tvbvXHrmxb8epnNZu0j+rg0TXvqjRWRSJKkqGiJF4auDMFoNpud\nOXNmoaugYOrr6wtdAuSlpaWlpaVl2cdpbm5e9kEAAHrZ7NmzvXHr4+bOnVvoEiAvra2thS6B\n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"
     },
     "metadata": {
      "image/png": {
       "height": 480,
       "width": 900
      }
     },
     "output_type": "display_data"
    }
   ],
   "source": [
    "options(repr.plot.width=15, repr.plot.height=8)\n",
    "validation_sequences %>% select(sequence) %>% mutate(length = str_count(sequence)) %>% \n",
    "    ggplot(aes(x=length)) + geom_boxplot(outliers = FALSE) + \n",
    "    xlab(\"Sequence length\") + ylab(\"Sequence\") + ggtitle(\"Boxplot of sequence length values (without outliers)\") + theme_minimal()\n",
    "\n",
    "# A quick comparison of the two boxplots shows the medians are drastically different for the sequence lengths between validation_sequences and train_sequences"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 15,
   "id": "0fb625e0",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-05-06T17:27:45.826652Z",
     "iopub.status.busy": "2025-05-06T17:27:45.825562Z",
     "iopub.status.idle": "2025-05-06T17:27:45.853758Z",
     "shell.execute_reply": "2025-05-06T17:27:45.852678Z"
    },
    "papermill": {
     "duration": 0.046005,
     "end_time": "2025-05-06T17:27:45.855648",
     "exception": false,
     "start_time": "2025-05-06T17:27:45.809643",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "[1] \"The train_sequences median sequence length is 39.5\"\n"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "[1] \"The validation_sequences median sequence length is 129.5\"\n"
     ]
    }
   ],
   "source": [
    "train_sequence_med <- train_sequences %>% select(sequence) %>% mutate(length = str_count(sequence)) %>% select(length) %>% pull() %>% median()\n",
    "valid_sequence_med <- validation_sequences %>% select(sequence) %>% mutate(length = str_count(sequence)) %>% select(length) %>% pull() %>% median()\n",
    "\n",
    "print(paste('The train_sequences median sequence length is', train_sequence_med))\n",
    "print(paste('The validation_sequences median sequence length is', valid_sequence_med))\n",
    "\n",
    "# That's quite a difference!"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "11f6fe2f",
   "metadata": {
    "papermill": {
     "duration": 0.013003,
     "end_time": "2025-05-06T17:27:45.881888",
     "exception": false,
     "start_time": "2025-05-06T17:27:45.868885",
     "status": "completed"
    },
    "tags": []
   },
   "source": [
    "### validation_labels.csv"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 16,
   "id": "99f5913c",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-05-06T17:27:45.910278Z",
     "iopub.status.busy": "2025-05-06T17:27:45.909184Z",
     "iopub.status.idle": "2025-05-06T17:27:45.971200Z",
     "shell.execute_reply": "2025-05-06T17:27:45.969745Z"
    },
    "papermill": {
     "duration": 0.078266,
     "end_time": "2025-05-06T17:27:45.973100",
     "exception": false,
     "start_time": "2025-05-06T17:27:45.894834",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "[1] \"validation_labels has 2515 rows and 123 columns\"\n"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "[1] \"validation_labels has 0 NAs.\"\n"
     ]
    },
    {
     "data": {
      "text/html": [
       "<table class=\"dataframe\">\n",
       "<caption>A data.frame: 3 × 123</caption>\n",
       "<thead>\n",
       "\t<tr><th></th><th scope=col>ID</th><th scope=col>resname</th><th scope=col>resid</th><th scope=col>x_1</th><th scope=col>y_1</th><th scope=col>z_1</th><th scope=col>x_2</th><th scope=col>y_2</th><th scope=col>z_2</th><th scope=col>x_3</th><th scope=col>⋯</th><th scope=col>z_37</th><th scope=col>x_38</th><th scope=col>y_38</th><th scope=col>z_38</th><th scope=col>x_39</th><th scope=col>y_39</th><th scope=col>z_39</th><th scope=col>x_40</th><th scope=col>y_40</th><th scope=col>z_40</th></tr>\n",
       "\t<tr><th></th><th scope=col>&lt;chr&gt;</th><th scope=col>&lt;chr&gt;</th><th scope=col>&lt;int&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>⋯</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th></tr>\n",
       "</thead>\n",
       "<tbody>\n",
       "\t<tr><th scope=row>1</th><td>R1107_1</td><td>G</td><td>1</td><td>-5.499</td><td> 8.520</td><td> 8.605</td><td>-1e+18</td><td>-1e+18</td><td>-1e+18</td><td>-1e+18</td><td>⋯</td><td>-1e+18</td><td>-1e+18</td><td>-1e+18</td><td>-1e+18</td><td>-1e+18</td><td>-1e+18</td><td>-1e+18</td><td>-1e+18</td><td>-1e+18</td><td>-1e+18</td></tr>\n",
       "\t<tr><th scope=row>2</th><td>R1107_2</td><td>G</td><td>2</td><td>-5.826</td><td>10.453</td><td>14.010</td><td>-1e+18</td><td>-1e+18</td><td>-1e+18</td><td>-1e+18</td><td>⋯</td><td>-1e+18</td><td>-1e+18</td><td>-1e+18</td><td>-1e+18</td><td>-1e+18</td><td>-1e+18</td><td>-1e+18</td><td>-1e+18</td><td>-1e+18</td><td>-1e+18</td></tr>\n",
       "\t<tr><th scope=row>3</th><td>R1107_3</td><td>G</td><td>3</td><td>-5.849</td><td>14.768</td><td>17.585</td><td>-1e+18</td><td>-1e+18</td><td>-1e+18</td><td>-1e+18</td><td>⋯</td><td>-1e+18</td><td>-1e+18</td><td>-1e+18</td><td>-1e+18</td><td>-1e+18</td><td>-1e+18</td><td>-1e+18</td><td>-1e+18</td><td>-1e+18</td><td>-1e+18</td></tr>\n",
       "</tbody>\n",
       "</table>\n"
      ],
      "text/latex": [
       "A data.frame: 3 × 123\n",
       "\\begin{tabular}{r|lllllllllllllllllllll}\n",
       "  & ID & resname & resid & x\\_1 & y\\_1 & z\\_1 & x\\_2 & y\\_2 & z\\_2 & x\\_3 & ⋯ & z\\_37 & x\\_38 & y\\_38 & z\\_38 & x\\_39 & y\\_39 & z\\_39 & x\\_40 & y\\_40 & z\\_40\\\\\n",
       "  & <chr> & <chr> & <int> & <dbl> & <dbl> & <dbl> & <dbl> & <dbl> & <dbl> & <dbl> & ⋯ & <dbl> & <dbl> & <dbl> & <dbl> & <dbl> & <dbl> & <dbl> & <dbl> & <dbl> & <dbl>\\\\\n",
       "\\hline\n",
       "\t1 & R1107\\_1 & G & 1 & -5.499 &  8.520 &  8.605 & -1e+18 & -1e+18 & -1e+18 & -1e+18 & ⋯ & -1e+18 & -1e+18 & -1e+18 & -1e+18 & -1e+18 & -1e+18 & -1e+18 & -1e+18 & -1e+18 & -1e+18\\\\\n",
       "\t2 & R1107\\_2 & G & 2 & -5.826 & 10.453 & 14.010 & -1e+18 & -1e+18 & -1e+18 & -1e+18 & ⋯ & -1e+18 & -1e+18 & -1e+18 & -1e+18 & -1e+18 & -1e+18 & -1e+18 & -1e+18 & -1e+18 & -1e+18\\\\\n",
       "\t3 & R1107\\_3 & G & 3 & -5.849 & 14.768 & 17.585 & -1e+18 & -1e+18 & -1e+18 & -1e+18 & ⋯ & -1e+18 & -1e+18 & -1e+18 & -1e+18 & -1e+18 & -1e+18 & -1e+18 & -1e+18 & -1e+18 & -1e+18\\\\\n",
       "\\end{tabular}\n"
      ],
      "text/markdown": [
       "\n",
       "A data.frame: 3 × 123\n",
       "\n",
       "| <!--/--> | ID &lt;chr&gt; | resname &lt;chr&gt; | resid &lt;int&gt; | x_1 &lt;dbl&gt; | y_1 &lt;dbl&gt; | z_1 &lt;dbl&gt; | x_2 &lt;dbl&gt; | y_2 &lt;dbl&gt; | z_2 &lt;dbl&gt; | x_3 &lt;dbl&gt; | ⋯ ⋯ | z_37 &lt;dbl&gt; | x_38 &lt;dbl&gt; | y_38 &lt;dbl&gt; | z_38 &lt;dbl&gt; | x_39 &lt;dbl&gt; | y_39 &lt;dbl&gt; | z_39 &lt;dbl&gt; | x_40 &lt;dbl&gt; | y_40 &lt;dbl&gt; | z_40 &lt;dbl&gt; |\n",
       "|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|\n",
       "| 1 | R1107_1 | G | 1 | -5.499 |  8.520 |  8.605 | -1e+18 | -1e+18 | -1e+18 | -1e+18 | ⋯ | -1e+18 | -1e+18 | -1e+18 | -1e+18 | -1e+18 | -1e+18 | -1e+18 | -1e+18 | -1e+18 | -1e+18 |\n",
       "| 2 | R1107_2 | G | 2 | -5.826 | 10.453 | 14.010 | -1e+18 | -1e+18 | -1e+18 | -1e+18 | ⋯ | -1e+18 | -1e+18 | -1e+18 | -1e+18 | -1e+18 | -1e+18 | -1e+18 | -1e+18 | -1e+18 | -1e+18 |\n",
       "| 3 | R1107_3 | G | 3 | -5.849 | 14.768 | 17.585 | -1e+18 | -1e+18 | -1e+18 | -1e+18 | ⋯ | -1e+18 | -1e+18 | -1e+18 | -1e+18 | -1e+18 | -1e+18 | -1e+18 | -1e+18 | -1e+18 | -1e+18 |\n",
       "\n"
      ],
      "text/plain": [
       "  ID      resname resid x_1    y_1    z_1    x_2    y_2    z_2    x_3    ⋯\n",
       "1 R1107_1 G       1     -5.499  8.520  8.605 -1e+18 -1e+18 -1e+18 -1e+18 ⋯\n",
       "2 R1107_2 G       2     -5.826 10.453 14.010 -1e+18 -1e+18 -1e+18 -1e+18 ⋯\n",
       "3 R1107_3 G       3     -5.849 14.768 17.585 -1e+18 -1e+18 -1e+18 -1e+18 ⋯\n",
       "  z_37   x_38   y_38   z_38   x_39   y_39   z_39   x_40   y_40   z_40  \n",
       "1 -1e+18 -1e+18 -1e+18 -1e+18 -1e+18 -1e+18 -1e+18 -1e+18 -1e+18 -1e+18\n",
       "2 -1e+18 -1e+18 -1e+18 -1e+18 -1e+18 -1e+18 -1e+18 -1e+18 -1e+18 -1e+18\n",
       "3 -1e+18 -1e+18 -1e+18 -1e+18 -1e+18 -1e+18 -1e+18 -1e+18 -1e+18 -1e+18"
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    }
   ],
   "source": [
    "print(paste('validation_labels has', dim(validation_labels)[1], 'rows and', dim(validation_labels)[2], 'columns'))\n",
    "print(paste('validation_labels has', sum(is.na(validation_labels)), 'NAs.'))\n",
    "# Quick look at the data\n",
    "validation_labels %>% head(3)\n",
    "\n",
    "# Note validation_labels has 123 columns; train_labels has 6"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "29a00e19",
   "metadata": {
    "papermill": {
     "duration": 0.013215,
     "end_time": "2025-05-06T17:27:45.999881",
     "exception": false,
     "start_time": "2025-05-06T17:27:45.986666",
     "status": "completed"
    },
    "tags": []
   },
   "source": [
    "### The number of NAs is misleading; from a discussion post [here](https://www.kaggle.com/competitions/stanford-rna-3d-folding/discussion/565746), the -1e+18 should be interpreted as NA/NaN values.\n",
    "\n",
    "### We will recreate the resname boxplot from train_labels from earlier:"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 17,
   "id": "17a0ffac",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-05-06T17:27:46.029258Z",
     "iopub.status.busy": "2025-05-06T17:27:46.028156Z",
     "iopub.status.idle": "2025-05-06T17:27:46.281735Z",
     "shell.execute_reply": "2025-05-06T17:27:46.280094Z"
    },
    "papermill": {
     "duration": 0.269965,
     "end_time": "2025-05-06T17:27:46.283269",
     "exception": false,
     "start_time": "2025-05-06T17:27:46.013304",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "data": {
      "image/png": "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\nu/PGi397yc33PDlz/kxzsyGd66peefiz6i8bGu595OO8gvIty4sjGn4+uaJ80E+6FSRN/Ut6\n7HTCCSfs3ttt8gAAwDeoLb61s/aL5yOi96S/jr/9gXc/qe69+qBdDz5+p/VWqa16JSLWKv3q\nO8iGlxY89EplfD8Ws6lFdXV13+gQIIcav++ioaHBdQ6smN7622dJXvGovoPerqxtbCnptd6l\n9z140AbdG3/c7Y5bNttg131GbHLEkXv379zw6mO33fJWzVFX/G2Nguycmc9+UpsZOnqNCZee\nev4lt736fkWfNdfddOfv/eqco7s2i0oBYOXln/FAu7GSfqAVFhYualNbBKOZuV9ExEWX/22/\no39wWO/iN57+05Xn/GDupTdtXVcVEd0LvrprtUdhfv3smohomLvITQtraGiorKz8RocAOVdT\nU1NT0/JbACC3/jptTjZTPfTIK+46Zufy+hnPTvjDseOvOGabrdd+88mBHQoiIvLXOurIbf52\n3v2X/t+rjbt0G3Hw97ftU1lZWTPzrYiY+vTYXW/4aKvd9jlq5/K3//XXG//vhw899e7L958l\nGgWgHfDrKtBurIwfaPn5+V27dl3U1rYIRvMK8iNi63PO2WtY14hYc/jIqf/87j2Xv7btcSUR\nUVHfUJaf39hzRl0mv0tRROQVLXITALBCOeiy6/YtGrD1ZoMiImLVbQ4654H8SWNOePLEuz+4\n74BBEfHYubsddNlzOx77f2cfscdqXRpenvjnU8b9bMfN/ve3F27t2VAdEbOn/O+8+/79g437\nRETEebceMfqEey8+/d9H//pbPXM3LAAAoJ1ri2C0oHRIxDNbrt6pqWWjPqVPT/+4sOM6EU+/\nWV3fv3he+vl2dX35Zl0iYjGbFpaXl9e9e/dveBCQM59//nnjqvQlJYtc2AQgh3bd97sLtHQ6\n9MI4YeP3b5/RfdzoutnPH3bF8302v/z+i4/8/PPPI2K7741/Ysi0Pptd+sM/T3/0oAER0WXw\nz8/aZe2m3Y+89rcn3Lv3xCs+7n7PsDYcB0RExPRPc10B0N7k7tfVz3J0XqDdan/5W1sEox26\nfrtrwc2PvlU5bGT3iIhs5qmP5nQaMahDl+F9i658+O/Tttu1f0TUVb303KzavbdbJSI6dNl6\nUZtalCSetaP9c50DK4vC0iER0TA3kyTJnGk3VzdkRx+3Q9OHWJIkvUb/OOLSd295r/i4TfKT\n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\n97kPX+A0A/KGAw3IG530QMtkltvf8iGMNjU1zZkzJ+0pVkaXkl5pjwDkm9mzZ6c9AkArcJoB\necOBBuSNznigZbPZHj16LG83H8JoQUFBM3/CjmxBTdoTAHmnk56HAMtI7TSb9XE61wXyV3o/\nnjnQgFbWGf++2cztokl+hNEkSbLZbNojAHQIzkMgPzjNgLzhQAPyRv4daD58CQAAAAAIRxgF\nAAAAAMIRRgEAAACAcIRRAAAAACAcYRQAAAAACEcYBQAAAADCEUYBAAAAgHCEUQAAAAAgHGEU\nAAAAAAhHGAUAAAAAwhFGAQAAAIBwhFEAAAAAIBxhFAAAAAAIRxgFAAAAAMIRRgEAAACAcIRR\nAAAAACAcYRQAAAAACEcYBQAAAADCEUYBAAAAgHCEUQAAAAAgHGEUAAAAAAhHGAUAAAAAwhFG\nAQAAAIBwhFEAAAAAIBxhFAAAAAAIRxgFAAAAAMIRRgEAAACAcIRRAAAAACAcYRQAAAAACEcY\nBQAAAADCEUYBAAAAgHCEUQAAAAAgHGEUAAAAAAhHGAUAAAAAwhFGAQAAAIBwhFEAAAAAIBxh\nFAAAAAAIRxgFAAAAAMIRRgEAAACAcIRRAAAAACAcYRQAAAAACEcYBQAAAADCEUYBAAAAgHCE\nUQAAAAAgHGEUAAAAAAhHGAUAAAAAwhFGAQAAAIBwhFEAAAAAIBxhFAAAAAAIRxgFAAAAAMIR\nRgEAAACAcIRRAAAAACAcYRQAAAAACEcYBQAAAADCEUYBAAAAgHCEUQAAAAAgHGEUAAAAAAhH\nGAUAAAAAwhFGAQAAAIBwhFEAAAAAIBxhFAAAAAAIRxgFAAAAAMIRRgEAAACAcIRRAAAAACAc\nYRQAAAAACEcYBQAAAADCEUYBAAAAgHCEUQAAAAAgHGEUAAAAAAhHGAUAAAAAwhFGAQAAAIBw\nhFEAAAAAIBxhFAAAAAAIRxgFAAAAAMIRRgEAAACAcIRRAAAAACAcYRQAAAAACEcYBQAAAADC\nEUYBAAAAgHCEUQAAAAAgHGEUAAAAAAhHGAUAAAAAwhFGAQAAAIBwhFEAAAAAIBxhFAAAAAAI\nRxgFAAAAAMIRRgEAAACAcIRRAAAAACAcYRQAAAAACEcYBQAAAADCEUYBAAAAgHCEUQAAAAAg\nHGEUAAAAAAinpWF0+PDhv35n4ZfXP3jyRyN3OKhVRwIAAAAAaFtdmt+e/5/X31/cmCTJ008/\n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\nKAAAAAAQjjAKAAAAAIQjjAIAAAAA4XRJe4BWkMvl5s+fn/YUKyVbkfYEQL6ZN29e2iMAtAKn\nGZA3HGhA3uiMB1pBQUG3bt2Wt5sPYTRJkqKiorRHWBl1jWlPAOSdTnoeAiwjvdOsJqXrAnnL\nj2dA3uiMB1omk2lmNx/CaCaTKS0tTXuKlVG3MO0JgLzTSc9DgGWkd5p1vvsggA7Oj2dA3si/\nA80zRgEAAACAcIRRAAAAACAcYRQAAAAACEcYBQAAAADCEUYBAAAAgHCEUQAAAAAgHGEUAAAA\nAAhHGAUAAAAAwhFGAQAAAIBwhFEAAAAAIBxhFAAAAAAIRxgFAAAAAMIRRgEAAACAcIRRAAAA\nACAcYRQAAAAACEcYBQAAAADCEUYBAAAAgHCEUQAAAAAgHGEUAAAAAAhHGAUAAAAAwhFGAQAA\nAIBwhFEAAAAAIBxhFAAAAAAIRxgFAAAAAMIRRgEAAACAcIRRAAAAACAcYRQAAAAACEcYBQAA\nAADCEUYBAAAAgHCEUQAAAAAgHGEUAAAAAAhHGAUAAAAAwhFGAQAAAIBwhFEAAAAAIBxhFAAA\nAAAIRxgFAAAAAMIRRgEAAACAcIRRAAAAACAcYRQAAAAACEcYBQAAAADCEUYBAAAAgHCEUQAA\nAAAgHGEUAAAAAAhHGAUAAAAAwhFGAQAAAIBwhFEAAAAAIBxhFAAAAAAIRxgFAAAAAMIRRgEA\nAACAcIRRAAAAACAcYRQAAAAACEcYBQAAAADCEUYBAAAAgHCEUQAAAAAgHGEUAAAAAAhHGAUA\nAAAAwhFGAQAAAIBwhFEAAAAAIBxhFAAAAAAIRxgFAAAAAMIRRgEAAACAcIRRAAAAACAcYRQA\nAAAACEcYBQAAAADCEUYBAAAAgHCEUQAAAAAgHGEUAAAAAAhHGAUAAAAAwhFGAQAAAIBwhFEA\nAAAAIBxhFAAAAAAIRxgFAAAAAMIRRgEAAACAcIRRAAAAACAcYRQAAAAACEcYBQAAAADCEUYB\nAAAAgHCEUQAAAAAgHGEUAAAAAAhHGAUAAAAAwhFGAQAAAIBwhFEAAAAAIBxhFAAAAAAIRxgF\nAAAAAMIRRgEAAACAcIRRAAAAACAcYRQAAAAACEcYBQAAAADCEUYBAAAAgHCEUQAAAAAgHGEU\nAAAAAAhHGAUAAAAAwhFGAQAAAIBwhFEAAAAAIBxhFAAAAAAIp0v7XCbXUHXr5Zfd++S/ZtcW\nrNF/vT0OOvK/h/VNkiRJmqZOnnTnY/+cuSA7ZOi3Dj127MCypSM1swUAAAAAsPLa6Y7RB849\n+bpHP9xj7I9+edZPdxhUN2nCMbfNXJgkyYybT71wylNb7X34GccfXP7Gw+NPuKzp05c0swUA\nAAAAsCraI4w21s289JlZI087/Xs7DF9vyCb7HHPuzpXZ2ya9kOQWXzDl5UH7n7nvTsM3+ubI\n484bV/3+/de9W50kSXNbAAAAAACrpl3CaO2bA9ZZ5zsDu3+6kBlWUVw/d2HdvMferm3ceee1\nlqwWV44YVl70zNQPkiRpZgsAAAAAYBW1x1M7iypGXnTRyKVf1i+cfuV7CweMHby4+sYkSTYs\nK1y6tUFZl/uen5eMSRZXP7+8rS/L5XILFy5su/nbUKZb2hMA+WbBggVpjwDQCpxmQN5woAF5\nozMeaJlMpry8fHm77f1xRm9Nu+c3F19ZP3C38bv2a3irOkmSnl0+u2u1V2G2YWFtkiRNdcvd\n+rJcLldXV9e2c7eNLiXCKNDKOul5CLAMpxmQNxxoQN7ojAdaNpttZrf9wujiqleuvOQ39z47\nZ9tRR51zwA4lmcyCotIkSaoamso/HXF2fWO2sihJkoLlb31ZJpMpLi5ujz9Da2tMewAg/3TS\n8xBgGemdZg0pXRfIW348A/JGZzzQMplMM7vtFEYXvPXwSSf/NrvxbuddfvDgXiVLFgu7bpwk\nj71S09C/+JP6+VpNQ8WIyua3viyTyXTr1ilvvZzbOR8AAHRknfQ8BFhGeqeZT/sEWpkfz4C8\nkX8HWnt8+FKuadE5P51UvOOPJp3+w6VVNEmSksrt1yzK3v/ER0u+rK9+7u8LFm++U9/mtwAA\nAAAAVlF73DG66KPrXlpUP3bjsmemTfvswqXrbrZR5cmjhvz46gkPrfGTjXrU3zHx/LI1djy4\nX3mSJEmmaLlbAAAAAACrpj3C6ILX30yS5KpfnvP5xe79f3btxK3WHX320XUXTb7w9Nm1mUGb\nbnv2mYcvvYW1mS0AAAAAgFWRyeVyac8Ql2eMAq2uMqV76weeeE86Fwby1IwLvpPKdf8y/YNU\nrgvksR2GpPNQuHG3vpzKdYE89tu9Nkh7hFbmLkwAAAAAIBxhFAAAAAAIRxgFAAAAAMIRRgEA\nAACAcIRRAAAAACAcYRQAAAAACEcYBQAAAADCEUYBAAAAgHCEUQAAAAAgHGEUAAAAAAhHGAUA\nAAAAwhFGAQAAAIBwhFEAAAAAIBxhFAAAAAAIRxgFAAAAAMIRRgEAAACAcIRRAAAAACAcYRQA\nAAAACEcYBQAAAADCEUYBAAAAgHCEUQAAAAAgHGEUAAAAAAhHGAUAAAAAwhFGAQAAAIBwhFEA\nAAAAIBxhFAAAAAAIRxgFAAAAAMIRRgEAAACAcIRRAAAAACAcYRQAAAAACEcYBQAAAADCEUYB\nAAAAgHCEUQAAAAAgHGEUAAAAAAhHGAUAAAAAwhFGAQAAAIBwhFEAAAAAIBxhFAAAAAAIRxgF\nAAAAAMIRRgEAAACAcIRRAAAAACAcYRQAAAAACEcYBQAAAADCEUYBAAAAgHCEUQAAAAAgHGEU\nAAAAAAhHGAUAAAAAwhFGAQAAAIBwhFEAAAAAIBxhFAAAAAAIRxgFAAAAAMIRRgEAAACAcIRR\nAAAAACAcYRQAAAAACEcYBQAAAADCEUYBAAAAgHCEUQAAAAAgHGEUAAAAAAhHGAUAAAAAwhFG\nAQAAAIBwhFEAAAAAIBxhFAAAAAAIRxgFAAAAAMIRRgEAAACAcIRRAAAAACAcYRQAAAAACEcY\nBQAAAADCEUYBAAAAgHCEUQAAAAAgHGEUAAAAAAhHGAUAAAAAwhFGAQAAAIBwhFEAAAAAIBxh\nFAAAAAAIRxgFAAAAAMIRRgEAAACAcIRRAAAAACAcYRQAAAAACEcYBQAAAADCEUYBAAAAgHCE\nUQAAAAAgHGEUAAAAAAhHGAUAAAAAwhFGAQAAAIBwhFEAAAAAIBxhFAAAAAAIRxgFAAAAAMIR\nRgEAAACAcIRRAAAAACAcYRQAAAAACEcYBQAAAADCEUYBAAAAgHCEUQAAAAAgHGEUAAAAAAhH\nGAUAAAAAwumS9gCtIJfL1dXVpT3FyilJewAg39TW1qY9AkArcJoBecOBBuSNznigZTKZ4uLi\n5e3mQxhNkqSzhtGsMAq0ss56HgJ8kdMMyBsONCBvdMYDraCgIM/DaCaTqaioSHuKlTF3YdoT\nAHmnk56HAMtI7TR7vyad6wL5K70fz95L6bpA3sq/v296xigAAAAAEI4wCgAAAACEI4wCAAAA\nAOEIowAAAABAOMIoAAAAABCOMAoAAAAAhCOMAgAAAADhCKMAAAAAQDjCKAAAAAAQjjAKAAAA\nAIQjjAIAAAAA4QijAAAAAEA4wigAAAAAEI4wCgAAAACEI4wCAAAAAOEIowAAAABAOMIoAAAA\n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"
     },
     "metadata": {
      "image/png": {
       "height": 480,
       "width": 900
      }
     },
     "output_type": "display_data"
    }
   ],
   "source": [
    "options(repr.plot.width=15, repr.plot.height=8)\n",
    "validation_labels %>% group_by(resname) %>% summarize(total = n()) %>% \n",
    "    ggplot(aes(x=reorder(resname, total), y=total)) + geom_col(aes(fill=resname)) + geom_text(aes(label = total), vjust = -0.5) +  scale_fill_brewer(palette = \"Blues\") + \n",
    "    xlab(\"Resname\") + ylab(\"Count\") + ggtitle(\"Barplot of resname occurrences in valid_labels\") + guides(fill=\"none\") + theme_minimal()\n",
    "\n",
    "# Note there are no missing or 'X' resnames.  Also of note is in this datset, 'U' occurs more frequently than 'A'.  'C' and 'G' maintain their ordering."
   ]
  },
  {
   "cell_type": "markdown",
   "id": "9d67edb4",
   "metadata": {
    "papermill": {
     "duration": 0.013709,
     "end_time": "2025-05-06T17:27:46.311564",
     "exception": false,
     "start_time": "2025-05-06T17:27:46.297855",
     "status": "completed"
    },
    "tags": []
   },
   "source": [
    "### Submission format"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 18,
   "id": "1d5d926b",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-05-06T17:27:46.342736Z",
     "iopub.status.busy": "2025-05-06T17:27:46.341453Z",
     "iopub.status.idle": "2025-05-06T17:27:46.392281Z",
     "shell.execute_reply": "2025-05-06T17:27:46.390950Z"
    },
    "papermill": {
     "duration": 0.068312,
     "end_time": "2025-05-06T17:27:46.393959",
     "exception": false,
     "start_time": "2025-05-06T17:27:46.325647",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "[1] \"There are  2515 rows and 18 columns.\"\n"
     ]
    },
    {
     "data": {
      "text/html": [
       "<table class=\"dataframe\">\n",
       "<caption>A data.frame: 6 × 18</caption>\n",
       "<thead>\n",
       "\t<tr><th></th><th scope=col>ID</th><th scope=col>resname</th><th scope=col>resid</th><th scope=col>x_1</th><th scope=col>y_1</th><th scope=col>z_1</th><th scope=col>x_2</th><th scope=col>y_2</th><th scope=col>z_2</th><th scope=col>x_3</th><th scope=col>y_3</th><th scope=col>z_3</th><th scope=col>x_4</th><th scope=col>y_4</th><th scope=col>z_4</th><th scope=col>x_5</th><th scope=col>y_5</th><th scope=col>z_5</th></tr>\n",
       "\t<tr><th></th><th scope=col>&lt;chr&gt;</th><th scope=col>&lt;chr&gt;</th><th scope=col>&lt;int&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th></tr>\n",
       "</thead>\n",
       "<tbody>\n",
       "\t<tr><th scope=row>1</th><td>R1107_1</td><td>G</td><td>1</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td></tr>\n",
       "\t<tr><th scope=row>2</th><td>R1107_2</td><td>G</td><td>2</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td></tr>\n",
       "\t<tr><th scope=row>3</th><td>R1107_3</td><td>G</td><td>3</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td></tr>\n",
       "\t<tr><th scope=row>4</th><td>R1107_4</td><td>G</td><td>4</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td></tr>\n",
       "\t<tr><th scope=row>5</th><td>R1107_5</td><td>G</td><td>5</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td></tr>\n",
       "\t<tr><th scope=row>6</th><td>R1107_6</td><td>C</td><td>6</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td><td>0</td></tr>\n",
       "</tbody>\n",
       "</table>\n"
      ],
      "text/latex": [
       "A data.frame: 6 × 18\n",
       "\\begin{tabular}{r|llllllllllllllllll}\n",
       "  & ID & resname & resid & x\\_1 & y\\_1 & z\\_1 & x\\_2 & y\\_2 & z\\_2 & x\\_3 & y\\_3 & z\\_3 & x\\_4 & y\\_4 & z\\_4 & x\\_5 & y\\_5 & z\\_5\\\\\n",
       "  & <chr> & <chr> & <int> & <dbl> & <dbl> & <dbl> & <dbl> & <dbl> & <dbl> & <dbl> & <dbl> & <dbl> & <dbl> & <dbl> & <dbl> & <dbl> & <dbl> & <dbl>\\\\\n",
       "\\hline\n",
       "\t1 & R1107\\_1 & G & 1 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0\\\\\n",
       "\t2 & R1107\\_2 & G & 2 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0\\\\\n",
       "\t3 & R1107\\_3 & G & 3 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0\\\\\n",
       "\t4 & R1107\\_4 & G & 4 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0\\\\\n",
       "\t5 & R1107\\_5 & G & 5 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0\\\\\n",
       "\t6 & R1107\\_6 & C & 6 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0 & 0\\\\\n",
       "\\end{tabular}\n"
      ],
      "text/markdown": [
       "\n",
       "A data.frame: 6 × 18\n",
       "\n",
       "| <!--/--> | ID &lt;chr&gt; | resname &lt;chr&gt; | resid &lt;int&gt; | x_1 &lt;dbl&gt; | y_1 &lt;dbl&gt; | z_1 &lt;dbl&gt; | x_2 &lt;dbl&gt; | y_2 &lt;dbl&gt; | z_2 &lt;dbl&gt; | x_3 &lt;dbl&gt; | y_3 &lt;dbl&gt; | z_3 &lt;dbl&gt; | x_4 &lt;dbl&gt; | y_4 &lt;dbl&gt; | z_4 &lt;dbl&gt; | x_5 &lt;dbl&gt; | y_5 &lt;dbl&gt; | z_5 &lt;dbl&gt; |\n",
       "|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|\n",
       "| 1 | R1107_1 | G | 1 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |\n",
       "| 2 | R1107_2 | G | 2 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |\n",
       "| 3 | R1107_3 | G | 3 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |\n",
       "| 4 | R1107_4 | G | 4 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |\n",
       "| 5 | R1107_5 | G | 5 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |\n",
       "| 6 | R1107_6 | C | 6 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |\n",
       "\n"
      ],
      "text/plain": [
       "  ID      resname resid x_1 y_1 z_1 x_2 y_2 z_2 x_3 y_3 z_3 x_4 y_4 z_4 x_5 y_5\n",
       "1 R1107_1 G       1     0   0   0   0   0   0   0   0   0   0   0   0   0   0  \n",
       "2 R1107_2 G       2     0   0   0   0   0   0   0   0   0   0   0   0   0   0  \n",
       "3 R1107_3 G       3     0   0   0   0   0   0   0   0   0   0   0   0   0   0  \n",
       "4 R1107_4 G       4     0   0   0   0   0   0   0   0   0   0   0   0   0   0  \n",
       "5 R1107_5 G       5     0   0   0   0   0   0   0   0   0   0   0   0   0   0  \n",
       "6 R1107_6 C       6     0   0   0   0   0   0   0   0   0   0   0   0   0   0  \n",
       "  z_5\n",
       "1 0  \n",
       "2 0  \n",
       "3 0  \n",
       "4 0  \n",
       "5 0  \n",
       "6 0  "
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    }
   ],
   "source": [
    "# This is our submission format\n",
    "sample_submission <- read.csv('/kaggle/input/stanford-rna-3d-folding/sample_submission.csv')\n",
    "print(paste('There are ',dim(sample_submission)[1], 'rows and',dim(sample_submission)[2], 'columns.'))\n",
    "sample_submission %>% head(6)\n",
    "\n",
    "# Note: It is required to submit 5 sets of coordinate plots (x,y,z), per ID, resname & resid from the target_id, which is 18 columns.\n",
    "# For rows in the submission, we need one row for each resname/resid for each target\n",
    "# From the sample submission, we need 2515 rows"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "0748d2e0",
   "metadata": {
    "papermill": {
     "duration": 0.014696,
     "end_time": "2025-05-06T17:27:46.424518",
     "exception": false,
     "start_time": "2025-05-06T17:27:46.409822",
     "status": "completed"
    },
    "tags": []
   },
   "source": [
    "### Generating the output file from test_sequence"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 19,
   "id": "b4c8f074",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-05-06T17:27:46.456112Z",
     "iopub.status.busy": "2025-05-06T17:27:46.454943Z",
     "iopub.status.idle": "2025-05-06T17:27:46.474957Z",
     "shell.execute_reply": "2025-05-06T17:27:46.473432Z"
    },
    "papermill": {
     "duration": 0.03773,
     "end_time": "2025-05-06T17:27:46.476656",
     "exception": false,
     "start_time": "2025-05-06T17:27:46.438926",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "[1] \"There are  12 rows and 5 columns.\"\n"
     ]
    }
   ],
   "source": [
    "test_sequences <- read.csv('/kaggle/input/stanford-rna-3d-folding/test_sequences.csv')\n",
    "print(paste('There are ',dim(test_sequences)[1], 'rows and',dim(test_sequences)[2], 'columns.'))\n",
    "\n",
    "# Reading in the test sequences, we can see we have 12 x rows and the same 5 x columns found in train & validation sequences."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 20,
   "id": "fb47da5a",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-05-06T17:27:46.508450Z",
     "iopub.status.busy": "2025-05-06T17:27:46.507055Z",
     "iopub.status.idle": "2025-05-06T17:27:46.523528Z",
     "shell.execute_reply": "2025-05-06T17:27:46.522276Z"
    },
    "papermill": {
     "duration": 0.033859,
     "end_time": "2025-05-06T17:27:46.525088",
     "exception": false,
     "start_time": "2025-05-06T17:27:46.491229",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "data": {
      "text/html": [
       "2515"
      ],
      "text/latex": [
       "2515"
      ],
      "text/markdown": [
       "2515"
      ],
      "text/plain": [
       "[1] 2515"
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    }
   ],
   "source": [
    "# By summing each sequence length (equivalent to one resname/resid), for the entire test_sequences, we can arrive at our number of 2515.\n",
    "test_sequences %>% mutate(length = nchar(sequence)) %>% select(length) %>% sum(.)\n",
    "\n",
    "# Now, we need to create the df to house our submission"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 21,
   "id": "0b1e995f",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-05-06T17:27:46.558425Z",
     "iopub.status.busy": "2025-05-06T17:27:46.557105Z",
     "iopub.status.idle": "2025-05-06T17:27:46.597844Z",
     "shell.execute_reply": "2025-05-06T17:27:46.596664Z"
    },
    "papermill": {
     "duration": 0.059598,
     "end_time": "2025-05-06T17:27:46.599483",
     "exception": false,
     "start_time": "2025-05-06T17:27:46.539885",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "[1] \"There are 2515 rows in the test_clean df.\"\n"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "     ID resname resid\n",
      "1 R1107       G     1\n",
      "2 R1107       G     2\n",
      "3 R1107       G     3\n",
      "4 R1107       G     4\n",
      "5 R1107       G     5\n",
      "6 R1107       C     6\n"
     ]
    }
   ],
   "source": [
    "# This function will accept a test_sequence ID & sequence and return df in format of submission (one resid/resname per row in sequence)\n",
    "parse_target <- function(tmp_ID, tmp_sequence){\n",
    "    seq_length <- nchar(tmp_sequence)\n",
    "    tmp_df=data.frame(matrix(ncol = 3, nrow = seq_length)) \n",
    "    colnames(tmp_df) <- c('ID','resname','resid')\n",
    "    tmp_df$resname <- unlist(strsplit(tmp_sequence,split=''))\n",
    "    tmp_df$ID <- tmp_ID\n",
    "    tmp_df$resid <- seq(1:seq_length)\n",
    "\n",
    "    return(tmp_df)\n",
    "}\n",
    "# Create the test_clean df in the format of the submission\n",
    "test_id_seq <- test_sequences %>% select(target_id, sequence)\n",
    "test_clean <- data.frame(matrix(ncol = 3, nrow = 0)) \n",
    "colnames(test_clean) <- c('ID','resname','resid')\n",
    "\n",
    "# For each target_id / sequence, apply the function and rbind to previous results\n",
    "for(i in 1:nrow(test_id_seq)){\n",
    "    tmp_df <- as.data.frame(mapply(parse_target,test_id_seq$target_id[i],test_id_seq$sequence[i], SIMPLIFY=FALSE))\n",
    "    colnames(tmp_df) <- c('ID','resname','resid')\n",
    "    test_clean <- rbind(test_clean,tmp_df)\n",
    "}\n",
    "\n",
    "print(paste('There are',nrow(test_clean),'rows in the test_clean df.'))\n",
    "print(head(test_clean))\n",
    "\n",
    "# That works...now let's get back to the training data, add some features, & train a model."
   ]
  },
  {
   "cell_type": "markdown",
   "id": "a45808c0",
   "metadata": {
    "papermill": {
     "duration": 0.014675,
     "end_time": "2025-05-06T17:27:46.629029",
     "exception": false,
     "start_time": "2025-05-06T17:27:46.614354",
     "status": "completed"
    },
    "tags": []
   },
   "source": [
    "# 🎯 Model Training"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 22,
   "id": "b4d76b02",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-05-06T17:27:46.660319Z",
     "iopub.status.busy": "2025-05-06T17:27:46.659181Z",
     "iopub.status.idle": "2025-05-06T17:27:49.991816Z",
     "shell.execute_reply": "2025-05-06T17:27:49.990167Z"
    },
    "papermill": {
     "duration": 3.364098,
     "end_time": "2025-05-06T17:27:50.007204",
     "exception": false,
     "start_time": "2025-05-06T17:27:46.643106",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "[1] \"There are  0 NA's in the dataset!\"\n"
     ]
    }
   ],
   "source": [
    "# Function to create some features based off resname combinations & sequence length\n",
    "feat_eng <- function(df){\n",
    "    df <- df %>% mutate(seq_length = nchar(sequence), \n",
    "               A_cnt = str_count(sequence,\"A\"), \n",
    "               C_cnt = str_count(sequence,\"C\"), \n",
    "               U_cnt = str_count(sequence,\"U\"), \n",
    "               G_cnt = str_count(sequence,\"G\"),                  \n",
    "               AC_cnt = str_count(sequence,\"AC\"), \n",
    "               AU_cnt = str_count(sequence,\"AU\"), \n",
    "               AG_cnt = str_count(sequence,\"AG\"),\n",
    "               CA_cnt = str_count(sequence,\"CA\"), \n",
    "               CU_cnt = str_count(sequence,\"CU\"), \n",
    "               CG_cnt = str_count(sequence,\"CG\"),\n",
    "               UA_cnt = str_count(sequence,\"UA\"), \n",
    "               UC_cnt = str_count(sequence,\"UC\"), \n",
    "               UG_cnt = str_count(sequence,\"UG\"),\n",
    "               GA_cnt = str_count(sequence,\"GA\"), \n",
    "               GC_cnt = str_count(sequence,\"GC\"), \n",
    "               GU_cnt = str_count(sequence,\"GU\"), \n",
    "               AA_cnt = str_count(sequence,\"AA\"), \n",
    "               CC_cnt = str_count(sequence,\"CC\"), \n",
    "               UU_cnt = str_count(sequence,\"UU\"), \n",
    "               GG_cnt = str_count(sequence,\"GG\"),\n",
    "               begin_seq = substr(sequence,1,1),\n",
    "               end_seq = substr(sequence,nchar(sequence),nchar(sequence))) %>% select(-c(sequence, temporal_cutoff, description, all_sequences))\n",
    "    return(df)\n",
    "}\n",
    "train_sequences <- feat_eng(train_sequences)\n",
    "\n",
    "# Create the target_id from ID to facilitate joining with the meta_train data we just created\n",
    "train_labels <- train_labels %>% group_by(ID) %>% mutate(target_id = paste(unlist(strsplit(ID,'_'))[1],unlist(strsplit(ID,'_'))[2],sep='_'))\n",
    "\n",
    "# Create the final df to train\n",
    "train_data_clean <- merge(train_labels, train_sequences, by=\"target_id\", all.x = TRUE)\n",
    "\n",
    "# For now, we will impute the missing x_1,y_1,z_1 values with the group average for that target_id, resname\n",
    "train_data_clean <- train_data_clean %>% group_by(target_id, resname) %>% mutate(x_1 = ifelse(is.na(x_1),mean(x_1, na.rm=TRUE),x_1), y_1 = ifelse(is.na(y_1),mean(y_1, na.rm=TRUE),y_1), z_1 = ifelse(is.na(z_1),mean(z_1, na.rm=TRUE),z_1)) %>% ungroup() %>% select(-target_id)\n",
    "\n",
    "# The above imputation for train_data_clean doesn't take care of all NAs...so for now we will remove them(~ 1979 rows)\n",
    "train_data_clean <- train_data_clean %>% na.exclude() \n",
    "print(paste('There are ',sum(is.na(train_data_clean)),\"NA's in the dataset!\"))"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 23,
   "id": "c1ebd317",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-05-06T17:27:50.039831Z",
     "iopub.status.busy": "2025-05-06T17:27:50.038605Z",
     "iopub.status.idle": "2025-05-06T17:27:50.050904Z",
     "shell.execute_reply": "2025-05-06T17:27:50.049604Z"
    },
    "papermill": {
     "duration": 0.030433,
     "end_time": "2025-05-06T17:27:50.052505",
     "exception": false,
     "start_time": "2025-05-06T17:27:50.022072",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [],
   "source": [
    "features <- train_data_clean %>% select(-c(x_1,y_1,z_1, ID)) %>% colnames()  "
   ]
  },
  {
   "cell_type": "markdown",
   "id": "2685a54e",
   "metadata": {
    "papermill": {
     "duration": 0.013797,
     "end_time": "2025-05-06T17:27:50.080888",
     "exception": false,
     "start_time": "2025-05-06T17:27:50.067091",
     "status": "completed"
    },
    "tags": []
   },
   "source": [
    "### For now, our model approach will consist of 3 separate models for x,y,z values"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 24,
   "id": "f4503b97",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-05-06T17:27:50.111320Z",
     "iopub.status.busy": "2025-05-06T17:27:50.110190Z",
     "iopub.status.idle": "2025-05-06T18:29:15.606774Z",
     "shell.execute_reply": "2025-05-06T18:29:15.605353Z"
    },
    "papermill": {
     "duration": 3685.513591,
     "end_time": "2025-05-06T18:29:15.608305",
     "exception": false,
     "start_time": "2025-05-06T17:27:50.094714",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |                                                                      |   0%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |======================================================================| 100%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\n"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |                                                                      |   0%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |                                                                      |   1%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=                                                                     |   1%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=                                                                     |   2%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==                                                                    |   2%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==                                                                    |   3%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===                                                                   |   4%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===                                                                   |   5%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |====                                                                  |   5%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |====                                                                  |   6%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=====                                                                 |   6%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=====                                                                 |   7%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=====                                                                 |   8%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |======                                                                |   8%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |======                                                                |   9%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=======                                                               |  10%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=======                                                               |  11%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |========                                                              |  11%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |========                                                              |  12%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=========                                                             |  12%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=========                                                             |  13%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==========                                                            |  14%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==========                                                            |  15%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===========                                                           |  15%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===========                                                           |  16%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |============                                                          |  16%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |============                                                          |  17%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |============                                                          |  18%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=============                                                         |  18%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=============                                                         |  19%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==============                                                        |  19%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==============                                                        |  20%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===============                                                       |  21%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===============                                                       |  22%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |================                                                      |  22%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |================                                                      |  23%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |================                                                      |  24%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=================                                                     |  24%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=================                                                     |  25%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==================                                                    |  25%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==================                                                    |  26%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===================                                                   |  27%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===================                                                   |  28%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |====================                                                  |  28%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |====================                                                  |  29%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=====================                                                 |  29%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=====================                                                 |  30%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=====================                                                 |  31%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |======================                                                |  31%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |======================                                                |  32%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=======================                                               |  32%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=======================                                               |  33%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=======================                                               |  34%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |========================                                              |  34%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |========================                                              |  35%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=========================                                             |  35%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=========================                                             |  36%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==========================                                            |  37%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==========================                                            |  38%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===========================                                           |  38%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===========================                                           |  39%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |============================                                          |  39%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |============================                                          |  40%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |============================                                          |  41%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=============================                                         |  41%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=============================                                         |  42%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==============================                                        |  42%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==============================                                        |  43%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===============================                                       |  44%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===============================                                       |  45%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |================================                                      |  45%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |================================                                      |  46%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=================================                                     |  47%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=================================                                     |  48%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==================================                                    |  48%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==================================                                    |  49%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===================================                                   |  49%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===================================                                   |  50%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===================================                                   |  51%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |====================================                                  |  51%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |====================================                                  |  52%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=====================================                                 |  52%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=====================================                                 |  53%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=====================================                                 |  54%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |======================================                                |  54%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |======================================                                |  55%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=======================================                               |  55%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=======================================                               |  56%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |========================================                              |  57%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |========================================                              |  58%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=========================================                             |  58%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=========================================                             |  59%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==========================================                            |  59%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==========================================                            |  60%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==========================================                            |  61%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===========================================                           |  61%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===========================================                           |  62%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |============================================                          |  62%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |============================================                          |  63%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=============================================                         |  64%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=============================================                         |  65%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==============================================                        |  65%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==============================================                        |  66%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===============================================                       |  67%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===============================================                       |  68%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |================================================                      |  68%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |================================================                      |  69%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=================================================                     |  69%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=================================================                     |  70%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=================================================                     |  71%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==================================================                    |  71%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==================================================                    |  72%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===================================================                   |  72%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===================================================                   |  73%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |====================================================                  |  74%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |====================================================                  |  75%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=====================================================                 |  75%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=====================================================                 |  76%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |======================================================                |  77%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |======================================================                |  78%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=======================================================               |  78%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=======================================================               |  79%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |========================================================              |  80%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |========================================================              |  81%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=========================================================             |  81%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=========================================================             |  82%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==========================================================            |  82%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==========================================================            |  83%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==========================================================            |  84%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===========================================================           |  84%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===========================================================           |  85%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |============================================================          |  85%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |============================================================          |  86%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=============================================================         |  87%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=============================================================         |  88%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==============================================================        |  88%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==============================================================        |  89%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===============================================================       |  89%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===============================================================       |  90%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===============================================================       |  91%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |================================================================      |  91%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |================================================================      |  92%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=================================================================     |  92%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=================================================================     |  93%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==================================================================    |  94%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==================================================================    |  95%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===================================================================   |  95%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===================================================================   |  96%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |====================================================================  |  96%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |====================================================================  |  97%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |====================================================================  |  98%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===================================================================== |  98%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===================================================================== |  99%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |======================================================================|  99%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |======================================================================| 100%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\n"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "[1] 44.19813\n"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |                                                                      |   0%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |======================================================================| 100%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\n"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |                                                                      |   0%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |                                                                      |   1%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=                                                                     |   1%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=                                                                     |   2%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==                                                                    |   2%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==                                                                    |   3%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===                                                                   |   4%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===                                                                   |   5%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |====                                                                  |   5%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |====                                                                  |   6%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=====                                                                 |   7%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=====                                                                 |   8%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |======                                                                |   8%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |======                                                                |   9%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=======                                                               |   9%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=======                                                               |  10%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=======                                                               |  11%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |========                                                              |  11%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |========                                                              |  12%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=========                                                             |  12%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=========                                                             |  13%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=========                                                             |  14%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==========                                                            |  14%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==========                                                            |  15%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===========                                                           |  15%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===========                                                           |  16%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |============                                                          |  16%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |============                                                          |  17%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |============                                                          |  18%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=============                                                         |  18%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=============                                                         |  19%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==============                                                        |  19%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==============                                                        |  20%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==============                                                        |  21%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===============                                                       |  21%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===============                                                       |  22%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |================                                                      |  22%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |================                                                      |  23%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |================                                                      |  24%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=================                                                     |  24%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=================                                                     |  25%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==================                                                    |  25%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==================                                                    |  26%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===================                                                   |  27%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===================                                                   |  28%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |====================                                                  |  28%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |====================                                                  |  29%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=====================                                                 |  29%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=====================                                                 |  30%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=====================                                                 |  31%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |======================                                                |  31%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |======================                                                |  32%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=======================                                               |  32%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=======================                                               |  33%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=======================                                               |  34%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |========================                                              |  34%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |========================                                              |  35%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=========================                                             |  35%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=========================                                             |  36%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==========================                                            |  36%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==========================                                            |  37%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==========================                                            |  38%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===========================                                           |  38%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===========================                                           |  39%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |============================                                          |  39%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |============================                                          |  40%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |============================                                          |  41%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=============================                                         |  41%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=============================                                         |  42%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==============================                                        |  42%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==============================                                        |  43%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==============================                                        |  44%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===============================                                       |  44%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===============================                                       |  45%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |================================                                      |  45%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |================================                                      |  46%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=================================                                     |  46%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=================================                                     |  47%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=================================                                     |  48%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==================================                                    |  48%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==================================                                    |  49%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===================================                                   |  49%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===================================                                   |  50%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |====================================                                  |  51%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |====================================                                  |  52%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=====================================                                 |  52%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=====================================                                 |  53%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |======================================                                |  54%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |======================================                                |  55%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=======================================                               |  55%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=======================================                               |  56%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |========================================                              |  56%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |========================================                              |  57%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |========================================                              |  58%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=========================================                             |  58%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=========================================                             |  59%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==========================================                            |  59%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==========================================                            |  60%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==========================================                            |  61%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===========================================                           |  61%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===========================================                           |  62%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |============================================                          |  62%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |============================================                          |  63%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=============================================                         |  64%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=============================================                         |  65%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==============================================                        |  65%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==============================================                        |  66%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===============================================                       |  66%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===============================================                       |  67%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===============================================                       |  68%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |================================================                      |  68%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |================================================                      |  69%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=================================================                     |  70%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=================================================                     |  71%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==================================================                    |  71%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==================================================                    |  72%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===================================================                   |  72%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===================================================                   |  73%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |====================================================                  |  74%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |====================================================                  |  75%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=====================================================                 |  75%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=====================================================                 |  76%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |======================================================                |  76%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |======================================================                |  77%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |======================================================                |  78%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=======================================================               |  78%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=======================================================               |  79%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |========================================================              |  79%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |========================================================              |  80%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=========================================================             |  81%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=========================================================             |  82%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==========================================================            |  82%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==========================================================            |  83%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==========================================================            |  84%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===========================================================           |  84%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===========================================================           |  85%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |============================================================          |  85%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |============================================================          |  86%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=============================================================         |  87%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=============================================================         |  88%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==============================================================        |  88%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==============================================================        |  89%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===============================================================       |  89%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===============================================================       |  90%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===============================================================       |  91%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |================================================================      |  91%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |================================================================      |  92%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=================================================================     |  92%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=================================================================     |  93%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=================================================================     |  94%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==================================================================    |  94%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==================================================================    |  95%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===================================================================   |  95%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===================================================================   |  96%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |====================================================================  |  97%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |====================================================================  |  98%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===================================================================== |  98%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===================================================================== |  99%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |======================================================================|  99%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |======================================================================| 100%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\n"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "[1] 75.47626\n"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |                                                                      |   0%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |======================================================================| 100%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\n"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |                                                                      |   0%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |                                                                      |   1%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=                                                                     |   1%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=                                                                     |   2%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==                                                                    |   2%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==                                                                    |   3%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===                                                                   |   4%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===                                                                   |   5%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |====                                                                  |   5%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |====                                                                  |   6%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=====                                                                 |   6%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=====                                                                 |   7%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=====                                                                 |   8%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |======                                                                |   8%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |======                                                                |   9%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=======                                                               |   9%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=======                                                               |  10%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=======                                                               |  11%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |========                                                              |  11%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |========                                                              |  12%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=========                                                             |  12%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=========                                                             |  13%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=========                                                             |  14%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==========                                                            |  14%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==========                                                            |  15%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===========                                                           |  15%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===========                                                           |  16%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |============                                                          |  17%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |============                                                          |  18%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=============                                                         |  18%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=============                                                         |  19%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==============                                                        |  19%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==============                                                        |  20%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==============                                                        |  21%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===============                                                       |  21%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===============                                                       |  22%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |================                                                      |  22%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |================                                                      |  23%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |================                                                      |  24%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=================                                                     |  24%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=================                                                     |  25%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==================                                                    |  25%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==================                                                    |  26%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===================                                                   |  26%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===================                                                   |  27%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===================                                                   |  28%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |====================                                                  |  28%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |====================                                                  |  29%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=====================                                                 |  29%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=====================                                                 |  30%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=====================                                                 |  31%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |======================                                                |  31%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |======================                                                |  32%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=======================                                               |  32%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=======================                                               |  33%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=======================                                               |  34%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |========================                                              |  34%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |========================                                              |  35%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=========================                                             |  35%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=========================                                             |  36%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==========================                                            |  36%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==========================                                            |  37%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==========================                                            |  38%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===========================                                           |  38%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===========================                                           |  39%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |============================                                          |  39%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |============================                                          |  40%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |============================                                          |  41%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=============================                                         |  41%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=============================                                         |  42%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==============================                                        |  42%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==============================                                        |  43%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===============================                                       |  44%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===============================                                       |  45%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |================================                                      |  45%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |================================                                      |  46%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=================================                                     |  47%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=================================                                     |  48%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==================================                                    |  48%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==================================                                    |  49%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===================================                                   |  49%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===================================                                   |  50%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===================================                                   |  51%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |====================================                                  |  51%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |====================================                                  |  52%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=====================================                                 |  52%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=====================================                                 |  53%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |======================================                                |  54%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |======================================                                |  55%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=======================================                               |  55%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=======================================                               |  56%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |========================================                              |  56%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |========================================                              |  57%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |========================================                              |  58%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=========================================                             |  58%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=========================================                             |  59%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==========================================                            |  59%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==========================================                            |  60%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==========================================                            |  61%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===========================================                           |  61%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===========================================                           |  62%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |============================================                          |  62%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |============================================                          |  63%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=============================================                         |  64%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=============================================                         |  65%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==============================================                        |  65%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==============================================                        |  66%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===============================================                       |  66%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===============================================                       |  67%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===============================================                       |  68%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |================================================                      |  68%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |================================================                      |  69%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=================================================                     |  69%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=================================================                     |  70%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=================================================                     |  71%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==================================================                    |  71%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==================================================                    |  72%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===================================================                   |  72%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===================================================                   |  73%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===================================================                   |  74%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |====================================================                  |  74%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |====================================================                  |  75%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=====================================================                 |  75%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=====================================================                 |  76%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |======================================================                |  77%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |======================================================                |  78%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=======================================================               |  78%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=======================================================               |  79%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |========================================================              |  79%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |========================================================              |  80%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |========================================================              |  81%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=========================================================             |  81%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=========================================================             |  82%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==========================================================            |  82%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==========================================================            |  83%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==========================================================            |  84%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===========================================================           |  84%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===========================================================           |  85%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |============================================================          |  85%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |============================================================          |  86%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=============================================================         |  87%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=============================================================         |  88%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==============================================================        |  88%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==============================================================        |  89%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===============================================================       |  89%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===============================================================       |  90%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===============================================================       |  91%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |================================================================      |  91%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |================================================================      |  92%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=================================================================     |  92%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |=================================================================     |  93%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==================================================================    |  94%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |==================================================================    |  95%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===================================================================   |  95%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===================================================================   |  96%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |====================================================================  |  96%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |====================================================================  |  97%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |====================================================================  |  98%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===================================================================== |  98%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |===================================================================== |  99%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |======================================================================|  99%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |======================================================================| 100%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\n"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "[1] 83.52053\n"
     ]
    }
   ],
   "source": [
    "# Train model for X\n",
    "\n",
    "train_hframe = train_data_clean %>%  select(-c(ID,y_1,z_1)) %>% as.h2o() # will need to separate out x_1,y_1,z_1 & ID for each iteration\n",
    "train_hframe$resname <- as.factor(train_hframe$resname)\n",
    "train_hframe$begin_seq <- as.factor(train_hframe$begin_seq)\n",
    "train_hframe$end_seq <- as.factor(train_hframe$end_seq)\n",
    "# split the data into training and validation sets:\n",
    "splits <- h2o.splitFrame(data = train_hframe, ratio = 0.8, seed = 1)\n",
    "train <- splits[[1]]\n",
    "valid <- splits[[2]]\n",
    "xgb_x <- h2o.xgboost(x = features,\n",
    "        y = 'x_1',\n",
    "        nfolds = 5,\n",
    "        seed = 1,\n",
    "        booster = 'gbtree',\n",
    "        learn_rate=.15,\n",
    "        ntrees=800,\n",
    "        max_depth=15,\n",
    "        keep_cross_validation_predictions = TRUE,\n",
    "        training_frame = train_hframe)#,\n",
    "        #validation_frame = valid)\n",
    "\n",
    "print(h2o.mse(xgb_x,train=TRUE,valid=FALSE))\n",
    "\n",
    "# Train model for Y\n",
    "train_hframe = train_data_clean %>% select(-c(ID,x_1,z_1)) %>% as.h2o() # will need to separate out x_1,y_1,z_1 & ID for each iteration\n",
    "train_hframe$resname <- as.factor(train_hframe$resname)\n",
    "train_hframe$begin_seq <- as.factor(train_hframe$begin_seq)\n",
    "train_hframe$end_seq <- as.factor(train_hframe$end_seq)\n",
    "# split the data into training and validation sets:\n",
    "splits <- h2o.splitFrame(data = train_hframe, ratio = 0.8, seed = 1)\n",
    "train <- splits[[1]]\n",
    "valid <- splits[[2]]\n",
    "xgb_y <- h2o.xgboost(x = features,\n",
    "        y = 'y_1',\n",
    "        nfolds = 5,\n",
    "        seed = 1,\n",
    "        booster = 'gbtree',\n",
    "        learn_rate=.15,\n",
    "        ntrees=800,\n",
    "        max_depth=15,\n",
    "        keep_cross_validation_predictions = TRUE,\n",
    "        training_frame = train_hframe)#,\n",
    "        #validation_frame = valid)\n",
    "\n",
    "print(h2o.mse(xgb_y,train=TRUE,valid=FALSE))\n",
    "\n",
    "# Train model for Z\n",
    "train_hframe = train_data_clean %>% select(-c(ID,y_1,x_1)) %>% as.h2o() # will need to separate out x_1,y_1,z_1 & ID for each iteration\n",
    "train_hframe$resname <- as.factor(train_hframe$resname)\n",
    "train_hframe$begin_seq <- as.factor(train_hframe$begin_seq)\n",
    "train_hframe$end_seq <- as.factor(train_hframe$end_seq)\n",
    "# split the data into training and validation sets:\n",
    "splits <- h2o.splitFrame(data = train_hframe, ratio = 0.8, seed = 1)\n",
    "train <- splits[[1]]\n",
    "valid <- splits[[2]]\n",
    "xgb_z <- h2o.xgboost(x = features,\n",
    "        y = 'z_1',\n",
    "        nfolds = 5,\n",
    "        seed = 1,\n",
    "        booster = 'gbtree',\n",
    "        learn_rate=.15,\n",
    "        ntrees=800,\n",
    "        max_depth=15,\n",
    "        keep_cross_validation_predictions = TRUE,\n",
    "        training_frame = train_hframe)#,\n",
    "        #validation_frame = valid)\n",
    "\n",
    "print(h2o.mse(xgb_z,train=TRUE,valid=FALSE))"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 25,
   "id": "28adb50e",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-05-06T18:29:15.872788Z",
     "iopub.status.busy": "2025-05-06T18:29:15.871135Z",
     "iopub.status.idle": "2025-05-06T18:29:15.901630Z",
     "shell.execute_reply": "2025-05-06T18:29:15.900216Z"
    },
    "papermill": {
     "duration": 0.256737,
     "end_time": "2025-05-06T18:29:15.903247",
     "exception": false,
     "start_time": "2025-05-06T18:29:15.646510",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [],
   "source": [
    "# Create features on test sequence\n",
    "test_sequences <- feat_eng(test_sequences)\n",
    "\n",
    "# Merge test_clean we created earlier with test_sequences\n",
    "test_data_clean <- merge(test_clean, test_sequences, by.x=\"ID\",by.y=\"target_id\", all.x = TRUE)\n",
    "test_data_clean$resname <- as.factor(test_data_clean$resname)\n",
    "test_data_clean$begin_seq <- as.factor(test_data_clean$begin_seq)\n",
    "test_data_clean$end_seq <- as.factor(test_data_clean$end_seq)"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 26,
   "id": "e3127c47",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-05-06T18:29:15.972472Z",
     "iopub.status.busy": "2025-05-06T18:29:15.971251Z",
     "iopub.status.idle": "2025-05-06T18:29:19.655714Z",
     "shell.execute_reply": "2025-05-06T18:29:19.653784Z"
    },
    "papermill": {
     "duration": 3.720746,
     "end_time": "2025-05-06T18:29:19.657784",
     "exception": false,
     "start_time": "2025-05-06T18:29:15.937038",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |                                                                      |   0%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |======================================================================| 100%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\n"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |                                                                      |   0%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |======================================================================| 100%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\n"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |                                                                      |   0%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |======================================================================| 100%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\n"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |                                                                      |   0%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |======================================================================| 100%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\n"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |                                                                      |   0%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |======================================================================| 100%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\n"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |                                                                      |   0%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\r",
      "  |                                                                            \r",
      "  |======================================================================| 100%"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\n"
     ]
    }
   ],
   "source": [
    "preds_x = h2o.predict(xgb_x,newdata = as.h2o(test_data_clean %>% select(-ID)))\n",
    "preds_y = h2o.predict(xgb_y,newdata = as.h2o(test_data_clean %>% select(-ID)))\n",
    "preds_z = h2o.predict(xgb_z,newdata = as.h2o(test_data_clean %>% select(-ID)))"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "5a3bb05f",
   "metadata": {
    "papermill": {
     "duration": 0.035663,
     "end_time": "2025-05-06T18:29:19.726840",
     "exception": false,
     "start_time": "2025-05-06T18:29:19.691177",
     "status": "completed"
    },
    "tags": []
   },
   "source": [
    "# 🤞 Submission"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "ff3a19d7",
   "metadata": {
    "papermill": {
     "duration": 0.034699,
     "end_time": "2025-05-06T18:29:19.795832",
     "exception": false,
     "start_time": "2025-05-06T18:29:19.761133",
     "status": "completed"
    },
    "tags": []
   },
   "source": [
    "### For now, we will use the same predictions for all x,y,z combinations.  Future version will incorporate different methods for these predictions."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 27,
   "id": "2ead42a4",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-05-06T18:29:19.868000Z",
     "iopub.status.busy": "2025-05-06T18:29:19.866936Z",
     "iopub.status.idle": "2025-05-06T18:29:20.010792Z",
     "shell.execute_reply": "2025-05-06T18:29:20.009346Z"
    },
    "papermill": {
     "duration": 0.182761,
     "end_time": "2025-05-06T18:29:20.013191",
     "exception": false,
     "start_time": "2025-05-06T18:29:19.830430",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [],
   "source": [
    "submission <- data.frame(test_data_clean$ID, \n",
    "                         test_data_clean$resname, \n",
    "                         test_data_clean$resid) \n",
    "\n",
    "submission <- cbind(submission, \n",
    "                         as.data.frame(preds_x),\n",
    "                         as.data.frame(preds_y),\n",
    "                         as.data.frame(preds_z),\n",
    "                    \n",
    "                         as.data.frame(preds_x),\n",
    "                         as.data.frame(preds_y),\n",
    "                         as.data.frame(preds_z),\n",
    "                    \n",
    "                         as.data.frame(preds_x),\n",
    "                         as.data.frame(preds_y),\n",
    "                         as.data.frame(preds_z),\n",
    "                    \n",
    "                         as.data.frame(preds_x),\n",
    "                         as.data.frame(preds_y),\n",
    "                         as.data.frame(preds_z),\n",
    "                    \n",
    "                         as.data.frame(preds_x),\n",
    "                         as.data.frame(preds_y),\n",
    "                         as.data.frame(preds_z))\n",
    "colnames(submission) <- sample_submission %>% colnames()"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "60d2992b",
   "metadata": {
    "papermill": {
     "duration": 0.035596,
     "end_time": "2025-05-06T18:29:20.083613",
     "exception": false,
     "start_time": "2025-05-06T18:29:20.048017",
     "status": "completed"
    },
    "tags": []
   },
   "source": [
    "### My first two submissions in R errored at the scoring phase.  This was due to the ID columns not being in the same order as the sample_submission, so we will create a simple sort column based off the sample_submission, and apply that to our submission df."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 28,
   "id": "700dc1ea",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-05-06T18:29:20.155730Z",
     "iopub.status.busy": "2025-05-06T18:29:20.154510Z",
     "iopub.status.idle": "2025-05-06T18:29:20.179694Z",
     "shell.execute_reply": "2025-05-06T18:29:20.178456Z"
    },
    "papermill": {
     "duration": 0.063494,
     "end_time": "2025-05-06T18:29:20.181269",
     "exception": false,
     "start_time": "2025-05-06T18:29:20.117775",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [],
   "source": [
    "# Update ID to match submission ID column\n",
    "submission <- submission %>% mutate(ID = paste(ID,resid,sep=\"_\"))\n",
    "\n",
    "# Create a sort_order column within the sample_submission so we can apply it to our submission\n",
    "sample_submission$sort_order <- seq(1:nrow(sample_submission))\n",
    "submission <- merge(submission,sample_submission %>% select(ID,sort_order), by='ID',all.x=TRUE) %>% arrange(sort_order) %>% select(-sort_order)"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 29,
   "id": "c591369e",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-05-06T18:29:20.255272Z",
     "iopub.status.busy": "2025-05-06T18:29:20.254121Z",
     "iopub.status.idle": "2025-05-06T18:29:20.276973Z",
     "shell.execute_reply": "2025-05-06T18:29:20.275828Z"
    },
    "papermill": {
     "duration": 0.059449,
     "end_time": "2025-05-06T18:29:20.278431",
     "exception": false,
     "start_time": "2025-05-06T18:29:20.218982",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "data": {
      "text/html": [
       "<table class=\"dataframe\">\n",
       "<caption>A data.frame: 3 × 18</caption>\n",
       "<thead>\n",
       "\t<tr><th></th><th scope=col>ID</th><th scope=col>resname</th><th scope=col>resid</th><th scope=col>x_1</th><th scope=col>y_1</th><th scope=col>z_1</th><th scope=col>x_2</th><th scope=col>y_2</th><th scope=col>z_2</th><th scope=col>x_3</th><th scope=col>y_3</th><th scope=col>z_3</th><th scope=col>x_4</th><th scope=col>y_4</th><th scope=col>z_4</th><th scope=col>x_5</th><th scope=col>y_5</th><th scope=col>z_5</th></tr>\n",
       "\t<tr><th></th><th scope=col>&lt;chr&gt;</th><th scope=col>&lt;fct&gt;</th><th scope=col>&lt;int&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th></tr>\n",
       "</thead>\n",
       "<tbody>\n",
       "\t<tr><th scope=row>1</th><td>R1107_1</td><td>G</td><td>1</td><td>52.25308</td><td>138.8444</td><td> 99.71029</td><td>52.25308</td><td>138.8444</td><td> 99.71029</td><td>52.25308</td><td>138.8444</td><td> 99.71029</td><td>52.25308</td><td>138.8444</td><td> 99.71029</td><td>52.25308</td><td>138.8444</td><td> 99.71029</td></tr>\n",
       "\t<tr><th scope=row>2</th><td>R1107_2</td><td>G</td><td>2</td><td>51.38475</td><td>138.4478</td><td>100.63914</td><td>51.38475</td><td>138.4478</td><td>100.63914</td><td>51.38475</td><td>138.4478</td><td>100.63914</td><td>51.38475</td><td>138.4478</td><td>100.63914</td><td>51.38475</td><td>138.4478</td><td>100.63914</td></tr>\n",
       "\t<tr><th scope=row>3</th><td>R1107_3</td><td>G</td><td>3</td><td>50.75843</td><td>137.9750</td><td>101.93651</td><td>50.75843</td><td>137.9750</td><td>101.93651</td><td>50.75843</td><td>137.9750</td><td>101.93651</td><td>50.75843</td><td>137.9750</td><td>101.93651</td><td>50.75843</td><td>137.9750</td><td>101.93651</td></tr>\n",
       "</tbody>\n",
       "</table>\n"
      ],
      "text/latex": [
       "A data.frame: 3 × 18\n",
       "\\begin{tabular}{r|llllllllllllllllll}\n",
       "  & ID & resname & resid & x\\_1 & y\\_1 & z\\_1 & x\\_2 & y\\_2 & z\\_2 & x\\_3 & y\\_3 & z\\_3 & x\\_4 & y\\_4 & z\\_4 & x\\_5 & y\\_5 & z\\_5\\\\\n",
       "  & <chr> & <fct> & <int> & <dbl> & <dbl> & <dbl> & <dbl> & <dbl> & <dbl> & <dbl> & <dbl> & <dbl> & <dbl> & <dbl> & <dbl> & <dbl> & <dbl> & <dbl>\\\\\n",
       "\\hline\n",
       "\t1 & R1107\\_1 & G & 1 & 52.25308 & 138.8444 &  99.71029 & 52.25308 & 138.8444 &  99.71029 & 52.25308 & 138.8444 &  99.71029 & 52.25308 & 138.8444 &  99.71029 & 52.25308 & 138.8444 &  99.71029\\\\\n",
       "\t2 & R1107\\_2 & G & 2 & 51.38475 & 138.4478 & 100.63914 & 51.38475 & 138.4478 & 100.63914 & 51.38475 & 138.4478 & 100.63914 & 51.38475 & 138.4478 & 100.63914 & 51.38475 & 138.4478 & 100.63914\\\\\n",
       "\t3 & R1107\\_3 & G & 3 & 50.75843 & 137.9750 & 101.93651 & 50.75843 & 137.9750 & 101.93651 & 50.75843 & 137.9750 & 101.93651 & 50.75843 & 137.9750 & 101.93651 & 50.75843 & 137.9750 & 101.93651\\\\\n",
       "\\end{tabular}\n"
      ],
      "text/markdown": [
       "\n",
       "A data.frame: 3 × 18\n",
       "\n",
       "| <!--/--> | ID &lt;chr&gt; | resname &lt;fct&gt; | resid &lt;int&gt; | x_1 &lt;dbl&gt; | y_1 &lt;dbl&gt; | z_1 &lt;dbl&gt; | x_2 &lt;dbl&gt; | y_2 &lt;dbl&gt; | z_2 &lt;dbl&gt; | x_3 &lt;dbl&gt; | y_3 &lt;dbl&gt; | z_3 &lt;dbl&gt; | x_4 &lt;dbl&gt; | y_4 &lt;dbl&gt; | z_4 &lt;dbl&gt; | x_5 &lt;dbl&gt; | y_5 &lt;dbl&gt; | z_5 &lt;dbl&gt; |\n",
       "|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|\n",
       "| 1 | R1107_1 | G | 1 | 52.25308 | 138.8444 |  99.71029 | 52.25308 | 138.8444 |  99.71029 | 52.25308 | 138.8444 |  99.71029 | 52.25308 | 138.8444 |  99.71029 | 52.25308 | 138.8444 |  99.71029 |\n",
       "| 2 | R1107_2 | G | 2 | 51.38475 | 138.4478 | 100.63914 | 51.38475 | 138.4478 | 100.63914 | 51.38475 | 138.4478 | 100.63914 | 51.38475 | 138.4478 | 100.63914 | 51.38475 | 138.4478 | 100.63914 |\n",
       "| 3 | R1107_3 | G | 3 | 50.75843 | 137.9750 | 101.93651 | 50.75843 | 137.9750 | 101.93651 | 50.75843 | 137.9750 | 101.93651 | 50.75843 | 137.9750 | 101.93651 | 50.75843 | 137.9750 | 101.93651 |\n",
       "\n"
      ],
      "text/plain": [
       "  ID      resname resid x_1      y_1      z_1       x_2      y_2      z_2      \n",
       "1 R1107_1 G       1     52.25308 138.8444  99.71029 52.25308 138.8444  99.71029\n",
       "2 R1107_2 G       2     51.38475 138.4478 100.63914 51.38475 138.4478 100.63914\n",
       "3 R1107_3 G       3     50.75843 137.9750 101.93651 50.75843 137.9750 101.93651\n",
       "  x_3      y_3      z_3       x_4      y_4      z_4       x_5      y_5     \n",
       "1 52.25308 138.8444  99.71029 52.25308 138.8444  99.71029 52.25308 138.8444\n",
       "2 51.38475 138.4478 100.63914 51.38475 138.4478 100.63914 51.38475 138.4478\n",
       "3 50.75843 137.9750 101.93651 50.75843 137.9750 101.93651 50.75843 137.9750\n",
       "  z_5      \n",
       "1  99.71029\n",
       "2 100.63914\n",
       "3 101.93651"
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    }
   ],
   "source": [
    "submission %>% head(3)"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 30,
   "id": "1719144b",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-05-06T18:29:20.365368Z",
     "iopub.status.busy": "2025-05-06T18:29:20.364144Z",
     "iopub.status.idle": "2025-05-06T18:29:20.471595Z",
     "shell.execute_reply": "2025-05-06T18:29:20.470045Z"
    },
    "papermill": {
     "duration": 0.153502,
     "end_time": "2025-05-06T18:29:20.473177",
     "exception": false,
     "start_time": "2025-05-06T18:29:20.319675",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [],
   "source": [
    "write_csv(submission, 'submission.csv')"
   ]
  }
 ],
 "metadata": {
  "kaggle": {
   "accelerator": "none",
   "dataSources": [
    {
     "databundleVersionId": 12024591,
     "sourceId": 87793,
     "sourceType": "competition"
    }
   ],
   "dockerImageVersionId": 30749,
   "isGpuEnabled": false,
   "isInternetEnabled": false,
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
   "duration": 3710.638077,
   "end_time": "2025-05-06T18:29:20.727552",
   "environment_variables": {},
   "exception": null,
   "input_path": "__notebook__.ipynb",
   "output_path": "__notebook__.ipynb",
   "parameters": {},
   "start_time": "2025-05-06T17:27:30.089475",
   "version": "2.6.0"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 5
}
