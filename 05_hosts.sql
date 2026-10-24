USE AirbnbDW;
GO
CREATE OR ALTER VIEW gold.vw_listings AS
SELECT f.listing_id, c.city, r.room_type, d.day_type,
       f.price, f.log_price, f.is_price_outlier, f.person_capacity, f.bedrooms,
       f.host_is_superhost, f.is_multi_listing, f.is_business,
       f.guest_satisfaction, f.cleanliness_rating,
       f.dist_center_km, f.dist_metro_km, f.attr_index, f.attr_index_norm,
       f.rest_index, f.rest_index_norm, f.latitude, f.longitude
FROM gold.fact_listings f
JOIN gold.dim_city      c ON c.city_id      = f.city_id
JOIN gold.dim_room_type r ON r.room_type_id = f.room_type_id
JOIN gold.dim_day_type  d ON d.day_type_id  = f.day_type_id;
GO

USE AirbnbDW;
GO
SELECT TOP 3 listing_id, city, is_multi_listing, is_business
FROM gold.vw_listings;