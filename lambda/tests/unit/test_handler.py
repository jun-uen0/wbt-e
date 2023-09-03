import unittest
from unittest.mock import Mock, patch
from hello_world import app

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