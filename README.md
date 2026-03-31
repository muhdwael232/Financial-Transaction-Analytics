# Financial Transaction Analytics
> End-to-end analytics pipeline: Python EDA & cleaning → MySQL → Power BI dashboard with DAX. Analyzes 1,000 financial transactions across 4 account types (2025–2027). Key insights on failure rates, revenue trends, profit margins & data quality.

![Power BI Dashboard](dashboard_screenshot.png)

---

## Table of Contents
- [Project Overview](#project-overview)
- [Dataset](#dataset)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Analytics Pipeline](#analytics-pipeline)
- [Dashboard](#dashboard)
- [Key Insights](#key-insights)
- [Business Recommendations](#business-recommendations)
- [How to Run](#how-to-run)
- [Author](#author)

---

## Project Overview

This project simulates a real-world data analyst workflow — taking raw financial transaction data from a CSV file all the way through to an interactive Power BI dashboard and business report.

The goal is to evaluate financial software effectiveness by analyzing transaction processing quality, profitability, and operational performance across four account types over a three-year period.

---

## Dataset

| Property | Detail |
|---|---|
| Source | Simulated accounting dataset (Kaggle) |
| Rows | 1,000 transactions |
| Columns | 18 features |
| Date range | 2025-01-01 → 2027-09-27 |
| Account types | Asset (255) · Expense (257) · Liability (250) · Revenue (238) |
| Target variable | `Transaction_Outcome` (1 = Success, 0 = Failure) |

### Features

| Column | Description |
|---|---|
| `Transaction_ID` | Unique identifier |
| `Date` | Transaction date |
| `Account_Type` | Asset / Expense / Liability / Revenue |
| `Transaction_Amount` | Amount involved (106–4,998) |
| `Cash_Flow` | Cash flow value |
| `Net_Income` | Net income generated |
| `Revenue` | Total revenue |
| `Expenditure` | Total costs |
| `Profit_Margin` | Margin as decimal (0.2–0.8) |
| `Debt_to_Equity_Ratio` | Financial leverage ratio (0.5–3.0) |
| `Operating_Expenses` | Direct and indirect costs |
| `Gross_Profit` | Revenue minus direct costs |
| `Transaction_Volume` | Number of transactions processed |
| `Processing_Time_seconds` | Time to process each transaction |
| `Accuracy_Score` | Processing system accuracy |
| `Missing_Data_Indicator` | Flag for missing values (True/False) |
| `Normalized_Transaction_Amount` | Min-max scaled amount |
| `Transaction_Outcome` | Success = 1, Failure = 0 |

---

## Tech Stack

| Stage | Tool |
|---|---|
| EDA & cleaning | Python · pandas · matplotlib · seaborn |
| Database | MySQL · SQLAlchemy · pymysql |
| Dashboard | Power BI Desktop |
| Measures | DAX |
| Version control | Git · GitHub |

---

## Project Structure

```
financial-transaction-analytics/
│
├── data/
│   ├── accounting_data.csv          # Raw dataset
│   └── accounting_clean.csv         # Cleaned dataset (output of cleaning script)
│
├── notebooks/
│   ├── accounting_eda.py            # EDA script — generates 10 charts
│   └── eda_report/                  # Output folder for EDA charts
│       ├── 01_distributions.png
│       ├── 02_account_types.png
│       ├── 03_monthly_cashflow.png
│       ├── 04_profit_margin_by_type.png
│       ├── 05_revenue_vs_expenditure.png
│       ├── 06_outcome_by_type.png
│       ├── 07_correlation_heatmap.png
│       ├── 08_operational_metrics.png
│       ├── 09_de_ratio_trend.png
│       └── 10_data_quality.png
│
├── sql/
│   └── analysis_queries.sql         # 17 SQL analysis queries
│
├── powerbi/
│   └── financial_transaction_analytics_dashboard.pbix
│
├── dashboard_screenshot.png         # Dashboard preview image
└── README.md
```

---

## Analytics Pipeline

### Step 1 — Exploratory Data Analysis

Ran a full EDA to understand distributions, correlations, and data quality before any cleaning.

```python
# Key libraries
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

df = pd.read_csv('data/accounting_data.csv')
print(df.shape)        # (1000, 18)
print(df.isnull().sum()) # No null values — but 48 rows flagged via Missing_Data_Indicator
```

**Output:** 10 charts covering distributions, time trends, correlation heatmap, and data quality flags. See `notebooks/eda_report/`.

---

### Step 2 — Data Cleaning

```python
# Rename columns (snake_case, no spaces)
df.columns = [c.strip().replace(' ', '_').replace('(','').replace(')','')
              for c in df.columns]

# Parse dates and extract time dimensions
df['Date']      = pd.to_datetime(df['Date'])
df['Month']     = df['Date'].dt.strftime('%B')   # January, February...
df['Quarter']   = df['Date'].dt.quarter          # 1, 2, 3, 4
df['Year']      = df['Date'].dt.year             # 2025, 2026, 2027
df['Month_Num'] = df['Date'].dt.month            # for Power BI sort order
df['DayOfWeek'] = df['Date'].dt.day_name()

# Derived KPI columns
df['Net_Profit']   = df['Revenue'] - df['Expenditure']
df['OpEx_Ratio']   = (df['Operating_Expenses'] / df['Revenue']).round(4)
df['Success_Flag'] = df['Transaction_Outcome'].map({1: 'Success', 0: 'Failure'})

# Validate
assert (df['Transaction_Amount'] >= 0).all()

df.to_csv('data/accounting_clean.csv', index=False)
```

---

### Step 3 — MySQL Load

```python
from sqlalchemy import create_engine
from urllib.parse import quote_plus

password = quote_plus("your_password")  # handles special characters in password
engine = create_engine(
    f'mysql+pymysql://root:{password}@localhost:3306/accounting_db'
)

df.to_sql('transactions', con=engine, if_exists='replace',
          index=False, chunksize=500)
```

> **Note:** Use `quote_plus()` if your MySQL password contains special characters like `@`.

---

### Step 4 — Power BI Dashboard

**Connection:** Home → Get Data → MySQL database → `localhost` / `accounting_db`

**Key DAX Measures:**

```dax
-- Success rate (stored as decimal, displayed as percentage)
Success Rate % =
DIVIDE(
    COUNTROWS(FILTER(transactions, transactions[Transaction_Outcome] = 1)),
    COUNTROWS(transactions), 0
)

-- Average profit margin percentage
Avg Profit Margin % = AVERAGE(transactions[Profit_Margin]) * 100

-- Month-over-month revenue growth
Revenue Growth % =
VAR CurrentRevenue = CALCULATE(SUM(transactions[Revenue]))
VAR PreviousRevenue = CALCULATE(
    SUM(transactions[Revenue]),
    DATEADD('Date Table'[Date], -1, YEAR)
)
RETURN ROUND(DIVIDE(CurrentRevenue - PreviousRevenue, PreviousRevenue, 0) * 100, 1)

-- Missing data count
Missing Rows = COUNTROWS(FILTER(transactions, transactions[Missing_Data_Indicator] = 1))
```

**Sort fix for Month column:**
- Create `Month_Sort = transactions[Year] * 100 + transactions[Month_Num]`
- Column tools → Sort by column → `Month_Sort`

---

### Step 5 — Dashboard Visuals

| Visual | Fields | Purpose |
|---|---|---|
| KPI cards (×5) | Revenue, Transactions, Profit Margin, Success Rate, Missing Flags | Executive summary |
| Line chart | Month_Year → Avg Cash Flow | Cash flow trend over time |
| Donut chart | Account_Type → Count | Portfolio composition |
| Bar chart | Account_Type → Avg Profit Margin | Profitability by type |
| Scatter plot | Revenue vs Expenditure, Legend: Account_Type | Break-even analysis |
| Gauge | Success Rate % (Min: 0, Max: 1, Target: 0.98) | Performance vs target |
| Histogram | Processing_Time_seconds (bins: 0.2) → Count | Processing distribution |
| Slicers (×3) | Account_Type · Year · Success_Flag | Cross-page filtering |

---

## Dashboard

![Dashboard](dashboard_screenshot.png)

The dashboard is a single-page layout designed for 1280×720px canvas. All 8 visuals cross-filter through 3 slicers — Account Type, Year, and Outcome.

---

## Key Insights

| # | Insight | Finding |
|---|---|---|
| 1 | Revenue declining YoY | $964K (2025) → $947K (2026) → $699K (2027 partial) |
| 2 | Expense failure rate | 6.61% — double the portfolio average |
| 3 | Profit margins healthy | All 4 types above 49%, spread only 1.76pp |
| 4 | Success rate below target | 95.1% vs 98% target — 49 failures |
| 5 | Processing time ≠ failures | Difference of 0.007s between failed and successful |
| 6 | Revenue data quality worst | 6.3% missing data rate — highest of any type |

---

## Business Recommendations

**High priority**
- Investigate the 17 failed Expense transactions — at 6.61% failure rate, identify patterns in Amount, D/E Ratio, and Date, then implement input validation rules. Target: below 3% within one quarter
- Fix missing data entry validation for Revenue transactions before the next reporting cycle — 15 incomplete records directly corrupt the $2.61M revenue figure

**Medium priority**
- Drill into Q1, Q2, Q3 2027 using the Quarter slicer to confirm whether the cash flow decline is seasonal or structural
- Set a formal D/E ratio cap policy — 41.7% of transactions exceed the 2.0 high-risk threshold

**Maintain**
- Profit margin controls are working — all types above 49%, no action needed
- Processing infrastructure is healthy — average 1.24s, no investment required

---

## How to Run

### Prerequisites

```bash
pip install pandas matplotlib seaborn sqlalchemy pymysql
```

MySQL 8.0+ with a local instance running on port 3306.

Power BI Desktop (free download from Microsoft).

### Steps

```bash
# 1. Clone the repo
git clone https://github.com/yourusername/financial-transaction-analytics.git
cd financial-transaction-analytics

# 2. Run EDA
python notebooks/accounting_eda.py
# Charts saved to notebooks/eda_report/

# 3. Run cleaning script
# (edit CSV_PATH inside the script if needed)
python notebooks/accounting_eda.py

# 4. Load to MySQL
# Update your MySQL password in the connection string, then run:
python notebooks/mysql_loader.py

# 5. Open Power BI
# Open powerbi/financial_transaction_analytics_dashboard.pbix
# Refresh the data source connection to your local MySQL
```

---

## Author

**freakwhale23**
- Built as a portfolio project to demonstrate end-to-end data analytics skills
- Open to data analyst opportunities — feel free to connect on LinkedIn

---

*Dataset source: Simulated financial transaction data for testing intelligent accounting models*
