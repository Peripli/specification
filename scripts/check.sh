#!/bin/bash

# Copyright 2018 
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# This script will excute static ckecks on *.md and *.html files 
#
# Usage: check.sh

set -o errexit
set -o nounset
set -o pipefail

# Static check functions

# Function that checks if file is empty 
function checkIfFileIsEmpty {
    if [ ! -s $1 ]
    then
        echo [ERROR] Empty file: $1
        exit 1
    fi
}

# Locating files in the repository
REPODIR=$(dirname "${BASH_SOURCE}")/..
FULL_PATH=$( cd $REPODIR && pwd)
Files=$(find -L $FULL_PATH -type f -name "*.md" -o -name "*.htm*" | sort)

# Main loop over all files
for file in ${Files}; do
    echo [CHECKS] $file

    checkIfFileIsEmpty $file

    echo [VALID] $file

done
