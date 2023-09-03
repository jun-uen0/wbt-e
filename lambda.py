import json
import boto3
import csv
from datetime import datetime

s3_client = boto3.client('s3')

def lambda_handler(event, context):

  bucket_name = 'wbt-e-s3-bucket-dev'
  object_key = 'recommended-fishing-rivers-and-streams-1.csv'

  # Download CSV file from S3
  response = s3_client.get_object(Bucket=bucket_name, Key=object_key)
  csv_data = response['Body'].read().decode('utf-8').splitlines()

  # Process date for each row
  for row in csv.reader(csv_data):
    waterbody_name = row[0]
    fish_species = row[1]
    comments = row[2]
    regulations_link = row[3]
    county = row[4]
    access_types = row[5]
    access_owner = row[6]
    waterbody_info = row[7]
    longitude = row[8]
    latitude = row[9]
    location = row[10]

    # Add timestamp column with the current datetime
    timestamp = datetime.now().isoformat()

    stream_name = 'wbt-e-kds-dev' # Name of stream that is created at kds.yml # TODO
    partition_key = 'partition-key' # We have just one shard in this project

    # Create instance
    kinesis_client = boto3.client('kinesis')

    # Create a dictionary with the data you want to publish to Kinesis
    data = {
      'WaterbodyName': waterbody_name,
      'FishSpecies': fish_species,
      'Comments': comments,
      'RegulationsLink': regulations_link,
      'County': county,
      'AccessTypes': access_types,
      'AccessOwner': access_owner,
      'WaterbodyInfo': waterbody_info,
      'Longitude': longitude,
      'Latitude': latitude,
      'Location': location,
      'Timestamp': timestamp  # Add the timestamp column
    }

    # Publish data to Kinesis
    response = kinesis_client.put_record(
      StreamName = stream_name,
      Data = json.dumps(data), # Convert Data to Json style
      PartitionKey = partition_key
    )

    print('Published to Kinesis Data Stream. SequenceNumber: {}'.format(response['SequenceNumber']))

  return {
    'statusCode': 200,
    'body': json.dumps('Data publishing completed.')
  }
