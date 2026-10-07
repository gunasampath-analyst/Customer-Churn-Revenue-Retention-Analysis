#Total Churned MRR
SELECT SUM(mrr_usd) AS churned_mrr_usd
FROM subscriptions AS s 
JOIN customers AS c 
	ON s.customer_id = c.customer_id
WHERE c.churn_date IS NOT NULL 
AND s.subscription_status = 'Churned';


#Churned MRR by Customer Segment
SELECT c.segment,
	COUNT(DISTINCT c.customer_id) AS churned_customers,
    SUM(s.mrr_usd) AS churned_mrr_usd,
    ROUND(SUM(s.mrr_usd)*100.0 / SUM(SUM(s.mrr_usd)) OVER() ,2) AS mrr_loss_share_pct
FROM customers AS c 
JOIN subscriptions AS s
	ON s.customer_id = c.customer_id
WHERE c.churn_date IS NOT NULL 
AND s.subscription_status = 'Churned'
GROUP BY C.segment
ORDER BY churned_mrr_usd DESC;


#Average MRR Lost per Churned Customer by Segment
SELECT c.segment ,
	COUNT(DISTINCT c.customer_id) AS churned_customers,
    SUM(s.mrr_usd) AS churned_mrr_usd,
    ROUND(SUM(s.mrr_usd)/COUNT(DISTINCT c.customer_id),2) AS avg_mrr_per_churned_customer
FROM customers AS c 
JOIN subscriptions AS s 
	ON c.customer_id = s.customer_id
WHERE c.churn_date IS NOT NULL 
AND s.subscription_status = 'Churned'
GROUP BY c.segment
ORDER BY avg_mrr_per_churned_customer DESC;


#Invoice Payment Status Distribution
SELECT invoice_status ,
	COUNT(*) AS invoices,
    SUM(total_usd) AS invoice_value,
    ROUND(COUNT(*)*100.0 / SUM(COUNT(*)) OVER(),2) AS invoice_share_pct
FROM invoices
GROUP BY invoice_status
ORDER BY invoices DESC ;


#Active Customers with Payment Issues
SELECT c.customer_id , c.company_name ,c.segment,
	COUNT(i.invoice_id) AS problem_invoices,
    SUM(i.total_usd) AS problem_invoice_value
FROM customers AS c 
JOIN invoices AS i 
	ON c.customer_id = i.customer_id
WHERE c.customer_status = 'Active'
AND i.invoice_status IN ('Overdue' , 'Failed')
GROUP BY c.customer_id , c.company_name , c.segment
ORDER BY problem_invoices DESC , problem_invoice_value DESC;


#Payment Issues Among Active Customers
SELECT COUNT(DISTINCT c.customer_id) AS active_customers_with_payment_issues,
	SUM(i.total_usd) AS problem_invoice_value,
   ROUND(COUNT(DISTINCT c.customer_id)*100.0/ (SELECT COUNT(*) FROM customers WHERE customer_status = 'Active'),2) AS pct_of_active_customers
FROM customers AS c 
JOIN invoices AS i 
	ON c.customer_id = i.customer_id
WHERE c.customer_status = 'Active'
AND i.invoice_status IN ('Overdue' , 'Failed');


#Payment Issues by Customer Segment
SELECT c.segment,
	COUNT(DISTINCT c.customer_id) AS customers_with_issues,
    SUM(i.total_usd) AS problem_invoice_value
FROM customers AS c 
JOIN invoices AS i 
	ON c.customer_id = i.customer_id
WHERE c.customer_status = 'Active'
AND i.invoice_status IN ('Overdue' , 'Failed')
GROUP BY c.segment
ORDER BY problem_invoice_value DESC;


#Active MRR at Risk from Payment Issues
WITH payment_risk AS (
    SELECT DISTINCT customer_id
    FROM invoices
    WHERE invoice_status IN ('Overdue', 'Failed')
),
customer_mrr AS (
    SELECT
        customer_id,
        SUM(mrr_usd) AS current_mrr
    FROM subscriptions
    WHERE subscription_status = 'Active'
    GROUP BY customer_id
)
SELECT
    ROUND(SUM(cm.current_mrr), 2) AS mrr_at_risk
FROM payment_risk pr
JOIN customers c
    ON pr.customer_id = c.customer_id
JOIN customer_mrr cm
    ON pr.customer_id = cm.customer_id
WHERE c.customer_status = 'Active';


#MRR at Risk from Payment Issues by Segment
SELECT x.segment,
	COUNT(DISTINCT x.customer_id) AS customers_with_payment_issues,
    SUM(customer_mrr) AS mrr_at_risk
FROM(
SELECT c.customer_id,
		c.segment,
        MAX(s.mrr_usd) AS customer_mrr
FROM customers AS c
JOIN invoices AS i 
	ON c.customer_id = i.customer_id
JOIN subscriptions AS s 
	ON c.customer_id = s.customer_id
WHERE c.customer_status = 'Active'
AND i.invoice_status IN ('Overdue' , 'Failed')
AND s.subscription_status = 'Active'
GROUP BY c.customer_id , c.segment
) x
GROUP BY x.segment
ORDER BY mrr_at_risk DESC; 


