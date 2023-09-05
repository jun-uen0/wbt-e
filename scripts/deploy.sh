#!/bin/bash

# Change current diretory to `scripts/`
cd $(dirname $0)
cd ../cfn/

# Check if aws-cli version is >= required_aws_cli_version
aws_cli_version=$(aws --version 2>&1 | awk '/aws-cli/{print $1}' | cut -d/ -f2)
required_aws_cli_version="1.10" # Minimum version
if [ "$(printf '%s\n' "$required_aws_cli_version" "$aws_cli_version" | sort -V | head -n1)" != "$required_aws_cli_version" ]; then
  echo "Error: aws-cli version should be $required_aws_cli_version or higher."
  exit 1
fi

# Deploy S3
echo "Creating stack s3-${env}"
aws cloudformation deploy \
  --template-file s3.yml \
  --stack-name s3-${env} \
  --s3-prefix ${env} \
  --parameter-overrides Env=${env}

echo "Update file (csv) for e2e testing to S3 bucket created"
aws s3 cp ${testfile_path} s3://wbt-e-s3-bucket-e2e/

# Deploy Kinesis Data Stream
echo "Creating stack kds-${env}"
aws cloudformation deploy \
  --template-file kds.yml \
  --stack-name kds-${env} \
  --s3-prefix ${env} \
  --parameter-overrides Env=${env}

# Deploy DynamoDB
echo "Creating stack dynamodb-${env}"
aws cloudformation deploy \
  --template-file dynamodb.yml \
  --stack-name dynamodb-${env} \
  --s3-prefix ${env} \
  --parameter-overrides Env=${env}