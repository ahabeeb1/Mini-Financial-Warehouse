import pandas as pd
from sqlalchemy import create_engine
from datetime import datetime, date

class SCD2Manager:
    """
    Manages SCD2 operations using Pandas + PostgreSQL
    
    Learning objectives:
    - Read from PostgreSQL into Pandas DataFrames
    - Detect dimension changes
    - Close old records (UPDATE)
    - Insert new versions (INSERT)
    - Maintain temporal integrity
    """
    
    def __init__(self):
        # Connection string
        self.engine = create_engine(
            'postgresql://warehouse_user:warehouse_pass@localhost:5432/taxi_warehosue'
        )
        print("✅ Connected to PostgreSQL")
    
    def read_dimension(self, table_name):
        """Read dimension table into Pandas DataFrame"""
        query = f"SELECT * FROM warehouse.{table_name}"
        df = pd.read_sql(query, self.engine)
        print(f"📊 Read {len(df)} rows from {table_name}")
        return df
    
    def detect_changes(self, current_df, new_data, natural_key, compare_columns):
        """
        Detect which records have changed
        
        Args:
            current_df: Current dimension data (from warehouse)
            new_data: New data (from staging or external source)
            natural_key: Business key (e.g., 'location_lk_id')
            compare_columns: Columns to check for changes (e.g., ['zone', 'borough'])
        
        Returns:
            DataFrame of changed records
        """
        # Filter to current records only
        current_active = current_df[current_df['is_current'] == True].copy()
        
        # Merge to find matches
        merged = new_data.merge(
            current_active,
            on=natural_key,
            how='inner',
            suffixes=('_new', '_old')
        )
        
        # Detect changes in any compare column
        changed_mask = False
        for col in compare_columns:
            changed_mask |= (merged[f'{col}_new'] != merged[f'{col}_old'])
        
        changes = merged[changed_mask].copy()
        print(f"🔍 Detected {len(changes)} changes")
        return changes
    
    def close_old_records(self, table_name, natural_key, changed_ids, effective_date):
        """
        Close old dimension records (SCD2 Type 2)
        
        Sets:
        - valid_to = effective_date - 1 day
        - is_current = FALSE
        """
        if len(changed_ids) == 0:
            print("⚠️ No records to close")
            return
        
        # Build UPDATE query
        ids_str = ','.join(map(str, changed_ids))
        valid_to_date = pd.to_datetime(effective_date) - pd.Timedelta(days=1)
        
        update_query = f"""
        UPDATE warehouse.{table_name}
        SET 
            valid_to = '{valid_to_date.date()}'::DATE,
            is_current = FALSE
        WHERE {natural_key} IN ({ids_str})
          AND is_current = TRUE;
        """
        
        with self.engine.connect() as conn:
            result = conn.execute(update_query)
            conn.commit()
            print(f"✅ Closed {result.rowcount} old records")
    
    def insert_new_versions(self, table_name, new_records_df, effective_date):
        """
        Insert new dimension versions
        
        Sets:
        - valid_from = effective_date
        - valid_to = '9999-12-31'
        - is_current = TRUE
        """
        if len(new_records_df) == 0:
            print("⚠️ No new records to insert")
            return
        
        # Set SCD2 fields
        new_records_df['valid_from'] = pd.to_datetime(effective_date)
        new_records_df['valid_to'] = pd.to_datetime('9999-12-31')
        new_records_df['is_current'] = True
        new_records_df['created_at'] = datetime.now()
        
        # Insert into database
        new_records_df.to_sql(
            table_name,
            self.engine,
            schema='warehouse',
            if_exists='append',
            index=False
        )
        print(f"✅ Inserted {len(new_records_df)} new versions")
    
    def apply_scd2_changes(self, table_name, new_data, natural_key, compare_columns, effective_date):
        """
        Complete SCD2 workflow:
        1. Read current dimension
        2. Detect changes
        3. Close old records
        4. Insert new versions
        """
        print(f"\n🔄 Starting SCD2 process for {table_name}...")
        
        # Step 1: Read current dimension
        current_df = self.read_dimension(table_name)
        
        # Step 2: Detect changes
        changes = self.detect_changes(current_df, new_data, natural_key, compare_columns)
        
        if len(changes) == 0:
            print("✅ No changes detected - dimension is up to date")
            return
        
        # Step 3: Close old records
        changed_ids = changes[natural_key].unique()
        self.close_old_records(table_name, natural_key, changed_ids, effective_date)
        
        # Step 4: Prepare and insert new versions
        # Select only the new columns from changes
        new_cols = [col for col in new_data.columns]
        new_records = changes[[f'{col}_new' for col in new_cols if f'{col}_new' in changes.columns]]
        new_records.columns = new_cols  # Remove '_new' suffix
        
        self.insert_new_versions(table_name, new_records, effective_date)
        
        print(f"✅ SCD2 process complete for {table_name}\n")


# ============================================
# Example Usage
# ============================================

if __name__ == "__main__":
    # Initialize SCD2 manager
    scd2 = SCD2Manager()
    
    # Example 1: Simulate zone name change
    print("=" * 60)
    print("EXAMPLE 1: Zone Name Change")
    print("=" * 60)
    
    # New data (simulating a zone rename)
    new_zones = pd.DataFrame({
        'location_lk_id': [161],
        'borough': ['Manhattan'],
        'zone': ['Midtown North'],  # Changed from "Midtown Center"
        'service_zone': ['Yellow Zone']
    })
    
    # Apply SCD2
    scd2.apply_scd2_changes(
        table_name='dim_taxi_zone',
        new_data=new_zones,
        natural_key='location_lk_id',
        compare_columns=['zone', 'borough', 'service_zone'],
        effective_date='2024-07-15'
    )
    
    # Verify results
    print("\n📊 Verification: Zone 161 History")
    print("=" * 60)
    query = """
    SELECT zone_key, location_lk_id, zone, valid_from, valid_to, is_current
    FROM warehouse.dim_taxi_zone
    WHERE location_lk_id = 161
    ORDER BY valid_from;
    """
    result = pd.read_sql(query, scd2.engine)
    print(result.to_string(index=False))
    
    print("\n✅ SCD2 with Pandas - Complete!")