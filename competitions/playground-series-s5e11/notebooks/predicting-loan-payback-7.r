{
 "cells": [
  {
   "cell_type": "code",
   "execution_count": 1,
   "id": "4c429e96",
   "metadata": {
    "_cell_guid": "b1076dfc-b9ad-4769-8c92-a6c4dae69d19",
    "_uuid": "8f2839f25d086af736a60e9eeb907d3b93b6e0e5",
    "execution": {
     "iopub.execute_input": "2025-11-18T21:01:48.480576Z",
     "iopub.status.busy": "2025-11-18T21:01:48.478115Z",
     "iopub.status.idle": "2025-11-18T21:01:50.239946Z",
     "shell.execute_reply": "2025-11-18T21:01:50.237940Z"
    },
    "papermill": {
     "duration": 1.76913,
     "end_time": "2025-11-18T21:01:50.242669",
     "exception": false,
     "start_time": "2025-11-18T21:01:48.473539",
     "status": "completed"
    },
    "tags": []
   },
   "outputs": [
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "R Version: R version 4.4.0 (2024-04-24) \n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[1mRows: \u001b[22m\u001b[34m254569\u001b[39m \u001b[1mColumns: \u001b[22m\u001b[34m2\u001b[39m\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[36m──\u001b[39m \u001b[1mColumn specification\u001b[22m \u001b[36m────────────────────────────────────────────────────────\u001b[39m\n",
      "\u001b[1mDelimiter:\u001b[22m \",\"\n",
      "\u001b[32mdbl\u001b[39m (2): id, loan_paid_back\n"
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
      "\u001b[1mRows: \u001b[22m\u001b[34m254569\u001b[39m \u001b[1mColumns: \u001b[22m\u001b[34m2\u001b[39m\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[36m──\u001b[39m \u001b[1mColumn specification\u001b[22m \u001b[36m────────────────────────────────────────────────────────\u001b[39m\n",
      "\u001b[1mDelimiter:\u001b[22m \",\"\n",
      "\u001b[32mdbl\u001b[39m (2): id, loan_paid_back\n"
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
      "\u001b[1mRows: \u001b[22m\u001b[34m254569\u001b[39m \u001b[1mColumns: \u001b[22m\u001b[34m2\u001b[39m\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[36m──\u001b[39m \u001b[1mColumn specification\u001b[22m \u001b[36m────────────────────────────────────────────────────────\u001b[39m\n",
      "\u001b[1mDelimiter:\u001b[22m \",\"\n",
      "\u001b[32mdbl\u001b[39m (2): id, loan_paid_back\n"
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
      "\u001b[1mRows: \u001b[22m\u001b[34m254569\u001b[39m \u001b[1mColumns: \u001b[22m\u001b[34m2\u001b[39m\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[36m──\u001b[39m \u001b[1mColumn specification\u001b[22m \u001b[36m────────────────────────────────────────────────────────\u001b[39m\n",
      "\u001b[1mDelimiter:\u001b[22m \",\"\n",
      "\u001b[32mdbl\u001b[39m (2): id, loan_paid_back\n"
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
      "\u001b[1mRows: \u001b[22m\u001b[34m254569\u001b[39m \u001b[1mColumns: \u001b[22m\u001b[34m2\u001b[39m\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[36m──\u001b[39m \u001b[1mColumn specification\u001b[22m \u001b[36m────────────────────────────────────────────────────────\u001b[39m\n",
      "\u001b[1mDelimiter:\u001b[22m \",\"\n",
      "\u001b[32mdbl\u001b[39m (2): id, loan_paid_back\n"
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
      "\u001b[1mRows: \u001b[22m\u001b[34m254569\u001b[39m \u001b[1mColumns: \u001b[22m\u001b[34m2\u001b[39m\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[36m──\u001b[39m \u001b[1mColumn specification\u001b[22m \u001b[36m────────────────────────────────────────────────────────\u001b[39m\n",
      "\u001b[1mDelimiter:\u001b[22m \",\"\n",
      "\u001b[32mdbl\u001b[39m (2): id, loan_paid_back\n"
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
      "\u001b[1mRows: \u001b[22m\u001b[34m254569\u001b[39m \u001b[1mColumns: \u001b[22m\u001b[34m2\u001b[39m\n"
     ]
    },
    {
     "name": "stderr",
     "output_type": "stream",
     "text": [
      "\u001b[36m──\u001b[39m \u001b[1mColumn specification\u001b[22m \u001b[36m────────────────────────────────────────────────────────\u001b[39m\n",
      "\u001b[1mDelimiter:\u001b[22m \",\"\n",
      "\u001b[32mdbl\u001b[39m (2): id, loan_paid_back\n"
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
     "data": {
      "text/html": [
       "<table class=\"dataframe\">\n",
       "<caption>A spec_tbl_df: 254569 × 2</caption>\n",
       "<thead>\n",
       "\t<tr><th scope=col>id</th><th scope=col>loan_paid_back</th></tr>\n",
       "\t<tr><th scope=col>&lt;dbl&gt;</th><th scope=col>&lt;dbl&gt;</th></tr>\n",
       "</thead>\n",
       "<tbody>\n",
       "\t<tr><td>593994</td><td>0.94922478</td></tr>\n",
       "\t<tr><td>593995</td><td>0.96922102</td></tr>\n",
       "\t<tr><td>593996</td><td>0.43959213</td></tr>\n",
       "\t<tr><td>593997</td><td>0.92476331</td></tr>\n",
       "\t<tr><td>593998</td><td>0.96864035</td></tr>\n",
       "\t<tr><td>593999</td><td>0.97117862</td></tr>\n",
       "\t<tr><td>594000</td><td>0.97485269</td></tr>\n",
       "\t<tr><td>594001</td><td>0.97381725</td></tr>\n",
       "\t<tr><td>594002</td><td>0.95477135</td></tr>\n",
       "\t<tr><td>594003</td><td>0.03758527</td></tr>\n",
       "\t<tr><td>594004</td><td>0.08720341</td></tr>\n",
       "\t<tr><td>594005</td><td>0.97857527</td></tr>\n",
       "\t<tr><td>594006</td><td>0.80247477</td></tr>\n",
       "\t<tr><td>594007</td><td>0.06619877</td></tr>\n",
       "\t<tr><td>594008</td><td>0.97317775</td></tr>\n",
       "\t<tr><td>594009</td><td>0.73425105</td></tr>\n",
       "\t<tr><td>594010</td><td>0.97918915</td></tr>\n",
       "\t<tr><td>594011</td><td>0.79104128</td></tr>\n",
       "\t<tr><td>594012</td><td>0.97619434</td></tr>\n",
       "\t<tr><td>594013</td><td>0.95749034</td></tr>\n",
       "\t<tr><td>594014</td><td>0.37025984</td></tr>\n",
       "\t<tr><td>594015</td><td>0.97686688</td></tr>\n",
       "\t<tr><td>594016</td><td>0.94459165</td></tr>\n",
       "\t<tr><td>594017</td><td>0.91469286</td></tr>\n",
       "\t<tr><td>594018</td><td>0.92958461</td></tr>\n",
       "\t<tr><td>594019</td><td>0.05280909</td></tr>\n",
       "\t<tr><td>594020</td><td>0.74377868</td></tr>\n",
       "\t<tr><td>594021</td><td>0.29584164</td></tr>\n",
       "\t<tr><td>594022</td><td>0.97171715</td></tr>\n",
       "\t<tr><td>594023</td><td>0.04798073</td></tr>\n",
       "\t<tr><td>⋮</td><td>⋮</td></tr>\n",
       "\t<tr><td>848533</td><td>0.96848817</td></tr>\n",
       "\t<tr><td>848534</td><td>0.92450930</td></tr>\n",
       "\t<tr><td>848535</td><td>0.97347591</td></tr>\n",
       "\t<tr><td>848536</td><td>0.97556372</td></tr>\n",
       "\t<tr><td>848537</td><td>0.35559553</td></tr>\n",
       "\t<tr><td>848538</td><td>0.97879326</td></tr>\n",
       "\t<tr><td>848539</td><td>0.17851335</td></tr>\n",
       "\t<tr><td>848540</td><td>0.82306221</td></tr>\n",
       "\t<tr><td>848541</td><td>0.86432403</td></tr>\n",
       "\t<tr><td>848542</td><td>0.98088301</td></tr>\n",
       "\t<tr><td>848543</td><td>0.04240245</td></tr>\n",
       "\t<tr><td>848544</td><td>0.23133254</td></tr>\n",
       "\t<tr><td>848545</td><td>0.91446791</td></tr>\n",
       "\t<tr><td>848546</td><td>0.96762052</td></tr>\n",
       "\t<tr><td>848547</td><td>0.14244036</td></tr>\n",
       "\t<tr><td>848548</td><td>0.91072266</td></tr>\n",
       "\t<tr><td>848549</td><td>0.89308673</td></tr>\n",
       "\t<tr><td>848550</td><td>0.96875674</td></tr>\n",
       "\t<tr><td>848551</td><td>0.97394092</td></tr>\n",
       "\t<tr><td>848552</td><td>0.96356159</td></tr>\n",
       "\t<tr><td>848553</td><td>0.95461749</td></tr>\n",
       "\t<tr><td>848554</td><td>0.95005396</td></tr>\n",
       "\t<tr><td>848555</td><td>0.97847199</td></tr>\n",
       "\t<tr><td>848556</td><td>0.67629820</td></tr>\n",
       "\t<tr><td>848557</td><td>0.96701533</td></tr>\n",
       "\t<tr><td>848558</td><td>0.97907286</td></tr>\n",
       "\t<tr><td>848559</td><td>0.85941446</td></tr>\n",
       "\t<tr><td>848560</td><td>0.94856363</td></tr>\n",
       "\t<tr><td>848561</td><td>0.97571573</td></tr>\n",
       "\t<tr><td>848562</td><td>0.95876568</td></tr>\n",
       "</tbody>\n",
       "</table>\n"
      ],
      "text/latex": [
       "A spec\\_tbl\\_df: 254569 × 2\n",
       "\\begin{tabular}{ll}\n",
       " id & loan\\_paid\\_back\\\\\n",
       " <dbl> & <dbl>\\\\\n",
       "\\hline\n",
       "\t 593994 & 0.94922478\\\\\n",
       "\t 593995 & 0.96922102\\\\\n",
       "\t 593996 & 0.43959213\\\\\n",
       "\t 593997 & 0.92476331\\\\\n",
       "\t 593998 & 0.96864035\\\\\n",
       "\t 593999 & 0.97117862\\\\\n",
       "\t 594000 & 0.97485269\\\\\n",
       "\t 594001 & 0.97381725\\\\\n",
       "\t 594002 & 0.95477135\\\\\n",
       "\t 594003 & 0.03758527\\\\\n",
       "\t 594004 & 0.08720341\\\\\n",
       "\t 594005 & 0.97857527\\\\\n",
       "\t 594006 & 0.80247477\\\\\n",
       "\t 594007 & 0.06619877\\\\\n",
       "\t 594008 & 0.97317775\\\\\n",
       "\t 594009 & 0.73425105\\\\\n",
       "\t 594010 & 0.97918915\\\\\n",
       "\t 594011 & 0.79104128\\\\\n",
       "\t 594012 & 0.97619434\\\\\n",
       "\t 594013 & 0.95749034\\\\\n",
       "\t 594014 & 0.37025984\\\\\n",
       "\t 594015 & 0.97686688\\\\\n",
       "\t 594016 & 0.94459165\\\\\n",
       "\t 594017 & 0.91469286\\\\\n",
       "\t 594018 & 0.92958461\\\\\n",
       "\t 594019 & 0.05280909\\\\\n",
       "\t 594020 & 0.74377868\\\\\n",
       "\t 594021 & 0.29584164\\\\\n",
       "\t 594022 & 0.97171715\\\\\n",
       "\t 594023 & 0.04798073\\\\\n",
       "\t ⋮ & ⋮\\\\\n",
       "\t 848533 & 0.96848817\\\\\n",
       "\t 848534 & 0.92450930\\\\\n",
       "\t 848535 & 0.97347591\\\\\n",
       "\t 848536 & 0.97556372\\\\\n",
       "\t 848537 & 0.35559553\\\\\n",
       "\t 848538 & 0.97879326\\\\\n",
       "\t 848539 & 0.17851335\\\\\n",
       "\t 848540 & 0.82306221\\\\\n",
       "\t 848541 & 0.86432403\\\\\n",
       "\t 848542 & 0.98088301\\\\\n",
       "\t 848543 & 0.04240245\\\\\n",
       "\t 848544 & 0.23133254\\\\\n",
       "\t 848545 & 0.91446791\\\\\n",
       "\t 848546 & 0.96762052\\\\\n",
       "\t 848547 & 0.14244036\\\\\n",
       "\t 848548 & 0.91072266\\\\\n",
       "\t 848549 & 0.89308673\\\\\n",
       "\t 848550 & 0.96875674\\\\\n",
       "\t 848551 & 0.97394092\\\\\n",
       "\t 848552 & 0.96356159\\\\\n",
       "\t 848553 & 0.95461749\\\\\n",
       "\t 848554 & 0.95005396\\\\\n",
       "\t 848555 & 0.97847199\\\\\n",
       "\t 848556 & 0.67629820\\\\\n",
       "\t 848557 & 0.96701533\\\\\n",
       "\t 848558 & 0.97907286\\\\\n",
       "\t 848559 & 0.85941446\\\\\n",
       "\t 848560 & 0.94856363\\\\\n",
       "\t 848561 & 0.97571573\\\\\n",
       "\t 848562 & 0.95876568\\\\\n",
       "\\end{tabular}\n"
      ],
      "text/markdown": [
       "\n",
       "A spec_tbl_df: 254569 × 2\n",
       "\n",
       "| id &lt;dbl&gt; | loan_paid_back &lt;dbl&gt; |\n",
       "|---|---|\n",
       "| 593994 | 0.94922478 |\n",
       "| 593995 | 0.96922102 |\n",
       "| 593996 | 0.43959213 |\n",
       "| 593997 | 0.92476331 |\n",
       "| 593998 | 0.96864035 |\n",
       "| 593999 | 0.97117862 |\n",
       "| 594000 | 0.97485269 |\n",
       "| 594001 | 0.97381725 |\n",
       "| 594002 | 0.95477135 |\n",
       "| 594003 | 0.03758527 |\n",
       "| 594004 | 0.08720341 |\n",
       "| 594005 | 0.97857527 |\n",
       "| 594006 | 0.80247477 |\n",
       "| 594007 | 0.06619877 |\n",
       "| 594008 | 0.97317775 |\n",
       "| 594009 | 0.73425105 |\n",
       "| 594010 | 0.97918915 |\n",
       "| 594011 | 0.79104128 |\n",
       "| 594012 | 0.97619434 |\n",
       "| 594013 | 0.95749034 |\n",
       "| 594014 | 0.37025984 |\n",
       "| 594015 | 0.97686688 |\n",
       "| 594016 | 0.94459165 |\n",
       "| 594017 | 0.91469286 |\n",
       "| 594018 | 0.92958461 |\n",
       "| 594019 | 0.05280909 |\n",
       "| 594020 | 0.74377868 |\n",
       "| 594021 | 0.29584164 |\n",
       "| 594022 | 0.97171715 |\n",
       "| 594023 | 0.04798073 |\n",
       "| ⋮ | ⋮ |\n",
       "| 848533 | 0.96848817 |\n",
       "| 848534 | 0.92450930 |\n",
       "| 848535 | 0.97347591 |\n",
       "| 848536 | 0.97556372 |\n",
       "| 848537 | 0.35559553 |\n",
       "| 848538 | 0.97879326 |\n",
       "| 848539 | 0.17851335 |\n",
       "| 848540 | 0.82306221 |\n",
       "| 848541 | 0.86432403 |\n",
       "| 848542 | 0.98088301 |\n",
       "| 848543 | 0.04240245 |\n",
       "| 848544 | 0.23133254 |\n",
       "| 848545 | 0.91446791 |\n",
       "| 848546 | 0.96762052 |\n",
       "| 848547 | 0.14244036 |\n",
       "| 848548 | 0.91072266 |\n",
       "| 848549 | 0.89308673 |\n",
       "| 848550 | 0.96875674 |\n",
       "| 848551 | 0.97394092 |\n",
       "| 848552 | 0.96356159 |\n",
       "| 848553 | 0.95461749 |\n",
       "| 848554 | 0.95005396 |\n",
       "| 848555 | 0.97847199 |\n",
       "| 848556 | 0.67629820 |\n",
       "| 848557 | 0.96701533 |\n",
       "| 848558 | 0.97907286 |\n",
       "| 848559 | 0.85941446 |\n",
       "| 848560 | 0.94856363 |\n",
       "| 848561 | 0.97571573 |\n",
       "| 848562 | 0.95876568 |\n",
       "\n"
      ],
      "text/plain": [
       "       id     loan_paid_back\n",
       "1      593994 0.94922478    \n",
       "2      593995 0.96922102    \n",
       "3      593996 0.43959213    \n",
       "4      593997 0.92476331    \n",
       "5      593998 0.96864035    \n",
       "6      593999 0.97117862    \n",
       "7      594000 0.97485269    \n",
       "8      594001 0.97381725    \n",
       "9      594002 0.95477135    \n",
       "10     594003 0.03758527    \n",
       "11     594004 0.08720341    \n",
       "12     594005 0.97857527    \n",
       "13     594006 0.80247477    \n",
       "14     594007 0.06619877    \n",
       "15     594008 0.97317775    \n",
       "16     594009 0.73425105    \n",
       "17     594010 0.97918915    \n",
       "18     594011 0.79104128    \n",
       "19     594012 0.97619434    \n",
       "20     594013 0.95749034    \n",
       "21     594014 0.37025984    \n",
       "22     594015 0.97686688    \n",
       "23     594016 0.94459165    \n",
       "24     594017 0.91469286    \n",
       "25     594018 0.92958461    \n",
       "26     594019 0.05280909    \n",
       "27     594020 0.74377868    \n",
       "28     594021 0.29584164    \n",
       "29     594022 0.97171715    \n",
       "30     594023 0.04798073    \n",
       "⋮      ⋮      ⋮             \n",
       "254540 848533 0.96848817    \n",
       "254541 848534 0.92450930    \n",
       "254542 848535 0.97347591    \n",
       "254543 848536 0.97556372    \n",
       "254544 848537 0.35559553    \n",
       "254545 848538 0.97879326    \n",
       "254546 848539 0.17851335    \n",
       "254547 848540 0.82306221    \n",
       "254548 848541 0.86432403    \n",
       "254549 848542 0.98088301    \n",
       "254550 848543 0.04240245    \n",
       "254551 848544 0.23133254    \n",
       "254552 848545 0.91446791    \n",
       "254553 848546 0.96762052    \n",
       "254554 848547 0.14244036    \n",
       "254555 848548 0.91072266    \n",
       "254556 848549 0.89308673    \n",
       "254557 848550 0.96875674    \n",
       "254558 848551 0.97394092    \n",
       "254559 848552 0.96356159    \n",
       "254560 848553 0.95461749    \n",
       "254561 848554 0.95005396    \n",
       "254562 848555 0.97847199    \n",
       "254563 848556 0.67629820    \n",
       "254564 848557 0.96701533    \n",
       "254565 848558 0.97907286    \n",
       "254566 848559 0.85941446    \n",
       "254567 848560 0.94856363    \n",
       "254568 848561 0.97571573    \n",
       "254569 848562 0.95876568    "
      ]
     },
     "metadata": {},
     "output_type": "display_data"
    }
   ],
   "source": [
    "cat(\"R Version:\", R.version.string, \"\\n\")\n",
    "\n",
    "library(readr)\n",
    "\n",
    "df <- read_csv('/kaggle/input/playground-series-s5e11/sample_submission.csv')\n",
    "\n",
    "t <- 'loan_paid_back'\n",
    "\n",
    "sub_1 <- read_csv('/kaggle/input/predicting-loan-payback/submission1.csv')[[t]]\n",
    "sub_2 <- read_csv('/kaggle/input/predicting-loan-payback/submission2.csv')[[t]]\n",
    "sub_3 <- read_csv('/kaggle/input/predicting-loan-payback/submission3.csv')[[t]]\n",
    "sub_4 <- read_csv('/kaggle/input/predicting-loan-payback/submission4.csv')[[t]]\n",
    "sub_5 <- read_csv('/kaggle/input/predicting-loan-payback/submission5.csv')[[t]]\n",
    "sub_6 <- read_csv('/kaggle/input/predicting-loan-payback/submission6.csv')[[t]]\n",
    "\n",
    "df[[t]] <- sub_1 * 0.99 + sub_2 * 0.002 + sub_3 * 0.002 + sub_4 * 0.002 + sub_5 * 0.002 + sub_6 * 0.002\n",
    "\n",
    "write_csv(df, 'submission.csv')\n",
    "\n",
    "df"
   ]
  }
 ],
 "metadata": {
  "kaggle": {
   "accelerator": "none",
   "dataSources": [
    {
     "databundleVersionId": 14262372,
     "sourceId": 91722,
     "sourceType": "competition"
    },
    {
     "datasetId": 8760583,
     "sourceId": 13765664,
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
   "duration": 5.191656,
   "end_time": "2025-11-18T21:01:50.367616",
   "environment_variables": {},
   "exception": null,
   "input_path": "__notebook__.ipynb",
   "output_path": "__notebook__.ipynb",
   "parameters": {},
   "start_time": "2025-11-18T21:01:45.175960",
   "version": "2.6.0"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 5
}
