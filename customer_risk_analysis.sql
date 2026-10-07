#Customer-Level Payment Risk Signals
SELECT c.customer_id,
	c.company_name,
    c.segment,
    MAX(s.mrr_usd) AS current_mrr,
    MAX(s.auto_renew)AS auto_renew,
    COUNT(DISTINCT i.invoice_id) AS problem_invoices
FROM customers AS c 
JOIN subscriptions AS s 
	ON c.customer_id = s.customer_id
LEFT JOIN invoices AS i 
	ON c.customer_id = i.customer_id
    AND i.invoice_status IN ('Overdue', 'Failed')
WHERE c.customer_status = 'Active'
AND s.subscription_status = 'Active'
GROUP BY c.customer_id,
	c.company_name,
    c.segment
HAVING problem_invoices > 0
ORDER BY current_mrr DESC ;


#Payment Risk with Latest MRR Movement
SELECT x.customer_id,
	x.company_name,
    x.segment,
    x.current_mrr,
    x.auto_renew,
    x.problem_invoices,
    sm.previous_mrr_usd,
    sm.mrr_delta_usd,
    sm.movement_type
FROM(
SELECT c.customer_id,
	c.company_name,
    c.segment,
    MAX(s.mrr_usd) AS current_mrr,
    MAX(s.auto_renew) AS auto_renew,
    COUNT(DISTINCT i.invoice_id) AS problem_invoices
FROM customers AS c 
JOIN subscriptions AS s 
	ON c.customer_id = s.customer_id
LEFT JOIN invoices AS i 
	ON c.customer_id = i.customer_id
	AND i.invoice_status IN ('Overdue', 'Failed')
WHERE c.customer_status = 'Active'
AND s.subscription_status = 'Active'
GROUP BY c.customer_id , c.company_name , c.segment
HAVING problem_invoices > 0
) AS x
JOIN subscription_months AS sm 
	ON x.customer_id = sm.customer_id
WHERE sm.period_month = (SELECT MAX(period_month) FROM subscription_months)
ORDER BY x.current_mrr;


#Latest Customer MRR Movement
WITH latest_mrr AS (
	SELECT customer_id ,
		SUM(mrr_usd) AS current_mrr,
        SUM(previous_mrr_usd) AS previous_mrr,
        SUM(mrr_delta_usd) AS mrr_delta
    FROM subscription_months
    WHERE period_month = (SELECT MAX(period_month) FROM subscription_months)
    AND is_active = 'Yes'
    GROUP BY customer_id
)
SELECT customer_id ,
	current_mrr,
    previous_mrr,
    mrr_delta,
    CASE 
		WHEN mrr_delta > 0 THEN 'Expansion'
        WHEN mrr_delta < 0 THEN 'Contraction'
        ELSE 'Stable'
	END AS movement_type
FROM latest_mrr
ORDER BY current_mrr DESC ;


#Combined Customer Risk Signals
WITH payment_risk AS (
	SELECT customer_id ,
		COUNT(DISTINCT invoice_id) AS problem_invoices
	FROM invoices
    WHERE invoice_status IN ('Overdue', 'Failed')
    GROUP BY customer_id
),
latest_mrr  AS (
	SELECT customer_id,
		SUM(mrr_usd) AS current_mrr,
        SUM(previous_mrr_usd) AS previous_mrr  ,
        SUM(mrr_delta_usd) AS mrr_delta
    FROM subscription_months
    WHERE period_month = (SELECT MAX(period_month) FROM subscription_months)
    AND is_active = 'Yes'
    GROUP BY customer_id
),
renewal_risk AS (
	SELECT customer_id,
		MAX(CASE 
			WHEN auto_renew = 'No' THEN 1
            ELSE 0
		END) AS has_auto_renew_off
    FROM subscriptions
    WHERE subscription_status = 'Active'
    GROUP BY customer_id
)
SELECT c.customer_id,
	c.company_name,
    c.segment,
    l.current_mrr,
    l.previous_mrr ,
    l.mrr_delta,
    CASE 
		WHEN l.mrr_delta > 0 THEN 'Expansion'
        WHEN l.mrr_delta < 0 THEN 'Contraction'
        ELSE 'Stable'
	END AS movement_type,
    p.problem_invoices,
    CASE
		WHEN r.has_auto_renew_off = 1 THEN 'No'
        ELSE 'Yes'
    END AS auto_renew
FROM customers AS c
JOIN payment_risk AS p 
	ON c.customer_id = p.customer_id 
JOIN latest_mrr AS l 
	ON c.customer_id = l.customer_id
JOIN renewal_risk AS r 
	ON c.customer_id = r.customer_id
WHERE c.customer_status = 'Active'
ORDER BY current_mrr DESC;


#MRR Movement Summary
WITH latest_mrr AS (
    SELECT
        sm.customer_id,
        SUM(sm.mrr_usd) AS current_mrr,
        SUM(sm.previous_mrr_usd) AS previous_mrr,
        SUM(sm.mrr_delta_usd) AS mrr_delta
    FROM subscription_months sm
    WHERE sm.period_month = (SELECT MAX(period_month) FROM subscription_months)
	AND sm.is_active = 'Yes'
    GROUP BY sm.customer_id
)

SELECT
    CASE
        WHEN mrr_delta > 0 THEN 'Expansion'
        WHEN mrr_delta < 0 THEN 'Contraction'
        ELSE 'Stable'
    END AS movement_type,
    COUNT(*) AS customers,
    SUM(current_mrr) AS current_mrr,
    SUM(mrr_delta) AS total_mrr_change
FROM latest_mrr
GROUP BY
    CASE
        WHEN mrr_delta > 0 THEN 'Expansion'
        WHEN mrr_delta < 0 THEN 'Contraction'
        ELSE 'Stable'
    END
ORDER BY current_mrr DESC;


#Payment Risk with MRR Movement Prioritization
WITH payment_risk AS (
    SELECT
        customer_id,
        COUNT(DISTINCT invoice_id) AS problem_invoices
    FROM invoices
    WHERE invoice_status IN ('Overdue', 'Failed')
    GROUP BY customer_id
),
latest_mrr AS (
    SELECT
        customer_id,
        SUM(mrr_usd) AS current_mrr,
        SUM(previous_mrr_usd) AS previous_mrr,
        SUM(mrr_delta_usd) AS mrr_delta
    FROM subscription_months 
    WHERE period_month = (SELECT MAX(period_month) FROM subscription_months)
	AND is_active = 'Yes'
    GROUP BY customer_id
),
renewal_risk AS (
    SELECT customer_id,
        MAX(CASE
                WHEN auto_renew = 'No' THEN 1
                ELSE 0
            END) AS has_auto_renew_off
    FROM subscriptions
    WHERE subscription_status = 'Active'
    GROUP BY customer_id
)
SELECT
    c.customer_id,
    c.company_name,
    c.segment,
    current_mrr ,
    mrr_delta ,
    CASE
        WHEN m.mrr_delta > 0 THEN 'Expansion'
        WHEN m.mrr_delta < 0 THEN 'Contraction'
        ELSE 'Stable'
    END AS movement_type,
    p.problem_invoices,
    CASE
        WHEN r.has_auto_renew_off = 1 THEN 'No'
        ELSE 'Yes'
    END AS auto_renew
FROM customers c
JOIN payment_risk p
    ON c.customer_id = p.customer_id
JOIN latest_mrr m
    ON c.customer_id = m.customer_id
JOIN renewal_risk r
    ON c.customer_id = r.customer_id
WHERE c.customer_status = 'Active'
ORDER BY
    CASE
        WHEN m.mrr_delta < 0 THEN 1
        ELSE 2
    END,
    m.current_mrr DESC;
    

#Customer Risk Signal Distribution
WITH payment_risk AS (
    SELECT customer_id,
        COUNT(DISTINCT invoice_id) AS problem_invoices
    FROM invoices
    WHERE invoice_status IN ('Overdue', 'Failed')
    GROUP BY customer_id
),
latest_mrr AS (
    SELECT customer_id,
        SUM(mrr_usd) AS current_mrr,
        SUM(mrr_delta_usd) AS mrr_delta
    FROM subscription_months
    WHERE period_month = (SELECT MAX(period_month) FROM subscription_months)
	AND is_active = 'Yes'
    GROUP BY customer_id
),
renewal_risk AS (
    SELECT customer_id,
        MAX(CASE
                WHEN auto_renew = 'No' THEN 1
                ELSE 0
            END) AS has_auto_renew_off
    FROM subscriptions
    WHERE subscription_status = 'Active'
    GROUP BY customer_id
)
SELECT
    CASE
        WHEN m.mrr_delta < 0 THEN 'Contraction'
        WHEN m.mrr_delta > 0 THEN 'Expansion'
        ELSE 'Stable'
    END AS movement_type,
    p.problem_invoices,
    CASE
        WHEN r.has_auto_renew_off = 1 THEN 'No'
        ELSE 'Yes'
    END AS auto_renew,
    COUNT(*) AS customers,
	SUM(m.current_mrr) AS current_mrr
FROM customers c
JOIN payment_risk p
    ON c.customer_id = p.customer_id
JOIN latest_mrr m
    ON c.customer_id = m.customer_id
JOIN renewal_risk r
    ON c.customer_id = r.customer_id
WHERE c.customer_status = 'Active'
GROUP BY
    movement_type,
    p.problem_invoices,
    auto_renew
ORDER BY
    CASE
        WHEN movement_type = 'Contraction' THEN 1
        WHEN movement_type = 'Stable' THEN 2
        ELSE 3
    END,
    p.problem_invoices DESC,
    current_mrr DESC;