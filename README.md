# ATM Network Operations Analysis
### SQL Portfolio Project — Sean Codner | Operations & Data Analyst

> *This project draws on firsthand experience supporting operational performance across a nationwide ATM network of 45,000+ machines. The analysis simulates the monitoring workflows, escalation logic, and vendor performance reviews conducted daily in high-availability ATM operations.*

---

## 📌 Project Overview

This project analyzes ATM network operational data using SQL to replicate how operations teams monitor cash levels, evaluate vendor performance, rank regional demand, and identify service risk — before it impacts customer availability.

The analysis answers the kinds of questions that drive real dispatch decisions, SLA compliance reviews, and cash logistics planning in a live network environment.

---

## 🏢 Business Context

ATM networks operate under strict uptime requirements — many clients require **98%+ availability**. When a machine runs low on cash or a vendor falls behind, the cost is immediate: failed transactions, SLA penalties, and lost customer trust.

Operational teams rely on daily data pulls to:
- Identify which machines are approaching cash-out risk
- Evaluate armored carrier workload and service distribution
- Prioritize dispatch to highest-demand regions
- Compare performance between bank-branded and independent ATMs

This project simulates that operational monitoring environment using structured SQL analysis.

---

## ❓ Business Questions Answered

| # | Business Question | Analysis Type |
|---|-------------------|---------------|
| 1 | Which regions generate the highest withdrawal demand? | Aggregation + Ranking |
| 2 | Which ATMs are approaching low-cash risk thresholds? | Correlated Subquery + CASE WHEN |
| 3 | Which armored vendor handles the most ATM activity? | GROUP BY + Aggregation |
| 4 | Do bank-branded ATMs outperform non-bank locations? | Comparative Analysis |
| 5 | Which ATM is the top performer in each region? | Window Function — RANK + PARTITION BY |

---

## 📊 Key Query Results

### 1. Regional Withdrawal Demand

Identifies which regions drive the highest total ATM withdrawal volume — used to prioritize cash logistics and vendor scheduling.

```sql
SELECT
    l.region,
    SUM(s.withdrawals) AS total_withdrawals,
    COUNT(DISTINCT s.atm_id) AS atm_count,
    ROUND(AVG(s.withdrawals), 0) AS avg_withdrawals_per_atm
FROM atm_daily_status s
JOIN atm_locations l ON s.atm_id = l.atm_id
GROUP BY l.region
ORDER BY total_withdrawals DESC;
```

| Region    | Total Withdrawals | ATM Count | Avg Withdrawals/ATM |
|-----------|:-----------------:|:---------:|:-------------------:|
| South     | 34,650            | 3         | 3,850               |
| Southeast | 10,400            | 1         | 3,467               |
| Midwest   | 5,200             | 1         | 1,733               |

**Operational Insight:** The South region drives over 68% of total withdrawal volume across the network. In a live environment, this would trigger prioritized vendor scheduling and tighter cash-out alert thresholds for Southern machines.

---

### 2. Low Cash Risk Detection

Flags machines approaching the cash-out threshold — enabling proactive vendor dispatch before service failure occurs. Uses a correlated subquery to return only the most recent status record per ATM, avoiding duplicate rows in a time-series dataset.

```sql
SELECT
    s.atm_id,
    l.location_name,
    l.region,
    s.cash_remaining,
    CASE
        WHEN s.cash_remaining < 1000 THEN 'CRITICAL — Dispatch Immediately'
        WHEN s.cash_remaining BETWEEN 1000 AND 2500 THEN 'WARNING — Schedule Within 24hrs'
        ELSE 'OK'
    END AS cash_status
FROM atm_daily_status s
JOIN atm_locations l ON s.atm_id = l.atm_id
WHERE s.cash_remaining < 2500
AND s.status_date = (
    SELECT MAX(status_date)
    FROM atm_daily_status
    WHERE atm_id = s.atm_id
)
ORDER BY s.cash_remaining ASC;
```

| ATM ID | Location | Region | Cash Remaining | Status |
|--------|----------|--------|:--------------:|--------|
| 101 | Chase Downtown | South | $750 | ⚠️ CRITICAL — Dispatch Immediately |
| 103 | CVS Midtown | Southeast | $1,800 | 🔶 WARNING — Schedule Within 24hrs |

**Operational Insight:** Two machines require immediate action. ATM 101 at Chase Downtown is in critical status with only $750 remaining — in a live environment this triggers same-day armored carrier dispatch. ATM 103 at CVS Midtown is in warning status and should be scheduled within 24 hours.

---

### 3. Vendor Workload Analysis

Evaluates how ATM servicing activity is distributed across armored carriers — used to identify vendor dependency risk and rebalance coverage territories.

```sql
SELECT
    s.armored_vendor,
    COUNT(DISTINCT s.atm_id) AS atms_serviced,
    SUM(s.withdrawals) AS total_transaction_volume
FROM atm_daily_status s
JOIN atm_locations l ON s.atm_id = l.atm_id
GROUP BY s.armored_vendor
ORDER BY total_transaction_volume DESC;
```

| Vendor  | ATMs Serviced | Total Transaction Volume |
|---------|:-------------:|:------------------------:|
| Brinks  | 2             | 24,500                   |
| Garda   | 1             | 14,700                   |
| Loomis  | 2             | 11,050                   |

**Operational Insight:** Brinks handles 49% of total network transaction volume — the highest single point of vendor dependency in the network. A Brinks outage or staffing shortage would represent the greatest operational risk exposure. In a live environment this finding would prompt a vendor diversification review.

---

### 4. Bank-Branded vs. Non-Bank ATM Performance

Compares withdrawal activity between bank-branded and independent ATM locations — used to guide placement strategy and cash replenishment prioritization.

```sql
SELECT
    l.bank_branded,
    COUNT(DISTINCT l.atm_id) AS total_atms,
    SUM(s.withdrawals) AS total_withdrawals,
    ROUND(AVG(s.withdrawals), 0) AS avg_withdrawals
FROM atm_daily_status s
JOIN atm_locations l ON s.atm_id = l.atm_id
GROUP BY l.bank_branded
ORDER BY l.bank_branded DESC;
```

| ATM Type     | Total ATMs | Total Withdrawals | Avg Withdrawals |
|--------------|:----------:|:-----------------:|:---------------:|
| Bank-Branded | 2          | 28,800            | 4,800           |
| Non-Bank     | 3          | 21,450            | 2,383           |

**Operational Insight:** Bank-branded ATMs average **2x the withdrawal volume** of non-bank locations. Despite being fewer machines, they generate 57% of total withdrawals. This directly informs cash loading schedules — bank-branded machines should be stocked more aggressively and monitored at tighter thresholds.

---

### 5. Top ATM by Region (Window Function)

Uses SQL window functions to rank ATMs within each region by withdrawal volume — identifying the highest-demand machine in every market for priority monitoring.

```sql
SELECT atm_id, location_name, region, withdrawals, regional_rank
FROM (
    SELECT
        s.atm_id,
        l.location_name,
        l.region,
        s.withdrawals,
        RANK() OVER (PARTITION BY l.region ORDER BY s.withdrawals DESC) AS regional_rank
    FROM atm_daily_status s
    JOIN atm_locations l ON s.atm_id = l.atm_id
) ranked
WHERE regional_rank = 1;
```

| ATM ID | Location | Region | Withdrawals | Rank |
|--------|----------|--------|:-----------:|:----:|
| 104 | Bank of America Central | South | 5,200 | #1 |
| 103 | CVS Midtown | Southeast | 3,700 | #1 |
| 105 | Walgreens Uptown | Midwest | 1,900 | #1 |

**Operational Insight:** Bank of America Central leads the entire network with 5,200 withdrawals — nearly 3x the top Midwest performer. These three locations represent the highest cash-out risk machines in their respective regions and would receive daily priority status checks in a live operation.

---

## 🛠️ SQL Skills Demonstrated

| Skill | Applied In |
|-------|------------|
| `JOIN` (INNER) | All queries — linking ATM status, location, and vendor tables |
| `GROUP BY` + `ORDER BY` | Regional demand, vendor workload, brand comparison |
| `SUM`, `COUNT`, `AVG`, `ROUND` | Aggregation across all analyses |
| `CASE WHEN` | Cash risk classification and escalation logic |
| Correlated Subquery | Deduplicating time-series records to latest status per ATM |
| `Window Functions` — `RANK()` | Top ATM per region ranking |
| `PARTITION BY` | Region-scoped performance ranking |
| Subquery / Derived Table | Filtering on window function results in MySQL |

---

## 📁 Project Files

| File | Description |
|------|-------------|
| `schema.sql` | Database and table definitions |
| `sample_data.sql` | Simulated ATM network dataset |
| `analysis.sql` | All analytical queries with inline comments |
| `README.md` | This documentation |

---

## 👤 About the Author

**Sean Codner** — Operations & Data Analyst
Houston, Texas

I spent years inside ATM network operations at **Cardtronics**, supporting performance monitoring across a network of 45,000+ machines nationwide. I tracked cash levels, coordinated vendor dispatch, monitored SLA compliance, and used data every day to prevent service failures before they happened.

This project formalizes that operational knowledge into a repeatable SQL analysis framework — translating the monitoring logic I used in the field into structured, queryable form.

**Connect:**
- 🔗 [LinkedIn](https://linkedin.com/in/sean-codner-aa60822b)
- 💻 [GitHub](https://github.com/SEANSKIDATA)

---

*Tools used: MySQL · SQL · GitHub*
