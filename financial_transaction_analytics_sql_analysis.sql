-- Revenue, expenditure & net profit by account type
-- Core P&L summary grouped by account type — good for the KPI overview page.
SELECT
    Account_Type,
    COUNT(*)                        AS transaction_count,
    SUM(Revenue)                    AS total_revenue,
    SUM(Expenditure)                AS total_expenditure,
    SUM(Revenue - Expenditure)      AS net_profit,
    ROUND(AVG(Profit_Margin)*100,2) AS avg_profit_margin_pct,
    ROUND(AVG(Gross_Profit),0)      AS avg_gross_profit
FROM transactions
GROUP BY Account_Type
ORDER BY net_profit DESC;

-- Top 10 most profitable transactions
-- Identify the highest net-profit individual transactions
SELECT
    Transaction_ID,
    Date,
    Account_Type,
    Revenue,
    Expenditure,
    (Revenue - Expenditure)        AS net_profit,
    ROUND(Profit_Margin * 100, 2)  AS profit_margin_pct
FROM transactions
ORDER BY net_profit DESC
LIMIT 10;

-- Profit margin distribution buckets
-- See how transactions are spread across margin bands — useful for a histogram in Power BI
SELECT
    CASE
        WHEN Profit_Margin < 0.30 THEN '< 30%'
        WHEN Profit_Margin < 0.50 THEN '30–50%'
        WHEN Profit_Margin < 0.70 THEN '50–70%'
        ELSE '70%+'
    END AS margin_band,
    COUNT(*) AS transactions,
    ROUND(AVG(Profit_Margin)*100,2) AS avg_margin_pct
FROM transactions
GROUP BY margin_band
ORDER BY MIN(Profit_Margin);

-- Monthly revenue & cash flow trend
-- Month-over-month totals for the trend line chart in Power BI
SELECT
    Year,
    Month,
    COUNT(*)               AS transactions,
    SUM(Revenue)           AS total_revenue,
    SUM(Cash_Flow)         AS total_cash_flow,
    SUM(Net_Income)        AS total_net_income,
    ROUND(AVG(Profit_Margin)*100,2) AS avg_margin_pct
FROM transactions
GROUP BY Year, Month
ORDER BY Year, MIN(Date);

-- Quarterly performance summary
-- Quarter-level rollup — maps directly to your Quarter slicer in Power BI.
SELECT
    Year,
    Quarter,
    Account_Type,
    COUNT(*)                         AS transactions,
    SUM(Revenue)                     AS total_revenue,
    SUM(Expenditure)                 AS total_expenditure,
    ROUND(AVG(Profit_Margin)*100,2)  AS avg_margin_pct,
    SUM(CASE WHEN Transaction_Outcome=0 THEN 1 ELSE 0 END) AS failures
FROM transactions
GROUP BY Year, Quarter, Account_Type
ORDER BY Year, Quarter, Account_Type;

-- Day-of-week transaction volume & success rate
-- Reveals if failures cluster on specific weekdays — operational insight.
SELECT
    DayOfWeek,
    COUNT(*)                                                AS total_transactions,
    SUM(CASE WHEN Transaction_Outcome=1 THEN 1 ELSE 0 END) AS successes,
    SUM(CASE WHEN Transaction_Outcome=0 THEN 1 ELSE 0 END) AS failures,
    ROUND(AVG(Transaction_Outcome)*100,2)                  AS success_rate_pct,
    ROUND(AVG(Processing_Time_seconds),3)                  AS avg_processing_s
FROM transactions
GROUP BY DayOfWeek
ORDER BY FIELD(DayOfWeek,'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday');

-- Failed transactions detail
-- All 49 failures with key attributes — useful as a drillthrough table in Power BI
SELECT
    Transaction_ID,
    Date,
    Account_Type,
    Transaction_Amount,
    Revenue,
    Expenditure,
    ROUND(Profit_Margin*100,2)    AS profit_margin_pct,
    Processing_Time_seconds,
    Accuracy_Score,
    Missing_Data_Indicator
FROM transactions
WHERE Transaction_Outcome = 0
ORDER BY Date DESC;

-- Failure rate by account type
-- Which account types have the highest failure rate — risk ranking
SELECT
    Account_Type,
    COUNT(*)                                                AS total,
    SUM(CASE WHEN Transaction_Outcome=0 THEN 1 ELSE 0 END) AS failures,
    ROUND(
        SUM(CASE WHEN Transaction_Outcome=0 THEN 1 ELSE 0 END)
        / COUNT(*) * 100, 2)                               AS failure_rate_pct,
    ROUND(AVG(Accuracy_Score),4)                           AS avg_accuracy
FROM transactions
GROUP BY Account_Type
ORDER BY failure_rate_pct DESC;

-- High debt-to-equity transactions (risk flag)
-- Transactions where D/E ratio exceeds 2.0 — high-leverage risk indicator.
SELECT
    Transaction_ID,
    Date,
    Account_Type,
    ROUND(Debt_to_Equity_Ratio,4)  AS de_ratio,
    Revenue,
    Expenditure,
    ROUND(Profit_Margin*100,2)     AS margin_pct,
    Transaction_Outcome,
    Missing_Data_Indicator
FROM transactions
WHERE Debt_to_Equity_Ratio > 2.0
ORDER BY Debt_to_Equity_Ratio DESC
LIMIT 50;

-- Missing data flag summary
-- 48 flagged rows broken down by account type, year, and quarter
SELECT
    Account_Type,
    Year,
    Quarter,
    COUNT(*)  AS flagged_transactions,
    ROUND(AVG(Accuracy_Score),4) AS avg_accuracy,
    ROUND(AVG(Transaction_Outcome),4) AS avg_success_rate
FROM transactions
WHERE Missing_Data_Indicator = 1
GROUP BY Account_Type, Year, Quarter
ORDER BY flagged_transactions DESC;

-- Processing time statistics
-- Min, max, average and slow-transaction count — for the operational metrics page.
SELECT
    Account_Type,
    ROUND(MIN(Processing_Time_seconds),3)  AS min_s,
    ROUND(AVG(Processing_Time_seconds),3)  AS avg_s,
    ROUND(MAX(Processing_Time_seconds),3)  AS max_s,
    SUM(CASE WHEN Processing_Time_seconds > 1.8 THEN 1 ELSE 0 END) AS slow_transactions
FROM transactions
GROUP BY Account_Type
ORDER BY avg_s DESC;

-- Accuracy score by outcome
-- Does lower accuracy predict failure? Compare mean scores for success vs failure.
SELECT
    CASE WHEN Transaction_Outcome=1 THEN 'Success' ELSE 'Failure' END AS outcome,
    COUNT(*)                             AS transactions,
    ROUND(MIN(Accuracy_Score),4)         AS min_accuracy,
    ROUND(AVG(Accuracy_Score),4)         AS avg_accuracy,
    ROUND(MAX(Accuracy_Score),4)         AS max_accuracy,
    ROUND(AVG(Processing_Time_seconds),3) AS avg_processing_s
FROM transactions
GROUP BY Transaction_Outcome;

-- Transaction volume distribution
-- How many transactions fall in each volume bucket (1–9 range in data).
SELECT
    Transaction_Volume,
    COUNT(*)                                AS transactions,
    ROUND(AVG(Revenue),0)                  AS avg_revenue,
    ROUND(AVG(Profit_Margin)*100,2)        AS avg_margin_pct,
    ROUND(AVG(Transaction_Outcome)*100,2)  AS success_rate_pct
FROM transactions
GROUP BY Transaction_Volume
ORDER BY Transaction_Volume;

-- Month-over-month revenue growth
-- Uses LAG() to compute MoM change — good for a growth rate KPI card.
WITH monthly AS (
    SELECT
        Year, Month,
        SUM(Revenue) AS total_revenue
    FROM transactions
    GROUP BY Year, Month
)
SELECT
    Year,
    Month,
    total_revenue,
    LAG(total_revenue) OVER (ORDER BY Year, Month) AS prev_month_revenue,
    ROUND(
        (total_revenue - LAG(total_revenue) OVER (ORDER BY Year, Month))
        / LAG(total_revenue) OVER (ORDER BY Year, Month) * 100, 2
    ) AS mom_growth_pct
FROM monthly
ORDER BY Year, Month;

-- Running cumulative revenue by year
-- Cumulative sum using SUM() OVER — maps to a running total line chart.
SELECT
    Transaction_ID,
    Date,
    Year,
    Month,
    Revenue,
    SUM(Revenue) OVER (
        PARTITION BY Year
        ORDER BY Date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_revenue_ytd
FROM transactions
ORDER BY Date;

-- Rank accounts by profit margin (per type)
-- RANK() within each account type — spot the top and bottom performers
SELECT
    Transaction_ID,
    Date,
    Account_Type,
    Revenue,
    Expenditure,
    ROUND(Profit_Margin*100,2) AS margin_pct,
    RANK() OVER (
        PARTITION BY Account_Type
        ORDER BY Profit_Margin DESC
    ) AS rank_within_type
FROM transactions
ORDER BY Account_Type, rank_within_type
LIMIT 40;

-- Anomaly detection — statistical outliers
-- Flags transactions where profit margin or D/E ratio is more than 2 std devs from the mean
WITH stats AS (
    SELECT
        AVG(Profit_Margin)          AS avg_pm,
        STDDEV(Profit_Margin)       AS std_pm,
        AVG(Debt_to_Equity_Ratio)   AS avg_de,
        STDDEV(Debt_to_Equity_Ratio) AS std_de
    FROM transactions
)
SELECT
    t.Transaction_ID,
    t.Date,
    t.Account_Type,
    ROUND(t.Profit_Margin*100,2)       AS margin_pct,
    ROUND(t.Debt_to_Equity_Ratio,4)    AS de_ratio,
    t.Transaction_Outcome,
    CASE
        WHEN ABS(t.Profit_Margin - s.avg_pm) > 2 * s.std_pm THEN 'Margin outlier'
        WHEN ABS(t.Debt_to_Equity_Ratio - s.avg_de) > 2 * s.std_de THEN 'D/E outlier'
        ELSE 'Normal'
    END AS anomaly_flag
FROM transactions t, stats s
WHERE
    ABS(t.Profit_Margin - s.avg_pm) > 2 * s.std_pm
    OR ABS(t.Debt_to_Equity_Ratio - s.avg_de) > 2 * s.std_de
ORDER BY anomaly_flag, t.Date;
