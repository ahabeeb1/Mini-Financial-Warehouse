# Mini-Financial-Warehouse
time-travel warehouse


##Building a PySpark + SQL warehouse with SCD2 handling.

#Challenge: NYC periodically redraws taxi zone boundaries

Example: Zone 161 was "Midtown Center" in Jan 2023, becomes "Midtown North" in June 2023
SCD2 Value: Historical reports show correct zone names for each time period
Business Question: "What was revenue by pickup zone in Q1 vs Q3, using the zone definitions that existed at each time?"

#Goal: Build a warehouse that can answer this question


## 🎓 Learning Objectives

1. **SCD2 Implementation** - Hands-on experience with slowly changing dimensions
2. **Time-Travel Analytics** - Query data "as it existed" at any point in time  
3. **Data Warehouse Design** - Staging → Warehouse → Analytics pattern
4. **PostgreSQL Mastery** - Advanced SQL, schema design, performance optimization
5. **ETL Pipelines** - PySpark integration with PostgreSQL

## 🚕 Business Use Cases

**Zone Boundary Analysis:**
- Track revenue impact of zone reclassifications
- Historical reporting with correct zone names for each period

**Rate Structure Evolution:**
- Analyze how pricing changes affected trip patterns
- Compare performance across different rate periods

**Vendor Market Share:**
- Monitor market share despite company rebranding
- Historical vendor performance analysis

## 🔧 Quick Start

```bash
# Build and run PostgreSQL container
docker build -t taxi-warehouse .
docker run --name my-taxi-warehouse -p 5432:5432 \
  -v /path/to/data:/data -d taxi-warehouse

# Connect to database
docker exec -it my-taxi-warehouse psql -U warehouse_user -d taxi_warehouse

# Load data
\copy staging.taxi_zone_lookup FROM '/path/to/data/taxi_zone_lookup.csv' WITH CSV HEADER;
\copy staging.yellow_taxi_trips FROM '/path/to/data/2023_Yellow_Taxi_Trip_Data.csv' WITH CSV HEADER;