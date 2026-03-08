# ATM Network Operations Analysis

This SQL project analyzes ATM network operational data to simulate how operations teams monitor ATM performance, cash levels, and vendor workload.

The analysis reflects real-world ATM operations including monitoring withdrawal demand, identifying low cash risk, evaluating armored vendor workload, and ranking high-performing ATM locations.

---

## Business Context

ATM networks must maintain high service availability while coordinating cash logistics across multiple vendors and locations. Operations teams monitor transaction demand and cash thresholds to prevent outages and maintain uptime SLAs.

---

## Key Analysis

**Regional Withdrawal Demand**

Identifies regions with the highest ATM withdrawal activity.

**Low Cash Risk Detection**

Flags ATM machines approaching low cash thresholds that may require armored vendor dispatch.

**Vendor Workload Analysis**

Evaluates the distribution of ATM service activity across armored vendors.

**Bank-Branded ATM Performance**

Compares withdrawal demand between bank-branded and non-bank ATM locations.

**Top ATM by Region**

Uses SQL window functions to rank the highest-performing ATM in each region.

---

## SQL Skills Demonstrated

- JOIN operations
- GROUP BY aggregation
- Conditional filtering
- Common Table Expressions (CTEs)
- Window Functions (RANK)
- PARTITION BY
- Operational data analysis

---

## Tools Used

MySQL  
SQL
