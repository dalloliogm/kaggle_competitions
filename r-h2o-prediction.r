{
 "cells": [
  {
   "cell_type": "code",
   "execution_count": 1,
   "id": "0bfd2c59",
   "metadata": {
    "_execution_state": "idle",
    "_uuid": "051d70d956493feee0c6d64651c6a088724dca2a",
    "execution": {
     "iopub.execute_input": "2025-04-22T07:16:11.058063Z",
     "iopub.status.busy": "2025-04-22T07:16:11.056094Z",
     "iopub.status.idle": "2025-04-22T07:16:12.402134Z",
     "shell.execute_reply": "2025-04-22T07:16:12.400376Z"
    },
    "papermill": {
     "duration": 1.354614,
     "end_time": "2025-04-22T07:16:12.404489",
     "exception": false,
     "start_time": "2025-04-22T07:16:11.049875",
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
   "id": "ed56dd65",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-04-22T07:16:12.444211Z",
     "iopub.status.busy": "2025-04-22T07:16:12.414542Z",
     "iopub.status.idle": "2025-04-22T07:16:16.197330Z",
     "shell.execute_reply": "2025-04-22T07:16:16.195112Z"
    },
    "papermill": {
     "duration": 3.791306,
     "end_time": "2025-04-22T07:16:16.200046",
     "exception": false,
     "start_time": "2025-04-22T07:16:12.408740",
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
      "\u001b[34m•\u001b[39m Use \u001b[32mtidymodels_prefer()\u001b[39m to resolve common conflicts.\n",
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
   "id": "20e62bd3",
   "metadata": {
    "papermill": {
     "duration": 0.004839,
     "end_time": "2025-04-22T07:16:16.209695",
     "exception": false,
     "start_time": "2025-04-22T07:16:16.204856",
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
   "id": "2f7b6774",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-04-22T07:16:16.223738Z",
     "iopub.status.busy": "2025-04-22T07:16:16.221269Z",
     "iopub.status.idle": "2025-04-22T07:16:26.833143Z",
     "shell.execute_reply": "2025-04-22T07:16:26.830166Z"
    },
    "papermill": {
     "duration": 10.62143,
     "end_time": "2025-04-22T07:16:26.835880",
     "exception": false,
     "start_time": "2025-04-22T07:16:16.214450",
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
       "\\553688 (73.8%)</td><td><span style=white-space:pre-wrap>&lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAF8AAADKCAQAAABp7lSOAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBYHEBO2XgtjAAABc0lEQVR42u3bQYrCQBRF0aRxdS6hFxh30OtyB3Fg01QkCPYgv17lXEfODlKBPCjndUruqxqAn9ul/XL7fRC+52rWu9qn9eXXv07Xat1HhR8efHz8yPDx8SPDr+yy/fpT7fmwuX177vo1/6837/tpbQ7PErG22qwtfPzI8PHxI8PHPyvfXKksnG9tdcRPCx8fPzJ8fPzI8Cuztiobib+s9/W+LkEXa0f69fPCx8ePDB8fP7Jwvqt4R2dt9ZK1hY8fGT4+fmT4+GflW1tHN9Da2rmKl3MRb5qmtflkrK1WHH548PHxI8PHx48Mv7KdtZX0wmxtVeaPTx3x08LHx48MHx8/MvzKzJXKwvnWVkf8tPDx8SPDx8ePDL8ya6uykfjPq3jVpH/z88LHx48MHx8/MvzK/PHp6KytXrK28PEjw8fHjwwf/6x8a+voBlpbu1fxOq85JC9nv/+LeNunM/zw4OPjR4aPjx8ZfmUjra28wg8PfmUPPABb6rm7Ea0AAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjJUMDc6MTY6MTkrMDA6MDAVMMXmAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIyVDA3OjE2OjE5KzAwOjAwZG19WgAAAABJRU5ErkJggg==\"&gt;                        </span></td><td>750000\\\n",
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
       "\\650479 (86.7%)</span></td><td><span style=white-space:pre-wrap>&lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAG0AAADKCAQAAAAF6AaLAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBYHEBO2XgtjAAABX0lEQVR42u3YwWnDQBRFUSm4unSQFOh0kPac7STglQPi/LlnZeHNXCSEn8/HMdXb1QcorbTVbb34ehzH53n1kV6xvjkG37XSRKWJShOVJipNVJqoNNG5Lhx6qh3Hsedeuz/ug/7g2uWuzVKaqDRRaaLSRKWJShM1RUW7pLWyEaWJShOVJipNVJqoNNHgtFa2aJe0VjaiNFFpotJEpYlKE5UmGpzWyhbtktbKRpQmKk1Umqg0UWmi0kSD01rZoqaoqDRRaaLSRKWJShOVJipN1MoWtbJFpYlKE5UmKk1Umqg00eC0pqhol7RWNqI0UWmi0kSliUoTlSYanNbKFu2S1spGlCYqTVSaqDRRaaLSRIPTWtmiXdJa2YjSRKWJShOVJipNVJpocForW3RbLwYM0eXBu/3+5v3qo/2jwQ9kaaLSRKWJShOVJipN9OeX//fV53nRx/L59CfaM4MfyNJEP0K2Ox7416vXAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDI1LTA0LTIyVDA3OjE2OjE5KzAwOjAwFTDF5gAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyNS0wNC0yMlQwNzoxNjoxOSswMDowMGRtfVoAAAAASUVORK5CYII=\"&gt;                                                    </span></td><td>750000\\\n",
       "(100.0%)</td><td><span style=white-space:pre-wrap>0\\\n",
       "(0.0%)      </span></td></tr>\n",
       "\t<tr><th scope=row>3</th><td> 3</td><td><span style=white-space:pre-wrap>Episode_Length_minutes\\\n",
       "[numeric]     </span></td><td><span style=white-space:pre-wrap>Mean (sd) : 64.5 (33)\\\n",
       "min &lt; med &lt; max:\\\n",
       "0 &lt; 63.8 &lt; 325.2\\\n",
       "IQR (CV) : 58.3 (0.5)                                                                                                                                        </span></td><td><span style=white-space:pre-wrap>12268 distinct values                                                                                                                                                                                                   </span></td><td><span style=white-space:pre-wrap>&lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBYHEBQoOp7AAAAA5klEQVR42u3cwQ2CMBhAYWuYzg10wLqBc7kB3kiJEpFiWt7/Hhe4NHwBSgKENJ5idG69A0KFbmsoN1LFQHl2sd9qhtqtcpeGzaO8dZnWHq2FH1qE9niE/gLt/Qj9WpjJSCitKmgen9PSGvKtlbeX3D1kJ2g5Ax9zNvYapSWUllBaQmkJpSWUllBaQmkJpSWUllBaQmmFgc6e1B//xcNKKO3lb1mYU1coLaG0hNISSksoLaG0hNISSksoLaG0hNISSksoLaG0hNISSksoLaG0wkBT+WnRHfad0bX4TUaC2RYLc+oKpfUCK5UeTY+BarAAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjJUMDc6MTY6MjArMDA6MDAOJ4fWAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIyVDA3OjE2OjIwKzAwOjAwf3o/agAAAABJRU5ErkJggg==\"&gt;                                                                                                                                                                                                                    </span></td><td>662907\\\n",
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
       "\\85059 (11.3%)                              </span></td><td><span style=white-space:pre-wrap>&lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAABoAAAC3CAQAAACmwYZ1AAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBYHEBVfPa5WAAAAy0lEQVRo3u2awQ2DMBAEfRHVpQQXSDqgLjpwHvmwxo4OiMiBZnhZ8kg+jgVbwkrazmOHc6I0LAev8mxOmlK2Ze3Ba0JCUgYdTi5JHnn7MvFwNGR5Y/ctk60rpdRLrhK8T0hIypWTm80haXL79QXvExKScuXkfljn1/XNrQneJyQk5bwQsltGQvqdFDy5Io1lrq52loPfciQkJfjGl+QiITUJnlznxleX4Tyyaq3B+4SEpNwjuTuOrDXB+4SEpJDcI8tDQvqXZDf8HeoNSZBWhwHfHEYAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjJUMDc6MTY6MjErMDA6MDCoUIxiAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIyVDA3OjE2OjIxKzAwOjAw2Q003gAAAABJRU5ErkJggg==\"&gt;                                                                                                                                                                                                                                                        </span></td><td>750000\\\n",
       "(100.0%)</td><td><span style=white-space:pre-wrap>0\\\n",
       "(0.0%)      </span></td></tr>\n",
       "\t<tr><th scope=row>5</th><td> 5</td><td>Host_Popularity_percentage\\\n",
       "[numeric] </td><td><span style=white-space:pre-wrap>Mean (sd) : 59.9 (22.9)\\\n",
       "min &lt; med &lt; max:\\\n",
       "1.3 &lt; 60 &lt; 119.5\\\n",
       "IQR (CV) : 40.1 (0.4)                                                                                                                                      </span></td><td><span style=white-space:pre-wrap>8038 distinct values                                                                                                                                                                                                    </span></td><td><span style=white-space:pre-wrap>&lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBYHEBbGNP/sAAABK0lEQVR42u3b0Q2CMABFUWqYjg10QNyAudgAPxCoSiNtKdDXe3+MJhAPlBajmqEqo9vZbwAo0LBq+4nx2LCdL+6Hz2aHZs8/dehOmvdjd7ZmY8UMXaBqAVWrGGjw8rI0rajjgtNFravpVucdoBNwO2Lpm5Nudd4B6ntIlrqqH8bH3/M3HZa9zmxCaNww3DpOLgC91k3ioUPXXev8/O8e3FlCm/hd/Il19KqFTnHZQD9vS/ynuGygsVdxAmg/rL9y7jJTzGQEVC3Pa7TN9hsM78ko/T1MmooZukDVAqoWULWAqgVULaBqAVULqFpA1QKqFlC1gKoFVC2gagFVC6haQNUCqhZQtYCqBVQtoGoBVQuoWsVAjf0j+We2v5hf7279qcuI2ZwVM3SBqvUCy9ktIuH0SSgAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjJUMDc6MTY6MjIrMDA6MDCZuJb/AAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIyVDA3OjE2OjIyKzAwOjAw6OUuQwAAAABJRU5ErkJggg==\"&gt;                                                                                                                        </span></td><td>750000\\\n",
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
       "\\107886 (14.4%)                                                                                </span></td><td><span style=white-space:pre-wrap>&lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAB4AAACCCAQAAAD7nbARAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBYHEBbGNP/sAAAArElEQVRYw+3Z2w2AIAwF0NYwnSN0QN2A9fDX+iiiNqZy+SPhJNCGG6Jc6P4YHtgPcVpP5jKaizMJr2sU9MzAwL446WluwuqK8QXw2pVU256qaSh8ionGmlYjaJ+BgX1xD0kibGA7Sfb1CNpnYGBf3EOSbLfX+CbRNQnaZ2BgX9xDkuBNAgzsjf+fJMImtpLkqBpB+wwM7Iv/nyREj764bisStM/AwL6YO/wLvACUmyhPC06I2AAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAyNS0wNC0yMlQwNzoxNjoyMiswMDowMJm4lv8AAAAldEVYdGRhdGU6bW9kaWZ5ADIwMjUtMDQtMjJUMDc6MTY6MjIrMDA6MDDo5S5DAAAAAElFTkSuQmCC\"&gt;                                                                                                                                                                                                                                                                                                    </span></td><td>750000\\\n",
       "(100.0%)</td><td><span style=white-space:pre-wrap>0\\\n",
       "(0.0%)      </span></td></tr>\n",
       "\t<tr><th scope=row>7</th><td> 7</td><td><span style=white-space:pre-wrap>Publication_Time\\\n",
       "[character]         </span></td><td><span style=white-space:pre-wrap>1\\. Afternoon\\\n",
       "2\\. Evening\\\n",
       "3\\. Morning\\\n",
       "4\\. Night                                                                                                                                                                  </span></td><td><span style=white-space:pre-wrap>\\179460 (23.9%)\\\n",
       "\\195778 (26.1%)\\\n",
       "\\177913 (23.7%)\\\n",
       "\\196849 (26.2%)                                                                                                                                            </span></td><td><span style=white-space:pre-wrap>&lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAACoAAABOCAQAAAD8r0ycAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBYHEBbGNP/sAAAAiklEQVRYw+3WSw6AIAxF0dawOpfAAnUHbk+HFHXEJ2nD7cxETvKEPNRbxs82wQyEJvtwNn3grCIidmmqX9j9xgcFBV0TfbXUNQRV24PaAVlnfvyj52o1MQc1f70XcY4UKCioe5TmL9PW/PkTsLv5/3YhzpECBQV1j9L8ZfjnBwUFXQOd3/yu48dBH/iKFxn/tftSAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDI1LTA0LTIyVDA3OjE2OjIyKzAwOjAwmbiW/wAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyNS0wNC0yMlQwNzoxNjoyMiswMDowMOjlLkMAAAAASUVORK5CYII=\"&gt;                                                                                                                                                                                                                                                                                                                                                </span></td><td>750000\\\n",
       "(100.0%)</td><td><span style=white-space:pre-wrap>0\\\n",
       "(0.0%)      </span></td></tr>\n",
       "\t<tr><th scope=row>8</th><td> 8</td><td>Guest_Popularity_percentage\\\n",
       "[numeric]</td><td><span style=white-space:pre-wrap>Mean (sd) : 52.2 (28.5)\\\n",
       "min &lt; med &lt; max:\\\n",
       "0 &lt; 53.6 &lt; 119.9\\\n",
       "IQR (CV) : 48.2 (0.5)                                                                                                                                      </span></td><td><span style=white-space:pre-wrap>10019 distinct values                                                                                                                                                                                                   </span></td><td><span style=white-space:pre-wrap>&lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBYHEBghjNLrAAABS0lEQVR42u2bwRGDIBBFIWN16SAp0HRgXenAHBgcRoMisot8/vPkRXmwu66M2tn0waP2AChK0TyG8MSK3GJcysBb5gZRwvozZF/lBE9jjDGTruWKbkK3G1GV0D1im8Xj7MO9VF7fQtRn8ZmpaFT0+lQ0LzoW6lFVRbeDPg7EUo8mVdF1+E3F1quqaIqEXivxV7RM0+bXr6xG7tgiK3q1xsmRO33sjFKp926iLLouKL55y0OuCp8UlV4/mQKWIXrnMrVPdjH6zu6oLSAu2hrdiCbmaEo1dGFcd2coUXRP5w4bXMVE29eJwxx16L0vVhaV61S06SZ0KYoGRdGgKBoURYOiaFAUDYqiQVE0KIoGRdGgKBoURYOiaFAUDYqiQVE0KIoGRdGgKBoURYOiaFAUDYqi0Y2oDT+x/sB8b+14Bb+VWTC3KN2ELkXR+AGM4D3GuUKOYwAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAyNS0wNC0yMlQwNzoxNjoyNCswMDowMPpoo8UAAAAldEVYdGRhdGU6bW9kaWZ5ADIwMjUtMDQtMjJUMDc6MTY6MjQrMDA6MDCLNRt5AAAAAElFTkSuQmCC\"&gt;                                                                                </span></td><td>603970\\\n",
       "(80.5%) </td><td>146030\\\n",
       "(19.5%)</td></tr>\n",
       "\t<tr><th scope=row>9</th><td> 9</td><td><span style=white-space:pre-wrap>Number_of_Ads\\\n",
       "[numeric]              </span></td><td><span style=white-space:pre-wrap>Mean (sd) : 1.3 (1.2)\\\n",
       "min &lt; med &lt; max:\\\n",
       "0 &lt; 1 &lt; 103.9\\\n",
       "IQR (CV) : 2 (0.9)                                                                                                                                              </span></td><td><span style=white-space:pre-wrap>12 distinct values                                                                                                                                                                                                      </span></td><td><span style=white-space:pre-wrap>&lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBYHEBghjNLrAAAAs0lEQVR42u3cwQnCQBBAUSOpzhIsUDuwPb0IrjmJCgs/711CyGU+7OY4y/2wD8fZAwgV+p11fLkOF/a8zB7td+P/Z33/dHo+b7Nn/LvdHF2hNUJrhNYIrRFaI7RGaI3QGqE1QmuE1gitEVojtEZojdAaoTVCa4TWCK0RWiO0RmiN0BqhNUJrhNYIrRFaI7RGaI3QGqE1QmuE1git2WzWeG3UuBT2/wxrUJZCzyd2c3SF1jwANQAJB63xoakAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjJUMDc6MTY6MjQrMDA6MDD6aKPFAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIyVDA3OjE2OjI0KzAwOjAwizUbeQAAAABJRU5ErkJggg==\"&gt;                                                                                                                                                                                                                                                                                        </span></td><td>749999\\\n",
       "(100.0%)</td><td><span style=white-space:pre-wrap>1\\\n",
       "(0.0%)      </span></td></tr>\n",
       "\t<tr><th scope=row>10</th><td>10</td><td><span style=white-space:pre-wrap>Episode_Sentiment\\\n",
       "[character]        </span></td><td><span style=white-space:pre-wrap>1\\. Negative\\\n",
       "2\\. Neutral\\\n",
       "3\\. Positive                                                                                                                                                                                </span></td><td><span style=white-space:pre-wrap>\\250116 (33.3%)\\\n",
       "\\251291 (33.5%)\\\n",
       "\\248593 (33.1%)                                                                                                                                                                </span></td><td><span style=white-space:pre-wrap>&lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAADIAAAA7CAQAAACTORHyAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBYHEBlWi+J9AAAAeElEQVRYw+3YsQ3AIAxEUTtiOjbIgskGrEdaQyoig4j1r6PxE1AcQqvMz7HACIQku7hrdhpb5NTFOwEBAQH5I5LaZZmCqK1f/TzmHTs36J1cjs0oNCMICAjIJgjNOJSuGR0nm7PvnkSO9WsS505AQEBAnKN82W6HPFCdD3vWiEuiAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDI1LTA0LTIyVDA3OjE2OjI1KzAwOjAwXB+ocQAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyNS0wNC0yMlQwNzoxNjoyNSswMDowMC1CEM0AAAAASUVORK5CYII=\"&gt;                                                                                                                                                                                                                                                                                                                                                                        </span></td><td>750000\\\n",
       "(100.0%)</td><td><span style=white-space:pre-wrap>0\\\n",
       "(0.0%)      </span></td></tr>\n",
       "\t<tr><th scope=row>11</th><td>11</td><td><span style=white-space:pre-wrap>Listening_Time_minutes\\\n",
       "[numeric]     </span></td><td><span style=white-space:pre-wrap>Mean (sd) : 45.4 (27.1)\\\n",
       "min &lt; med &lt; max:\\\n",
       "0 &lt; 43.4 &lt; 120\\\n",
       "IQR (CV) : 41.6 (0.6)                                                                                                                                        </span></td><td><span style=white-space:pre-wrap>42807 distinct values                                                                                                                                                                                                   </span></td><td>&lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBYHEBrPgrPHAAABhUlEQVR42u2b0XGDMBBEhccFuC46cAokHbguOiAfCaAgMCAk393evj+PB8aPW4mTwM0QfHCT/gEUpWge9/hDk3GCbhrkXzmHVyWef+7ZZ5loQwghvKStdjgp+q5+3WIC11Xhg6KzRLuhNVe2TY4dv5FUP1zRZUBHne3Idqpu0QXG6Bb7lwJENGWssUSEd0TLxq+9fopaorridwWfndGIrvmyoqjsaPqoaF0k+mMRUYkpzs1kRFE0KIqGsGg/9EM/fKJBYUXRoCgabkRFet2U/m/efVRr8t1UlKJo/BujiFsoq6JWHhjl4Ca6FJXhdzVTYz2jTLQeFEWDomi4EVWyTEsp/XRcrWjpZtRNdCmqhVItoXrRUlAUDTeiau+jS642EGZEr74Q5Ca6FEWDomiYE83dEDUnmgtF0aAoGmZ63ZRzbb5h0XP7hIyuHY5FGED02EqV0bXH+wgDic7/VV5TZXQtMy3hospCiq61Em6i60a0iXckvsHe7nxGY7QBc9vETXQpisYP9XNcCznJq+YAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjJUMDc6MTY6MjYrMDA6MDBt97LsAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIyVDA3OjE2OjI2KzAwOjAwHKoKUAAAAABJRU5ErkJggg==\"&gt;</td><td>750000\\\n",
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
       "\\textbackslash{}553688 (73.8\\%) & <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAF8AAADKCAQAAABp7lSOAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBYHEBO2XgtjAAABc0lEQVR42u3bQYrCQBRF0aRxdS6hFxh30OtyB3Fg01QkCPYgv17lXEfODlKBPCjndUruqxqAn9ul/XL7fRC+52rWu9qn9eXXv07Xat1HhR8efHz8yPDx8SPDr+yy/fpT7fmwuX177vo1/6837/tpbQ7PErG22qwtfPzI8PHxI8PHPyvfXKksnG9tdcRPCx8fPzJ8fPzI8Cuztiobib+s9/W+LkEXa0f69fPCx8ePDB8fP7Jwvqt4R2dt9ZK1hY8fGT4+fmT4+GflW1tHN9Da2rmKl3MRb5qmtflkrK1WHH548PHxI8PHx48Mv7KdtZX0wmxtVeaPTx3x08LHx48MHx8/MvzKzJXKwvnWVkf8tPDx8SPDx8ePDL8ya6uykfjPq3jVpH/z88LHx48MHx8/MvzK/PHp6KytXrK28PEjw8fHjwwf/6x8a+voBlpbu1fxOq85JC9nv/+LeNunM/zw4OPjR4aPjx8ZfmUjra28wg8PfmUPPABb6rm7Ea0AAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjJUMDc6MTY6MTkrMDA6MDAVMMXmAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIyVDA3OjE2OjE5KzAwOjAwZG19WgAAAABJRU5ErkJggg==\">                         & 750000\\textbackslash{}\n",
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
       "\\textbackslash{}650479 (86.7\\%) & <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAG0AAADKCAQAAAAF6AaLAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBYHEBO2XgtjAAABX0lEQVR42u3YwWnDQBRFUSm4unSQFOh0kPac7STglQPi/LlnZeHNXCSEn8/HMdXb1QcorbTVbb34ehzH53n1kV6xvjkG37XSRKWJShOVJipNVJqoNNG5Lhx6qh3Hsedeuz/ug/7g2uWuzVKaqDRRaaLSRKWJShM1RUW7pLWyEaWJShOVJipNVJqoNNHgtFa2aJe0VjaiNFFpotJEpYlKE5UmGpzWyhbtktbKRpQmKk1Umqg0UWmi0kSD01rZoqaoqDRRaaLSRKWJShOVJipN1MoWtbJFpYlKE5UmKk1Umqg00eC0pqhol7RWNqI0UWmi0kSliUoTlSYanNbKFu2S1spGlCYqTVSaqDRRaaLSRIPTWtmiXdJa2YjSRKWJShOVJipNVJpocForW3RbLwYM0eXBu/3+5v3qo/2jwQ9kaaLSRKWJShOVJipN9OeX//fV53nRx/L59CfaM4MfyNJEP0K2Ox7416vXAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDI1LTA0LTIyVDA3OjE2OjE5KzAwOjAwFTDF5gAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyNS0wNC0yMlQwNzoxNjoxOSswMDowMGRtfVoAAAAASUVORK5CYII=\">                                                     & 750000\\textbackslash{}\n",
       "(100.0\\%) & 0\\textbackslash{}\n",
       "(0.0\\%)      \\\\\n",
       "\t3 &  3 & Episode\\_Length\\_minutes\\textbackslash{}\n",
       "{[}numeric{]}      & Mean (sd) : 64.5 (33)\\textbackslash{}\n",
       "min < med < max:\\textbackslash{}\n",
       "0 < 63.8 < 325.2\\textbackslash{}\n",
       "IQR (CV) : 58.3 (0.5)                                                                                                                                         & 12268 distinct values                                                                                                                                                                                                    & <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBYHEBQoOp7AAAAA5klEQVR42u3cwQ2CMBhAYWuYzg10wLqBc7kB3kiJEpFiWt7/Hhe4NHwBSgKENJ5idG69A0KFbmsoN1LFQHl2sd9qhtqtcpeGzaO8dZnWHq2FH1qE9niE/gLt/Qj9WpjJSCitKmgen9PSGvKtlbeX3D1kJ2g5Ax9zNvYapSWUllBaQmkJpSWUllBaQmkJpSWUllBaQmmFgc6e1B//xcNKKO3lb1mYU1coLaG0hNISSksoLaG0hNISSksoLaG0hNISSksoLaG0hNISSksoLaG0wkBT+WnRHfad0bX4TUaC2RYLc+oKpfUCK5UeTY+BarAAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjJUMDc6MTY6MjArMDA6MDAOJ4fWAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIyVDA3OjE2OjIwKzAwOjAwf3o/agAAAABJRU5ErkJggg==\">                                                                                                                                                                                                                     & 662907\\textbackslash{}\n",
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
       "\\textbackslash{}85059 (11.3\\%)                               & <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAABoAAAC3CAQAAACmwYZ1AAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBYHEBVfPa5WAAAAy0lEQVRo3u2awQ2DMBAEfRHVpQQXSDqgLjpwHvmwxo4OiMiBZnhZ8kg+jgVbwkrazmOHc6I0LAev8mxOmlK2Ze3Ba0JCUgYdTi5JHnn7MvFwNGR5Y/ctk60rpdRLrhK8T0hIypWTm80haXL79QXvExKScuXkfljn1/XNrQneJyQk5bwQsltGQvqdFDy5Io1lrq52loPfciQkJfjGl+QiITUJnlznxleX4Tyyaq3B+4SEpNwjuTuOrDXB+4SEpJDcI8tDQvqXZDf8HeoNSZBWhwHfHEYAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjJUMDc6MTY6MjErMDA6MDCoUIxiAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIyVDA3OjE2OjIxKzAwOjAw2Q003gAAAABJRU5ErkJggg==\">                                                                                                                                                                                                                                                         & 750000\\textbackslash{}\n",
       "(100.0\\%) & 0\\textbackslash{}\n",
       "(0.0\\%)      \\\\\n",
       "\t5 &  5 & Host\\_Popularity\\_percentage\\textbackslash{}\n",
       "{[}numeric{]}  & Mean (sd) : 59.9 (22.9)\\textbackslash{}\n",
       "min < med < max:\\textbackslash{}\n",
       "1.3 < 60 < 119.5\\textbackslash{}\n",
       "IQR (CV) : 40.1 (0.4)                                                                                                                                       & 8038 distinct values                                                                                                                                                                                                     & <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBYHEBbGNP/sAAABK0lEQVR42u3b0Q2CMABFUWqYjg10QNyAudgAPxCoSiNtKdDXe3+MJhAPlBajmqEqo9vZbwAo0LBq+4nx2LCdL+6Hz2aHZs8/dehOmvdjd7ZmY8UMXaBqAVWrGGjw8rI0rajjgtNFravpVucdoBNwO2Lpm5Nudd4B6ntIlrqqH8bH3/M3HZa9zmxCaNww3DpOLgC91k3ioUPXXev8/O8e3FlCm/hd/Il19KqFTnHZQD9vS/ynuGygsVdxAmg/rL9y7jJTzGQEVC3Pa7TN9hsM78ko/T1MmooZukDVAqoWULWAqgVULaBqAVULqFpA1QKqFlC1gKoFVC2gagFVC6haQNUCqhZQtYCqBVQtoGoBVQuoWsVAjf0j+We2v5hf7279qcuI2ZwVM3SBqvUCy9ktIuH0SSgAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjJUMDc6MTY6MjIrMDA6MDCZuJb/AAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIyVDA3OjE2OjIyKzAwOjAw6OUuQwAAAABJRU5ErkJggg==\">                                                                                                                         & 750000\\textbackslash{}\n",
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
       "\\textbackslash{}107886 (14.4\\%)                                                                                 & <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAB4AAACCCAQAAAD7nbARAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBYHEBbGNP/sAAAArElEQVRYw+3Z2w2AIAwF0NYwnSN0QN2A9fDX+iiiNqZy+SPhJNCGG6Jc6P4YHtgPcVpP5jKaizMJr2sU9MzAwL446WluwuqK8QXw2pVU256qaSh8ionGmlYjaJ+BgX1xD0kibGA7Sfb1CNpnYGBf3EOSbLfX+CbRNQnaZ2BgX9xDkuBNAgzsjf+fJMImtpLkqBpB+wwM7Iv/nyREj764bisStM/AwL6YO/wLvACUmyhPC06I2AAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAyNS0wNC0yMlQwNzoxNjoyMiswMDowMJm4lv8AAAAldEVYdGRhdGU6bW9kaWZ5ADIwMjUtMDQtMjJUMDc6MTY6MjIrMDA6MDDo5S5DAAAAAElFTkSuQmCC\">                                                                                                                                                                                                                                                                                                     & 750000\\textbackslash{}\n",
       "(100.0\\%) & 0\\textbackslash{}\n",
       "(0.0\\%)      \\\\\n",
       "\t7 &  7 & Publication\\_Time\\textbackslash{}\n",
       "{[}character{]}          & 1\\textbackslash{}. Afternoon\\textbackslash{}\n",
       "2\\textbackslash{}. Evening\\textbackslash{}\n",
       "3\\textbackslash{}. Morning\\textbackslash{}\n",
       "4\\textbackslash{}. Night                                                                                                                                                                   & \\textbackslash{}179460 (23.9\\%)\\textbackslash{}\n",
       "\\textbackslash{}195778 (26.1\\%)\\textbackslash{}\n",
       "\\textbackslash{}177913 (23.7\\%)\\textbackslash{}\n",
       "\\textbackslash{}196849 (26.2\\%)                                                                                                                                             & <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAACoAAABOCAQAAAD8r0ycAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBYHEBbGNP/sAAAAiklEQVRYw+3WSw6AIAxF0dawOpfAAnUHbk+HFHXEJ2nD7cxETvKEPNRbxs82wQyEJvtwNn3grCIidmmqX9j9xgcFBV0TfbXUNQRV24PaAVlnfvyj52o1MQc1f70XcY4UKCioe5TmL9PW/PkTsLv5/3YhzpECBQV1j9L8ZfjnBwUFXQOd3/yu48dBH/iKFxn/tftSAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDI1LTA0LTIyVDA3OjE2OjIyKzAwOjAwmbiW/wAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyNS0wNC0yMlQwNzoxNjoyMiswMDowMOjlLkMAAAAASUVORK5CYII=\">                                                                                                                                                                                                                                                                                                                                                 & 750000\\textbackslash{}\n",
       "(100.0\\%) & 0\\textbackslash{}\n",
       "(0.0\\%)      \\\\\n",
       "\t8 &  8 & Guest\\_Popularity\\_percentage\\textbackslash{}\n",
       "{[}numeric{]} & Mean (sd) : 52.2 (28.5)\\textbackslash{}\n",
       "min < med < max:\\textbackslash{}\n",
       "0 < 53.6 < 119.9\\textbackslash{}\n",
       "IQR (CV) : 48.2 (0.5)                                                                                                                                       & 10019 distinct values                                                                                                                                                                                                    & <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBYHEBghjNLrAAABS0lEQVR42u2bwRGDIBBFIWN16SAp0HRgXenAHBgcRoMisot8/vPkRXmwu66M2tn0waP2AChK0TyG8MSK3GJcysBb5gZRwvozZF/lBE9jjDGTruWKbkK3G1GV0D1im8Xj7MO9VF7fQtRn8ZmpaFT0+lQ0LzoW6lFVRbeDPg7EUo8mVdF1+E3F1quqaIqEXivxV7RM0+bXr6xG7tgiK3q1xsmRO33sjFKp926iLLouKL55y0OuCp8UlV4/mQKWIXrnMrVPdjH6zu6oLSAu2hrdiCbmaEo1dGFcd2coUXRP5w4bXMVE29eJwxx16L0vVhaV61S06SZ0KYoGRdGgKBoURYOiaFAUDYqiQVE0KIoGRdGgKBoURYOiaFAUDYqiQVE0KIoGRdGgKBoURYOiaFAUDYqi0Y2oDT+x/sB8b+14Bb+VWTC3KN2ELkXR+AGM4D3GuUKOYwAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAyNS0wNC0yMlQwNzoxNjoyNCswMDowMPpoo8UAAAAldEVYdGRhdGU6bW9kaWZ5ADIwMjUtMDQtMjJUMDc6MTY6MjQrMDA6MDCLNRt5AAAAAElFTkSuQmCC\">                                                                                 & 603970\\textbackslash{}\n",
       "(80.5\\%)  & 146030\\textbackslash{}\n",
       "(19.5\\%)\\\\\n",
       "\t9 &  9 & Number\\_of\\_Ads\\textbackslash{}\n",
       "{[}numeric{]}               & Mean (sd) : 1.3 (1.2)\\textbackslash{}\n",
       "min < med < max:\\textbackslash{}\n",
       "0 < 1 < 103.9\\textbackslash{}\n",
       "IQR (CV) : 2 (0.9)                                                                                                                                               & 12 distinct values                                                                                                                                                                                                       & <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBYHEBghjNLrAAAAs0lEQVR42u3cwQnCQBBAUSOpzhIsUDuwPb0IrjmJCgs/711CyGU+7OY4y/2wD8fZAwgV+p11fLkOF/a8zB7td+P/Z33/dHo+b7Nn/LvdHF2hNUJrhNYIrRFaI7RGaI3QGqE1QmuE1gitEVojtEZojdAaoTVCa4TWCK0RWiO0RmiN0BqhNUJrhNYIrRFaI7RGaI3QGqE1QmuE1git2WzWeG3UuBT2/wxrUJZCzyd2c3SF1jwANQAJB63xoakAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjJUMDc6MTY6MjQrMDA6MDD6aKPFAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIyVDA3OjE2OjI0KzAwOjAwizUbeQAAAABJRU5ErkJggg==\">                                                                                                                                                                                                                                                                                         & 749999\\textbackslash{}\n",
       "(100.0\\%) & 1\\textbackslash{}\n",
       "(0.0\\%)      \\\\\n",
       "\t10 & 10 & Episode\\_Sentiment\\textbackslash{}\n",
       "{[}character{]}         & 1\\textbackslash{}. Negative\\textbackslash{}\n",
       "2\\textbackslash{}. Neutral\\textbackslash{}\n",
       "3\\textbackslash{}. Positive                                                                                                                                                                                 & \\textbackslash{}250116 (33.3\\%)\\textbackslash{}\n",
       "\\textbackslash{}251291 (33.5\\%)\\textbackslash{}\n",
       "\\textbackslash{}248593 (33.1\\%)                                                                                                                                                                 & <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAADIAAAA7CAQAAACTORHyAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBYHEBlWi+J9AAAAeElEQVRYw+3YsQ3AIAxEUTtiOjbIgskGrEdaQyoig4j1r6PxE1AcQqvMz7HACIQku7hrdhpb5NTFOwEBAQH5I5LaZZmCqK1f/TzmHTs36J1cjs0oNCMICAjIJgjNOJSuGR0nm7PvnkSO9WsS505AQEBAnKN82W6HPFCdD3vWiEuiAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDI1LTA0LTIyVDA3OjE2OjI1KzAwOjAwXB+ocQAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyNS0wNC0yMlQwNzoxNjoyNSswMDowMC1CEM0AAAAASUVORK5CYII=\">                                                                                                                                                                                                                                                                                                                                                                         & 750000\\textbackslash{}\n",
       "(100.0\\%) & 0\\textbackslash{}\n",
       "(0.0\\%)      \\\\\n",
       "\t11 & 11 & Listening\\_Time\\_minutes\\textbackslash{}\n",
       "{[}numeric{]}      & Mean (sd) : 45.4 (27.1)\\textbackslash{}\n",
       "min < med < max:\\textbackslash{}\n",
       "0 < 43.4 < 120\\textbackslash{}\n",
       "IQR (CV) : 41.6 (0.6)                                                                                                                                         & 42807 distinct values                                                                                                                                                                                                    & <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBYHEBrPgrPHAAABhUlEQVR42u2b0XGDMBBEhccFuC46cAokHbguOiAfCaAgMCAk393evj+PB8aPW4mTwM0QfHCT/gEUpWge9/hDk3GCbhrkXzmHVyWef+7ZZ5loQwghvKStdjgp+q5+3WIC11Xhg6KzRLuhNVe2TY4dv5FUP1zRZUBHne3Idqpu0QXG6Bb7lwJENGWssUSEd0TLxq+9fopaorridwWfndGIrvmyoqjsaPqoaF0k+mMRUYkpzs1kRFE0KIqGsGg/9EM/fKJBYUXRoCgabkRFet2U/m/efVRr8t1UlKJo/BujiFsoq6JWHhjl4Ca6FJXhdzVTYz2jTLQeFEWDomi4EVWyTEsp/XRcrWjpZtRNdCmqhVItoXrRUlAUDTeiau+jS642EGZEr74Q5Ca6FEWDomiYE83dEDUnmgtF0aAoGmZ63ZRzbb5h0XP7hIyuHY5FGED02EqV0bXH+wgDic7/VV5TZXQtMy3hospCiq61Em6i60a0iXckvsHe7nxGY7QBc9vETXQpisYP9XNcCznJq+YAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjJUMDc6MTY6MjYrMDA6MDBt97LsAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIyVDA3OjE2OjI2KzAwOjAwHKoKUAAAAABJRU5ErkJggg==\"> & 750000\\textbackslash{}\n",
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
       "\\553688 (73.8%) | &lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAF8AAADKCAQAAABp7lSOAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBYHEBO2XgtjAAABc0lEQVR42u3bQYrCQBRF0aRxdS6hFxh30OtyB3Fg01QkCPYgv17lXEfODlKBPCjndUruqxqAn9ul/XL7fRC+52rWu9qn9eXXv07Xat1HhR8efHz8yPDx8SPDr+yy/fpT7fmwuX177vo1/6837/tpbQ7PErG22qwtfPzI8PHxI8PHPyvfXKksnG9tdcRPCx8fPzJ8fPzI8Cuztiobib+s9/W+LkEXa0f69fPCx8ePDB8fP7Jwvqt4R2dt9ZK1hY8fGT4+fmT4+GflW1tHN9Da2rmKl3MRb5qmtflkrK1WHH548PHxI8PHx48Mv7KdtZX0wmxtVeaPTx3x08LHx48MHx8/MvzKzJXKwvnWVkf8tPDx8SPDx8ePDL8ya6uykfjPq3jVpH/z88LHx48MHx8/MvzK/PHp6KytXrK28PEjw8fHjwwf/6x8a+voBlpbu1fxOq85JC9nv/+LeNunM/zw4OPjR4aPjx8ZfmUjra28wg8PfmUPPABb6rm7Ea0AAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjJUMDc6MTY6MTkrMDA6MDAVMMXmAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIyVDA3OjE2OjE5KzAwOjAwZG19WgAAAABJRU5ErkJggg==\"&gt;                         | 750000\\\n",
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
       "\\650479 (86.7%) | &lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAG0AAADKCAQAAAAF6AaLAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBYHEBO2XgtjAAABX0lEQVR42u3YwWnDQBRFUSm4unSQFOh0kPac7STglQPi/LlnZeHNXCSEn8/HMdXb1QcorbTVbb34ehzH53n1kV6xvjkG37XSRKWJShOVJipNVJqoNNG5Lhx6qh3Hsedeuz/ug/7g2uWuzVKaqDRRaaLSRKWJShM1RUW7pLWyEaWJShOVJipNVJqoNNHgtFa2aJe0VjaiNFFpotJEpYlKE5UmGpzWyhbtktbKRpQmKk1Umqg0UWmi0kSD01rZoqaoqDRRaaLSRKWJShOVJipN1MoWtbJFpYlKE5UmKk1Umqg00eC0pqhol7RWNqI0UWmi0kSliUoTlSYanNbKFu2S1spGlCYqTVSaqDRRaaLSRIPTWtmiXdJa2YjSRKWJShOVJipNVJpocForW3RbLwYM0eXBu/3+5v3qo/2jwQ9kaaLSRKWJShOVJipN9OeX//fV53nRx/L59CfaM4MfyNJEP0K2Ox7416vXAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDI1LTA0LTIyVDA3OjE2OjE5KzAwOjAwFTDF5gAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyNS0wNC0yMlQwNzoxNjoxOSswMDowMGRtfVoAAAAASUVORK5CYII=\"&gt;                                                     | 750000\\\n",
       "(100.0%) | 0\\\n",
       "(0.0%)       |\n",
       "| 3 |  3 | Episode_Length_minutes\\\n",
       "[numeric]      | Mean (sd) : 64.5 (33)\\\n",
       "min &lt; med &lt; max:\\\n",
       "0 &lt; 63.8 &lt; 325.2\\\n",
       "IQR (CV) : 58.3 (0.5)                                                                                                                                         | 12268 distinct values                                                                                                                                                                                                    | &lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBYHEBQoOp7AAAAA5klEQVR42u3cwQ2CMBhAYWuYzg10wLqBc7kB3kiJEpFiWt7/Hhe4NHwBSgKENJ5idG69A0KFbmsoN1LFQHl2sd9qhtqtcpeGzaO8dZnWHq2FH1qE9niE/gLt/Qj9WpjJSCitKmgen9PSGvKtlbeX3D1kJ2g5Ax9zNvYapSWUllBaQmkJpSWUllBaQmkJpSWUllBaQmmFgc6e1B//xcNKKO3lb1mYU1coLaG0hNISSksoLaG0hNISSksoLaG0hNISSksoLaG0hNISSksoLaG0wkBT+WnRHfad0bX4TUaC2RYLc+oKpfUCK5UeTY+BarAAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjJUMDc6MTY6MjArMDA6MDAOJ4fWAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIyVDA3OjE2OjIwKzAwOjAwf3o/agAAAABJRU5ErkJggg==\"&gt;                                                                                                                                                                                                                     | 662907\\\n",
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
       "\\85059 (11.3%)                               | &lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAABoAAAC3CAQAAACmwYZ1AAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBYHEBVfPa5WAAAAy0lEQVRo3u2awQ2DMBAEfRHVpQQXSDqgLjpwHvmwxo4OiMiBZnhZ8kg+jgVbwkrazmOHc6I0LAev8mxOmlK2Ze3Ba0JCUgYdTi5JHnn7MvFwNGR5Y/ctk60rpdRLrhK8T0hIypWTm80haXL79QXvExKScuXkfljn1/XNrQneJyQk5bwQsltGQvqdFDy5Io1lrq52loPfciQkJfjGl+QiITUJnlznxleX4Tyyaq3B+4SEpNwjuTuOrDXB+4SEpJDcI8tDQvqXZDf8HeoNSZBWhwHfHEYAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjJUMDc6MTY6MjErMDA6MDCoUIxiAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIyVDA3OjE2OjIxKzAwOjAw2Q003gAAAABJRU5ErkJggg==\"&gt;                                                                                                                                                                                                                                                         | 750000\\\n",
       "(100.0%) | 0\\\n",
       "(0.0%)       |\n",
       "| 5 |  5 | Host_Popularity_percentage\\\n",
       "[numeric]  | Mean (sd) : 59.9 (22.9)\\\n",
       "min &lt; med &lt; max:\\\n",
       "1.3 &lt; 60 &lt; 119.5\\\n",
       "IQR (CV) : 40.1 (0.4)                                                                                                                                       | 8038 distinct values                                                                                                                                                                                                     | &lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBYHEBbGNP/sAAABK0lEQVR42u3b0Q2CMABFUWqYjg10QNyAudgAPxCoSiNtKdDXe3+MJhAPlBajmqEqo9vZbwAo0LBq+4nx2LCdL+6Hz2aHZs8/dehOmvdjd7ZmY8UMXaBqAVWrGGjw8rI0rajjgtNFravpVucdoBNwO2Lpm5Nudd4B6ntIlrqqH8bH3/M3HZa9zmxCaNww3DpOLgC91k3ioUPXXev8/O8e3FlCm/hd/Il19KqFTnHZQD9vS/ynuGygsVdxAmg/rL9y7jJTzGQEVC3Pa7TN9hsM78ko/T1MmooZukDVAqoWULWAqgVULaBqAVULqFpA1QKqFlC1gKoFVC2gagFVC6haQNUCqhZQtYCqBVQtoGoBVQuoWsVAjf0j+We2v5hf7279qcuI2ZwVM3SBqvUCy9ktIuH0SSgAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjJUMDc6MTY6MjIrMDA6MDCZuJb/AAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIyVDA3OjE2OjIyKzAwOjAw6OUuQwAAAABJRU5ErkJggg==\"&gt;                                                                                                                         | 750000\\\n",
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
       "\\107886 (14.4%)                                                                                 | &lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAB4AAACCCAQAAAD7nbARAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBYHEBbGNP/sAAAArElEQVRYw+3Z2w2AIAwF0NYwnSN0QN2A9fDX+iiiNqZy+SPhJNCGG6Jc6P4YHtgPcVpP5jKaizMJr2sU9MzAwL446WluwuqK8QXw2pVU256qaSh8ionGmlYjaJ+BgX1xD0kibGA7Sfb1CNpnYGBf3EOSbLfX+CbRNQnaZ2BgX9xDkuBNAgzsjf+fJMImtpLkqBpB+wwM7Iv/nyREj764bisStM/AwL6YO/wLvACUmyhPC06I2AAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAyNS0wNC0yMlQwNzoxNjoyMiswMDowMJm4lv8AAAAldEVYdGRhdGU6bW9kaWZ5ADIwMjUtMDQtMjJUMDc6MTY6MjIrMDA6MDDo5S5DAAAAAElFTkSuQmCC\"&gt;                                                                                                                                                                                                                                                                                                     | 750000\\\n",
       "(100.0%) | 0\\\n",
       "(0.0%)       |\n",
       "| 7 |  7 | Publication_Time\\\n",
       "[character]          | 1\\. Afternoon\\\n",
       "2\\. Evening\\\n",
       "3\\. Morning\\\n",
       "4\\. Night                                                                                                                                                                   | \\179460 (23.9%)\\\n",
       "\\195778 (26.1%)\\\n",
       "\\177913 (23.7%)\\\n",
       "\\196849 (26.2%)                                                                                                                                             | &lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAACoAAABOCAQAAAD8r0ycAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBYHEBbGNP/sAAAAiklEQVRYw+3WSw6AIAxF0dawOpfAAnUHbk+HFHXEJ2nD7cxETvKEPNRbxs82wQyEJvtwNn3grCIidmmqX9j9xgcFBV0TfbXUNQRV24PaAVlnfvyj52o1MQc1f70XcY4UKCioe5TmL9PW/PkTsLv5/3YhzpECBQV1j9L8ZfjnBwUFXQOd3/yu48dBH/iKFxn/tftSAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDI1LTA0LTIyVDA3OjE2OjIyKzAwOjAwmbiW/wAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyNS0wNC0yMlQwNzoxNjoyMiswMDowMOjlLkMAAAAASUVORK5CYII=\"&gt;                                                                                                                                                                                                                                                                                                                                                 | 750000\\\n",
       "(100.0%) | 0\\\n",
       "(0.0%)       |\n",
       "| 8 |  8 | Guest_Popularity_percentage\\\n",
       "[numeric] | Mean (sd) : 52.2 (28.5)\\\n",
       "min &lt; med &lt; max:\\\n",
       "0 &lt; 53.6 &lt; 119.9\\\n",
       "IQR (CV) : 48.2 (0.5)                                                                                                                                       | 10019 distinct values                                                                                                                                                                                                    | &lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBYHEBghjNLrAAABS0lEQVR42u2bwRGDIBBFIWN16SAp0HRgXenAHBgcRoMisot8/vPkRXmwu66M2tn0waP2AChK0TyG8MSK3GJcysBb5gZRwvozZF/lBE9jjDGTruWKbkK3G1GV0D1im8Xj7MO9VF7fQtRn8ZmpaFT0+lQ0LzoW6lFVRbeDPg7EUo8mVdF1+E3F1quqaIqEXivxV7RM0+bXr6xG7tgiK3q1xsmRO33sjFKp926iLLouKL55y0OuCp8UlV4/mQKWIXrnMrVPdjH6zu6oLSAu2hrdiCbmaEo1dGFcd2coUXRP5w4bXMVE29eJwxx16L0vVhaV61S06SZ0KYoGRdGgKBoURYOiaFAUDYqiQVE0KIoGRdGgKBoURYOiaFAUDYqiQVE0KIoGRdGgKBoURYOiaFAUDYqi0Y2oDT+x/sB8b+14Bb+VWTC3KN2ELkXR+AGM4D3GuUKOYwAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAyNS0wNC0yMlQwNzoxNjoyNCswMDowMPpoo8UAAAAldEVYdGRhdGU6bW9kaWZ5ADIwMjUtMDQtMjJUMDc6MTY6MjQrMDA6MDCLNRt5AAAAAElFTkSuQmCC\"&gt;                                                                                 | 603970\\\n",
       "(80.5%)  | 146030\\\n",
       "(19.5%) |\n",
       "| 9 |  9 | Number_of_Ads\\\n",
       "[numeric]               | Mean (sd) : 1.3 (1.2)\\\n",
       "min &lt; med &lt; max:\\\n",
       "0 &lt; 1 &lt; 103.9\\\n",
       "IQR (CV) : 2 (0.9)                                                                                                                                               | 12 distinct values                                                                                                                                                                                                       | &lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBYHEBghjNLrAAAAs0lEQVR42u3cwQnCQBBAUSOpzhIsUDuwPb0IrjmJCgs/711CyGU+7OY4y/2wD8fZAwgV+p11fLkOF/a8zB7td+P/Z33/dHo+b7Nn/LvdHF2hNUJrhNYIrRFaI7RGaI3QGqE1QmuE1gitEVojtEZojdAaoTVCa4TWCK0RWiO0RmiN0BqhNUJrhNYIrRFaI7RGaI3QGqE1QmuE1git2WzWeG3UuBT2/wxrUJZCzyd2c3SF1jwANQAJB63xoakAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjJUMDc6MTY6MjQrMDA6MDD6aKPFAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIyVDA3OjE2OjI0KzAwOjAwizUbeQAAAABJRU5ErkJggg==\"&gt;                                                                                                                                                                                                                                                                                         | 749999\\\n",
       "(100.0%) | 1\\\n",
       "(0.0%)       |\n",
       "| 10 | 10 | Episode_Sentiment\\\n",
       "[character]         | 1\\. Negative\\\n",
       "2\\. Neutral\\\n",
       "3\\. Positive                                                                                                                                                                                 | \\250116 (33.3%)\\\n",
       "\\251291 (33.5%)\\\n",
       "\\248593 (33.1%)                                                                                                                                                                 | &lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAADIAAAA7CAQAAACTORHyAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBYHEBlWi+J9AAAAeElEQVRYw+3YsQ3AIAxEUTtiOjbIgskGrEdaQyoig4j1r6PxE1AcQqvMz7HACIQku7hrdhpb5NTFOwEBAQH5I5LaZZmCqK1f/TzmHTs36J1cjs0oNCMICAjIJgjNOJSuGR0nm7PvnkSO9WsS505AQEBAnKN82W6HPFCdD3vWiEuiAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDI1LTA0LTIyVDA3OjE2OjI1KzAwOjAwXB+ocQAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyNS0wNC0yMlQwNzoxNjoyNSswMDowMC1CEM0AAAAASUVORK5CYII=\"&gt;                                                                                                                                                                                                                                                                                                                                                                         | 750000\\\n",
       "(100.0%) | 0\\\n",
       "(0.0%)       |\n",
       "| 11 | 11 | Listening_Time_minutes\\\n",
       "[numeric]      | Mean (sd) : 45.4 (27.1)\\\n",
       "min &lt; med &lt; max:\\\n",
       "0 &lt; 43.4 &lt; 120\\\n",
       "IQR (CV) : 41.6 (0.6)                                                                                                                                         | 42807 distinct values                                                                                                                                                                                                    | &lt;img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBYHEBrPgrPHAAABhUlEQVR42u2b0XGDMBBEhccFuC46cAokHbguOiAfCaAgMCAk393evj+PB8aPW4mTwM0QfHCT/gEUpWge9/hDk3GCbhrkXzmHVyWef+7ZZ5loQwghvKStdjgp+q5+3WIC11Xhg6KzRLuhNVe2TY4dv5FUP1zRZUBHne3Idqpu0QXG6Bb7lwJENGWssUSEd0TLxq+9fopaorridwWfndGIrvmyoqjsaPqoaF0k+mMRUYkpzs1kRFE0KIqGsGg/9EM/fKJBYUXRoCgabkRFet2U/m/efVRr8t1UlKJo/BujiFsoq6JWHhjl4Ca6FJXhdzVTYz2jTLQeFEWDomi4EVWyTEsp/XRcrWjpZtRNdCmqhVItoXrRUlAUDTeiau+jS642EGZEr74Q5Ca6FEWDomiYE83dEDUnmgtF0aAoGmZ63ZRzbb5h0XP7hIyuHY5FGED02EqV0bXH+wgDic7/VV5TZXQtMy3hospCiq61Em6i60a0iXckvsHe7nxGY7QBc9vETXQpisYP9XNcCznJq+YAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjJUMDc6MTY6MjYrMDA6MDBt97LsAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIyVDA3OjE2OjI2KzAwOjAwHKoKUAAAAABJRU5ErkJggg==\"&gt; | 750000\\\n",
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
       "1  <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAF8AAADKCAQAAABp7lSOAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBYHEBO2XgtjAAABc0lEQVR42u3bQYrCQBRF0aRxdS6hFxh30OtyB3Fg01QkCPYgv17lXEfODlKBPCjndUruqxqAn9ul/XL7fRC+52rWu9qn9eXXv07Xat1HhR8efHz8yPDx8SPDr+yy/fpT7fmwuX177vo1/6837/tpbQ7PErG22qwtfPzI8PHxI8PHPyvfXKksnG9tdcRPCx8fPzJ8fPzI8Cuztiobib+s9/W+LkEXa0f69fPCx8ePDB8fP7Jwvqt4R2dt9ZK1hY8fGT4+fmT4+GflW1tHN9Da2rmKl3MRb5qmtflkrK1WHH548PHxI8PHx48Mv7KdtZX0wmxtVeaPTx3x08LHx48MHx8/MvzKzJXKwvnWVkf8tPDx8SPDx8ePDL8ya6uykfjPq3jVpH/z88LHx48MHx8/MvzK/PHp6KytXrK28PEjw8fHjwwf/6x8a+voBlpbu1fxOq85JC9nv/+LeNunM/zw4OPjR4aPjx8ZfmUjra28wg8PfmUPPABb6rm7Ea0AAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjJUMDc6MTY6MTkrMDA6MDAVMMXmAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIyVDA3OjE2OjE5KzAwOjAwZG19WgAAAABJRU5ErkJggg==\">                        \n",
       "2  <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAG0AAADKCAQAAAAF6AaLAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBYHEBO2XgtjAAABX0lEQVR42u3YwWnDQBRFUSm4unSQFOh0kPac7STglQPi/LlnZeHNXCSEn8/HMdXb1QcorbTVbb34ehzH53n1kV6xvjkG37XSRKWJShOVJipNVJqoNNG5Lhx6qh3Hsedeuz/ug/7g2uWuzVKaqDRRaaLSRKWJShM1RUW7pLWyEaWJShOVJipNVJqoNNHgtFa2aJe0VjaiNFFpotJEpYlKE5UmGpzWyhbtktbKRpQmKk1Umqg0UWmi0kSD01rZoqaoqDRRaaLSRKWJShOVJipN1MoWtbJFpYlKE5UmKk1Umqg00eC0pqhol7RWNqI0UWmi0kSliUoTlSYanNbKFu2S1spGlCYqTVSaqDRRaaLSRIPTWtmiXdJa2YjSRKWJShOVJipNVJpocForW3RbLwYM0eXBu/3+5v3qo/2jwQ9kaaLSRKWJShOVJipN9OeX//fV53nRx/L59CfaM4MfyNJEP0K2Ox7416vXAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDI1LTA0LTIyVDA3OjE2OjE5KzAwOjAwFTDF5gAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyNS0wNC0yMlQwNzoxNjoxOSswMDowMGRtfVoAAAAASUVORK5CYII=\">                                                    \n",
       "3  <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBYHEBQoOp7AAAAA5klEQVR42u3cwQ2CMBhAYWuYzg10wLqBc7kB3kiJEpFiWt7/Hhe4NHwBSgKENJ5idG69A0KFbmsoN1LFQHl2sd9qhtqtcpeGzaO8dZnWHq2FH1qE9niE/gLt/Qj9WpjJSCitKmgen9PSGvKtlbeX3D1kJ2g5Ax9zNvYapSWUllBaQmkJpSWUllBaQmkJpSWUllBaQmmFgc6e1B//xcNKKO3lb1mYU1coLaG0hNISSksoLaG0hNISSksoLaG0hNISSksoLaG0hNISSksoLaG0wkBT+WnRHfad0bX4TUaC2RYLc+oKpfUCK5UeTY+BarAAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjJUMDc6MTY6MjArMDA6MDAOJ4fWAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIyVDA3OjE2OjIwKzAwOjAwf3o/agAAAABJRU5ErkJggg==\">                                                                                                                                                                                                                    \n",
       "4  <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAABoAAAC3CAQAAACmwYZ1AAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBYHEBVfPa5WAAAAy0lEQVRo3u2awQ2DMBAEfRHVpQQXSDqgLjpwHvmwxo4OiMiBZnhZ8kg+jgVbwkrazmOHc6I0LAev8mxOmlK2Ze3Ba0JCUgYdTi5JHnn7MvFwNGR5Y/ctk60rpdRLrhK8T0hIypWTm80haXL79QXvExKScuXkfljn1/XNrQneJyQk5bwQsltGQvqdFDy5Io1lrq52loPfciQkJfjGl+QiITUJnlznxleX4Tyyaq3B+4SEpNwjuTuOrDXB+4SEpJDcI8tDQvqXZDf8HeoNSZBWhwHfHEYAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjJUMDc6MTY6MjErMDA6MDCoUIxiAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIyVDA3OjE2OjIxKzAwOjAw2Q003gAAAABJRU5ErkJggg==\">                                                                                                                                                                                                                                                        \n",
       "5  <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBYHEBbGNP/sAAABK0lEQVR42u3b0Q2CMABFUWqYjg10QNyAudgAPxCoSiNtKdDXe3+MJhAPlBajmqEqo9vZbwAo0LBq+4nx2LCdL+6Hz2aHZs8/dehOmvdjd7ZmY8UMXaBqAVWrGGjw8rI0rajjgtNFravpVucdoBNwO2Lpm5Nudd4B6ntIlrqqH8bH3/M3HZa9zmxCaNww3DpOLgC91k3ioUPXXev8/O8e3FlCm/hd/Il19KqFTnHZQD9vS/ynuGygsVdxAmg/rL9y7jJTzGQEVC3Pa7TN9hsM78ko/T1MmooZukDVAqoWULWAqgVULaBqAVULqFpA1QKqFlC1gKoFVC2gagFVC6haQNUCqhZQtYCqBVQtoGoBVQuoWsVAjf0j+We2v5hf7279qcuI2ZwVM3SBqvUCy9ktIuH0SSgAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjJUMDc6MTY6MjIrMDA6MDCZuJb/AAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIyVDA3OjE2OjIyKzAwOjAw6OUuQwAAAABJRU5ErkJggg==\">                                                                                                                        \n",
       "6  <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAB4AAACCCAQAAAD7nbARAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBYHEBbGNP/sAAAArElEQVRYw+3Z2w2AIAwF0NYwnSN0QN2A9fDX+iiiNqZy+SPhJNCGG6Jc6P4YHtgPcVpP5jKaizMJr2sU9MzAwL446WluwuqK8QXw2pVU256qaSh8ionGmlYjaJ+BgX1xD0kibGA7Sfb1CNpnYGBf3EOSbLfX+CbRNQnaZ2BgX9xDkuBNAgzsjf+fJMImtpLkqBpB+wwM7Iv/nyREj764bisStM/AwL6YO/wLvACUmyhPC06I2AAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAyNS0wNC0yMlQwNzoxNjoyMiswMDowMJm4lv8AAAAldEVYdGRhdGU6bW9kaWZ5ADIwMjUtMDQtMjJUMDc6MTY6MjIrMDA6MDDo5S5DAAAAAElFTkSuQmCC\">                                                                                                                                                                                                                                                                                                    \n",
       "7  <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAACoAAABOCAQAAAD8r0ycAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBYHEBbGNP/sAAAAiklEQVRYw+3WSw6AIAxF0dawOpfAAnUHbk+HFHXEJ2nD7cxETvKEPNRbxs82wQyEJvtwNn3grCIidmmqX9j9xgcFBV0TfbXUNQRV24PaAVlnfvyj52o1MQc1f70XcY4UKCioe5TmL9PW/PkTsLv5/3YhzpECBQV1j9L8ZfjnBwUFXQOd3/yu48dBH/iKFxn/tftSAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDI1LTA0LTIyVDA3OjE2OjIyKzAwOjAwmbiW/wAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyNS0wNC0yMlQwNzoxNjoyMiswMDowMOjlLkMAAAAASUVORK5CYII=\">                                                                                                                                                                                                                                                                                                                                                \n",
       "8  <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBYHEBghjNLrAAABS0lEQVR42u2bwRGDIBBFIWN16SAp0HRgXenAHBgcRoMisot8/vPkRXmwu66M2tn0waP2AChK0TyG8MSK3GJcysBb5gZRwvozZF/lBE9jjDGTruWKbkK3G1GV0D1im8Xj7MO9VF7fQtRn8ZmpaFT0+lQ0LzoW6lFVRbeDPg7EUo8mVdF1+E3F1quqaIqEXivxV7RM0+bXr6xG7tgiK3q1xsmRO33sjFKp926iLLouKL55y0OuCp8UlV4/mQKWIXrnMrVPdjH6zu6oLSAu2hrdiCbmaEo1dGFcd2coUXRP5w4bXMVE29eJwxx16L0vVhaV61S06SZ0KYoGRdGgKBoURYOiaFAUDYqiQVE0KIoGRdGgKBoURYOiaFAUDYqiQVE0KIoGRdGgKBoURYOiaFAUDYqi0Y2oDT+x/sB8b+14Bb+VWTC3KN2ELkXR+AGM4D3GuUKOYwAAACV0RVh0ZGF0ZTpjcmVhdGUAMjAyNS0wNC0yMlQwNzoxNjoyNCswMDowMPpoo8UAAAAldEVYdGRhdGU6bW9kaWZ5ADIwMjUtMDQtMjJUMDc6MTY6MjQrMDA6MDCLNRt5AAAAAElFTkSuQmCC\">                                                                                \n",
       "9  <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBYHEBghjNLrAAAAs0lEQVR42u3cwQnCQBBAUSOpzhIsUDuwPb0IrjmJCgs/711CyGU+7OY4y/2wD8fZAwgV+p11fLkOF/a8zB7td+P/Z33/dHo+b7Nn/LvdHF2hNUJrhNYIrRFaI7RGaI3QGqE1QmuE1gitEVojtEZojdAaoTVCa4TWCK0RWiO0RmiN0BqhNUJrhNYIrRFaI7RGaI3QGqE1QmuE1git2WzWeG3UuBT2/wxrUJZCzyd2c3SF1jwANQAJB63xoakAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjJUMDc6MTY6MjQrMDA6MDD6aKPFAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIyVDA3OjE2OjI0KzAwOjAwizUbeQAAAABJRU5ErkJggg==\">                                                                                                                                                                                                                                                                                        \n",
       "10 <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAADIAAAA7CAQAAACTORHyAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBYHEBlWi+J9AAAAeElEQVRYw+3YsQ3AIAxEUTtiOjbIgskGrEdaQyoig4j1r6PxE1AcQqvMz7HACIQku7hrdhpb5NTFOwEBAQH5I5LaZZmCqK1f/TzmHTs36J1cjs0oNCMICAjIJgjNOJSuGR0nm7PvnkSO9WsS505AQEBAnKN82W6HPFCdD3vWiEuiAAAAJXRFWHRkYXRlOmNyZWF0ZQAyMDI1LTA0LTIyVDA3OjE2OjI1KzAwOjAwXB+ocQAAACV0RVh0ZGF0ZTptb2RpZnkAMjAyNS0wNC0yMlQwNzoxNjoyNSswMDowMC1CEM0AAAAASUVORK5CYII=\">                                                                                                                                                                                                                                                                                                                                                                        \n",
       "11 <img style=\"border:none;background-color:transparent;padding:0;max-width:max-content;\" src=\"data:image/png;base64, iVBORw0KGgoAAAANSUhEUgAAAHQAAABUCAQAAAD5P9uaAAAABGdBTUEAALGPC/xhBQAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAAAmJLR0QA/4ePzL8AAAAHdElNRQfpBBYHEBrPgrPHAAABhUlEQVR42u2b0XGDMBBEhccFuC46cAokHbguOiAfCaAgMCAk393evj+PB8aPW4mTwM0QfHCT/gEUpWge9/hDk3GCbhrkXzmHVyWef+7ZZ5loQwghvKStdjgp+q5+3WIC11Xhg6KzRLuhNVe2TY4dv5FUP1zRZUBHne3Idqpu0QXG6Bb7lwJENGWssUSEd0TLxq+9fopaorridwWfndGIrvmyoqjsaPqoaF0k+mMRUYkpzs1kRFE0KIqGsGg/9EM/fKJBYUXRoCgabkRFet2U/m/efVRr8t1UlKJo/BujiFsoq6JWHhjl4Ca6FJXhdzVTYz2jTLQeFEWDomi4EVWyTEsp/XRcrWjpZtRNdCmqhVItoXrRUlAUDTeiau+jS642EGZEr74Q5Ca6FEWDomiYE83dEDUnmgtF0aAoGmZ63ZRzbb5h0XP7hIyuHY5FGED02EqV0bXH+wgDic7/VV5TZXQtMy3hospCiq61Em6i60a0iXckvsHe7nxGY7QBc9vETXQpisYP9XNcCznJq+YAAAAldEVYdGRhdGU6Y3JlYXRlADIwMjUtMDQtMjJUMDc6MTY6MjYrMDA6MDBt97LsAAAAJXRFWHRkYXRlOm1vZGlmeQAyMDI1LTA0LTIyVDA3OjE2OjI2KzAwOjAwHKoKUAAAAABJRU5ErkJggg==\">\n",
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
   "id": "9c886041",
   "metadata": {
    "papermill": {
     "duration": 0.006939,
     "end_time": "2025-04-22T07:16:26.850386",
     "exception": false,
     "start_time": "2025-04-22T07:16:26.843447",
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
   "id": "cbeb21ec",
   "metadata": {
    "papermill": {
     "duration": 0.006717,
     "end_time": "2025-04-22T07:16:26.863911",
     "exception": false,
     "start_time": "2025-04-22T07:16:26.857194",
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
   "id": "e78cad82",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-04-22T07:16:26.882674Z",
     "iopub.status.busy": "2025-04-22T07:16:26.880463Z",
     "iopub.status.idle": "2025-04-22T07:17:46.663943Z",
     "shell.execute_reply": "2025-04-22T07:17:46.661602Z"
    },
    "papermill": {
     "duration": 79.795985,
     "end_time": "2025-04-22T07:17:46.666730",
     "exception": false,
     "start_time": "2025-04-22T07:16:26.870745",
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
      "/usr/bin/pandoc +RTS -K512m -RTS /kaggle/working/report.knit.md --to html4 --from markdown+autolink_bare_uris+tex_math_single_backslash --output pandocd388affd8.html --lua-filter /usr/local/lib/R/site-library/rmarkdown/rmarkdown/lua/pagebreak.lua --lua-filter /usr/local/lib/R/site-library/rmarkdown/rmarkdown/lua/latex-div.lua --embed-resources --standalone --variable bs3=TRUE --section-divs --table-of-contents --toc-depth 6 --template /usr/local/lib/R/site-library/rmarkdown/rmd/h/default.html --no-highlight --variable highlightjs=1 --variable theme=yeti --mathjax --variable 'mathjax-url=https://mathjax.rstudio.com/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML' --include-in-header /tmp/RtmpLDP5Qq/rmarkdown-strd4b1f7ce0.html \n"
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
   "cell_type": "code",
   "execution_count": 5,
   "id": "ec4c50d0",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-04-22T07:17:46.690209Z",
     "iopub.status.busy": "2025-04-22T07:17:46.688508Z",
     "iopub.status.idle": "2025-04-22T07:17:52.731933Z",
     "shell.execute_reply": "2025-04-22T07:17:52.729452Z"
    },
    "papermill": {
     "duration": 6.057179,
     "end_time": "2025-04-22T07:17:52.734641",
     "exception": false,
     "start_time": "2025-04-22T07:17:46.677462",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "data": {
      "image/png": "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"
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
    "plot_histogram(train_tbl)"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 6,
   "id": "7d154084",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-04-22T07:17:52.758492Z",
     "iopub.status.busy": "2025-04-22T07:17:52.756655Z",
     "iopub.status.idle": "2025-04-22T07:17:54.161819Z",
     "shell.execute_reply": "2025-04-22T07:17:54.159311Z"
    },
    "papermill": {
     "duration": 1.420784,
     "end_time": "2025-04-22T07:17:54.165113",
     "exception": false,
     "start_time": "2025-04-22T07:17:52.744329",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "1 columns ignored with more than 50 categories.\n",
      "Episode_Title: 100 categories\n",
      "\n",
      "\n"
     ]
    },
    {
     "data": {
      "image/png": "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\nkNgBAAAoxP8DfgK9vTK+5koAAAAASUVORK5CYII="
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
    "plot_bar(train_tbl)"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "991bdd9f",
   "metadata": {
    "papermill": {
     "duration": 0.011848,
     "end_time": "2025-04-22T07:17:54.189173",
     "exception": false,
     "start_time": "2025-04-22T07:17:54.177325",
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
   "execution_count": 7,
   "id": "0328fc8c",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-04-22T07:17:54.216816Z",
     "iopub.status.busy": "2025-04-22T07:17:54.215092Z",
     "iopub.status.idle": "2025-04-22T07:17:54.261798Z",
     "shell.execute_reply": "2025-04-22T07:17:54.259476Z"
    },
    "papermill": {
     "duration": 0.064123,
     "end_time": "2025-04-22T07:17:54.264925",
     "exception": false,
     "start_time": "2025-04-22T07:17:54.200802",
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
   "execution_count": 8,
   "id": "6c3a433d",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-04-22T07:17:54.292652Z",
     "iopub.status.busy": "2025-04-22T07:17:54.290805Z",
     "iopub.status.idle": "2025-04-22T07:19:33.604090Z",
     "shell.execute_reply": "2025-04-22T07:19:33.601809Z"
    },
    "papermill": {
     "duration": 99.330421,
     "end_time": "2025-04-22T07:19:33.607037",
     "exception": false,
     "start_time": "2025-04-22T07:17:54.276616",
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
   "execution_count": 9,
   "id": "bfbfc96c",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-04-22T07:19:33.640551Z",
     "iopub.status.busy": "2025-04-22T07:19:33.638715Z",
     "iopub.status.idle": "2025-04-22T07:20:35.247717Z",
     "shell.execute_reply": "2025-04-22T07:20:35.245481Z"
    },
    "papermill": {
     "duration": 61.626951,
     "end_time": "2025-04-22T07:20:35.250742",
     "exception": false,
     "start_time": "2025-04-22T07:19:33.623791",
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
   "execution_count": 10,
   "id": "eaccc428",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-04-22T07:20:35.285246Z",
     "iopub.status.busy": "2025-04-22T07:20:35.283615Z",
     "iopub.status.idle": "2025-04-22T07:20:43.039491Z",
     "shell.execute_reply": "2025-04-22T07:20:43.035778Z"
    },
    "papermill": {
     "duration": 7.774427,
     "end_time": "2025-04-22T07:20:43.042964",
     "exception": false,
     "start_time": "2025-04-22T07:20:35.268537",
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
      "    /tmp/RtmpLDP5Qq/filed372464d5/h2o_UnknownUser_started_from_r.out\n",
      "    /tmp/RtmpLDP5Qq/filed3f1771f8/h2o_UnknownUser_started_from_r.err\n",
      "\n",
      "\n",
      "Starting H2O JVM and connecting: ..... Connection successful!\n",
      "\n",
      "R is connected to the H2O cluster: \n",
      "    H2O cluster uptime:         3 seconds 359 milliseconds \n",
      "    H2O cluster timezone:       Etc/UTC \n",
      "    H2O data parsing timezone:  UTC \n",
      "    H2O cluster version:        3.44.0.3 \n",
      "    H2O cluster version age:    1 year, 4 months and 1 day \n",
      "    H2O cluster name:           H2O_started_from_R_root_zub724 \n",
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
   "execution_count": 11,
   "id": "0627d726",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-04-22T07:20:43.089141Z",
     "iopub.status.busy": "2025-04-22T07:20:43.086564Z",
     "iopub.status.idle": "2025-04-22T07:34:04.970427Z",
     "shell.execute_reply": "2025-04-22T07:34:04.966701Z"
    },
    "papermill": {
     "duration": 801.913126,
     "end_time": "2025-04-22T07:34:04.976118",
     "exception": false,
     "start_time": "2025-04-22T07:20:43.062992",
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
       "                                             model_id     rmse       mse\n",
       "1 StackedEnsemble_AllModels_1_AutoML_1_20250422_72136 13.08699  171.2692\n",
       "2                   XGBoost_1_AutoML_1_20250422_72136 14.41655  207.8371\n",
       "3                   XGBoost_2_AutoML_1_20250422_72136 41.42997 1716.4421\n",
       "        mae     rmsle mean_residual_deviance\n",
       "1  9.502862 0.4101020               171.2692\n",
       "2 10.512800 0.4088485               207.8371\n",
       "3 33.253835 1.2271445              1716.4421\n",
       "\n",
       "[3 rows x 6 columns] "
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
    "    include_algos = c(\"DeepLearning\", \"XGBoost\", \"StackedEnsemble\"),\n",
    "    stopping_metric = \"RMSE\",\n",
    "    sort_metric = \"RMSE\",\n",
    "    max_runtime_secs = 720\n",
    ")\n",
    "h2o_automl_models@leaderboard\n"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 12,
   "id": "7fc59854",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-04-22T07:34:05.245527Z",
     "iopub.status.busy": "2025-04-22T07:34:05.241004Z",
     "iopub.status.idle": "2025-04-22T07:34:05.281670Z",
     "shell.execute_reply": "2025-04-22T07:34:05.276556Z"
    },
    "papermill": {
     "duration": 0.235997,
     "end_time": "2025-04-22T07:34:05.285296",
     "exception": false,
     "start_time": "2025-04-22T07:34:05.049299",
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
      "“This model doesn't have variable importances”\n"
     ]
    }
   ],
   "source": [
    "h2o.varimp(h2o_automl_models@leader)\n"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 13,
   "id": "d9cf7870",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-04-22T07:34:05.376319Z",
     "iopub.status.busy": "2025-04-22T07:34:05.371998Z",
     "iopub.status.idle": "2025-04-22T07:34:05.483965Z",
     "shell.execute_reply": "2025-04-22T07:34:05.478319Z"
    },
    "papermill": {
     "duration": 0.162181,
     "end_time": "2025-04-22T07:34:05.488214",
     "exception": false,
     "start_time": "2025-04-22T07:34:05.326033",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "data": {
      "text/html": [
       "<table class=\"dataframe\">\n",
       "<caption>A data.frame: 3 × 3</caption>\n",
       "<thead>\n",
       "\t<tr><th scope=col>model_id</th><th scope=col>rmse</th><th scope=col>mse</th></tr>\n",
       "\t<tr><th scope=col>&lt;chr&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th></tr>\n",
       "</thead>\n",
       "<tbody>\n",
       "\t<tr><td>StackedEnsemble_AllModels_1_AutoML_1_20250422_72136</td><td>13.08699</td><td> 171.2692</td></tr>\n",
       "\t<tr><td>XGBoost_1_AutoML_1_20250422_72136                  </td><td>14.41655</td><td> 207.8371</td></tr>\n",
       "\t<tr><td>XGBoost_2_AutoML_1_20250422_72136                  </td><td>41.42997</td><td>1716.4421</td></tr>\n",
       "</tbody>\n",
       "</table>\n"
      ],
      "text/latex": [
       "A data.frame: 3 × 3\n",
       "\\begin{tabular}{lll}\n",
       " model\\_id & rmse & mse\\\\\n",
       " <chr> & <dbl> & <dbl>\\\\\n",
       "\\hline\n",
       "\t StackedEnsemble\\_AllModels\\_1\\_AutoML\\_1\\_20250422\\_72136 & 13.08699 &  171.2692\\\\\n",
       "\t XGBoost\\_1\\_AutoML\\_1\\_20250422\\_72136                   & 14.41655 &  207.8371\\\\\n",
       "\t XGBoost\\_2\\_AutoML\\_1\\_20250422\\_72136                   & 41.42997 & 1716.4421\\\\\n",
       "\\end{tabular}\n"
      ],
      "text/markdown": [
       "\n",
       "A data.frame: 3 × 3\n",
       "\n",
       "| model_id &lt;chr&gt; | rmse &lt;dbl&gt; | mse &lt;dbl&gt; |\n",
       "|---|---|---|\n",
       "| StackedEnsemble_AllModels_1_AutoML_1_20250422_72136 | 13.08699 |  171.2692 |\n",
       "| XGBoost_1_AutoML_1_20250422_72136                   | 14.41655 |  207.8371 |\n",
       "| XGBoost_2_AutoML_1_20250422_72136                   | 41.42997 | 1716.4421 |\n",
       "\n"
      ],
      "text/plain": [
       "  model_id                                            rmse     mse      \n",
       "1 StackedEnsemble_AllModels_1_AutoML_1_20250422_72136 13.08699  171.2692\n",
       "2 XGBoost_1_AutoML_1_20250422_72136                   14.41655  207.8371\n",
       "3 XGBoost_2_AutoML_1_20250422_72136                   41.42997 1716.4421"
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    }
   ],
   "source": [
    "lb <- h2o_automl_models@leaderboard\n",
    "as.data.frame(lb) %>%\n",
    "    select(model_id, rmse, mse) %>%\n",
    "    arrange(rmse)\n"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 14,
   "id": "348ed6df",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-04-22T07:34:05.594776Z",
     "iopub.status.busy": "2025-04-22T07:34:05.587353Z",
     "iopub.status.idle": "2025-04-22T07:34:06.075579Z",
     "shell.execute_reply": "2025-04-22T07:34:06.073004Z"
    },
    "papermill": {
     "duration": 0.549465,
     "end_time": "2025-04-22T07:34:06.078539",
     "exception": false,
     "start_time": "2025-04-22T07:34:05.529074",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "data": {
      "image/png": "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"
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
    "as.data.frame(lb) %>%\n",
    "    mutate(model_id = fct_reorder(model_id, rmse)) %>%\n",
    "    ggplot(aes(x = model_id, y = rmse)) +\n",
    "    geom_col(fill = \"steelblue\") +\n",
    "    coord_flip() +\n",
    "    labs(title = \"RMSE per Model in H2O AutoML\",\n",
    "         x = \"Model ID\", y = \"RMSE\") +\n",
    "    theme_minimal()\n"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 15,
   "id": "aafb47c0",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-04-22T07:34:06.136442Z",
     "iopub.status.busy": "2025-04-22T07:34:06.133552Z",
     "iopub.status.idle": "2025-04-22T07:35:10.238188Z",
     "shell.execute_reply": "2025-04-22T07:35:10.235123Z"
    },
    "papermill": {
     "duration": 64.13442,
     "end_time": "2025-04-22T07:35:10.241644",
     "exception": false,
     "start_time": "2025-04-22T07:34:06.107224",
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
       "9.41591602037934e-07"
      ],
      "text/latex": [
       "9.41591602037934e-07"
      ],
      "text/markdown": [
       "9.41591602037934e-07"
      ],
      "text/plain": [
       "[1] 9.415916e-07"
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
      "image/png": "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\nr74OEkIAAAAASUVORK5CYII="
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
   "execution_count": 16,
   "id": "d0db53c6",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-04-22T07:35:10.301378Z",
     "iopub.status.busy": "2025-04-22T07:35:10.298794Z",
     "iopub.status.idle": "2025-04-22T07:35:10.453453Z",
     "shell.execute_reply": "2025-04-22T07:35:10.449950Z"
    },
    "papermill": {
     "duration": 0.18613,
     "end_time": "2025-04-22T07:35:10.456580",
     "exception": false,
     "start_time": "2025-04-22T07:35:10.270450",
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
   "duration": 1143.332905,
   "end_time": "2025-04-22T07:35:11.016477",
   "environment_variables": {},
   "exception": null,
   "input_path": "__notebook__.ipynb",
   "output_path": "__notebook__.ipynb",
   "parameters": {},
   "start_time": "2025-04-22T07:16:07.683572",
   "version": "2.6.0"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 5
}
