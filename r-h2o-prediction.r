{
 "cells": [
  {
   "cell_type": "code",
   "execution_count": 1,
   "id": "9404b750",
   "metadata": {
    "_execution_state": "idle",
    "_uuid": "051d70d956493feee0c6d64651c6a088724dca2a",
    "execution": {
     "iopub.execute_input": "2025-04-21T21:21:31.891806Z",
     "iopub.status.busy": "2025-04-21T21:21:31.889250Z",
     "iopub.status.idle": "2025-04-21T21:21:33.425965Z",
     "shell.execute_reply": "2025-04-21T21:21:33.423663Z"
    },
    "papermill": {
     "duration": 1.547222,
     "end_time": "2025-04-21T21:21:33.429848",
     "exception": false,
     "start_time": "2025-04-21T21:21:31.882626",
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
   "id": "d33028ed",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-04-21T21:21:33.476336Z",
     "iopub.status.busy": "2025-04-21T21:21:33.440969Z",
     "iopub.status.idle": "2025-04-21T21:21:37.870166Z",
     "shell.execute_reply": "2025-04-21T21:21:37.866670Z"
    },
    "papermill": {
     "duration": 4.439697,
     "end_time": "2025-04-21T21:21:37.873963",
     "exception": false,
     "start_time": "2025-04-21T21:21:33.434266",
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
      "\u001b[34m•\u001b[39m Search for functions across packages at \u001b[32mhttps://www.tidymodels.org/find/\u001b[39m\n",
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
   "id": "a578233e",
   "metadata": {
    "papermill": {
     "duration": 0.004953,
     "end_time": "2025-04-21T21:21:37.883713",
     "exception": false,
     "start_time": "2025-04-21T21:21:37.878760",
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
   "id": "3047c245",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-04-21T21:21:37.901247Z",
     "iopub.status.busy": "2025-04-21T21:21:37.897127Z",
     "iopub.status.idle": "2025-04-21T21:21:49.525936Z",
     "shell.execute_reply": "2025-04-21T21:21:49.523362Z"
    },
    "papermill": {
     "duration": 11.640382,
     "end_time": "2025-04-21T21:21:49.529026",
     "exception": false,
     "start_time": "2025-04-21T21:21:37.888644",
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
       "\\553688 (73.8%)</td><td><span style=white-space:pre-wrap>&lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAF8AAADKCAQAAABp7lSOAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVFSkAMv5kAAABc0lEQVR42u3bQYrCQBRF0aRxdS6hFxh30OtyB3Fg01QkCPYgv17lXEfODlKBPCjndUruqxqAn9ul/XL7fRC+52rWu9qn9eXXv07Xat1HhR8efHz8yPDx8SPDr+yy/fpT7fmwuX177vo1/6837/tpbQ7PErG22qwtfPzI8PHxI8PHPyvfXKksnG9tdcRPCx8fPzJ8fPzI8Cuztiobib+s9/W+LkEXa0f69fPCx8ePDB8fP7Jwvqt4R2dt9ZK1hY8fGT4+fmT4+GflW1tHN9Da2rmKl3MRb5qmtflkrK1WHH548PHxI8PHx48Mv7KdtZX0wmxtVeaPTx3x08LHx48MHx8/MvzKzJXKwvnWVkf8tPDx8SPDx8ePDL8ya6uykfjPq3jVpH/z88LHx48MHx8/MvzK/PHp6KytXrK28PEjw8fHjwwf/6x8a+voBlpbu1fxOq85JC9nv/+LeNunM/zw4OPjR4aPjx8ZfmUjra28wg8PfmUPPABb6rm7Ea0AAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjFUMjE6MjE6NDErMDA6MDB9QlcfAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIxVDIxOjIxOjQxKzAwOjAwDB/vowAAAABJRU5ErkJggg==\"&gt;                        </span></td><td>750000\\\n",
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
       "\\650479 (86.7%)</span></td><td><span style=white-space:pre-wrap>&lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAG0AAADKCAQAAAAF6AaLAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVFSkAMv5kAAABX0lEQVR42u3YwWnDQBRFUSm4unSQFOh0kPac7STglQPi/LlnZeHNXCSEn8/HMdXb1QcorbTVbb34ehzH53n1kV6xvjkG37XSRKWJShOVJipNVJqoNNG5Lhx6qh3Hsedeuz/ug/7g2uWuzVKaqDRRaaLSRKWJShM1RUW7pLWyEaWJShOVJipNVJqoNNHgtFa2aJe0VjaiNFFpotJEpYlKE5UmGpzWyhbtktbKRpQmKk1Umqg0UWmi0kSD01rZoqaoqDRRaaLSRKWJShOVJipN1MoWtbJFpYlKE5UmKk1Umqg00eC0pqhol7RWNqI0UWmi0kSliUoTlSYanNbKFu2S1spGlCYqTVSaqDRRaaLSRIPTWtmiXdJa2YjSRKWJShOVJipNVJpocForW3RbLwYM0eXBu/3+5v3qo/2jwQ9kaaLSRKWJShOVJipN9OeX//fV53nRx/L59CfaM4MfyNJEP0K2Ox7416vXAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDI1LTA0LTIxVDIxOjIxOjQxKzAwOjAwfUJXHwAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyNS0wNC0yMVQyMToyMTo0MSswMDowMAwf76MAAAAASUVORK5CYII=\"&gt;                                                    </span></td><td>750000\\\n",
       "(100.0%)</td><td><span style=white-space:pre-wrap>0\\\n",
       "(0.0%)      </span></td></tr>\n",
       "\t<tr><th scope=row>3</th><td> 3</td><td><span style=white-space:pre-wrap>Episode_Length_minutes\\\n",
       "[numeric]     </span></td><td><span style=white-space:pre-wrap>Mean (sd) : 64.5 (33)\\\n",
       "min &lt; med &lt; max:\\\n",
       "0 &lt; 63.8 &lt; 325.2\\\n",
       "IQR (CV) : 58.3 (0.5)                                                                                                                                        </span></td><td><span style=white-space:pre-wrap>12268 distinct values                                                                                                                                                                                                   </span></td><td><span style=white-space:pre-wrap>&lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVFSqZO6/eAAAA5klEQVR42u3cwQ2CMBhAYWuYzg10wLqBc7kB3kiJEpFiWt7/Hhe4NHwBSgKENJ5idG69A0KFbmsoN1LFQHl2sd9qhtqtcpeGzaO8dZnWHq2FH1qE9niE/gLt/Qj9WpjJSCitKmgen9PSGvKtlbeX3D1kJ2g5Ax9zNvYapSWUllBaQmkJpSWUllBaQmkJpSWUllBaQmmFgc6e1B//xcNKKO3lb1mYU1coLaG0hNISSksoLaG0hNISSksoLaG0hNISSksoLaG0hNISSksoLaG0wkBT+WnRHfad0bX4TUaC2RYLc+oKpfUCK5UeTY+BarAAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjFUMjE6MjE6NDIrMDA6MDBMqk2CAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIxVDIxOjIxOjQyKzAwOjAwPff1PgAAAABJRU5ErkJggg==\"&gt;                                                                                                                                                                                                                    </span></td><td>662907\\\n",
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
       "\\85059 (11.3%)                              </span></td><td><span style=white-space:pre-wrap>&lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAABoAAAC3CAQAAACmwYZ1AAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVFSqZO6/eAAAAy0lEQVRo3u2awQ2DMBAEfRHVpQQXSDqgLjpwHvmwxo4OiMiBZnhZ8kg+jgVbwkrazmOHc6I0LAev8mxOmlK2Ze3Ba0JCUgYdTi5JHnn7MvFwNGR5Y/ctk60rpdRLrhK8T0hIypWTm80haXL79QXvExKScuXkfljn1/XNrQneJyQk5bwQsltGQvqdFDy5Io1lrq52loPfciQkJfjGl+QiITUJnlznxleX4Tyyaq3B+4SEpNwjuTuOrDXB+4SEpJDcI8tDQvqXZDf8HeoNSZBWhwHfHEYAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjFUMjE6MjE6NDIrMDA6MDBMqk2CAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIxVDIxOjIxOjQyKzAwOjAwPff1PgAAAABJRU5ErkJggg==\"&gt;                                                                                                                                                                                                                                                        </span></td><td>750000\\\n",
       "(100.0%)</td><td><span style=white-space:pre-wrap>0\\\n",
       "(0.0%)      </span></td></tr>\n",
       "\t<tr><th scope=row>5</th><td> 5</td><td>Host_Popularity_percentage\\\n",
       "[numeric] </td><td><span style=white-space:pre-wrap>Mean (sd) : 59.9 (22.9)\\\n",
       "min &lt; med &lt; max:\\\n",
       "1.3 &lt; 60 &lt; 119.5\\\n",
       "IQR (CV) : 40.1 (0.4)                                                                                                                                      </span></td><td><span style=white-space:pre-wrap>8038 distinct values                                                                                                                                                                                                    </span></td><td><span style=white-space:pre-wrap>&lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVFSxwWArrAAABK0lEQVR42u3b0Q2CMABFUWqYjg10QNyAudgAPxCoSiNtKdDXe3+MJhAPlBajmqEqo9vZbwAo0LBq+4nx2LCdL+6Hz2aHZs8/dehOmvdjd7ZmY8UMXaBqAVWrGGjw8rI0rajjgtNFravpVucdoBNwO2Lpm5Nudd4B6ntIlrqqH8bH3/M3HZa9zmxCaNww3DpOLgC91k3ioUPXXev8/O8e3FlCm/hd/Il19KqFTnHZQD9vS/ynuGygsVdxAmg/rL9y7jJTzGQEVC3Pa7TN9hsM78ko/T1MmooZukDVAqoWULWAqgVULaBqAVULqFpA1QKqFlC1gKoFVC2gagFVC6haQNUCqhZQtYCqBVQtoGoBVQuoWsVAjf0j+We2v5hf7279qcuI2ZwVM3SBqvUCy9ktIuH0SSgAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjFUMjE6MjE6NDQrMDA6MDAveni4AAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIxVDIxOjIxOjQ0KzAwOjAwXifABAAAAABJRU5ErkJggg==\"&gt;                                                                                                                        </span></td><td>750000\\\n",
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
       "\\107886 (14.4%)                                                                                </span></td><td><span style=white-space:pre-wrap>&lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAB4AAACCCAQAAAD7nbARAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVFSxwWArrAAAArElEQVRYw+3Z2w2AIAwF0NYwnSN0QN2A9fDX+iiiNqZy+SPhJNCGG6Jc6P4YHtgPcVpP5jKaizMJr2sU9MzAwL446WluwuqK8QXw2pVU256qaSh8ionGmlYjaJ+BgX1xD0kibGA7Sfb1CNpnYGBf3EOSbLfX+CbRNQnaZ2BgX9xDkuBNAgzsjf+fJMImtpLkqBpB+wwM7Iv/nyREj764bisStM/AwL6YO/wLvACUmyhPC06I2AAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAyNS0wNC0yMVQyMToyMTo0NCswMDowMC96eLgAAAAldEVYdGRhdGU6bW9kaWZ5ADIwMjUtMDQtMjFUMjE6MjE6NDQrMDA6MDBeJ8AEAAAAAElFTkSuQmCC\"&gt;                                                                                                                                                                                                                                                                                                    </span></td><td>750000\\\n",
       "(100.0%)</td><td><span style=white-space:pre-wrap>0\\\n",
       "(0.0%)      </span></td></tr>\n",
       "\t<tr><th scope=row>7</th><td> 7</td><td><span style=white-space:pre-wrap>Publication_Time\\\n",
       "[character]         </span></td><td><span style=white-space:pre-wrap>1\\. Afternoon\\\n",
       "2\\. Evening\\\n",
       "3\\. Morning\\\n",
       "4\\. Night                                                                                                                                                                  </span></td><td><span style=white-space:pre-wrap>\\179460 (23.9%)\\\n",
       "\\195778 (26.1%)\\\n",
       "\\177913 (23.7%)\\\n",
       "\\196849 (26.2%)                                                                                                                                            </span></td><td><span style=white-space:pre-wrap>&lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAACoAAABOCAQAAAD8r0ycAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVFSxwWArrAAAAiklEQVRYw+3WSw6AIAxF0dawOpfAAnUHbk+HFHXEJ2nD7cxETvKEPNRbxs82wQyEJvtwNn3grCIidmmqX9j9xgcFBV0TfbXUNQRV24PaAVlnfvyj52o1MQc1f70XcY4UKCioe5TmL9PW/PkTsLv5/3YhzpECBQV1j9L8ZfjnBwUFXQOd3/yu48dBH/iKFxn/tftSAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDI1LTA0LTIxVDIxOjIxOjQ0KzAwOjAwL3p4uAAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyNS0wNC0yMVQyMToyMTo0NCswMDowMF4nwAQAAAAASUVORK5CYII=\"&gt;                                                                                                                                                                                                                                                                                                                                                </span></td><td>750000\\\n",
       "(100.0%)</td><td><span style=white-space:pre-wrap>0\\\n",
       "(0.0%)      </span></td></tr>\n",
       "\t<tr><th scope=row>8</th><td> 8</td><td>Guest_Popularity_percentage\\\n",
       "[numeric]</td><td><span style=white-space:pre-wrap>Mean (sd) : 52.2 (28.5)\\\n",
       "min &lt; med &lt; max:\\\n",
       "0 &lt; 53.6 &lt; 119.9\\\n",
       "IQR (CV) : 48.2 (0.5)                                                                                                                                      </span></td><td><span style=white-space:pre-wrap>10019 distinct values                                                                                                                                                                                                   </span></td><td><span style=white-space:pre-wrap>&lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVFS6eVmvHAAABS0lEQVR42u2bwRGDIBBFIWN16SAp0HRgXenAHBgcRoMisot8/vPkRXmwu66M2tn0waP2AChK0TyG8MSK3GJcysBb5gZRwvozZF/lBE9jjDGTruWKbkK3G1GV0D1im8Xj7MO9VF7fQtRn8ZmpaFT0+lQ0LzoW6lFVRbeDPg7EUo8mVdF1+E3F1quqaIqEXivxV7RM0+bXr6xG7tgiK3q1xsmRO33sjFKp926iLLouKL55y0OuCp8UlV4/mQKWIXrnMrVPdjH6zu6oLSAu2hrdiCbmaEo1dGFcd2coUXRP5w4bXMVE29eJwxx16L0vVhaV61S06SZ0KYoGRdGgKBoURYOiaFAUDYqiQVE0KIoGRdGgKBoURYOiaFAUDYqiQVE0KIoGRdGgKBoURYOiaFAUDYqi0Y2oDT+x/sB8b+14Bb+VWTC3KN2ELkXR+AGM4D3GuUKOYwAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAyNS0wNC0yMVQyMToyMTo0NiswMDowMLjlaZEAAAAldEVYdGRhdGU6bW9kaWZ5ADIwMjUtMDQtMjFUMjE6MjE6NDYrMDA6MDDJuNEtAAAAAElFTkSuQmCC\"&gt;                                                                                </span></td><td>603970\\\n",
       "(80.5%) </td><td>146030\\\n",
       "(19.5%)</td></tr>\n",
       "\t<tr><th scope=row>9</th><td> 9</td><td><span style=white-space:pre-wrap>Number_of_Ads\\\n",
       "[numeric]              </span></td><td><span style=white-space:pre-wrap>Mean (sd) : 1.3 (1.2)\\\n",
       "min &lt; med &lt; max:\\\n",
       "0 &lt; 1 &lt; 103.9\\\n",
       "IQR (CV) : 2 (0.9)                                                                                                                                              </span></td><td><span style=white-space:pre-wrap>12 distinct values                                                                                                                                                                                                      </span></td><td><span style=white-space:pre-wrap>&lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVFS/pUVtRAAAAs0lEQVR42u3cwQnCQBBAUSOpzhIsUDuwPb0IrjmJCgs/711CyGU+7OY4y/2wD8fZAwgV+p11fLkOF/a8zB7td+P/Z33/dHo+b7Nn/LvdHF2hNUJrhNYIrRFaI7RGaI3QGqE1QmuE1gitEVojtEZojdAaoTVCa4TWCK0RWiO0RmiN0BqhNUJrhNYIrRFaI7RGaI3QGqE1QmuE1git2WzWeG3UuBT2/wxrUJZCzyd2c3SF1jwANQAJB63xoakAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjFUMjE6MjE6NDcrMDA6MDAekmIlAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIxVDIxOjIxOjQ3KzAwOjAwb8/amQAAAABJRU5ErkJggg==\"&gt;                                                                                                                                                                                                                                                                                        </span></td><td>749999\\\n",
       "(100.0%)</td><td><span style=white-space:pre-wrap>1\\\n",
       "(0.0%)      </span></td></tr>\n",
       "\t<tr><th scope=row>10</th><td>10</td><td><span style=white-space:pre-wrap>Episode_Sentiment\\\n",
       "[character]        </span></td><td><span style=white-space:pre-wrap>1\\. Negative\\\n",
       "2\\. Neutral\\\n",
       "3\\. Positive                                                                                                                                                                                </span></td><td><span style=white-space:pre-wrap>\\250116 (33.3%)\\\n",
       "\\251291 (33.5%)\\\n",
       "\\248593 (33.1%)                                                                                                                                                                </span></td><td><span style=white-space:pre-wrap>&lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAADIAAAA7CAQAAACTORHyAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVFS/pUVtRAAAAeElEQVRYw+3YsQ3AIAxEUTtiOjbIgskGrEdaQyoig4j1r6PxE1AcQqvMz7HACIQku7hrdhpb5NTFOwEBAQH5I5LaZZmCqK1f/TzmHTs36J1cjs0oNCMICAjIJgjNOJSuGR0nm7PvnkSO9WsS505AQEBAnKN82W6HPFCdD3vWiEuiAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDI1LTA0LTIxVDIxOjIxOjQ3KzAwOjAwHpJiJQAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyNS0wNC0yMVQyMToyMTo0NyswMDowMG/P2pkAAAAASUVORK5CYII=\"&gt;                                                                                                                                                                                                                                                                                                                                                                        </span></td><td>750000\\\n",
       "(100.0%)</td><td><span style=white-space:pre-wrap>0\\\n",
       "(0.0%)      </span></td></tr>\n",
       "\t<tr><th scope=row>11</th><td>11</td><td><span style=white-space:pre-wrap>Listening_Time_minutes\\\n",
       "[numeric]     </span></td><td><span style=white-space:pre-wrap>Mean (sd) : 45.4 (27.1)\\\n",
       "min &lt; med &lt; max:\\\n",
       "0 &lt; 43.4 &lt; 120\\\n",
       "IQR (CV) : 41.6 (0.6)                                                                                                                                        </span></td><td><span style=white-space:pre-wrap>42807 distinct values                                                                                                                                                                                                   </span></td><td>&lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVFTETXmYyAAABhUlEQVR42u2b0XGDMBBEhccFuC46cAokHbguOiAfCaAgMCAk393evj+PB8aPW4mTwM0QfHCT/gEUpWge9/hDk3GCbhrkXzmHVyWef+7ZZ5loQwghvKStdjgp+q5+3WIC11Xhg6KzRLuhNVe2TY4dv5FUP1zRZUBHne3Idqpu0QXG6Bb7lwJENGWssUSEd0TLxq+9fopaorridwWfndGIrvmyoqjsaPqoaF0k+mMRUYkpzs1kRFE0KIqGsGg/9EM/fKJBYUXRoCgabkRFet2U/m/efVRr8t1UlKJo/BujiFsoq6JWHhjl4Ca6FJXhdzVTYz2jTLQeFEWDomi4EVWyTEsp/XRcrWjpZtRNdCmqhVItoXrRUlAUDTeiau+jS642EGZEr74Q5Ca6FEWDomiYE83dEDUnmgtF0aAoGmZ63ZRzbb5h0XP7hIyuHY5FGED02EqV0bXH+wgDic7/VV5TZXQtMy3hospCiq61Em6i60a0iXckvsHe7nxGY7QBc9vETXQpisYP9XNcCznJq+YAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjFUMjE6MjE6NDkrMDA6MDBOrRl4AAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIxVDIxOjIxOjQ5KzAwOjAwP/ChxAAAAABJRU5ErkJggg==\"&gt;</td><td>750000\\\n",
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
       "\\textbackslash{}553688 (73.8\\%) & <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAF8AAADKCAQAAABp7lSOAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVFSkAMv5kAAABc0lEQVR42u3bQYrCQBRF0aRxdS6hFxh30OtyB3Fg01QkCPYgv17lXEfODlKBPCjndUruqxqAn9ul/XL7fRC+52rWu9qn9eXXv07Xat1HhR8efHz8yPDx8SPDr+yy/fpT7fmwuX177vo1/6837/tpbQ7PErG22qwtfPzI8PHxI8PHPyvfXKksnG9tdcRPCx8fPzJ8fPzI8Cuztiobib+s9/W+LkEXa0f69fPCx8ePDB8fP7Jwvqt4R2dt9ZK1hY8fGT4+fmT4+GflW1tHN9Da2rmKl3MRb5qmtflkrK1WHH548PHxI8PHx48Mv7KdtZX0wmxtVeaPTx3x08LHx48MHx8/MvzKzJXKwvnWVkf8tPDx8SPDx8ePDL8ya6uykfjPq3jVpH/z88LHx48MHx8/MvzK/PHp6KytXrK28PEjw8fHjwwf/6x8a+voBlpbu1fxOq85JC9nv/+LeNunM/zw4OPjR4aPjx8ZfmUjra28wg8PfmUPPABb6rm7Ea0AAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjFUMjE6MjE6NDErMDA6MDB9QlcfAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIxVDIxOjIxOjQxKzAwOjAwDB/vowAAAABJRU5ErkJggg==\">                         & 750000\\textbackslash{}\n",
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
       "\\textbackslash{}650479 (86.7\\%) & <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAG0AAADKCAQAAAAF6AaLAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVFSkAMv5kAAABX0lEQVR42u3YwWnDQBRFUSm4unSQFOh0kPac7STglQPi/LlnZeHNXCSEn8/HMdXb1QcorbTVbb34ehzH53n1kV6xvjkG37XSRKWJShOVJipNVJqoNNG5Lhx6qh3Hsedeuz/ug/7g2uWuzVKaqDRRaaLSRKWJShM1RUW7pLWyEaWJShOVJipNVJqoNNHgtFa2aJe0VjaiNFFpotJEpYlKE5UmGpzWyhbtktbKRpQmKk1Umqg0UWmi0kSD01rZoqaoqDRRaaLSRKWJShOVJipN1MoWtbJFpYlKE5UmKk1Umqg00eC0pqhol7RWNqI0UWmi0kSliUoTlSYanNbKFu2S1spGlCYqTVSaqDRRaaLSRIPTWtmiXdJa2YjSRKWJShOVJipNVJpocForW3RbLwYM0eXBu/3+5v3qo/2jwQ9kaaLSRKWJShOVJipN9OeX//fV53nRx/L59CfaM4MfyNJEP0K2Ox7416vXAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDI1LTA0LTIxVDIxOjIxOjQxKzAwOjAwfUJXHwAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyNS0wNC0yMVQyMToyMTo0MSswMDowMAwf76MAAAAASUVORK5CYII=\">                                                     & 750000\\textbackslash{}\n",
       "(100.0\\%) & 0\\textbackslash{}\n",
       "(0.0\\%)      \\\\\n",
       "\t3 &  3 & Episode\\_Length\\_minutes\\textbackslash{}\n",
       "{[}numeric{]}      & Mean (sd) : 64.5 (33)\\textbackslash{}\n",
       "min < med < max:\\textbackslash{}\n",
       "0 < 63.8 < 325.2\\textbackslash{}\n",
       "IQR (CV) : 58.3 (0.5)                                                                                                                                         & 12268 distinct values                                                                                                                                                                                                    & <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVFSqZO6/eAAAA5klEQVR42u3cwQ2CMBhAYWuYzg10wLqBc7kB3kiJEpFiWt7/Hhe4NHwBSgKENJ5idG69A0KFbmsoN1LFQHl2sd9qhtqtcpeGzaO8dZnWHq2FH1qE9niE/gLt/Qj9WpjJSCitKmgen9PSGvKtlbeX3D1kJ2g5Ax9zNvYapSWUllBaQmkJpSWUllBaQmkJpSWUllBaQmmFgc6e1B//xcNKKO3lb1mYU1coLaG0hNISSksoLaG0hNISSksoLaG0hNISSksoLaG0hNISSksoLaG0wkBT+WnRHfad0bX4TUaC2RYLc+oKpfUCK5UeTY+BarAAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjFUMjE6MjE6NDIrMDA6MDBMqk2CAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIxVDIxOjIxOjQyKzAwOjAwPff1PgAAAABJRU5ErkJggg==\">                                                                                                                                                                                                                     & 662907\\textbackslash{}\n",
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
       "\\textbackslash{}85059 (11.3\\%)                               & <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAABoAAAC3CAQAAACmwYZ1AAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVFSqZO6/eAAAAy0lEQVRo3u2awQ2DMBAEfRHVpQQXSDqgLjpwHvmwxo4OiMiBZnhZ8kg+jgVbwkrazmOHc6I0LAev8mxOmlK2Ze3Ba0JCUgYdTi5JHnn7MvFwNGR5Y/ctk60rpdRLrhK8T0hIypWTm80haXL79QXvExKScuXkfljn1/XNrQneJyQk5bwQsltGQvqdFDy5Io1lrq52loPfciQkJfjGl+QiITUJnlznxleX4Tyyaq3B+4SEpNwjuTuOrDXB+4SEpJDcI8tDQvqXZDf8HeoNSZBWhwHfHEYAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjFUMjE6MjE6NDIrMDA6MDBMqk2CAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIxVDIxOjIxOjQyKzAwOjAwPff1PgAAAABJRU5ErkJggg==\">                                                                                                                                                                                                                                                         & 750000\\textbackslash{}\n",
       "(100.0\\%) & 0\\textbackslash{}\n",
       "(0.0\\%)      \\\\\n",
       "\t5 &  5 & Host\\_Popularity\\_percentage\\textbackslash{}\n",
       "{[}numeric{]}  & Mean (sd) : 59.9 (22.9)\\textbackslash{}\n",
       "min < med < max:\\textbackslash{}\n",
       "1.3 < 60 < 119.5\\textbackslash{}\n",
       "IQR (CV) : 40.1 (0.4)                                                                                                                                       & 8038 distinct values                                                                                                                                                                                                     & <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVFSxwWArrAAABK0lEQVR42u3b0Q2CMABFUWqYjg10QNyAudgAPxCoSiNtKdDXe3+MJhAPlBajmqEqo9vZbwAo0LBq+4nx2LCdL+6Hz2aHZs8/dehOmvdjd7ZmY8UMXaBqAVWrGGjw8rI0rajjgtNFravpVucdoBNwO2Lpm5Nudd4B6ntIlrqqH8bH3/M3HZa9zmxCaNww3DpOLgC91k3ioUPXXev8/O8e3FlCm/hd/Il19KqFTnHZQD9vS/ynuGygsVdxAmg/rL9y7jJTzGQEVC3Pa7TN9hsM78ko/T1MmooZukDVAqoWULWAqgVULaBqAVULqFpA1QKqFlC1gKoFVC2gagFVC6haQNUCqhZQtYCqBVQtoGoBVQuoWsVAjf0j+We2v5hf7279qcuI2ZwVM3SBqvUCy9ktIuH0SSgAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjFUMjE6MjE6NDQrMDA6MDAveni4AAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIxVDIxOjIxOjQ0KzAwOjAwXifABAAAAABJRU5ErkJggg==\">                                                                                                                         & 750000\\textbackslash{}\n",
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
       "\\textbackslash{}107886 (14.4\\%)                                                                                 & <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAB4AAACCCAQAAAD7nbARAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVFSxwWArrAAAArElEQVRYw+3Z2w2AIAwF0NYwnSN0QN2A9fDX+iiiNqZy+SPhJNCGG6Jc6P4YHtgPcVpP5jKaizMJr2sU9MzAwL446WluwuqK8QXw2pVU256qaSh8ionGmlYjaJ+BgX1xD0kibGA7Sfb1CNpnYGBf3EOSbLfX+CbRNQnaZ2BgX9xDkuBNAgzsjf+fJMImtpLkqBpB+wwM7Iv/nyREj764bisStM/AwL6YO/wLvACUmyhPC06I2AAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAyNS0wNC0yMVQyMToyMTo0NCswMDowMC96eLgAAAAldEVYdGRhdGU6bW9kaWZ5ADIwMjUtMDQtMjFUMjE6MjE6NDQrMDA6MDBeJ8AEAAAAAElFTkSuQmCC\">                                                                                                                                                                                                                                                                                                     & 750000\\textbackslash{}\n",
       "(100.0\\%) & 0\\textbackslash{}\n",
       "(0.0\\%)      \\\\\n",
       "\t7 &  7 & Publication\\_Time\\textbackslash{}\n",
       "{[}character{]}          & 1\\textbackslash{}. Afternoon\\textbackslash{}\n",
       "2\\textbackslash{}. Evening\\textbackslash{}\n",
       "3\\textbackslash{}. Morning\\textbackslash{}\n",
       "4\\textbackslash{}. Night                                                                                                                                                                   & \\textbackslash{}179460 (23.9\\%)\\textbackslash{}\n",
       "\\textbackslash{}195778 (26.1\\%)\\textbackslash{}\n",
       "\\textbackslash{}177913 (23.7\\%)\\textbackslash{}\n",
       "\\textbackslash{}196849 (26.2\\%)                                                                                                                                             & <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAACoAAABOCAQAAAD8r0ycAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVFSxwWArrAAAAiklEQVRYw+3WSw6AIAxF0dawOpfAAnUHbk+HFHXEJ2nD7cxETvKEPNRbxs82wQyEJvtwNn3grCIidmmqX9j9xgcFBV0TfbXUNQRV24PaAVlnfvyj52o1MQc1f70XcY4UKCioe5TmL9PW/PkTsLv5/3YhzpECBQV1j9L8ZfjnBwUFXQOd3/yu48dBH/iKFxn/tftSAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDI1LTA0LTIxVDIxOjIxOjQ0KzAwOjAwL3p4uAAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyNS0wNC0yMVQyMToyMTo0NCswMDowMF4nwAQAAAAASUVORK5CYII=\">                                                                                                                                                                                                                                                                                                                                                 & 750000\\textbackslash{}\n",
       "(100.0\\%) & 0\\textbackslash{}\n",
       "(0.0\\%)      \\\\\n",
       "\t8 &  8 & Guest\\_Popularity\\_percentage\\textbackslash{}\n",
       "{[}numeric{]} & Mean (sd) : 52.2 (28.5)\\textbackslash{}\n",
       "min < med < max:\\textbackslash{}\n",
       "0 < 53.6 < 119.9\\textbackslash{}\n",
       "IQR (CV) : 48.2 (0.5)                                                                                                                                       & 10019 distinct values                                                                                                                                                                                                    & <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVFS6eVmvHAAABS0lEQVR42u2bwRGDIBBFIWN16SAp0HRgXenAHBgcRoMisot8/vPkRXmwu66M2tn0waP2AChK0TyG8MSK3GJcysBb5gZRwvozZF/lBE9jjDGTruWKbkK3G1GV0D1im8Xj7MO9VF7fQtRn8ZmpaFT0+lQ0LzoW6lFVRbeDPg7EUo8mVdF1+E3F1quqaIqEXivxV7RM0+bXr6xG7tgiK3q1xsmRO33sjFKp926iLLouKL55y0OuCp8UlV4/mQKWIXrnMrVPdjH6zu6oLSAu2hrdiCbmaEo1dGFcd2coUXRP5w4bXMVE29eJwxx16L0vVhaV61S06SZ0KYoGRdGgKBoURYOiaFAUDYqiQVE0KIoGRdGgKBoURYOiaFAUDYqiQVE0KIoGRdGgKBoURYOiaFAUDYqi0Y2oDT+x/sB8b+14Bb+VWTC3KN2ELkXR+AGM4D3GuUKOYwAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAyNS0wNC0yMVQyMToyMTo0NiswMDowMLjlaZEAAAAldEVYdGRhdGU6bW9kaWZ5ADIwMjUtMDQtMjFUMjE6MjE6NDYrMDA6MDDJuNEtAAAAAElFTkSuQmCC\">                                                                                 & 603970\\textbackslash{}\n",
       "(80.5\\%)  & 146030\\textbackslash{}\n",
       "(19.5\\%)\\\\\n",
       "\t9 &  9 & Number\\_of\\_Ads\\textbackslash{}\n",
       "{[}numeric{]}               & Mean (sd) : 1.3 (1.2)\\textbackslash{}\n",
       "min < med < max:\\textbackslash{}\n",
       "0 < 1 < 103.9\\textbackslash{}\n",
       "IQR (CV) : 2 (0.9)                                                                                                                                               & 12 distinct values                                                                                                                                                                                                       & <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVFS/pUVtRAAAAs0lEQVR42u3cwQnCQBBAUSOpzhIsUDuwPb0IrjmJCgs/711CyGU+7OY4y/2wD8fZAwgV+p11fLkOF/a8zB7td+P/Z33/dHo+b7Nn/LvdHF2hNUJrhNYIrRFaI7RGaI3QGqE1QmuE1gitEVojtEZojdAaoTVCa4TWCK0RWiO0RmiN0BqhNUJrhNYIrRFaI7RGaI3QGqE1QmuE1git2WzWeG3UuBT2/wxrUJZCzyd2c3SF1jwANQAJB63xoakAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjFUMjE6MjE6NDcrMDA6MDAekmIlAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIxVDIxOjIxOjQ3KzAwOjAwb8/amQAAAABJRU5ErkJggg==\">                                                                                                                                                                                                                                                                                         & 749999\\textbackslash{}\n",
       "(100.0\\%) & 1\\textbackslash{}\n",
       "(0.0\\%)      \\\\\n",
       "\t10 & 10 & Episode\\_Sentiment\\textbackslash{}\n",
       "{[}character{]}         & 1\\textbackslash{}. Negative\\textbackslash{}\n",
       "2\\textbackslash{}. Neutral\\textbackslash{}\n",
       "3\\textbackslash{}. Positive                                                                                                                                                                                 & \\textbackslash{}250116 (33.3\\%)\\textbackslash{}\n",
       "\\textbackslash{}251291 (33.5\\%)\\textbackslash{}\n",
       "\\textbackslash{}248593 (33.1\\%)                                                                                                                                                                 & <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAADIAAAA7CAQAAACTORHyAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVFS/pUVtRAAAAeElEQVRYw+3YsQ3AIAxEUTtiOjbIgskGrEdaQyoig4j1r6PxE1AcQqvMz7HACIQku7hrdhpb5NTFOwEBAQH5I5LaZZmCqK1f/TzmHTs36J1cjs0oNCMICAjIJgjNOJSuGR0nm7PvnkSO9WsS505AQEBAnKN82W6HPFCdD3vWiEuiAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDI1LTA0LTIxVDIxOjIxOjQ3KzAwOjAwHpJiJQAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyNS0wNC0yMVQyMToyMTo0NyswMDowMG/P2pkAAAAASUVORK5CYII=\">                                                                                                                                                                                                                                                                                                                                                                         & 750000\\textbackslash{}\n",
       "(100.0\\%) & 0\\textbackslash{}\n",
       "(0.0\\%)      \\\\\n",
       "\t11 & 11 & Listening\\_Time\\_minutes\\textbackslash{}\n",
       "{[}numeric{]}      & Mean (sd) : 45.4 (27.1)\\textbackslash{}\n",
       "min < med < max:\\textbackslash{}\n",
       "0 < 43.4 < 120\\textbackslash{}\n",
       "IQR (CV) : 41.6 (0.6)                                                                                                                                         & 42807 distinct values                                                                                                                                                                                                    & <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVFTETXmYyAAABhUlEQVR42u2b0XGDMBBEhccFuC46cAokHbguOiAfCaAgMCAk393evj+PB8aPW4mTwM0QfHCT/gEUpWge9/hDk3GCbhrkXzmHVyWef+7ZZ5loQwghvKStdjgp+q5+3WIC11Xhg6KzRLuhNVe2TY4dv5FUP1zRZUBHne3Idqpu0QXG6Bb7lwJENGWssUSEd0TLxq+9fopaorridwWfndGIrvmyoqjsaPqoaF0k+mMRUYkpzs1kRFE0KIqGsGg/9EM/fKJBYUXRoCgabkRFet2U/m/efVRr8t1UlKJo/BujiFsoq6JWHhjl4Ca6FJXhdzVTYz2jTLQeFEWDomi4EVWyTEsp/XRcrWjpZtRNdCmqhVItoXrRUlAUDTeiau+jS642EGZEr74Q5Ca6FEWDomiYE83dEDUnmgtF0aAoGmZ63ZRzbb5h0XP7hIyuHY5FGED02EqV0bXH+wgDic7/VV5TZXQtMy3hospCiq61Em6i60a0iXckvsHe7nxGY7QBc9vETXQpisYP9XNcCznJq+YAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjFUMjE6MjE6NDkrMDA6MDBOrRl4AAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIxVDIxOjIxOjQ5KzAwOjAwP/ChxAAAAABJRU5ErkJggg==\"> & 750000\\textbackslash{}\n",
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
       "\\553688 (73.8%) | &lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAF8AAADKCAQAAABp7lSOAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVFSkAMv5kAAABc0lEQVR42u3bQYrCQBRF0aRxdS6hFxh30OtyB3Fg01QkCPYgv17lXEfODlKBPCjndUruqxqAn9ul/XL7fRC+52rWu9qn9eXXv07Xat1HhR8efHz8yPDx8SPDr+yy/fpT7fmwuX177vo1/6837/tpbQ7PErG22qwtfPzI8PHxI8PHPyvfXKksnG9tdcRPCx8fPzJ8fPzI8Cuztiobib+s9/W+LkEXa0f69fPCx8ePDB8fP7Jwvqt4R2dt9ZK1hY8fGT4+fmT4+GflW1tHN9Da2rmKl3MRb5qmtflkrK1WHH548PHxI8PHx48Mv7KdtZX0wmxtVeaPTx3x08LHx48MHx8/MvzKzJXKwvnWVkf8tPDx8SPDx8ePDL8ya6uykfjPq3jVpH/z88LHx48MHx8/MvzK/PHp6KytXrK28PEjw8fHjwwf/6x8a+voBlpbu1fxOq85JC9nv/+LeNunM/zw4OPjR4aPjx8ZfmUjra28wg8PfmUPPABb6rm7Ea0AAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjFUMjE6MjE6NDErMDA6MDB9QlcfAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIxVDIxOjIxOjQxKzAwOjAwDB/vowAAAABJRU5ErkJggg==\"&gt;                         | 750000\\\n",
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
       "\\650479 (86.7%) | &lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAG0AAADKCAQAAAAF6AaLAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVFSkAMv5kAAABX0lEQVR42u3YwWnDQBRFUSm4unSQFOh0kPac7STglQPi/LlnZeHNXCSEn8/HMdXb1QcorbTVbb34ehzH53n1kV6xvjkG37XSRKWJShOVJipNVJqoNNG5Lhx6qh3Hsedeuz/ug/7g2uWuzVKaqDRRaaLSRKWJShM1RUW7pLWyEaWJShOVJipNVJqoNNHgtFa2aJe0VjaiNFFpotJEpYlKE5UmGpzWyhbtktbKRpQmKk1Umqg0UWmi0kSD01rZoqaoqDRRaaLSRKWJShOVJipN1MoWtbJFpYlKE5UmKk1Umqg00eC0pqhol7RWNqI0UWmi0kSliUoTlSYanNbKFu2S1spGlCYqTVSaqDRRaaLSRIPTWtmiXdJa2YjSRKWJShOVJipNVJpocForW3RbLwYM0eXBu/3+5v3qo/2jwQ9kaaLSRKWJShOVJipN9OeX//fV53nRx/L59CfaM4MfyNJEP0K2Ox7416vXAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDI1LTA0LTIxVDIxOjIxOjQxKzAwOjAwfUJXHwAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyNS0wNC0yMVQyMToyMTo0MSswMDowMAwf76MAAAAASUVORK5CYII=\"&gt;                                                     | 750000\\\n",
       "(100.0%) | 0\\\n",
       "(0.0%)       |\n",
       "| 3 |  3 | Episode_Length_minutes\\\n",
       "[numeric]      | Mean (sd) : 64.5 (33)\\\n",
       "min &lt; med &lt; max:\\\n",
       "0 &lt; 63.8 &lt; 325.2\\\n",
       "IQR (CV) : 58.3 (0.5)                                                                                                                                         | 12268 distinct values                                                                                                                                                                                                    | &lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVFSqZO6/eAAAA5klEQVR42u3cwQ2CMBhAYWuYzg10wLqBc7kB3kiJEpFiWt7/Hhe4NHwBSgKENJ5idG69A0KFbmsoN1LFQHl2sd9qhtqtcpeGzaO8dZnWHq2FH1qE9niE/gLt/Qj9WpjJSCitKmgen9PSGvKtlbeX3D1kJ2g5Ax9zNvYapSWUllBaQmkJpSWUllBaQmkJpSWUllBaQmmFgc6e1B//xcNKKO3lb1mYU1coLaG0hNISSksoLaG0hNISSksoLaG0hNISSksoLaG0hNISSksoLaG0wkBT+WnRHfad0bX4TUaC2RYLc+oKpfUCK5UeTY+BarAAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjFUMjE6MjE6NDIrMDA6MDBMqk2CAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIxVDIxOjIxOjQyKzAwOjAwPff1PgAAAABJRU5ErkJggg==\"&gt;                                                                                                                                                                                                                     | 662907\\\n",
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
       "\\85059 (11.3%)                               | &lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAABoAAAC3CAQAAACmwYZ1AAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVFSqZO6/eAAAAy0lEQVRo3u2awQ2DMBAEfRHVpQQXSDqgLjpwHvmwxo4OiMiBZnhZ8kg+jgVbwkrazmOHc6I0LAev8mxOmlK2Ze3Ba0JCUgYdTi5JHnn7MvFwNGR5Y/ctk60rpdRLrhK8T0hIypWTm80haXL79QXvExKScuXkfljn1/XNrQneJyQk5bwQsltGQvqdFDy5Io1lrq52loPfciQkJfjGl+QiITUJnlznxleX4Tyyaq3B+4SEpNwjuTuOrDXB+4SEpJDcI8tDQvqXZDf8HeoNSZBWhwHfHEYAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjFUMjE6MjE6NDIrMDA6MDBMqk2CAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIxVDIxOjIxOjQyKzAwOjAwPff1PgAAAABJRU5ErkJggg==\"&gt;                                                                                                                                                                                                                                                         | 750000\\\n",
       "(100.0%) | 0\\\n",
       "(0.0%)       |\n",
       "| 5 |  5 | Host_Popularity_percentage\\\n",
       "[numeric]  | Mean (sd) : 59.9 (22.9)\\\n",
       "min &lt; med &lt; max:\\\n",
       "1.3 &lt; 60 &lt; 119.5\\\n",
       "IQR (CV) : 40.1 (0.4)                                                                                                                                       | 8038 distinct values                                                                                                                                                                                                     | &lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVFSxwWArrAAABK0lEQVR42u3b0Q2CMABFUWqYjg10QNyAudgAPxCoSiNtKdDXe3+MJhAPlBajmqEqo9vZbwAo0LBq+4nx2LCdL+6Hz2aHZs8/dehOmvdjd7ZmY8UMXaBqAVWrGGjw8rI0rajjgtNFravpVucdoBNwO2Lpm5Nudd4B6ntIlrqqH8bH3/M3HZa9zmxCaNww3DpOLgC91k3ioUPXXev8/O8e3FlCm/hd/Il19KqFTnHZQD9vS/ynuGygsVdxAmg/rL9y7jJTzGQEVC3Pa7TN9hsM78ko/T1MmooZukDVAqoWULWAqgVULaBqAVULqFpA1QKqFlC1gKoFVC2gagFVC6haQNUCqhZQtYCqBVQtoGoBVQuoWsVAjf0j+We2v5hf7279qcuI2ZwVM3SBqvUCy9ktIuH0SSgAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjFUMjE6MjE6NDQrMDA6MDAveni4AAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIxVDIxOjIxOjQ0KzAwOjAwXifABAAAAABJRU5ErkJggg==\"&gt;                                                                                                                         | 750000\\\n",
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
       "\\107886 (14.4%)                                                                                 | &lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAB4AAACCCAQAAAD7nbARAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVFSxwWArrAAAArElEQVRYw+3Z2w2AIAwF0NYwnSN0QN2A9fDX+iiiNqZy+SPhJNCGG6Jc6P4YHtgPcVpP5jKaizMJr2sU9MzAwL446WluwuqK8QXw2pVU256qaSh8ionGmlYjaJ+BgX1xD0kibGA7Sfb1CNpnYGBf3EOSbLfX+CbRNQnaZ2BgX9xDkuBNAgzsjf+fJMImtpLkqBpB+wwM7Iv/nyREj764bisStM/AwL6YO/wLvACUmyhPC06I2AAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAyNS0wNC0yMVQyMToyMTo0NCswMDowMC96eLgAAAAldEVYdGRhdGU6bW9kaWZ5ADIwMjUtMDQtMjFUMjE6MjE6NDQrMDA6MDBeJ8AEAAAAAElFTkSuQmCC\"&gt;                                                                                                                                                                                                                                                                                                     | 750000\\\n",
       "(100.0%) | 0\\\n",
       "(0.0%)       |\n",
       "| 7 |  7 | Publication_Time\\\n",
       "[character]          | 1\\. Afternoon\\\n",
       "2\\. Evening\\\n",
       "3\\. Morning\\\n",
       "4\\. Night                                                                                                                                                                   | \\179460 (23.9%)\\\n",
       "\\195778 (26.1%)\\\n",
       "\\177913 (23.7%)\\\n",
       "\\196849 (26.2%)                                                                                                                                             | &lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAACoAAABOCAQAAAD8r0ycAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVFSxwWArrAAAAiklEQVRYw+3WSw6AIAxF0dawOpfAAnUHbk+HFHXEJ2nD7cxETvKEPNRbxs82wQyEJvtwNn3grCIidmmqX9j9xgcFBV0TfbXUNQRV24PaAVlnfvyj52o1MQc1f70XcY4UKCioe5TmL9PW/PkTsLv5/3YhzpECBQV1j9L8ZfjnBwUFXQOd3/yu48dBH/iKFxn/tftSAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDI1LTA0LTIxVDIxOjIxOjQ0KzAwOjAwL3p4uAAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyNS0wNC0yMVQyMToyMTo0NCswMDowMF4nwAQAAAAASUVORK5CYII=\"&gt;                                                                                                                                                                                                                                                                                                                                                 | 750000\\\n",
       "(100.0%) | 0\\\n",
       "(0.0%)       |\n",
       "| 8 |  8 | Guest_Popularity_percentage\\\n",
       "[numeric] | Mean (sd) : 52.2 (28.5)\\\n",
       "min &lt; med &lt; max:\\\n",
       "0 &lt; 53.6 &lt; 119.9\\\n",
       "IQR (CV) : 48.2 (0.5)                                                                                                                                       | 10019 distinct values                                                                                                                                                                                                    | &lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVFS6eVmvHAAABS0lEQVR42u2bwRGDIBBFIWN16SAp0HRgXenAHBgcRoMisot8/vPkRXmwu66M2tn0waP2AChK0TyG8MSK3GJcysBb5gZRwvozZF/lBE9jjDGTruWKbkK3G1GV0D1im8Xj7MO9VF7fQtRn8ZmpaFT0+lQ0LzoW6lFVRbeDPg7EUo8mVdF1+E3F1quqaIqEXivxV7RM0+bXr6xG7tgiK3q1xsmRO33sjFKp926iLLouKL55y0OuCp8UlV4/mQKWIXrnMrVPdjH6zu6oLSAu2hrdiCbmaEo1dGFcd2coUXRP5w4bXMVE29eJwxx16L0vVhaV61S06SZ0KYoGRdGgKBoURYOiaFAUDYqiQVE0KIoGRdGgKBoURYOiaFAUDYqiQVE0KIoGRdGgKBoURYOiaFAUDYqi0Y2oDT+x/sB8b+14Bb+VWTC3KN2ELkXR+AGM4D3GuUKOYwAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAyNS0wNC0yMVQyMToyMTo0NiswMDowMLjlaZEAAAAldEVYdGRhdGU6bW9kaWZ5ADIwMjUtMDQtMjFUMjE6MjE6NDYrMDA6MDDJuNEtAAAAAElFTkSuQmCC\"&gt;                                                                                 | 603970\\\n",
       "(80.5%)  | 146030\\\n",
       "(19.5%) |\n",
       "| 9 |  9 | Number_of_Ads\\\n",
       "[numeric]               | Mean (sd) : 1.3 (1.2)\\\n",
       "min &lt; med &lt; max:\\\n",
       "0 &lt; 1 &lt; 103.9\\\n",
       "IQR (CV) : 2 (0.9)                                                                                                                                               | 12 distinct values                                                                                                                                                                                                       | &lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVFS/pUVtRAAAAs0lEQVR42u3cwQnCQBBAUSOpzhIsUDuwPb0IrjmJCgs/711CyGU+7OY4y/2wD8fZAwgV+p11fLkOF/a8zB7td+P/Z33/dHo+b7Nn/LvdHF2hNUJrhNYIrRFaI7RGaI3QGqE1QmuE1gitEVojtEZojdAaoTVCa4TWCK0RWiO0RmiN0BqhNUJrhNYIrRFaI7RGaI3QGqE1QmuE1git2WzWeG3UuBT2/wxrUJZCzyd2c3SF1jwANQAJB63xoakAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjFUMjE6MjE6NDcrMDA6MDAekmIlAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIxVDIxOjIxOjQ3KzAwOjAwb8/amQAAAABJRU5ErkJggg==\"&gt;                                                                                                                                                                                                                                                                                         | 749999\\\n",
       "(100.0%) | 1\\\n",
       "(0.0%)       |\n",
       "| 10 | 10 | Episode_Sentiment\\\n",
       "[character]         | 1\\. Negative\\\n",
       "2\\. Neutral\\\n",
       "3\\. Positive                                                                                                                                                                                 | \\250116 (33.3%)\\\n",
       "\\251291 (33.5%)\\\n",
       "\\248593 (33.1%)                                                                                                                                                                 | &lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAADIAAAA7CAQAAACTORHyAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVFS/pUVtRAAAAeElEQVRYw+3YsQ3AIAxEUTtiOjbIgskGrEdaQyoig4j1r6PxE1AcQqvMz7HACIQku7hrdhpb5NTFOwEBAQH5I5LaZZmCqK1f/TzmHTs36J1cjs0oNCMICAjIJgjNOJSuGR0nm7PvnkSO9WsS505AQEBAnKN82W6HPFCdD3vWiEuiAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDI1LTA0LTIxVDIxOjIxOjQ3KzAwOjAwHpJiJQAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyNS0wNC0yMVQyMToyMTo0NyswMDowMG/P2pkAAAAASUVORK5CYII=\"&gt;                                                                                                                                                                                                                                                                                                                                                                         | 750000\\\n",
       "(100.0%) | 0\\\n",
       "(0.0%)       |\n",
       "| 11 | 11 | Listening_Time_minutes\\\n",
       "[numeric]      | Mean (sd) : 45.4 (27.1)\\\n",
       "min &lt; med &lt; max:\\\n",
       "0 &lt; 43.4 &lt; 120\\\n",
       "IQR (CV) : 41.6 (0.6)                                                                                                                                         | 42807 distinct values                                                                                                                                                                                                    | &lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVFTETXmYyAAABhUlEQVR42u2b0XGDMBBEhccFuC46cAokHbguOiAfCaAgMCAk393evj+PB8aPW4mTwM0QfHCT/gEUpWge9/hDk3GCbhrkXzmHVyWef+7ZZ5loQwghvKStdjgp+q5+3WIC11Xhg6KzRLuhNVe2TY4dv5FUP1zRZUBHne3Idqpu0QXG6Bb7lwJENGWssUSEd0TLxq+9fopaorridwWfndGIrvmyoqjsaPqoaF0k+mMRUYkpzs1kRFE0KIqGsGg/9EM/fKJBYUXRoCgabkRFet2U/m/efVRr8t1UlKJo/BujiFsoq6JWHhjl4Ca6FJXhdzVTYz2jTLQeFEWDomi4EVWyTEsp/XRcrWjpZtRNdCmqhVItoXrRUlAUDTeiau+jS642EGZEr74Q5Ca6FEWDomiYE83dEDUnmgtF0aAoGmZ63ZRzbb5h0XP7hIyuHY5FGED02EqV0bXH+wgDic7/VV5TZXQtMy3hospCiq61Em6i60a0iXckvsHe7nxGY7QBc9vETXQpisYP9XNcCznJq+YAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjFUMjE6MjE6NDkrMDA6MDBOrRl4AAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIxVDIxOjIxOjQ5KzAwOjAwP/ChxAAAAABJRU5ErkJggg==\"&gt; | 750000\\\n",
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
       "1  <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAF8AAADKCAQAAABp7lSOAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVFSkAMv5kAAABc0lEQVR42u3bQYrCQBRF0aRxdS6hFxh30OtyB3Fg01QkCPYgv17lXEfODlKBPCjndUruqxqAn9ul/XL7fRC+52rWu9qn9eXXv07Xat1HhR8efHz8yPDx8SPDr+yy/fpT7fmwuX177vo1/6837/tpbQ7PErG22qwtfPzI8PHxI8PHPyvfXKksnG9tdcRPCx8fPzJ8fPzI8Cuztiobib+s9/W+LkEXa0f69fPCx8ePDB8fP7Jwvqt4R2dt9ZK1hY8fGT4+fmT4+GflW1tHN9Da2rmKl3MRb5qmtflkrK1WHH548PHxI8PHx48Mv7KdtZX0wmxtVeaPTx3x08LHx48MHx8/MvzKzJXKwvnWVkf8tPDx8SPDx8ePDL8ya6uykfjPq3jVpH/z88LHx48MHx8/MvzK/PHp6KytXrK28PEjw8fHjwwf/6x8a+voBlpbu1fxOq85JC9nv/+LeNunM/zw4OPjR4aPjx8ZfmUjra28wg8PfmUPPABb6rm7Ea0AAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjFUMjE6MjE6NDErMDA6MDB9QlcfAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIxVDIxOjIxOjQxKzAwOjAwDB/vowAAAABJRU5ErkJggg==\">                        \n",
       "2  <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAG0AAADKCAQAAAAF6AaLAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVFSkAMv5kAAABX0lEQVR42u3YwWnDQBRFUSm4unSQFOh0kPac7STglQPi/LlnZeHNXCSEn8/HMdXb1QcorbTVbb34ehzH53n1kV6xvjkG37XSRKWJShOVJipNVJqoNNG5Lhx6qh3Hsedeuz/ug/7g2uWuzVKaqDRRaaLSRKWJShM1RUW7pLWyEaWJShOVJipNVJqoNNHgtFa2aJe0VjaiNFFpotJEpYlKE5UmGpzWyhbtktbKRpQmKk1Umqg0UWmi0kSD01rZoqaoqDRRaaLSRKWJShOVJipN1MoWtbJFpYlKE5UmKk1Umqg00eC0pqhol7RWNqI0UWmi0kSliUoTlSYanNbKFu2S1spGlCYqTVSaqDRRaaLSRIPTWtmiXdJa2YjSRKWJShOVJipNVJpocForW3RbLwYM0eXBu/3+5v3qo/2jwQ9kaaLSRKWJShOVJipN9OeX//fV53nRx/L59CfaM4MfyNJEP0K2Ox7416vXAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDI1LTA0LTIxVDIxOjIxOjQxKzAwOjAwfUJXHwAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyNS0wNC0yMVQyMToyMTo0MSswMDowMAwf76MAAAAASUVORK5CYII=\">                                                    \n",
       "3  <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVFSqZO6/eAAAA5klEQVR42u3cwQ2CMBhAYWuYzg10wLqBc7kB3kiJEpFiWt7/Hhe4NHwBSgKENJ5idG69A0KFbmsoN1LFQHl2sd9qhtqtcpeGzaO8dZnWHq2FH1qE9niE/gLt/Qj9WpjJSCitKmgen9PSGvKtlbeX3D1kJ2g5Ax9zNvYapSWUllBaQmkJpSWUllBaQmkJpSWUllBaQmmFgc6e1B//xcNKKO3lb1mYU1coLaG0hNISSksoLaG0hNISSksoLaG0hNISSksoLaG0hNISSksoLaG0wkBT+WnRHfad0bX4TUaC2RYLc+oKpfUCK5UeTY+BarAAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjFUMjE6MjE6NDIrMDA6MDBMqk2CAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIxVDIxOjIxOjQyKzAwOjAwPff1PgAAAABJRU5ErkJggg==\">                                                                                                                                                                                                                    \n",
       "4  <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAABoAAAC3CAQAAACmwYZ1AAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVFSqZO6/eAAAAy0lEQVRo3u2awQ2DMBAEfRHVpQQXSDqgLjpwHvmwxo4OiMiBZnhZ8kg+jgVbwkrazmOHc6I0LAev8mxOmlK2Ze3Ba0JCUgYdTi5JHnn7MvFwNGR5Y/ctk60rpdRLrhK8T0hIypWTm80haXL79QXvExKScuXkfljn1/XNrQneJyQk5bwQsltGQvqdFDy5Io1lrq52loPfciQkJfjGl+QiITUJnlznxleX4Tyyaq3B+4SEpNwjuTuOrDXB+4SEpJDcI8tDQvqXZDf8HeoNSZBWhwHfHEYAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjFUMjE6MjE6NDIrMDA6MDBMqk2CAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIxVDIxOjIxOjQyKzAwOjAwPff1PgAAAABJRU5ErkJggg==\">                                                                                                                                                                                                                                                        \n",
       "5  <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVFSxwWArrAAABK0lEQVR42u3b0Q2CMABFUWqYjg10QNyAudgAPxCoSiNtKdDXe3+MJhAPlBajmqEqo9vZbwAo0LBq+4nx2LCdL+6Hz2aHZs8/dehOmvdjd7ZmY8UMXaBqAVWrGGjw8rI0rajjgtNFravpVucdoBNwO2Lpm5Nudd4B6ntIlrqqH8bH3/M3HZa9zmxCaNww3DpOLgC91k3ioUPXXev8/O8e3FlCm/hd/Il19KqFTnHZQD9vS/ynuGygsVdxAmg/rL9y7jJTzGQEVC3Pa7TN9hsM78ko/T1MmooZukDVAqoWULWAqgVULaBqAVULqFpA1QKqFlC1gKoFVC2gagFVC6haQNUCqhZQtYCqBVQtoGoBVQuoWsVAjf0j+We2v5hf7279qcuI2ZwVM3SBqvUCy9ktIuH0SSgAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjFUMjE6MjE6NDQrMDA6MDAveni4AAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIxVDIxOjIxOjQ0KzAwOjAwXifABAAAAABJRU5ErkJggg==\">                                                                                                                        \n",
       "6  <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAB4AAACCCAQAAAD7nbARAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVFSxwWArrAAAArElEQVRYw+3Z2w2AIAwF0NYwnSN0QN2A9fDX+iiiNqZy+SPhJNCGG6Jc6P4YHtgPcVpP5jKaizMJr2sU9MzAwL446WluwuqK8QXw2pVU256qaSh8ionGmlYjaJ+BgX1xD0kibGA7Sfb1CNpnYGBf3EOSbLfX+CbRNQnaZ2BgX9xDkuBNAgzsjf+fJMImtpLkqBpB+wwM7Iv/nyREj764bisStM/AwL6YO/wLvACUmyhPC06I2AAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAyNS0wNC0yMVQyMToyMTo0NCswMDowMC96eLgAAAAldEVYdGRhdGU6bW9kaWZ5ADIwMjUtMDQtMjFUMjE6MjE6NDQrMDA6MDBeJ8AEAAAAAElFTkSuQmCC\">                                                                                                                                                                                                                                                                                                    \n",
       "7  <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAACoAAABOCAQAAAD8r0ycAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVFSxwWArrAAAAiklEQVRYw+3WSw6AIAxF0dawOpfAAnUHbk+HFHXEJ2nD7cxETvKEPNRbxs82wQyEJvtwNn3grCIidmmqX9j9xgcFBV0TfbXUNQRV24PaAVlnfvyj52o1MQc1f70XcY4UKCioe5TmL9PW/PkTsLv5/3YhzpECBQV1j9L8ZfjnBwUFXQOd3/yu48dBH/iKFxn/tftSAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDI1LTA0LTIxVDIxOjIxOjQ0KzAwOjAwL3p4uAAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyNS0wNC0yMVQyMToyMTo0NCswMDowMF4nwAQAAAAASUVORK5CYII=\">                                                                                                                                                                                                                                                                                                                                                \n",
       "8  <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVFS6eVmvHAAABS0lEQVR42u2bwRGDIBBFIWN16SAp0HRgXenAHBgcRoMisot8/vPkRXmwu66M2tn0waP2AChK0TyG8MSK3GJcysBb5gZRwvozZF/lBE9jjDGTruWKbkK3G1GV0D1im8Xj7MO9VF7fQtRn8ZmpaFT0+lQ0LzoW6lFVRbeDPg7EUo8mVdF1+E3F1quqaIqEXivxV7RM0+bXr6xG7tgiK3q1xsmRO33sjFKp926iLLouKL55y0OuCp8UlV4/mQKWIXrnMrVPdjH6zu6oLSAu2hrdiCbmaEo1dGFcd2coUXRP5w4bXMVE29eJwxx16L0vVhaV61S06SZ0KYoGRdGgKBoURYOiaFAUDYqiQVE0KIoGRdGgKBoURYOiaFAUDYqiQVE0KIoGRdGgKBoURYOiaFAUDYqi0Y2oDT+x/sB8b+14Bb+VWTC3KN2ELkXR+AGM4D3GuUKOYwAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAyNS0wNC0yMVQyMToyMTo0NiswMDowMLjlaZEAAAAldEVYdGRhdGU6bW9kaWZ5ADIwMjUtMDQtMjFUMjE6MjE6NDYrMDA6MDDJuNEtAAAAAElFTkSuQmCC\">                                                                                \n",
       "9  <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVFS/pUVtRAAAAs0lEQVR42u3cwQnCQBBAUSOpzhIsUDuwPb0IrjmJCgs/711CyGU+7OY4y/2wD8fZAwgV+p11fLkOF/a8zB7td+P/Z33/dHo+b7Nn/LvdHF2hNUJrhNYIrRFaI7RGaI3QGqE1QmuE1gitEVojtEZojdAaoTVCa4TWCK0RWiO0RmiN0BqhNUJrhNYIrRFaI7RGaI3QGqE1QmuE1git2WzWeG3UuBT2/wxrUJZCzyd2c3SF1jwANQAJB63xoakAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjFUMjE6MjE6NDcrMDA6MDAekmIlAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIxVDIxOjIxOjQ3KzAwOjAwb8/amQAAAABJRU5ErkJggg==\">                                                                                                                                                                                                                                                                                        \n",
       "10 <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAADIAAAA7CAQAAACTORHyAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVFS/pUVtRAAAAeElEQVRYw+3YsQ3AIAxEUTtiOjbIgskGrEdaQyoig4j1r6PxE1AcQqvMz7HACIQku7hrdhpb5NTFOwEBAQH5I5LaZZmCqK1f/TzmHTs36J1cjs0oNCMICAjIJgjNOJSuGR0nm7PvnkSO9WsS505AQEBAnKN82W6HPFCdD3vWiEuiAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDI1LTA0LTIxVDIxOjIxOjQ3KzAwOjAwHpJiJQAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyNS0wNC0yMVQyMToyMTo0NyswMDowMG/P2pkAAAAASUVORK5CYII=\">                                                                                                                                                                                                                                                                                                                                                                        \n",
       "11 <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBUVFTETXmYyAAABhUlEQVR42u2b0XGDMBBEhccFuC46cAokHbguOiAfCaAgMCAk393evj+PB8aPW4mTwM0QfHCT/gEUpWge9/hDk3GCbhrkXzmHVyWef+7ZZ5loQwghvKStdjgp+q5+3WIC11Xhg6KzRLuhNVe2TY4dv5FUP1zRZUBHne3Idqpu0QXG6Bb7lwJENGWssUSEd0TLxq+9fopaorridwWfndGIrvmyoqjsaPqoaF0k+mMRUYkpzs1kRFE0KIqGsGg/9EM/fKJBYUXRoCgabkRFet2U/m/efVRr8t1UlKJo/BujiFsoq6JWHhjl4Ca6FJXhdzVTYz2jTLQeFEWDomi4EVWyTEsp/XRcrWjpZtRNdCmqhVItoXrRUlAUDTeiau+jS642EGZEr74Q5Ca6FEWDomiYE83dEDUnmgtF0aAoGmZ63ZRzbb5h0XP7hIyuHY5FGED02EqV0bXH+wgDic7/VV5TZXQtMy3hospCiq61Em6i60a0iXckvsHe7nxGY7QBc9vETXQpisYP9XNcCznJq+YAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjFUMjE6MjE6NDkrMDA6MDBOrRl4AAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIxVDIxOjIxOjQ5KzAwOjAwP/ChxAAAAABJRU5ErkJggg==\">\n",
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
   "id": "85108e3d",
   "metadata": {
    "papermill": {
     "duration": 0.007691,
     "end_time": "2025-04-21T21:21:49.544328",
     "exception": false,
     "start_time": "2025-04-21T21:21:49.536637",
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
   "id": "489dc82e",
   "metadata": {
    "papermill": {
     "duration": 0.007172,
     "end_time": "2025-04-21T21:21:49.558919",
     "exception": false,
     "start_time": "2025-04-21T21:21:49.551747",
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
   "id": "2b281994",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-04-21T21:21:49.578691Z",
     "iopub.status.busy": "2025-04-21T21:21:49.576489Z",
     "iopub.status.idle": "2025-04-21T21:23:24.905876Z",
     "shell.execute_reply": "2025-04-21T21:23:24.901609Z"
    },
    "papermill": {
     "duration": 95.343529,
     "end_time": "2025-04-21T21:23:24.909541",
     "exception": false,
     "start_time": "2025-04-21T21:21:49.566012",
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
      "/usr/bin/pandoc +RTS -K512m -RTS /kaggle/working/report.knit.md --to html4 --from markdown+autolink_bare_uris+tex_math_single_backslash --output pandocd11e997d2.html --lua-filter /usr/local/lib/R/site-library/rmarkdown/rmarkdown/lua/pagebreak.lua --lua-filter /usr/local/lib/R/site-library/rmarkdown/rmarkdown/lua/latex-div.lua --embed-resources --standalone --variable bs3=TRUE --section-divs --table-of-contents --toc-depth 6 --template /usr/local/lib/R/site-library/rmarkdown/rmd/h/default.html --no-highlight --variable highlightjs=1 --variable theme=yeti --mathjax --variable 'mathjax-url=https://mathjax.rstudio.com/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML' --include-in-header /tmp/Rtmpcl6XXb/rmarkdown-strd2953014c.html \n"
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
   "id": "8b5d2492",
   "metadata": {
    "papermill": {
     "duration": 0.011795,
     "end_time": "2025-04-21T21:23:24.935777",
     "exception": false,
     "start_time": "2025-04-21T21:23:24.923982",
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
   "id": "7f9ff497",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-04-21T21:23:24.959263Z",
     "iopub.status.busy": "2025-04-21T21:23:24.956878Z",
     "iopub.status.idle": "2025-04-21T21:23:25.016737Z",
     "shell.execute_reply": "2025-04-21T21:23:25.013717Z"
    },
    "papermill": {
     "duration": 0.075785,
     "end_time": "2025-04-21T21:23:25.019950",
     "exception": false,
     "start_time": "2025-04-21T21:23:24.944165",
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
   "id": "0a08939d",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-04-21T21:23:25.041706Z",
     "iopub.status.busy": "2025-04-21T21:23:25.039642Z",
     "iopub.status.idle": "2025-04-21T21:25:19.737140Z",
     "shell.execute_reply": "2025-04-21T21:25:19.734467Z"
    },
    "papermill": {
     "duration": 114.712377,
     "end_time": "2025-04-21T21:25:19.740790",
     "exception": false,
     "start_time": "2025-04-21T21:23:25.028413",
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
   "id": "c5bfe6f1",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-04-21T21:25:19.773751Z",
     "iopub.status.busy": "2025-04-21T21:25:19.771703Z",
     "iopub.status.idle": "2025-04-21T21:26:28.441276Z",
     "shell.execute_reply": "2025-04-21T21:26:28.437654Z"
    },
    "papermill": {
     "duration": 68.689304,
     "end_time": "2025-04-21T21:26:28.444894",
     "exception": false,
     "start_time": "2025-04-21T21:25:19.755590",
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
   "id": "53bd4e1e",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-04-21T21:26:28.477635Z",
     "iopub.status.busy": "2025-04-21T21:26:28.475125Z",
     "iopub.status.idle": "2025-04-21T21:26:37.862442Z",
     "shell.execute_reply": "2025-04-21T21:26:37.858801Z"
    },
    "papermill": {
     "duration": 9.405888,
     "end_time": "2025-04-21T21:26:37.866688",
     "exception": false,
     "start_time": "2025-04-21T21:26:28.460800",
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
      "    /tmp/Rtmpcl6XXb/filed17ecc043/h2o_UnknownUser_started_from_r.out\n",
      "    /tmp/Rtmpcl6XXb/filed284299/h2o_UnknownUser_started_from_r.err\n",
      "\n",
      "\n",
      "Starting H2O JVM and connecting: ..... Connection successful!\n",
      "\n",
      "R is connected to the H2O cluster: \n",
      "    H2O cluster uptime:         4 seconds 246 milliseconds \n",
      "    H2O cluster timezone:       Etc/UTC \n",
      "    H2O data parsing timezone:  UTC \n",
      "    H2O cluster version:        3.44.0.3 \n",
      "    H2O cluster version age:    1 year, 4 months and 1 day \n",
      "    H2O cluster name:           H2O_started_from_R_root_ecw068 \n",
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
   "id": "f38e3230",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-04-21T21:26:37.904270Z",
     "iopub.status.busy": "2025-04-21T21:26:37.901232Z",
     "iopub.status.idle": "2025-04-21T21:39:55.876631Z",
     "shell.execute_reply": "2025-04-21T21:39:55.872997Z"
    },
    "papermill": {
     "duration": 797.999929,
     "end_time": "2025-04-21T21:39:55.882742",
     "exception": false,
     "start_time": "2025-04-21T21:26:37.882813",
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
      "  |=======                                                               |  10%"
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
       "                                 model_id   rmse      mse      mae rmsle\n",
       "1 DeepLearning_1_AutoML_1_20250421_212748 13.266 175.9867 9.687824   NaN\n",
       "  mean_residual_deviance\n",
       "1               175.9867\n",
       "\n",
       "[1 row x 6 columns] "
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
    "    max_runtime_secs = 720\n",
    ")\n",
    "h2o_automl_models@leaderboard\n"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 10,
   "id": "ec7a3d0f",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-04-21T21:39:56.055451Z",
     "iopub.status.busy": "2025-04-21T21:39:56.053256Z",
     "iopub.status.idle": "2025-04-21T21:41:11.900894Z",
     "shell.execute_reply": "2025-04-21T21:41:11.897624Z"
    },
    "papermill": {
     "duration": 76.024954,
     "end_time": "2025-04-21T21:41:11.935444",
     "exception": false,
     "start_time": "2025-04-21T21:39:55.910490",
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
       "0.00182958354242251"
      ],
      "text/latex": [
       "0.00182958354242251"
      ],
      "text/markdown": [
       "0.00182958354242251"
      ],
      "text/plain": [
       "[1] 0.001829584"
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
      "image/png": "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\njV5aL+JTjKuOb2o8/WpyZnZadPD4p/LCPrPzk3p5rK/WLUuzEybffLvYS/GWM3Zd6D35T4Z2\nP3zqdRa6MwKLlJPxdPrfCdPrWuQVyNYsj5L/ZFhpJH2u4VEeO1pk2KCmnvBhejYR3Vp0m7b5\nKiYd6ek97s94IjKrGRoZ1q2i9lHa61M9Nz2Q/ywxazfK3pDUHjCSdG36XOLuLj31N2b5/e8u\nESefUg7wX2FkP6K5Se6RZcTYHUpPvT9Sq5K9ra2tra1tt12PP0NPjF2N5T9kpz/sseJUNktE\nsidXD4R0WFvsfJT+Ov/FaNKsN4qft/+ee0SOjdjaY02Umi0Uac53ufcHvL05rtsvv8m3kjTj\nxdSvvW7kXaX01cIiHhBVavzQr6vKf7qTmElEIqNGU6ubKCZrt77q0K7l1R38d918QUTSjPdr\nhvssfZJ7tqPJ9MGfmkV3RuCnzG8bsPf2KyKSZrxbObTl6ufJ8vJW876R/1BOw6P0A7sEjCDU\nN/ek3ePd3UN/z41QcTc29D14/dGjR48ePdLv6k6a76PMxDNj8qy4oe7rbaRZKUl5Xj9/eHRr\naDO3oLgsqXxqi5nL5X/6qdkZrcdVibu7RGxOWtInZLMabMzy+9+txjoAgC4p/jl2hT3a2U9R\n39zZ+5t+/b/yb2aY9xQuI8eghLwHMag8wVyF4lZEsXEz5fJmxrlHMdfv/1AUJj2dolio/FbE\nxEfTlA8sfJGRiZ6AiBgm/1yP8l2xHga5dzgKDWr3Hzh44f0PLMtmJkUIlZ5MVtXNs06NSvyC\nDwKNSc8ppoUi74rNTotubpZ/EZLI2K5+g9rGSt/L2DQdX9SDygpspZyMJ4r6yq8TKF7S01Dl\nztfqd1F5qkbrW8zuK7zW6rdc+Dl2BlaV9PhKz7Gz65KQLf3UglhNRmCRirkrVruhyCo/2IzJ\nHSSG1pX0lDaIoUP3pLyH85XJ8FAo5cDWaPilvztuJ8r//2VV1d3To5biOXZi48bPtdpH2j3u\npBimNb9Lz7+5Wd3OqN9njXZ3kZTvii2GfICp2bHS73Q5jYYEHncCoIs0DXYsy+6ZlP9xq8zC\n4+ur7/Mfy1muwY5l2bkdq6h0gOGJR2z+RfGrcrDbHVCgsuLAdHBoPZVGREYu01bm3+TXY9v9\nYlr41KsRkmOOtapkQEVx8Bn6ML3oVwsobwftgh3LSpuZ5H9ZE6q0BTRdX42CnfotK4IdX2ip\n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\nF3r97x8m/jt2fl3r0jho652nEjIVlQXGyTpqVWZycnJ6lqqUxi9U7QnLdkzI3dzjbd/58sse\nK6NmuZjp9SzjwgogdRS/vDjxadZAJ4FeeldN3faAJ6mkkOV/Pc+4Ks6EAACAcX0S14Y+Czb1\ngqMm1yWifUtvldIhpC6u7u7uPKaUhi/R+Cq5TkI0tgIKy5RlFuHD7xKr/1OgKvvNVyf101va\no3knUuT1vy3OV2npkr3O0mvJd2ILmJBS/UEAAEBpQ7CrQKx9rYko/W66ZnNnbVuGYVKUeYJH\nmL2J2LKdbkvGi9OjQttUsjYVSi1q+QbO3Xr+Y+Pv83XUu7MqK+XGD8NDazrZCgXSym4+w6ev\nTMrO/bOe/vDoxLDO7k62Ij7fxNyuQauQhTuuad5aXsPKovo8IvpnUE2GYZY+f/fh+Nnpt+aM\n6evl4iDmC60dqgX1iziamKZbj+YmOUXG7YjOjSUSEY8rcq5RJ2zS8lSlkbOWXmGa46Y/iu1S\nv4pYKuYLTVwbfrH65AtSZW6e+WWdKvYivtC+er2IRYd1B1ErU6J+GtvM08VMLLRzdmvff8LB\nhJSiVmLr/XMVIe/o13v12q/MXMsw/J9DXPTaC53DuK7VOVwJEW37YYizjbTBxHNkwMTmOyEF\n/yCykq9OGdixsq2ZyMymUeCAo0/fLXC1lNqGFnUGAACgVCHYVSCXVt0jIisfK8N3UWQktKnV\neu2RR3VbdW7ToPrjcwcn9WzU7eezhuyblXa2bY2GM1b9JXTx7jege03pk5Wzh9f2GyVXExFl\nJMXU8Wg/P+qAWd2W/YcO6dy27oNTMRHd6005/R8RtZo5f8GsdkTkNvCHFStW+JsL9QuTXe1Q\n02fyki0pFq5dw/r4uJod3LKwfW2vDfdS9XpO9m+x9Ghyl4GjJo4KM399Z9Pckb7D9xs+A8UW\n6N39eIbriAmTwjrVTrxwcETbRt/0rDv45+PeHcOGhXWUPbr267j2Uy6/0nRWq96N9ffoP3Xx\nLXLq2DusWS37f7YsCKrnPu/YiyIdlMOzWNCy0qsrkx7meXBBNXXrffNqUxqZCnQ7Gz6H8ZEd\n+v1ytGnngUMCnbSNRZ3YAvorZDcCPJrO2bjP1rNF3xD/7Bs7Org32P0ms0jnDgAAZUENZSvj\nzV4iMqvyrU6bMunxnd9nDuVzGIbhrX2armnd4WlDRMkKle7u/e2kIou2mtcNTAREZOMdfvtd\n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\nRNatERJU2sfZ2ZCZlpYQHxd7OGbT+q1xKZmlG/b+d/O3ZY3F/tCRC9vGBjV7R/Q+vV96sVlY\n4MkdK2Z+HZ2i9//hyJGeFTwsw96r7DPqxFUNbJyPff/RvCNX77Z07NixXpX6vNY3JOvimDFj\niqquQhH/zwcVGr+Zrri3679o+ayHVNO1qIpBS85er9uxb8+2jct7mfdtX/HJl9EZ+tI/nDje\ns6y7vestqOTzy6oHR51JM7mWKmdIPHctw9zvuz93P995T4b/wNdeaBzqf3LvphnT5yWYXWYd\niRtQydP6PTqwYralsneyBFByrX+ptohEvvTxqaSMXAeY0uK/e6eXoig1B64u2tIKxXuhvjq9\nx7yYy5Zrzqz5yF2v86r0VLLp1r/1NbPHbnW3KiXnw2hMNV+d3v2r7ReyLp5Z01NEGg5bmn3M\n+S2fOOuUoMhv7VGgjc1/qLyiKMPn71JV1ZR2fkzHCiKidyq99OQ1y5gr+7910SmB4XPtV6Zt\nFK8tFXvsANhNSx+Xf9z6XTv7Wd7DZoUHvbI/JPXqhqKpqvBUdHFKDZt1Yff/sl+5dUJks9Eb\nO846ED0wLOsazeyxM6fHvf9ir+FfrnPxqz9+xuiqtx9u1bVr11K1x3w5vkHWxaioKHvUaDP+\nRoNadVb8/v5ZFzcNqtF89sF/ktLruztlHzazZumhsQHp12PsUaMt1fNwPlF6+NUT47Iuplz6\n1a3040HNF5zd0CP7sBlhpV4/XS49aY89arSZ4rWl0tpRjQCKkb3XMzzCHrU6rFHLMhk7iv0H\noYgkmcwe/hVyXNl0+LIOHwX99WqX/U/vr+mmqW2yzhj41py1nTpNfvzZ/xv9ynsf/rDwhXa3\n7cNzKR0eFdXeXuXZlp9Bl+B86wtHnVEnIhWdc76gVfxdTIfPFWllheNoaqZnQBPLRWevFiLi\nXbNcjmFhFdxNR44XaWWFoHhtqez9TTCAEiyqlOuVg5Pi0s15DTKnfLXghIuvFj7+H/Rxubhz\nSpLptl1xit77m6UjTalHOnSfUez30eWmTre39p7Y2rfe5cHtq3ccMv1SZp4vd7H1ai3fywfe\n3Ho1PetiSN8WIvLOzgvZx6iZVybsjnct1dkO9dlacy9j4vF5ppsXE49/JSIXNmzJMWzJgQSj\nZ9OiLc32itmWyt7fBQMouf6b201ESjV4fN7yHUmZd5xQZk6NWfdr/weDRaTTJ/vtUaCNbR/e\n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\nWBi8eOp2AAAAAElFTkSuQmCC"
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
   "id": "0428ccaf",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-04-21T21:41:11.986400Z",
     "iopub.status.busy": "2025-04-21T21:41:11.983661Z",
     "iopub.status.idle": "2025-04-21T21:41:12.143557Z",
     "shell.execute_reply": "2025-04-21T21:41:12.140393Z"
    },
    "papermill": {
     "duration": 0.190001,
     "end_time": "2025-04-21T21:41:12.147801",
     "exception": false,
     "start_time": "2025-04-21T21:41:11.957800",
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
   "duration": 1184.748686,
   "end_time": "2025-04-21T21:41:12.704364",
   "environment_variables": {},
   "exception": null,
   "input_path": "__notebook__.ipynb",
   "output_path": "__notebook__.ipynb",
   "parameters": {},
   "start_time": "2025-04-21T21:21:27.955678",
   "version": "2.6.0"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 5
}
