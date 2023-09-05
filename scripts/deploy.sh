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

# Variables
env=$1
testfile_path=../lambda/tests/e2e/test-files/test.csv

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