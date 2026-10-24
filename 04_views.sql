USE AirbnbDW;
GO

CREATE INDEX ix_fact_city ON gold.fact_listings(city_id);
CREATE INDEX ix_fact_room ON gold.fact_listings(room_type_id);
CREATE INDEX ix_fact_day  ON gold.fact_listings(day_type_id);
GO

CREATE OR ALTER VIEW gold.vw_listings AS
SELECT f.listing_id, c.city, r.room_type, d.day_type,
       f.price, f.log_price, f.is_price_outlier, f.person_capacity, f.bedrooms,
       f.host_is_superhost, f.guest_satisfaction, f.cleanliness_rating,
       f.dist_center_km, f.dist_metro_km, f.attr_index_norm, f.rest_index_norm,
       f.latitude, f.longitude
FROM gold.fact_listings f
JOIN gold.dim_city      c ON c.city_id      = f.city_id
JOIN gold.dim_room_type r ON r.room_type_id = f.room_type_id
JOIN gold.dim_day_type  d ON d.day_type_id  = f.day_type_id;
GO

CREATE OR ALTER VIEW gold.vw_city_summary AS
SELECT c.city, COUNT(*) AS listings, ROUND(AVG(f.price),1) AS avg_price,
       ROUND(AVG(f.guest_satisfaction),1) AS avg_satisfaction,
       ROUND(100.0*AVG(CAST(f.host_is_superhost AS INT)),1) AS superhost_pct
FROM gold.fact_listings f JOIN gold.dim_city c ON c.city_id = f.city_id
GROUP BY c.city;
GO

SELECT COUNT(*) AS view_rows FROM gold.vw_listings;   -- 51707
SELECT * FROM gold.vw_city_summary ORDER BY avg_price DESC;