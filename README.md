# Improvado — Senior Data Analyst Technical Assessment

Unified cross-channel marketing data pipeline and dashboard, built for the
Improvado Senior Data Analyst (Marketing) take-home. Source data spans three
ad platforms — Facebook, Google, TikTok — covering Jan 1–30, 2024.

**Dashboard:** https://datastudio.google.com/reporting/045564e5-3d8a-4cce-a8f2-825cdd079a0d
**Video walkthrough:** https://youtu.be/qvTfZdBvOKU

---

## Architecture

```
   ┌──────────────────┐      ┌──────────────────┐      ┌──────────────────┐
   │ 01_facebook.csv  │      │ 02_google.csv    │      │ 03_tiktok.csv    │
   └────────┬─────────┘      └────────┬─────────┘      └────────┬─────────┘
            │                         │                         │
            ▼                         ▼                         ▼
    ┌─────────────────────────────────────────────────────────────────┐
    │                   BigQuery  —  raw_* tables                     │
    │         (loaded via scripts/ingest.py or BQ native UI)          │
    └─────────────────────────────────────────────────────────────────┘
            │                         │                         │
            ▼                         ▼                         ▼
    ┌─────────────────┐      ┌─────────────────┐      ┌─────────────────┐
    │ stg_facebook    │      │ stg_google      │      │ stg_tiktok      │
    │   (view)        │      │   (view)        │      │   (view)        │
    │  rename spend,  │      │  pass-through + │      │  rename adgroup,│
    │  ad_set →       │      │  platform tag   │      │  platform tag   │
    │  ad_group       │      │                 │      │                 │
    └────────┬────────┘      └────────┬────────┘      └────────┬────────┘
             │                        │                        │
             └────────────────────────┼────────────────────────┘
                                      ▼
                        ┌───────────────────────────┐
                        │  fct_ad_performance       │
                        │         (table)           │
                        │  unified grain:           │
                        │  date × platform ×        │
                        │  campaign × ad_group      │
                        └─────────────┬─────────────┘
                                      │
                                      ▼
                             ┌──────────────────┐
                             │  Looker Studio   │
                             │  Dashboard       │
                             └──────────────────┘
```

---

## Data model decision

I chose a **single unified fact table** over a star schema. The three sources
share identical grain (date × campaign × ad_group), zero null keys, and the
dataset is 330 rows. Dimensional modeling is a tool that earns its weight when
you have multiple fact tables or SCD requirements — neither applies here.

When a star schema *would* be the right answer:
- A second fact table enters the model (e.g. `fct_conversions_crm`, `fct_cost_dsp`)
- Campaigns acquire slowly-changing attributes (campaign owner, objective, budget tier)
- We want to join against a date dimension carrying fiscal calendar or holiday flags

At that point `dim_campaign`, `dim_date`, and `dim_platform` make analyst queries
simpler, enable conformed reporting, and become worth the maintenance cost.

**Ratio metrics (CTR, CPC, CPA, CVR) are computed in Looker Studio, not baked
into the fact.** SUM-based ratios in the BI layer stay additive under every
filter combination — a blended CPA filtered to "TikTok, last 7 days" is always
correct because the SUMs recompute against the filtered grain. Storing
pre-computed ratios breaks additivity and creates data-quality bugs that are
painful to debug later.

---

## Repository layout

```
improvado-assessment/
├── data/                          # Source CSVs (vendored for reproducibility)
├── scripts/
│   └── ingest.py                  # Python loader → BigQuery raw tables
├── sql/
│   ├── staging/
│   │   ├── stg_facebook_ads.sql
│   │   ├── stg_google_ads.sql
│   │   └── stg_tiktok_ads.sql
│   └── marts/
│       └── fct_ad_performance.sql
├── qa/
│   ├── qa_checks.sql              # 7-test validation suite
│   └── qa_results.md              # All checks passed (penny-exact reconciliation)
├── requirements.txt
└── README.md
```

---

## How to reproduce

```bash
# 1. Authenticate to GCP
gcloud auth application-default login

# 2. Install deps
pip install -r requirements.txt

# 3. Load raw tables
python scripts/ingest.py --project-id YOUR_PROJECT --dataset marketing_analytics

# 4. Build staging + fact in BigQuery
#    Run each file in this order via the BQ console or `bq query`:
#      sql/staging/stg_facebook_ads.sql
#      sql/staging/stg_google_ads.sql
#      sql/staging/stg_tiktok_ads.sql
#      sql/marts/fct_ad_performance.sql

# 5. Validate
#    Run each test in qa/qa_checks.sql. Expect results documented in qa/qa_results.md.

# 6. Connect Looker Studio to fct_ad_performance
#    Follow docs/dashboard_build_guide.md.
```

---

## QA summary

Seven tests, all pass. Cost reconciliation is **penny-exact** across all three platforms: $18,292.00 / $37,686.20 / $74,266.70, blended $130,244.90. Full detail in [`qa/qa_results.md`](qa/qa_results.md).

---

## AI tooling

Consistent with the role's expectation that analysts leverage AI to accelerate workflows, I used Claude for:

- **Boilerplate SQL generation** — staging DDL, the QA test suite scaffolding, and the README structure.
- **Sanity-checking reconciliation math** — independent Python verification against the CSV raw totals.
- **Document drafting** — first-pass text for the insights brief and video script.

What I owned end-to-end: the model decision (unified fact vs. star schema), the QA test selection, the dashboard layout and narrative, and the interpretation behind the three insights. AI accelerated the typing; the analytical judgment is mine — and every choice is defensible in the follow-up discussion.

---

## What I'd build next

1. **dbt-ify the pipeline.** Convert the SQL files into dbt models, add `unique` / `not_null` / `accepted_values` tests, and wire to a CI job so every PR runs the full test suite.
2. **Attribution layer.** Current `conversions` are platform-reported and double-count across channels. A multi-touch attribution model (even last-non-direct as a baseline) would give a defensible cross-channel conversion number.
3. **MMM-ready aggregations.** Weekly rollups by platform, channel, and creative type — the shape a Marketing Mix Model expects as input.
4. **Conversion value reconciliation.** Google carries `conversion_value`; Facebook and TikTok don't. Aligning on a value model (CRM-sourced revenue back-joined to campaign) unlocks blended ROAS — the metric this dashboard should show next.
5. **Data observability.** Freshness SLAs, volume anomaly detection, schema-drift alerts (Elementary Data or Monte Carlo).
