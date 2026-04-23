-- =============================================================================
-- stg_google_ads
-- Purpose: Standardize the raw Google Ads table to the unified schema.
-- Transformations:
--   * Schema already uses ad_group_id / ad_group_name and cost -> pass through.
--   * Add a hardcoded platform literal.
--   * Cast date to DATE and enforce numeric types.
-- Materialization: view.
-- =============================================================================

CREATE OR REPLACE VIEW `marketing_analytics.stg_google_ads` AS
SELECT
    CAST(date AS DATE)                  AS date,
    'Google'                            AS platform,
    CAST(campaign_id     AS STRING)     AS campaign_id,
    CAST(campaign_name   AS STRING)     AS campaign_name,
    CAST(ad_group_id     AS STRING)     AS ad_group_id,
    CAST(ad_group_name   AS STRING)     AS ad_group_name,
    CAST(impressions     AS INT64)      AS impressions,
    CAST(clicks          AS INT64)      AS clicks,
    CAST(cost            AS NUMERIC)    AS cost,
    CAST(conversions     AS INT64)      AS conversions
FROM `marketing_analytics.raw_google_ads`;
