-- =============================================================================
-- stg_tiktok_ads
-- Purpose: Standardize the raw TikTok ads table to the unified schema.
-- Transformations:
--   * Rename adgroup_id / adgroup_name -> ad_group_id / ad_group_name
--     (TikTok drops the underscore; we conform to snake_case "ad_group".)
--   * cost column already named correctly -> pass through.
--   * Add a hardcoded platform literal.
--   * Cast date to DATE and enforce numeric types.
-- Materialization: view.
-- =============================================================================

CREATE OR REPLACE VIEW `marketing_analytics.stg_tiktok_ads` AS
SELECT
    CAST(date AS DATE)                  AS date,
    'TikTok'                            AS platform,
    CAST(campaign_id     AS STRING)     AS campaign_id,
    CAST(campaign_name   AS STRING)     AS campaign_name,
    CAST(adgroup_id      AS STRING)     AS ad_group_id,
    CAST(adgroup_name    AS STRING)     AS ad_group_name,
    CAST(impressions     AS INT64)      AS impressions,
    CAST(clicks          AS INT64)      AS clicks,
    CAST(cost            AS NUMERIC)    AS cost,
    CAST(conversions     AS INT64)      AS conversions
FROM `marketing_analytics.raw_tiktok_ads`;
