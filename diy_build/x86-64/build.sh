#!/bin/bash
echo "==============================下载脚本=============================="
url="https://raw.githubusercontent.com/3wlh/Actions-Build_ImmortalWrt/refs/heads/main/.github/.sh"
curl -# --fail "${url}/Download.sh" -o "/usr/bin/Download" && chmod 755 "//usr/bin/Download"
curl -# --fail "${url}/Segmentation.sh" -o "/usr/bin/Segmentation" && chmod 755 "/usr/bin/Segmentation"
curl -# --fail "${url}/Check.sh" -o "/usr/bin/Check" && chmod 755 "/usr/bin/Check"
curl -# --fail "${url}/Replace.sh" -o "/usr/bin/Replace" && chmod 755 "/usr/bin/Replace"

find . -maxdepth 1 -type f -name "repositories.conf" -exec cp {} "$(pwd)/packages/" \;
echo "==============================下载插件=============================="
[[ -d "$(pwd)/packages/diy_packages" ]] || mkdir -p "$(pwd)/packages/diy_packages"
echo "Download_Path: $(pwd)/packages/diy_packages"
# sed -i '1a src/gz openwrt_kiddin9 https://dl.openwrt.ai/releases/24.10/packages/aarch64_generic/kiddin9' "repositories.conf"
# sed -i "s/option check_signature/# option check_signature/g" "repositories.conf"

# Segmentation "https://dl.openwrt.ai/releases/24.10/packages/x86_64/kiddin9/" \
# "luci-app-unishare unishare webdav2 luci-app-v2ray-server sunpanel luci-app-sunpanel"
Segmentation "https://op.dllkids.xyz/packages/x86_64/" \
"luci-app-unishare unishare webdav2 luci-app-v2ray-server sunpanel luci-app-sunpanel"
echo "=========================== 查看下载插件 ==========================="
ls $(pwd)/packages/diy_packages
echo "============================= 检查缓存 ============================="
if [[ -d "$(pwd)/dl" ]]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - 正在检查缓存插件："
    Check
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - 没有缓存插件."
fi
echo "============================= 镜像信息 ============================="
echo "路由器型号: $PROFILE"
echo "固件大小: $ROOTFS_PARTSIZE"
#========== 创建自定义配置文件 ==========# 
mkdir -p  /home/build/immortalwrt/files/etc/config
cat << EOF > /home/build/immortalwrt/files/etc/config/diy-settings
enable_pppoe=${ENABLE_PPPOE}
pppoe_account=${PPPOE_ACCOUNT}
pppoe_password=${PPPOE_PASSWORD}
EOF
echo "========================= 查看自定义配置 ========================="
cat /home/build/immortalwrt/files/etc/config/diy-settings
echo "================================================================="
#=============== 开始构建镜像 ===============#
echo "$(date '+%Y-%m-%d %H:%M:%S') - 开始构建镜像..."
#========== 定义所需安装的包列表 ==========#
PACKAGES=""
PACKAGES="$PACKAGES bash busybox uci luci uhttpd luci-base opkg curl openssl-util"
PACKAGES="$PACKAGES coremark ds-lite e2fsprogs htop kmod-lib-zstd"
PACKAGES="$PACKAGES lsblk nano resolveip swconfig wget-ssl zram-swap"
# USB驱动
PACKAGES="$PACKAGES kmod-usb-core kmod-usb2 kmod-usb3 kmod-usb-ohci kmod-usb-storage kmod-scsi-generic"
PACKAGES="$PACKAGES kmod-nft-offload kmod-nft-fullcone kmod-nft-nat"
# 23.05.4 luci-i18n-opkg-zh-cn
PACKAGES="$PACKAGES luci-i18n-package-manager-zh-cn"
PACKAGES="$PACKAGES luci-i18n-base-zh-cn" 
PACKAGES="$PACKAGES luci-i18n-firewall-zh-cn"
PACKAGES="$PACKAGES luci-i18n-argon-config-zh-cn"
PACKAGES="$PACKAGES luci-i18n-passwall-zh-cn"
# PACKAGES="$PACKAGES luci-app-openclash"
PACKAGES="$PACKAGES luci-i18n-homeproxy-zh-cn"
PACKAGES="$PACKAGES luci-i18n-alist-zh-cn"
PACKAGES="$PACKAGES luci-i18n-ramfree-zh-cn"
PACKAGES="$PACKAGES luci-i18n-ttyd-zh-cn"
PACKAGES="$PACKAGES luci-app-unishare"
PACKAGES="$PACKAGES luci-app-v2ray-server"
PACKAGES="$PACKAGES sunpanel luci-app-sunpanel"
# PACKAGES="$PACKAGES luci-i18n-cifs-mount-zh-cn"
# DDNS解析
PACKAGES="$PACKAGES luci-i18n-ddns-zh-cn ddns-scripts_aliyun ddns-scripts-cloudflare ddns-scripts-dnspod"
# 增加几个必备组件 方便用户安装iStore
PACKAGES="$PACKAGES fdisk"
PACKAGES="$PACKAGES script-utils"
# PACKAGES="$PACKAGES luci-i18n-samba4-zh-cn"
# 添加Docker插件
if $INCLUDE_DOCKER; then
    PACKAGES="$PACKAGES docker-compose luci-i18n-dockerman-zh-cn"
    echo "添加Package: luci-i18n-dockerman-zh-cn"
fi
#========== 删除插件包 ==========#
PACKAGES="$PACKAGES -luci-app-cpufreq"

#=============== 开始打包镜像 ===============#
echo "============================= 默认插件 ============================="
echo "$(date '+%Y-%m-%d %H:%M:%S') - 默认插件包："
echo "$(make info | grep "Default Packages:" | sed 's/Default Packages: //')"
echo "=========================== 编译添加插件 ==========================="
echo "$(date '+%Y-%m-%d %H:%M:%S') - 编译添加插件："
echo "$PACKAGES"
echo "============================ 编辑Config ============================"
Replace "CONFIG_TARGET_KERNEL_PARTSIZE" "32"
Replace "CONFIG_TARGET_ROOTFS_PARTSIZE" "${ROOTFS_PARTSIZE}"
Replace "CONFIG_TARGET_ROOTFS_EXT4FS"
Replace "CONFIG_TARGET_EXT4_JOURNAL"
Replace "CONFIG_TARGET_ROOTFS_TARGZ"
Replace "CONFIG_GRUB_IMAGES"
Replace "CONFIG_ISO_IMAGES"
Replace "CONFIG_QCOW2_IMAGES"
Replace "CONFIG_VDI_IMAGES"
Replace "CONFIG_VMDK_IMAGES"
Replace "CONFIG_VHDX_IMAGES"
cp -f "$(pwd)/.config" "$(pwd)/bin/buildinfo.config"
echo "============================= 打包镜像 ============================="
make image PROFILE=$PROFILE PACKAGES="$PACKAGES" FILES="/home/build/immortalwrt/files" ROOTFS_PARTSIZE=$ROOTFS_PARTSIZE
echo "============================= 构建结果 ============================="
if [ $? -ne 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - 打包镜像失败!"
    exit 1
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') - 打包镜像完成."