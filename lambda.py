import json
import boto3
import csv

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

    print(f"Waterbody Name: {waterbody_name}")
    print(f"Fish Species: {fish_species}")

  # Next Step goes here:
  # Data processing
  # Kinesis

  return {
    'statusCode': 200,
    'body': json.dumps('Data publishing completed.')
  }
