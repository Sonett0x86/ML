-- 01_init.sql
-- 1) create table
CREATE TABLE IF NOT EXISTS raw_sales (
  datesold DATE,
  postcode INT,
  price BIGINT,
  propertyType VARCHAR(32),
  bedrooms INT
);

-- 2) load csv (server-side file, must be under secure_file_priv, usually /var/lib/mysql-files)
LOAD DATA INFILE '/var/lib/mysql-files/raw_sales.csv'
INTO TABLE raw_sales
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(datesold, postcode, price, propertyType, bedrooms);
