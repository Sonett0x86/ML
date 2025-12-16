USE house_prices;

DROP TABLE IF EXISTS raw_sales;

CREATE TABLE raw_sales (
  datesold DATE,
  postcode INT,
  price BIGINT,
  propertyType VARCHAR(32),
  bedrooms INT
);

-- 如果 CSV 第一行是表头, 用 IGNORE 1 LINES
LOAD DATA INFILE '/var/lib/mysql-files/raw_sales.csv'
INTO TABLE raw_sales
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(datesold, postcode, price, propertyType, bedrooms);
