USE ChurnSenseDB;

SELECT COUNT(*) AS total_rows 
FROM dbo.customers;    


SELECT COUNT(*) AS satisfaction_nulls
FROM dbo.customers 
WHERE SatisfactionScore IS NULL;   

-- Q1. What is our overall churn rate?
--ans:--
SELECT COUNT(*) AS total_customers,
       SUM(CASE WHEN Churned = 'yes' THEN 1 ELSE 0 END) AS churned_customers,
       CAST(100.0 * SUM(CASE WHEN Churned = 'yes' THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)) AS churn_rate_pct
FROM dbo.Customers;

-- Q2. Which contract type loses the most customers?
--ans:--
SELECT ContractType,
       COUNT(*) AS customers,
       CAST(100.0 * SUM(CASE WHEN Churned='yes' THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,1)) AS churn_rate_pct
FROM dbo.customers
GROUP BY ContractType
ORDER BY churn_rate_pct DESC;

-- Q3. Churn by plan, with average bill
--ans:--
SELECT PlanName,
       COUNT(*) AS customers,
       AVG(MonthlyCharge) AS avg_monthly_charge,
       CAST(100.0 * SUM(CASE WHEN Churned='yes' THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,1)) AS churn_rate_pct
FROM dbo.customers
GROUP BY PlanName
ORDER BY churn_rate_pct DESC;

--Q4. Does tenure matter? (uses your TenureBucket)
--ans:--
SELECT TenureBucket, COUNT(*) AS customers,
       CAST(100.0 * SUM(CASE WHEN Churned='yes' THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,1)) AS churn_rate_pct
FROM dbo.customers
GROUP BY TenureBucket
ORDER BY churn_rate_pct DESC;

--Q5. Why do customers say they left, and how much money did each reason cost?
--ans--
SELECT ChurnReason,
       COUNT(*) AS customers,
       SUM(MonthlyCharge) AS monthly_revenue_lost,
       CAST(100.0 * SUM(MonthlyCharge) / SUM(SUM(MonthlyCharge)) OVER () AS DECIMAL(5,1)) AS pct_of_lost_revenue
FROM dbo.customers
WHERE Churned = 'yes'
GROUP BY ChurnReason
ORDER BY monthly_revenue_lost DESC;

--Q6. Monthly churn trend and month-over-month change
--ans:--
 
--Q7. Rank cities by churn
--ans:--
SELECT City,
       COUNT(*) AS customers,
       CAST(100.0 * SUM(CASE WHEN Churned='yes' THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,2)) AS churn_rate_pct,
       RANK() OVER (ORDER BY 1.0 * SUM(CASE WHEN Churned='yes' THEN 1 ELSE 0 END) / COUNT(*) DESC) AS churn_rank
FROM dbo.customers
GROUP BY City
ORDER BY churn_rank;

--Q8. Autopay vs manual payment
--ans:--
SELECT CASE WHEN PaymentMethod IN ('UPI AutoPay','Card AutoPay') THEN 'AutoPay' ELSE 'Manual / Other' END AS payment_type,
       COUNT(*) AS customers,
       CAST(100.0 * SUM(CASE WHEN Churned='yes' THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,1)) AS churn_rate_pct
FROM dbo.customers
GROUP BY CASE WHEN PaymentMethod IN ('UPI AutoPay','Card AutoPay') THEN 'AutoPay' ELSE 'Manual / Other' END;

---create view table
GO
CREATE VIEW dbo.vw_customer_risk AS
WITH points AS (
    SELECT c.*,
        CASE ContractType WHEN 'Month-to-Month' THEN 25 WHEN 'One Year' THEN 8 ELSE 0 END AS pts_contract,
        CASE WHEN SatisfactionScore IS NULL THEN 8
             WHEN SatisfactionScore <= 2 THEN 25
             WHEN SatisfactionScore = 3 THEN 12 ELSE 0 END AS pts_satisfaction,
        CASE WHEN SupportTickets6M >= 4 THEN 20
             WHEN SupportTickets6M >= 2 THEN 10 ELSE 0 END AS pts_tickets,
        CASE WHEN LateInvoices12M >= 2 THEN 10
             WHEN LateInvoices12M = 1 THEN 5 ELSE 0 END AS pts_late,
        CASE WHEN PaymentMethod IN ('UPI Manual','Cash at Office') THEN 7 ELSE 0 END AS pts_payment
    FROM dbo.customers c
),
scored AS (
    SELECT *, pts_contract + pts_satisfaction + pts_tickets + pts_late + pts_payment AS RiskScore
    FROM points
)
SELECT *,
    CASE WHEN RiskScore >= 50 THEN 'High' WHEN RiskScore >= 30 THEN 'Medium' ELSE 'Low' END AS RiskBand,
    CASE WHEN RiskScore >= 50 THEN 1 WHEN RiskScore >= 30 THEN 2 ELSE 3 END AS RiskBandSort
FROM scored;
GO
-- 9. BACKTEST:prove your score works from view:-

SELECT RiskBand,
       COUNT(*) AS customers,
       CAST(100.0 * SUM(CASE WHEN Churned='yes' THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,1)) AS actual_churn_pct
FROM dbo.vw_customer_risk
GROUP BY RiskBand
ORDER BY MIN(RiskBandSort);

--10.The action list (active, High-risk customers)

SELECT COUNT(*) AS high_risk_active_customers, SUM(MonthlyCharge) AS monthly_revenue_at_risk
FROM dbo.vw_customer_risk
WHERE Churned = 'no' AND RiskBand = 'High';

--11. top 25 customers details

SELECT TOP 25 CustomerID, City, PlanName, ContractType, MonthlyCharge, RiskScore
FROM dbo.vw_customer_risk
WHERE Churned = 'No' AND RiskBand = 'High'
ORDER BY RiskScore DESC, MonthlyCharge DESC;
 

--12. Get the unique comments

SELECT  DISTINCT CustomerFeedback
FROM dbo.Customers
WHERE CustomerFeedback IS NOT NULL
ORDER BY CustomerFeedback;  

SELECT DISTINCT CustomerFeedback
FROM dbo.customers
WHERE CustomerFeedback IS NOT NULL AND CustomerFeedback <> ''
ORDER BY CustomerFeedback;

