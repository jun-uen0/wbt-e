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

# Check Docker version
DOCKER_VERSION=$(docker --version | awk -F '[ ,]+' '{print $3}')
DOCKER_MAJOR_VERSION=$(echo "$DOCKER_VERSION" | awk -F '.' '{print $1}')

if [ "$DOCKER_MAJOR_VERSION" -ge 20 ]; then
	echo "Docker version is $DOCKER_VERSION, which meets the minimum requirement."
else
	echo "Error: Docker version $DOCKER_VERSION is not supported. Please upgrade to version 20 or higher."
	exit 1
fi

# Check Python version
python_version=$(python3 --version 2>&1 | awk '/Python/{print $2}')
required_python_version="3.9.0" # Minimum required Python version

if [[ ! $python_version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
	echo "Error: Failed to parse Python version."
	exit 1
fi

IFS=. read -ra version_parts <<<"$python_version"
IFS=. read -ra required_parts <<<"$required_python_version"

for ((i = 0; i < 3; i++)); do
	if ((version_parts[i] < required_parts[i])); then
		echo "Error: Python version should be $required_python_version or higher."
		exit 1
	fi
done

read -r -p "Run application indefinitely? (y/N):" yn
case "$yn" in [yY]*) ;; *)
	echo "Exit"
	exit
	;;
esac

read -r -p "Did you build application? (y/N):" yn
case "$yn" in [yY]*) ;; *)
	echo "Exit"
	exit
	;;
esac

read -r -p "Did you deploy application to Lambda? (y/N):" yn
case "$yn" in [yY]*) ;; *)
	echo "Exit"
	exit
	;;
esac

read -r -p "Did you uplaod dataset data (csv file) to S3 bucket? (y/N):" yn
case "$yn" in [yY]*) ;; *)
	echo "Exit"
	exit
	;;
esac

read -r -p "Did you deploy CloudFormation stacks of DynamoDB, Kinesis Data Steam, and S3? (y/N):" yn
case "$yn" in [yY]*) ;; *)
	echo "Exit"
	exit
	;;
esac

read -r -p "Run application indefinitely. Are you sure? (y/N):" yn
case "$yn" in [yY]*) ;; *)
	echo "Exit"
	exit
	;;
esac

# Start streaming data indefinitely
while true; do
	sam local invoke
	sleep 3 # Per second (adjust as needed)
done
