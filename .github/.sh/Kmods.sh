#!/bin/bash
Kernel=$(find "$(pwd)/build_dir/" -type f -name "kernel_*.ipk" 2>/dev/null)
[[ -z "${Kernel}" ]] && Kernel=$(find "$(pwd)/build_dir/" -type f -name "kernel_*.apk" 2>/dev/null)
[[ -n "${Kernel}" ]] && echo "$(date '+%Y-%m-%d %H:%M:%S') - Kernel版本：$(basename ${Kernel})"
cat "$(pwd)/repositories.conf" | \
while IFS= read -r LINE; do
    [[ -z "$(echo "${LINE}" | grep -Eo "^src/gz .*kmods")" ]] && continue
    url=$(echo "${LINE}" | cut -d " " -f 3)
    [[ -z "${url}" ]] && continue
	kmods_url="${url%/*}"
	kmods_version="${url##*/}"
	echo "$(date '+%Y-%m-%d %H:%M:%S') - kmods版本：${kmods_version}"
	[[ -n "${1}" ]] && sed -i "s/${url}/${1}/" "$(pwd)/repositories.conf"
	# wget -qO- "${kmods_url}" | \
	# while IFS= read -r line; do
    	# if [[ "$line" == *"${1}"* ]]; then
			# FILE=$(echo "$line" | grep -Eo 'href="[^"]*' | sed 's/href="//' | tr -d "/")
			# if [[ -n "$line" ]]; then
				# sed -i "s/${kmods_version}/${FILE}/" "$(pwd)/repositories.conf"
				# echo "$(date '+%Y-%m-%d %H:%M:%S') - 修改kmods版本：${FILE}"
			# fi
		# fi
	# done
done