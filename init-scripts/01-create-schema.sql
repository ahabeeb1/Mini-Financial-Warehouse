CREATE SCHEMA staging;
CREATE SCHEMA warehouse;
CREATE SCHEMA analytics;

GRANT ALL ON SCHEMA staging TO warehouse_user;
GRANT ALL ON SCHEMA warehouse TO warehouse_user;
GRANT ALL ON SCHEMA analytics TO warehouse_user;
-- this schema is based on yellow.taxi.trips 
CREATE TABLE staging.yellow_taxi_trips ( 
    vendor_id INTEGER,
    tpep_pickup_datetime TIMESTAMP,
    tpep_dropoff_datetime TIMESTAMP,
    passenger_count INTEGER,
    trip_distance DECIMAL(8,2),
    ratecode_id INTEGER,
    store_and_fwd_flag CHAR(1),
    pu_location_id INTEGER,
    do_location_id INTEGER,
    payment_type INTEGER,
    fare_amount DECIMAL(10,2),
    extra DECIMAL(10,2),
    mta_tax DECIMAL(10,2),
    tip_amount DECIMAL(10,2),
    tolls_amount DECIMAL(10,2),
    improvement_surcharge DECIMAL(10,2),
    total_amount DECIMAL(10,2),
    congestion_surcharge DECIMAL(10,2),
    airport_fee DECIMAL(10,2),
    loaded_at TIMESTAMP DEFAULT NOW(),
    source_file TEXT
);
-- table for taxi_zone lookup
CREATE TABLE staging.taxi_zone_lookup ( 
    location_id INTEGER,
    borough TEXT,
    zone TEXT,
    service_zone TEXT
);

CREATE TABLE warehouse.dim_taxi_zone (
    zone_key SERIAL PRIMARY KEY,
    location_id INTEGER,
    borough TEXT,
    zone TEXT,
    service_zone TEXT,
    valid_from TIMESTAMP,
    valid_to TIMESTAMP,
    is_current BOOLEAN,
    created_at TIMESTAMP DEFAULT NOW()
)

CREATE TABLE warehouse.dim_vendor (
    vendor_key SERIAL PRIMARY KEY,
    vendor_lk_id INTEGER,
    vendor_name TEXT,
    valid_from TIMESTAMP,
    valid_to TIMESTAMP,
    is_current BOOLEAN,
    created_at TIMESTAMP DEFAULT NOW()
)

CREATE TABLE warehouse.dim_payment_type (
    payment_type_key SERIAL PRIMARY KEY,
    payment_type_lk_id INTEGER,
    payment_type_name TEXT,
    valid_from TIMESTAMP,
    valid_to TIMESTAMP,
    is_current BOOLEAN,
    created_at TIMESTAMP DEFAULT NOW()
)

CREATE TABLE warehouse.dim_ratecode (
    ratecode_key SERIAL PRIMARY KEY,
    ratecode_lk_id INTEGER,
    ratecode_name TEXT,
    valid_from TIMESTAMP,
    valid_to TIMESTAMP,
    is_current BOOLEAN,
    created_at TIMESTAMP DEFAULT NOW()
)


CREATE TABLE warehouse.yellow_tripdata_2023 (
    trip_key SERIAL PRIMARY KEY,
    
    -- Dimension foreign keys
    vendor_key INTEGER REFERENCES warehouse.dim_vendor(vendor_key),
    pu_zone_key INTEGER REFERENCES warehouse.dim_taxi_zone(zone_key),
    do_zone_key INTEGER REFERENCES warehouse.dim_taxi_zone(zone_key),
    ratecode_key INTEGER REFERENCES warehouse.dim_ratecode(ratecode_key),
    payment_type_key INTEGER REFERENCES warehouse.dim_payment_type(payment_type_key),
    -- Temporal columns (for point-in-time joins)
    tpep_pickup_datetime TIMESTAMP NOT NULL,
    tpep_dropoff_datetime TIMESTAMP NOT NULL,
    -- Facts/Measures
    passenger_count INTEGER,
    trip_distance DECIMAL(8,2),
    fare_amount DECIMAL(10,2),
    extra DECIMAL(10,2),
    mta_tax DECIMAL(10,2),
    tip_amount DECIMAL(10,2),
    tolls_amount DECIMAL(10,2),
    improvement_surcharge DECIMAL(10,2),
    total_amount DECIMAL(10,2),
    congestion_surcharge DECIMAL(10,2),
    airport_fee DECIMAL(10,2),
    -- Audit columns
    loaded_at TIMESTAMP DEFAULT NOW(),
    source_file TEXT
);