# Mini Financial Warehouse - NYC Taxi Data with SCD2

> **A data warehouse implementation featuring Slowly Changing Dimensions Type 2 (SCD2) for time-travel analytics**

[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-blue.svg)](https://www.postgresql.org/)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue.svg)](https://www.docker.com/)
[![SCD2](https://img.shields.io/badge/SCD2-Implemented-green.svg)](https://en.wikipedia.org/wiki/Slowly_changing_dimension)

## Project Overview

A hands-on data warehouse project built with **PostgreSQL** and **SQL**, processing **38.3 million** NYC Yellow Taxi trip records from 2023. Implements **SCD2 (Slowly Changing Dimensions Type 2)** to enable time-travel queries and historical accuracy.

### Key Features
- 38.3M trip records loaded and optimized
- SCD2 implementation for dimension tracking
- Time-travel queries - Query data as it existed at any point in time
- Star schema design - 4 dimensions + 1 fact table
- Batched loading - Handles large datasets efficiently
- Historical accuracy - Preserves dimension values as they were

---

## What is SCD2?

**Slowly Changing Dimension Type 2** tracks historical changes by creating new records when dimension attributes change, preserving complete history.

### Example: Zone Name Change

```sql
-- Before: Zone 161 (2001-2024)
zone_key: 691 | location_lk_id: 161 | zone: "Midtown Center" | is_current: TRUE

-- After: Zone renamed on 2024-07-15
zone_key: 691 | location_lk_id: 161 | zone: "Midtown Center" | valid_to: 2024-07-14 | is_current: FALSE
zone_key: 796 | location_lk_id: 161 | zone: "Midtown North"  | valid_from: 2024-07-15 | is_current: TRUE
```

**Business Value:**
- 2023 trips show "Midtown Center" (historically accurate)
- 2024 trips show "Midtown North" (current name)
- Reports reflect reality at the time events occurred

---

## Architecture

### Schema Design

```
┌─────────────┐
│   Staging   │  ← Raw data from source systems
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Warehouse  │  ← Star schema with SCD2
│             │
│  ┌────────┐ │
│  │  Dims  │ │  ← 4 SCD2 dimensions
│  └────────┘ │
│      │      │
│      ▼      │
│  ┌────────┐ │
│  │ Facts  │ │  ← 38.3M trip records
│  └────────┘ │
└─────────────┘
```

### Database Schema

**Dimensions (SCD2):**
- `dim_vendor` - Taxi vendors (Creative Mobile Tech, Curb Mobility, Myle Tech)
- `dim_taxi_zone` - 265 NYC taxi zones with borough and service zone
- `dim_payment_type` - Payment methods (Credit, cash, etc.)
- `dim_ratecode` - Rate codes (Standard, JFK, Newark, etc.)

**Facts:**
- `yellow_tripdata_2023` - 38.3M trip records with measures (fare, distance, time)

---

## Quick Start

### Prerequisites
- Docker installed
- 8GB+ RAM available
- ~10GB disk space for data

### 1. Clone and Setup

```bash
git clone https://github.com/ahabeeb1/Mini-Financial-Warehouse.git
cd Mini-Financial-Warehouse
```

### 2. Build and Run PostgreSQL Container

```bash
# Build image
docker build -t taxi-warehouse .

# Run container
docker run --name my-taxi-warehouse -p 5432:5432 -d taxi-warehouse
```

### 3. Load Your Data

**Option A: Using PySpark (if you have data files)**
```bash
python src/load_tables.py
```

**Option B: Using SQL directly**
```bash
# Connect to database
docker exec -it my-taxi-warehouse psql -U warehouse_user -d taxi_warehouse

# Load staging data
\copy staging.taxi_zone_lookup FROM '/path/to/taxi_zone_lookup.csv' WITH CSV HEADER;
\copy staging.yellow_taxi_trips FROM '/path/to/2023_Yellow_Taxi_Trip_Data.csv' WITH CSV HEADER;
```

### 4. Create Warehouse Schema

```bash
# Run schema creation
Get-Content postgres-scripts/01-create-schema.sql | docker exec -i my-taxi-warehouse psql -U warehouse_user -d taxi_warehosue
```

### 5. Load Dimensions and Facts

```bash
# Load dimension tables (vendors, zones, payment types, rate codes)
Get-Content postgres-scripts/02-load-warehouse.sql | docker exec -i my-taxi-warehouse psql -U warehouse_user -d taxi_warehosue

# Load fact table (38.3M trips in batches)
Get-Content postgres-scripts/03-batch-load-warehouse.sql | docker exec -i my-taxi-warehouse psql -U warehouse_user -d taxi_warehosue
```

**Expected load time:** 10-15 minutes for full dataset

### 6. Implement SCD2 Changes

```bash
# Simulate dimension changes (zone rename)
Get-Content postgres-scripts/04-scd2-implementation.sql | docker exec -i my-taxi-warehouse psql -U warehouse_user -d taxi_warehosue
```

### 7. Run Time-Travel Queries

```bash
# Test SCD2 time-travel capabilities
Get-Content postgres-scripts/05-time-travel-queries.sql | docker exec -i my-taxi-warehouse psql -U warehouse_user -d taxi_warehosue
```

---

## 📊 Data Loaded

After completing the setup, your warehouse contains:

| Table | Rows | Description |
|-------|------|-------------|
| `dim_vendor` | 3 | Taxi vendors (Creative Mobile Tech, Curb Mobility, Myle Tech) |
| `dim_taxi_zone` | 265+ | NYC taxi zones (includes SCD2 versions) |
| `dim_payment_type` | 6 | Payment methods |
| `dim_ratecode` | 7 | Rate codes |
| `yellow_tripdata_2023` | 38,310,226 | Trip records from 2023 |

**Total warehouse size:** ~10GB

---

## 🔍 Example Queries

### Current State Query
```sql
-- What zones are currently active?
SELECT location_lk_id, zone, valid_from, is_current
FROM warehouse.dim_taxi_zone
WHERE is_current = TRUE
ORDER BY location_lk_id;
```

### Time-Travel Query
```sql
-- What was zone 161 called in June 2024?
SELECT location_lk_id, zone, valid_from, valid_to
FROM warehouse.dim_taxi_zone
WHERE location_lk_id = 161
  AND '2024-06-15'::DATE BETWEEN valid_from AND valid_to;
-- Result: "Midtown Center"
```

### Business Analysis
```sql
-- Revenue by zone (with historical accuracy)
SELECT 
    z.zone,
    COUNT(*) as trip_count,
    SUM(f.total_amount) as total_revenue,
    AVG(f.total_amount) as avg_fare
FROM warehouse.yellow_tripdata_2023 f
JOIN warehouse.dim_taxi_zone z ON f.pu_zone_key = z.zone_key
GROUP BY z.zone
ORDER BY total_revenue DESC
LIMIT 10;
```

### SCD2 Change Detection
```sql
-- Which dimensions have changed over time?
SELECT 
    location_lk_id,
    COUNT(*) as version_count,
    STRING_AGG(zone, ' → ' ORDER BY valid_from) as name_history
FROM warehouse.dim_taxi_zone
GROUP BY location_lk_id
HAVING COUNT(*) > 1;
-- Result: Zone 161: "Midtown Center → Midtown North"
```

---

## 🎓 Learning Outcomes

### SCD2 Implementation
- ✅ Surrogate keys vs natural keys
- ✅ Temporal tracking (`valid_from`, `valid_to`)
- ✅ Current flag usage (`is_current`)
- ✅ Closing old records and inserting new versions
- ✅ Maintaining referential integrity

### Data Warehouse Design
- ✅ Star schema modeling
- ✅ Fact and dimension tables
- ✅ Role-playing dimensions (zones used for pickup AND dropoff)
- ✅ Slowly changing dimensions
- ✅ Historical accuracy preservation

### SQL Mastery
- ✅ Complex joins (5-way joins with 38M rows)
- ✅ Batched loading for large datasets
- ✅ Point-in-time queries
- ✅ Window functions and aggregations
- ✅ Performance optimization

### Pandas Skills
- ✅ Reading from PostgreSQL into DataFrames
- ✅ DataFrame merging and filtering
- ✅ Change detection with boolean masks
- ✅ Writing DataFrames back to PostgreSQL
- ✅ Date/time manipulation
- ✅ Programmatic SCD2 workflows

---

## 🐼 Pandas Implementation

### Why Pandas?

In addition to SQL-based SCD2, this project includes a **Pandas implementation** for programmatic SCD2 management:

- ✅ **Simpler than PySpark** - Easier to learn and debug
- ✅ **Perfect for learning** - Immediate feedback with DataFrames
- ✅ **Production-ready** - Used in real data pipelines
- ✅ **Flexible** - Easy to customize logic

### Setup Pandas Environment

```bash
# Install dependencies
pip install -r requirements.txt

# Dependencies:
# - pandas
# - psycopg2
# - sqlalchemy
# - numpy
```

### Run Pandas SCD2 Examples

```bash
# Run main SCD2 implementation
python src/pandas/scd2_pandas.py

# Run learning exercises
python src/pandas/pandas_exercises.py
```

### Example: Pandas SCD2 Workflow

```python
from scd2_pandas import SCD2Manager
import pandas as pd

# Initialize manager
scd2 = SCD2Manager()

# Create new data (zone rename)
new_zones = pd.DataFrame({
    'location_lk_id': [161],
    'borough': ['Manhattan'],
    'zone': ['Midtown North'],
    'service_zone': ['Yellow Zone']
})

# Apply SCD2 changes
scd2.apply_scd2_changes(
    table_name='dim_taxi_zone',
    new_data=new_zones,
    natural_key='location_lk_id',
    compare_columns=['zone'],
    effective_date='2024-07-15'
)
```

**Output:**
```
✅ Connected to PostgreSQL
🔄 Starting SCD2 process for dim_taxi_zone...
📊 Read 266 rows from dim_taxi_zone
🔍 Detected 1 changes
✅ Closed 1 old records
✅ Inserted 1 new versions
✅ SCD2 process complete for dim_taxi_zone
```

### Learning Exercises

The project includes 3 hands-on exercises:

1. **Exercise 1: Vendor Rebrand** - Apply SCD2 to vendor dimension
2. **Exercise 2: Time-Travel Queries** - Query data at different points in time
3. **Exercise 3: Bulk Changes** - Process multiple dimension changes at once

---

## 📁 Project Structure

```
Mini-Financial-Warehouse/
├── postgres-scripts/
│   ├── 01-create-schema.sql          # Schema definitions
│   ├── 02-load-warehouse.sql         # Dimension loading
│   ├── 03-batch-load-warehouse.sql   # Fact loading (batched)
│   ├── 04-scd2-implementation.sql    # SCD2 change simulation
│   └── 05-time-travel-queries.sql    # Time-travel examples
├── src/
│   ├── pandas/
│   │   ├── scd2_pandas.py            # Pandas SCD2 implementation
│   │   └── pandas_exercises.py       # Learning exercises
│   └── spark/
│       └── load_tables.py            # PySpark data loader
├── data/                             # Your CSV files go here
├── requirements.txt                  # Python dependencies
├── dockerfile                        # PostgreSQL container
└── README.md
```

---

## 🔧 Troubleshooting

### Container Issues
```bash
# Check if container is running
docker ps | findstr taxi-warehouse

# View logs
docker logs my-taxi-warehouse

# Restart container
docker restart my-taxi-warehouse
```

### Connection Issues
```bash
# Test PostgreSQL connection
docker exec -it my-taxi-warehouse psql -U warehouse_user -d taxi_warehosue -c "SELECT version();"

# Check port binding
docker port my-taxi-warehouse
```

### Data Loading Issues
```bash
# Check staging data loaded
docker exec -it my-taxi-warehouse psql -U warehouse_user -d taxi_warehosue -c "
SELECT 
    'staging.yellow_taxi_trips' as table_name, COUNT(*) 
FROM staging.yellow_taxi_trips
UNION ALL
SELECT 'staging.taxi_zone_lookup', COUNT(*) 
FROM staging.taxi_zone_lookup;
"
```

---

## 🚀 Next Steps

1. **Add More Dimensions** - Implement SCD2 for vendors and rate codes
2. **Build Analytics Views** - Create materialized views for common queries
3. **Add Indexes** - Optimize query performance
4. **Implement Incremental Loads** - Handle new data arriving monthly
5. **Create Dashboards** - Visualize insights with BI tools

---

## 📚 Resources

- [NYC Taxi Data Dictionary](https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page)
- [SCD2 Pattern](https://en.wikipedia.org/wiki/Slowly_changing_dimension#Type_2:_add_new_row)
- [Star Schema Design](https://en.wikipedia.org/wiki/Star_schema)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

---

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🤝 Contributing

This is a learning project, but suggestions and improvements are welcome! Feel free to:
- Open issues for bugs or questions
- Submit pull requests for enhancements
- Share your own SCD2 implementations

---

## 👤 Author

**Abdullah Habeeb**
- GitHub: [@ahabeeb1](https://github.com/ahabeeb1)
- Project: [Mini-Financial-Warehouse](https://github.com/ahabeeb1/Mini-Financial-Warehouse)

---

## ⭐ Acknowledgments

- NYC Taxi & Limousine Commission for the open data
- PostgreSQL community for excellent documentation
- Data engineering community for SCD2 best practices

---