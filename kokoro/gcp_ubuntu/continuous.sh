#!/bin/bash

# Fail on any error.
set -e
# Display commands being run.
set -x

# Code under repo is checked out to ${KOKORO_ARTIFACTS_DIR}/git.
# The final directory name in this path is determined by the scm name specified
# in the job configuration.
cd ${KOKORO_ARTIFACTS_DIR}/git/anthos-platform-setup
./tests/setup_teardown.sh
