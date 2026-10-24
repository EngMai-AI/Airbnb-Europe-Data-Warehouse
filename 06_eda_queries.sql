/* 07 - Exploratory analysis queries on silver.airbnb_listings */
USE AirbnbDW;
GO

-- 1) Price summary
SELECT COUNT(*) AS n, MIN(price) AS min_price, ROUND(AVG(price),1) AS avg_price,
       MAX(price) AS max_price, ROUND(STDEV(price),1) AS std_price
FROM silver.airbnb_listings;

SELECT DISTINCT
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY price) OVER () AS p25,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY price) OVER () AS median,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY price) OVER () AS p75,
    PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY price) OVER () AS p99
FROM silver.airbnb_listings;

-- 2) Price by city (outliers excluded)
SELECT city, COUNT(*) AS listings, ROUND(AVG(price),1) AS avg_price
FROM silver.airbnb_listings
WHERE is_price_outlier = 0
GROUP BY city ORDER BY avg_price DESC;

-- 3) Room type
SELECT room_type, COUNT(*) AS n, ROUND(AVG(price),1) AS avg_price
FROM silver.airbnb_listings WHERE is_price_outlier = 0
GROUP BY room_type ORDER BY avg_price DESC;

-- 4) Weekday vs weekend
SELECT day_type, COUNT(*) AS n, ROUND(AVG(price),1) AS avg_price
FROM silver.airbnb_listings WHERE is_price_outlier = 0
GROUP BY day_type;

-- 5) Superhost effect
SELECT host_is_superhost, COUNT(*) AS n, ROUND(AVG(price),1) AS avg_price,
       ROUND(AVG(guest_satisfaction),1) AS avg_satisfaction
FROM silver.airbnb_listings WHERE is_price_outlier = 0
GROUP BY host_is_superhost;

-- 6) Bedrooms (small groups above 4 bedrooms are not reliable)
SELECT bedrooms, COUNT(*) AS n, ROUND(AVG(price),1) AS avg_price
FROM silver.airbnb_listings WHERE is_price_outlier = 0
GROUP BY bedrooms ORDER BY bedrooms;

-- 7) Most expensive listings (the flagged outliers)
SELECT TOP 10 city, room_type, bedrooms, person_capacity, ROUND(price,0) AS price
FROM silver.airbnb_listings WHERE is_price_outlier = 1 ORDER BY price DESC;
