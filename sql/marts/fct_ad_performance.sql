-- =============================================================================
-- fct_ad_performance
-- Purpose: Unified cross-channel ad performance fact table.
-- Grain: one row per (date, platform, campaign_id, ad_group_id).
-- Design choice: single unified fact table (not a star schema) because the
--   three sources share identical grain and the dataset does not justify
--   dimensional overhead. A star schema (dim_campaign, dim_platform, dim_date)
--   becomes valuable the moment a second fact is introduced -- e.g.,
--   fct_conversions_from_crm -- so conformed dimensions can pay for themselves.
-- Materialization: table. Stable BI source, fast Looker Studio queries.
-- =============================================================================

CREATE OR REPLACE TABLE `marketing_analytics.fct_ad_performance` AS
SELECT * FROM `marketing_analytics.stg_facebook_ads`
UNION ALL
SELECT * FROM `marketing_analytics.stg_google_ads`
UNION ALL
SELECT * FROM `marketing_analytics.stg_tiktok_ads`;

-- -----------------------------------------------------------------------------
-- Derived metrics are intentionally NOT baked into this table.
-- CTR, CPC, CPA, CVR are calculated in the BI tool (Looker Studio) using
-- SUM-based ratios. This preserves additivity across any filter combination
-- and follows modern analytics-engineering convention (keep facts additive,
-- derive ratios downstream).
-- -----------------------------------------------------------------------------
