# Airbnb European Cities: Data Warehouse & Power BI Dashboard

An end-to-end analytics project on Airbnb prices across 10 European cities. It uses a **medallion architecture (Bronze → Silver → Gold)** in SQL Server, a **star schema**, exploratory SQL analysis, and an interactive **Power BI** dashboard.

<img width="1331" height="744" alt="image" src="https://github.com/user-attachments/assets/a73362d2-3f4f-40b4-8e0c-2c2984dcda35" />
<img width="1327" height="752" alt="image" src="https://github.com/user-attachments/assets/97128281-a01f-41ee-9045-f59c38d099cc" />
<img width="1332" height="748" alt="image" src="https://github.com/user-attachments/assets/ff39d452-4908-4f53-8b51-7fe5338bfe21" />
<img width="1326" height="752" alt="image" src="https://github.com/user-attachments/assets/5de9dfec-2fb0-4fdd-a6b8-d7385b03feb8" />



## Dataset

- **Source:** [Airbnb Prices in European Cities (Kaggle)](https://www.kaggle.com/datasets/thedevastator/airbnb-prices-in-european-cities)
- **Content:** 20 CSV files (10 cities × weekdays/weekends)
- **Cities:** Amsterdam, Athens, Barcelona, Berlin, Budapest, Lisbon, London, Paris, Rome, Vienna
- Raw data is **not included** in this repo. Please download it from Kaggle and check the dataset license there.

## Architecture

| Layer | What it does |
|-------|--------------|
| **Bronze** | Raw CSV files loaded as-is, one table per city and day type (`bronze.<city>_<weekdays/weekends>`). |
| **Silver** | One unified table `silver.airbnb_listings` built with dynamic SQL (UNION ALL of the 20 tables). Columns are typed and renamed, rows with `price <= 0` are removed, `log_price` is added, and price outliers are flagged. |
| **Gold** | Star schema: `fact_listings` with `dim_city`, `dim_room_type`, `dim_day_type`. Views: `vw_listings`, `vw_city_summary`. |

**Star schema**

```
dim_city ───────┐
dim_room_type ──┼── fact_listings
dim_day_type ───┘
```

**Final row count:** 51,707 (identical in Silver and Gold).

## Repository structure

```
airbnb-europe-dw/
├── sql/
│   ├── 01_bronze.sql        # database, schema, load checks
│   ├── 02_silver.sql        # cleaning, unification, outlier flag, quality checks
│   ├── 03_gold.sql          # star schema + validation
│   ├── 04_views.sql         # indexes + views
│   ├── 05_hosts.sql         # updates vw_listings (adds is_multi_listing, is_business)
│   └── 06_eda_queries.sql   # exploratory analysis
├── powerbi/
│   └── Airbnb.pbix
├── images/
│   └── dashboard.png
└── README.md
```

## How to run

1. Create a SQL Server database and import the 20 Kaggle CSV files into the `bronze` schema, using the table names `<city>_weekdays` and `<city>_weekends` (for example `bronze.amsterdam_weekdays`).
2. Run the scripts in `sql/` **in order**, from `01` to `06`.
   - Note: `05_hosts.sql` redefines `gold.vw_listings` from `04_views.sql` to add `is_multi_listing` and `is_business`. Run it after `04`.
3. Open `powerbi/Airbnb.pbix`, point the data source to your SQL Server instance (`AirbnbDW`), and refresh.

## Data cleaning decisions

- Removed rows where `realSum` (price) is 0 or negative.
- Added `log_price = LOG(1 + price)` to handle the right-skewed price distribution.
- Flagged price outliers with `is_price_outlier = 1` when price is above the **99th percentile**. Rows are flagged, not deleted, so analysis can include or exclude them.
- Cast text and boolean columns to proper types (for example `host_is_superhost` → BIT).
- Ran checks for NULLs, value ranges, and duplicates.

## Key findings

All averages below exclude price outliers (top 1%, 518 rows), which leaves 51,189 rows.

- **Prices are strongly right-skewed.** The mean (≈ 280) is well above the median (≈ 211), and the maximum (≈ 18,545) is more than 15× the 99th percentile (≈ 1,161). This is why I added a log-transformed price and flagged the top 1% as outliers.
- **City matters most.** Amsterdam is the most expensive city (≈ 496), about 3.3× more than Athens (≈ 148), the cheapest. Paris (≈ 368) and London (≈ 323) follow; Rome, Budapest, and Athens are the most affordable.
- **Room type is a strong driver.** Entire homes/apartments average ≈ 300, about 53% more than private rooms (≈ 196) and roughly 2× shared rooms (≈ 144). Shared rooms are under 1% of rows (366), so their average should be read with caution.
- **Weekday vs weekend:** weekend prices are only slightly higher (≈ 266 vs ≈ 257, about +3.4%), so day type is a much weaker driver than city or room type.
- **Superhosts** (≈ 26% of rows) have higher guest satisfaction (≈ 96.9 vs 91.1) but slightly lower average prices (≈ 240 vs ≈ 269). This is a descriptive difference and may partly reflect differences in city and room-type mix.
- **Bedrooms:** average price rises from ≈ 232 (1 bedroom) to ≈ 355 (2) and ≈ 449 (3). Groups with 4 or more bedrooms have very few rows (77 or fewer), so they are not reliable.
- **Outliers:** the 10 most expensive rows (≈ 12,900 to 18,545) come from London, Vienna, Athens, and Paris. Several are private rooms priced above 13,000, and the single highest price is in Athens, the cheapest city on average. These values look implausible for nightly rates, which supports flagging them as outliers.

## Limitations

- **No listing ID in the source data.** `listing_id` in the fact table is a surrogate key. Each row is a listing observed for one day type (weekday or weekend), so the 51,707 rows are **not** 51,707 unique properties.
- Outliers use a **global** P99 threshold, not a per-city threshold, so expensive cities are flagged more often.
- Groups with more than 4 bedrooms have small sample sizes and are not reliable.
- Prices are as provided in the dataset; currency and the exact booking length are not specified by the source.

## Tools

SQL Server (T-SQL, dynamic SQL, views, indexes) · Power BI (DAX) · Medallion architecture · Star schema modeling

## Author

**Mai Reda** · [LinkedIn](www.linkedin.com/in/mai-reda-74477423b) · [GitHub](https://github.com/EngMai-AI))
