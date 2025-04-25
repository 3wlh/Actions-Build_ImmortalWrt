#!/bin/sh
# immortalwrt固件首次启动时运行的脚本 /etc/uci-defaults/99-custom.sh
# 输出日志文件
LOGFILE="/tmp/uci-defaults-log.txt"
echo "Starting 99-custom.sh at $(date '+%Y-%m-%d %H:%M:%S')" >> $LOGFILE

# 检查配置文件diy-settings是否存在
SETTINGS_FILE="/etc/config/diy-settings"
if [ ! -f "$SETTINGS_FILE" ]; then
    echo "settings file not found. Skipping." >> $LOGFILE
else
   # 读取pppoe信息($enable_pppoe、$pppoe_account、$pppoe_password)
   . "$SETTINGS_FILE"
fi

#========System========
# 更改名称
Count=$(cat /tmp/sysinfo/model | grep -o ' ' | wc -l)
[[ Count -ge 4 ]] && Model=$(cat /tmp/sysinfo/model | awk '{print $(NF-1), $NF}')
[[ -z "${Model}" ]] && Model=$(cat /tmp/sysinfo/model | awk '{print $NF}')
uci set system.@system[0].hostname="${Model}"
uci commit system

# 设置编译作者信息
FILE_PATH="/etc/openwrt_release"
NEW_DESCRIPTION="Compiled by 3wlh"
sed -i "s/DISTRIB_DESCRIPTION='[^']*'/DISTRIB_DESCRIPTION='$NEW_DESCRIPTION'/" "$FILE_PATH"
# 删除配置文件
rm -f "${SETTINGS_FILE}"
exit 0
