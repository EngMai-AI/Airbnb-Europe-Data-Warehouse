/* Gold layer: star schema
   Grain: one Airbnb listing for one day type (weekday or weekend).
   Dimensions: dim_city, dim_room_type, dim_day_type
   Fact: fact_listings (listing_id is a surrogate key, the source has no listing id)
   Source: silver.airbnb_listings */


USE AirbnbDW;
GO
DROP TABLE IF EXISTS gold.fact_listings;
DROP TABLE IF EXISTS gold.dim_city;
DROP TABLE IF EXISTS gold.dim_room_type;
DROP TABLE IF EXISTS gold.dim_day_type;
GO

CREATE TABLE gold.dim_city      (city_id INT IDENTITY(1,1) PRIMARY KEY, city NVARCHAR(50) NOT NULL UNIQUE);
CREATE TABLE gold.dim_room_type (room_type_id INT IDENTITY(1,1) PRIMARY KEY, room_type NVARCHAR(50) NOT NULL UNIQUE);
CREATE TABLE gold.dim_day_type  (day_type_id INT IDENTITY(1,1) PRIMARY KEY, day_type NVARCHAR(20) NOT NULL UNIQUE);
GO

INSERT INTO gold.dim_city(city)           SELECT DISTINCT city      FROM silver.airbnb_listings ORDER BY city;
INSERT INTO gold.dim_room_type(room_type) SELECT DISTINCT room_type FROM silver.airbnb_listings ORDER BY room_type;
INSERT INTO gold.dim_day_type(day_type)   SELECT DISTINCT day_type  FROM silver.airbnb_listings ORDER BY day_type;
GO

CREATE TABLE gold.fact_listings (
    listing_id         INT IDENTITY(1,1) PRIMARY KEY,
    city_id            INT NOT NULL REFERENCES gold.dim_city(city_id),
    room_type_id       INT NOT NULL REFERENCES gold.dim_room_type(room_type_id),
    day_type_id        INT NOT NULL REFERENCES gold.dim_day_type(day_type_id),
    price              FLOAT NOT NULL,
    log_price          FLOAT NOT NULL,
    is_price_outlier   BIT,
    person_capacity    INT,
    bedrooms           INT,
    host_is_superhost  BIT,
    is_multi_listing   BIT,
    is_business        BIT,
    cleanliness_rating FLOAT,
    guest_satisfaction FLOAT,
    dist_center_km     FLOAT,
    dist_metro_km      FLOAT,
    attr_index         FLOAT,
    attr_index_norm    FLOAT,
    rest_index         FLOAT,
    rest_index_norm    FLOAT,
    latitude           FLOAT,
    longitude          FLOAT
);
GO

INSERT INTO gold.fact_listings
    (city_id, room_type_id, day_type_id, price, log_price, is_price_outlier, person_capacity, bedrooms,
     host_is_superhost, is_multi_listing, is_business, cleanliness_rating, guest_satisfaction,
     dist_center_km, dist_metro_km, attr_index, attr_index_norm, rest_index, rest_index_norm,
     latitude, longitude)
SELECT c.city_id, r.room_type_id, d.day_type_id, s.price, s.log_price, s.is_price_outlier,
       s.person_capacity, s.bedrooms, s.host_is_superhost, s.is_multi_listing, s.is_business,
       s.cleanliness_rating, s.guest_satisfaction, s.dist_center_km, s.dist_metro_km,
       s.attr_index, s.attr_index_norm, s.rest_index, s.rest_index_norm, s.latitude, s.longitude
FROM silver.airbnb_listings s
JOIN gold.dim_city      c ON c.city      = s.city
JOIN gold.dim_room_type r ON r.room_type = s.room_type
JOIN gold.dim_day_type  d ON d.day_type  = s.day_type;
GO




SELECT (SELECT COUNT(*) FROM silver.airbnb_listings) AS silver_rows,
       (SELECT COUNT(*) FROM gold.fact_listings)     AS fact_rows;      

SELECT COUNT(*) AS bad_prices FROM gold.fact_listings WHERE price <= 0; -- 0

SELECT c.city, ROUND(AVG(f.price),1) AS avg_price, COUNT(*) AS listings
FROM gold.fact_listings f JOIN gold.dim_city c ON c.city_id = f.city_id
GROUP BY c.city ORDER BY avg_price DESC;           