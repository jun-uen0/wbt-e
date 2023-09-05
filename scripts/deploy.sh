#!/bin/bash

set -e

# Get arguments and define enviroment
usage() {
  echo "Please specify arguments after the command:"
  echo "Deploy to the development environment: ./deploy.sh dev"
  echo "Deploy to the e2e environment: ./deploy.sh e2e"
  echo "Deploy to the production environment: ./deploy.sh prod"
}

if [ -z "$1" ]; then
  usage
  exit
fi

case "$1" in "dev" | "e2e" | "prod" ) ;; * )
  usage
  echo "Invalid argument. Allowed arguments are 'dev', 'e2e', and 'prod'."
  exit 1 ;;
esac

if [ "$1" == "prod" ]; then
  read -p "This command will deploy to the production environment. Are you sure? (y/N): " yn
  case "$yn" in [yY]*) ;; *) echo "Exiting" ; exit ;; esac
fi

# Check if aws-cli version is >= required_aws_cli_version
aws_cli_version=$(aws --version 2>&1 | awk '/aws-cli/{print $1}' | cut -d/ -f2)
required_aws_cli_version="1.10" # Minimum version
if [ "$(printf '%s\n' "$required_aws_cli_version" "$aws_cli_version" | sort -V | head -n1)" != "$required_aws_cli_version" ]; then
  echo "Error: aws-cli version should be $required_aws_cli_version or higher."
  exit 1
fi

# Check if SAM version is >= required_sam_version
sam_version=$(sam --version 2>&1 | awk '/SAM CLI/{print $4}')
required_sam_version="1.82.0" # Minimum version
if [ "$(printf '%s\n' "$required_sam_version" "$sam_version" | sort -V | head -n1)" != "$required_sam_version" ]; then
  echo "Error: SAM CLI version should be $required_sam_version or higher."
  exit 1
fi

# Check Python version
python_version=$(python3 --version 2>&1 | awk '/Python/{print $2}')
required_python_version="3.9.0"  # Minimum required Python version

if [[ ! $python_version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Error: Failed to parse Python version."
  exit 1
fi

IFS=. read -ra version_parts <<< "$python_version"
IFS=. read -ra required_parts <<< "$required_python_version"

for ((i=0; i<3; i++)); do
  if ((version_parts[i] < required_parts[i])); then
    echo "Error: Python version should be $required_python_version or higher."
    exit 1
  fi
done

# Variables
env=$1
testfile_path=../lambda/tests/e2e/test-files/test.csv

# Change current diretory to `scripts/`
cd $(dirname $0)
cd ../cfn/

# Deploy S3
echo "Creating stack s3-${env}"
aws cloudformation deploy \
  --template-file s3.yml \
  --stack-name s3-${env} \
  --s3-prefix ${env} \
  --parameter-overrides Env=${env}

if [ "$1" == "e2e" ]; then
  echo "Update file (csv) for e2e testing to S3 bucket created"
  aws s3 cp ${testfile_path} s3://wbt-e-s3-bucket-e2e/
fi

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

cd ../lambda

# If e2e test, build and deploy e2e application
if [ "$1" == "e2e" ]; then
  echo "changing application code for e2e test"
  mv hello_world/app.py hello_world/app_bk.py
  cp tests/e2e/e2e.py hello_world/app.py
fi

# Build Lambda
sam build

# Test(Unit) Lambda
python3 -m pytest

# Deploy Lambda
sam deploy \
  --stack-name lambda-${env} \
  --s3-prefix ${env}

# If e2e test, fetch data and confirm it's correct and then destory all AWS services created
if [ "$1" == "e2e" ]; then
  # Run locally
  sam local invoke
  # Fetch data from DynamoDB
  # Compare data
  # Cleanup everything
fi

# If Production deployment, ask about running stream.sh