import json
import boto3
import csv
from datetime import datetime, timedelta

s3_client = boto3.client('s3')
kinesis_client = boto3.client('kinesis')
dynamodb_client = boto3.client('dynamodb')
DYNAMO = boto3.resource('dynamodb')

def download_data_from_s3(bucket_name, object_key):
  response = s3_client.get_object(Bucket=bucket_name, Key=object_key)
  csv_data = response['Body'].read().decode('utf-8').splitlines()
  return csv_data

def publish_data_to_kinesis(stream_name, data):
  response = kinesis_client.put_record(
    StreamName=stream_name,
    Data=json.dumps(data),
    PartitionKey='partition-key'
  )
  return response

def aggregate_county_data(records):
  county_counts = {}
  for record in records:
    data = json.loads(record['Data'])
    county = data.get('County')
    if county:
      county_counts[county] = county_counts.get(county, 0) + 1
  return county_counts

def update_dynamodb(table_name, county_counts):
  table = DYNAMO.Table(table_name)
  with table.batch_writer() as batch:
    for county, count in county_counts.items():
      batch.put_item(
        Item={
          'County': county,
          'Count': count
        }
      )

def lambda_handler(event, context):
  bucket_name = 'wbt-e-s3-bucket-e2e'
  object_key = 'test.csv'
  stream_name = 'wbt-e-kds-e2e'
  dynamodb_table_name = 'wbt-e-dynamodb-e2e'

  csv_data = download_data_from_s3(bucket_name, object_key)

  # Process and publish data to Kinesis
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

    publish_data_to_kinesis(stream_name, data)

  # Get data from Kinesis and aggregate county counts
  current_time = datetime.utcnow()
  five_minutes_ago = current_time - timedelta(minutes=5)
  shard_iterator = kinesis_client.get_shard_iterator(
    StreamName=stream_name,
    ShardId='shardId-000000000000',
    ShardIteratorType='AT_TIMESTAMP',
    Timestamp=five_minutes_ago
  )['ShardIterator']

  records = []
  response = kinesis_client.get_records(
    ShardIterator=shard_iterator,
    Limit=100
  )
  records.extend(response['Records'])

  county_counts = aggregate_county_data(records)

  # Update DynamoDB
  update_dynamodb(dynamodb_table_name, county_counts)

  return {
    'statusCode': 200,
    'body': json.dumps('Data publishing completed.')
  }
