# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
import csv
import json


def dictionary_to_csv(data, csv_file_path):
    """
    Write a list of dictionaries to a CSV file.
    """
    with open(csv_file_path, 'w') as f:
        writer = csv.DictWriter(f, fieldnames=data[0].keys())
        writer.writeheader()
        for row in data:
            writer.writerow(row)


def dictionary_to_json(data, json_file_path):
    """
    Write a list of dictionaries to a CSV file.
    """
    with open(json_file_path, 'w') as f:
        json.dump(data, f)


def csv_to_dictionary(csv_file_path):
    """
    Read a CSV file into a list of dictionaries.
    """
    with open(csv_file_path, 'r') as f:
        reader = csv.DictReader(f)
        data = list(reader)
    return data


def json_to_csv(json_file_path, csv_file_path):
    """
    Convert a JSON file to a CSV file.

    :param json_file_path: The path to the JSON file to convert.
    :param csv_file_path: The path to save the resulting CSV file.
    """
    with open(json_file_path, 'r') as json_file:
        # Read the JSON data using the built-in json module
        json_data = json.load(json_file)

        # Get the header row from the keys of the first dictionary in the list
        header = list(json_data[0].keys())

        # Write the header row and data rows to a CSV file using the built-in csv module
        with open(csv_file_path, 'w', newline='') as csv_file:
            writer = csv.DictWriter(csv_file, fieldnames=header)
            writer.writeheader()
            writer.writerows(json_data)


def csv_to_json(csv_file_path, json_file_path):
    """
    Convert a CSV file to a JSON file.

    :param csv_file_path: The path to the CSV file to convert.
    :param json_file_path: The path to save the resulting JSON file.
    """
    with open(csv_file_path, 'r') as csv_file:
        # Read the CSV file using the built-in csv module
        csv_data = csv.DictReader(csv_file)

        # Convert the CSV data to a list of dictionaries
        data_list = []
        for row in csv_data:
            data_list.append(row)

        # Write the list of dictionaries to a JSON file using the built-in json module
        with open(json_file_path, 'w') as json_file:
            json.dump(data_list, json_file)
