-- raw_data_table
--      ↓
-- cleaned_table
--      ↓
-- analysis_features_table
--      ↓
-- models / dashboards
-- two tables imported - one raw, and one is being cleaned

# DB Browser - SQL Lite

-- checking the rows:
 SELECT COUNT(*)
 FROM flipkart_mobiles;
 
#Inspect the Raw Data
SELECT *
FROM flipkart_mobiles
LIMIT 10;

-- Data Cleaning: finding missing values
SELECT
COUNT(*) - COUNT(Brand) AS missing_brand,
COUNT(*) - COUNT(Model) AS missing_model,
COUNT(*) - COUNT(Color) AS missing_color,
COUNT(*) - COUNT(Memory) AS missing_ram,
COUNT(*) - COUNT(Storage) AS missing_storage,
COUNT(*) - COUNT(Rating) AS missing_rating,
COUNT(*) - COUNT("Selling Price") AS missing_price,
COUNT(*) - COUNT("Original Price") AS missing_original_price
FROM flipkart_mobiles;

-- Handling missing values:
DELETE FROM flipkart_mobiles
WHERE memory IS NULL
OR storage IS NULL;

-- check case inconsistencies in brand names.
SELECT DISTINCT brand
FROM flipkart_mobiles
ORDER BY brand;

-- Step 4 — Standardize Brand Names: we choose to make all upepr CASE
UPDATE flipkart_mobiles
SET brand = UPPER(brand);

-- verifying fix:
SELECT DISTINCT brand
FROM flipkart_mobiles
ORDER BY brand;
-- Next Step — Trim Hidden Spaces

UPDATE flipkart_mobiles
SET brand = TRIM(brand);

UPDATE flipkart_mobiles
SET 
model = TRIM(model),
color = TRIM(color),
memory = TRIM(memory),
storage = TRIM(storage);

-- Checking Duplicates:

SELECT
brand,
model,
color,
memory,
storage,
COUNT(*) AS duplicate_count
FROM flipkart_mobiles
GROUP BY
brand, model, color, memory, storage
HAVING COUNT(*) > 1;

-- there are 156 rows of duplicates:

DELETE FROM flipkart_mobiles
WHERE rowid NOT IN (
SELECT MIN(rowid)
FROM flipkart_mobiles
GROUP BY brand, model, color, memory, storage
);

-- confirming deletion: 
SELECT
brand,
model,
color,
memory,
storage,
COUNT(*)
FROM flipkart_mobiles
GROUP BY
brand, model, color, memory, storage
HAVING COUNT(*) > 1;

-- checking data types::
PRAGMA table_info(flipkart_mobiles);

-- memory and storage are texts for analytics we prefer them to be numerical
-- inspecting these values: 
SELECT 
    typeof("Selling Price") AS price_type, 
    typeof("Original Price") AS mrp_type, 
    typeof(Rating) AS rating_type
FROM flipkart_mobiles 
LIMIT 5;
-- checking others again
SELECT DISTINCT memory
FROM flipkart_mobiles
ORDER BY memory;

SELECT DISTINCT storage
FROM flipkart_mobiles;

-- there is 1 GB in memory and storage, we need only numbers and not GB
-- we will later alter this

-- working with data integrity:

-- validating price logic:  Original price must be ≥ selling price.
SELECT *
FROM flipkart_mobiles
WHERE "Original Price" < "Selling Price";

DELETE FROM flipkart_mobiles
WHERE "Original Price" < "Selling Price";

-- checking rating range: 
SELECT *
FROM flipkart_mobiles
WHERE rating > 5 OR rating < 0;
-- missing ratings check:
SELECT COUNT(*) - COUNT(Rating) AS missing_ratings
FROM flipkart_mobiles_clean;

-- creating flag variable for missing ratings
ALTER TABLE flipkart_mobiles_clean
ADD COLUMN has_rating INTEGER;
UPDATE flipkart_mobiles_clean
SET has_rating =
CASE
WHEN rating IS NULL THEN 0
ELSE 1
END;

-- checking price outliers
SELECT
MIN("Selling Price"),
MAX("Selling Price"),
AVG("Selling Price")
FROM flipkart_mobiles;

SELECT *
FROM flipkart_mobiles
WHERE "Selling Price" <= 1500;

SELECT brand, model, "Selling Price"
FROM flipkart_mobiles
WHERE "Selling Price" >= 150000;

SELECT * FROM flipkart_mobiles
WHERE "Selling Price" = 0 
OR "Original Price" = 0;

--changing name 
ALTER TABLE flipkart_mobiles
RENAME TO flipkart_mobiles_clean;

-- checking
SELECT * FROM 
flipkart_mobiles_clean;

-- new columns for memory and storage without "GB" for analytical work:

ALTER TABLE flipkart_mobiles_clean
ADD COLUMN ram_gb INTEGER;
UPDATE flipkart_mobiles_clean
SET ram_gb = CAST(REPLACE(Memory,' GB','') AS INTEGER);

ALTER TABLE flipkart_mobiles_clean
ADD COLUMN storage_gb INTEGER;
UPDATE flipkart_mobiles_clean
SET storage_gb = CAST(REPLACE(Storage,' GB','') AS INTEGER);

-- checking

SELECT
brand,
memory,
ram_gb,
storage,
storage_gb,
"Selling Price",
"Original Price"
FROM flipkart_mobiles_clean
LIMIT 10;

-- Feature Engineering: 
ALTER TABLE flipkart_mobiles_clean
ADD COLUMN discount_pct REAL;

UPDATE flipkart_mobiles_clean
SET discount_pct =
("Original Price"- "Selling Price") * 1.0 / "Original Price";

-- verifying discount column:

SELECT * FROM flipkart_mobiles_clean;

-- decimals are too many places and we need percentages for a/b testing
UPDATE flipkart_mobiles_clean
SET discount_pct =
ROUND(("Original Price" - "Selling Price") * 100.0 / "Original Price", 2);

-- verifying
SELECT * FROM flipkart_mobiles_clean;

-- checking any discount outliers:
-- See all outlier rows
SELECT brand, model, "Selling Price", "Original Price", discount_pct
FROM flipkart_mobiles_clean
WHERE discount_pct < 0       -- negative discount
OR discount_pct > 90         -- unrealistically high
OR discount_pct = 0          -- no discount (optional flag)
;

--  no negative discount case, multiple no discounts: this is common in e-commerce

-- frequency of zero discounts

SELECT
COUNT(*) AS zero_discount_count
FROM flipkart_mobiles_clean
WHERE discount_pct = 0;

-- 1738 zero discounts
DELETE FROM flipkart_mobiles_clean
WHERE discount_pct < 0
;

-- in feature engineering : disocunt strategy group for a/b testing:
 ALTER TABLE flipkart_mobiles_clean
ADD COLUMN discount_group TEXT;

UPDATE flipkart_mobiles_clean
SET discount_group =
CASE
WHEN discount_pct >= 30 THEN 'Aggressive'
WHEN discount_pct BETWEEN 10 AND 30 THEN 'Moderate'
ELSE 'Low'
END;

-- making market price segmentation
ALTER TABLE flipkart_mobiles_clean
ADD COLUMN price_segment TEXT;
UPDATE flipkart_mobiles_clean
SET price_segment =
CASE
WHEN "Selling Price" < 15000 THEN 'Budget'
WHEN "Selling Price" BETWEEN 15000 AND 40000 THEN 'Mid'
ELSE 'Premium'
END;

-- storage tier:
ALTER TABLE flipkart_mobiles_clean
ADD COLUMN storage_tier TEXT;
UPDATE flipkart_mobiles_clean
SET storage_tier =
CASE
WHEN storage_gb <= 64 THEN 'Low Storage'
WHEN storage_gb <= 128 THEN 'Medium Storage'
ELSE 'High Storage'
END;

-- For brand tier to be used in game theory, we first calcualte averages:
SELECT
brand,
COUNT(*) AS models,
ROUND(AVG(selling_price), 2) AS avg_brand_price
FROM flipkart_mobiles_clean
GROUP BY brand
ORDER BY avg_brand_price DESC;
-- creating new column:

ALTER TABLE flipkart_mobiles_clean
ADD COLUMN brand_tier TEXT;
-- Tier setting:
UPDATE flipkart_mobiles_clean
SET brand_tier =
(
    SELECT CASE
        WHEN AVG(f2.selling_price) > 40000 THEN 'Premium'
        WHEN AVG(f2.selling_price) BETWEEN 20000 AND 40000 THEN 'Mid'
        ELSE 'Budget'
    END
    FROM flipkart_mobiles_clean f2
    WHERE f2.brand = flipkart_mobiles_clean.brand
);
-- verification:
SELECT
brand,
brand_tier,
ROUND(AVG(selling_price),2) AS avg_price
FROM flipkart_mobiles_clean
GROUP BY brand, brand_tier
ORDER BY avg_price DESC;



-- checking the result:
 SELECT
brand_tier,
COUNT(*) AS phones,
AVG(discount_pct) AS avg_discount
FROM flipkart_mobiles_clean
GROUP BY brand_tier;


--- EDA in SQL ---

-- Brand Positioning:
SELECT
brand,
COUNT(*) AS models,
AVG("Selling Price") AS avg_price,
AVG(discount_pct) AS avg_discount
FROM flipkart_mobiles_clean
GROUP BY brand
ORDER BY avg_price DESC;

-- Price Segment × Discount Group
SELECT
price_segment,
discount_group,
COUNT(*) AS models,
ROUND(AVG(discount_pct),2) AS avg_discount
FROM flipkart_mobiles_clean
GROUP BY price_segment, discount_group
ORDER BY price_segment, discount_group;

-- Brand Tier × Discount Strategy:

SELECT
brand_tier,
discount_group,
COUNT(*) AS models,
ROUND(AVG(discount_pct),2) AS avg_discount
FROM flipkart_mobiles_clean
GROUP BY brand_tier, discount_group;

-- Rating vs Price Segment:
SELECT
price_segment,
COUNT(*) AS total,
ROUND(AVG(rating),2) AS avg_rating
FROM flipkart_mobiles_clean
WHERE rating IS NOT NULL
GROUP BY price_segment;

-- Discount Distribution:
SELECT
discount_group,
COUNT(*) AS count,
ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM flipkart_mobiles_clean),2) AS pct
FROM flipkart_mobiles_clean
GROUP BY discount_group;

-- Samsung vs Xiaomi (Game Theory Prep):
SELECT
brand,
COUNT(*) AS models,
AVG(discount_pct) AS avg_discount,
AVG("Selling Price") AS avg_price
FROM flipkart_mobiles_clean
WHERE brand IN ('SAMSUNG','XIAOMI')
GROUP BY brand;

-- A/B Prep Ratings vs Discount:
SELECT
discount_group,
COUNT(*) AS total,
COUNT(CASE WHEN has_rating = 1 THEN 1 END) AS rated,
AVG(CASE WHEN has_rating = 1 THEN rating END) AS avg_rating
FROM flipkart_mobiles_clean
GROUP BY discount_group;

-- changing name : 
ALTER TABLE flipkart_mobiles_clean
RENAME COLUMN "Selling Price" TO selling_price;

ALTER TABLE flipkart_mobiles_clean
RENAME COLUMN "Original Price" TO original_price;

-- Market Share by Segment
-- Who dominates each segment?
SELECT 
    price_segment,
    brand,
    COUNT(*) AS models,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY price_segment), 2) AS market_share_pct
FROM flipkart_mobiles_clean
WHERE brand IN ('SAMSUNG', 'XIAOMI', 'REALME', 'OPPO', 'VIVO')  -- Top 5 brands
GROUP BY price_segment, brand
ORDER BY price_segment, market_share_pct DESC;

-- Do brands discount differently in different segments?
SELECT 
    brand,
    price_segment,
    COUNT(*) AS models,
    ROUND(AVG(discount_pct), 2) AS avg_discount,
    ROUND(MIN(discount_pct), 2) AS min_discount,
    ROUND(MAX(discount_pct), 2) AS max_discount
FROM flipkart_mobiles_clean
WHERE brand IN ('SAMSUNG', 'XIAOMI')
GROUP BY brand, price_segment
HAVING COUNT(*) >= 3  -- Only meaningful samples
ORDER BY price_segment, avg_discount DESC;

-- Does higher discount correlate with more models sold?
-- (We don't have sales, but model count = market presence)
SELECT 
    CASE 
        WHEN discount_pct < 10 THEN '0-10%'
        WHEN discount_pct < 20 THEN '10-20%'
        WHEN discount_pct < 30 THEN '20-30%'
        ELSE '30%+'
    END AS discount_bracket,
    COUNT(*) AS models,
    ROUND(AVG(CASE WHEN has_rating = 1 THEN rating END), 2) AS avg_rating,
    ROUND(AVG(selling_price), 2) AS avg_price
FROM flipkart_mobiles_clean
GROUP BY discount_bracket
ORDER BY 
    CASE 
        WHEN discount_pct < 10 THEN 1
        WHEN discount_pct < 20 THEN 2
        WHEN discount_pct < 30 THEN 3
        ELSE 4
    END;
	
-- Are ratings reliable across discount groups?
SELECT 
    discount_group,
    COUNT(CASE WHEN has_rating = 1 THEN 1 END) AS rated_products,
    ROUND(COUNT(CASE WHEN has_rating = 1 THEN 1 END) * 100.0 / COUNT(*), 2) AS pct_rated,
    ROUND(MIN(CASE WHEN has_rating = 1 THEN rating END), 2) AS min_rating,
    ROUND(MAX(CASE WHEN has_rating = 1 THEN rating END), 2) AS max_rating,
    ROUND(AVG(CASE WHEN has_rating = 1 THEN rating END), 2) AS avg_rating,
    -- Standard deviation (measure of spread)
    ROUND(
        SQRT(AVG((rating - (SELECT AVG(rating) FROM flipkart_mobiles_clean WHERE has_rating = 1)) * 
                 (rating - (SELECT AVG(rating) FROM flipkart_mobiles_clean WHERE has_rating = 1)))), 2
    ) AS rating_std_dev
FROM flipkart_mobiles_clean
GROUP BY discount_group;

--sanity check :
SELECT
COUNT(*) AS total,
COUNT(DISTINCT brand || model || color || ram_gb || storage_gb) AS unique_products
FROM analysis_ready;

-- Creating final view: 
CREATE VIEW IF NOT EXISTS analysis_ready AS
SELECT
    brand,
    model,
    color,
    
    -- Pricing
    selling_price,
    original_price,
    discount_pct,
    discount_group,
    
    -- Segmentation
    price_segment,
    brand_tier,
    storage_tier,
    
    -- Hardware
    ram_gb,
    storage_gb,
    
    -- Outcome
    rating,
    has_rating
    
FROM flipkart_mobiles_clean;

-- verifying:
SELECT * 
FROM analysis_ready
LIMIT 10;
SELECT COUNT(*) 
FROM analysis_ready;

-- view for game theory on R:
CREATE VIEW IF NOT EXISTS game_theory_ready AS
SELECT
    brand,
    price_segment,
    COUNT(*) AS models,
    ROUND(AVG(discount_pct),2) AS avg_discount,
    ROUND(AVG(selling_price),2) AS avg_price,
    ROUND(AVG(rating),2) AS avg_rating
FROM flipkart_mobiles_clean
WHERE brand IN ('SAMSUNG','XIAOMI')
GROUP BY brand, price_segment;

 SELECT * FROM game_theory_ready;
 
 
 -- now exporting using expo:
 
 SELECT * FROM analysis_ready;
 
  SELECT * FROM game_theory_ready;