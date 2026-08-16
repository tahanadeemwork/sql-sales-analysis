CREATE DATABASE IF NOT EXISTS sql_sales_analysis;
USE sql_sales_analysis;

CREATE TABLE Customers (
    customer_id     VARCHAR(20) PRIMARY KEY,
    customer_name   VARCHAR(100) NOT NULL,
    segment         VARCHAR(50) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE Products (
    product_id      VARCHAR(30) PRIMARY KEY,
    category        VARCHAR(50) NOT NULL,
    sub_category    VARCHAR(50) NOT NULL,
    product_name    VARCHAR(255) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE Orders (
    order_id        VARCHAR(20) PRIMARY KEY,
    customer_id     VARCHAR(20) NOT NULL,
    order_date      DATE NOT NULL,
    ship_date       DATE NOT NULL,
    ship_mode       VARCHAR(50) NOT NULL,
    country         VARCHAR(50) NOT NULL,
    city            VARCHAR(100) NOT NULL,
    state           VARCHAR(50) NOT NULL,
    postal_code     VARCHAR(10),
    region          VARCHAR(50) NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE OrderDetails (
    row_id          INT PRIMARY KEY,
    order_id        VARCHAR(20) NOT NULL,
    product_id      VARCHAR(30) NOT NULL,
    sales           DECIMAL(10,2) NOT NULL,
    quantity        INT NOT NULL,
    discount        DECIMAL(4,2) NOT NULL,
    profit          DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES Orders(order_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Staging table mirrors the raw CSV exactly (no types enforced yet — landing zone only)
CREATE TABLE staging_superstore (
    row_id          INT,
    order_id        VARCHAR(20),
    order_date      VARCHAR(20),
    ship_date       VARCHAR(20),
    ship_mode       VARCHAR(50),
    customer_id     VARCHAR(20),
    customer_name   VARCHAR(100),
    segment         VARCHAR(50),
    country         VARCHAR(50),
    city            VARCHAR(100),
    state           VARCHAR(50),
    postal_code     VARCHAR(10),
    region          VARCHAR(50),
    product_id      VARCHAR(30),
    category        VARCHAR(50),
    sub_category    VARCHAR(50),
    product_name    VARCHAR(255),
    sales           DECIMAL(10,2),
    quantity        INT,
    discount        DECIMAL(4,2),
    profit          DECIMAL(10,2)
) ENGINE=InnoDB;

-- CHARACTER SET latin1: source CSV was Windows-encoded, not UTF-8 — without this,
-- LOAD DATA INFILE fails on special characters (e.g. 'Konftel 250 Conference')
-- ESCAPED BY '"': handles doubled "" inside quoted product names correctly
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/superstore_sales.csv'
INTO TABLE staging_superstore
CHARACTER SET latin1
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
ESCAPED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

INSERT INTO Customers (customer_id, customer_name, segment)
SELECT DISTINCT customer_id, customer_name, segment
FROM staging_superstore;

-- MAX() + GROUP BY: 31 Product IDs in the source map to two different product names
-- (a known data quality issue in this dataset) — one name is kept deterministically
-- since product_id is the primary key and must be unique
INSERT INTO Products (product_id, category, sub_category, product_name)
SELECT product_id, MAX(category), MAX(sub_category), MAX(product_name)
FROM staging_superstore
GROUP BY product_id;

INSERT INTO Orders (order_id, customer_id, order_date, ship_date, ship_mode, country, city, state, postal_code, region)
SELECT DISTINCT
    order_id,
    customer_id,
    STR_TO_DATE(order_date, '%d-%m-%Y'),
    STR_TO_DATE(ship_date, '%d-%m-%Y'),
    ship_mode,
    country,
    city,
    state,
    postal_code,
    region
FROM staging_superstore;

INSERT INTO OrderDetails (row_id, order_id, product_id, sales, quantity, discount, profit)
SELECT row_id, order_id, product_id, sales, quantity, discount, profit
FROM staging_superstore;

