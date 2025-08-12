/* 
Step 1 : Create the project database and prepare the data structure
*/
CREATE DATABASE Hotel_Project;
USE Hotel_Project;

EXEC sp_rename 'orgin', 'origin';

ALTER TABLE traffic_transaction
ALTER COLUMN country_id SMALLINT;

ALTER TABLE booking_transaction
ALTER COLUMN booking_datetime DATETIME2;


/* Step 2: Create shared dimensions (date, time, origin) and populate with distinct values */


-- 1. Dim_date
CREATE TABLE dim_date (
    date_id DATE PRIMARY KEY,
    year INT,
    month INT,
    day INT
);

INSERT INTO dim_date (date_id, year, month, day)
SELECT DISTINCT
    ISNULL(CAST(d AS DATE), '1900-01-01') AS date_id,
    YEAR(ISNULL(d, '1900-01-01')),
    MONTH(ISNULL(d, '1900-01-01')),
    DAY(ISNULL(d, '1900-01-01'))
FROM (
    SELECT booking_datetime FROM booking_transaction
    UNION SELECT checkin_date FROM booking_transaction
    UNION SELECT checkout_date FROM booking_transaction
    UNION SELECT cancellation_date FROM booking_transaction
    UNION SELECT traffic_logtime FROM traffic_transaction
    UNION SELECT search_logtime FROM search_transaction
    UNION SELECT search_date FROM search_transaction
    UNION SELECT checkin FROM search_transaction
    UNION SELECT checkout FROM search_transaction
) AS all_dates(d);

select * FROM dim_date;

-- 2. dim_time
DROP TABLE dim_time;

CREATE TABLE dim_time (
    time_id TIME PRIMARY KEY,
    hour INT,
    minute INT,
    second INT
);

INSERT INTO dim_time (time_id, hour, minute, second)
SELECT DISTINCT
    t_cleaned AS time_id,
    DATEPART(HOUR, t_cleaned) AS hour,
    DATEPART(MINUTE, t_cleaned) AS minute,
    DATEPART(SECOND, t_cleaned) AS second
FROM (
    SELECT ISNULL(CAST(booking_datetime AS TIME), '00:00:00') AS t_cleaned FROM booking_transaction
    UNION
    SELECT ISNULL(CAST(traffic_logtime AS TIME), '00:00:00') FROM traffic_transaction
    UNION
    SELECT ISNULL(CAST(search_logtime AS TIME), '00:00:00') FROM search_transaction
) AS all_times;

select * FROM dim_time;

-- 3. dim_origin
DROP TABLE dim_origin;

CREATE TABLE dim_origin (
    origin_id INT IDENTITY(1,1) PRIMARY KEY,
    origin NVARCHAR(10) ,
    origin_name NVARCHAR(100)
);


INSERT INTO dim_origin (origin, origin_name)
SELECT DISTINCT
    ISNULL(t.origin, '-1') AS origin,
    ISNULL(o.origin_name, 'Unknown') AS origin_name
FROM (
    SELECT origin FROM booking_transaction
    UNION
    SELECT origin FROM search_transaction
) t
LEFT JOIN origin o ON t.origin = o.origin;

select * FROM dim_origin;

/* Step 3: Create table-specific dimensions and facts (Booking, Search, Traffic) and populate from each source */


--  3A: Booking Table.

-- 1. DIM HOTEL /Booking
CREATE TABLE dim_hotel (
    hotel_id FLOAT PRIMARY KEY,
    hotel_country NVARCHAR(100)
);

INSERT INTO dim_hotel
SELECT DISTINCT
    ISNULL(hotel_id, -1) AS hotel_id,
    ISNULL(hotel_country, 'Unknown') AS hotel_country
FROM booking_transaction;

-- The other way
SELECT SUM(case when hotel_id IS NULL then 1 else 0 end) AS null_hotel_id,
    SUM(CASE WHEN hotel_country IS NULL THEN 1 ELSE 0 END) AS null_hotel_country
FROM booking_transaction;


INSERT INTO dim_hotel
SELECT DISTINCT hotel_id, hotel_country
FROM booking_transaction;

-- 2. fact_booking_transaction and link to dimensions
DROP TABLE IF EXISTS fact_booking_transaction;

CREATE TABLE fact_booking_transaction (
    booking_id INT PRIMARY KEY,
    booking_date_id DATE FOREIGN KEY REFERENCES dim_date(date_id),
    booking_time_id TIME FOREIGN KEY REFERENCES dim_time(time_id),
    checkin_date_id DATE FOREIGN KEY REFERENCES dim_date(date_id),
    checkout_date_id DATE FOREIGN KEY REFERENCES dim_date(date_id),
    cancellation_date_id DATE FOREIGN KEY REFERENCES dim_date(date_id),

    origin NVARCHAR(10),
    origin_id INT FOREIGN KEY REFERENCES dim_origin(origin_id),
    hotel_id FLOAT FOREIGN KEY REFERENCES dim_hotel(hotel_id)
);


INSERT INTO fact_booking_transaction (
    booking_id,
    booking_date_id,
    booking_time_id,
    checkin_date_id,
    checkout_date_id,
    cancellation_date_id,
    origin,
    origin_id,
    hotel_id
)
SELECT
    b.booking_id,
    ISNULL(CAST(b.booking_datetime AS DATE), '1900-01-01') AS booking_date_id,
    ISNULL(CAST(b.booking_datetime AS TIME), '00:00:00') AS booking_time_id,
    ISNULL(b.checkin_date, '1900-01-01') AS checkin_date_id,
    ISNULL(b.checkout_date, '1900-01-01') AS checkout_date_id,
    ISNULL(b.cancellation_date, '1900-01-01') AS cancellation_date_id,
    
    ISNULL(b.origin, '-1') AS origin,
    ISNULL(d.origin_id, -1) AS origin_id,  
    
    ISNULL(b.hotel_id, -1) AS hotel_id
FROM booking_transaction b
LEFT JOIN dim_origin d
  ON b.origin = d.origin;


SELECT * FROM fact_booking_transaction;
SELECT * FROM booking_transaction;

--  3B: traffic Table.

-- 1. DIM COUNTRY
DROP TABLE dim_country;


CREATE TABLE dim_country (
    country_sk INT IDENTITY(1,1) PRIMARY KEY,
    country_id SMALLINT,
    country_code NVARCHAR(50),
    country_name NVARCHAR(100)
);

INSERT INTO dim_country (country_id, country_code, country_name)
SELECT DISTINCT
    ISNULL(country_id, -1),
    ISNULL(country_code, '-1'),
    ISNULL(country_name, 'Unknown')
FROM traffic_transaction;


SELECT * FROM dim_country;


-- 2. DIM CITY
CREATE TABLE dim_city (
    city_id FLOAT PRIMARY KEY,
    city_name NVARCHAR(100)
);

INSERT INTO dim_city (city_id, city_name)
SELECT DISTINCT 
    ISNULL(city_id, -1) AS city_id,
    ISNULL(city_name, 'Unknown') AS city_name
FROM traffic_transaction;



-- 3. DIM DESTINATION
DROP TABLE dim_destination_geo;

CREATE TABLE dim_destination_geo (
    destination_geo_id INT IDENTITY(1,1) PRIMARY KEY,
    country_name NVARCHAR(100),
    city_name NVARCHAR(100)
);

INSERT INTO dim_destination_geo (country_name, city_name)
SELECT DISTINCT
    ISNULL(country_name, 'Unknown'),
    ISNULL(city_name, 'Unknown')
FROM traffic_transaction;

SELECT *  FROM dim_destination_geo;



-- 4. DIM PAGE TYPE
DROP TABLE dim_page_type;

CREATE TABLE dim_page_type (
    page_type_sk INT IDENTITY(1,1) PRIMARY KEY,
    page_type_name NVARCHAR(100) 
);


INSERT INTO dim_page_type (page_type_name)
SELECT DISTINCT ISNULL(page_type_name, 'Unknown')
FROM traffic_transaction;


-- 5. DIM BROWSER OS
CREATE TABLE dim_browser_os (
    browser_os_sk INT IDENTITY(1,1) PRIMARY KEY,
    browser NVARCHAR(100),
    operating_system NVARCHAR(100)
);

INSERT INTO dim_browser_os (browser, operating_system)
SELECT DISTINCT
    ISNULL(browser, 'Unknown'),
    ISNULL(operating_system, 'Unknown')
FROM traffic_transaction;


-- 7. FACT traffic transaction
DROP TABLE fact_traffic_transaction;

CREATE TABLE fact_traffic_transaction (
    traffic_id INT IDENTITY(1,1) PRIMARY KEY,
    traffic_date_id DATE FOREIGN KEY REFERENCES dim_date_traffic(date_id),
    traffic_time_id TIME FOREIGN KEY REFERENCES dim_time(time_id),
    hotel_id FLOAT,
    destination_geo_id INT FOREIGN KEY REFERENCES dim_destination_geo(destination_geo_id),
    page_type_sk INT FOREIGN KEY REFERENCES dim_page_type(page_type_sk),
    browser_os_sk INT FOREIGN KEY REFERENCES dim_browser_os(browser_os_sk)
);


INSERT INTO fact_traffic_transaction (
    traffic_date_id,
    traffic_time_id,
    hotel_id,
    destination_geo_id,
    page_type_sk,
    browser_os_sk
)
SELECT
    ISNULL(CAST(t.traffic_logtime AS DATE), '1900-01-01') AS traffic_date_id,
    ISNULL(CAST(t.traffic_logtime AS TIME), '00:00:00') AS traffic_time_id,
    ISNULL(t.hotel_id, -1) AS hotel_id,
    ISNULL(dg.destination_geo_id, -1) AS destination_geo_id,
    ISNULL(dpt.page_type_sk, -1) AS page_type_sk,
    ISNULL(dbo.browser_os_sk, -1) AS browser_os_sk
FROM traffic_transaction t
LEFT JOIN dim_destination_geo dg
    ON ISNULL(t.city_name, 'Unknown') = ISNULL(dg.city_name, 'Unknown')
    AND ISNULL(t.country_name, 'Unknown') = ISNULL(dg.country_name, 'Unknown')
LEFT JOIN dim_page_type dpt
    ON ISNULL(t.page_type_name, 'Unknown') = ISNULL(dpt.page_type_name, 'Unknown')
LEFT JOIN dim_browser_os dbo
    ON ISNULL(t.browser, 'Unknown') = ISNULL(dbo.browser, 'Unknown')
    AND ISNULL(t.operating_system, 'Unknown') = ISNULL(dbo.operating_system, 'Unknown');


SELECT * FROM fact_traffic_transaction;



--  3C: serarch Table.

-- 1. dim_currency 
DROP TABLE IF EXISTS dim_currency;

CREATE TABLE dim_currency (
    currency_sk INT IDENTITY(1,1) PRIMARY KEY,
    currency_code NVARCHAR(10)
);

INSERT INTO dim_currency(currency_code)
SELECT DISTINCT ISNULL(currency_code, 'Unknown')
FROM search_transaction;



SET IDENTITY_INSERT dim_currency ON;

INSERT INTO dim_currency (currency_sk, currency_code)
VALUES (-1, 'Unknown');

SET IDENTITY_INSERT dim_currency OFF;




-- 2. FACT SEARCH

DROP TABLE IF EXISTS fact_search_transaction;

CREATE TABLE fact_search_transaction (
    id NVARCHAR(50) PRIMARY KEY,
    search_date_id DATE FOREIGN KEY REFERENCES dim_date(date_id),
    search_time_id TIME FOREIGN KEY REFERENCES dim_time(time_id),
    
    origin NVARCHAR(10),
    origin_id INT FOREIGN KEY REFERENCES dim_origin(origin_id),  
    
    currency_sk INT FOREIGN KEY REFERENCES dim_currency(currency_sk),
    city_id FLOAT,
    language_id INT,
    length_of_stay INT,
    adults INT,
    children INT,
    rooms INT
);



ALTER TABLE fact_search_transaction
ADD checkin_date_id DATE FOREIGN KEY REFERENCES dim_date(date_id),
    checkout_date_id DATE FOREIGN KEY REFERENCES dim_date(date_id);  



INSERT INTO fact_search_transaction (
  id,
  search_date_id,
  search_time_id,
  origin,
  origin_id,
  currency_sk,
  city_id,
  language_id,
  length_of_stay,
  adults,
  children,
  rooms,
  checkin_date_id,
  checkout_date_id
)
SELECT
  s.id,
  ISNULL(CAST(s.search_logtime AS DATE), '1900-01-01'),
  ISNULL(CAST(s.search_logtime AS TIME), '00:00:00'),
  ISNULL(s.origin, '-1'),
  ISNULL(do.origin_id, -1),
  ISNULL(dc.currency_sk, -1),
  ISNULL(s.city_id, -1),
  ISNULL(s.language_id, -1),
  ISNULL(s.length_of_stay, -1),
  ISNULL(s.adults, -1),
  ISNULL(s.children, -1),
  ISNULL(s.room, -1),
  ISNULL(CAST(s.checkin AS DATE), '1900-01-01'),
  ISNULL(CAST(s.checkout AS DATE), '1900-01-01')
FROM search_transaction s
LEFT JOIN dim_currency dc
  ON ISNULL(s.currency_code, '-1') = dc.currency_code
LEFT JOIN dim_origin do
  ON ISNULL(s.origin, '-1') = do.origin;

