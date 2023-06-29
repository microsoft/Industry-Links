# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License.
from converters import dictionary_to_csv, dictionary_to_json
import datetime
import random
import sys

weather_measurement_types = [
    {'name': 'temperature', 'unit': 'C', 'min': 0, 'max': 45},
    {'name': 'wind_speed', 'unit': 'km/h', 'min': 0, 'max': 30},
    {'name': 'wind_direction', 'unit': 'degrees', 'min': 0, 'max': 360},
    {'name': 'solar_radiation', 'unit': 'W/m2', 'min': 100, 'max': 500},
    {'name': 'humidity', 'unit': '%', 'min': 1, 'max': 100},
    {'name': 'barometric_pressure', 'unit': 'hPa', 'min': 1000, 'max': 1030}
]

water_measurement_types = [
    {'name': 'withdrawal', 'unit': 'gallon', 'min': 10, 'max': 1000},
    {'name': 'discharge', 'unit': 'gallon', 'min': 10, 'max': 1000}
]


def generate_hourly_timestamps(start_date, end_date):
    """
    Generate hourly timestamps between start_date and end_date.

    Example:
    ['2023-01-01T00:00:00Z','2023-01-01T01:00:00Z','2023-01-01T02:00:00Z']
    """
    hourly_timestamps = [
        start_date + datetime.timedelta(hours=x) for x in range(0, (end_date-start_date).days*24)]
    return hourly_timestamps


def generate_instruments(count=20):
    """
    Generate a list of instrument IDs.

    Example:
    ['instr00001','instr00002','instr00003']
    """
    instruments = []
    for c_idx in range(0, count):
        instrument = 'instr{:05d}'.format(c_idx)
        instruments.append(instrument)
    return instruments


def generate_hourly_measurements(start_date, end_date, instruments=[], n_instruments=20, measurement_types=weather_measurement_types):
    """
    Generates a list of hourly weather measurements for a given date range,
    number of instruments, and list of measurement types. The expected output
    is a list of dictionaries, with each dictionary containing a single
    measurement type and data for one hour.

    Example:
    [{'timestamp': '2018-01-01T00:00:00Z', 'name': 'temperature', 'value': 23.5, 'unit': 'C', 'instrument': 'instr00001' },
    {'timestamp': '2018-01-01T00:00:00Z', 'name': 'wind_speed', 'value': 5.2, 'unit': 'km/h', 'instrument': 'instr00001' },
    {'timestamp': '2018-01-01T00:00:00Z', 'name': 'wind_direction', 'value': 180, 'unit': 'degrees', 'instrument': 'instr00001' },
    {'timestamp': '2018-01-01T00:00:00Z', 'name': 'solar_radiation', 'value': 400, 'unit': 'W/m2', 'instrument': 'instr00001' },
    {'timestamp': '2018-01-01T00:00:00Z', 'name': 'humidity', 'value': 90, 'unit': '%', 'instrument': 'instr00001' },
    {'timestamp': '2018-01-01T00:00:00Z', 'name': 'barometric_pressure', 'value': 1013.25, 'unit': 'hPa', 'instrument': 'instr00001' }]
    """
    if (len(instruments) == 0):
        instruments = generate_instruments(count=n_instruments)

    measurements = []
    hourly_timestamps = generate_hourly_timestamps(
        start_date=start_date, end_date=end_date)
    for ts in hourly_timestamps:
        ts_str = ts.strftime('%Y-%m-%dT%H:%M:%SZ')

        for instrument in instruments:
            for mt in measurement_types:
                value = round(random.uniform(mt['min'], mt['max']), 5)
                measurement = {
                    'timestamp': ts_str,
                    'name': mt['name'],
                    'value': value,
                    'unit': mt['unit'],
                    'instrument': instrument
                }
                measurements.append(measurement)
    return measurements


def main():
    input_start_date = sys.argv[1]
    input_end_date = sys.argv[2]
    input_n_instruments = sys.argv[3]
    input_measurement_type = sys.argv[4]
    output_filepath = sys.argv[5]

    start_date = datetime.datetime.strptime(
        input_start_date, '%Y-%m-%d %H:%M:%S')
    end_date = datetime.datetime.strptime(input_end_date, '%Y-%m-%d %H:%M:%S')

    measurement_types = []
    if input_measurement_type.lower() == 'weather':
        measurement_types = weather_measurement_types
    elif input_measurement_type.lower() == 'water':
        measurement_types = water_measurement_types
    else:
        print('Measurement type not recognized. Exiting.')
        sys.exit(1)

    data = generate_hourly_measurements(start_date, end_date, n_instruments=int(
        input_n_instruments), measurement_types=measurement_types)

    if output_filepath.lower().endswith('.csv'):
        dictionary_to_csv(data, output_filepath)
    elif output_filepath.lower().endswith('.json'):
        dictionary_to_json(data, output_filepath)
    else:
        print('Output file extension (csv, json) not recognized. Exiting.')
        sys.exit(1)


if __name__ == '__main__':
    main()
