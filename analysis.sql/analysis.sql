USE atm_network_analysis;

-- ============================================================
-- Query 1: Regional Withdrawal Demand
-- ============================================================
SELECT
    l.region,
    SUM(s.withdrawals) AS total_withdrawals,
    COUNT(DISTINCT s.atm_id) AS atm_count,
    ROUND(AVG(s.withdrawals), 0) AS avg_withdrawals_per_atm
FROM atm_daily_status s
JOIN atm_locations l
    ON s.atm_id = l.atm_id
GROUP BY l.region
ORDER BY total_withdrawals DESC;

-- ============================================================
-- Query 2: Low Cash Risk Detection (Correlated Subquery + CASE)
-- ============================================================
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

-- ============================================================
-- Query 3: Vendor Workload Analysis
-- ============================================================
SELECT
    s.armored_vendor,
    COUNT(DISTINCT s.atm_id) AS atms_serviced,
    SUM(s.withdrawals) AS total_withdrawals
FROM atm_daily_status s
GROUP BY s.armored_vendor
ORDER BY total_withdrawals DESC;

-- ============================================================
-- Query 4: Bank-Branded vs Non-Bank ATM Performance
-- ============================================================
SELECT
    l.bank_branded,
    COUNT(DISTINCT l.atm_id) AS total_atms,
    SUM(s.withdrawals) AS total_withdrawals,
    ROUND(AVG(s.withdrawals), 0) AS avg_withdrawals
FROM atm_daily_status s
JOIN atm_locations l
    ON s.atm_id = l.atm_id
GROUP BY l.bank_branded
ORDER BY l.bank_branded DESC;

-- ============================================================
-- Query 5: Top ATM by Region (CTE + Window Function)
-- ============================================================
WITH atm_totals AS (
    SELECT
        l.region,
        l.atm_id,
        l.location_name,
        SUM(s.withdrawals) AS total_withdrawals
    FROM atm_daily_status s
    JOIN atm_locations l
        ON s.atm_id = l.atm_id
    GROUP BY l.region, l.atm_id, l.location_name
),
ranked AS (
    SELECT
        region,
        atm_id,
        location_name,
        total_withdrawals,
        RANK() OVER (
            PARTITION BY region
            ORDER BY total_withdrawals DESC
        ) AS atm_rank
    FROM atm_totals
)
SELECT *
FROM ranked
WHERE atm_rank = 1
ORDER BY total_withdrawals DESC;
