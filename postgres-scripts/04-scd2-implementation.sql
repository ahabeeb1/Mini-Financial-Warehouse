-- ============================================
-- PART 4: Implement SCD2 for Another Dimension
-- ============================================

-- Your turn! Implement zone change:
-- Zone 161: "Midtown Center" → "Midtown North" on 2024-07-15

-- Step 1: Check current state
SELECT zone_key, location_lk_id, borough, zone, service_zone, valid_from, valid_to, is_current
FROM warehouse.dim_taxi_zone
WHERE location_lk_id = 161;

-- Step 2: Close old record
UPDATE warehouse.dim_taxi_zone
SET 
    valid_to = '2024-07-14'::DATE,  -- Day before change
    is_current = FALSE
WHERE location_lk_id = 161
  AND is_current = TRUE;

-- Step 3: Insert new version
INSERT INTO warehouse.dim_taxi_zone (location_lk_id, borough, zone, service_zone, valid_from, valid_to, is_current)
SELECT 
    161,
    borough,  -- Keep existing
    'Midtown North',  -- New name
    service_zone,  -- Keep existing
    '2024-07-15'::DATE,
    '9999-12-31'::DATE,
    TRUE
FROM warehouse.dim_taxi_zone
WHERE location_lk_id = 161 
  AND valid_to = '2024-07-14'::DATE;  -- The record we just closed

-- Step 4: Verify - Should see 2 versions
SELECT 
    zone_key,
    location_lk_id,
    zone,
    valid_from,
    valid_to,
    is_current
FROM warehouse.dim_taxi_zone
WHERE location_lk_id = 161
ORDER BY valid_from;