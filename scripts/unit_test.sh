#!/bin/bash

set -e

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

# Change current diretory to `scripts/`
cd $(dirname $0)
cd ../lambda/

# Excute unit test
python3 -m pytest