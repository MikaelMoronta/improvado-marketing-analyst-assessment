"""
ingest.py
---------
Loads the three raw advertising CSVs into BigQuery as staging tables.

Usage:
    # Authenticate first (one-time):
    #   gcloud auth application-default login
    #
    # Then:
    python scripts/ingest.py \
        --project-id YOUR_GCP_PROJECT_ID \
        --dataset   marketing_analytics

Design notes
------------
* BigQuery's native CSV loader handles 330 rows trivially and would have been a
  reasonable choice. This script exists to demonstrate a repeatable, parameterised
  ingestion pattern that scales as sources multiply -- the realistic Improvado use
  case is onboarding a new ad platform every few weeks per client.
* Writes to `raw_*` tables. Staging views (`stg_*`) and the unified fact table
  (`fct_ad_performance`) are created downstream via SQL in `/sql/`.
* `WRITE_TRUNCATE` keeps the script idempotent for local dev; switch to
  `WRITE_APPEND` when wiring to a scheduler.
"""
from __future__ import annotations

import argparse
import logging
from pathlib import Path

import pandas as pd
from google.cloud import bigquery


SOURCES = {
    "raw_facebook_ads": "data/01_facebook_ads.csv",
    "raw_google_ads":   "data/02_google_ads.csv",
    "raw_tiktok_ads":   "data/03_tiktok_ads.csv",
}


def load_csv_to_bq(
    client: bigquery.Client,
    dataset_id: str,
    table_id: str,
    csv_path: Path,
) -> int:
    """Load one CSV into BigQuery with schema auto-detection. Returns row count."""
    df = pd.read_csv(csv_path)
    df["date"] = pd.to_datetime(df["date"]).dt.date  # normalize date dtype

    full_table_id = f"{dataset_id}.{table_id}"
    job_config = bigquery.LoadJobConfig(
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
        autodetect=True,
    )
    job = client.load_table_from_dataframe(df, full_table_id, job_config=job_config)
    job.result()  # wait
    return len(df)


def main() -> None:
    parser = argparse.ArgumentParser(description="Load raw ad CSVs into BigQuery.")
    parser.add_argument("--project-id", required=True, help="GCP project ID")
    parser.add_argument("--dataset",    required=True, help="BigQuery dataset name")
    args = parser.parse_args()

    logging.basicConfig(level=logging.INFO, format="%(asctime)s  %(levelname)-7s  %(message)s")

    client = bigquery.Client(project=args.project_id)
    dataset_id = f"{args.project_id}.{args.dataset}"

    # Create dataset if it doesn't exist (idempotent).
    dataset = bigquery.Dataset(dataset_id)
    dataset.location = "US"
    client.create_dataset(dataset, exists_ok=True)
    logging.info("Dataset ready: %s", dataset_id)

    for table_id, rel_path in SOURCES.items():
        csv_path = Path(rel_path)
        if not csv_path.exists():
            raise FileNotFoundError(f"Source not found: {csv_path.resolve()}")
        rows = load_csv_to_bq(client, dataset_id, table_id, csv_path)
        logging.info("Loaded %s rows into %s.%s", rows, dataset_id, table_id)

    logging.info("Done. Next: run the SQL files in sql/staging/ then sql/marts/.")


if __name__ == "__main__":
    main()
