#!/bin/bash

set -e

# Change current diretory to `scripts/`
cd "$(dirname "$0")"
cd ../lambda/

# Check if SAM version is >= required_sam_version
sam_version=$(sam --version 2>&1 | awk '/SAM CLI/{print $4}')
required_sam_version="1.82.0" # Minimum version
if [ "$(printf '%s\n' "$required_sam_version" "$sam_version" | sort -V | head -n1)" != "$required_sam_version" ]; then
	echo "Error: SAM CLI version should be $required_sam_version or higher."
	exit 1
fi

# Check if aws-cli version is >= required_aws_cli_version
aws_cli_version=$(aws --version 2>&1 | awk '/aws-cli/{print $1}' | cut -d/ -f2)
required_aws_cli_version="1.10" # Minimum version
if [ "$(printf '%s\n' "$required_aws_cli_version" "$aws_cli_version" | sort -V | head -n1)" != "$required_aws_cli_version" ]; then
	echo "Error: aws-cli version should be $required_aws_cli_version or higher."
	exit 1
fi

# Build application
sam build
