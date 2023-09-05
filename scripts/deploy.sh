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
aws cloudformation deploy \
  --template-file s3.yml \
  --stack-name sample-stack \
  --s3-prefix prod \
  --parameter-overrides Env=prod

# Deploy Kinesis Data steam
# Deploy 