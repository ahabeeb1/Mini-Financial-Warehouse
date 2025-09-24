🎯 Goal

Show you can design a time-travel warehouse: handle slowly changing dimensions (SCD2), back-dated transactions, and query metrics “as of” any date. This screams finance/enterprise readiness.

🔧 Tech Stack

Storage: PostgreSQL (local or RDS free tier) for warehouse

Processing: PySpark (local, start with Docker or pip install)

Modeling: SQL (SCD2 logic), optional dbt for transformations/docs

Data Source: NYC Taxi dataset (public, has datetime + fare + trip data)

📝 Steps Outline
1. Data Ingestion

Download raw NYC Taxi CSV (yellow_tripdata).

Load into staging schema in Postgres (staging.trips).

2. Dimension Modeling (SCD2)

Create a dim_customer or dim_driver table with SCD2 fields:

customer_id, surrogate_key, effective_from, effective_to, is_current.

Write PySpark job to detect changes and MERGE into dim_customer.

3. Fact Table

fact_trips: trip_id, driver_sk, customer_sk, fare, trip_datetime.

Ensure facts join to dimensions using valid as-of date logic.

4. Time Travel Queries

Build SQL queries to answer:

“Revenue as of 2023-06-30.”

“Average fare per customer as of last quarter.”

Validate using SCD2 effective dates.

5. PySpark Pipeline

Recreate ETL with PySpark:

Read raw CSV.

Apply transformations.

Load to Postgres warehouse.

Optimize with partitioning on trip_date.

6. Deliverables

GitHub Repo with:

README.md → problem, schema diagram, “as-of” examples.

sql/ → queries (SCD2, back-dated metrics).

pyspark/ → ETL job scripts.

docs/ → schema diagram (draw.io or dbdiagram.io).