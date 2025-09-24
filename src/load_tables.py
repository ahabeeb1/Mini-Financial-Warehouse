from pyspark.sql import SparkSession

class LoadTables:
    def __init__(self):
        self.spark = SparkSession.builder \
        .appName("Mini-Financial-Warehouse") \
        .config("spark.jars.packages", "org.postgresql:postgresql:42.6.0") \
        .config("spark.sql.adaptive.enabled", "false") \
        .getOrCreate()

        # Add this line to see what JARs are loaded
        print("Spark JARs:", self.spark.sparkContext.getConf().get("spark.jars"))
        self.main()

    def main(self):
        try:
            self.loadTables("")
        except Exception as e:
            print("failed to load tables " , e)
    
    def loadTables(self, filePath):
        if filePath == '':
            df = self.spark.read.csv("../data/2023_Yellow_Taxi_Trip_Data.csv", header=True, inferSchema=True)
            df1 = self.spark.read.csv("../data/taxi_zone_lookup.csv", header=True, inferSchema=True)
            self.copyTablesToPostgres(df, "yellow_taxi_trips")
            self.copyTablesToPostgres(df1, "taxi_zone_lookup")
        else:
            df = self.spark.read.csv(filePath, header=True, inferSchema=True)
        
    def copyTablesToPostgres(self, df, tableName):  # Add 'self'
        # PostgreSQL connection details
        url = "jdbc:postgresql://localhost:5432/taxi_warehosue"  # Note: your DB has the typo
        properties = {
            "user": "warehouse_user",
            "password": "warehouse_pass",
            "driver": "org.postgresql.Driver"
        }
        
        # Write to staging schema
        df.write.jdbc(url=url, table=f"staging.{tableName}", mode="overwrite", properties=properties)
        
        print(f"Loaded {df.count()} rows into staging.{tableName}")

# Run it
if __name__ == "__main__":
    LoadTables()
