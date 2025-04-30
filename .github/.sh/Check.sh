#!/bin/bash
cat "$(pwd)/repositories.conf" | \
while IFS= read -r LINE; do
    [[ -z "$(echo "${LINE}" | grep -Eo "^src/gz")" ]] && continue
    name=$(echo "${LINE}" | cut -d " " -f 2)
    url=$(echo "${LINE}" | cut -d " " -f 3)
    [[ -z "${name}" || -z "${url}" ]] && continue
    echo "Downloading ${url}/Packages.gz"
    curl -# --fail "${url}/Packages.gz" -o "/tmp/Packages.gz"
    [[ -f "/tmp/Packages.gz" && -f "$(pwd)/dl/${name}" ]] || continue
    md5url=$(md5sum -b "/tmp/Packages.gz" | awk '{print $1}')
    md5name=$(md5sum -b "$(pwd)/dl/${name}" | awk '{print $1}')
    echo "md5sum: ${md5url}  ${md5name}"
    [[ -z "${md5url}" || -z "${md5name}" ]] && continue
    if [[ "${md5url}" == "${md5name}" ]]; then
        echo "${name} 无更新插件."
    else
        # 删除 GitHub 缓存
        echo "gh cache delete cache" > "$(pwd)/bin/delete.cache"
        rm -rf "$(pwd)/dl"
        echo -e "删除所有缓存插件！" 
        break
    fi
done