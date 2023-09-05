#!/bin/bash
env=test

set -e

cd $(dirname $0)
cd ../lambda

app_dir=hello_world

mv ${app_dir}/app.py ${app_dir}/app_bk.py
cp tests/e2e/e2e.py ${app_dir}/app.py

# Remend
rm ${app_dir}/app.py
mv ${app_dir}/app_bk.py ${app_dir}/app.py