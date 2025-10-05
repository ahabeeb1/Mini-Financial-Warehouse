-- Batch load facts in chunks to avoid memory issues
-- Clear table first
TRUNCATE TABLE warehouse.yellow_tripdata_2023;

-- Batch 1: First 10M rows
\echo 'Loading batch 1 of 4 (rows 1-10M)...'
INSERT INTO warehouse.yellow_tripdata_2023 (
    vendor_key, pu_zone_key, do_zone_key, ratecode_key, payment_type_key,
    tpep_pickup_datetime, tpep_dropoff_datetime,
    passenger_count, trip_distance, fare_amount, extra, mta_tax,
    tip_amount, tolls_amount, improvement_surcharge, total_amount,
    congestion_surcharge, airport_fee
)
SELECT 
    v.vendor_key, pz.zone_key, dz.zone_key, rc.ratecode_key, pt.payment_type_key,
    s.tpep_pickup_datetime, s.tpep_dropoff_datetime,
    s.passenger_count, s.trip_distance, s.fare_amount, s.extra, s.mta_tax,
    s.tip_amount, s.tolls_amount, s.improvement_surcharge, s.total_amount,
    s.congestion_surcharge, s.airport_fee
FROM staging.yellow_taxi_trips s
JOIN warehouse.dim_vendor v ON s.vendor_id = v.vendor_lk_id AND v.is_current = TRUE
JOIN warehouse.dim_taxi_zone pz ON s.pu_location_id = pz.location_lk_id AND pz.is_current = TRUE
JOIN warehouse.dim_taxi_zone dz ON s.do_location_id = dz.location_lk_id AND dz.is_current = TRUE
LEFT JOIN warehouse.dim_ratecode rc ON s.ratecode_id = rc.ratecode_lk_id AND rc.is_current = TRUE
JOIN warehouse.dim_payment_type pt ON s.payment_type = pt.payment_type_lk_id AND pt.is_current = TRUE
LIMIT 10000000;

SELECT 'Batch 1 complete. Current count:' as status, COUNT(*) FROM warehouse.yellow_tripdata_2023;

-- Batch 2: Next 10M rows
\echo 'Loading batch 2 of 4 (rows 10M-20M)...'
INSERT INTO warehouse.yellow_tripdata_2023 (
    vendor_key, pu_zone_key, do_zone_key, ratecode_key, payment_type_key,
    tpep_pickup_datetime, tpep_dropoff_datetime,
    passenger_count, trip_distance, fare_amount, extra, mta_tax,
    tip_amount, tolls_amount, improvement_surcharge, total_amount,
    congestion_surcharge, airport_fee
)
SELECT 
    v.vendor_key, pz.zone_key, dz.zone_key, rc.ratecode_key, pt.payment_type_key,
    s.tpep_pickup_datetime, s.tpep_dropoff_datetime,
    s.passenger_count, s.trip_distance, s.fare_amount, s.extra, s.mta_tax,
    s.tip_amount, s.tolls_amount, s.improvement_surcharge, s.total_amount,
    s.congestion_surcharge, s.airport_fee
FROM staging.yellow_taxi_trips s
JOIN warehouse.dim_vendor v ON s.vendor_id = v.vendor_lk_id AND v.is_current = TRUE
JOIN warehouse.dim_taxi_zone pz ON s.pu_location_id = pz.location_lk_id AND pz.is_current = TRUE
JOIN warehouse.dim_taxi_zone dz ON s.do_location_id = dz.location_lk_id AND dz.is_current = TRUE
LEFT JOIN warehouse.dim_ratecode rc ON s.ratecode_id = rc.ratecode_lk_id AND rc.is_current = TRUE
JOIN warehouse.dim_payment_type pt ON s.payment_type = pt.payment_type_lk_id AND pt.is_current = TRUE
LIMIT 10000000 OFFSET 10000000;

SELECT 'Batch 2 complete. Current count:' as status, COUNT(*) FROM warehouse.yellow_tripdata_2023;

-- Batch 3: Next 10M rows
\echo 'Loading batch 3 of 4 (rows 20M-30M)...'
INSERT INTO warehouse.yellow_tripdata_2023 (
    vendor_key, pu_zone_key, do_zone_key, ratecode_key, payment_type_key,
    tpep_pickup_datetime, tpep_dropoff_datetime,
    passenger_count, trip_distance, fare_amount, extra, mta_tax,
    tip_amount, tolls_amount, improvement_surcharge, total_amount,
    congestion_surcharge, airport_fee
)
SELECT 
    v.vendor_key, pz.zone_key, dz.zone_key, rc.ratecode_key, pt.payment_type_key,
    s.tpep_pickup_datetime, s.tpep_dropoff_datetime,
    s.passenger_count, s.trip_distance, s.fare_amount, s.extra, s.mta_tax,
    s.tip_amount, s.tolls_amount, s.improvement_surcharge, s.total_amount,
    s.congestion_surcharge, s.airport_fee
FROM staging.yellow_taxi_trips s
JOIN warehouse.dim_vendor v ON s.vendor_id = v.vendor_lk_id AND v.is_current = TRUE
JOIN warehouse.dim_taxi_zone pz ON s.pu_location_id = pz.location_lk_id AND pz.is_current = TRUE
JOIN warehouse.dim_taxi_zone dz ON s.do_location_id = dz.location_lk_id AND dz.is_current = TRUE
LEFT JOIN warehouse.dim_ratecode rc ON s.ratecode_id = rc.ratecode_lk_id AND rc.is_current = TRUE
JOIN warehouse.dim_payment_type pt ON s.payment_type = pt.payment_type_lk_id AND pt.is_current = TRUE
LIMIT 10000000 OFFSET 20000000;

SELECT 'Batch 3 complete. Current count:' as status, COUNT(*) FROM warehouse.yellow_tripdata_2023;

-- Batch 4: Remaining rows
\echo 'Loading batch 4 of 4 (rows 30M+)...'
INSERT INTO warehouse.yellow_tripdata_2023 (
    vendor_key, pu_zone_key, do_zone_key, ratecode_key, payment_type_key,
    tpep_pickup_datetime, tpep_dropoff_datetime,
    passenger_count, trip_distance, fare_amount, extra, mta_tax,
    tip_amount, tolls_amount, improvement_surcharge, total_amount,
    congestion_surcharge, airport_fee
)
SELECT 
    v.vendor_key, pz.zone_key, dz.zone_key, rc.ratecode_key, pt.payment_type_key,
    s.tpep_pickup_datetime, s.tpep_dropoff_datetime,
    s.passenger_count, s.trip_distance, s.fare_amount, s.extra, s.mta_tax,
    s.tip_amount, s.tolls_amount, s.improvement_surcharge, s.total_amount,
    s.congestion_surcharge, s.airport_fee
FROM staging.yellow_taxi_trips s
JOIN warehouse.dim_vendor v ON s.vendor_id = v.vendor_lk_id AND v.is_current = TRUE
JOIN warehouse.dim_taxi_zone pz ON s.pu_location_id = pz.location_lk_id AND pz.is_current = TRUE
JOIN warehouse.dim_taxi_zone dz ON s.do_location_id = dz.location_lk_id AND dz.is_current = TRUE
LEFT JOIN warehouse.dim_ratecode rc ON s.ratecode_id = rc.ratecode_lk_id AND rc.is_current = TRUE
JOIN warehouse.dim_payment_type pt ON s.payment_type = pt.payment_type_lk_id AND pt.is_current = TRUE
OFFSET 30000000;

-- Final count
SELECT 'All batches complete! Final count:' as status, COUNT(*) FROM warehouse.yellow_tripdata_2023;