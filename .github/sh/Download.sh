#!/bin/bash
echo "Downloading ${1}"
if [[ -f "$(pwd)/packages/diy_packages/$(basename ${1})" ]]; then
    echo "######################################################################## 100.0%"
else
    find $(pwd)/packages/diy_packages/ -type f -name "$(echo "$(basename ${1})" | cut -d "_" -f 1 )*.ipk" -exec rm -f {} \;
    curl -# --fail "${1}" -o "$(pwd)/packages/diy_packages/$(basename ${1})"
    # #wget -qO "$(pwd)/packages/diy_packages/$(basename $Download_URL)" "${Download_URL}" --show-progress
fi