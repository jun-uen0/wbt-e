#!/bin/bash

# Change current diretory to `scripts/`
cd $(dirname $0)
cd ../lambda/

# Check if SAM version is >= required_sam_version
sam_version=$(sam --version 2>&1 | awk '/SAM CLI/{print $4}')
required_sam_version="1.82.0" # Minimum version
if [ "$(printf '%s\n' "$required_sam_version" "$sam_version" | sort -V | head -n1)" != "$required_sam_version" ]; then
  echo "Error: SAM CLI version should be $required_sam_version or higher."
  exit 1
fi

# Deploy application
read -p "Do you deploy application? (y/N):" yn
case "$yn" in [yY]*) ;; *) echo "Exit" ; exit ;; esac

sam deploy --guided