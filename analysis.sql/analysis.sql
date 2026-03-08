USE atm_network_analysis;

-- Total withdrawals by region

SELECT
    l.region,
    SUM(s.withdrawals) AS total_withdrawals
FROM atm_daily_status s
JOIN atm_locations l
    ON s.atm_id = l.atm_id
GROUP BY l.region
ORDER BY total_withdrawals DESC;

-- ATMs with low remaining cash

SELECT
    l.atm_id,
    l.location_name,
    l.region,
    s.status_date,
    s.cash_remaining
FROM atm_daily_status s
JOIN atm_locations l
    ON s.atm_id = l.atm_id
WHERE s.cash_remaining < 8000
ORDER BY s.cash_remaining ASC;
-- Vendor workload by withdrawals

SELECT
    s.armored_vendor,
    COUNT(DISTINCT s.atm_id) AS atms_serviced,
    SUM(s.withdrawals) AS total_withdrawals
FROM atm_daily_status s
GROUP BY s.armored_vendor
ORDER BY total_withdrawals DESC;

-- Bank branded vs non-bank ATM performance

SELECT
    l.bank_branded,
    COUNT(DISTINCT l.atm_id) AS total_atms,
    SUM(s.withdrawals) AS total_withdrawals,
    ROUND(AVG(s.withdrawals),2) AS avg_withdrawals
FROM atm_daily_status s
JOIN atm_locations l
    ON s.atm_id = l.atm_id
GROUP BY l.bank_branded;

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