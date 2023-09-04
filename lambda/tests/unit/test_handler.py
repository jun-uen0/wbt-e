import unittest
from unittest.mock import Mock, patch
from hello_world import app
import json

class TestDownloadDataFromS3(unittest.TestCase):

  @patch('hello_world.app.s3_client')
  def test_download_data_from_s3(self, mock_s3_client):
    # Set up the mock
    bucket_name = 'test-bucket'
    object_key = 'test-key'
    csv_data = 'line1\nline2\nline3'
    response = {'Body': Mock(read=Mock(return_value=csv_data.encode('utf-8')))}
    mock_s3_client.get_object.return_value = response

    # Call the function under test
    result = app.download_data_from_s3(bucket_name, object_key)

    # Assert that the mock was called correctly
    mock_s3_client.get_object.assert_called_once_with(Bucket=bucket_name, Key=object_key)

    # Assert the function's return value
    expected_result = ['line1', 'line2', 'line3']
    self.assertEqual(result, expected_result)

if __name__ == '__main__':
  unittest.main()

class TestPublishDataToKinesis(unittest.TestCase):

  @patch('hello_world.app.kinesis_client')
  def test_publish_data_to_kinesis(self, mock_kinesis_client):
    # Set up the mock
    stream_name = 'test-stream'
    data = {
      'key1': 'value1',
      'key2': 'value2'
    }

    # Convert the data dictionary to a JSON string
    json_data = json.dumps(data)

    # Define the expected response from the mock
    expected_response = {'ResponseMetadata': {'HTTPStatusCode': 200}}

    # Configure the mock's put_record method to return the expected response
    mock_kinesis_client.put_record.return_value = expected_response

    # Call the function under test
    response = app.publish_data_to_kinesis(stream_name, data)

    # Assert that the mock's put_record method was called correctly
    mock_kinesis_client.put_record.assert_called_once_with(
      StreamName=stream_name,
      Data=json_data,  # Use the JSON string here
      PartitionKey='partition-key'
    )

    # Assert the function's return value
    self.assertEqual(response, expected_response)

if __name__ == '__main__':
  unittest.main()

class TestAggregateCountyData(unittest.TestCase):

  def test_aggregate_county_data(self):
    # Sample records with JSON data
    records = [
      {'Data': '{"County": "A"}'},
      {'Data': '{"County": "B"}'},
      {'Data': '{"County": "A"}'},
      {'Data': '{"Other": "Data"}'},  # This record should be ignored
      {'Data': '{"County": "B"}'},
    ]

    # Call the function under test
    result = app.aggregate_county_data(records)

    # Expected county counts
    expected_counts = {'A': 2, 'B': 2}

    # Assert that the function returns the correct county counts
    self.assertEqual(result, expected_counts)

if __name__ == '__main__':
  unittest.main()

# class TestUpdateDynamoDB(unittest.TestCase):

#   @patch('hello_world.app.DYNAMO.Table')
#   def test_update_dynamodb(self, mock_dynamodb_table):
#     # Set up the mock
#     table_name = 'test-table'
#     county_counts = {
#       'CountyA': 10,
#       'CountyB': 5,
#       'CountyC': 3
#     }

#     # Create a mock for the DynamoDB table
#     mock_table_instance = Mock()
#     mock_dynamodb_table.return_value = mock_table_instance

#     # Mock the batch_writer() method of the DynamoDB table
#     mock_batch_writer = Mock()
#     mock_table_instance.batch_writer.return_value = mock_batch_writer

#     # Call the function under test
#     app.update_dynamodb(table_name, county_counts)

#     # Ensure that the batch_writer() method of the mock was called correctly
#     mock_table_instance.batch_writer.assert_called_once()

#     # Ensure that the batch_writer() method of the mock was called with the correct arguments
#     expected_items = [
#       {'County': 'CountyA', 'Count': 10},
#       {'County': 'CountyB', 'Count': 5},
#       {'County': 'CountyC', 'Count': 3}
#     ]

#     mock_batch_writer.put_item.assert_called_once_with(Item=expected_items)

# if __name__ == '__main__':
#   unittest.main()
