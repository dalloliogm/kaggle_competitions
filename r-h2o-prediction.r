{
 "cells": [
  {
   "cell_type": "code",
   "execution_count": 1,
   "id": "2061eb58",
   "metadata": {
    "_execution_state": "idle",
    "_uuid": "051d70d956493feee0c6d64651c6a088724dca2a",
    "execution": {
     "iopub.execute_input": "2025-04-21T21:08:03.738321Z",
     "iopub.status.busy": "2025-04-21T21:08:03.735852Z",
     "iopub.status.idle": "2025-04-21T21:08:04.950038Z",
     "shell.execute_reply": "2025-04-21T21:08:04.948175Z"
    },
    "papermill": {
     "duration": 1.222883,
     "end_time": "2025-04-21T21:08:04.952304",
     "exception": false,
     "start_time": "2025-04-21T21:08:03.729421",
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
       "'playground-series-s5e4'"
      ],
      "text/latex": [
       "'playground-series-s5e4'"
      ],
      "text/markdown": [
       "'playground-series-s5e4'"
      ],
      "text/plain": [
       "[1] \"playground-series-s5e4\""
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
   "id": "d9b815f7",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-04-21T21:08:04.992184Z",
     "iopub.status.busy": "2025-04-21T21:08:04.960825Z",
     "iopub.status.idle": "2025-04-21T21:08:08.428572Z",
     "shell.execute_reply": "2025-04-21T21:08:08.425437Z"
    },
    "papermill": {
     "duration": 3.476073,
     "end_time": "2025-04-21T21:08:08.431922",
     "exception": false,
     "start_time": "2025-04-21T21:08:04.955849",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "── \u001b[1mAttaching packages\u001b[22m ────────────────────────────────────── tidymodels 1.2.0 ──\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[32m✔\u001b[39m \u001b[34mbroom       \u001b[39m 1.0.6      \u001b[32m✔\u001b[39m \u001b[34mrsample     \u001b[39m 1.2.1 \n",
      "\u001b[32m✔\u001b[39m \u001b[34mdials       \u001b[39m 1.2.1      \u001b[32m✔\u001b[39m \u001b[34mtune        \u001b[39m 1.2.1 \n",
      "\u001b[32m✔\u001b[39m \u001b[34minfer       \u001b[39m 1.0.7      \u001b[32m✔\u001b[39m \u001b[34mworkflows   \u001b[39m 1.1.4 \n",
      "\u001b[32m✔\u001b[39m \u001b[34mmodeldata   \u001b[39m 1.4.0      \u001b[32m✔\u001b[39m \u001b[34mworkflowsets\u001b[39m 1.1.0 \n",
      "\u001b[32m✔\u001b[39m \u001b[34mparsnip     \u001b[39m 1.2.1      \u001b[32m✔\u001b[39m \u001b[34myardstick   \u001b[39m 1.3.1 \n",
      "\u001b[32m✔\u001b[39m \u001b[34mrecipes     \u001b[39m 1.0.10     \n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "── \u001b[1mConflicts\u001b[22m ───────────────────────────────────────── tidymodels_conflicts() ──\n",
      "\u001b[31m✖\u001b[39m \u001b[34mscales\u001b[39m::\u001b[32mdiscard()\u001b[39m masks \u001b[34mpurrr\u001b[39m::discard()\n",
      "\u001b[31m✖\u001b[39m \u001b[34mdplyr\u001b[39m::\u001b[32mfilter()\u001b[39m   masks \u001b[34mstats\u001b[39m::filter()\n",
      "\u001b[31m✖\u001b[39m \u001b[34mrecipes\u001b[39m::\u001b[32mfixed()\u001b[39m  masks \u001b[34mstringr\u001b[39m::fixed()\n",
      "\u001b[31m✖\u001b[39m \u001b[34mdplyr\u001b[39m::\u001b[32mlag()\u001b[39m      masks \u001b[34mstats\u001b[39m::lag()\n",
      "\u001b[31m✖\u001b[39m \u001b[34myardstick\u001b[39m::\u001b[32mspec()\u001b[39m masks \u001b[34mreadr\u001b[39m::spec()\n",
      "\u001b[31m✖\u001b[39m \u001b[34mrecipes\u001b[39m::\u001b[32mstep()\u001b[39m   masks \u001b[34mstats\u001b[39m::step()\n",
      "\u001b[34m•\u001b[39m Use suppressPackageStartupMessages() to eliminate package startup messages\n",
      "\n"
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
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "Warning message:\n",
      "“no DISPLAY variable so Tk is not available”\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "system might not have X11 capabilities; in case of errors when using dfSummary(), set st_options(use.x11 = FALSE)\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\n",
      "Attaching package: ‘summarytools’\n",
      "\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "The following object is masked from ‘package:tibble’:\n",
      "\n",
      "    view\n",
      "\n",
      "\n"
     ]
    }
   ],
   "source": [
    "library(tidyverse)\n",
    "library(tidymodels)\n",
    "library(h2o)\n",
    "library(summarytools)\n",
    "library(knitr)\n",
    "library(DataExplorer)"
   ]
  },
  {
   "cell_type": "raw",
   "id": "cb13daa7",
   "metadata": {
    "papermill": {
     "duration": 0.004045,
     "end_time": "2025-04-21T21:08:08.440563",
     "exception": false,
     "start_time": "2025-04-21T21:08:08.436518",
     "status": "completed"
    },
    "tags": []
   },
   "source": [
    "## Prepare Training/Test data"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 3,
   "id": "3b11cae8",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-04-21T21:08:08.453039Z",
     "iopub.status.busy": "2025-04-21T21:08:08.450540Z",
     "iopub.status.idle": "2025-04-21T21:08:18.506203Z",
     "shell.execute_reply": "2025-04-21T21:08:18.503358Z"
    },
    "papermill": {
     "duration": 10.06414,
     "end_time": "2025-04-21T21:08:18.508621",
     "exception": false,
     "start_time": "2025-04-21T21:08:08.444481",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[1mRows: \u001b[22m\u001b[34m750000\u001b[39m \u001b[1mColumns: \u001b[22m\u001b[34m12\u001b[39m\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[36m──\u001b[39m \u001b[1mColumn specification\u001b[22m \u001b[36m────────────────────────────────────────────────────────\u001b[39m\n",
      "\u001b[1mDelimiter:\u001b[22m \",\"\n",
      "\u001b[31mchr\u001b[39m (6): Podcast_Name, Episode_Title, Genre, Publication_Day, Publication_Ti...\n",
      "\u001b[32mdbl\u001b[39m (6): id, Episode_Length_minutes, Host_Popularity_percentage, Guest_Popul...\n"
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
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "Warning message in png(png_loc <- tempfile(fileext = \".png\"), width = 150 * graph.magnif, :\n",
      "“unable to open connection to X11 display ''”\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "Warning message in png(png_loc <- tempfile(fileext = \".png\"), width = 150 * graph.magnif, :\n",
      "“unable to open connection to X11 display ''”\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "Warning message in png(png_loc <- tempfile(fileext = \".png\"), width = 150 * graph.magnif, :\n",
      "“unable to open connection to X11 display ''”\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "Warning message in png(png_loc <- tempfile(fileext = \".png\"), width = 150 * graph.magnif, :\n",
      "“unable to open connection to X11 display ''”\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "Warning message in png(png_loc <- tempfile(fileext = \".png\"), width = 150 * graph.magnif, :\n",
      "“unable to open connection to X11 display ''”\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "Warning message in png(png_loc <- tempfile(fileext = \".png\"), width = 150 * graph.magnif, :\n",
      "“unable to open connection to X11 display ''”\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "Warning message in png(png_loc <- tempfile(fileext = \".png\"), width = 150 * graph.magnif, :\n",
      "“unable to open connection to X11 display ''”\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "Warning message in png(png_loc <- tempfile(fileext = \".png\"), width = 150 * graph.magnif, :\n",
      "“unable to open connection to X11 display ''”\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "Warning message in png(png_loc <- tempfile(fileext = \".png\"), width = 150 * graph.magnif, :\n",
      "“unable to open connection to X11 display ''”\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "Warning message in png(png_loc <- tempfile(fileext = \".png\"), width = 150 * graph.magnif, :\n",
      "“unable to open connection to X11 display ''”\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "Warning message in png(png_loc <- tempfile(fileext = \".png\"), width = 150 * graph.magnif, :\n",
      "“unable to open connection to X11 display ''”\n"
     ]
    },
    {
     "data": {
      "text/html": [
       "<table class=\"dataframe\">\n",
       "<caption>A summarytools: 11 × 7</caption>\n",
       "<thead>\n",
       "\t<tr><th></th><th scope=col>No</th><th scope=col>Variable</th><th scope=col>Stats / Values</th><th scope=col>Freqs (% of Valid)</th><th scope=col>Graph</th><th scope=col>Valid</th><th scope=col>Missing</th></tr>\n",
       "\t<tr><th></th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;chr&gt;</th><th scope=col>&lt;chr&gt;</th><th scope=col>&lt;chr&gt;</th><th scope=col>&lt;chr&gt;</th><th scope=col>&lt;chr&gt;</th><th scope=col>&lt;chr&gt;</th></tr>\n",
       "</thead>\n",
       "<tbody>\n",
       "\t<tr><th scope=row>1</th><td> 1</td><td><span style=white-space:pre-wrap>Podcast_Name\\\n",
       "[character]             </span></td><td>1\\. Tech Talks\\\n",
       "2\\. Sports Weekly\\\n",
       "3\\. Funny Folks\\\n",
       "4\\. Tech Trends\\\n",
       "5\\. Fitness First\\\n",
       "6\\. Business Insights\\\n",
       "7\\. Style Guide\\\n",
       "8\\. Game Day\\\n",
       "9\\. Melody Mix\\\n",
       "10\\. Criminal Minds\\\n",
       "[ 38 others ]</td><td>\\ 22847 ( 3.0%)\\\n",
       "\\ 20053 ( 2.7%)\\\n",
       "\\ 19635 ( 2.6%)\\\n",
       "\\ 19549 ( 2.6%)\\\n",
       "\\ 19488 ( 2.6%)\\\n",
       "\\ 19480 ( 2.6%)\\\n",
       "\\ 19364 ( 2.6%)\\\n",
       "\\ 19272 ( 2.6%)\\\n",
       "\\ 18889 ( 2.5%)\\\n",
       "\\ 17735 ( 2.4%)\\\n",
       "\\553688 (73.8%)</td><td><span style=white-space:pre-wrap>&lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAF8AAADKCAQAAABp7lSOAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVCAsqPtOcAAABc0lEQVR42u3bQYrCQBRF0aRxdS6hFxh30OtyB3Fg01QkCPYgv17lXEfODlKBPCjndUruqxqAn9ul/XL7fRC+52rWu9qn9eXXv07Xat1HhR8efHz8yPDx8SPDr+yy/fpT7fmwuX177vo1/6837/tpbQ7PErG22qwtfPzI8PHxI8PHPyvfXKksnG9tdcRPCx8fPzJ8fPzI8Cuztiobib+s9/W+LkEXa0f69fPCx8ePDB8fP7Jwvqt4R2dt9ZK1hY8fGT4+fmT4+GflW1tHN9Da2rmKl3MRb5qmtflkrK1WHH548PHxI8PHx48Mv7KdtZX0wmxtVeaPTx3x08LHx48MHx8/MvzKzJXKwvnWVkf8tPDx8SPDx8ePDL8ya6uykfjPq3jVpH/z88LHx48MHx8/MvzK/PHp6KytXrK28PEjw8fHjwwf/6x8a+voBlpbu1fxOq85JC9nv/+LeNunM/zw4OPjR4aPjx8ZfmUjra28wg8PfmUPPABb6rm7Ea0AAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjFUMjE6MDg6MTErMDA6MDCR28twAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIxVDIxOjA4OjExKzAwOjAw4IZzzAAAAABJRU5ErkJggg==\"&gt;                        </span></td><td>750000\\\n",
       "(100.0%)</td><td><span style=white-space:pre-wrap>0\\\n",
       "(0.0%)      </span></td></tr>\n",
       "\t<tr><th scope=row>2</th><td> 2</td><td><span style=white-space:pre-wrap>Episode_Title\\\n",
       "[character]            </span></td><td><span style=white-space:pre-wrap>1\\. Episode 71\\\n",
       "2\\. Episode 62\\\n",
       "3\\. Episode 31\\\n",
       "4\\. Episode 61\\\n",
       "5\\. Episode 69\\\n",
       "6\\. Episode 23\\\n",
       "7\\. Episode 63\\\n",
       "8\\. Episode 81\\\n",
       "9\\. Episode 64\\\n",
       "10\\. Episode 72\\\n",
       "[ 90 others ]                  </span></td><td><span style=white-space:pre-wrap>\\ 10515 ( 1.4%)\\\n",
       "\\ 10373 ( 1.4%)\\\n",
       "\\ 10292 ( 1.4%)\\\n",
       "\\  9991 ( 1.3%)\\\n",
       "\\  9864 ( 1.3%)\\\n",
       "\\  9762 ( 1.3%)\\\n",
       "\\  9743 ( 1.3%)\\\n",
       "\\  9741 ( 1.3%)\\\n",
       "\\  9686 ( 1.3%)\\\n",
       "\\  9554 ( 1.3%)\\\n",
       "\\650479 (86.7%)</span></td><td><span style=white-space:pre-wrap>&lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAG0AAADKCAQAAAAF6AaLAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVCAsqPtOcAAABX0lEQVR42u3YwWnDQBRFUSm4unSQFOh0kPac7STglQPi/LlnZeHNXCSEn8/HMdXb1QcorbTVbb34ehzH53n1kV6xvjkG37XSRKWJShOVJipNVJqoNNG5Lhx6qh3Hsedeuz/ug/7g2uWuzVKaqDRRaaLSRKWJShM1RUW7pLWyEaWJShOVJipNVJqoNNHgtFa2aJe0VjaiNFFpotJEpYlKE5UmGpzWyhbtktbKRpQmKk1Umqg0UWmi0kSD01rZoqaoqDRRaaLSRKWJShOVJipN1MoWtbJFpYlKE5UmKk1Umqg00eC0pqhol7RWNqI0UWmi0kSliUoTlSYanNbKFu2S1spGlCYqTVSaqDRRaaLSRIPTWtmiXdJa2YjSRKWJShOVJipNVJpocForW3RbLwYM0eXBu/3+5v3qo/2jwQ9kaaLSRKWJShOVJipN9OeX//fV53nRx/L59CfaM4MfyNJEP0K2Ox7416vXAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDI1LTA0LTIxVDIxOjA4OjExKzAwOjAwkdvLcAAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyNS0wNC0yMVQyMTowODoxMSswMDowMOCGc8wAAAAASUVORK5CYII=\"&gt;                                                    </span></td><td>750000\\\n",
       "(100.0%)</td><td><span style=white-space:pre-wrap>0\\\n",
       "(0.0%)      </span></td></tr>\n",
       "\t<tr><th scope=row>3</th><td> 3</td><td><span style=white-space:pre-wrap>Episode_Length_minutes\\\n",
       "[numeric]     </span></td><td><span style=white-space:pre-wrap>Mean (sd) : 64.5 (33)\\\n",
       "min &lt; med &lt; max:\\\n",
       "0 &lt; 63.8 &lt; 325.2\\\n",
       "IQR (CV) : 58.3 (0.5)                                                                                                                                        </span></td><td><span style=white-space:pre-wrap>12268 distinct values                                                                                                                                                                                                   </span></td><td><span style=white-space:pre-wrap>&lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVCAy0WkY/AAAA5klEQVR42u3cwQ2CMBhAYWuYzg10wLqBc7kB3kiJEpFiWt7/Hhe4NHwBSgKENJ5idG69A0KFbmsoN1LFQHl2sd9qhtqtcpeGzaO8dZnWHq2FH1qE9niE/gLt/Qj9WpjJSCitKmgen9PSGvKtlbeX3D1kJ2g5Ax9zNvYapSWUllBaQmkJpSWUllBaQmkJpSWUllBaQmmFgc6e1B//xcNKKO3lb1mYU1coLaG0hNISSksoLaG0hNISSksoLaG0hNISSksoLaG0hNISSksoLaG0wkBT+WnRHfad0bX4TUaC2RYLc+oKpfUCK5UeTY+BarAAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjFUMjE6MDg6MTIrMDA6MDCgM9HtAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIxVDIxOjA4OjEyKzAwOjAw0W5pUQAAAABJRU5ErkJggg==\"&gt;                                                                                                                                                                                                                    </span></td><td>662907\\\n",
       "(88.4%) </td><td>87093\\\n",
       "(11.6%) </td></tr>\n",
       "\t<tr><th scope=row>4</th><td> 4</td><td><span style=white-space:pre-wrap>Genre\\\n",
       "[character]                    </span></td><td><span style=white-space:pre-wrap>1\\. Business\\\n",
       "2\\. Comedy\\\n",
       "3\\. Education\\\n",
       "4\\. Health\\\n",
       "5\\. Lifestyle\\\n",
       "6\\. Music\\\n",
       "7\\. News\\\n",
       "8\\. Sports\\\n",
       "9\\. Technology\\\n",
       "10\\. True Crime                                                              </span></td><td><span style=white-space:pre-wrap>\\80521 (10.7%)\\\n",
       "\\81453 (10.9%)\\\n",
       "\\49100 ( 6.5%)\\\n",
       "\\71416 ( 9.5%)\\\n",
       "\\82461 (11.0%)\\\n",
       "\\62743 ( 8.4%)\\\n",
       "\\63385 ( 8.5%)\\\n",
       "\\87606 (11.7%)\\\n",
       "\\86256 (11.5%)\\\n",
       "\\85059 (11.3%)                              </span></td><td><span style=white-space:pre-wrap>&lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAABoAAAC3CAQAAACmwYZ1AAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVCAy0WkY/AAAAy0lEQVRo3u2awQ2DMBAEfRHVpQQXSDqgLjpwHvmwxo4OiMiBZnhZ8kg+jgVbwkrazmOHc6I0LAev8mxOmlK2Ze3Ba0JCUgYdTi5JHnn7MvFwNGR5Y/ctk60rpdRLrhK8T0hIypWTm80haXL79QXvExKScuXkfljn1/XNrQneJyQk5bwQsltGQvqdFDy5Io1lrq52loPfciQkJfjGl+QiITUJnlznxleX4Tyyaq3B+4SEpNwjuTuOrDXB+4SEpJDcI8tDQvqXZDf8HeoNSZBWhwHfHEYAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjFUMjE6MDg6MTIrMDA6MDCgM9HtAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIxVDIxOjA4OjEyKzAwOjAw0W5pUQAAAABJRU5ErkJggg==\"&gt;                                                                                                                                                                                                                                                        </span></td><td>750000\\\n",
       "(100.0%)</td><td><span style=white-space:pre-wrap>0\\\n",
       "(0.0%)      </span></td></tr>\n",
       "\t<tr><th scope=row>5</th><td> 5</td><td>Host_Popularity_percentage\\\n",
       "[numeric] </td><td><span style=white-space:pre-wrap>Mean (sd) : 59.9 (22.9)\\\n",
       "min &lt; med &lt; max:\\\n",
       "1.3 &lt; 60 &lt; 119.5\\\n",
       "IQR (CV) : 40.1 (0.4)                                                                                                                                      </span></td><td><span style=white-space:pre-wrap>8038 distinct values                                                                                                                                                                                                    </span></td><td><span style=white-space:pre-wrap>&lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVCA5aVCcTAAABK0lEQVR42u3b0Q2CMABFUWqYjg10QNyAudgAPxCoSiNtKdDXe3+MJhAPlBajmqEqo9vZbwAo0LBq+4nx2LCdL+6Hz2aHZs8/dehOmvdjd7ZmY8UMXaBqAVWrGGjw8rI0rajjgtNFravpVucdoBNwO2Lpm5Nudd4B6ntIlrqqH8bH3/M3HZa9zmxCaNww3DpOLgC91k3ioUPXXev8/O8e3FlCm/hd/Il19KqFTnHZQD9vS/ynuGygsVdxAmg/rL9y7jJTzGQEVC3Pa7TN9hsM78ko/T1MmooZukDVAqoWULWAqgVULaBqAVULqFpA1QKqFlC1gKoFVC2gagFVC6haQNUCqhZQtYCqBVQtoGoBVQuoWsVAjf0j+We2v5hf7279qcuI2ZwVM3SBqvUCy9ktIuH0SSgAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjFUMjE6MDg6MTQrMDA6MDDD4+TXAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIxVDIxOjA4OjE0KzAwOjAwsr5cawAAAABJRU5ErkJggg==\"&gt;                                                                                                                        </span></td><td>750000\\\n",
       "(100.0%)</td><td><span style=white-space:pre-wrap>0\\\n",
       "(0.0%)      </span></td></tr>\n",
       "\t<tr><th scope=row>6</th><td> 6</td><td><span style=white-space:pre-wrap>Publication_Day\\\n",
       "[character]          </span></td><td><span style=white-space:pre-wrap>1\\. Friday\\\n",
       "2\\. Monday\\\n",
       "3\\. Saturday\\\n",
       "4\\. Sunday\\\n",
       "5\\. Thursday\\\n",
       "6\\. Tuesday\\\n",
       "7\\. Wednesday                                                                                                                 </span></td><td><span style=white-space:pre-wrap>\\108237 (14.4%)\\\n",
       "\\111963 (14.9%)\\\n",
       "\\103505 (13.8%)\\\n",
       "\\115946 (15.5%)\\\n",
       "\\104360 (13.9%)\\\n",
       "\\ 98103 (13.1%)\\\n",
       "\\107886 (14.4%)                                                                                </span></td><td><span style=white-space:pre-wrap>&lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAB4AAACCCAQAAAD7nbARAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVCA5aVCcTAAAArElEQVRYw+3Z2w2AIAwF0NYwnSN0QN2A9fDX+iiiNqZy+SPhJNCGG6Jc6P4YHtgPcVpP5jKaizMJr2sU9MzAwL446WluwuqK8QXw2pVU256qaSh8ionGmlYjaJ+BgX1xD0kibGA7Sfb1CNpnYGBf3EOSbLfX+CbRNQnaZ2BgX9xDkuBNAgzsjf+fJMImtpLkqBpB+wwM7Iv/nyREj764bisStM/AwL6YO/wLvACUmyhPC06I2AAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAyNS0wNC0yMVQyMTowODoxNCswMDowMMPj5NcAAAAldEVYdGRhdGU6bW9kaWZ5ADIwMjUtMDQtMjFUMjE6MDg6MTQrMDA6MDCyvlxrAAAAAElFTkSuQmCC\"&gt;                                                                                                                                                                                                                                                                                                    </span></td><td>750000\\\n",
       "(100.0%)</td><td><span style=white-space:pre-wrap>0\\\n",
       "(0.0%)      </span></td></tr>\n",
       "\t<tr><th scope=row>7</th><td> 7</td><td><span style=white-space:pre-wrap>Publication_Time\\\n",
       "[character]         </span></td><td><span style=white-space:pre-wrap>1\\. Afternoon\\\n",
       "2\\. Evening\\\n",
       "3\\. Morning\\\n",
       "4\\. Night                                                                                                                                                                  </span></td><td><span style=white-space:pre-wrap>\\179460 (23.9%)\\\n",
       "\\195778 (26.1%)\\\n",
       "\\177913 (23.7%)\\\n",
       "\\196849 (26.2%)                                                                                                                                            </span></td><td><span style=white-space:pre-wrap>&lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAACoAAABOCAQAAAD8r0ycAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVCA5aVCcTAAAAiklEQVRYw+3WSw6AIAxF0dawOpfAAnUHbk+HFHXEJ2nD7cxETvKEPNRbxs82wQyEJvtwNn3grCIidmmqX9j9xgcFBV0TfbXUNQRV24PaAVlnfvyj52o1MQc1f70XcY4UKCioe5TmL9PW/PkTsLv5/3YhzpECBQV1j9L8ZfjnBwUFXQOd3/yu48dBH/iKFxn/tftSAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDI1LTA0LTIxVDIxOjA4OjE0KzAwOjAww+Pk1wAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyNS0wNC0yMVQyMTowODoxNCswMDowMLK+XGsAAAAASUVORK5CYII=\"&gt;                                                                                                                                                                                                                                                                                                                                                </span></td><td>750000\\\n",
       "(100.0%)</td><td><span style=white-space:pre-wrap>0\\\n",
       "(0.0%)      </span></td></tr>\n",
       "\t<tr><th scope=row>8</th><td> 8</td><td>Guest_Popularity_percentage\\\n",
       "[numeric]</td><td><span style=white-space:pre-wrap>Mean (sd) : 52.2 (28.5)\\\n",
       "min &lt; med &lt; max:\\\n",
       "0 &lt; 53.6 &lt; 119.9\\\n",
       "IQR (CV) : 48.2 (0.5)                                                                                                                                      </span></td><td><span style=white-space:pre-wrap>10019 distinct values                                                                                                                                                                                                   </span></td><td><span style=white-space:pre-wrap>&lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVCA8tUxeFAAABS0lEQVR42u2bwRGDIBBFIWN16SAp0HRgXenAHBgcRoMisot8/vPkRXmwu66M2tn0waP2AChK0TyG8MSK3GJcysBb5gZRwvozZF/lBE9jjDGTruWKbkK3G1GV0D1im8Xj7MO9VF7fQtRn8ZmpaFT0+lQ0LzoW6lFVRbeDPg7EUo8mVdF1+E3F1quqaIqEXivxV7RM0+bXr6xG7tgiK3q1xsmRO33sjFKp926iLLouKL55y0OuCp8UlV4/mQKWIXrnMrVPdjH6zu6oLSAu2hrdiCbmaEo1dGFcd2coUXRP5w4bXMVE29eJwxx16L0vVhaV61S06SZ0KYoGRdGgKBoURYOiaFAUDYqiQVE0KIoGRdGgKBoURYOiaFAUDYqiQVE0KIoGRdGgKBoURYOiaFAUDYqi0Y2oDT+x/sB8b+14Bb+VWTC3KN2ELkXR+AGM4D3GuUKOYwAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAyNS0wNC0yMVQyMTowODoxNSswMDowMGWU72MAAAAldEVYdGRhdGU6bW9kaWZ5ADIwMjUtMDQtMjFUMjE6MDg6MTUrMDA6MDAUyVffAAAAAElFTkSuQmCC\"&gt;                                                                                </span></td><td>603970\\\n",
       "(80.5%) </td><td>146030\\\n",
       "(19.5%)</td></tr>\n",
       "\t<tr><th scope=row>9</th><td> 9</td><td><span style=white-space:pre-wrap>Number_of_Ads\\\n",
       "[numeric]              </span></td><td><span style=white-space:pre-wrap>Mean (sd) : 1.3 (1.2)\\\n",
       "min &lt; med &lt; max:\\\n",
       "0 &lt; 1 &lt; 103.9\\\n",
       "IQR (CV) : 2 (0.9)                                                                                                                                              </span></td><td><span style=white-space:pre-wrap>12 distinct values                                                                                                                                                                                                      </span></td><td><span style=white-space:pre-wrap>&lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVCBCgWxpwAAAAs0lEQVR42u3cwQnCQBBAUSOpzhIsUDuwPb0IrjmJCgs/711CyGU+7OY4y/2wD8fZAwgV+p11fLkOF/a8zB7td+P/Z33/dHo+b7Nn/LvdHF2hNUJrhNYIrRFaI7RGaI3QGqE1QmuE1gitEVojtEZojdAaoTVCa4TWCK0RWiO0RmiN0BqhNUJrhNYIrRFaI7RGaI3QGqE1QmuE1git2WzWeG3UuBT2/wxrUJZCzyd2c3SF1jwANQAJB63xoakAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjFUMjE6MDg6MTYrMDA6MDBUfPX+AAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIxVDIxOjA4OjE2KzAwOjAwJSFNQgAAAABJRU5ErkJggg==\"&gt;                                                                                                                                                                                                                                                                                        </span></td><td>749999\\\n",
       "(100.0%)</td><td><span style=white-space:pre-wrap>1\\\n",
       "(0.0%)      </span></td></tr>\n",
       "\t<tr><th scope=row>10</th><td>10</td><td><span style=white-space:pre-wrap>Episode_Sentiment\\\n",
       "[character]        </span></td><td><span style=white-space:pre-wrap>1\\. Negative\\\n",
       "2\\. Neutral\\\n",
       "3\\. Positive                                                                                                                                                                                </span></td><td><span style=white-space:pre-wrap>\\250116 (33.3%)\\\n",
       "\\251291 (33.5%)\\\n",
       "\\248593 (33.1%)                                                                                                                                                                </span></td><td><span style=white-space:pre-wrap>&lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAADIAAAA7CAQAAACTORHyAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVCBCgWxpwAAAAeElEQVRYw+3YsQ3AIAxEUTtiOjbIgskGrEdaQyoig4j1r6PxE1AcQqvMz7HACIQku7hrdhpb5NTFOwEBAQH5I5LaZZmCqK1f/TzmHTs36J1cjs0oNCMICAjIJgjNOJSuGR0nm7PvnkSO9WsS505AQEBAnKN82W6HPFCdD3vWiEuiAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDI1LTA0LTIxVDIxOjA4OjE2KzAwOjAwVHz1/gAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyNS0wNC0yMVQyMTowODoxNiswMDowMCUhTUIAAAAASUVORK5CYII=\"&gt;                                                                                                                                                                                                                                                                                                                                                                        </span></td><td>750000\\\n",
       "(100.0%)</td><td><span style=white-space:pre-wrap>0\\\n",
       "(0.0%)      </span></td></tr>\n",
       "\t<tr><th scope=row>11</th><td>11</td><td><span style=white-space:pre-wrap>Listening_Time_minutes\\\n",
       "[numeric]     </span></td><td><span style=white-space:pre-wrap>Mean (sd) : 45.4 (27.1)\\\n",
       "min &lt; med &lt; max:\\\n",
       "0 &lt; 43.4 &lt; 120\\\n",
       "IQR (CV) : 41.6 (0.6)                                                                                                                                        </span></td><td><span style=white-space:pre-wrap>42807 distinct values                                                                                                                                                                                                   </span></td><td>&lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVCBJOVXtcAAABhUlEQVR42u2b0XGDMBBEhccFuC46cAokHbguOiAfCaAgMCAk393evj+PB8aPW4mTwM0QfHCT/gEUpWge9/hDk3GCbhrkXzmHVyWef+7ZZ5loQwghvKStdjgp+q5+3WIC11Xhg6KzRLuhNVe2TY4dv5FUP1zRZUBHne3Idqpu0QXG6Bb7lwJENGWssUSEd0TLxq+9fopaorridwWfndGIrvmyoqjsaPqoaF0k+mMRUYkpzs1kRFE0KIqGsGg/9EM/fKJBYUXRoCgabkRFet2U/m/efVRr8t1UlKJo/BujiFsoq6JWHhjl4Ca6FJXhdzVTYz2jTLQeFEWDomi4EVWyTEsp/XRcrWjpZtRNdCmqhVItoXrRUlAUDTeiau+jS642EGZEr74Q5Ca6FEWDomiYE83dEDUnmgtF0aAoGmZ63ZRzbb5h0XP7hIyuHY5FGED02EqV0bXH+wgDic7/VV5TZXQtMy3hospCiq61Em6i60a0iXckvsHe7nxGY7QBc9vETXQpisYP9XNcCznJq+YAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjFUMjE6MDg6MTgrMDA6MDAEQ46jAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIxVDIxOjA4OjE4KzAwOjAwdR42HwAAAABJRU5ErkJggg==\"&gt;</td><td>750000\\\n",
       "(100.0%)</td><td><span style=white-space:pre-wrap>0\\\n",
       "(0.0%)      </span></td></tr>\n",
       "</tbody>\n",
       "</table>\n"
      ],
      "text/latex": [
       "A summarytools: 11 × 7\n",
       "\\begin{tabular}{r|lllllll}\n",
       "  & No & Variable & Stats / Values & Freqs (\\% of Valid) & Graph & Valid & Missing\\\\\n",
       "  & <dbl> & <chr> & <chr> & <chr> & <chr> & <chr> & <chr>\\\\\n",
       "\\hline\n",
       "\t1 &  1 & Podcast\\_Name\\textbackslash{}\n",
       "{[}character{]}              & 1\\textbackslash{}. Tech Talks\\textbackslash{}\n",
       "2\\textbackslash{}. Sports Weekly\\textbackslash{}\n",
       "3\\textbackslash{}. Funny Folks\\textbackslash{}\n",
       "4\\textbackslash{}. Tech Trends\\textbackslash{}\n",
       "5\\textbackslash{}. Fitness First\\textbackslash{}\n",
       "6\\textbackslash{}. Business Insights\\textbackslash{}\n",
       "7\\textbackslash{}. Style Guide\\textbackslash{}\n",
       "8\\textbackslash{}. Game Day\\textbackslash{}\n",
       "9\\textbackslash{}. Melody Mix\\textbackslash{}\n",
       "10\\textbackslash{}. Criminal Minds\\textbackslash{}\n",
       "{[} 38 others {]} & \\textbackslash{} 22847 ( 3.0\\%)\\textbackslash{}\n",
       "\\textbackslash{} 20053 ( 2.7\\%)\\textbackslash{}\n",
       "\\textbackslash{} 19635 ( 2.6\\%)\\textbackslash{}\n",
       "\\textbackslash{} 19549 ( 2.6\\%)\\textbackslash{}\n",
       "\\textbackslash{} 19488 ( 2.6\\%)\\textbackslash{}\n",
       "\\textbackslash{} 19480 ( 2.6\\%)\\textbackslash{}\n",
       "\\textbackslash{} 19364 ( 2.6\\%)\\textbackslash{}\n",
       "\\textbackslash{} 19272 ( 2.6\\%)\\textbackslash{}\n",
       "\\textbackslash{} 18889 ( 2.5\\%)\\textbackslash{}\n",
       "\\textbackslash{} 17735 ( 2.4\\%)\\textbackslash{}\n",
       "\\textbackslash{}553688 (73.8\\%) & <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAF8AAADKCAQAAABp7lSOAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVCAsqPtOcAAABc0lEQVR42u3bQYrCQBRF0aRxdS6hFxh30OtyB3Fg01QkCPYgv17lXEfODlKBPCjndUruqxqAn9ul/XL7fRC+52rWu9qn9eXXv07Xat1HhR8efHz8yPDx8SPDr+yy/fpT7fmwuX177vo1/6837/tpbQ7PErG22qwtfPzI8PHxI8PHPyvfXKksnG9tdcRPCx8fPzJ8fPzI8Cuztiobib+s9/W+LkEXa0f69fPCx8ePDB8fP7Jwvqt4R2dt9ZK1hY8fGT4+fmT4+GflW1tHN9Da2rmKl3MRb5qmtflkrK1WHH548PHxI8PHx48Mv7KdtZX0wmxtVeaPTx3x08LHx48MHx8/MvzKzJXKwvnWVkf8tPDx8SPDx8ePDL8ya6uykfjPq3jVpH/z88LHx48MHx8/MvzK/PHp6KytXrK28PEjw8fHjwwf/6x8a+voBlpbu1fxOq85JC9nv/+LeNunM/zw4OPjR4aPjx8ZfmUjra28wg8PfmUPPABb6rm7Ea0AAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjFUMjE6MDg6MTErMDA6MDCR28twAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIxVDIxOjA4OjExKzAwOjAw4IZzzAAAAABJRU5ErkJggg==\">                         & 750000\\textbackslash{}\n",
       "(100.0\\%) & 0\\textbackslash{}\n",
       "(0.0\\%)      \\\\\n",
       "\t2 &  2 & Episode\\_Title\\textbackslash{}\n",
       "{[}character{]}             & 1\\textbackslash{}. Episode 71\\textbackslash{}\n",
       "2\\textbackslash{}. Episode 62\\textbackslash{}\n",
       "3\\textbackslash{}. Episode 31\\textbackslash{}\n",
       "4\\textbackslash{}. Episode 61\\textbackslash{}\n",
       "5\\textbackslash{}. Episode 69\\textbackslash{}\n",
       "6\\textbackslash{}. Episode 23\\textbackslash{}\n",
       "7\\textbackslash{}. Episode 63\\textbackslash{}\n",
       "8\\textbackslash{}. Episode 81\\textbackslash{}\n",
       "9\\textbackslash{}. Episode 64\\textbackslash{}\n",
       "10\\textbackslash{}. Episode 72\\textbackslash{}\n",
       "{[} 90 others {]}                   & \\textbackslash{} 10515 ( 1.4\\%)\\textbackslash{}\n",
       "\\textbackslash{} 10373 ( 1.4\\%)\\textbackslash{}\n",
       "\\textbackslash{} 10292 ( 1.4\\%)\\textbackslash{}\n",
       "\\textbackslash{}  9991 ( 1.3\\%)\\textbackslash{}\n",
       "\\textbackslash{}  9864 ( 1.3\\%)\\textbackslash{}\n",
       "\\textbackslash{}  9762 ( 1.3\\%)\\textbackslash{}\n",
       "\\textbackslash{}  9743 ( 1.3\\%)\\textbackslash{}\n",
       "\\textbackslash{}  9741 ( 1.3\\%)\\textbackslash{}\n",
       "\\textbackslash{}  9686 ( 1.3\\%)\\textbackslash{}\n",
       "\\textbackslash{}  9554 ( 1.3\\%)\\textbackslash{}\n",
       "\\textbackslash{}650479 (86.7\\%) & <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAG0AAADKCAQAAAAF6AaLAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVCAsqPtOcAAABX0lEQVR42u3YwWnDQBRFUSm4unSQFOh0kPac7STglQPi/LlnZeHNXCSEn8/HMdXb1QcorbTVbb34ehzH53n1kV6xvjkG37XSRKWJShOVJipNVJqoNNG5Lhx6qh3Hsedeuz/ug/7g2uWuzVKaqDRRaaLSRKWJShM1RUW7pLWyEaWJShOVJipNVJqoNNHgtFa2aJe0VjaiNFFpotJEpYlKE5UmGpzWyhbtktbKRpQmKk1Umqg0UWmi0kSD01rZoqaoqDRRaaLSRKWJShOVJipN1MoWtbJFpYlKE5UmKk1Umqg00eC0pqhol7RWNqI0UWmi0kSliUoTlSYanNbKFu2S1spGlCYqTVSaqDRRaaLSRIPTWtmiXdJa2YjSRKWJShOVJipNVJpocForW3RbLwYM0eXBu/3+5v3qo/2jwQ9kaaLSRKWJShOVJipN9OeX//fV53nRx/L59CfaM4MfyNJEP0K2Ox7416vXAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDI1LTA0LTIxVDIxOjA4OjExKzAwOjAwkdvLcAAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyNS0wNC0yMVQyMTowODoxMSswMDowMOCGc8wAAAAASUVORK5CYII=\">                                                     & 750000\\textbackslash{}\n",
       "(100.0\\%) & 0\\textbackslash{}\n",
       "(0.0\\%)      \\\\\n",
       "\t3 &  3 & Episode\\_Length\\_minutes\\textbackslash{}\n",
       "{[}numeric{]}      & Mean (sd) : 64.5 (33)\\textbackslash{}\n",
       "min < med < max:\\textbackslash{}\n",
       "0 < 63.8 < 325.2\\textbackslash{}\n",
       "IQR (CV) : 58.3 (0.5)                                                                                                                                         & 12268 distinct values                                                                                                                                                                                                    & <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVCAy0WkY/AAAA5klEQVR42u3cwQ2CMBhAYWuYzg10wLqBc7kB3kiJEpFiWt7/Hhe4NHwBSgKENJ5idG69A0KFbmsoN1LFQHl2sd9qhtqtcpeGzaO8dZnWHq2FH1qE9niE/gLt/Qj9WpjJSCitKmgen9PSGvKtlbeX3D1kJ2g5Ax9zNvYapSWUllBaQmkJpSWUllBaQmkJpSWUllBaQmmFgc6e1B//xcNKKO3lb1mYU1coLaG0hNISSksoLaG0hNISSksoLaG0hNISSksoLaG0hNISSksoLaG0wkBT+WnRHfad0bX4TUaC2RYLc+oKpfUCK5UeTY+BarAAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjFUMjE6MDg6MTIrMDA6MDCgM9HtAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIxVDIxOjA4OjEyKzAwOjAw0W5pUQAAAABJRU5ErkJggg==\">                                                                                                                                                                                                                     & 662907\\textbackslash{}\n",
       "(88.4\\%)  & 87093\\textbackslash{}\n",
       "(11.6\\%) \\\\\n",
       "\t4 &  4 & Genre\\textbackslash{}\n",
       "{[}character{]}                     & 1\\textbackslash{}. Business\\textbackslash{}\n",
       "2\\textbackslash{}. Comedy\\textbackslash{}\n",
       "3\\textbackslash{}. Education\\textbackslash{}\n",
       "4\\textbackslash{}. Health\\textbackslash{}\n",
       "5\\textbackslash{}. Lifestyle\\textbackslash{}\n",
       "6\\textbackslash{}. Music\\textbackslash{}\n",
       "7\\textbackslash{}. News\\textbackslash{}\n",
       "8\\textbackslash{}. Sports\\textbackslash{}\n",
       "9\\textbackslash{}. Technology\\textbackslash{}\n",
       "10\\textbackslash{}. True Crime                                                               & \\textbackslash{}80521 (10.7\\%)\\textbackslash{}\n",
       "\\textbackslash{}81453 (10.9\\%)\\textbackslash{}\n",
       "\\textbackslash{}49100 ( 6.5\\%)\\textbackslash{}\n",
       "\\textbackslash{}71416 ( 9.5\\%)\\textbackslash{}\n",
       "\\textbackslash{}82461 (11.0\\%)\\textbackslash{}\n",
       "\\textbackslash{}62743 ( 8.4\\%)\\textbackslash{}\n",
       "\\textbackslash{}63385 ( 8.5\\%)\\textbackslash{}\n",
       "\\textbackslash{}87606 (11.7\\%)\\textbackslash{}\n",
       "\\textbackslash{}86256 (11.5\\%)\\textbackslash{}\n",
       "\\textbackslash{}85059 (11.3\\%)                               & <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAABoAAAC3CAQAAACmwYZ1AAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVCAy0WkY/AAAAy0lEQVRo3u2awQ2DMBAEfRHVpQQXSDqgLjpwHvmwxo4OiMiBZnhZ8kg+jgVbwkrazmOHc6I0LAev8mxOmlK2Ze3Ba0JCUgYdTi5JHnn7MvFwNGR5Y/ctk60rpdRLrhK8T0hIypWTm80haXL79QXvExKScuXkfljn1/XNrQneJyQk5bwQsltGQvqdFDy5Io1lrq52loPfciQkJfjGl+QiITUJnlznxleX4Tyyaq3B+4SEpNwjuTuOrDXB+4SEpJDcI8tDQvqXZDf8HeoNSZBWhwHfHEYAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjFUMjE6MDg6MTIrMDA6MDCgM9HtAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIxVDIxOjA4OjEyKzAwOjAw0W5pUQAAAABJRU5ErkJggg==\">                                                                                                                                                                                                                                                         & 750000\\textbackslash{}\n",
       "(100.0\\%) & 0\\textbackslash{}\n",
       "(0.0\\%)      \\\\\n",
       "\t5 &  5 & Host\\_Popularity\\_percentage\\textbackslash{}\n",
       "{[}numeric{]}  & Mean (sd) : 59.9 (22.9)\\textbackslash{}\n",
       "min < med < max:\\textbackslash{}\n",
       "1.3 < 60 < 119.5\\textbackslash{}\n",
       "IQR (CV) : 40.1 (0.4)                                                                                                                                       & 8038 distinct values                                                                                                                                                                                                     & <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVCA5aVCcTAAABK0lEQVR42u3b0Q2CMABFUWqYjg10QNyAudgAPxCoSiNtKdDXe3+MJhAPlBajmqEqo9vZbwAo0LBq+4nx2LCdL+6Hz2aHZs8/dehOmvdjd7ZmY8UMXaBqAVWrGGjw8rI0rajjgtNFravpVucdoBNwO2Lpm5Nudd4B6ntIlrqqH8bH3/M3HZa9zmxCaNww3DpOLgC91k3ioUPXXev8/O8e3FlCm/hd/Il19KqFTnHZQD9vS/ynuGygsVdxAmg/rL9y7jJTzGQEVC3Pa7TN9hsM78ko/T1MmooZukDVAqoWULWAqgVULaBqAVULqFpA1QKqFlC1gKoFVC2gagFVC6haQNUCqhZQtYCqBVQtoGoBVQuoWsVAjf0j+We2v5hf7279qcuI2ZwVM3SBqvUCy9ktIuH0SSgAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjFUMjE6MDg6MTQrMDA6MDDD4+TXAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIxVDIxOjA4OjE0KzAwOjAwsr5cawAAAABJRU5ErkJggg==\">                                                                                                                         & 750000\\textbackslash{}\n",
       "(100.0\\%) & 0\\textbackslash{}\n",
       "(0.0\\%)      \\\\\n",
       "\t6 &  6 & Publication\\_Day\\textbackslash{}\n",
       "{[}character{]}           & 1\\textbackslash{}. Friday\\textbackslash{}\n",
       "2\\textbackslash{}. Monday\\textbackslash{}\n",
       "3\\textbackslash{}. Saturday\\textbackslash{}\n",
       "4\\textbackslash{}. Sunday\\textbackslash{}\n",
       "5\\textbackslash{}. Thursday\\textbackslash{}\n",
       "6\\textbackslash{}. Tuesday\\textbackslash{}\n",
       "7\\textbackslash{}. Wednesday                                                                                                                  & \\textbackslash{}108237 (14.4\\%)\\textbackslash{}\n",
       "\\textbackslash{}111963 (14.9\\%)\\textbackslash{}\n",
       "\\textbackslash{}103505 (13.8\\%)\\textbackslash{}\n",
       "\\textbackslash{}115946 (15.5\\%)\\textbackslash{}\n",
       "\\textbackslash{}104360 (13.9\\%)\\textbackslash{}\n",
       "\\textbackslash{} 98103 (13.1\\%)\\textbackslash{}\n",
       "\\textbackslash{}107886 (14.4\\%)                                                                                 & <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAB4AAACCCAQAAAD7nbARAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVCA5aVCcTAAAArElEQVRYw+3Z2w2AIAwF0NYwnSN0QN2A9fDX+iiiNqZy+SPhJNCGG6Jc6P4YHtgPcVpP5jKaizMJr2sU9MzAwL446WluwuqK8QXw2pVU256qaSh8ionGmlYjaJ+BgX1xD0kibGA7Sfb1CNpnYGBf3EOSbLfX+CbRNQnaZ2BgX9xDkuBNAgzsjf+fJMImtpLkqBpB+wwM7Iv/nyREj764bisStM/AwL6YO/wLvACUmyhPC06I2AAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAyNS0wNC0yMVQyMTowODoxNCswMDowMMPj5NcAAAAldEVYdGRhdGU6bW9kaWZ5ADIwMjUtMDQtMjFUMjE6MDg6MTQrMDA6MDCyvlxrAAAAAElFTkSuQmCC\">                                                                                                                                                                                                                                                                                                     & 750000\\textbackslash{}\n",
       "(100.0\\%) & 0\\textbackslash{}\n",
       "(0.0\\%)      \\\\\n",
       "\t7 &  7 & Publication\\_Time\\textbackslash{}\n",
       "{[}character{]}          & 1\\textbackslash{}. Afternoon\\textbackslash{}\n",
       "2\\textbackslash{}. Evening\\textbackslash{}\n",
       "3\\textbackslash{}. Morning\\textbackslash{}\n",
       "4\\textbackslash{}. Night                                                                                                                                                                   & \\textbackslash{}179460 (23.9\\%)\\textbackslash{}\n",
       "\\textbackslash{}195778 (26.1\\%)\\textbackslash{}\n",
       "\\textbackslash{}177913 (23.7\\%)\\textbackslash{}\n",
       "\\textbackslash{}196849 (26.2\\%)                                                                                                                                             & <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAACoAAABOCAQAAAD8r0ycAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVCA5aVCcTAAAAiklEQVRYw+3WSw6AIAxF0dawOpfAAnUHbk+HFHXEJ2nD7cxETvKEPNRbxs82wQyEJvtwNn3grCIidmmqX9j9xgcFBV0TfbXUNQRV24PaAVlnfvyj52o1MQc1f70XcY4UKCioe5TmL9PW/PkTsLv5/3YhzpECBQV1j9L8ZfjnBwUFXQOd3/yu48dBH/iKFxn/tftSAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDI1LTA0LTIxVDIxOjA4OjE0KzAwOjAww+Pk1wAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyNS0wNC0yMVQyMTowODoxNCswMDowMLK+XGsAAAAASUVORK5CYII=\">                                                                                                                                                                                                                                                                                                                                                 & 750000\\textbackslash{}\n",
       "(100.0\\%) & 0\\textbackslash{}\n",
       "(0.0\\%)      \\\\\n",
       "\t8 &  8 & Guest\\_Popularity\\_percentage\\textbackslash{}\n",
       "{[}numeric{]} & Mean (sd) : 52.2 (28.5)\\textbackslash{}\n",
       "min < med < max:\\textbackslash{}\n",
       "0 < 53.6 < 119.9\\textbackslash{}\n",
       "IQR (CV) : 48.2 (0.5)                                                                                                                                       & 10019 distinct values                                                                                                                                                                                                    & <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVCA8tUxeFAAABS0lEQVR42u2bwRGDIBBFIWN16SAp0HRgXenAHBgcRoMisot8/vPkRXmwu66M2tn0waP2AChK0TyG8MSK3GJcysBb5gZRwvozZF/lBE9jjDGTruWKbkK3G1GV0D1im8Xj7MO9VF7fQtRn8ZmpaFT0+lQ0LzoW6lFVRbeDPg7EUo8mVdF1+E3F1quqaIqEXivxV7RM0+bXr6xG7tgiK3q1xsmRO33sjFKp926iLLouKL55y0OuCp8UlV4/mQKWIXrnMrVPdjH6zu6oLSAu2hrdiCbmaEo1dGFcd2coUXRP5w4bXMVE29eJwxx16L0vVhaV61S06SZ0KYoGRdGgKBoURYOiaFAUDYqiQVE0KIoGRdGgKBoURYOiaFAUDYqiQVE0KIoGRdGgKBoURYOiaFAUDYqi0Y2oDT+x/sB8b+14Bb+VWTC3KN2ELkXR+AGM4D3GuUKOYwAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAyNS0wNC0yMVQyMTowODoxNSswMDowMGWU72MAAAAldEVYdGRhdGU6bW9kaWZ5ADIwMjUtMDQtMjFUMjE6MDg6MTUrMDA6MDAUyVffAAAAAElFTkSuQmCC\">                                                                                 & 603970\\textbackslash{}\n",
       "(80.5\\%)  & 146030\\textbackslash{}\n",
       "(19.5\\%)\\\\\n",
       "\t9 &  9 & Number\\_of\\_Ads\\textbackslash{}\n",
       "{[}numeric{]}               & Mean (sd) : 1.3 (1.2)\\textbackslash{}\n",
       "min < med < max:\\textbackslash{}\n",
       "0 < 1 < 103.9\\textbackslash{}\n",
       "IQR (CV) : 2 (0.9)                                                                                                                                               & 12 distinct values                                                                                                                                                                                                       & <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVCBCgWxpwAAAAs0lEQVR42u3cwQnCQBBAUSOpzhIsUDuwPb0IrjmJCgs/711CyGU+7OY4y/2wD8fZAwgV+p11fLkOF/a8zB7td+P/Z33/dHo+b7Nn/LvdHF2hNUJrhNYIrRFaI7RGaI3QGqE1QmuE1gitEVojtEZojdAaoTVCa4TWCK0RWiO0RmiN0BqhNUJrhNYIrRFaI7RGaI3QGqE1QmuE1git2WzWeG3UuBT2/wxrUJZCzyd2c3SF1jwANQAJB63xoakAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjFUMjE6MDg6MTYrMDA6MDBUfPX+AAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIxVDIxOjA4OjE2KzAwOjAwJSFNQgAAAABJRU5ErkJggg==\">                                                                                                                                                                                                                                                                                         & 749999\\textbackslash{}\n",
       "(100.0\\%) & 1\\textbackslash{}\n",
       "(0.0\\%)      \\\\\n",
       "\t10 & 10 & Episode\\_Sentiment\\textbackslash{}\n",
       "{[}character{]}         & 1\\textbackslash{}. Negative\\textbackslash{}\n",
       "2\\textbackslash{}. Neutral\\textbackslash{}\n",
       "3\\textbackslash{}. Positive                                                                                                                                                                                 & \\textbackslash{}250116 (33.3\\%)\\textbackslash{}\n",
       "\\textbackslash{}251291 (33.5\\%)\\textbackslash{}\n",
       "\\textbackslash{}248593 (33.1\\%)                                                                                                                                                                 & <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAADIAAAA7CAQAAACTORHyAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVCBCgWxpwAAAAeElEQVRYw+3YsQ3AIAxEUTtiOjbIgskGrEdaQyoig4j1r6PxE1AcQqvMz7HACIQku7hrdhpb5NTFOwEBAQH5I5LaZZmCqK1f/TzmHTs36J1cjs0oNCMICAjIJgjNOJSuGR0nm7PvnkSO9WsS505AQEBAnKN82W6HPFCdD3vWiEuiAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDI1LTA0LTIxVDIxOjA4OjE2KzAwOjAwVHz1/gAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyNS0wNC0yMVQyMTowODoxNiswMDowMCUhTUIAAAAASUVORK5CYII=\">                                                                                                                                                                                                                                                                                                                                                                         & 750000\\textbackslash{}\n",
       "(100.0\\%) & 0\\textbackslash{}\n",
       "(0.0\\%)      \\\\\n",
       "\t11 & 11 & Listening\\_Time\\_minutes\\textbackslash{}\n",
       "{[}numeric{]}      & Mean (sd) : 45.4 (27.1)\\textbackslash{}\n",
       "min < med < max:\\textbackslash{}\n",
       "0 < 43.4 < 120\\textbackslash{}\n",
       "IQR (CV) : 41.6 (0.6)                                                                                                                                         & 42807 distinct values                                                                                                                                                                                                    & <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVCBJOVXtcAAABhUlEQVR42u2b0XGDMBBEhccFuC46cAokHbguOiAfCaAgMCAk393evj+PB8aPW4mTwM0QfHCT/gEUpWge9/hDk3GCbhrkXzmHVyWef+7ZZ5loQwghvKStdjgp+q5+3WIC11Xhg6KzRLuhNVe2TY4dv5FUP1zRZUBHne3Idqpu0QXG6Bb7lwJENGWssUSEd0TLxq+9fopaorridwWfndGIrvmyoqjsaPqoaF0k+mMRUYkpzs1kRFE0KIqGsGg/9EM/fKJBYUXRoCgabkRFet2U/m/efVRr8t1UlKJo/BujiFsoq6JWHhjl4Ca6FJXhdzVTYz2jTLQeFEWDomi4EVWyTEsp/XRcrWjpZtRNdCmqhVItoXrRUlAUDTeiau+jS642EGZEr74Q5Ca6FEWDomiYE83dEDUnmgtF0aAoGmZ63ZRzbb5h0XP7hIyuHY5FGED02EqV0bXH+wgDic7/VV5TZXQtMy3hospCiq61Em6i60a0iXckvsHe7nxGY7QBc9vETXQpisYP9XNcCznJq+YAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjFUMjE6MDg6MTgrMDA6MDAEQ46jAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIxVDIxOjA4OjE4KzAwOjAwdR42HwAAAABJRU5ErkJggg==\"> & 750000\\textbackslash{}\n",
       "(100.0\\%) & 0\\textbackslash{}\n",
       "(0.0\\%)      \\\\\n",
       "\\end{tabular}\n"
      ],
      "text/markdown": [
       "\n",
       "A summarytools: 11 × 7\n",
       "\n",
       "| <!--/--> | No &lt;dbl&gt; | Variable &lt;chr&gt; | Stats / Values &lt;chr&gt; | Freqs (% of Valid) &lt;chr&gt; | Graph &lt;chr&gt; | Valid &lt;chr&gt; | Missing &lt;chr&gt; |\n",
       "|---|---|---|---|---|---|---|---|\n",
       "| 1 |  1 | Podcast_Name\\\n",
       "[character]              | 1\\. Tech Talks\\\n",
       "2\\. Sports Weekly\\\n",
       "3\\. Funny Folks\\\n",
       "4\\. Tech Trends\\\n",
       "5\\. Fitness First\\\n",
       "6\\. Business Insights\\\n",
       "7\\. Style Guide\\\n",
       "8\\. Game Day\\\n",
       "9\\. Melody Mix\\\n",
       "10\\. Criminal Minds\\\n",
       "[ 38 others ] | \\ 22847 ( 3.0%)\\\n",
       "\\ 20053 ( 2.7%)\\\n",
       "\\ 19635 ( 2.6%)\\\n",
       "\\ 19549 ( 2.6%)\\\n",
       "\\ 19488 ( 2.6%)\\\n",
       "\\ 19480 ( 2.6%)\\\n",
       "\\ 19364 ( 2.6%)\\\n",
       "\\ 19272 ( 2.6%)\\\n",
       "\\ 18889 ( 2.5%)\\\n",
       "\\ 17735 ( 2.4%)\\\n",
       "\\553688 (73.8%) | &lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAF8AAADKCAQAAABp7lSOAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVCAsqPtOcAAABc0lEQVR42u3bQYrCQBRF0aRxdS6hFxh30OtyB3Fg01QkCPYgv17lXEfODlKBPCjndUruqxqAn9ul/XL7fRC+52rWu9qn9eXXv07Xat1HhR8efHz8yPDx8SPDr+yy/fpT7fmwuX177vo1/6837/tpbQ7PErG22qwtfPzI8PHxI8PHPyvfXKksnG9tdcRPCx8fPzJ8fPzI8Cuztiobib+s9/W+LkEXa0f69fPCx8ePDB8fP7Jwvqt4R2dt9ZK1hY8fGT4+fmT4+GflW1tHN9Da2rmKl3MRb5qmtflkrK1WHH548PHxI8PHx48Mv7KdtZX0wmxtVeaPTx3x08LHx48MHx8/MvzKzJXKwvnWVkf8tPDx8SPDx8ePDL8ya6uykfjPq3jVpH/z88LHx48MHx8/MvzK/PHp6KytXrK28PEjw8fHjwwf/6x8a+voBlpbu1fxOq85JC9nv/+LeNunM/zw4OPjR4aPjx8ZfmUjra28wg8PfmUPPABb6rm7Ea0AAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjFUMjE6MDg6MTErMDA6MDCR28twAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIxVDIxOjA4OjExKzAwOjAw4IZzzAAAAABJRU5ErkJggg==\"&gt;                         | 750000\\\n",
       "(100.0%) | 0\\\n",
       "(0.0%)       |\n",
       "| 2 |  2 | Episode_Title\\\n",
       "[character]             | 1\\. Episode 71\\\n",
       "2\\. Episode 62\\\n",
       "3\\. Episode 31\\\n",
       "4\\. Episode 61\\\n",
       "5\\. Episode 69\\\n",
       "6\\. Episode 23\\\n",
       "7\\. Episode 63\\\n",
       "8\\. Episode 81\\\n",
       "9\\. Episode 64\\\n",
       "10\\. Episode 72\\\n",
       "[ 90 others ]                   | \\ 10515 ( 1.4%)\\\n",
       "\\ 10373 ( 1.4%)\\\n",
       "\\ 10292 ( 1.4%)\\\n",
       "\\  9991 ( 1.3%)\\\n",
       "\\  9864 ( 1.3%)\\\n",
       "\\  9762 ( 1.3%)\\\n",
       "\\  9743 ( 1.3%)\\\n",
       "\\  9741 ( 1.3%)\\\n",
       "\\  9686 ( 1.3%)\\\n",
       "\\  9554 ( 1.3%)\\\n",
       "\\650479 (86.7%) | &lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAG0AAADKCAQAAAAF6AaLAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVCAsqPtOcAAABX0lEQVR42u3YwWnDQBRFUSm4unSQFOh0kPac7STglQPi/LlnZeHNXCSEn8/HMdXb1QcorbTVbb34ehzH53n1kV6xvjkG37XSRKWJShOVJipNVJqoNNG5Lhx6qh3Hsedeuz/ug/7g2uWuzVKaqDRRaaLSRKWJShM1RUW7pLWyEaWJShOVJipNVJqoNNHgtFa2aJe0VjaiNFFpotJEpYlKE5UmGpzWyhbtktbKRpQmKk1Umqg0UWmi0kSD01rZoqaoqDRRaaLSRKWJShOVJipN1MoWtbJFpYlKE5UmKk1Umqg00eC0pqhol7RWNqI0UWmi0kSliUoTlSYanNbKFu2S1spGlCYqTVSaqDRRaaLSRIPTWtmiXdJa2YjSRKWJShOVJipNVJpocForW3RbLwYM0eXBu/3+5v3qo/2jwQ9kaaLSRKWJShOVJipN9OeX//fV53nRx/L59CfaM4MfyNJEP0K2Ox7416vXAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDI1LTA0LTIxVDIxOjA4OjExKzAwOjAwkdvLcAAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyNS0wNC0yMVQyMTowODoxMSswMDowMOCGc8wAAAAASUVORK5CYII=\"&gt;                                                     | 750000\\\n",
       "(100.0%) | 0\\\n",
       "(0.0%)       |\n",
       "| 3 |  3 | Episode_Length_minutes\\\n",
       "[numeric]      | Mean (sd) : 64.5 (33)\\\n",
       "min &lt; med &lt; max:\\\n",
       "0 &lt; 63.8 &lt; 325.2\\\n",
       "IQR (CV) : 58.3 (0.5)                                                                                                                                         | 12268 distinct values                                                                                                                                                                                                    | &lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVCAy0WkY/AAAA5klEQVR42u3cwQ2CMBhAYWuYzg10wLqBc7kB3kiJEpFiWt7/Hhe4NHwBSgKENJ5idG69A0KFbmsoN1LFQHl2sd9qhtqtcpeGzaO8dZnWHq2FH1qE9niE/gLt/Qj9WpjJSCitKmgen9PSGvKtlbeX3D1kJ2g5Ax9zNvYapSWUllBaQmkJpSWUllBaQmkJpSWUllBaQmmFgc6e1B//xcNKKO3lb1mYU1coLaG0hNISSksoLaG0hNISSksoLaG0hNISSksoLaG0hNISSksoLaG0wkBT+WnRHfad0bX4TUaC2RYLc+oKpfUCK5UeTY+BarAAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjFUMjE6MDg6MTIrMDA6MDCgM9HtAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIxVDIxOjA4OjEyKzAwOjAw0W5pUQAAAABJRU5ErkJggg==\"&gt;                                                                                                                                                                                                                     | 662907\\\n",
       "(88.4%)  | 87093\\\n",
       "(11.6%)  |\n",
       "| 4 |  4 | Genre\\\n",
       "[character]                     | 1\\. Business\\\n",
       "2\\. Comedy\\\n",
       "3\\. Education\\\n",
       "4\\. Health\\\n",
       "5\\. Lifestyle\\\n",
       "6\\. Music\\\n",
       "7\\. News\\\n",
       "8\\. Sports\\\n",
       "9\\. Technology\\\n",
       "10\\. True Crime                                                               | \\80521 (10.7%)\\\n",
       "\\81453 (10.9%)\\\n",
       "\\49100 ( 6.5%)\\\n",
       "\\71416 ( 9.5%)\\\n",
       "\\82461 (11.0%)\\\n",
       "\\62743 ( 8.4%)\\\n",
       "\\63385 ( 8.5%)\\\n",
       "\\87606 (11.7%)\\\n",
       "\\86256 (11.5%)\\\n",
       "\\85059 (11.3%)                               | &lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAABoAAAC3CAQAAACmwYZ1AAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVCAy0WkY/AAAAy0lEQVRo3u2awQ2DMBAEfRHVpQQXSDqgLjpwHvmwxo4OiMiBZnhZ8kg+jgVbwkrazmOHc6I0LAev8mxOmlK2Ze3Ba0JCUgYdTi5JHnn7MvFwNGR5Y/ctk60rpdRLrhK8T0hIypWTm80haXL79QXvExKScuXkfljn1/XNrQneJyQk5bwQsltGQvqdFDy5Io1lrq52loPfciQkJfjGl+QiITUJnlznxleX4Tyyaq3B+4SEpNwjuTuOrDXB+4SEpJDcI8tDQvqXZDf8HeoNSZBWhwHfHEYAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjFUMjE6MDg6MTIrMDA6MDCgM9HtAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIxVDIxOjA4OjEyKzAwOjAw0W5pUQAAAABJRU5ErkJggg==\"&gt;                                                                                                                                                                                                                                                         | 750000\\\n",
       "(100.0%) | 0\\\n",
       "(0.0%)       |\n",
       "| 5 |  5 | Host_Popularity_percentage\\\n",
       "[numeric]  | Mean (sd) : 59.9 (22.9)\\\n",
       "min &lt; med &lt; max:\\\n",
       "1.3 &lt; 60 &lt; 119.5\\\n",
       "IQR (CV) : 40.1 (0.4)                                                                                                                                       | 8038 distinct values                                                                                                                                                                                                     | &lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVCA5aVCcTAAABK0lEQVR42u3b0Q2CMABFUWqYjg10QNyAudgAPxCoSiNtKdDXe3+MJhAPlBajmqEqo9vZbwAo0LBq+4nx2LCdL+6Hz2aHZs8/dehOmvdjd7ZmY8UMXaBqAVWrGGjw8rI0rajjgtNFravpVucdoBNwO2Lpm5Nudd4B6ntIlrqqH8bH3/M3HZa9zmxCaNww3DpOLgC91k3ioUPXXev8/O8e3FlCm/hd/Il19KqFTnHZQD9vS/ynuGygsVdxAmg/rL9y7jJTzGQEVC3Pa7TN9hsM78ko/T1MmooZukDVAqoWULWAqgVULaBqAVULqFpA1QKqFlC1gKoFVC2gagFVC6haQNUCqhZQtYCqBVQtoGoBVQuoWsVAjf0j+We2v5hf7279qcuI2ZwVM3SBqvUCy9ktIuH0SSgAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjFUMjE6MDg6MTQrMDA6MDDD4+TXAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIxVDIxOjA4OjE0KzAwOjAwsr5cawAAAABJRU5ErkJggg==\"&gt;                                                                                                                         | 750000\\\n",
       "(100.0%) | 0\\\n",
       "(0.0%)       |\n",
       "| 6 |  6 | Publication_Day\\\n",
       "[character]           | 1\\. Friday\\\n",
       "2\\. Monday\\\n",
       "3\\. Saturday\\\n",
       "4\\. Sunday\\\n",
       "5\\. Thursday\\\n",
       "6\\. Tuesday\\\n",
       "7\\. Wednesday                                                                                                                  | \\108237 (14.4%)\\\n",
       "\\111963 (14.9%)\\\n",
       "\\103505 (13.8%)\\\n",
       "\\115946 (15.5%)\\\n",
       "\\104360 (13.9%)\\\n",
       "\\ 98103 (13.1%)\\\n",
       "\\107886 (14.4%)                                                                                 | &lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAB4AAACCCAQAAAD7nbARAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVCA5aVCcTAAAArElEQVRYw+3Z2w2AIAwF0NYwnSN0QN2A9fDX+iiiNqZy+SPhJNCGG6Jc6P4YHtgPcVpP5jKaizMJr2sU9MzAwL446WluwuqK8QXw2pVU256qaSh8ionGmlYjaJ+BgX1xD0kibGA7Sfb1CNpnYGBf3EOSbLfX+CbRNQnaZ2BgX9xDkuBNAgzsjf+fJMImtpLkqBpB+wwM7Iv/nyREj764bisStM/AwL6YO/wLvACUmyhPC06I2AAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAyNS0wNC0yMVQyMTowODoxNCswMDowMMPj5NcAAAAldEVYdGRhdGU6bW9kaWZ5ADIwMjUtMDQtMjFUMjE6MDg6MTQrMDA6MDCyvlxrAAAAAElFTkSuQmCC\"&gt;                                                                                                                                                                                                                                                                                                     | 750000\\\n",
       "(100.0%) | 0\\\n",
       "(0.0%)       |\n",
       "| 7 |  7 | Publication_Time\\\n",
       "[character]          | 1\\. Afternoon\\\n",
       "2\\. Evening\\\n",
       "3\\. Morning\\\n",
       "4\\. Night                                                                                                                                                                   | \\179460 (23.9%)\\\n",
       "\\195778 (26.1%)\\\n",
       "\\177913 (23.7%)\\\n",
       "\\196849 (26.2%)                                                                                                                                             | &lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAACoAAABOCAQAAAD8r0ycAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVCA5aVCcTAAAAiklEQVRYw+3WSw6AIAxF0dawOpfAAnUHbk+HFHXEJ2nD7cxETvKEPNRbxs82wQyEJvtwNn3grCIidmmqX9j9xgcFBV0TfbXUNQRV24PaAVlnfvyj52o1MQc1f70XcY4UKCioe5TmL9PW/PkTsLv5/3YhzpECBQV1j9L8ZfjnBwUFXQOd3/yu48dBH/iKFxn/tftSAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDI1LTA0LTIxVDIxOjA4OjE0KzAwOjAww+Pk1wAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyNS0wNC0yMVQyMTowODoxNCswMDowMLK+XGsAAAAASUVORK5CYII=\"&gt;                                                                                                                                                                                                                                                                                                                                                 | 750000\\\n",
       "(100.0%) | 0\\\n",
       "(0.0%)       |\n",
       "| 8 |  8 | Guest_Popularity_percentage\\\n",
       "[numeric] | Mean (sd) : 52.2 (28.5)\\\n",
       "min &lt; med &lt; max:\\\n",
       "0 &lt; 53.6 &lt; 119.9\\\n",
       "IQR (CV) : 48.2 (0.5)                                                                                                                                       | 10019 distinct values                                                                                                                                                                                                    | &lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVCA8tUxeFAAABS0lEQVR42u2bwRGDIBBFIWN16SAp0HRgXenAHBgcRoMisot8/vPkRXmwu66M2tn0waP2AChK0TyG8MSK3GJcysBb5gZRwvozZF/lBE9jjDGTruWKbkK3G1GV0D1im8Xj7MO9VF7fQtRn8ZmpaFT0+lQ0LzoW6lFVRbeDPg7EUo8mVdF1+E3F1quqaIqEXivxV7RM0+bXr6xG7tgiK3q1xsmRO33sjFKp926iLLouKL55y0OuCp8UlV4/mQKWIXrnMrVPdjH6zu6oLSAu2hrdiCbmaEo1dGFcd2coUXRP5w4bXMVE29eJwxx16L0vVhaV61S06SZ0KYoGRdGgKBoURYOiaFAUDYqiQVE0KIoGRdGgKBoURYOiaFAUDYqiQVE0KIoGRdGgKBoURYOiaFAUDYqi0Y2oDT+x/sB8b+14Bb+VWTC3KN2ELkXR+AGM4D3GuUKOYwAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAyNS0wNC0yMVQyMTowODoxNSswMDowMGWU72MAAAAldEVYdGRhdGU6bW9kaWZ5ADIwMjUtMDQtMjFUMjE6MDg6MTUrMDA6MDAUyVffAAAAAElFTkSuQmCC\"&gt;                                                                                 | 603970\\\n",
       "(80.5%)  | 146030\\\n",
       "(19.5%) |\n",
       "| 9 |  9 | Number_of_Ads\\\n",
       "[numeric]               | Mean (sd) : 1.3 (1.2)\\\n",
       "min &lt; med &lt; max:\\\n",
       "0 &lt; 1 &lt; 103.9\\\n",
       "IQR (CV) : 2 (0.9)                                                                                                                                               | 12 distinct values                                                                                                                                                                                                       | &lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVCBCgWxpwAAAAs0lEQVR42u3cwQnCQBBAUSOpzhIsUDuwPb0IrjmJCgs/711CyGU+7OY4y/2wD8fZAwgV+p11fLkOF/a8zB7td+P/Z33/dHo+b7Nn/LvdHF2hNUJrhNYIrRFaI7RGaI3QGqE1QmuE1gitEVojtEZojdAaoTVCa4TWCK0RWiO0RmiN0BqhNUJrhNYIrRFaI7RGaI3QGqE1QmuE1git2WzWeG3UuBT2/wxrUJZCzyd2c3SF1jwANQAJB63xoakAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjFUMjE6MDg6MTYrMDA6MDBUfPX+AAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIxVDIxOjA4OjE2KzAwOjAwJSFNQgAAAABJRU5ErkJggg==\"&gt;                                                                                                                                                                                                                                                                                         | 749999\\\n",
       "(100.0%) | 1\\\n",
       "(0.0%)       |\n",
       "| 10 | 10 | Episode_Sentiment\\\n",
       "[character]         | 1\\. Negative\\\n",
       "2\\. Neutral\\\n",
       "3\\. Positive                                                                                                                                                                                 | \\250116 (33.3%)\\\n",
       "\\251291 (33.5%)\\\n",
       "\\248593 (33.1%)                                                                                                                                                                 | &lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAADIAAAA7CAQAAACTORHyAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVCBCgWxpwAAAAeElEQVRYw+3YsQ3AIAxEUTtiOjbIgskGrEdaQyoig4j1r6PxE1AcQqvMz7HACIQku7hrdhpb5NTFOwEBAQH5I5LaZZmCqK1f/TzmHTs36J1cjs0oNCMICAjIJgjNOJSuGR0nm7PvnkSO9WsS505AQEBAnKN82W6HPFCdD3vWiEuiAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDI1LTA0LTIxVDIxOjA4OjE2KzAwOjAwVHz1/gAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyNS0wNC0yMVQyMTowODoxNiswMDowMCUhTUIAAAAASUVORK5CYII=\"&gt;                                                                                                                                                                                                                                                                                                                                                                         | 750000\\\n",
       "(100.0%) | 0\\\n",
       "(0.0%)       |\n",
       "| 11 | 11 | Listening_Time_minutes\\\n",
       "[numeric]      | Mean (sd) : 45.4 (27.1)\\\n",
       "min &lt; med &lt; max:\\\n",
       "0 &lt; 43.4 &lt; 120\\\n",
       "IQR (CV) : 41.6 (0.6)                                                                                                                                         | 42807 distinct values                                                                                                                                                                                                    | &lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVCBJOVXtcAAABhUlEQVR42u2b0XGDMBBEhccFuC46cAokHbguOiAfCaAgMCAk393evj+PB8aPW4mTwM0QfHCT/gEUpWge9/hDk3GCbhrkXzmHVyWef+7ZZ5loQwghvKStdjgp+q5+3WIC11Xhg6KzRLuhNVe2TY4dv5FUP1zRZUBHne3Idqpu0QXG6Bb7lwJENGWssUSEd0TLxq+9fopaorridwWfndGIrvmyoqjsaPqoaF0k+mMRUYkpzs1kRFE0KIqGsGg/9EM/fKJBYUXRoCgabkRFet2U/m/efVRr8t1UlKJo/BujiFsoq6JWHhjl4Ca6FJXhdzVTYz2jTLQeFEWDomi4EVWyTEsp/XRcrWjpZtRNdCmqhVItoXrRUlAUDTeiau+jS642EGZEr74Q5Ca6FEWDomiYE83dEDUnmgtF0aAoGmZ63ZRzbb5h0XP7hIyuHY5FGED02EqV0bXH+wgDic7/VV5TZXQtMy3hospCiq61Em6i60a0iXckvsHe7nxGY7QBc9vETXQpisYP9XNcCznJq+YAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjFUMjE6MDg6MTgrMDA6MDAEQ46jAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIxVDIxOjA4OjE4KzAwOjAwdR42HwAAAABJRU5ErkJggg==\"&gt; | 750000\\\n",
       "(100.0%) | 0\\\n",
       "(0.0%)       |\n",
       "\n"
      ],
      "text/plain": [
       "   No Variable                                \n",
       "1   1 Podcast_Name\\\\\\n[character]             \n",
       "2   2 Episode_Title\\\\\\n[character]            \n",
       "3   3 Episode_Length_minutes\\\\\\n[numeric]     \n",
       "4   4 Genre\\\\\\n[character]                    \n",
       "5   5 Host_Popularity_percentage\\\\\\n[numeric] \n",
       "6   6 Publication_Day\\\\\\n[character]          \n",
       "7   7 Publication_Time\\\\\\n[character]         \n",
       "8   8 Guest_Popularity_percentage\\\\\\n[numeric]\n",
       "9   9 Number_of_Ads\\\\\\n[numeric]              \n",
       "10 10 Episode_Sentiment\\\\\\n[character]        \n",
       "11 11 Listening_Time_minutes\\\\\\n[numeric]     \n",
       "   Stats / Values                                                                                                                                                                                                                \n",
       "1  1\\\\. Tech Talks\\\\\\n2\\\\. Sports Weekly\\\\\\n3\\\\. Funny Folks\\\\\\n4\\\\. Tech Trends\\\\\\n5\\\\. Fitness First\\\\\\n6\\\\. Business Insights\\\\\\n7\\\\. Style Guide\\\\\\n8\\\\. Game Day\\\\\\n9\\\\. Melody Mix\\\\\\n10\\\\. Criminal Minds\\\\\\n[ 38 others ]\n",
       "2  1\\\\. Episode 71\\\\\\n2\\\\. Episode 62\\\\\\n3\\\\. Episode 31\\\\\\n4\\\\. Episode 61\\\\\\n5\\\\. Episode 69\\\\\\n6\\\\. Episode 23\\\\\\n7\\\\. Episode 63\\\\\\n8\\\\. Episode 81\\\\\\n9\\\\. Episode 64\\\\\\n10\\\\. Episode 72\\\\\\n[ 90 others ]                  \n",
       "3  Mean (sd) : 64.5 (33)\\\\\\nmin < med < max:\\\\\\n0 < 63.8 < 325.2\\\\\\nIQR (CV) : 58.3 (0.5)                                                                                                                                        \n",
       "4  1\\\\. Business\\\\\\n2\\\\. Comedy\\\\\\n3\\\\. Education\\\\\\n4\\\\. Health\\\\\\n5\\\\. Lifestyle\\\\\\n6\\\\. Music\\\\\\n7\\\\. News\\\\\\n8\\\\. Sports\\\\\\n9\\\\. Technology\\\\\\n10\\\\. True Crime                                                              \n",
       "5  Mean (sd) : 59.9 (22.9)\\\\\\nmin < med < max:\\\\\\n1.3 < 60 < 119.5\\\\\\nIQR (CV) : 40.1 (0.4)                                                                                                                                      \n",
       "6  1\\\\. Friday\\\\\\n2\\\\. Monday\\\\\\n3\\\\. Saturday\\\\\\n4\\\\. Sunday\\\\\\n5\\\\. Thursday\\\\\\n6\\\\. Tuesday\\\\\\n7\\\\. Wednesday                                                                                                                 \n",
       "7  1\\\\. Afternoon\\\\\\n2\\\\. Evening\\\\\\n3\\\\. Morning\\\\\\n4\\\\. Night                                                                                                                                                                  \n",
       "8  Mean (sd) : 52.2 (28.5)\\\\\\nmin < med < max:\\\\\\n0 < 53.6 < 119.9\\\\\\nIQR (CV) : 48.2 (0.5)                                                                                                                                      \n",
       "9  Mean (sd) : 1.3 (1.2)\\\\\\nmin < med < max:\\\\\\n0 < 1 < 103.9\\\\\\nIQR (CV) : 2 (0.9)                                                                                                                                              \n",
       "10 1\\\\. Negative\\\\\\n2\\\\. Neutral\\\\\\n3\\\\. Positive                                                                                                                                                                                \n",
       "11 Mean (sd) : 45.4 (27.1)\\\\\\nmin < med < max:\\\\\\n0 < 43.4 < 120\\\\\\nIQR (CV) : 41.6 (0.6)                                                                                                                                        \n",
       "   Freqs (% of Valid)                                                                                                                                                                                                      \n",
       "1  \\\\ 22847 ( 3.0%)\\\\\\n\\\\ 20053 ( 2.7%)\\\\\\n\\\\ 19635 ( 2.6%)\\\\\\n\\\\ 19549 ( 2.6%)\\\\\\n\\\\ 19488 ( 2.6%)\\\\\\n\\\\ 19480 ( 2.6%)\\\\\\n\\\\ 19364 ( 2.6%)\\\\\\n\\\\ 19272 ( 2.6%)\\\\\\n\\\\ 18889 ( 2.5%)\\\\\\n\\\\ 17735 ( 2.4%)\\\\\\n\\\\553688 (73.8%)\n",
       "2  \\\\ 10515 ( 1.4%)\\\\\\n\\\\ 10373 ( 1.4%)\\\\\\n\\\\ 10292 ( 1.4%)\\\\\\n\\\\  9991 ( 1.3%)\\\\\\n\\\\  9864 ( 1.3%)\\\\\\n\\\\  9762 ( 1.3%)\\\\\\n\\\\  9743 ( 1.3%)\\\\\\n\\\\  9741 ( 1.3%)\\\\\\n\\\\  9686 ( 1.3%)\\\\\\n\\\\  9554 ( 1.3%)\\\\\\n\\\\650479 (86.7%)\n",
       "3  12268 distinct values                                                                                                                                                                                                   \n",
       "4  \\\\80521 (10.7%)\\\\\\n\\\\81453 (10.9%)\\\\\\n\\\\49100 ( 6.5%)\\\\\\n\\\\71416 ( 9.5%)\\\\\\n\\\\82461 (11.0%)\\\\\\n\\\\62743 ( 8.4%)\\\\\\n\\\\63385 ( 8.5%)\\\\\\n\\\\87606 (11.7%)\\\\\\n\\\\86256 (11.5%)\\\\\\n\\\\85059 (11.3%)                              \n",
       "5  8038 distinct values                                                                                                                                                                                                    \n",
       "6  \\\\108237 (14.4%)\\\\\\n\\\\111963 (14.9%)\\\\\\n\\\\103505 (13.8%)\\\\\\n\\\\115946 (15.5%)\\\\\\n\\\\104360 (13.9%)\\\\\\n\\\\ 98103 (13.1%)\\\\\\n\\\\107886 (14.4%)                                                                                \n",
       "7  \\\\179460 (23.9%)\\\\\\n\\\\195778 (26.1%)\\\\\\n\\\\177913 (23.7%)\\\\\\n\\\\196849 (26.2%)                                                                                                                                            \n",
       "8  10019 distinct values                                                                                                                                                                                                   \n",
       "9  12 distinct values                                                                                                                                                                                                      \n",
       "10 \\\\250116 (33.3%)\\\\\\n\\\\251291 (33.5%)\\\\\\n\\\\248593 (33.1%)                                                                                                                                                                \n",
       "11 42807 distinct values                                                                                                                                                                                                   \n",
       "   Graph                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    \n",
       "1  <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAF8AAADKCAQAAABp7lSOAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVCAsqPtOcAAABc0lEQVR42u3bQYrCQBRF0aRxdS6hFxh30OtyB3Fg01QkCPYgv17lXEfODlKBPCjndUruqxqAn9ul/XL7fRC+52rWu9qn9eXXv07Xat1HhR8efHz8yPDx8SPDr+yy/fpT7fmwuX177vo1/6837/tpbQ7PErG22qwtfPzI8PHxI8PHPyvfXKksnG9tdcRPCx8fPzJ8fPzI8Cuztiobib+s9/W+LkEXa0f69fPCx8ePDB8fP7Jwvqt4R2dt9ZK1hY8fGT4+fmT4+GflW1tHN9Da2rmKl3MRb5qmtflkrK1WHH548PHxI8PHx48Mv7KdtZX0wmxtVeaPTx3x08LHx48MHx8/MvzKzJXKwvnWVkf8tPDx8SPDx8ePDL8ya6uykfjPq3jVpH/z88LHx48MHx8/MvzK/PHp6KytXrK28PEjw8fHjwwf/6x8a+voBlpbu1fxOq85JC9nv/+LeNunM/zw4OPjR4aPjx8ZfmUjra28wg8PfmUPPABb6rm7Ea0AAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjFUMjE6MDg6MTErMDA6MDCR28twAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIxVDIxOjA4OjExKzAwOjAw4IZzzAAAAABJRU5ErkJggg==\">                        \n",
       "2  <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAG0AAADKCAQAAAAF6AaLAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVCAsqPtOcAAABX0lEQVR42u3YwWnDQBRFUSm4unSQFOh0kPac7STglQPi/LlnZeHNXCSEn8/HMdXb1QcorbTVbb34ehzH53n1kV6xvjkG37XSRKWJShOVJipNVJqoNNG5Lhx6qh3Hsedeuz/ug/7g2uWuzVKaqDRRaaLSRKWJShM1RUW7pLWyEaWJShOVJipNVJqoNNHgtFa2aJe0VjaiNFFpotJEpYlKE5UmGpzWyhbtktbKRpQmKk1Umqg0UWmi0kSD01rZoqaoqDRRaaLSRKWJShOVJipN1MoWtbJFpYlKE5UmKk1Umqg00eC0pqhol7RWNqI0UWmi0kSliUoTlSYanNbKFu2S1spGlCYqTVSaqDRRaaLSRIPTWtmiXdJa2YjSRKWJShOVJipNVJpocForW3RbLwYM0eXBu/3+5v3qo/2jwQ9kaaLSRKWJShOVJipN9OeX//fV53nRx/L59CfaM4MfyNJEP0K2Ox7416vXAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDI1LTA0LTIxVDIxOjA4OjExKzAwOjAwkdvLcAAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyNS0wNC0yMVQyMTowODoxMSswMDowMOCGc8wAAAAASUVORK5CYII=\">                                                    \n",
       "3  <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVCAy0WkY/AAAA5klEQVR42u3cwQ2CMBhAYWuYzg10wLqBc7kB3kiJEpFiWt7/Hhe4NHwBSgKENJ5idG69A0KFbmsoN1LFQHl2sd9qhtqtcpeGzaO8dZnWHq2FH1qE9niE/gLt/Qj9WpjJSCitKmgen9PSGvKtlbeX3D1kJ2g5Ax9zNvYapSWUllBaQmkJpSWUllBaQmkJpSWUllBaQmmFgc6e1B//xcNKKO3lb1mYU1coLaG0hNISSksoLaG0hNISSksoLaG0hNISSksoLaG0hNISSksoLaG0wkBT+WnRHfad0bX4TUaC2RYLc+oKpfUCK5UeTY+BarAAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjFUMjE6MDg6MTIrMDA6MDCgM9HtAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIxVDIxOjA4OjEyKzAwOjAw0W5pUQAAAABJRU5ErkJggg==\">                                                                                                                                                                                                                    \n",
       "4  <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAABoAAAC3CAQAAACmwYZ1AAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVCAy0WkY/AAAAy0lEQVRo3u2awQ2DMBAEfRHVpQQXSDqgLjpwHvmwxo4OiMiBZnhZ8kg+jgVbwkrazmOHc6I0LAev8mxOmlK2Ze3Ba0JCUgYdTi5JHnn7MvFwNGR5Y/ctk60rpdRLrhK8T0hIypWTm80haXL79QXvExKScuXkfljn1/XNrQneJyQk5bwQsltGQvqdFDy5Io1lrq52loPfciQkJfjGl+QiITUJnlznxleX4Tyyaq3B+4SEpNwjuTuOrDXB+4SEpJDcI8tDQvqXZDf8HeoNSZBWhwHfHEYAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjFUMjE6MDg6MTIrMDA6MDCgM9HtAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIxVDIxOjA4OjEyKzAwOjAw0W5pUQAAAABJRU5ErkJggg==\">                                                                                                                                                                                                                                                        \n",
       "5  <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVCA5aVCcTAAABK0lEQVR42u3b0Q2CMABFUWqYjg10QNyAudgAPxCoSiNtKdDXe3+MJhAPlBajmqEqo9vZbwAo0LBq+4nx2LCdL+6Hz2aHZs8/dehOmvdjd7ZmY8UMXaBqAVWrGGjw8rI0rajjgtNFravpVucdoBNwO2Lpm5Nudd4B6ntIlrqqH8bH3/M3HZa9zmxCaNww3DpOLgC91k3ioUPXXev8/O8e3FlCm/hd/Il19KqFTnHZQD9vS/ynuGygsVdxAmg/rL9y7jJTzGQEVC3Pa7TN9hsM78ko/T1MmooZukDVAqoWULWAqgVULaBqAVULqFpA1QKqFlC1gKoFVC2gagFVC6haQNUCqhZQtYCqBVQtoGoBVQuoWsVAjf0j+We2v5hf7279qcuI2ZwVM3SBqvUCy9ktIuH0SSgAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjFUMjE6MDg6MTQrMDA6MDDD4+TXAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIxVDIxOjA4OjE0KzAwOjAwsr5cawAAAABJRU5ErkJggg==\">                                                                                                                        \n",
       "6  <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAB4AAACCCAQAAAD7nbARAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVCA5aVCcTAAAArElEQVRYw+3Z2w2AIAwF0NYwnSN0QN2A9fDX+iiiNqZy+SPhJNCGG6Jc6P4YHtgPcVpP5jKaizMJr2sU9MzAwL446WluwuqK8QXw2pVU256qaSh8ionGmlYjaJ+BgX1xD0kibGA7Sfb1CNpnYGBf3EOSbLfX+CbRNQnaZ2BgX9xDkuBNAgzsjf+fJMImtpLkqBpB+wwM7Iv/nyREj764bisStM/AwL6YO/wLvACUmyhPC06I2AAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAyNS0wNC0yMVQyMTowODoxNCswMDowMMPj5NcAAAAldEVYdGRhdGU6bW9kaWZ5ADIwMjUtMDQtMjFUMjE6MDg6MTQrMDA6MDCyvlxrAAAAAElFTkSuQmCC\">                                                                                                                                                                                                                                                                                                    \n",
       "7  <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAACoAAABOCAQAAAD8r0ycAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVCA5aVCcTAAAAiklEQVRYw+3WSw6AIAxF0dawOpfAAnUHbk+HFHXEJ2nD7cxETvKEPNRbxs82wQyEJvtwNn3grCIidmmqX9j9xgcFBV0TfbXUNQRV24PaAVlnfvyj52o1MQc1f70XcY4UKCioe5TmL9PW/PkTsLv5/3YhzpECBQV1j9L8ZfjnBwUFXQOd3/yu48dBH/iKFxn/tftSAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDI1LTA0LTIxVDIxOjA4OjE0KzAwOjAww+Pk1wAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyNS0wNC0yMVQyMTowODoxNCswMDowMLK+XGsAAAAASUVORK5CYII=\">                                                                                                                                                                                                                                                                                                                                                \n",
       "8  <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVCA8tUxeFAAABS0lEQVR42u2bwRGDIBBFIWN16SAp0HRgXenAHBgcRoMisot8/vPkRXmwu66M2tn0waP2AChK0TyG8MSK3GJcysBb5gZRwvozZF/lBE9jjDGTruWKbkK3G1GV0D1im8Xj7MO9VF7fQtRn8ZmpaFT0+lQ0LzoW6lFVRbeDPg7EUo8mVdF1+E3F1quqaIqEXivxV7RM0+bXr6xG7tgiK3q1xsmRO33sjFKp926iLLouKL55y0OuCp8UlV4/mQKWIXrnMrVPdjH6zu6oLSAu2hrdiCbmaEo1dGFcd2coUXRP5w4bXMVE29eJwxx16L0vVhaV61S06SZ0KYoGRdGgKBoURYOiaFAUDYqiQVE0KIoGRdGgKBoURYOiaFAUDYqiQVE0KIoGRdGgKBoURYOiaFAUDYqi0Y2oDT+x/sB8b+14Bb+VWTC3KN2ELkXR+AGM4D3GuUKOYwAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAyNS0wNC0yMVQyMTowODoxNSswMDowMGWU72MAAAAldEVYdGRhdGU6bW9kaWZ5ADIwMjUtMDQtMjFUMjE6MDg6MTUrMDA6MDAUyVffAAAAAElFTkSuQmCC\">                                                                                \n",
       "9  <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVCBCgWxpwAAAAs0lEQVR42u3cwQnCQBBAUSOpzhIsUDuwPb0IrjmJCgs/711CyGU+7OY4y/2wD8fZAwgV+p11fLkOF/a8zB7td+P/Z33/dHo+b7Nn/LvdHF2hNUJrhNYIrRFaI7RGaI3QGqE1QmuE1gitEVojtEZojdAaoTVCa4TWCK0RWiO0RmiN0BqhNUJrhNYIrRFaI7RGaI3QGqE1QmuE1git2WzWeG3UuBT2/wxrUJZCzyd2c3SF1jwANQAJB63xoakAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjFUMjE6MDg6MTYrMDA6MDBUfPX+AAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIxVDIxOjA4OjE2KzAwOjAwJSFNQgAAAABJRU5ErkJggg==\">                                                                                                                                                                                                                                                                                        \n",
       "10 <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAADIAAAA7CAQAAACTORHyAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVCBCgWxpwAAAAeElEQVRYw+3YsQ3AIAxEUTtiOjbIgskGrEdaQyoig4j1r6PxE1AcQqvMz7HACIQku7hrdhpb5NTFOwEBAQH5I5LaZZmCqK1f/TzmHTs36J1cjs0oNCMICAjIJgjNOJSuGR0nm7PvnkSO9WsS505AQEBAnKN82W6HPFCdD3vWiEuiAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDI1LTA0LTIxVDIxOjA4OjE2KzAwOjAwVHz1/gAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyNS0wNC0yMVQyMTowODoxNiswMDowMCUhTUIAAAAASUVORK5CYII=\">                                                                                                                                                                                                                                                                                                                                                                        \n",
       "11 <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVCBJOVXtcAAABhUlEQVR42u2b0XGDMBBEhccFuC46cAokHbguOiAfCaAgMCAk393evj+PB8aPW4mTwM0QfHCT/gEUpWge9/hDk3GCbhrkXzmHVyWef+7ZZ5loQwghvKStdjgp+q5+3WIC11Xhg6KzRLuhNVe2TY4dv5FUP1zRZUBHne3Idqpu0QXG6Bb7lwJENGWssUSEd0TLxq+9fopaorridwWfndGIrvmyoqjsaPqoaF0k+mMRUYkpzs1kRFE0KIqGsGg/9EM/fKJBYUXRoCgabkRFet2U/m/efVRr8t1UlKJo/BujiFsoq6JWHhjl4Ca6FJXhdzVTYz2jTLQeFEWDomi4EVWyTEsp/XRcrWjpZtRNdCmqhVItoXrRUlAUDTeiau+jS642EGZEr74Q5Ca6FEWDomiYE83dEDUnmgtF0aAoGmZ63ZRzbb5h0XP7hIyuHY5FGED02EqV0bXH+wgDic7/VV5TZXQtMy3hospCiq61Em6i60a0iXckvsHe7nxGY7QBc9vETXQpisYP9XNcCznJq+YAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjFUMjE6MDg6MTgrMDA6MDAEQ46jAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIxVDIxOjA4OjE4KzAwOjAwdR42HwAAAABJRU5ErkJggg==\">\n",
       "   Valid              Missing          \n",
       "1  750000\\\\\\n(100.0%) 0\\\\\\n(0.0%)      \n",
       "2  750000\\\\\\n(100.0%) 0\\\\\\n(0.0%)      \n",
       "3  662907\\\\\\n(88.4%)  87093\\\\\\n(11.6%) \n",
       "4  750000\\\\\\n(100.0%) 0\\\\\\n(0.0%)      \n",
       "5  750000\\\\\\n(100.0%) 0\\\\\\n(0.0%)      \n",
       "6  750000\\\\\\n(100.0%) 0\\\\\\n(0.0%)      \n",
       "7  750000\\\\\\n(100.0%) 0\\\\\\n(0.0%)      \n",
       "8  603970\\\\\\n(80.5%)  146030\\\\\\n(19.5%)\n",
       "9  749999\\\\\\n(100.0%) 1\\\\\\n(0.0%)      \n",
       "10 750000\\\\\\n(100.0%) 0\\\\\\n(0.0%)      \n",
       "11 750000\\\\\\n(100.0%) 0\\\\\\n(0.0%)      "
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    }
   ],
   "source": [
    "\n",
    "train_tbl <- read_csv(\"/kaggle/input/playground-series-s5e4/train.csv\")\n",
    "\n",
    "train_tbl %>%\n",
    "    select(-id) %>%\n",
    "    dfSummary(\n",
    "        plain.ascii  = FALSE,\n",
    "          style        = \"grid\",\n",
    "          graph.magnif = 0.75,\n",
    "          method       = \"render\"\n",
    "    )%>%\n",
    "    select(-text.graph) #%>%\n",
    "   # knitr::kable(align = \"c\")"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "0a273dcd",
   "metadata": {
    "papermill": {
     "duration": 0.006223,
     "end_time": "2025-04-21T21:08:18.521900",
     "exception": false,
     "start_time": "2025-04-21T21:08:18.515677",
     "status": "completed"
    },
    "tags": []
   },
   "source": [
    "## Comprehensive EDA report. This report can be found in Output file area.\n"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "id": "c67a375b",
   "metadata": {
    "papermill": {
     "duration": 0.006109,
     "end_time": "2025-04-21T21:08:18.534171",
     "exception": false,
     "start_time": "2025-04-21T21:08:18.528062",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [],
   "source": []
  },
  {
   "cell_type": "code",
   "execution_count": 4,
   "id": "73079f8b",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-04-21T21:08:18.550834Z",
     "iopub.status.busy": "2025-04-21T21:08:18.549016Z",
     "iopub.status.idle": "2025-04-21T21:09:38.187463Z",
     "shell.execute_reply": "2025-04-21T21:09:38.185219Z"
    },
    "papermill": {
     "duration": 79.65028,
     "end_time": "2025-04-21T21:09:38.190551",
     "exception": false,
     "start_time": "2025-04-21T21:08:18.540271",
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
      "\n",
      "processing file: report.rmd\n",
      "\n"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "1/42                                 \n",
      "2/42 [global_options]                \n",
      "3/42                                 \n",
      "4/42 [introduce]                     \n",
      "5/42                                 \n",
      "6/42 [plot_intro]                    \n"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "7/42                                 \n",
      "8/42 [data_structure]                \n",
      "9/42                                 \n",
      "10/42 [missing_profile]               \n"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "11/42                                 \n",
      "12/42 [univariate_distribution_header]\n",
      "13/42                                 \n",
      "14/42 [plot_histogram]                \n"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "15/42                                 \n",
      "16/42 [plot_density]                  \n",
      "17/42                                 \n",
      "18/42 [plot_frequency_bar]            \n"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "19/42                                 \n",
      "20/42 [plot_response_bar]             \n",
      "21/42                                 \n",
      "22/42 [plot_with_bar]                 \n",
      "23/42                                 \n",
      "24/42 [plot_normal_qq]                \n"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "25/42                                 \n",
      "26/42 [plot_response_qq]              \n"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "27/42                                 \n",
      "28/42 [plot_by_qq]                    \n",
      "29/42                                 \n",
      "30/42 [correlation_analysis]          \n"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "31/42                                 \n",
      "32/42 [principal_component_analysis]  \n"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "33/42                                 \n",
      "34/42 [bivariate_distribution_header] \n",
      "35/42                                 \n",
      "36/42 [plot_response_boxplot]         \n"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "37/42                                 \n",
      "38/42 [plot_by_boxplot]               \n",
      "39/42                                 \n",
      "40/42 [plot_response_scatterplot]     \n"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "41/42                                 \n",
      "42/42 [plot_by_scatterplot]           \n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "output file: /kaggle/working/report.knit.md\n",
      "\n",
      "\n"
     ]
    },
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "/usr/bin/pandoc +RTS -K512m -RTS /kaggle/working/report.knit.md --to html4 --from markdown+autolink_bare_uris+tex_math_single_backslash --output pandocd56875edc.html --lua-filter /usr/local/lib/R/site-library/rmarkdown/rmarkdown/lua/pagebreak.lua --lua-filter /usr/local/lib/R/site-library/rmarkdown/rmarkdown/lua/latex-div.lua --embed-resources --standalone --variable bs3=TRUE --section-divs --table-of-contents --toc-depth 6 --template /usr/local/lib/R/site-library/rmarkdown/rmd/h/default.html --no-highlight --variable highlightjs=1 --variable theme=yeti --mathjax --variable 'mathjax-url=https://mathjax.rstudio.com/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML' --include-in-header /tmp/RtmpX6rZq8/rmarkdown-strd260916dc.html \n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\n",
      "Output created: Predict Podcast Listening Time.html\n",
      "\n"
     ]
    }
   ],
   "source": [
    "train_tbl%>% \n",
    "    select(-id) %>% \n",
    "    mutate(across(where(is_character),as.factor))%>% \n",
    "    mutate(Number_of_Ads=as.factor(Number_of_Ads)) %>% \n",
    "    create_report(\n",
    "        output_file = \"Predict Podcast Listening Time.html\",\n",
    "        report_title = \"Predict Podcast Listening Time\",\n",
    "        output_dir = getwd(),\n",
    "        y = \"Listening_Time_minutes\"      \n",
    "    )\n",
    "\n"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "0a4c674e",
   "metadata": {
    "papermill": {
     "duration": 0.007944,
     "end_time": "2025-04-21T21:09:38.210129",
     "exception": false,
     "start_time": "2025-04-21T21:09:38.202185",
     "status": "completed"
    },
    "tags": []
   },
   "source": [
    "## Conclusions from EDA\n",
    "\n",
    "- Episode_Length_minutes is lineally,positively correlated to Listening_Time_minutes\n",
    "- 10 exceptional digital values and 1 NA in column Number_of_Ads. To make it simple, change all exceptional values to 1\n"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 5,
   "id": "8ce345e3",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-04-21T21:09:38.228590Z",
     "iopub.status.busy": "2025-04-21T21:09:38.226807Z",
     "iopub.status.idle": "2025-04-21T21:09:38.275567Z",
     "shell.execute_reply": "2025-04-21T21:09:38.273105Z"
    },
    "papermill": {
     "duration": 0.061352,
     "end_time": "2025-04-21T21:09:38.278655",
     "exception": false,
     "start_time": "2025-04-21T21:09:38.217303",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [],
   "source": [
    "train_tbl <- train_tbl %>%  \n",
    "    mutate(Number_of_Ads = ifelse(!(Number_of_Ads %in% c(0, 1, 2, 3)), 1, Number_of_Ads))\n",
    "\n"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 6,
   "id": "dbc93179",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-04-21T21:09:38.297266Z",
     "iopub.status.busy": "2025-04-21T21:09:38.295599Z",
     "iopub.status.idle": "2025-04-21T21:11:19.197325Z",
     "shell.execute_reply": "2025-04-21T21:11:19.194952Z"
    },
    "papermill": {
     "duration": 100.914568,
     "end_time": "2025-04-21T21:11:19.200598",
     "exception": false,
     "start_time": "2025-04-21T21:09:38.286030",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "Rows: 750,000\n",
      "Columns: 180\n",
      "$ Episode_Length_minutes           \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m 9.169398e-16, 1.783933e+00, 3.031095e…\n",
      "$ Host_Popularity_percentage       \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m 0.653610611, 0.309975474, 0.442008313…\n",
      "$ Guest_Popularity_percentage      \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m 2.504693e-15, 9.287918e-01, -1.694623…\n",
      "$ Listening_Time_minutes           \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m 31.41998, 88.01241, 44.92531, 46.2782…\n",
      "$ Podcast_Name_Athlete.s.Arena     \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1537823, -0.1537823, -0.1537823, -…\n",
      "$ Podcast_Name_Brain.Boost         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1250249, -0.1250249, -0.1250249, -…\n",
      "$ Podcast_Name_Business.Briefs     \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1523453, -0.1523453, -0.1523453, -…\n",
      "$ Podcast_Name_Business.Insights   \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.163297, -0.163297, -0.163297, -0.1…\n",
      "$ Podcast_Name_Comedy.Corner       \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1472981, -0.1472981, -0.1472981, -…\n",
      "$ Podcast_Name_Crime.Chronicles    \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1539957, -0.1539957, -0.1539957, -…\n",
      "$ Podcast_Name_Criminal.Minds      \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1556256, -0.1556256, -0.1556256, -…\n",
      "$ Podcast_Name_Current.Affairs     \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1335277, -0.1335277, -0.1335277, -…\n",
      "$ Podcast_Name_Daily.Digest        \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1348304, -0.1348304, -0.1348304, -…\n",
      "$ Podcast_Name_Detective.Diaries   \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1543492, -0.1543492, -0.1543492, -…\n",
      "$ Podcast_Name_Digital.Digest      \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1484468, -0.1484468, -0.1484468, 6…\n",
      "$ Podcast_Name_Educational.Nuggets \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1288318, -0.1288318, -0.1288318, -…\n",
      "$ Podcast_Name_Fashion.Forward     \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1535686, -0.1535686, -0.1535686, -…\n",
      "$ Podcast_Name_Finance.Focus       \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1551441, -0.1551441, -0.1551441, -…\n",
      "$ Podcast_Name_Fitness.First       \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1633314, -0.1633314, -0.1633314, -…\n",
      "$ Podcast_Name_Funny.Folks         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1639627, -0.1639627, -0.1639627, -…\n",
      "$ Podcast_Name_Gadget.Geek         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1417354, -0.1417354, -0.1417354, -…\n",
      "$ Podcast_Name_Game.Day            \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1623997, -0.1623997, -0.1623997, -…\n",
      "$ Podcast_Name_Global.News         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1361469, -0.1361469, -0.1361469, -…\n",
      "$ Podcast_Name_Health.Hour         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.122644, -0.122644, -0.122644, -0.1…\n",
      "$ Podcast_Name_Healthy.Living      \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1285802, -0.1285802, -0.1285802, -…\n",
      "$ Podcast_Name_Home...Living       \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1413237, -0.1413237, -0.1413237, -…\n",
      "$ Podcast_Name_Humor.Hub           \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.14832, -0.14832, -0.14832, -0.1483…\n",
      "$ Podcast_Name_Innovators          \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1323591, -0.1323591, -0.1323591, -…\n",
      "$ Podcast_Name_Joke.Junction       \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1432162, 6.9824408, -0.1432162, -0…\n",
      "$ Podcast_Name_Laugh.Line          \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1412599, -0.1412599, -0.1412599, -…\n",
      "$ Podcast_Name_Learning.Lab        \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1290776, -0.1290776, -0.1290776, -…\n",
      "$ Podcast_Name_Life.Lessons        \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1402303, -0.1402303, -0.1402303, -…\n",
      "$ Podcast_Name_Lifestyle.Lounge    \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1507294, -0.1507294, -0.1507294, -…\n",
      "$ Podcast_Name_Market.Masters      \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1332895, -0.1332895, -0.1332895, -…\n",
      "$ Podcast_Name_Melody.Mix          \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1607358, -0.1607358, -0.1607358, -…\n",
      "$ Podcast_Name_Mind...Body         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1360961, -0.1360961, -0.1360961, -…\n",
      "$ Podcast_Name_Money.Matters       \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.134774, -0.134774, -0.134774, -0.1…\n",
      "$ Podcast_Name_Music.Matters       \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1309915, -0.1309915, -0.1309915, -…\n",
      "$ Podcast_Name_Mystery.Matters     \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m 6.772672, -0.147652, -0.147652, -0.14…\n",
      "$ Podcast_Name_News.Roundup        \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1112503, -0.1112503, -0.1112503, -…\n",
      "$ Podcast_Name_Sound.Waves         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1375574, -0.1375574, -0.1375574, -…\n",
      "$ Podcast_Name_Sport.Spot          \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1417746, -0.1417746, -0.1417746, -…\n",
      "$ Podcast_Name_Sports.Central      \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1485406, -0.1485406, -0.1485406, -…\n",
      "$ Podcast_Name_Sports.Weekly       \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1657463, -0.1657463, -0.1657463, -…\n",
      "$ Podcast_Name_Study.Sessions      \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1330873, -0.1330873, 7.5138526, -0…\n",
      "$ Podcast_Name_Style.Guide         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1627971, -0.1627971, -0.1627971, -…\n",
      "$ Podcast_Name_Tech.Talks          \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1772562, -0.1772562, -0.1772562, -…\n",
      "$ Podcast_Name_Tech.Trends         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1635936, -0.1635936, -0.1635936, -…\n",
      "$ Podcast_Name_True.Crime.Stories  \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1493916, -0.1493916, -0.1493916, -…\n",
      "$ Podcast_Name_Tune.Time           \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1534503, -0.1534503, -0.1534503, -…\n",
      "$ Podcast_Name_Wellness.Wave       \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1429008, -0.1429008, -0.1429008, -…\n",
      "$ Podcast_Name_World.Watch         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1381349, -0.1381349, -0.1381349, -…\n",
      "$ Episode_Title_Episode.1          \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.08921229, -0.08921229, -0.08921229…\n",
      "$ Episode_Title_Episode.10         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.09316661, -0.09316661, -0.09316661…\n",
      "$ Episode_Title_Episode.100        \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.09239177, -0.09239177, -0.09239177…\n",
      "$ Episode_Title_Episode.11         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.09521256, -0.09521256, -0.09521256…\n",
      "$ Episode_Title_Episode.12         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1027602, -0.1027602, -0.1027602, -…\n",
      "$ Episode_Title_Episode.13         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.09853605, -0.09853605, -0.09853605…\n",
      "$ Episode_Title_Episode.14         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.0938124, -0.0938124, -0.0938124, -…\n",
      "$ Episode_Title_Episode.15         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.09831508, -0.09831508, -0.09831508…\n",
      "$ Episode_Title_Episode.16         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.089991, -0.089991, 11.112208, -0.0…\n",
      "$ Episode_Title_Episode.17         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.08332181, -0.08332181, -0.08332181…\n",
      "$ Episode_Title_Episode.18         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.09968157, -0.09968157, -0.09968157…\n",
      "$ Episode_Title_Episode.19         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1010236, -0.1010236, -0.1010236, -…\n",
      "$ Episode_Title_Episode.2          \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.08302112, -0.08302112, -0.08302112…\n",
      "$ Episode_Title_Episode.20         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1007538, -0.1007538, -0.1007538, -…\n",
      "$ Episode_Title_Episode.21         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.09504845, -0.09504845, -0.09504845…\n",
      "$ Episode_Title_Episode.22         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.09095717, -0.09095717, -0.09095717…\n",
      "$ Episode_Title_Episode.23         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1148374, -0.1148374, -0.1148374, -…\n",
      "$ Episode_Title_Episode.24         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1050546, -0.1050546, -0.1050546, -…\n",
      "$ Episode_Title_Episode.25         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.0828826, -0.0828826, -0.0828826, -…\n",
      "$ Episode_Title_Episode.26         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1019956, 9.8043342, -0.1019956, -0…\n",
      "$ Episode_Title_Episode.27         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1028397, -0.1028397, -0.1028397, -…\n",
      "$ Episode_Title_Episode.28         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1009157, -0.1009157, -0.1009157, -…\n",
      "$ Episode_Title_Episode.29         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1044235, -0.1044235, -0.1044235, -…\n",
      "$ Episode_Title_Episode.3          \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.09666344, -0.09666344, -0.09666344…\n",
      "$ Episode_Title_Episode.30         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1023885, -0.1023885, -0.1023885, -…\n",
      "$ Episode_Title_Episode.31         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1179558, -0.1179558, -0.1179558, -…\n",
      "$ Episode_Title_Episode.32         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1043387, -0.1043387, -0.1043387, -…\n",
      "$ Episode_Title_Episode.33         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1134288, -0.1134288, -0.1134288, -…\n",
      "$ Episode_Title_Episode.34         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1095988, -0.1095988, -0.1095988, -…\n",
      "$ Episode_Title_Episode.35         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.103256, -0.103256, -0.103256, -0.1…\n",
      "$ Episode_Title_Episode.36         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.09806592, -0.09806592, -0.09806592…\n",
      "$ Episode_Title_Episode.37         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.08142684, -0.08142684, -0.08142684…\n",
      "$ Episode_Title_Episode.38         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.09642426, -0.09642426, -0.09642426…\n",
      "$ Episode_Title_Episode.39         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.09068107, -0.09068107, -0.09068107…\n",
      "$ Episode_Title_Episode.4          \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.09706314, -0.09706314, -0.09706314…\n",
      "$ Episode_Title_Episode.40         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.09705614, -0.09705614, -0.09705614…\n",
      "$ Episode_Title_Episode.41         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.08163399, -0.08163399, -0.08163399…\n",
      "$ Episode_Title_Episode.42         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1010505, -0.1010505, -0.1010505, -…\n",
      "$ Episode_Title_Episode.43         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1064853, -0.1064853, -0.1064853, -…\n",
      "$ Episode_Title_Episode.44         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.08531859, -0.08531859, -0.08531859…\n",
      "$ Episode_Title_Episode.45         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.09595833, -0.09595833, -0.09595833…\n",
      "$ Episode_Title_Episode.46         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1035984, -0.1035984, -0.1035984, -…\n",
      "$ Episode_Title_Episode.47         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1013866, -0.1013866, -0.1013866, -…\n",
      "$ Episode_Title_Episode.48         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1046647, -0.1046647, -0.1046647, -…\n",
      "$ Episode_Title_Episode.49         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1058109, -0.1058109, -0.1058109, -…\n",
      "$ Episode_Title_Episode.5          \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.09252379, -0.09252379, -0.09252379…\n",
      "$ Episode_Title_Episode.50         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.09495557, -0.09495557, -0.09495557…\n",
      "$ Episode_Title_Episode.51         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1101147, -0.1101147, -0.1101147, -…\n",
      "$ Episode_Title_Episode.52         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1049832, -0.1049832, -0.1049832, -…\n",
      "$ Episode_Title_Episode.53         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.09266294, -0.09266294, -0.09266294…\n",
      "$ Episode_Title_Episode.54         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1060554, -0.1060554, -0.1060554, -…\n",
      "$ Episode_Title_Episode.55         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.09489837, -0.09489837, -0.09489837…\n",
      "$ Episode_Title_Episode.56         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.09925777, -0.09925777, -0.09925777…\n",
      "$ Episode_Title_Episode.57         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.09095717, -0.09095717, -0.09095717…\n",
      "$ Episode_Title_Episode.58         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1041361, -0.1041361, -0.1041361, -…\n",
      "$ Episode_Title_Episode.59         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.09940151, -0.09940151, -0.09940151…\n",
      "$ Episode_Title_Episode.6          \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.09701414, -0.09701414, -0.09701414…\n",
      "$ Episode_Title_Episode.60         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.09256043, -0.09256043, -0.09256043…\n",
      "$ Episode_Title_Episode.61         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1161945, -0.1161945, -0.1161945, -…\n",
      "$ Episode_Title_Episode.62         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1184256, -0.1184256, -0.1184256, -…\n",
      "$ Episode_Title_Episode.63         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1147241, -0.1147241, -0.1147241, -…\n",
      "$ Episode_Title_Episode.64         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1143837, -0.1143837, -0.1143837, -…\n",
      "$ Episode_Title_Episode.65         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1100713, -0.1100713, -0.1100713, -…\n",
      "$ Episode_Title_Episode.66         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.09952455, -0.09952455, -0.09952455…\n",
      "$ Episode_Title_Episode.67         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1063059, -0.1063059, -0.1063059, -…\n",
      "$ Episode_Title_Episode.68         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.09935361, -0.09935361, -0.09935361…\n",
      "$ Episode_Title_Episode.69         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1154438, -0.1154438, -0.1154438, -…\n",
      "$ Episode_Title_Episode.7          \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.09254577, -0.09254577, -0.09254577…\n",
      "$ Episode_Title_Episode.70         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1034273, -0.1034273, -0.1034273, -…\n",
      "$ Episode_Title_Episode.71         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1192449, -0.1192449, -0.1192449, -…\n",
      "$ Episode_Title_Episode.72         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1135914, -0.1135914, -0.1135914, -…\n",
      "$ Episode_Title_Episode.73         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1054689, -0.1054689, -0.1054689, -…\n",
      "$ Episode_Title_Episode.74         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.09652985, -0.09652985, -0.09652985…\n",
      "$ Episode_Title_Episode.75         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.09887348, -0.09887348, -0.09887348…\n",
      "$ Episode_Title_Episode.76         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.09262634, -0.09262634, -0.09262634…\n",
      "$ Episode_Title_Episode.77         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.09153658, -0.09153658, -0.09153658…\n",
      "$ Episode_Title_Episode.78         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1117406, -0.1117406, -0.1117406, -…\n",
      "$ Episode_Title_Episode.79         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1130846, -0.1130846, -0.1130846, -…\n",
      "$ Episode_Title_Episode.8          \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1017818, -0.1017818, -0.1017818, -…\n",
      "$ Episode_Title_Episode.80         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1092494, -0.1092494, -0.1092494, -…\n",
      "$ Episode_Title_Episode.81         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1147122, -0.1147122, -0.1147122, -…\n",
      "$ Episode_Title_Episode.82         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1062802, -0.1062802, -0.1062802, -…\n",
      "$ Episode_Title_Episode.83         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1077017, -0.1077017, -0.1077017, -…\n",
      "$ Episode_Title_Episode.84         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1007606, -0.1007606, -0.1007606, -…\n",
      "$ Episode_Title_Episode.85         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1001512, -0.1001512, -0.1001512, -…\n",
      "$ Episode_Title_Episode.86         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1069326, -0.1069326, -0.1069326, -…\n",
      "$ Episode_Title_Episode.87         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1009764, -0.1009764, -0.1009764, -…\n",
      "$ Episode_Title_Episode.88         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.1026807, -0.1026807, -0.1026807, -…\n",
      "$ Episode_Title_Episode.89         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.0972589, -0.0972589, -0.0972589, -…\n",
      "$ Episode_Title_Episode.9          \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.0953052, -0.0953052, -0.0953052, -…\n",
      "$ Episode_Title_Episode.90         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.09671261, -0.09671261, -0.09671261…\n",
      "$ Episode_Title_Episode.91         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.09688803, -0.09688803, -0.09688803…\n",
      "$ Episode_Title_Episode.92         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.09374005, -0.09374005, -0.09374005…\n",
      "$ Episode_Title_Episode.93         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.08918951, -0.08918951, -0.08918951…\n",
      "$ Episode_Title_Episode.94         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.09539064, -0.09539064, -0.09539064…\n",
      "$ Episode_Title_Episode.95         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.08057629, -0.08057629, -0.08057629…\n",
      "$ Episode_Title_Episode.96         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.09508415, -0.09508415, -0.09508415…\n",
      "$ Episode_Title_Episode.97         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.09365316, -0.09365316, -0.09365316…\n",
      "$ Episode_Title_Episode.98         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m 11.22833022, -0.08906032, -0.08906032…\n",
      "$ Episode_Title_Episode.99         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.111869, -0.111869, -0.111869, -0.1…\n",
      "$ Genre_Business                   \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.3468054, -0.3468054, -0.3468054, -…\n",
      "$ Genre_Comedy                     \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.3490497, 2.8649176, -0.3490497, -0…\n",
      "$ Genre_Education                  \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.2646747, -0.2646747, 3.7782178, -0…\n",
      "$ Genre_Health                     \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.3244111, -0.3244111, -0.3244111, -…\n",
      "$ Genre_Lifestyle                  \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.3514679, -0.3514679, -0.3514679, -…\n",
      "$ Genre_Music                      \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.3021501, -0.3021501, -0.3021501, -…\n",
      "$ Genre_News                       \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.303834, -0.303834, -0.303834, -0.3…\n",
      "$ Genre_Sports                     \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.3636708, -0.3636708, -0.3636708, -…\n",
      "$ Genre_Technology                 \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.3604907, -0.3604907, -0.3604907, 2…\n",
      "$ Genre_True.Crime                 \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m 2.7959611, -0.3576583, -0.3576583, -0…\n",
      "$ Publication_Day_Friday           \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.4106769, -0.4106769, -0.4106769, -…\n",
      "$ Publication_Day_Monday           \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.4189036, -0.4189036, -0.4189036, 2…\n",
      "$ Publication_Day_Saturday         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.4001269, 2.4992036, -0.4001269, -0…\n",
      "$ Publication_Day_Sunday           \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.4276264, -0.4276264, -0.4276264, -…\n",
      "$ Publication_Day_Thursday         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m 2.4872984, -0.4020421, -0.4020421, -0…\n",
      "$ Publication_Day_Tuesday          \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.3879282, -0.3879282, 2.5777931, -0…\n",
      "$ Publication_Day_Wednesday        \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.4098984, -0.4098984, -0.4098984, -…\n",
      "$ Publication_Time_Afternoon       \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.560842, 1.783031, -0.560842, -0.56…\n",
      "$ Publication_Time_Evening         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.5943466, -0.5943466, 1.6825177, -0…\n",
      "$ Publication_Time_Morning         \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.5576639, -0.5576639, -0.5576639, 1…\n",
      "$ Publication_Time_Night           \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m 1.6763124, -0.5965467, -0.5965467, -0…\n",
      "$ Number_of_Ads_X0                 \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m 1.5642297, -0.6392914, 1.5642297, -0.…\n",
      "$ Number_of_Ads_X1                 \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.6320281, -0.6320281, -0.6320281, -…\n",
      "$ Number_of_Ads_X2                 \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.5169386, 1.9344633, -0.5169386, 1.…\n",
      "$ Number_of_Ads_X3                 \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.5211132, -0.5211132, -0.5211132, -…\n",
      "$ Episode_Sentiment_Negative       \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.7073524, 1.4137206, 1.4137206, -0.…\n",
      "$ Episode_Sentiment_Neutral        \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m -0.7098467, -0.7098467, -0.7098467, -…\n",
      "$ Episode_Sentiment_Positive       \u001b[3m\u001b[90m<dbl>\u001b[39m\u001b[23m 1.4202031, -0.7041237, -0.7041237, 1.…\n"
     ]
    }
   ],
   "source": [
    "recipe_basic <- recipe(Listening_Time_minutes ~ ., data = train_tbl) %>%\n",
    "    step_rm(id) %>%\n",
    "    step_mutate(across(where(is_character),as.factor))%>% \n",
    "    step_mutate(Number_of_Ads=as.factor(Number_of_Ads)) %>% \n",
    "    step_dummy(all_nominal(),one_hot=TRUE) %>%\n",
    "    step_impute_mean(Episode_Length_minutes,Guest_Popularity_percentage) %>% \n",
    "    step_normalize(all_numeric_predictors())\n",
    "\n",
    "recipe_basic%>% prep() %>% juice() %>% glimpse()\n",
    "\n",
    "\n",
    "recipe_prep <- prep(recipe_basic)\n"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 7,
   "id": "9845b451",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-04-21T21:11:19.229215Z",
     "iopub.status.busy": "2025-04-21T21:11:19.227449Z",
     "iopub.status.idle": "2025-04-21T21:12:19.713801Z",
     "shell.execute_reply": "2025-04-21T21:12:19.711556Z"
    },
    "papermill": {
     "duration": 60.502587,
     "end_time": "2025-04-21T21:12:19.717025",
     "exception": false,
     "start_time": "2025-04-21T21:11:19.214438",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[1mRows: \u001b[22m\u001b[34m250000\u001b[39m \u001b[1mColumns: \u001b[22m\u001b[34m11\u001b[39m\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[36m──\u001b[39m \u001b[1mColumn specification\u001b[22m \u001b[36m────────────────────────────────────────────────────────\u001b[39m\n",
      "\u001b[1mDelimiter:\u001b[22m \",\"\n",
      "\u001b[31mchr\u001b[39m (6): Podcast_Name, Episode_Title, Genre, Publication_Day, Publication_Ti...\n",
      "\u001b[32mdbl\u001b[39m (5): id, Episode_Length_minutes, Host_Popularity_percentage, Guest_Popul...\n"
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
    "\n",
    "baked_train_tbl <- bake(recipe_prep, new_data = train_tbl)\n",
    "\n",
    "test_tbl <- read_csv(\"/kaggle/input/playground-series-s5e4/test.csv\") %>% \n",
    "    mutate(Number_of_Ads = ifelse(!(Number_of_Ads %in% c(0, 1, 2, 3)), 1, Number_of_Ads))\n",
    "\n",
    "baked_test_tbl <-  bake(recipe_prep, new_data = test_tbl)"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 8,
   "id": "87fc562d",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-04-21T21:12:19.742211Z",
     "iopub.status.busy": "2025-04-21T21:12:19.740415Z",
     "iopub.status.idle": "2025-04-21T21:12:26.629281Z",
     "shell.execute_reply": "2025-04-21T21:12:26.626100Z"
    },
    "papermill": {
     "duration": 6.904615,
     "end_time": "2025-04-21T21:12:26.634711",
     "exception": false,
     "start_time": "2025-04-21T21:12:19.730096",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "\n",
      "H2O is not running yet, starting it now...\n",
      "\n",
      "Note:  In case of errors look at the following log files:\n",
      "    /tmp/RtmpX6rZq8/filed16b6d507/h2o_UnknownUser_started_from_r.out\n",
      "    /tmp/RtmpX6rZq8/filed95521db/h2o_UnknownUser_started_from_r.err\n",
      "\n",
      "\n",
      "Starting H2O JVM and connecting: .... Connection successful!\n",
      "\n",
      "R is connected to the H2O cluster: \n",
      "    H2O cluster uptime:         3 seconds 84 milliseconds \n",
      "    H2O cluster timezone:       Etc/UTC \n",
      "    H2O data parsing timezone:  UTC \n",
      "    H2O cluster version:        3.44.0.3 \n",
      "    H2O cluster version age:    1 year, 4 months and 1 day \n",
      "    H2O cluster name:           H2O_started_from_R_root_sxd023 \n",
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
      "Your H2O cluster version is (1 year, 4 months and 1 day) old. There may be a newer version available.\n",
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
    "h2o.init()"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 9,
   "id": "c160e8b1",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-04-21T21:12:26.672538Z",
     "iopub.status.busy": "2025-04-21T21:12:26.669733Z",
     "iopub.status.idle": "2025-04-21T23:13:28.414412Z",
     "shell.execute_reply": "2025-04-21T23:13:28.411688Z"
    },
    "papermill": {
     "duration": 7261.767016,
     "end_time": "2025-04-21T23:13:28.418427",
     "exception": false,
     "start_time": "2025-04-21T21:12:26.651411",
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
      "  |============================================                          |  64%"
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
      "  |=============================================================         |  86%"
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
     "data": {
      "text/plain": [
       "                                              model_id     rmse      mse\n",
       "1              DeepLearning_1_AutoML_1_20250421_211322 13.26700 176.0133\n",
       "2 DeepLearning_grid_1_AutoML_1_20250421_211322_model_2 13.31410 177.2654\n",
       "3 DeepLearning_grid_1_AutoML_1_20250421_211322_model_1 13.32135 177.4584\n",
       "4 DeepLearning_grid_1_AutoML_1_20250421_211322_model_7 13.32187 177.4722\n",
       "5 DeepLearning_grid_1_AutoML_1_20250421_211322_model_3 13.32319 177.5074\n",
       "6 DeepLearning_grid_1_AutoML_1_20250421_211322_model_5 13.34563 178.1058\n",
       "       mae rmsle mean_residual_deviance\n",
       "1 9.684545   NaN               176.0133\n",
       "2 9.742042   NaN               177.2654\n",
       "3 9.743940   NaN               177.4584\n",
       "4 9.752859   NaN               177.4722\n",
       "5 9.755102   NaN               177.5074\n",
       "6 9.788672   NaN               178.1058\n",
       "\n",
       "[9 rows x 6 columns] "
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    }
   ],
   "source": [
    "\n",
    "\n",
    "y <- \"Listening_Time_minutes\"\n",
    "x <- setdiff(names(baked_train_tbl), y)\n",
    "\n",
    "## H2O AutoML does multiple folds of validation and choose best model based on specified sort_metric\n",
    "\n",
    "\n",
    "h2o_automl_models <- h2o.automl(\n",
    "    x = x,\n",
    "    y = y,\n",
    "    training_frame   = as.h2o(baked_train_tbl),\n",
    "    nfolds           = 10,\n",
    "    include_algos = c(\"DeepLearning\"),\n",
    "    stopping_metric = \"RMSE\",\n",
    "    sort_metric = \"RMSE\",\n",
    "    max_runtime_secs = 7200\n",
    ")\n",
    "h2o_automl_models@leaderboard\n"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 10,
   "id": "cbfb050f",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-04-21T23:13:29.898089Z",
     "iopub.status.busy": "2025-04-21T23:13:29.895568Z",
     "iopub.status.idle": "2025-04-21T23:14:38.890570Z",
     "shell.execute_reply": "2025-04-21T23:14:38.888308Z"
    },
    "papermill": {
     "duration": 70.436272,
     "end_time": "2025-04-21T23:14:38.894568",
     "exception": false,
     "start_time": "2025-04-21T23:13:28.458296",
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
     "data": {
      "text/html": [
       "0.00199405966476181"
      ],
      "text/latex": [
       "0.00199405966476181"
      ],
      "text/markdown": [
       "0.00199405966476181"
      ],
      "text/plain": [
       "[1] 0.00199406"
      ]
     },
     "metadata": {},
     "output_type": "display_data"
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
     "data": {
      "image/png": "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\nsJPmX3FaHuw07IxWfdZquIukebDTpmMlGfTCk0qrKSH/H4rr2AF8eczqfnNmSw8i+nDnoKKw\np9LPScoS/r1E1FG5hGF4f4xs8KnGRYb1bUT5v0Mpvqgsm+Xv2OAJTUvUcbWYgQMHEptz99KJ\nsA3Bf95/8PDho6gHd2NLcWphTvrD0x9yT0RtMNdf+SWewHxuc5vOx58T0YcHO4l6FXzVtLWJ\nSPFUbNRU8ZjNVn+Cn3G1KU2MZ19NzmRlmTMi3u5tbTfv5Cv5S32CvfJqlWR9ix++ErfMF5ov\naGajVMAbN6nO+sArRJTyaqWU5hV5GZWSzUANlX4qCsSOvzVUPsiJP26M85bpN4goPeFgDkuU\nUcLpodko5FfXdjjUTr/s1NvXP+a+3WNmC+X39jh4vYfS03Ido+LlpOfffMXQyUjzzny4c0WT\naip9VjvcgiKOi9OONhtT60EvflJp/omEYAfwxRDoGTnUqNet3/CfJw2wEPCIKOWZ+lsw5aRF\nqZQwfGOr4q6gVvSF0Hiiz3EljaSog726DzsT9YGI+GLzRs2adBviU8/50vffnS9Zg9KMJ4rH\nDk5GKq+a1TWl48+p4DdQnoJfAlrfp4c/v2eVNn88JKJ/Zv6Tvo+RBwihgfuvzpUUlUqwvuqG\nr4QtC/ScVS4ha+aRe6qHTJoSmymtXNQV8ko2AzVW2qkoNHBXacKsYe5KsbKsxByZUUmnh4aj\noKD9QKuZfsoT28lSUsyiy3mMipP2dp/isW1nW807U7I+qx3u0l85UquOaTvo6iaVpp9ICHYA\nustt/NU7Sz2LqaBvn3u0B8Pw/w4NERb19yhfZFuorNR/txan5JerYnMSvZt8czkpk4jqj1l3\nZskwMyGPiOJv9/y+pG3yJfk/07x6mkK1Kim/+uF+kvyBQOxIZa3BzMH0xzQiehsxI/pQ7imT\njr6LxXmbv6Trq374StByTnpUhoyUs13incTc5fH17D5x3eOSzsDPJDvtnqzghfiT7uWOOF9k\nZSHk5ZR8emjxn6g8JjZPZK94/LLYe3ZV4BjdXpi/f6tHZzvNO6OfPkGTaiolaoe7ZGuhTPON\nWaJBL5tPZgQ7gC9YpbqdiE4TEctKxU3bdDQVK17KSIhPypEREU9QTj+bFsDk/ciRnfofq/T5\nlPlBiz0BH18ukH8OEtHPMwea5X0QP/mj8O40TQn0nFubisMSM4no1oy91HmC4iVZzvvpYbnH\n1hjX6FfiRXyKcdVJzYxnXU7OzE6L8p/0TF44YE5+Ui+P9S1xy9LshGnX3y7xVNzljF0XfE/+\nyND2+0/dzkJ3ZmCRcjKezbqdMKueeV6BbM2KSPkjQ/ux9LmmR3kMtMiwYU094aP0bCK6sfgm\nbeukeOlwX6+J/8YTUaWawRGhvSpqjNJen+i76aH8saRSh3F2hqTxhJGkl6TPaoe79DTfmOX3\nv1stTl6lHOD/hZFdYAuT3E+WwAk7lK56f7iWvZ2NjY2NjU2vXY8/Q0+MXY3lD7LTH/X5/UQ2\nS0Syp5cPBHReW+z7KP11/o3RpFlvFI+3/537iRwbvrXPmkgNWyjS3KG55we8vT6x1y9/yreS\nNOPFjK89r+UdpfTVoiIuEFVq/OCvq8of3UnMJCKRUeMZ1U0UL5dsfTVRspZXd/bZdf0FEUkz\n3q8Z02bZ09y9HU1njfjUW3RnBn7Kgva+e2++IiJpxruVo1qtfp4sL289/xv5g3KaHqWf2Gow\nguBOuTvtHu/uHfx3boSKu7Zh4MGr0dHR0dHR+j3dSPsxykw8FZTn92ua3t5GmpWSlOf180dH\ntgY3r9MjLksqf7Xl7BXyP/007EyJ55Xa4VaLzUlL+oRsVouNWX7/uzVYBwDQJcVfx66w6J2D\nFPXNnL2+GTT4K5/mhnlX4TJy7JGQdyEGlSuYq1Cciig2bq5c3tw491PM9bt/FIVJz6YrFio/\nFTExeqbyBwtfZGSiJyAihsnf16N8Vqy7Qe4ZjkKD2oOHjVj04APLsplJ4UKlK5NVreNRt4Y9\nv+CFQJ+k5xTTQpFnxWanRbWolH8QksjYtkHD2sZKv8tYN5tU1IXKCmylnIynivrKtxMoXtKz\nYOXO1xp0XvlVrda3mOErvNaat1z4OnYGlvZ6fKXr2Nl2T8iWfmpBrDYzsEjFnBVbsqnIKl/Y\njMmdJIZW9npKG8TQoXdS3sX5ymR6KJRyYms1/dLfhdiK8v9/WVZ183CvpbiOndi4yfMSjVHJ\nLndSDNOaQ9PzT27WtDOa91mr4S6S8lmxxZBPMA07VvpBl9NqSuByJwC6SNtgx7Lsnqn5X7fK\nzN2/vvw+/7Kc5RrsWJad16WKSgcYnjhw8y+Kp8rBbrdvgcqKD6aDo+qrNCIycpm5Mv8kvz7b\nHhTTwqdujZD85GhrewMqikObUY/Si761gPJ2KFmwY1lpc5P8H2uClbaAtuurVbDTvGVFsOML\nLRR39lSQmDc+9kL9nSc0nIFFKtdgp2/x1SIf1WkpMfc8GVvgNlOlnx4KpZzY2k6/lycW2Rd1\n+KPY1H3XgwJXW9R8jMo22Jm59fkvOUvljRp2RsNq2g53YVoFO807VspBl0OwA/jilSDYsSz7\n5MKu4b07VbWxEAsldtVcW3fuFbwxRPmvZLb8g51MmrLlt9GNXR30xXwDU8uGHfttvvDyU9ex\ny0l/Mi2gs4OZIY8nMLZwHH8zPvcFWfbBxT80cXXQE4qruTX9ZsSkfxMyMj6cVtxjwMBqQDEt\nFHMzU2lW/J9LpnVtWdfKzFggEJtZO7Ty9V+652LxNwPN73AJgx17Ie92mWKTVtLCL2u8vtoG\nOw1bVr5XbHL0uYkDuznZmouFEpsqdQKC5kdrfK9YTWZgkco52H0tk6ZsmD6sjqO1RCixcawd\nEBSsslJypZweCqWc2CWYfmlxN+cFDfF0qWKiLxLqGTnWaTJ06rLIQlmK1XiMSh/s+EKRuW21\ndn7+wVtPZnxiT5mGndGkWgmGW4W2wU7T/pdu0OVKEOwYli35KWwAAAC65lzP6u3+ekpE+hZf\np8bvU1sfvmgYbhU4eQIAAACAIxDsAAAAADgCwQ4AAACAI3CBYgAA4BQT10Yt3tkTkdhU9WIu\nwD0YbhU4eQIAAACAI/BTLAAAAABHINgBAAAAcASCHQAAAABHINgBAAAAcASCHQAAAABHINgB\nAAAAcASCHQAAAABHINgBAAAAcASCHQAAAABHINgBAAAAcASCHQAAAABHINgBAAAAcASCHQAA\nAABHINgBAAAAcASCHQAAAABHINgBAAAAcASCHQAAAABHINgBAAAAcASCHQAAAABHINgBAAAA\ncASCHQAAAABHINgBAAAAcASCHQAAAABHINgBAAAAcASCHQAAAABHINgBAAAAcASCHQAAAABH\nINgBAAAAcASCHQAAAABHINgBAAAAcASCHQAAAABHINgBAAAAcASCHQAAAABHINgBAAAAcASC\nHQAAAABHINgBAAAAcASCHQAAAABHINgBAAAAcASCHQAAAABHINgBAAAAcASCHQAAAABHINgB\nAAAAcASCHQAAAABHINgBAAAAcASCHQAAAABHINgBAAAAcASCHQAAAABHINgBAAAAcASCHQAA\nAABHINgBAAAAcASCHQAAAABHINgBAAAAcASCHQAAAABHINgBAAAAcASCHQAAAABHINgBAAAA\n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\nSSQSHx8fPh+XYwSALwaCHQAAAABH4OQJAAAAAI5AsAMAAADgCAQ7AAAAAI5AsAMAAADgCAQ7\nAAAAAI5AsAMAAADgCAQ7AAAAAI5AsAMAAADgCAQ7AAAAAI5AsAMAAADgCAQ7AAAAAI5AsAMA\nAADgCAQ7AAAAAI5AsAMAAADgCAQ7AAAAAI5AsAMAAADgCAQ7AAAAAI5AsAMAAADgCAQ7AAAA\nAI5AsAMAAADgCAQ7AAAAAI5AsAMAAADgCAQ7AAAAAI5AsAMAAADgCAQ7AAAAAI5AsAMAAADg\nCAQ7AAAAAI4QVHQHAADySaXS0NDQjIyM8luERCLx8fHh8/nltwgAgIqCYAcAOuTYsWN+fn7l\nvZQjR474+vqW91IAAD4/BDsA0CHp6elEZNy4h9jOpTzaz4yNTL72l3wpAADcg2AHADpHbOei\n79KionsBAPDlwckTAAAAAByBYAcAAADAEQh2AAAAAByBYAcAAADAEQh2AAAAAByBYFfuMj6E\nMoWI9E2c6jUPmr89VcaWsv3wIS4Mw4R+KMcLupZG5LrmDMNITFu8ypIWfvVC/5oMw8x58fHz\nd0xz8k4Wr5TbX76Ic0mZn7NLp72rMAxz+WOW/OlwWyO9Sh1KsxYAAFDhcLmTz0So79y1k2ve\nM+nb54+v3bq8bMo/+09Fx5ye9aXk6+SYGVXqr2q2+npofyet3piZFN5pbOi9td3KqWPlyrxR\nxx4ZboqnceeOXUnKdO7k66qf/9/HWvhZb2Ogg10CAABdgGD3mehZ9Dl06Fflkne3D7dp3vve\nmV8n/jd2SV3ziuqYVlhZRmJiYkqWTNs38gS8B+t7rQ56+72zaXl0rFzVmbD60IT8p0cbWHe7\n9fbr9Tt/q2KMLgEAgE75UnYVcZBFve47p9QlomOroiq6L+WuybrJfMqZ3OG70v/0rJCRllFm\nbQEAAHACgl1FMm9mTkQp0Snyp9kpUfMDv3GrYqMnFJvbVPPxDzr/RPXgs6TIEyO+amtrbiQ2\nrOTWqse6009UKmQl3f91ZO9a9pZikYFDDY+RM9bHZ+fvYEuJOT8xoJuzvaVEKDQ0sWrYusfy\nQ3dVWri4fa53U7dKRnoiPcMa9VpOXRkiz09rapqZVl9MRBcH12IYZtXrVM3X1KzOuL1DnFNe\n7vEOvl58zeJ7KD+2LOV5qF99Rz0DPaHY0KlR543hcSTL2DV7hLujtUQotq5eL2jFaeU2WWnS\n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\nSnKh7xsz1hBRm2WjFze1lmbFjQuPK7teaar9vLN9HAzjwn8esv+pvOTizx0PxqY69d2ypLOD\notq2VfcYhr97xw+GfEZeYtWo/55hztKsN9NvxH/+bgMAwKcg2IF6ZnXG7R3inPJyj3fw9WKq\n/VXHkmGYJGmBwBZgbahXqYP8sfyYvJTnoX71HfUM9IRiQ6dGnTeGx5EsY9fsEe6O1hKh2Lp6\nvaAVp1VaTo+7PLp3O1tzI7GBqWsz74X7VLvBSpN2zhvrVbuKsZ7YqnKNjgMmnIzMP+LtXM/q\nPL4+Ee3/9dvKFgYNJ17TcMWzU6LmB37jVsVGTyg2t6nm4x90/kn+AYXHmtkZ2o0hon9nNmAY\nZsxjbfZospnjDzzjCc1WtLdvN78TEZ2dcFilSlLkiRFftbU1NxIbVnJr1WPd6SeFm7m4fa53\nU7dKRnoiPcMa9VpOXRmiVVxm+MYbwlbq83k7B3nfTs3+GLPDe/51iWnLM38EKFc7l5gpMvL0\nMhYpF9p3sCGi+KhkbRYIAADlC8EONOK3+kQTY3H4L52Ovi3tfTa9G/S6kO40asKkAN86T26c\nHNW+8eQ+dYcsuNCga8DwgK5pz+8uG9dxqtLJBDnpke1c224++7xu627tGlZ/ce3kpD6Nv1oQ\noajAylLHtnEZMO33KLLv2i/Ay9X64u6lPvWcF4cV2Ad2NbiT/6LzTbsN+tbbXpN+5qTd6VTL\nY8rK3UmmTj0D+ns4GZ/cvbxjHbdtj3OjjNvk+cvn9yMiR9/pa9eu7Wepr/lGSLg37XZKlnWT\nZZXFfMtGC21E/He3Jz1Mz/9ZMzFqk2u9rhsOnZdUrtfTr43gVdiozq5zbhbYPRYxt0urgdPD\nnlLnnv6DevsKXl4LDvTtFHxT824QkXH1Qad+8spOi+rWe/XYdmPSZcys0weriPnKdf4Iv3bt\n8h6VN97e9pSIajU212pxAABQrnCvWNAIX+x44MB3Dh2XD+k8883N+aX5gyCqamBMxHwTPkNE\nnb+q1v/Qs6XHXC7F3PS0kBDRuPY9ag44fGh51LwtFvL6GR9ORzcY9t+lNTX1BUT0/s6ehp4D\nDk9rHzYyobWJiIjuLOyy8lKcR9C2fxYHiBgiojcROxu2GjTN12fIhxtmAoaIiM3yXS78Nzaq\njqFQw34e9vc7/zq105zjJ6Z1lpdEH/nJufucwPYTBz5bT0SVewQMfZ08bvKfFo2+HjmyvlYb\n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\n"
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
    "\n",
    "\n",
    "\n",
    "\n",
    "\n",
    "## Use the leading model to do prediction\n",
    "\n",
    "predictions <- h2o.predict(h2o_automl_models@leader, newdata = as.h2o(baked_test_tbl))\n",
    "\n",
    "\n",
    "## Join Column Id with predicted price and change column name to SalePrice\n",
    "\n",
    "predictions_tbl <- predictions %>% \n",
    "    as_tibble() %>% \n",
    "    mutate(id = test_tbl$id) %>% \n",
    "    rename(Listening_Time_minutes = predict) %>% \n",
    "    select(id,Listening_Time_minutes)\n",
    "\n",
    "## RMSE \n",
    "\n",
    "performance_h2o <- h2o.performance(h2o_automl_models@leader, \n",
    "                                   newdata = as.h2o(baked_test_tbl %>% \n",
    "                                                        mutate(Listening_Time_minutes = predictions_tbl$Listening_Time_minutes)))\n",
    "\n",
    "performance_h2o@metrics$RMSE\n",
    "\n",
    "\n",
    "## Get list of 10 most important variables to influence prediction\n",
    "\n",
    "h2o.permutation_importance_plot(h2o_automl_models@leader,newdata=as.h2o(baked_test_tbl %>% \n",
    "                                                                            mutate(Listening_Time_minutes = predictions_tbl$Listening_Time_minutes)))\n",
    "\n",
    "## Write to CSV file\n",
    "\n",
    "predictions_tbl %>% \n",
    "    write_csv(\"H2O_AutoML_20250404_01.csv\") \n",
    "\n",
    "predictions_tbl %>% \n",
    "    write_csv(\"submission.csv\") \n"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 11,
   "id": "ed70c87e",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-04-21T23:14:38.962264Z",
     "iopub.status.busy": "2025-04-21T23:14:38.959786Z",
     "iopub.status.idle": "2025-04-21T23:14:39.087530Z",
     "shell.execute_reply": "2025-04-21T23:14:39.085012Z"
    },
    "papermill": {
     "duration": 0.159298,
     "end_time": "2025-04-21T23:14:39.090630",
     "exception": false,
     "start_time": "2025-04-21T23:14:38.931332",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [],
   "source": [
    "## Write to CSV file\n",
    "\n",
    "predictions_tbl %>% \n",
    "    write_csv(\"H2O_AutoML_20250404_01.csv\") \n",
    "\n",
    "predictions_tbl %>% \n",
    "    write_csv(\"submission.csv\") "
   ]
  }
 ],
 "metadata": {
  "kaggle": {
   "accelerator": "none",
   "dataSources": [
    {
     "databundleVersionId": 11351736,
     "sourceId": 91715,
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
   "duration": 7598.982094,
   "end_time": "2025-04-21T23:14:39.634841",
   "environment_variables": {},
   "exception": null,
   "input_path": "__notebook__.ipynb",
   "output_path": "__notebook__.ipynb",
   "parameters": {},
   "start_time": "2025-04-21T21:08:00.652747",
   "version": "2.6.0"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 5
}
