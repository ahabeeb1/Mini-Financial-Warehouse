from pyspark.sql import SparkSession

# Create Spark session with PostgreSQL driver
spark = SparkSession.builder \
    .appName("Test-PostgreSQL-Connection") \
    .config("spark.jars.packages", "org.postgresql:postgresql:42.6.0") \
    .getOrCreate()

# Connection properties
url = "jdbc:postgresql://localhost:5432/taxi_warehosue"
properties = {
    "user": "warehouse_user",
    "password": "warehouse_pass",
    "driver": "org.postgresql.Driver",
    "ssl": "false",
    "sslmode": "disable"
}

# Test 1: Read from dimension table
print("Test 1: Reading dim_vendor...")
try:
    vendors = spark.read.jdbc(url=url, table="warehouse.dim_vendor", properties=properties)
    print(f"✅ Success! Read {vendors.count()} vendors")
    vendors.show()
except Exception as e:
    print(f"❌ Failed: {e}")

# Test 2: Read from fact table (with limit)
print("\nTest 2: Reading fact table sample...")
try:
    query = "(SELECT * FROM warehouse.yellow_tripdata_2023 LIMIT 10) as sample"
    facts = spark.read.jdbc(url=url, table=query, properties=properties)
    print(f"✅ Success! Read {facts.count()} rows")
    facts.show()
except Exception as e:
    print(f"❌ Failed: {e}")

spark.stop()