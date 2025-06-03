{
 "cells": [
  {
   "cell_type": "markdown",
   "id": "1fd6415a",
   "metadata": {
    "papermill": {
     "duration": 0.003474,
     "end_time": "2025-06-03T13:50:48.982430",
     "exception": false,
     "start_time": "2025-06-03T13:50:48.978956",
     "status": "completed"
    },
    "tags": []
   },
   "source": [
    "# How long does it take to make progress in Kaggle?\n",
    "\n",
    "I am one of the first users of Kaggle - more precisely, user number 650.\n",
    "\n",
    "After registering about 15 years ago, life happened and I never managed to participate much. Only recently, this year, I was able to complete my registration and join some competitions.\n",
    "\n",
    "Am I the slowest Kaggle participant ever? To verify this, let's compute how long does it take for users to achieve a new rank, and see how the distribution looks like.\n",
    "\n",
    "Unfortunately we are only able to compute the time it has taken for a user to get to their current rank since they registered. It is not possible to know how long it took them to go between one rank and the others, because the data is not saved."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 1,
   "id": "239e7f29",
   "metadata": {
    "_cell_guid": "b1076dfc-b9ad-4769-8c92-a6c4dae69d19",
    "_uuid": "8f2839f25d086af736a60e9eeb907d3b93b6e0e5",
    "execution": {
     "iopub.execute_input": "2025-06-03T13:50:48.992890Z",
     "iopub.status.busy": "2025-06-03T13:50:48.990792Z",
     "iopub.status.idle": "2025-06-03T13:50:50.307385Z",
     "shell.execute_reply": "2025-06-03T13:50:50.305679Z"
    },
    "papermill": {
     "duration": 1.324508,
     "end_time": "2025-06-03T13:50:50.309962",
     "exception": false,
     "start_time": "2025-06-03T13:50:48.985454",
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
      "collapse 2.0.14, see ?`collapse-package` or ?`collapse-documentation`\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\n",
      "Attaching package: ‘collapse’\n",
      "\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "The following object is masked from ‘package:lubridate’:\n",
      "\n",
      "    is.Date\n",
      "\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "The following object is masked from ‘package:tidyr’:\n",
      "\n",
      "    replace_na\n",
      "\n",
      "\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "The following object is masked from ‘package:stats’:\n",
      "\n",
      "    D\n",
      "\n",
      "\n"
     ]
    }
   ],
   "source": [
    "# Since I am old style, let's use R\n",
    "library(tidyverse)\n",
    "library(lubridate)\n",
    "library(collapse)\n",
    "set_collapse(mask = \"manip\") # Use collapse instead of tidyverse for group_by/summarise functions\n",
    "options(repr.plot.width = 12, repr.plot.height = 8)\n"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "cc56b0fb",
   "metadata": {
    "papermill": {
     "duration": 0.003264,
     "end_time": "2025-06-03T13:50:50.316610",
     "exception": false,
     "start_time": "2025-06-03T13:50:50.313346",
     "status": "completed"
    },
    "tags": []
   },
   "source": [
    "### Reading Data and parsing dates"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 2,
   "id": "11a62551",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-06-03T13:50:50.353959Z",
     "iopub.status.busy": "2025-06-03T13:50:50.324341Z",
     "iopub.status.idle": "2025-06-03T13:53:34.120559Z",
     "shell.execute_reply": "2025-06-03T13:53:34.118979Z"
    },
    "papermill": {
     "duration": 163.803463,
     "end_time": "2025-06-03T13:53:34.123189",
     "exception": false,
     "start_time": "2025-06-03T13:50:50.319726",
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
      "“\u001b[1m\u001b[22mOne or more parsing issues, call `problems()` on your data frame for details,\n",
      "e.g.:\n",
      "  dat <- vroom(...)\n",
      "  problems(dat)”\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[1mRows: \u001b[22m\u001b[34m24435461\u001b[39m \u001b[1mColumns: \u001b[22m\u001b[34m7\u001b[39m\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[36m──\u001b[39m \u001b[1mColumn specification\u001b[22m \u001b[36m────────────────────────────────────────────────────────\u001b[39m\n",
      "\u001b[1mDelimiter:\u001b[22m \",\"\n",
      "\u001b[31mchr\u001b[39m (4): UserName, DisplayName, RegisterDate, Country\n",
      "\u001b[32mdbl\u001b[39m (2): Id, PerformanceTier\n",
      "\u001b[33mlgl\u001b[39m (1): LocationSharingOptOut\n"
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
    "users = read_csv(\"/kaggle/input/meta-kaggle/Users.csv\") %>% \n",
    "     mutate(RegisterDate = mdy(RegisterDate))"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 3,
   "id": "86448efe",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-06-03T13:53:34.141499Z",
     "iopub.status.busy": "2025-06-03T13:53:34.140199Z",
     "iopub.status.idle": "2025-06-03T13:53:34.176105Z",
     "shell.execute_reply": "2025-06-03T13:53:34.174099Z"
    },
    "papermill": {
     "duration": 0.048381,
     "end_time": "2025-06-03T13:53:34.178739",
     "exception": false,
     "start_time": "2025-06-03T13:53:34.130358",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "data": {
      "text/html": [
       "<table class=\"dataframe\">\n",
       "<caption>A tibble: 6 × 7</caption>\n",
       "<thead>\n",
       "\t<tr><th scope=col>Id</th><th scope=col>UserName</th><th scope=col>DisplayName</th><th scope=col>RegisterDate</th><th scope=col>PerformanceTier</th><th scope=col>Country</th><th scope=col>LocationSharingOptOut</th></tr>\n",
       "\t<tr><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;chr&gt;</th><th scope=col>&lt;chr&gt;</th><th scope=col>&lt;date&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;chr&gt;</th><th scope=col>&lt;lgl&gt;</th></tr>\n",
       "</thead>\n",
       "<tbody>\n",
       "\t<tr><td>  1</td><td>kaggleteam  </td><td>Kaggle Team      </td><td>2011-03-24</td><td>5</td><td>NA            </td><td>FALSE</td></tr>\n",
       "\t<tr><td>368</td><td>antgoldbloom</td><td>Anthony Goldbloom</td><td>2010-01-20</td><td>2</td><td>United States </td><td>FALSE</td></tr>\n",
       "\t<tr><td>381</td><td>iguyon      </td><td>Isabelle         </td><td>2010-01-29</td><td>2</td><td>United States </td><td>FALSE</td></tr>\n",
       "\t<tr><td>383</td><td>davidstephan</td><td>David Stephan    </td><td>2010-02-01</td><td>0</td><td>Australia     </td><td>FALSE</td></tr>\n",
       "\t<tr><td>384</td><td>gabewarren  </td><td>Gabe Warren      </td><td>2010-02-02</td><td>0</td><td>Australia     </td><td>FALSE</td></tr>\n",
       "\t<tr><td>385</td><td>demonjosh   </td><td>Demon Josh       </td><td>2010-02-02</td><td>0</td><td>United Kingdom</td><td>FALSE</td></tr>\n",
       "</tbody>\n",
       "</table>\n"
      ],
      "text/latex": [
       "A tibble: 6 × 7\n",
       "\\begin{tabular}{lllllll}\n",
       " Id & UserName & DisplayName & RegisterDate & PerformanceTier & Country & LocationSharingOptOut\\\\\n",
       " <dbl> & <chr> & <chr> & <date> & <dbl> & <chr> & <lgl>\\\\\n",
       "\\hline\n",
       "\t   1 & kaggleteam   & Kaggle Team       & 2011-03-24 & 5 & NA             & FALSE\\\\\n",
       "\t 368 & antgoldbloom & Anthony Goldbloom & 2010-01-20 & 2 & United States  & FALSE\\\\\n",
       "\t 381 & iguyon       & Isabelle          & 2010-01-29 & 2 & United States  & FALSE\\\\\n",
       "\t 383 & davidstephan & David Stephan     & 2010-02-01 & 0 & Australia      & FALSE\\\\\n",
       "\t 384 & gabewarren   & Gabe Warren       & 2010-02-02 & 0 & Australia      & FALSE\\\\\n",
       "\t 385 & demonjosh    & Demon Josh        & 2010-02-02 & 0 & United Kingdom & FALSE\\\\\n",
       "\\end{tabular}\n"
      ],
      "text/markdown": [
       "\n",
       "A tibble: 6 × 7\n",
       "\n",
       "| Id &lt;dbl&gt; | UserName &lt;chr&gt; | DisplayName &lt;chr&gt; | RegisterDate &lt;date&gt; | PerformanceTier &lt;dbl&gt; | Country &lt;chr&gt; | LocationSharingOptOut &lt;lgl&gt; |\n",
       "|---|---|---|---|---|---|---|\n",
       "|   1 | kaggleteam   | Kaggle Team       | 2011-03-24 | 5 | NA             | FALSE |\n",
       "| 368 | antgoldbloom | Anthony Goldbloom | 2010-01-20 | 2 | United States  | FALSE |\n",
       "| 381 | iguyon       | Isabelle          | 2010-01-29 | 2 | United States  | FALSE |\n",
       "| 383 | davidstephan | David Stephan     | 2010-02-01 | 0 | Australia      | FALSE |\n",
       "| 384 | gabewarren   | Gabe Warren       | 2010-02-02 | 0 | Australia      | FALSE |\n",
       "| 385 | demonjosh    | Demon Josh        | 2010-02-02 | 0 | United Kingdom | FALSE |\n",
       "\n"
      ],
      "text/plain": [
       "  Id  UserName     DisplayName       RegisterDate PerformanceTier\n",
       "1   1 kaggleteam   Kaggle Team       2011-03-24   5              \n",
       "2 368 antgoldbloom Anthony Goldbloom 2010-01-20   2              \n",
       "3 381 iguyon       Isabelle          2010-01-29   2              \n",
       "4 383 davidstephan David Stephan     2010-02-01   0              \n",
       "5 384 gabewarren   Gabe Warren       2010-02-02   0              \n",
       "6 385 demonjosh    Demon Josh        2010-02-02   0              \n",
       "  Country        LocationSharingOptOut\n",
       "1 NA             FALSE                \n",
       "2 United States  FALSE                \n",
       "3 United States  FALSE                \n",
       "4 Australia      FALSE                \n",
       "5 Australia      FALSE                \n",
       "6 United Kingdom FALSE                "
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    }
   ],
   "source": [
    "users %>% head "
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 4,
   "id": "b6b5e0b3",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-06-03T13:53:34.189224Z",
     "iopub.status.busy": "2025-06-03T13:53:34.187849Z",
     "iopub.status.idle": "2025-06-03T13:57:23.408320Z",
     "shell.execute_reply": "2025-06-03T13:57:23.406643Z"
    },
    "papermill": {
     "duration": 229.228754,
     "end_time": "2025-06-03T13:57:23.411285",
     "exception": false,
     "start_time": "2025-06-03T13:53:34.182531",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[1mRows: \u001b[22m\u001b[34m97741736\u001b[39m \u001b[1mColumns: \u001b[22m\u001b[34m11\u001b[39m\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[36m──\u001b[39m \u001b[1mColumn specification\u001b[22m \u001b[36m────────────────────────────────────────────────────────\u001b[39m\n",
      "\u001b[1mDelimiter:\u001b[22m \",\"\n",
      "\u001b[31mchr\u001b[39m (2): AchievementType, TierAchievementDate\n",
      "\u001b[32mdbl\u001b[39m (9): Id, UserId, Tier, Points, CurrentRanking, HighestRanking, TotalGold...\n"
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
    "user_achievements = read_csv(\"/kaggle/input/meta-kaggle/UserAchievements.csv\")  %>% \n",
    "    mutate(TierAchievementDate = mdy(TierAchievementDate))\n"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 5,
   "id": "0b78d0b7",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-06-03T13:57:23.437700Z",
     "iopub.status.busy": "2025-06-03T13:57:23.436283Z",
     "iopub.status.idle": "2025-06-03T13:57:23.475475Z",
     "shell.execute_reply": "2025-06-03T13:57:23.473906Z"
    },
    "papermill": {
     "duration": 0.061801,
     "end_time": "2025-06-03T13:57:23.477380",
     "exception": false,
     "start_time": "2025-06-03T13:57:23.415579",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "data": {
      "text/html": [
       "<table class=\"dataframe\">\n",
       "<caption>A tibble: 6 × 11</caption>\n",
       "<thead>\n",
       "\t<tr><th scope=col>Id</th><th scope=col>UserId</th><th scope=col>AchievementType</th><th scope=col>Tier</th><th scope=col>TierAchievementDate</th><th scope=col>Points</th><th scope=col>CurrentRanking</th><th scope=col>HighestRanking</th><th scope=col>TotalGold</th><th scope=col>TotalSilver</th><th scope=col>TotalBronze</th></tr>\n",
       "\t<tr><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;chr&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;date&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th></tr>\n",
       "</thead>\n",
       "<tbody>\n",
       "\t<tr><td>3739827</td><td>381</td><td>Scripts     </td><td>1</td><td>2016-07-15</td><td>0</td><td>NA</td><td>NA</td><td>0</td><td>0</td><td>0</td></tr>\n",
       "\t<tr><td>3916403</td><td>383</td><td>Competitions</td><td>0</td><td>2016-07-15</td><td>0</td><td>NA</td><td>NA</td><td>0</td><td>0</td><td>0</td></tr>\n",
       "\t<tr><td>3916404</td><td>384</td><td>Competitions</td><td>0</td><td>2016-07-15</td><td>0</td><td>NA</td><td>NA</td><td>0</td><td>0</td><td>0</td></tr>\n",
       "\t<tr><td>3916405</td><td>385</td><td>Competitions</td><td>0</td><td>2016-07-15</td><td>0</td><td>NA</td><td>NA</td><td>0</td><td>0</td><td>0</td></tr>\n",
       "\t<tr><td>3916406</td><td>386</td><td>Competitions</td><td>0</td><td>2016-07-15</td><td>0</td><td>NA</td><td>NA</td><td>0</td><td>0</td><td>0</td></tr>\n",
       "\t<tr><td>3739829</td><td>387</td><td>Discussion  </td><td>0</td><td>2016-07-15</td><td>0</td><td>NA</td><td>NA</td><td>0</td><td>1</td><td>0</td></tr>\n",
       "</tbody>\n",
       "</table>\n"
      ],
      "text/latex": [
       "A tibble: 6 × 11\n",
       "\\begin{tabular}{lllllllllll}\n",
       " Id & UserId & AchievementType & Tier & TierAchievementDate & Points & CurrentRanking & HighestRanking & TotalGold & TotalSilver & TotalBronze\\\\\n",
       " <dbl> & <dbl> & <chr> & <dbl> & <date> & <dbl> & <dbl> & <dbl> & <dbl> & <dbl> & <dbl>\\\\\n",
       "\\hline\n",
       "\t 3739827 & 381 & Scripts      & 1 & 2016-07-15 & 0 & NA & NA & 0 & 0 & 0\\\\\n",
       "\t 3916403 & 383 & Competitions & 0 & 2016-07-15 & 0 & NA & NA & 0 & 0 & 0\\\\\n",
       "\t 3916404 & 384 & Competitions & 0 & 2016-07-15 & 0 & NA & NA & 0 & 0 & 0\\\\\n",
       "\t 3916405 & 385 & Competitions & 0 & 2016-07-15 & 0 & NA & NA & 0 & 0 & 0\\\\\n",
       "\t 3916406 & 386 & Competitions & 0 & 2016-07-15 & 0 & NA & NA & 0 & 0 & 0\\\\\n",
       "\t 3739829 & 387 & Discussion   & 0 & 2016-07-15 & 0 & NA & NA & 0 & 1 & 0\\\\\n",
       "\\end{tabular}\n"
      ],
      "text/markdown": [
       "\n",
       "A tibble: 6 × 11\n",
       "\n",
       "| Id &lt;dbl&gt; | UserId &lt;dbl&gt; | AchievementType &lt;chr&gt; | Tier &lt;dbl&gt; | TierAchievementDate &lt;date&gt; | Points &lt;dbl&gt; | CurrentRanking &lt;dbl&gt; | HighestRanking &lt;dbl&gt; | TotalGold &lt;dbl&gt; | TotalSilver &lt;dbl&gt; | TotalBronze &lt;dbl&gt; |\n",
       "|---|---|---|---|---|---|---|---|---|---|---|\n",
       "| 3739827 | 381 | Scripts      | 1 | 2016-07-15 | 0 | NA | NA | 0 | 0 | 0 |\n",
       "| 3916403 | 383 | Competitions | 0 | 2016-07-15 | 0 | NA | NA | 0 | 0 | 0 |\n",
       "| 3916404 | 384 | Competitions | 0 | 2016-07-15 | 0 | NA | NA | 0 | 0 | 0 |\n",
       "| 3916405 | 385 | Competitions | 0 | 2016-07-15 | 0 | NA | NA | 0 | 0 | 0 |\n",
       "| 3916406 | 386 | Competitions | 0 | 2016-07-15 | 0 | NA | NA | 0 | 0 | 0 |\n",
       "| 3739829 | 387 | Discussion   | 0 | 2016-07-15 | 0 | NA | NA | 0 | 1 | 0 |\n",
       "\n"
      ],
      "text/plain": [
       "  Id      UserId AchievementType Tier TierAchievementDate Points CurrentRanking\n",
       "1 3739827 381    Scripts         1    2016-07-15          0      NA            \n",
       "2 3916403 383    Competitions    0    2016-07-15          0      NA            \n",
       "3 3916404 384    Competitions    0    2016-07-15          0      NA            \n",
       "4 3916405 385    Competitions    0    2016-07-15          0      NA            \n",
       "5 3916406 386    Competitions    0    2016-07-15          0      NA            \n",
       "6 3739829 387    Discussion      0    2016-07-15          0      NA            \n",
       "  HighestRanking TotalGold TotalSilver TotalBronze\n",
       "1 NA             0         0           0          \n",
       "2 NA             0         0           0          \n",
       "3 NA             0         0           0          \n",
       "4 NA             0         0           0          \n",
       "5 NA             0         0           0          \n",
       "6 NA             0         1           0          "
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    }
   ],
   "source": [
    "user_achievements %>% head"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 6,
   "id": "0a07e0ef",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-06-03T13:57:23.488836Z",
     "iopub.status.busy": "2025-06-03T13:57:23.487576Z",
     "iopub.status.idle": "2025-06-03T13:57:23.525928Z",
     "shell.execute_reply": "2025-06-03T13:57:23.524254Z"
    },
    "papermill": {
     "duration": 0.046202,
     "end_time": "2025-06-03T13:57:23.527924",
     "exception": false,
     "start_time": "2025-06-03T13:57:23.481722",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "data": {
      "text/html": [
       "<table class=\"dataframe\">\n",
       "<caption>A tibble: 6 × 11</caption>\n",
       "<thead>\n",
       "\t<tr><th scope=col>Id</th><th scope=col>UserId</th><th scope=col>AchievementType</th><th scope=col>Tier</th><th scope=col>TierAchievementDate</th><th scope=col>Points</th><th scope=col>CurrentRanking</th><th scope=col>HighestRanking</th><th scope=col>TotalGold</th><th scope=col>TotalSilver</th><th scope=col>TotalBronze</th></tr>\n",
       "\t<tr><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;chr&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;date&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th></tr>\n",
       "</thead>\n",
       "<tbody>\n",
       "\t<tr><td>235114068</td><td>27198929</td><td>Scripts     </td><td>0</td><td>2025-06-03</td><td>0</td><td>NA</td><td>NA</td><td>0</td><td>0</td><td>0</td></tr>\n",
       "\t<tr><td>235114067</td><td>27198929</td><td>Competitions</td><td>0</td><td>2025-06-03</td><td>0</td><td>NA</td><td>NA</td><td>0</td><td>0</td><td>0</td></tr>\n",
       "\t<tr><td>235114070</td><td>27198929</td><td>Datasets    </td><td>0</td><td>2025-06-03</td><td>0</td><td>NA</td><td>NA</td><td>0</td><td>0</td><td>0</td></tr>\n",
       "\t<tr><td>235114076</td><td>27198931</td><td>Scripts     </td><td>0</td><td>2025-06-03</td><td>0</td><td>NA</td><td>NA</td><td>0</td><td>0</td><td>0</td></tr>\n",
       "\t<tr><td>235114075</td><td>27198931</td><td>Competitions</td><td>0</td><td>2025-06-03</td><td>0</td><td>NA</td><td>NA</td><td>0</td><td>0</td><td>0</td></tr>\n",
       "\t<tr><td>235114078</td><td>27198931</td><td>Datasets    </td><td>0</td><td>2025-06-03</td><td>0</td><td>NA</td><td>NA</td><td>0</td><td>0</td><td>0</td></tr>\n",
       "</tbody>\n",
       "</table>\n"
      ],
      "text/latex": [
       "A tibble: 6 × 11\n",
       "\\begin{tabular}{lllllllllll}\n",
       " Id & UserId & AchievementType & Tier & TierAchievementDate & Points & CurrentRanking & HighestRanking & TotalGold & TotalSilver & TotalBronze\\\\\n",
       " <dbl> & <dbl> & <chr> & <dbl> & <date> & <dbl> & <dbl> & <dbl> & <dbl> & <dbl> & <dbl>\\\\\n",
       "\\hline\n",
       "\t 235114068 & 27198929 & Scripts      & 0 & 2025-06-03 & 0 & NA & NA & 0 & 0 & 0\\\\\n",
       "\t 235114067 & 27198929 & Competitions & 0 & 2025-06-03 & 0 & NA & NA & 0 & 0 & 0\\\\\n",
       "\t 235114070 & 27198929 & Datasets     & 0 & 2025-06-03 & 0 & NA & NA & 0 & 0 & 0\\\\\n",
       "\t 235114076 & 27198931 & Scripts      & 0 & 2025-06-03 & 0 & NA & NA & 0 & 0 & 0\\\\\n",
       "\t 235114075 & 27198931 & Competitions & 0 & 2025-06-03 & 0 & NA & NA & 0 & 0 & 0\\\\\n",
       "\t 235114078 & 27198931 & Datasets     & 0 & 2025-06-03 & 0 & NA & NA & 0 & 0 & 0\\\\\n",
       "\\end{tabular}\n"
      ],
      "text/markdown": [
       "\n",
       "A tibble: 6 × 11\n",
       "\n",
       "| Id &lt;dbl&gt; | UserId &lt;dbl&gt; | AchievementType &lt;chr&gt; | Tier &lt;dbl&gt; | TierAchievementDate &lt;date&gt; | Points &lt;dbl&gt; | CurrentRanking &lt;dbl&gt; | HighestRanking &lt;dbl&gt; | TotalGold &lt;dbl&gt; | TotalSilver &lt;dbl&gt; | TotalBronze &lt;dbl&gt; |\n",
       "|---|---|---|---|---|---|---|---|---|---|---|\n",
       "| 235114068 | 27198929 | Scripts      | 0 | 2025-06-03 | 0 | NA | NA | 0 | 0 | 0 |\n",
       "| 235114067 | 27198929 | Competitions | 0 | 2025-06-03 | 0 | NA | NA | 0 | 0 | 0 |\n",
       "| 235114070 | 27198929 | Datasets     | 0 | 2025-06-03 | 0 | NA | NA | 0 | 0 | 0 |\n",
       "| 235114076 | 27198931 | Scripts      | 0 | 2025-06-03 | 0 | NA | NA | 0 | 0 | 0 |\n",
       "| 235114075 | 27198931 | Competitions | 0 | 2025-06-03 | 0 | NA | NA | 0 | 0 | 0 |\n",
       "| 235114078 | 27198931 | Datasets     | 0 | 2025-06-03 | 0 | NA | NA | 0 | 0 | 0 |\n",
       "\n"
      ],
      "text/plain": [
       "  Id        UserId   AchievementType Tier TierAchievementDate Points\n",
       "1 235114068 27198929 Scripts         0    2025-06-03          0     \n",
       "2 235114067 27198929 Competitions    0    2025-06-03          0     \n",
       "3 235114070 27198929 Datasets        0    2025-06-03          0     \n",
       "4 235114076 27198931 Scripts         0    2025-06-03          0     \n",
       "5 235114075 27198931 Competitions    0    2025-06-03          0     \n",
       "6 235114078 27198931 Datasets        0    2025-06-03          0     \n",
       "  CurrentRanking HighestRanking TotalGold TotalSilver TotalBronze\n",
       "1 NA             NA             0         0           0          \n",
       "2 NA             NA             0         0           0          \n",
       "3 NA             NA             0         0           0          \n",
       "4 NA             NA             0         0           0          \n",
       "5 NA             NA             0         0           0          \n",
       "6 NA             NA             0         0           0          "
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    }
   ],
   "source": [
    "user_achievements %>% tail"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "8f8de132",
   "metadata": {
    "papermill": {
     "duration": 0.004308,
     "end_time": "2025-06-03T13:57:23.536535",
     "exception": false,
     "start_time": "2025-06-03T13:57:23.532227",
     "status": "completed"
    },
    "tags": []
   },
   "source": [
    "This is how data looks like for a specific user (me)\n",
    "\n",
    "Unfortunately, we only have one data point per user/category. This means we cannot track the full progression, e.g. from rank 0 to rank 1, then rank 1 to rank 2, because the data is not tracked. "
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 7,
   "id": "d5e3c936",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-06-03T13:57:23.547762Z",
     "iopub.status.busy": "2025-06-03T13:57:23.546173Z",
     "iopub.status.idle": "2025-06-03T13:57:25.735557Z",
     "shell.execute_reply": "2025-06-03T13:57:25.731589Z"
    },
    "papermill": {
     "duration": 2.199052,
     "end_time": "2025-06-03T13:57:25.739649",
     "exception": false,
     "start_time": "2025-06-03T13:57:23.540597",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "data": {
      "text/html": [
       "<table class=\"dataframe\">\n",
       "<caption>A spec_tbl_df: 1 × 7</caption>\n",
       "<thead>\n",
       "\t<tr><th scope=col>Id</th><th scope=col>UserName</th><th scope=col>DisplayName</th><th scope=col>RegisterDate</th><th scope=col>PerformanceTier</th><th scope=col>Country</th><th scope=col>LocationSharingOptOut</th></tr>\n",
       "\t<tr><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;chr&gt;</th><th scope=col>&lt;chr&gt;</th><th scope=col>&lt;date&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;chr&gt;</th><th scope=col>&lt;lgl&gt;</th></tr>\n",
       "</thead>\n",
       "<tbody>\n",
       "\t<tr><td>650</td><td>dalloliogm</td><td>Giovanni Marco Dall'Olio</td><td>2010-04-29</td><td>2</td><td>United Kingdom</td><td>FALSE</td></tr>\n",
       "</tbody>\n",
       "</table>\n"
      ],
      "text/latex": [
       "A spec\\_tbl\\_df: 1 × 7\n",
       "\\begin{tabular}{lllllll}\n",
       " Id & UserName & DisplayName & RegisterDate & PerformanceTier & Country & LocationSharingOptOut\\\\\n",
       " <dbl> & <chr> & <chr> & <date> & <dbl> & <chr> & <lgl>\\\\\n",
       "\\hline\n",
       "\t 650 & dalloliogm & Giovanni Marco Dall'Olio & 2010-04-29 & 2 & United Kingdom & FALSE\\\\\n",
       "\\end{tabular}\n"
      ],
      "text/markdown": [
       "\n",
       "A spec_tbl_df: 1 × 7\n",
       "\n",
       "| Id &lt;dbl&gt; | UserName &lt;chr&gt; | DisplayName &lt;chr&gt; | RegisterDate &lt;date&gt; | PerformanceTier &lt;dbl&gt; | Country &lt;chr&gt; | LocationSharingOptOut &lt;lgl&gt; |\n",
       "|---|---|---|---|---|---|---|\n",
       "| 650 | dalloliogm | Giovanni Marco Dall'Olio | 2010-04-29 | 2 | United Kingdom | FALSE |\n",
       "\n"
      ],
      "text/plain": [
       "  Id  UserName   DisplayName              RegisterDate PerformanceTier\n",
       "1 650 dalloliogm Giovanni Marco Dall'Olio 2010-04-29   2              \n",
       "  Country        LocationSharingOptOut\n",
       "1 United Kingdom FALSE                "
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    },
    {
     "data": {
      "text/html": [
       "<table class=\"dataframe\">\n",
       "<caption>A spec_tbl_df: 4 × 11</caption>\n",
       "<thead>\n",
       "\t<tr><th scope=col>Id</th><th scope=col>UserId</th><th scope=col>AchievementType</th><th scope=col>Tier</th><th scope=col>TierAchievementDate</th><th scope=col>Points</th><th scope=col>CurrentRanking</th><th scope=col>HighestRanking</th><th scope=col>TotalGold</th><th scope=col>TotalSilver</th><th scope=col>TotalBronze</th></tr>\n",
       "\t<tr><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;chr&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;date&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th></tr>\n",
       "</thead>\n",
       "<tbody>\n",
       "\t<tr><td>  3916583</td><td>650</td><td>Competitions</td><td>1</td><td>2025-01-15</td><td>423</td><td> NA</td><td> NA</td><td>0</td><td>0</td><td> 0</td></tr>\n",
       "\t<tr><td>  4495800</td><td>650</td><td>Scripts     </td><td>2</td><td>2025-03-29</td><td>177</td><td>624</td><td>620</td><td>0</td><td>1</td><td>15</td></tr>\n",
       "\t<tr><td>  5075581</td><td>650</td><td>Discussion  </td><td>2</td><td>2025-05-08</td><td>116</td><td>555</td><td>555</td><td>0</td><td>2</td><td>74</td></tr>\n",
       "\t<tr><td>138387028</td><td>650</td><td>Datasets    </td><td>1</td><td>2025-01-15</td><td>  3</td><td> NA</td><td> NA</td><td>0</td><td>0</td><td> 0</td></tr>\n",
       "</tbody>\n",
       "</table>\n"
      ],
      "text/latex": [
       "A spec\\_tbl\\_df: 4 × 11\n",
       "\\begin{tabular}{lllllllllll}\n",
       " Id & UserId & AchievementType & Tier & TierAchievementDate & Points & CurrentRanking & HighestRanking & TotalGold & TotalSilver & TotalBronze\\\\\n",
       " <dbl> & <dbl> & <chr> & <dbl> & <date> & <dbl> & <dbl> & <dbl> & <dbl> & <dbl> & <dbl>\\\\\n",
       "\\hline\n",
       "\t   3916583 & 650 & Competitions & 1 & 2025-01-15 & 423 &  NA &  NA & 0 & 0 &  0\\\\\n",
       "\t   4495800 & 650 & Scripts      & 2 & 2025-03-29 & 177 & 624 & 620 & 0 & 1 & 15\\\\\n",
       "\t   5075581 & 650 & Discussion   & 2 & 2025-05-08 & 116 & 555 & 555 & 0 & 2 & 74\\\\\n",
       "\t 138387028 & 650 & Datasets     & 1 & 2025-01-15 &   3 &  NA &  NA & 0 & 0 &  0\\\\\n",
       "\\end{tabular}\n"
      ],
      "text/markdown": [
       "\n",
       "A spec_tbl_df: 4 × 11\n",
       "\n",
       "| Id &lt;dbl&gt; | UserId &lt;dbl&gt; | AchievementType &lt;chr&gt; | Tier &lt;dbl&gt; | TierAchievementDate &lt;date&gt; | Points &lt;dbl&gt; | CurrentRanking &lt;dbl&gt; | HighestRanking &lt;dbl&gt; | TotalGold &lt;dbl&gt; | TotalSilver &lt;dbl&gt; | TotalBronze &lt;dbl&gt; |\n",
       "|---|---|---|---|---|---|---|---|---|---|---|\n",
       "|   3916583 | 650 | Competitions | 1 | 2025-01-15 | 423 |  NA |  NA | 0 | 0 |  0 |\n",
       "|   4495800 | 650 | Scripts      | 2 | 2025-03-29 | 177 | 624 | 620 | 0 | 1 | 15 |\n",
       "|   5075581 | 650 | Discussion   | 2 | 2025-05-08 | 116 | 555 | 555 | 0 | 2 | 74 |\n",
       "| 138387028 | 650 | Datasets     | 1 | 2025-01-15 |   3 |  NA |  NA | 0 | 0 |  0 |\n",
       "\n"
      ],
      "text/plain": [
       "  Id        UserId AchievementType Tier TierAchievementDate Points\n",
       "1   3916583 650    Competitions    1    2025-01-15          423   \n",
       "2   4495800 650    Scripts         2    2025-03-29          177   \n",
       "3   5075581 650    Discussion      2    2025-05-08          116   \n",
       "4 138387028 650    Datasets        1    2025-01-15            3   \n",
       "  CurrentRanking HighestRanking TotalGold TotalSilver TotalBronze\n",
       "1  NA             NA            0         0            0         \n",
       "2 624            620            0         1           15         \n",
       "3 555            555            0         2           74         \n",
       "4  NA             NA            0         0            0         "
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    }
   ],
   "source": [
    "# This is me\n",
    "users %>% filter(Id == 650)\n",
    "user_achievements %>% filter(UserId==650)"
   ]
  },
  {
   "cell_type": "markdown",
   "id": "18a4460d",
   "metadata": {
    "papermill": {
     "duration": 0.004645,
     "end_time": "2025-06-03T13:57:25.751776",
     "exception": false,
     "start_time": "2025-06-03T13:57:25.747131",
     "status": "completed"
    },
    "tags": []
   },
   "source": [
    "## Calculating Time to Current rank"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 8,
   "id": "bfed4fb4",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-06-03T13:57:25.764985Z",
     "iopub.status.busy": "2025-06-03T13:57:25.763054Z",
     "iopub.status.idle": "2025-06-03T13:58:20.739152Z",
     "shell.execute_reply": "2025-06-03T13:58:20.734729Z"
    },
    "papermill": {
     "duration": 54.987293,
     "end_time": "2025-06-03T13:58:20.743736",
     "exception": false,
     "start_time": "2025-06-03T13:57:25.756443",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [],
   "source": [
    "user_achievements = user_achievements %>%\n",
    "    left_join(\n",
    "        users %>% select(Id, RegisterDate, PerformanceTier), \n",
    "        by = join_by(Id)\n",
    "    ) %>% \n",
    "    mutate(achievement_delay = TierAchievementDate - RegisterDate ) "
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 9,
   "id": "b0d3e322",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-06-03T13:58:20.756476Z",
     "iopub.status.busy": "2025-06-03T13:58:20.755289Z",
     "iopub.status.idle": "2025-06-03T14:01:26.625120Z",
     "shell.execute_reply": "2025-06-03T14:01:26.623434Z"
    },
    "papermill": {
     "duration": 185.878637,
     "end_time": "2025-06-03T14:01:26.628231",
     "exception": false,
     "start_time": "2025-06-03T13:58:20.749594",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [],
   "source": [
    "time_to_current_rank = user_achievements %>%\n",
    "    filter(Tier == PerformanceTier) %>%\n",
    "    group_by(UserId, PerformanceTier) %>%\n",
    "    summarise(time_to_current_tier = min(achievement_delay))"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 10,
   "id": "67ffa09a",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-06-03T14:01:26.648641Z",
     "iopub.status.busy": "2025-06-03T14:01:26.647400Z",
     "iopub.status.idle": "2025-06-03T14:01:26.717446Z",
     "shell.execute_reply": "2025-06-03T14:01:26.715714Z"
    },
    "papermill": {
     "duration": 0.082201,
     "end_time": "2025-06-03T14:01:26.719647",
     "exception": false,
     "start_time": "2025-06-03T14:01:26.637446",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [],
   "source": [
    "my_tier <- time_to_current_rank %>%\n",
    "  filter(UserId == 650) %>%\n",
    "  select(PerformanceTier, time_to_current_tier)"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 11,
   "id": "ae56e960",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-06-03T14:01:26.732578Z",
     "iopub.status.busy": "2025-06-03T14:01:26.731123Z",
     "iopub.status.idle": "2025-06-03T14:01:28.618427Z",
     "shell.execute_reply": "2025-06-03T14:01:28.616597Z"
    },
    "papermill": {
     "duration": 1.895791,
     "end_time": "2025-06-03T14:01:28.620637",
     "exception": false,
     "start_time": "2025-06-03T14:01:26.724846",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [],
   "source": [
    "tier_labels <- c(\n",
    "  \"0\" = \"Novice\",\n",
    "  \"1\" = \"Contributor\",\n",
    "  \"2\" = \"Expert\",\n",
    "  \"3\" = \"Master\",\n",
    "  \"4\" = \"Grandmaster\"\n",
    ")\n",
    "\n",
    "time_to_current_rank <- time_to_current_rank %>%\n",
    "  mutate(\n",
    "    PerformanceTier = factor(\n",
    "      as.character(PerformanceTier),\n",
    "      levels = names(tier_labels),\n",
    "      labels = tier_labels\n",
    "    )\n",
    "  )\n"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 12,
   "id": "01aefc4e",
   "metadata": {
    "execution": {
     "iopub.execute_input": "2025-06-03T14:01:28.633255Z",
     "iopub.status.busy": "2025-06-03T14:01:28.631808Z",
     "iopub.status.idle": "2025-06-03T14:01:33.271022Z",
     "shell.execute_reply": "2025-06-03T14:01:33.269402Z"
    },
    "papermill": {
     "duration": 4.647915,
     "end_time": "2025-06-03T14:01:33.273437",
     "exception": false,
     "start_time": "2025-06-03T14:01:28.625522",
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
      "“\u001b[1m\u001b[22mUsing `size` aesthetic for lines was deprecated in ggplot2 3.4.0.\n",
      "\u001b[36mℹ\u001b[39m Please use `linewidth` instead.”\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "Warning message:\n",
      "“\u001b[1m\u001b[22mCombining variables of class <factor> and <numeric> was deprecated in ggplot2\n",
      "3.4.0.\n",
      "\u001b[36mℹ\u001b[39m Please ensure your variables are compatible before plotting (location:\n",
      "  `combine_vars()`)”\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "Warning message:\n",
      "“\u001b[1m\u001b[22mCombining variables of class <numeric> and <factor> was deprecated in ggplot2\n",
      "3.4.0.\n",
      "\u001b[36mℹ\u001b[39m Please ensure your variables are compatible before plotting (location:\n",
      "  `combine_vars()`)”\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[1m\u001b[22mDon't know how to automatically pick scale for object of type \u001b[34m<difftime>\u001b[39m.\n",
      "Defaulting to continuous.\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "Warning message:\n",
      "“\u001b[1m\u001b[22mRemoved 161699 rows containing non-finite outside the scale range\n",
      "(`stat_bin()`).”\n"
     ]
    },
    {
     "data": {
      "image/png": "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"
     },
     "metadata": {
      "image/png": {
       "height": 480,
       "width": 720
      }
     },
     "output_type": "display_data"
    }
   ],
   "source": [
    "time_to_current_rank %>%\n",
    "  ggplot(aes(time_to_current_tier)) +\n",
    "  geom_histogram(binwidth = 100, fill = \"steelblue\", alpha = 0.7) +\n",
    "  geom_vline(\n",
    "    data = my_tier,\n",
    "    aes(xintercept = time_to_current_tier),\n",
    "    color = \"red\", linetype = \"dashed\", size = 1\n",
    "  ) +\n",
    "  facet_wrap(~PerformanceTier, scales = \"free_y\") +\n",
    "  labs(\n",
    "    title = \"Time to Reach Current Tier by Performance Tier\",\n",
    "    x = \"Days from Registration to Current Tier\",\n",
    "    y = \"Number of Users\"\n",
    "  ) +\n",
    "  theme_minimal()"
   ]
  }
 ],
 "metadata": {
  "kaggle": {
   "accelerator": "none",
   "dataSources": [
    {
     "databundleVersionId": 12488425,
     "isSourceIdPinned": false,
     "sourceId": 100890,
     "sourceType": "competition"
    },
    {
     "datasetId": 9,
     "sourceId": 12041385,
     "sourceType": "datasetVersion"
    },
    {
     "datasetId": 3240808,
     "sourceId": 11991932,
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
   "duration": 650.263865,
   "end_time": "2025-06-03T14:01:36.393733",
   "environment_variables": {},
   "exception": null,
   "input_path": "__notebook__.ipynb",
   "output_path": "__notebook__.ipynb",
   "parameters": {},
   "start_time": "2025-06-03T13:50:46.129868",
   "version": "2.6.0"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 5
}
