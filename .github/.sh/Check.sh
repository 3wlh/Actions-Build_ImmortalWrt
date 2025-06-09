#!/bin/bash
# find "$(pwd)/dl" -type f
cat "$(pwd)/repositories.conf" | \
while IFS= read -r LINE; do
    [[ -z "$(echo "${LINE}" | grep -Eo "^src/gz immortalwrt_")" ]] && continue
    name=$(echo "${LINE}" | cut -d " " -f 2)
    url=$(echo "${LINE}" | cut -d " " -f 3)
    [[ -z "${name}" || -z "${url}" ]] && continue
    echo -e "检查${name}更新：" 
    echo "Downloading ${url}/Packages.gz"
    curl -# --fail "${url}/Packages.gz" -o "/tmp/Packages.gz"
    md5url=$(find "/tmp/" -type f -name "Packages.gz" 2>/dev/null -exec md5sum -b {} \; | awk '{print $1}')
    md5name=$(find "$(pwd)/dl" -type f -name "${name}" 2>/dev/null -exec md5sum -b {} \; | awk '{print $1}')
    echo "md5sum{[ md5url: ${md5url} ],[ md5name: ${md5name }]}"
    if [[ "${md5url}" == "${md5name}" ]]; then
        echo "${name} 无更新插件."
    else
        # 删除 GitHub 缓存
        echo "cache=delete" >> "$(pwd)/bin/.bashrc"
        rm -rf "$(pwd)/dl/"
        echo -e "删除所有缓存插件！" 
        break
    fi
done