# Customer Churn & Revenue Retention Analysis: Identifying $89K in Churned MRR and $600K in Payment Exposure

## Business Background

A subscription-based business is experiencing customer churn and recurring-revenue pressure. Management needs to understand not only **why customers are leaving**, but also **where revenue is being lost and which active customers require retention attention**. This analysis uses customer, subscription, monthly MRR, plan, and invoice data to evaluate churn patterns, revenue impact, payment issues, and observable customer-level risk signals.

## Objective

The objective is to help management answer four decisions:

1. **Where is customer churn concentrated?**
2. **What is the financial impact of customer churn?**
3. **Where is current recurring revenue exposed to payment problems?**
4. **Which active customers show observable risk signals that should be prioritized for retention review?**

The analysis focuses on evidence from historical churn, MRR, payment behavior, and renewal signals rather than predicting churn with a statistical or machine-learning model.

---

## Data Preparation

The analysis covered five related datasets:

* **Customers:** 1,200 records
* **Plans:** 10 records
* **Subscriptions:** 1,381 records
* **Subscription Months:** 19,015 records
* **Invoices:** 11,257 records

### Data quality checks

The data preparation process included:

* Converted source dates from `DD-MM-YYYY` text into valid SQL `DATE` values.
* Resolved an import issue caused by a UTF-8 BOM in the `customer_id` column.
* Validated customer, subscription, plan, and invoice relationships.
* Checked for orphan records across related tables.
* Validated customer status against churn dates.
* Validated subscription start/end dates and subscription status.
* Reconciled subscription MRR calculations.
* Validated monthly MRR movement calculations.
* Validated invoice totals.

All major relationship and MRR consistency checks returned **zero structural mismatches**.

Invoice subtotal validation identified small differences in 765 records, ranging from approximately $0.02 to $0.10. These were treated as **rounding/precision differences** rather than modifying the source data.

---

## Key Insights

### 1. Overall churn is significant at 28.75%

Out of 1,200 customers:

* **345 customers churned**
* **855 customers remained active**
* Overall churn rate: **28.75%**

Churn is particularly concentrated among SMB customers.

| Segment    | Customers | Churned | Churn Rate |
| ---------- | --------: | ------: | ---------: |
| SMB        |       662 |     249 | **37.61%** |
| Mid-Market |       390 |      85 | **21.79%** |
| Enterprise |       148 |      11 |  **7.43%** |

**Business implication:** SMB retention should be a major focus because it has both the highest churn rate and the largest number of churned customers.

---

### 2. Early-tenure customers show the highest observed churn

Customers in their first six months had the highest observed churn rate.

| Tenure       | Customers | Churn Rate |
| ------------ | --------: | ---------: |
| 0–5 months   |       197 | **54.31%** |
| 6–11 months  |       224 | **29.46%** |
| 12–23 months |       312 | **23.40%** |
| 24+ months   |       467 | **21.20%** |

**Business implication:** The first few months represent the strongest retention opportunity. Customer onboarding, activation, product adoption, and early support should receive additional attention.

---

### 3. Customer churn has already removed approximately $89K in MRR

Churned subscriptions represent:

**$89,038.84 in churned MRR**

The financial impact is not evenly distributed:

| Segment    |    Churned MRR | Share of Churned MRR |
| ---------- | -------------: | -------------------: |
| Mid-Market | **$39,023.42** |           **43.83%** |
| SMB        | **$35,274.98** |           **39.62%** |
| Enterprise | **$14,740.44** |           **16.56%** |

Enterprise customers have relatively low churn volume but substantially higher MRR per churned customer:

* Enterprise: **$1,340.04/customer**
* Mid-Market: **$459.10/customer**
* SMB: **$141.67/customer**

**Business implication:** Retention strategy should not rely only on churn rate. Mid-Market represents the largest aggregate MRR loss, while Enterprise churn requires attention because each lost customer carries substantially more recurring revenue.

---

### 4. Payment problems expose a substantial portion of the active customer base

Among active customers:

* **313 customers** had overdue or failed invoices
* Problem invoice value: **$600,391.77**
* **36.61% of active customers** were affected

The exposure differs substantially by segment:

| Segment    | Customers with Issues | Problem Invoice Value |
| ---------- | --------------------: | --------------------: |
| Enterprise |                    39 |       **$356,839.28** |
| Mid-Market |                   105 |       **$170,979.98** |
| SMB        |                   169 |        **$72,572.51** |

Enterprise has relatively few affected customers but represents the largest share of problem invoice value.

**Business implication:** Payment recovery should be prioritized by **financial exposure**, not simply by number of affected customers.

---

### 5. Customers with payment issues can be prioritized using observable risk signals

The final customer-level analysis combines:

* Overdue/failed invoice count
* Latest MRR movement
* Current MRR
* Auto-renewal status

This identifies customers whose recurring revenue is **contracting while payment problems are present**, as well as customers with repeated payment issues or auto-renewal turned off.

These are **risk signals**, not predicted probabilities of churn.

**Business implication:** Customer success and finance teams can use these signals to prioritize retention and payment-recovery reviews.

---

## Actionable Recommendations

### Priority 1 — Protect high-value revenue

Prioritize payment recovery for **Enterprise and high-MRR customers** with overdue or failed invoices.

Enterprise accounts represented approximately **$356.8K in problem invoice value**, despite only 39 affected customers.

**Action:** Create a high-touch payment recovery workflow for financially significant accounts.

**Expected impact:** Recovering even a portion of this exposure could protect recurring revenue and reduce potential involuntary churn.

**Caveat:** Problem invoice value is not equivalent to MRR at risk or guaranteed recoverable revenue.

---

### Priority 2 — Strengthen the first 6 months of the customer lifecycle

The **54.31% churn rate among 0–5 month customers** indicates a substantial early-lifecycle retention opportunity.

**Action:**

* Strengthen onboarding.
* Track activation milestones.
* Introduce early customer-success check-ins.
* Investigate common reasons for early cancellation.

**Expected impact:** Reducing early-tenure churn could have a meaningful effect on overall customer retention.

**Caveat:** The analysis identifies an association between tenure and churn but does not establish that onboarding quality is the causal driver.

---

### Priority 3 — Focus SMB retention efforts on scale

SMB customers account for:

* **249 of 345 churned customers**
* **37.61% churn rate**
* **$35.3K churned MRR**

**Action:** Develop scalable SMB retention programs rather than relying exclusively on high-touch account management.

**Expected impact:** Even a modest reduction in SMB churn could retain a meaningful number of customers because of the segment's large customer base.

---

### Priority 4 — Protect Mid-Market revenue

Mid-Market customers generated the largest share of churned MRR at **43.83%**.

**Action:** Prioritize account reviews for Mid-Market customers showing MRR contraction, payment problems, or renewal risk.

**Expected impact:** Focused intervention could reduce future recurring-revenue loss.

**Caveat:** The analysis does not estimate the causal effect or success rate of individual retention interventions.

---

## Limitations

This analysis is intentionally **descriptive and diagnostic**, not predictive.

### 1. No churn prediction model

The project identifies observable risk signals but does not calculate a statistical probability of churn.

### 2. No causal analysis

The analysis shows relationships between churn, tenure, segment, billing interval, and other variables. It does not prove that any individual factor caused churn.

### 3. Payment exposure is not guaranteed revenue loss

Overdue and failed invoice values represent payment exposure. They should not automatically be interpreted as MRR at risk or permanently lost revenue.

### 4. Historical payment problems are cumulative

The customer risk analysis counts overdue/failed invoices across the available invoice history. It does not distinguish between recent and old payment problems.

### 5. Limited customer-level behavioral data

The dataset does not provide detailed product usage, customer satisfaction, support interactions, contract conversations, or cancellation reasons. These factors could explain why customers churn.

### 6. No experiment-based measurement

The project does not test whether a specific retention intervention actually reduces churn. Recommendations therefore require validation through future monitoring or controlled experiments.

---

## Management Takeaway

The analysis shows that customer retention is not a single-segment problem.

**SMB has the highest churn rate and largest churn volume, Mid-Market accounts for the largest share of churned MRR, and Enterprise has relatively low churn but substantial payment-value exposure.**

The strongest immediate opportunities are therefore to:

1. **Protect high-value revenue from payment issues**
2. **Improve retention during the first six months**
3. **Scale SMB retention efforts**
4. **Prioritize Mid-Market and high-value customers showing multiple risk signals**

The key principle is to move from **“Who churned?”** to **“Where is revenue being lost, where is it currently exposed, and which customers should management review first?”**
