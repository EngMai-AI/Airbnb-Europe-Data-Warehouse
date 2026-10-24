   USE AirbnbDW;
   GO
   CREATE SCHEMA silver;  
   GO

DROP TABLE IF EXISTS silver.airbnb_listings;
GO

DECLARE @cols NVARCHAR(MAX) = N'
    room_type,
    CAST(realSum AS FLOAT)                                   AS price,
    LOG(1 + CAST(realSum AS FLOAT))                          AS log_price,
    CAST(CAST(person_capacity AS FLOAT) AS INT)              AS person_capacity,
    CAST(CAST(bedrooms AS FLOAT) AS INT)                     AS bedrooms,
    CASE WHEN CAST(host_is_superhost AS NVARCHAR(10)) IN (''True'',''1'') THEN 1 ELSE 0 END AS host_is_superhost,
    CAST(CAST(multi AS FLOAT) AS INT)                        AS is_multi_listing,
    CAST(CAST(biz AS FLOAT) AS INT)                          AS is_business,
    CAST(cleanliness_rating AS FLOAT)                        AS cleanliness_rating,
    CAST(guest_satisfaction_overall AS FLOAT)                AS guest_satisfaction,
    CAST(dist AS FLOAT)                                      AS dist_center_km,
    CAST(metro_dist AS FLOAT)                                AS dist_metro_km,
    CAST(attr_index AS FLOAT)                                AS attr_index,
    CAST(attr_index_norm AS FLOAT)                           AS attr_index_norm,
    CAST(rest_index AS FLOAT)                                AS rest_index,
    CAST(rest_index_norm AS FLOAT)                           AS rest_index_norm,
    CAST(lng AS FLOAT)                                       AS longitude,
    CAST(lat AS FLOAT)                                       AS latitude';

DECLARE @union NVARCHAR(MAX) = N'';

SELECT @union += CASE WHEN @union = N'' THEN N'' ELSE N' UNION ALL ' END
    + N'SELECT ''' + c.city + N''' AS city, ''' + d.day_type + N''' AS day_type, ' + @cols
    + N' FROM bronze.' + c.city + N'_' + d.day_type
    + N' WHERE CAST(realSum AS FLOAT) > 0'
FROM (VALUES ('amsterdam'),('athens'),('barcelona'),('berlin'),('budapest'),
             ('lisbon'),('london'),('paris'),('rome'),('vienna')) c(city)
CROSS JOIN (VALUES ('weekdays'),('weekends')) d(day_type);

DECLARE @sql NVARCHAR(MAX) = N'SELECT * INTO silver.airbnb_listings FROM (' + @union + N') t;';
EXEC sp_executesql @sql;
GO

ALTER TABLE silver.airbnb_listings ADD is_price_outlier INT NOT NULL DEFAULT 0,
                                       is_weekend       INT NOT NULL DEFAULT 0;
GO

DECLARE @p99 FLOAT = (SELECT TOP 1 PERCENTILE_CONT(0.99) WITHIN GROUP (ORDER BY price) OVER ()
                      FROM silver.airbnb_listings);

UPDATE silver.airbnb_listings
SET is_price_outlier = CASE WHEN price > @p99 THEN 1 ELSE 0 END,
    is_weekend       = CASE WHEN day_type = 'weekends' THEN 1 ELSE 0 END;
GO


USE AirbnbDW;
GO
SELECT COUNT(*) AS silver_rows, SUM(is_price_outlier) AS outliers
FROM silver.airbnb_listings;            

SELECT city, day_type, COUNT(*) AS n
FROM silver.airbnb_listings
GROUP BY city, day_type ORDER BY city, day_type;  



SELECT
    COUNT(*) - COUNT(price)              AS price_nulls,
    COUNT(*) - COUNT(room_type)          AS room_type_nulls,
    COUNT(*) - COUNT(person_capacity)    AS capacity_nulls,
    COUNT(*) - COUNT(bedrooms)           AS bedrooms_nulls,
    COUNT(*) - COUNT(cleanliness_rating) AS cleanliness_nulls,
    COUNT(*) - COUNT(guest_satisfaction) AS satisfaction_nulls,
    COUNT(*) - COUNT(dist_center_km)     AS dist_nulls,
    COUNT(*) - COUNT(latitude)           AS lat_nulls,
    COUNT(*) - COUNT(longitude)          AS lng_nulls
FROM silver.airbnb_listings;           

SELECT COUNT(*) AS duplicate_groups
FROM (SELECT city, day_type, price, latitude, longitude
      FROM silver.airbnb_listings
      GROUP BY city, day_type, price, latitude, longitude
      HAVING COUNT(*) > 1) d;          


      SELECT COUNT(*) AS full_duplicate_groups
FROM (
    SELECT city, day_type, room_type, price, person_capacity, bedrooms,
           host_is_superhost, is_multi_listing, is_business,
           cleanliness_rating, guest_satisfaction, dist_center_km, dist_metro_km,
           attr_index, rest_index, latitude, longitude
    FROM silver.airbnb_listings
    GROUP BY city, day_type, room_type, price, person_capacity, bedrooms,
             host_is_superhost, is_multi_listing, is_business,
             cleanliness_rating, guest_satisfaction, dist_center_km, dist_metro_km,
             attr_index, rest_index, latitude, longitude
    HAVING COUNT(*) > 1
) d;     


   SELECT MIN(person_capacity) min_cap, MAX(person_capacity) max_cap,
          MIN(bedrooms) min_bed, MAX(bedrooms) max_bed,
          MIN(cleanliness_rating) min_clean, MAX(cleanliness_rating) max_clean,
          MIN(guest_satisfaction) min_sat, MAX(guest_satisfaction) max_sat,
          MIN(dist_center_km) min_dist, MAX(dist_center_km) max_dist,
          MIN(dist_metro_km) min_metro, MAX(dist_metro_km) max_metro
   FROM silver.airbnb_listings;

   SELECT room_type, COUNT(*) AS n FROM silver.airbnb_listings GROUP BY room_type;