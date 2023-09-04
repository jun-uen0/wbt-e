#!/bin/bash

# Change current diretory to `scripts/`
cd $(dirname $0)
cd ../lambda/

# Excute unit test
python3 -m pytest