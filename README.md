# Sales Analysis (Kaggle Dataset)

## Overview
An analytical SQL project built on the Kaggle Superstore Sales dataset,
answering ten real business questions across revenue trends, top performers,
growth patterns, customer retention, and profitability. The project
demonstrates translating stakeholder-style questions into correct, efficient
SQL — including window functions where they are genuinely the right tool,
not just for coverage.

## Dataset
Source: Kaggle "Sample Superstore" dataset (~9,994 rows), a single flat CSV
covering orders, customers, products, and sales/profit figures for a
fictional office-supply retailer, 2011-2014.

The flat CSV was normalized into four related tables during setup:
- `Customers` — customer_id (PK), customer_name, segment
- `Products` — product_id (PK), category, sub_category, product_name
- `Orders` — order_id (PK), customer_id (FK), order_date, ship_date,
  ship_mode, shipping location fields
- `OrderDetails` — row_id (PK), order_id (FK), product_id (FK), sales,
  quantity, discount, profit — one row per product within an order

**Data quality notes (handled during import):**
- Source dates were in DD-MM-YYYY text format and required conversion using
  `STR_TO_DATE()`.
- The CSV was Windows-encoded (not UTF-8), requiring
  `CHARACTER SET latin1` during `LOAD DATA INFILE`.
- 31 Product IDs in the source data map to two different product names
  (a known data quality quirk in this dataset) — one name was kept
  deterministically via `MAX()` during normalization, since Product ID is
  used as the primary key.

## How to Run
1. Open MySQL Workbench, connect to a local MySQL server (InnoDB support required).
2. Copy `raw_data/superstore_sales.csv` into your MySQL server's secure file
   directory (find it via `SHOW VARIABLES LIKE 'secure_file_priv';`).
3. Update the file path in the `LOAD DATA INFILE` statement in `setup.sql` to
   match your local secure file directory.
4. Run `setup.sql` — creates the database, the four normalized tables, a
   staging table, imports the CSV, and fans the data out into the normalized
   schema.
5. Run `analysis_queries.sql` for all ten business questions, including the
   window-function queries.
6. See `findings.md` for the plain-English takeaway from each query result.

## What This Project Demonstrates
- Importing and normalizing a real, messy, flat-file dataset into a proper
  relational schema — including handling real data quality issues (encoding,
  malformed CSV quoting, duplicate natural keys) rather than assuming clean
  input.
- Translating business questions into SQL, including a self-authored
  question (discount vs. profit margin) with a stated business justification.
- Using window functions (`LAG()`, `SUM() OVER`, `RANK()`) specifically
  where they are the correct tool — trend comparison, running totals, and
  within-group ranking — rather than as a syntax showcase.
- Pairing every query with a concrete, numbers-backed business takeaway
  rather than raw output alone.

## What I Learned

Importing this dataset taught me that real-world data is rarely clean. I hit
a date format mismatch (source dates were DD-MM-YYYY, not MySQL's expected
YYYY-MM-DD), a CSV encoding issue that required specifying CHARACTER SET
latin1, and malformed quoting inside product names that the Import Wizard
couldn't parse but LOAD DATA INFILE handled correctly with ESCAPED BY. I also
learned that even normalization isn't always straightforward — 31 Product
IDs in the source data mapped to two different product names, which meant
picking a resolution strategy (MAX()) rather than assuming a natural key is
always clean.

Working with MySQL's strict mode taught me why ONLY_FULL_GROUP_BY exists —
grouping by YEAR() and QUARTER() separately, then referencing them directly
in SELECT rather than re-wrapping the raw date column, avoided an error I
didn't expect the first time I hit it.

The window functions were the most valuable part. LAG() let me compare each
month's revenue to the previous month without writing a self-join, SUM()
OVER gave me a running total without collapsing my monthly rows, and RANK()
with PARTITION BY let me rank products within each category separately
rather than one global ranking. Understanding when to reach for a window
function instead of a plain GROUP BY was the real skill this project was
testing.

The most interesting finding was the discount-vs-profit analysis I authored
myself: Tables, Bookcases, and Supplies are all operating at a net loss
despite generating real revenue, driven by discount levels that appear to
exceed what their margins can sustain. That's the kind of insight a plain
revenue report would completely hide.