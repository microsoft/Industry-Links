# Generating Sample Data
This document describes how to generate sample data for testing your Industry Links.

## Prerequisites
To run the following scripts, you will need:
- Python 3.6 or higher installed

## Measurements
The `generate_measurements.py` script is provided to generate sample measurements and output it into a CSV or JSON file.

Usage:
```
python generate_measurements.py <start-timestamp> <end-timestamp> <number-of-instruments> <water|weather> <output-file-path>
```
Example:
```
python generate_measurements.py "2023-01-01 00:00:00" "2023-03-01 00:00:00" 5 water water_measurements.csv
```

## Transactions
The `generate_transactions.py` script is provided to generate sample transactions and output it into a JSON or CSV file.

Usage:
```
python generate_transactions.py <min-timestamp> <max-timestamp> <number-of-transactions> <number-of-customers> <number-of-merchants> <output-file-path>
```
Example:
```
python generate_transactions.py "2023-01-01 00:00:00" "2023-03-01 00:00:00" 100 5 10 cc_transactions.json
```