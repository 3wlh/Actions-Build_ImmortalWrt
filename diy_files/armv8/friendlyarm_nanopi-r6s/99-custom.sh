#!/bin/sh
# immortalwrt固件首次启动时运行的脚本 /etc/uci-defaults/99-custom.sh
# 输出日志文件
LOGFILE="/tmp/uci-defaults-log.txt"
echo "Starting 99-custom.sh at $(date '+%Y-%m-%d %H:%M:%S')" >> $LOGFILE

# 检查配置文件diy-settings是否存在
SETTINGS_FILE="/etc/config/diy-settings"
if [ -f "$SETTINGS_FILE" ]; then
   # 读取diy-settings信息
   . "$SETTINGS_FILE"
fi

#====================设置LAN口IP====================
if [ -n "${settings_lan}" ]; then
uci set network.lan.ipaddr="${settings_lan}"
fi
uci commit network

#==========================Dropbear==========================
# 设置所有网口可连接 SSH
# uci set dropbear.@dropbear[0].Interface=''
# uci commit dropbear

#==========================Fstab==========================
# 自动挂载未配置的Swap
uci set fstab.@global[0].anon_swap="0"
# 自动挂载未配置的磁盘
uci set fstab.@global[0].anon_mount="0"
# 自动挂载交换分区
uci set fstab.@global[0].auto_swap="0"
# 自动挂载磁盘
uci set fstab.@global[0].auto_mount="1"
uci commit fstab

#==========================TTYD==========================
[[ -f "/etc/config/ttyd" ]] && uci delete ttyd.@ttyd[0].interface
uci commit ttyd

#==========================ARGON==========================
if [ ! -n "$(uci -q get argon.@global[])" ]; then
	echo "" > "/etc/config/argon"
	uci add argon global
	uci commit argon
fi
uci set argon.@global[0].online_wallpaper="none"
uci set argon.@global[0].mode="light"
uci set argon.@global[0].bing_background="0"
uci set argon.@global[0].primary="#5e72e4"
uci set argon.@global[0].dark_primary="#483d8b"
uci set argon.@global[0].blur="1"
uci set argon.@global[0].blur_dark="1"
uci set argon.@global[0].transparency="0.2"
uci set argon.@global[0].transparency_dark="0.2"
uci commit argon

#==========================DHCP==========================
# 强制此接口DHCP
uci set dhcp.lan.force='1'
# 删除 DNS重定向
uci -q delete dhcp.@dnsmasq[0].dns_redirect
# 禁用 ipv6 DHCP
# DHCPv6 服务
uci -q delete dhcp.lan.dhcpv6
# RA 服务
uci -q delete dhcp.lan.ra
# NDP 代理
uci -q delete dhcp.lan.ndp
# 禁用 ipv6 解析
# uci set dhcp.@dnsmasq[0].filter_aaaa="1"
uci commit dhcp

#==========================Firewall==========================
# 默认设置WAN口防火墙打开
uci set firewall.@zone[1].input='ACCEPT'
uci commit firewall

#==========================Network==========================
# 读取固件信息
. "/etc/openwrt_release"
# 更改 eth1 为 WAN 口
if [[ "${DISTRIB_ID}" == "ImmortalWrt" ]]; then
# 更改 eth1 为 WAN 口
uci del_list network.@device[0].ports="eth2"
uci add_list network.@device[0].ports="eth1"
uci set network.wan.device="eth2"
else
# 更改 eth2 为 WAN 口
uci del_list network.@device[0].ports="eth1"
uci add_list network.@device[0].ports="eth2"
uci set network.wan.device="eth1"
fi
# 删除 WAN6 口
uci -q delete network.wan6
# 设置拨号协议
if $enable_pppoe; then
	uci set network.wan.proto="pppoe"
	echo "PPPoE_Protocol configuration completed successfully." >> $LOGFILE
fi
if [ -n "${pppoe_account}" ]; then
   uci set network.wan.username=$pppoe_account
   echo "PPPoE_Account configuration completed successfully." >> $LOGFILE
fi
if [ -n "${pppoe_password}" ]; then
   uci set network.wan.password=$pppoe_password
   echo "PPPoE_Password configuration completed successfully." >> $LOGFILE
fi
uci commit network

#==========================System==========================
# echo ledtrig-netdev > /etc/modules.d/led-for-r6s && ln -s /etc/modules.d/led-for-r6s /etc/modules-boot.d/led-for-r6s && modprobe ledtrig-netdev
# 网口 LED 循序
# WAN LED
uci set system.led_wan.dev="pppoe-wan"
# LAN1 LED
uci set system.led_lan1.dev="eth1"
# LAN2 LED
uci set system.led_lan2.dev="eth0"
# 更改网口闪烁方式
uci set system.led_wan.mode="link"
uci set system.led_lan1.mode="link"
uci set system.led_lan2.mode="link"
# 关闭系统 SYS_led
RED_LED=$(find "/sys/class/leds/" -type l -name "*red*" | sed "s|.*/||g")
if [ -n "${RED_LED}" ]; then
	uci set system.led_red="led"
	uci set system.led_red.name="SYS"
	uci set system.led_red.sysfs="${RED_LED}"
	uci set system.led_red.trigger="none"
	uci set system.led_red.default="0"
fi
# 更改名称
Count=$(cat /tmp/sysinfo/model | grep -o ' ' | wc -l)
[[ $Count -ge 4 ]] && Model=$(cat /tmp/sysinfo/model | awk '{print $(NF-1), $NF}')
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