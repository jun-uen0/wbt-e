import json
import boto3
import csv
from datetime import datetime, timedelta

s3_client = boto3.client('s3')

def lambda_handler(event, context):

  bucket_name = 'wbt-e-s3-bucket-dev'
  object_key = 'recommended-fishing-rivers-and-streams-1.csv'

  # Download CSV file from S3
  response = s3_client.get_object(Bucket=bucket_name, Key=object_key)
  csv_data = response['Body'].read().decode('utf-8').splitlines()

  kinesis_client = boto3.client('kinesis')
  
  # DynamoDB table to store county statistics
  dynamodb_table_name = 'wbt-e-dynamodb-dev'
  DYNAMO = boto3.resource('dynamodb')
  table = DYNAMO.Table(dynamodb_table_name)

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

    stream_name = 'wbt-e-kds-dev'
    partition_key = 'partition-key' # We have just one shard in this project

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

  # Calculate current time and time 5 minutes ago
  current_time = datetime.utcnow()
  five_minutes_ago = current_time - timedelta(minutes = 5)
  
  # Get data from the Kinesis stream for the past 5 minutes
  shard_iterator = kinesis_client.get_shard_iterator(
    StreamName = 'wbt-e-kds-dev',
    ShardId = 'shardId-000000000000',
    ShardIteratorType = 'AT_TIMESTAMP',
    Timestamp = five_minutes_ago
  )['ShardIterator']

  print(f'shard_iterator ', shard_iterator)

  # Read records from the shard
  records = []
  response = kinesis_client.get_records(
    ShardIterator = shard_iterator,
    Limit = 100
  )
  records.extend(response['Records'])
  
  print(f'records', records)

  # Aggregate values in the County field
  county_counts = {}
  for record in records:
    data = json.loads(record['Data'])
    county = data.get('County')
    if county:
      county_counts[county] = county_counts.get(county, 0) + 1

  print(f'county_counts', county_counts)

  # Save the aggregation results to DynamoDB
  table = DYNAMO.Table(dynamodb_table_name)
  with table.batch_writer() as batch:
    for county, count in county_counts.items():
      batch.put_item(
        Item = {
          'County': county,
          'Count': count
          }
        )

  return {
    'statusCode': 200,
    'body': json.dumps('Data publishing completed.')
  }
