-- =============================================================================
-- QA / UAT Test Suite for fct_ad_performance
-- Run each test independently. Any row returned by test 3-7 indicates a failure.
-- Tests 1-2 should return the expected counts/sums documented in qa_results.md.
-- =============================================================================


-- -----------------------------------------------------------------------------
-- TEST 1: Row-count reconciliation by platform
-- Expected: Facebook 110, Google 110, TikTok 110, Total 330.
-- -----------------------------------------------------------------------------
SELECT
    platform,
    COUNT(*) AS row_count
FROM `marketing_analytics.fct_ad_performance`
GROUP BY platform
ORDER BY platform;


-- -----------------------------------------------------------------------------
-- TEST 2: Cost reconciliation vs raw sources
-- Expected: fct totals equal raw totals to the penny.
--   Facebook: $18,292.00 | Google: $37,686.20 | TikTok: $74,266.70
--   Blended:  $130,244.90
-- -----------------------------------------------------------------------------
WITH fct AS (
    SELECT platform, ROUND(SUM(cost), 2) AS fct_cost
    FROM `marketing_analytics.fct_ad_performance`
    GROUP BY platform
),
raw_totals AS (
    SELECT 'Facebook' AS platform, ROUND(SUM(spend), 2) AS raw_cost
    FROM `marketing_analytics.raw_facebook_ads`
    UNION ALL
    SELECT 'Google',              ROUND(SUM(cost),  2)
    FROM `marketing_analytics.raw_google_ads`
    UNION ALL
    SELECT 'TikTok',              ROUND(SUM(cost),  2)
    FROM `marketing_analytics.raw_tiktok_ads`
)
SELECT
    f.platform,
    f.fct_cost,
    r.raw_cost,
    ROUND(f.fct_cost - r.raw_cost, 2) AS variance
FROM fct f
JOIN raw_totals r USING (platform)
ORDER BY platform;


-- -----------------------------------------------------------------------------
-- TEST 3: Null integrity on key fields
-- Expected: ZERO rows returned.
-- -----------------------------------------------------------------------------
SELECT *
FROM `marketing_analytics.fct_ad_performance`
WHERE date          IS NULL
   OR platform      IS NULL
   OR campaign_id   IS NULL
   OR ad_group_id   IS NULL
   OR cost          IS NULL
   OR conversions   IS NULL;


-- -----------------------------------------------------------------------------
-- TEST 4: Logical sanity -- clicks must never exceed impressions
-- Expected: ZERO rows returned.
-- -----------------------------------------------------------------------------
SELECT *
FROM `marketing_analytics.fct_ad_performance`
WHERE clicks > impressions;


-- -----------------------------------------------------------------------------
-- TEST 5: Non-negativity on monetary & volume fields
-- Expected: ZERO rows returned.
-- -----------------------------------------------------------------------------
SELECT *
FROM `marketing_analytics.fct_ad_performance`
WHERE cost        < 0
   OR impressions < 0
   OR clicks      < 0
   OR conversions < 0;


-- -----------------------------------------------------------------------------
-- TEST 6: Date coverage -- expect 30 distinct dates (Jan 1-30, 2024) per platform
-- Expected: 3 rows, each with distinct_dates = 30.
-- -----------------------------------------------------------------------------
SELECT
    platform,
    MIN(date)                AS min_date,
    MAX(date)                AS max_date,
    COUNT(DISTINCT date)     AS distinct_dates
FROM `marketing_analytics.fct_ad_performance`
GROUP BY platform
ORDER BY platform;


-- -----------------------------------------------------------------------------
-- TEST 7: Grain uniqueness -- (date, platform, campaign_id, ad_group_id) must be unique
-- Expected: ZERO rows returned.
-- -----------------------------------------------------------------------------
SELECT
    date, platform, campaign_id, ad_group_id,
    COUNT(*) AS duplicate_count
FROM `marketing_analytics.fct_ad_performance`
GROUP BY date, platform, campaign_id, ad_group_id
HAVING COUNT(*) > 1;
