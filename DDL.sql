CREATE DATABASE IF NOT EXISTS accounting_db;
USE accounting_db;

CREATE TABLE IF NOT EXISTS transactions (
  Transaction_ID            INT          PRIMARY KEY,
  Date                      DATE         NOT NULL,
  Month                     CHAR(7),
  Quarter                   CHAR(7),
  DayOfWeek                 VARCHAR(10),
  Account_Type              VARCHAR(20),
  Transaction_Amount        INT,
  Cash_Flow                 INT,
  Net_Income                INT,
  Revenue                   INT,
  Expenditure               INT,
  Profit_Margin             DECIMAL(8,4),
  Debt_to_Equity_Ratio      DECIMAL(8,4),
  Operating_Expenses        INT,
  Gross_Profit              INT,
  Net_Profit                INT,
  OpEx_Ratio                DECIMAL(8,4),
  Transaction_Volume        INT,
  Processing_Time_seconds   DECIMAL(8,4),
  Accuracy_Score            DECIMAL(8,4),
  Missing_Data_Indicator    TINYINT,
  Normalized_Transaction_Amount DECIMAL(10,6),
  Transaction_Outcome       TINYINT,
  Success_Flag              VARCHAR(10)
);

SELECT *
FROM transactions
