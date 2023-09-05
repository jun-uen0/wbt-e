#!/bin/bash

set -e

# Function to check if Homebrew is installed
check_homebrew() {
  if ! command -v brew &> /dev/null; then
    echo "Homebrew is not installed."
    echo "Would you like to install Homebrew? (y/N):"
    read -r install_homebrew
    if [ "$install_homebrew" == "y" ] || [ "$install_homebrew" == "Y" ]; then
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      if [ $? -eq 0 ]; then
        echo "Homebrew has been installed successfully."
      else
        echo "Failed to install Homebrew. Exiting."
        exit 1
      fi
    else
      echo "Exiting."
      exit 1
    fi
  fi
}

# Function to check if jq is installed
check_jq() {
  if ! command -v jq &> /dev/null; then
    echo "jq is not installed."
    echo "Would you like to install jq using Homebrew? (y/N):"
    read -r install_jq
    if [ "$install_jq" == "y" ] || [ "$install_jq" == "Y" ]; then
      brew install jq
      if [ $? -eq 0 ]; then
        echo "jq has been installed successfully."
      else
        echo "Failed to install jq using Homebrew. Exiting."
        exit 1
      fi
    else
      echo "Exiting."
      exit 1
    fi
  else
    echo "jq is already installed."
  fi
}

# Check Homebrew
check_homebrew

# Check jq
check_jq

echo "All checks passed."

cd $(dirname $0)
cd ../lambda

# Fetch data from DynamoDB, County = Delaware
aws dynamodb scan \
  --table-name wbt-e-dynamodb-e2e \
  --filter-expression "County = :name" \
  --expression-attribute-values '{":name":{"S":"Delaware"}}' \
  > ./tests/e2e/test-files/dynamodb_result.json

# Confirm if value of Count is valid (Count = 6)
if jq -e '.Items[0].Count.N == "6"' ./tests/e2e/test-files/dynamodb_result.json > /dev/null; then
  echo "Count matches! E2E test has been succeeded!"
else
  echo "Count does not match."
fi

# Clean
rm ./tests/e2e/test-files/dynamodb_result.json