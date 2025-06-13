#!/bin/bash
cat "$(pwd)/repositories.conf" | \
while IFS= read -r LINE; do
    [[ -n "$(echo "${LINE}" | grep -Eo "^src/gz .*kmods")" ]] && continue
    [[ -z "$(echo "${LINE}" | grep -Eo "^src/gz")" ]] && continue
    name=$(echo "${LINE}" | cut -d " " -f 2)
    [[ -z "${name}" ]] && continue
	sed -i "s|${name}.*downloads..*.org|${name} https://${1}|" "$(pwd)/repositories.conf"
done