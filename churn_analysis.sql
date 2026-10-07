#Overall Customer Churn Rate
SELECT COUNT(*),
		COUNT(churn_date),
        ROUND(COUNT(churn_date)*100.0/ COUNT(*),2) AS churn_rate_pct
FROM customers;


#Churn Rate by Customer Segment
SELECT segment ,
		COUNT(*),
        COUNT(churn_date),
        ROUND(COUNT(churn_date)*100.0/ COUNT(*),2) AS churn_rate_pct
FROM customers
GROUP BY segment
ORDER BY churn_rate_pct DESC;


#Churn Rate by Plan
SELECT p.plan_name,
		COUNT(DISTINCT s.customer_id),
        COUNT(DISTINCT CASE 
							WHEN c.churn_date IS NOT NULL 
                            THEN c.customer_id 
						END )AS churned_customers ,
		ROUND(COUNT(DISTINCT CASE 
								WHEN c.churn_date IS NOT NULL 
								THEN c.customer_id  
							END)*100.0 / COUNT(DISTINCT s.customer_id) , 2) AS churn_rate_pct
FROM subscriptions AS s 
JOIN customers AS c
	ON s.customer_id = c.customer_id
JOIN plans AS p 
	ON s.plan_id = p.plan_id
GROUP BY p.plan_name
ORDER BY churn_rate_pct DESC;


#Churn Rate by Billing Interval
SELECT s.billing_interval ,
	COUNT(DISTINCT c.customer_id) AS customers,
    COUNT(DISTINCT c.churn_date) AS churned_customers,
    ROUND(COUNT(DISTINCT c.churn_date)*100.0 / COUNT(DISTINCT c.customer_id),2) AS churn_rate_pct
FROM subscriptions AS s 
JOIN customers AS c 
	ON s.customer_id = c.customer_id
GROUP BY s.billing_interval
ORDER BY churn_rate_pct DESC;


#Churn by Customer Tenure
SELECT 
	CASE 
		WHEN TIMESTAMPDIFF(MONTH , signup_date , churn_date) < 6 THEN '0-5 Months'
        WHEN TIMESTAMPDIFF(MONTH , signup_date , churn_date) < 12 THEN '6-11 Months'
        WHEN TIMESTAMPDIFF(MONTH , signup_date , churn_date) < 24 THEN '12-23 Months'
        ELSE '24+ Months'
	END AS tenure_bucket,
    COUNT(*) AS churned_customers
FROM customers
WHERE churn_date IS NOT NULL 
GROUP BY tenure_bucket
ORDER BY 
	MIN(TIMESTAMPDIFF(MONTH , signup_date , churn_date));
    

#Churn Rate by Customer Tenure
SELECT 
	CASE 
		WHEN TIMESTAMPDIFF(MONTH , signup_date , COALESCE(churn_date , CURDATE())) < 6 THEN '0-5 Months'
        WHEN TIMESTAMPDIFF(MONTH , signup_date , COALESCE(churn_date , CURDATE())) < 12 THEN '6-11 Months'
        WHEN TIMESTAMPDIFF(MONTH , signup_date , COALESCE(churn_date , CURDATE())) < 24 THEN '12-23 Months'
        ELSE '24+ Months'
	END AS tenure_bucket , 
    COUNT(*) AS total_customers,
    SUM(CASE
			WHEN churn_date IS NOT NULL THEN 1
            ELSE 0
		END) AS churned_customers,
	 ROUND(SUM(CASE
			WHEN churn_date IS NOT NULL THEN 1
            ELSE 0
		END)*100.0 / COUNT(*),2) AS churn_rate_pct
FROM customers
GROUP BY tenure_bucket
ORDER BY MIN(TIMESTAMPDIFF(MONTH , signup_date , COALESCE(churn_date , CURDATE())));