SELECT COUNT(*),
	COUNT(DISTINCT subscription_id),
    COUNT(DISTINCT customer_id),
	COUNT(DISTINCT plan_id )
FROM subscriptions;

SELECT COUNT(*)
FROM subscriptions AS s 
LEFT JOIN customers AS c 
	ON s.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

SELECT COUNT(*)
FROM subscriptions AS s 
LEFT JOIN plans AS p
	ON s.plan_id = p.plan_id
WHERE p.plan_id IS NULL ;

SELECT COUNT(*)
FROM subscription_months AS sm 
LEFT JOIN subscriptions AS s 
	ON sm.subscription_id = s.subscription_id
WHERE s.subscription_id IS NULL ;

SELECT COUNT(*)
FROM subscription_months AS sm 
LEFT JOIN customers AS c 
	ON sm.customer_id = c.customer_id
WHERE c.customer_id IS NULL ;

SELECT COUNT(*)
FROM subscription_months AS sm 
JOIN subscriptions  AS s 
	ON sm.subscription_id = s.subscription_id 
WHERE sm.customer_id != s.customer_id;

SELECT COUNT(*)
FROM invoices AS i 
LEFT JOIN subscriptions AS s
	ON i.subscription_id = s.subscription_id
WHERE s.subscription_id IS NULL ;

SELECT COUNT(*) 
FROM invoices i
LEFT JOIN customers c
    ON i.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

SELECT COUNT(*) 
FROM invoices i
JOIN subscriptions s
    ON i.subscription_id = s.subscription_id
WHERE i.customer_id <> s.customer_id;

SELECT *
FROM invoices ;

SELECT COUNT(*),
SUM(
    CASE 
		WHEN ROUND(subtotal_usd,2) = ROUND(amount_usd - discount_usd,2) 
		THEN 0 
        ELSE 1
	END) AS subtotal_errors,
SUM(
    CASE 
		WHEN ROUND(total_usd,2) = ROUND(subtotal_usd + tax_usd,2)
        THEN 0
        ELSE 1
	END ) AS total_errors
FROM invoices;

SELECT invoice_id , amount_usd , discount_usd , subtotal_usd , tax_usd , total_usd,
	amount_usd - discount_usd , 
    subtotal_usd -(amount_usd - discount_usd)
FROM invoices
WHERE subtotal_usd != amount_usd - discount_usd
LIMIT 20;

SELECT *
FROM customers;

SELECT customer_status , 
	COUNT(*),
SUM(
    CASE
		WHEN customer_status = 'Churned'
			AND churn_date IS NULL 
        THEN 1
		WHEN customer_status = 'Active'
			AND churn_date IS NOT NULL 
		THEN 1
        ELSE 0
	END ) AS status_date_mismatches
FROM customers
GROUP BY customer_status;

SELECT COUNT(*),
	SUM(CASE 
			WHEN end_date IS NOT NULL 
				AND end_date < start_date 
			THEN 1
			ELSE 0
		END ) AS invalid_date_order,
	SUM(CASE 
			WHEN subscription_status = 'Active'
				AND end_date IS NOT NULL 
			THEN 1
            ELSE 0
		END ) AS active_with_end_date,
	SUM(CASE 
			WHEN subscription_status IN ('Churned', 'Upgraded')
				AND end_date IS NULL
			THEN 1
            ELSE 0
		END) AS closed_without_end_date
FROM subscriptions;

SELECT  s.subscription_id,
    s.plan_id,
    p.plan_name,
    s.seats,
    p.seats_included,
    s.discount_pct,
    p.monthly_price_usd,
    s.mrr_usd,
    p.monthly_price_usd + GREATEST(s.seats - p.seats_included , 0) * p.extra_seat_price_usd AS expected_mrr_before_discount
FROM subscriptions AS s 
JOIN plans AS p 
	ON s.plan_id = p.plan_id
LIMIT 20 ;

SELECT
    COUNT(*) ,
	SUM(CASE
            WHEN ABS(
                s.mrr_usd -(p.monthly_price_usd + GREATEST(s.seats - p.seats_included, 0) * p.extra_seat_price_usd) * (1 - s.discount_pct / 100)
            ) > 0.01
            THEN 1
            ELSE 0
        END
    ) AS mrr_mismatches
FROM subscriptions s
JOIN plans p
    ON s.plan_id = p.plan_id;
    
SELECT
    COUNT(*),
    SUM(CASE
            WHEN mrr_usd - previous_mrr_usd != mrr_delta_usd
            THEN 1
            ELSE 0
        END
    ) AS mrr_delta_mismatches
FROM subscription_months;

