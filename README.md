# AI-Powered-Business-Intelligence_Churnsense
ChurnSense: AI-Powered Business Intelligence
A customer-churn analysis project for a subscription business | Excel · SQL Server · Power BI · AI (LLM)
1. Business Problem

StreamNet Broadband (fictional Indian home-internet + OTT provider) is losing about 1 in 4 customers. Leadership asked three questions:

WHO is leaving?
WHY are they leaving?
WHICH current customers are likely to leave next, and how much revenue is at risk?

This project answers all three using a full analytics workflow: raw data → cleaning → SQL analysis → an explainable risk score → AI-powered text analysis → an interactive Power BI dashboard.

Note on the data: this dataset is synthetic (computer-generated) so it could include realistic patterns and deliberate data-quality problems for practice. It does not describe a real company. The tools, queries, and methods used are the same ones used on real company data.

2. Tools Used
Tool	Purpose
Excel	Data profiling, cleaning, pivot-table exploration
SQL Server + SSMS	Business-question queries, an explainable churn-risk score (as a view), and a backtest
AI (LLM)	Sentiment and theme classification of free-text customer feedback
Power BI + DAX	Data modeling, measures, Key Influencers, Decomposition Tree, anomaly detection, forecasting, and a 4-page interactive dashboard
3. Dataset
10,000 raw rows, 23 columns, one row per customer
Data as-of date: 31-Aug-2026
Deliberately includes real-world messiness: 50 duplicate rows, inconsistent city spellings (63 variants of 16 real cities), inconsistent gender codes (M/F vs Male/Female), missing Age (31 rows) and missing SatisfactionScore (251 rows — customers who didn't answer the survey)
After cleaning: 9,950 unique customer records

Files:

data/ChurnSense_Customer_Dataset_10000.xlsx — raw data + README + Plans lookup + Data Dictionary
data/ChurnSense_Customers_raw.csv — same raw data as CSV
data/ChurnSense_Customers_clean.csv — cleaned version, ready for SQL Server import
data/AI_Feedback_Map.csv — AI-classified customer feedback (Sentiment, Theme), human-verified
4. Workflow
Raw Excel/CSV (10,000 rows)
   → EXCEL: profile + clean            → 9,950 clean rows
   → SQL SERVER: business analysis + churn risk score (view + backtest)
   → AI (LLM): sentiment + theme for customer comments, human-verified
   → POWER BI: data model + DAX + AI visuals + 4-page dashboard
   → INSIGHTS: business recommendations in rupees
Step 1 — Excel: Profiling and Cleaning
Removed 50 duplicate rows (10,000 → 9,950 unique customers)
Standardized city names (63 spelling variants → 16 correct cities) using TRIM + PROPER
Standardized gender codes (M/F → Male/Female)
Imputed missing Age with the median (36), and flagged which rows were imputed
Left missing SatisfactionScore blank intentionally (didn't invent survey answers customers never gave — later used as its own signal in the risk score)
Built pivot tables to test hypotheses about churn by contract type, plan, support tickets, and region
Step 2 — SQL Server: Business Analysis

Ten business questions answered with SQL (CTEs, window functions, CASE, aggregate functions), including:

Overall churn rate: 24.38% (2,426 of 9,950 customers)
Churn by contract: Month-to-Month 34.2% vs Two Year 6.8% (a 5x difference)
A churn spike detected in March 2026 (85 → 323 churned customers month-over-month) using LAG()
Churn reasons ranked by lost monthly revenue using window functions

Explainable Churn Risk Score: built as a SQL view (vw_customer_risk) using a rule-based points system (contract type, satisfaction, support tickets, late invoices, payment method) — deliberately excluding TenureMonths, ChurnDate, ChurnReason, and TotalRevenue to avoid data leakage (these are outcomes of churn, not predictors of it).

Backtest result (proving the score works):

Risk Band	Customers	Actual churn rate
High	1,278	56.7%
Medium	4,055	29.9%
Low	4,617	10.6%

Business impact identified: 554 active customers are currently High risk, representing Rs 5,09,314 in monthly revenue at risk (about 7.2% of active monthly recurring revenue).

Step 3 — AI: Voice of the Customer
Extracted the 58 unique customer feedback comments (out of 7,436 total responses) using SELECT DISTINCT
Classified each into Sentiment (Positive/Neutral/Negative) and Theme (Network/Speed, Customer Support, Billing/Price, Installation, OTT Content, Overall Experience) using a structured LLM prompt
Manually verified all 58 labels against the source text using an Excel COUNTIF check — confirmed 0 discrepancies between the AI's output and the original comments
Mapped labels back to all 7,436 feedback rows via a cleaned text-matching key (to handle punctuation/formatting differences between systems)
Step 4 — Power BI: Dashboard

Star-schema data model (Customers view + Calendar date table + AI_Feedback_Map) with 14+ DAX measures, across a 4-page dashboard:

Executive Summary — KPIs, churn trend with anomaly detection and forecast, churn by reason
Why They Leave — Key Influencers AI visual, Decomposition Tree, contract × plan churn matrix
Who's Next — active High-risk customer list with churn-risk scores, MRR at risk
Voice of the Customer — sentiment breakdown, churn rate by complaint theme, satisfaction-vs-sentiment mismatch analysis
5. Key Findings & Recommendations
#	Finding	Recommendation
1	Month-to-Month customers churn 34.2% vs 6.8% for Two Year (5x)	Incentivize moving Month-to-Month customers to annual plans
2	Customers with 4+ support tickets churn ~50%	Escalate to a senior agent after the 3rd ticket in 6 months
3	Manual payers churn 28.7% vs 19.2% for AutoPay	Offer a small incentive to switch to AutoPay
4	Churn spiked from 85 to 323 customers in March 2026	Investigate the cause (price change, outage, competitor offer)
5	Region and gender show no meaningful effect on churn	Don't target retention budget by region
6	554 active customers are High risk (~Rs 5.1 lakh/month at stake)	Prioritize this list for proactive retention outreach
6. Limitations
The dataset is synthetic.
The risk score is rule-based for explainability; a logistic regression or gradient-boosting model could improve accuracy, evaluated with AUC/precision/recall.
Correlation is not causation — an A/B test on retention offers would validate what actually works.
AI text labels were verified on 58 unique comments; real-world comment data at scale would need a more robust QA sampling approach.
