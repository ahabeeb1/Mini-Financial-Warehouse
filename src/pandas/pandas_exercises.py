"""
Pandas SCD2 Learning Exercises

Complete these exercises to master SCD2 with Pandas
"""

import pandas as pd
from scd2_pandas import SCD2Manager

def exercise_1_vendor_rebrand():
    """
    Exercise 1: Vendor Rebrand
    
    Task: Curb Mobility rebrands to "Curb LLC" on 2024-06-01
    
    Steps:
    1. Create new vendor data with updated name
    2. Apply SCD2 changes
    3. Verify both versions exist
    """
    print("\n🎓 EXERCISE 1: Vendor Rebrand")
    print("=" * 60)
    
    scd2 = SCD2Manager()
    
    # TODO: Create new_vendors DataFrame
    # Hint: vendor_lk_id=2, vendor_name='Curb LLC'
    new_vendors = pd.DataFrame({
        'vendor_lk_id': [2],
        'vendor_name': ['Curb LLC']
    })
    
    # TODO: Apply SCD2 changes
    # Hint: Use scd2.apply_scd2_changes()
    scd2.apply_scd2_changes(
        table_name='dim_vendor',
        new_data=new_vendors,
        natural_key='vendor_lk_id',
        compare_columns=['vendor_name'],
        effective_date='2024-06-01'
    )
    
    # Verify
    query = "SELECT * FROM warehouse.dim_vendor WHERE vendor_lk_id = 2 ORDER BY valid_from"
    result = pd.read_sql(query, scd2.engine)
    print("\n✅ Result:")
    print(result[['vendor_key', 'vendor_lk_id', 'vendor_name', 'valid_from', 'valid_to', 'is_current']])


def exercise_2_time_travel_query():
    """
    Exercise 2: Time-Travel Query with Pandas
    
    Task: Query vendor name as of different dates
    
    Learn: Point-in-time queries using Pandas
    """
    print("\n🎓 EXERCISE 2: Time-Travel Query")
    print("=" * 60)
    
    scd2 = SCD2Manager()
    
    # Read all vendor versions
    vendors = scd2.read_dimension('dim_vendor')
    
    # TODO: Filter to vendor_lk_id = 2
    vendor_2 = vendors[vendors['vendor_lk_id'] == 2].copy()
    
    # Convert dates to datetime
    vendor_2['valid_from'] = pd.to_datetime(vendor_2['valid_from'])
    vendor_2['valid_to'] = pd.to_datetime(vendor_2['valid_to'])
    
    # TODO: Find vendor name on 2024-05-15 (before rebrand)
    query_date_1 = pd.to_datetime('2024-05-15')
    name_before = vendor_2[
        (vendor_2['valid_from'] <= query_date_1) & 
        (vendor_2['valid_to'] >= query_date_1)
    ]['vendor_name'].values[0]
    
    print(f"Vendor name on 2024-05-15: {name_before}")
    
    # TODO: Find vendor name on 2024-07-01 (after rebrand)
    query_date_2 = pd.to_datetime('2024-07-01')
    name_after = vendor_2[
        (vendor_2['valid_from'] <= query_date_2) & 
        (vendor_2['valid_to'] >= query_date_2)
    ]['vendor_name'].values[0]
    
    print(f"Vendor name on 2024-07-01: {name_after}")


def exercise_3_bulk_changes():
    """
    Exercise 3: Process Multiple Changes
    
    Task: Update multiple zones at once
    
    Learn: Batch SCD2 processing
    """
    print("\n🎓 EXERCISE 3: Bulk Changes")
    print("=" * 60)
    
    scd2 = SCD2Manager()
    
    # TODO: Create DataFrame with multiple zone changes
    new_zones = pd.DataFrame({
        'location_lk_id': [161, 162, 163],
        'borough': ['Manhattan', 'Manhattan', 'Manhattan'],
        'zone': ['Midtown North', 'Midtown East Updated', 'Midtown West Updated'],
        'service_zone': ['Yellow Zone', 'Yellow Zone', 'Yellow Zone']
    })
    
    # Apply all changes at once
    scd2.apply_scd2_changes(
        table_name='dim_taxi_zone',
        new_data=new_zones,
        natural_key='location_lk_id',
        compare_columns=['zone'],
        effective_date='2024-08-01'
    )
    
    print("\n✅ Bulk changes applied!")


if __name__ == "__main__":
    # Run exercises
    exercise_1_vendor_rebrand()
    exercise_2_time_travel_query()
    # exercise_3_bulk_changes()  # Uncomment to run