# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
from converters import dictionary_to_csv, dictionary_to_json
import datetime
import math
import random
import sys
import uuid

sample_merchant_types = [
    'Agricultural Services',
    'Contracted Services',
    'Transportation Services',
    'Utility Services',
    'Retail Outlet Services',
    'Clothing Stores',
    'Miscellaneous Stores',
    'Business Services',
    'Professional Services and Membership Organizations',
    'Government Services',
    'Airlines',
    'Car Rental',
    'Lodging'
]


def generate_merchants(merchant_types=sample_merchant_types, count=100):
    """
    Generate a random list of merchants, with each merchant having a name,
    type, minimum transaction amount and maximum transaction amount.

    Example:
    [{'name': 'Merchant 1', 'type': 'Agricultural Services', 'min': 10, 'max': 50},
    {'name': 'Merchant 2', 'type': 'Clothing Stores', 'min': 50, 'max': 500},
    {'name': 'Merchant 3', 'type': 'Airlines', 'min': 500, 'max': 10000}]
    """
    merchants = []
    n_merchant_types = len(merchant_types)
    for m_idx in range(0, count):
        min_amount = random.randint(1, 100)
        merchant = {
            'name': 'Merchant {:d}'.format(m_idx),
            'type': merchant_types[random.randint(0, n_merchant_types-1)],
            'min': min_amount,
            'max': random.randint(min_amount*5, min_amount*20)
        }
        merchants.append(merchant)
    return merchants


def generate_customers(count=50):
    """
    Generate a list of customer IDs.

    Example:
    ['cust_1','cust_2','cust_3']
    """
    customers = []
    for c_idx in range(0, count):
        customer = 'cust_{:d}'.format(c_idx)
        customers.append(customer)
    return customers


def generate_transactions(start_date, end_date=datetime.datetime.now, n_transactions=1000, customers=[], n_customers=50, merchants=[], n_merchants=100):
    """
    Generates a list of transactions for a given date range, number of
    customers, and list of merchants. The expected output is a list of
    dictionaries, with each dictionary containing a single transaction.

    Example:
    [{'timestamp': '2023-02-10T16:54:57Z', 'transaction_id': 'fafd0ae0-fb86-4f0c-aa54-80b9253e7ee2', 'customer_id': 'cust_46', 'merchant_type': 'Miscellaneous Stores', 'merchant_name': 'Merchant 76', 'amount': 207.55},
    {'timestamp': '2023-02-10T18:41:14Z', 'transaction_id': 'b2de242f-11e2-4476-bb49-43d8af3001d6', 'customer_id': 'cust_49', 'merchant_type': 'Clothing Stores', 'merchant_name': 'Merchant 33', 'amount': 205.86},
    {'timestamp': '2023-02-10T20:26:04Z', 'transaction_id': '865474a4-5e13-427f-8703-74b6b0f0b044', 'customer_id': 'cust_38', 'merchant_type': 'Agricultural Services', 'merchant_name': 'Merchant 51', 'amount': 65.9},
    {'timestamp': '2023-02-10T22:17:33Z', 'transaction_id': '0d43f581-c110-4f2b-8367-f62dda1ae56b', 'customer_id': 'cust_43', 'merchant_type': 'Airlines', 'merchant_name': 'Merchant 11', 'amount': 990.25},
    {'timestamp': '2023-02-11T00:14:12Z', 'transaction_id': '6723e415-5aee-4e7c-b869-1e0916fbd3fe', 'customer_id': 'cust_10', 'merchant_type': 'Airlines', 'merchant_name': 'Merchant 82', 'amount': 12.37}]
    """
    if (len(customers) == 0):
        customers = generate_customers(count=n_customers)
    max_customers = len(customers) - 1

    if (len(merchants) == 0):
        merchants = generate_merchants(count=n_merchants)
    max_merchants = len(merchants) - 1

    transactions = []
    ts = start_date
    diff_seconds = (end_date-start_date).days*24*60*60
    max = math.floor(diff_seconds/n_transactions)
    min = math.floor(max/2)
    for _ in range(0, n_transactions):
        added_seconds = random.randint(min, max)
        ts = ts + datetime.timedelta(seconds=added_seconds)
        ts_str = ts.strftime('%Y-%m-%dT%H:%M:%SZ')
        cust_id = customers[random.randint(0, max_customers)]
        merchant = merchants[random.randint(0, max_merchants)]
        amount = round(random.uniform(merchant['min'], merchant['max']), 2)
        transaction = {
            'transaction_id': str(uuid.uuid4()),
            'timestamp': ts_str,
            'customer_id': cust_id,
            'merchant_type': merchant['type'],
            'merchant_name': merchant['name'],
            'amount': amount
        }
        transactions.append(transaction)
    return transactions


def main():
    input_start_date = sys.argv[1]
    input_end_date = sys.argv[2]
    input_n_transactions = sys.argv[3]
    input_n_customers = sys.argv[4]
    input_n_merchants = sys.argv[5]
    output_filepath = sys.argv[6]

    start_date = datetime.datetime.strptime(
        input_start_date, '%Y-%m-%d %H:%M:%S')
    end_date = datetime.datetime.strptime(input_end_date, '%Y-%m-%d %H:%M:%S')

    data = generate_transactions(start_date, end_date, n_transactions=int(
        input_n_transactions), n_customers=int(input_n_customers), n_merchants=int(input_n_merchants))

    if output_filepath.lower().endswith('.csv'):
        dictionary_to_csv(data, output_filepath)
    elif output_filepath.lower().endswith('.json'):
        dictionary_to_json(data, output_filepath)
    else:
        print('Output file extension (csv, json) not recognized. Exiting.')
        sys.exit(1)


if __name__ == '__main__':
    main()
