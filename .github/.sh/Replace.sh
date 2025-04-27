#!/bin/bash
[[ -f "$(pwd)/.config" ]] || return
if [[ -n "${2}" ]]; then
    echo "修改：${1}"
	sed -i "s/.*${1}.*/${1}=${2}/g" "$(pwd)/.config"
else
    echo "删除：${1}"
	sed -i "s/.*${1}.*/# ${1} is not set/g" "$(pwd)/.config"
fi