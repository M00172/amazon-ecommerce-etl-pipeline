import pandas as pd
import os

# LOAD
print("Loading...")
df = pd.read_csv('Data/Raw Data/Amazon-Products.csv', engine='python')
print(f"Original:{len(df)}rows")

# CLEAN
# a)Removing Useless column
if 'Unnamed: 0' in df.columns:
    df = df.drop(columns=['Unnamed: 0'])

# b) Cleaning the prices - Removing ₹,commas, and symbols
for col in ['discount_price', 'actual_price']:
    if col in df.columns:
        df[col] = df[col].astype(str).str.replace('₹', '', regex=False).str.replace(
            ',', '', regex=False)
        df[col] = df[col].str.replace(r'[^0-9.]', '', regex=True)
        df[col] = pd.to_numeric(df[col], errors='coerce')

# c) Filling Missing Values
# So Mobile gets Mobile Median, Ac gets Ac Median - not same value for all
# Fix sub_category nulls first to avoid group by error
df['sub_category'] = df['sub_category'].fillna(
    'unknown').astype(str).str.strip()

# Calculate median per category and map - no transform error
discount_median_map = df.groupby('sub_category')['discount_price'].median()
actual_median_map = df.groupby('sub_category')['actual_price'].median()

# Fii with category median
df['discount_price'] = df['discount_price'].fillna(
    df['sub_category'].map(discount_median_map))
df['actual_price'] = df['actual_price'].fillna(
    df['sub_category'].map(actual_median_map))

# Fill remaining nulls with overall median(Extra safety)
df['actual_price'] = df['discount_price'].fillna(df['discount_price'].median())
df['actual_price'] = df['actual_price'].fillna(df['actual_price'].median())

# Filling Ratings - 0 means no one rated
df['ratings'] = df['ratings'].fillna(0)
df['no_of_ratings'] = df['no_of_ratings'].fillna(0)

# d) Save Cleaned File
os.makedirs('Data/Cleaned Data', exist_ok=True)
df.to_csv('amazon_cleaned.csv', index=False)
print("5 lakhs rows Done!")
print(df.isnull().sum())
