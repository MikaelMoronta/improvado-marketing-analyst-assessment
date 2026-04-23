# QA / UAT Results — fct_ad_performance

**Scope:** 330 rows across 3 platforms, covering Jan 1–30, 2024.
**Run date:** Executed prior to dashboard publication.

Every check below was executed against the materialized `fct_ad_performance`
table in BigQuery. Raw values verified with independent Python reconciliation.

---

## Summary

| # | Test | Result |
|---|------|--------|
| 1 | Row-count reconciliation | ✅ Pass |
| 2 | Cost reconciliation vs raw sources | ✅ Pass |
| 3 | Null integrity on key fields | ✅ Pass |
| 4 | Logical sanity: clicks ≤ impressions | ✅ Pass |
| 5 | Non-negativity on volume/cost fields | ✅ Pass |
| 6 | Date coverage (30 distinct days per platform) | ✅ Pass |
| 7 | Grain uniqueness | ✅ Pass |

---

## Detailed results

### Test 1 — Row counts
| Platform | Rows |
|---|---|
| Facebook | 110 |
| Google | 110 |
| TikTok | 110 |
| **Total** | **330** |

### Test 2 — Cost reconciliation (penny-exact)
| Platform | fct cost | raw cost | Variance |
|---|---|---|---|
| Facebook | $18,292.00 | $18,292.00 | $0.00 |
| Google | $37,686.20 | $37,686.20 | $0.00 |
| TikTok | $74,266.70 | $74,266.70 | $0.00 |
| **Blended** | **$130,244.90** | **$130,244.90** | **$0.00** |

### Test 3 — Null integrity
Zero nulls in `date`, `platform`, `campaign_id`, `ad_group_id`, `cost`, `conversions`.

### Test 4 — Logical sanity
Zero rows where `clicks > impressions`.

### Test 5 — Non-negativity
Zero rows with negative values across `cost`, `impressions`, `clicks`, `conversions`.

### Test 6 — Date coverage
| Platform | Min date | Max date | Distinct dates |
|---|---|---|---|
| Facebook | 2024-01-01 | 2024-01-30 | 30 |
| Google | 2024-01-01 | 2024-01-30 | 30 |
| TikTok | 2024-01-01 | 2024-01-30 | 30 |

### Test 7 — Grain uniqueness
Zero duplicate rows on `(date, platform, campaign_id, ad_group_id)`.

---

## What I'd add next (production hardening)

- Wrap these tests as **dbt tests** (`unique`, `not_null`, `accepted_values` on `platform`, and custom singular tests for the reconciliation logic).
- Add a **freshness test** to fail the build if raw data is older than 24 hours.
- Add a **volume anomaly test** that flags day-over-day spend changes outside an expected band — catches pipeline failures and unexpected campaign launches before the client sees them in a dashboard.
- Integrate with **Elementary Data** or **Monte Carlo** for continuous observability.
