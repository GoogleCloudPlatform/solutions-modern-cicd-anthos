#!/bin/bash

# Fail on any error.
set -e
# Display commands being run.
set -x

docker build -t anthos-platform-setup .

echo "All passed"
