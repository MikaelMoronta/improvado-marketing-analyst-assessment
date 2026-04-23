-- =============================================================================
-- stg_facebook_ads
-- Purpose: Standardize the raw Facebook ads table to the unified schema.
-- Transformations:
--   * Rename ad_set_id / ad_set_name  -> ad_group_id / ad_group_name
--     (Facebook calls its mid-level grouping "ad set"; we conform to "ad group".)
--   * Rename spend -> cost
--     (Facebook reports "spend"; Google/TikTok and most ELT standards use "cost".)
--   * Add a hardcoded platform literal for downstream fan-out.
--   * Cast date to DATE and enforce numeric types.
-- Materialization: view. Staging stays cheap and transparent.
-- =============================================================================

CREATE OR REPLACE VIEW `marketing_analytics.stg_facebook_ads` AS
SELECT
    CAST(date AS DATE)                  AS date,
    'Facebook'                          AS platform,
    CAST(campaign_id     AS STRING)     AS campaign_id,
    CAST(campaign_name   AS STRING)     AS campaign_name,
    CAST(ad_set_id       AS STRING)     AS ad_group_id,
    CAST(ad_set_name     AS STRING)     AS ad_group_name,
    CAST(impressions     AS INT64)      AS impressions,
    CAST(clicks          AS INT64)      AS clicks,
    CAST(spend           AS NUMERIC)    AS cost,
    CAST(conversions     AS INT64)      AS conversions
FROM `marketing_analytics.raw_facebook_ads`;
