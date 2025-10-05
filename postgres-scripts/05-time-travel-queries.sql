-- ============================================
-- Time-Travel Queries - SCD2 in Action
-- ============================================

-- Query 1: Current State (What's active NOW?)
SELECT 
    location_lk_id,
    zone,
    valid_from,
    valid_to,
    is_current
FROM warehouse.dim_taxi_zone
WHERE location_lk_id = 161
  AND is_current = TRUE;

-- Expected: Midtown North

-- Query 2: Historical State (What was it in June 2024?)
SELECT 
    location_lk_id,
    zone,
    valid_from,
    valid_to
FROM warehouse.dim_taxi_zone
WHERE location_lk_id = 161
  AND '2024-06-15'::DATE BETWEEN valid_from AND valid_to;

-- Expected: Midtown Center (before the July 15 change)

-- Query 3: Historical State (What was it in August 2024?)
SELECT 
    location_lk_id,
    zone,
    valid_from,
    valid_to
FROM warehouse.dim_taxi_zone
WHERE location_lk_id = 161
  AND '2024-08-01'::DATE BETWEEN valid_from AND valid_to;

-- Expected: Midtown North (after the July 15 change)

-- ============================================
-- Business Analysis: Point-in-Time Reporting
-- ============================================

-- How many trips went to "Midtown Center" in 2023?
-- (All 2023 trips should show the old name)
SELECT 
    z.zone,
    COUNT(*) as trip_count,
    SUM(f.total_amount) as total_revenue
FROM warehouse.yellow_tripdata_2023 f
JOIN warehouse.dim_taxi_zone z ON f.pu_zone_key = z.zone_key
WHERE z.location_lk_id = 161
GROUP BY z.zone;

-- Expected: All trips show "Midtown Center" because facts are frozen with zone_key = 691

-- ============================================
-- Advanced: Show All Historical Versions
-- ============================================

-- See the complete history of zone 161
SELECT 
    zone_key,
    location_lk_id,
    zone,
    valid_from,
    valid_to,
    is_current,
    CASE 
        WHEN is_current THEN 'ACTIVE'
        ELSE 'HISTORICAL'
    END as status,
    (valid_to - valid_from) as days_valid
FROM warehouse.dim_taxi_zone
WHERE location_lk_id = 161
ORDER BY valid_from;

-- ============================================
-- Challenge: Find All Zones That Changed
-- ============================================

-- Which zones have multiple versions (SCD2 changes)?
SELECT 
    location_lk_id,
    COUNT(*) as version_count,
    STRING_AGG(zone, ' → ' ORDER BY valid_from) as name_history
FROM warehouse.dim_taxi_zone
GROUP BY location_lk_id
HAVING COUNT(*) > 1
ORDER BY version_count DESC;

-- Expected: Should show zone 161 with "Midtown Center → Midtown North"