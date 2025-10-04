
--- Taxi Zone Dimension
INSERT INTO warehouse.dim_taxi_zone (
    location_lk_id, 
    borough, 
    zone, 
    service_zone, 
    valid_from, 
    valid_to, 
    is_current
)
SELECT 
    location_id,
    borough,
    zone,
    service_zone,
    (SELECT MIN(tpep_pickup_datetime) FROM staging.yellow_taxi_trips)::DATE,
    '9999-12-31'::DATE,
    TRUE
    FROM staging.taxi_zone_lookup
    WHERE location_id IS NOT NULL;

--- Vendor Dimension
INSERT INTO warehouse.dim_vendor (
    vendor_lk_id, 
    vendor_name, 
    valid_from, 
    valid_to, 
    is_current
)
SELECT DISTINCT
    vendor_id,
    CASE vendor_id
        WHEN 1 THEN 'Creative Mobile Tech'
        WHEN 2 THEN 'Curb Mobility'
        WHEN 6 THEN 'Myle Tech'
        WHEN 7 THEN 'Helix'
        ELSE NULL
    END,
    (SELECT MIN(tpep_pickup_datetime) FROM staging.yellow_taxi_trips)::DATE,
    '9999-12-31'::DATE,
    TRUE
    FROM staging.yellow_taxi_trips
    WHERE vendor_id IS NOT NULL;

--- Payment Type Dimension
INSERT INTO warehouse.dim_payment_type (
    payment_type_lk_id, 
    payment_type_name, 
    valid_from, 
    valid_to, 
    is_current
)
SELECT DISTINCT
    payment_type,
    CASE payment_type
        WHEN 0 THEN 'Flex Fare'
        WHEN 1 THEN 'Credit card'
        WHEN 2 THEN 'Cash'
        WHEN 3 THEN 'No charge'
        WHEN 4 THEN 'Dispute'
        WHEN 5 THEN 'Unknown'
        WHEN 6 THEN 'Voided trip'
        ELSE NULL
    END,
    (SELECT MIN(tpep_pickup_datetime) FROM staging.yellow_taxi_trips)::DATE,
    '9999-12-31'::DATE,
    TRUE
    FROM staging.yellow_taxi_trips  
    WHERE payment_type IS NOT NULL;

--- Ratecode Dimension
INSERT INTO warehouse.dim_ratecode (
    ratecode_lk_id, 
    ratecode_name, 
    valid_from, 
    valid_to, 
    is_current
)
SELECT DISTINCT
    ratecode_id,
    CASE ratecode_id
        WHEN 1 THEN 'Standard rate'
        WHEN 2 THEN 'JFK'
        WHEN 3 THEN 'Newark'
        WHEN 4 THEN 'Nassau or Westchester'
        WHEN 5 THEN 'Negotiated fare'
        WHEN 6 THEN 'Group ride'
        ELSE NULL
    END,
    (SELECT MIN(tpep_pickup_datetime) FROM staging.yellow_taxi_trips)::DATE,
    '9999-12-31'::DATE,
    TRUE
    FROM staging.yellow_taxi_trips
    WHERE ratecode_id IS NOT NULL;

-- Loading the facts tables
INSERT INTO warehouse.yellow_tripdata_2023 (
    vendor_key,
    pu_zone_key,
    do_zone_key,
    ratecode_key,
    payment_type_key,
    tpep_pickup_datetime,
    tpep_dropoff_datetime,
    passenger_count,
    trip_distance,
    fare_amount,
    extra,
    mta_tax,
    tip_amount,
    tolls_amount,
    improvement_surcharge,
    total_amount,
    congestion_surcharge,
    airport_fee
)
SELECT 
    v.vendor_key,
    pz.zone_key,
    dz.zone_key,
    rc.ratecode_key,
    pt.payment_type_key,
    s.tpep_pickup_datetime,
    s.tpep_dropoff_datetime,
    s.passenger_count,
    s.trip_distance,
    s.fare_amount,
    s.extra,
    s.mta_tax,
    s.tip_amount,
    s.tolls_amount,
    s.improvement_surcharge,
    s.total_amount,
    s.congestion_surcharge,
    s.airport_fee
FROM staging.yellow_taxi_trips s
JOIN warehouse.dim_vendor v ON s.vendor_id = v.vendor_lk_id AND v.is_current = TRUE
JOIN warehouse.dim_taxi_zone pz ON s.pu_location_id = pz.location_lk_id AND pz.is_current = TRUE
JOIN warehouse.dim_taxi_zone dz ON s.do_location_id = dz.location_lk_id AND dz.is_current = TRUE
LEFT JOIN warehouse.dim_ratecode rc ON s.ratecode_id = rc.ratecode_lk_id AND rc.is_current = TRUE  -- ← Changed to LEFT
JOIN warehouse.dim_payment_type pt ON s.payment_type = pt.payment_type_lk_id AND pt.is_current = TRUE
LIMIT 1000;