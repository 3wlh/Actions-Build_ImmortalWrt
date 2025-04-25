#!/bin/bash
# 添加首次启动时运行的脚本
[[ -d "files/etc/uci-defaults" ]] || mkdir -p "files/etc/uci-defaults"
find "files" -type f -name "*.sh"  -exec mv {} "files/etc/uci-defaults/" \;

# 添加插件
function Download(){ # 下载函数
echo "Downloading ${1}"
curl -# --fail "${1}" -o "$(pwd)/packages/diy_packages/$(basename ${1})"
# #wget -qO "$(pwd)/packages/diy_packages/$(basename $Download_URL)" "${Download_URL}" --show-progress
}

function Segmentation(){ # 分割下载函数
[[ -d "$(pwd)/packages/diy_packages" ]] || mkdir -p "$(pwd)/packages/diy_packages"
echo "Download_Path: $(pwd)/packages/diy_packages"
PACKAGES_URL="${1}"
PACKAGES_NAME=(${2})
wget -qO- "${PACKAGES_URL}" | \
while IFS= read -r LINE; do
    for PREFIX in "${PACKAGES_NAME[@]}"; do
        if [[ "$LINE" == *"$PREFIX"* ]]; then
            FILE=$(echo "$LINE" | grep -Eo 'href="[^"]*' | sed 's/href="//')
            if [[ -z "$FILE" ]]; then
                # echo "No file found in line, skipping"
                continue
            fi
            Download_URL="${PACKAGES_URL}${FILE}"
            Download "${Download_URL}"
            curl -# --fail "$Download_URL" -o "$(pwd)/packages/diy_packages/$(basename $Download_URL)"
        fi
    done
done
}
echo "==============================下载插件=============================="
[[ -d "$(pwd)/packages/diy_packages" ]] || mkdir -p "$(pwd)/packages/diy_packages"
echo "Download_Path: $(pwd)/packages/diy_packages"
#Segmentation "https://dl.openwrt.ai/releases/24.10/packages/aarch64_generic/kiddin9/" \
#"luci-app-unishare unishare webdav2 luci-app-v2ray-server"
#Download "https://github.com/3wlh/Actions-Build_Package/releases/download/2025.04.25_173458/luci-app-cifs-mount_1-r12_aarch64_generic.ipk"
#Download "https://github.com/3wlh/Actions-Build_Package/releases/download/2025.04.25_173458/luci-i18n-cifs-mount-zh-cn_25.115.34439.90c7318_aarch64_generic.ipk"
#Download "https://github.com/3wlh/Actions-Build_Package/releases/download/2025.04.25_193659/luci-app-sunpanel_25.115.34439.90c7318_aarch64_generic.ipk"
#Download "https://github.com/3wlh/Actions-Build_Package/releases/download/2025.04.25_193659/luci-i18n-sunpanel-zh-cn_25.115.34439.90c7318_aarch64_generic.ipk"
#Download "https://github.com/3wlh/Actions-Build_Package/releases/download/2025.04.25_205106/sunpanel_1.3.1-r5_aarch64_generic_aarch64_generic.ipk"
sed -i '1a src/gz openwrt_kiddin9 https://dl.openwrt.ai/releases/24.10/packages/aarch64_generic/kiddin9' "repositories.conf"
sed -i "s/option check_signature/# option check_signature/g" "repositories.conf"


echo "=========================== 查看下载插件 ==========================="
ls $(pwd)/packages/diy_packages
echo "==============================镜像信息=============================="
echo "路由器型号: $PROFILE"
echo "固件大小: $ROOTFS_PARTSIZE"

# 创建自定义配置文件
mkdir -p  /home/build/immortalwrt/files/etc/config
cat << EOF > /home/build/immortalwrt/files/etc/config/diy-settings
enable_pppoe=${ENABLE_PPPOE}
pppoe_account=${PPPOE_ACCOUNT}
pppoe_password=${PPPOE_PASSWORD}
EOF
echo "==========================查看自定义配置=========================="
cat /home/build/immortalwrt/files/etc/config/diy-settings
echo "================================================================="
# 输出调试信息
echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting build process..."
# 定义所需安装的包列表
PACKAGES=""
PACKAGES="$PACKAGES bash uci luci uhttpd curl openssl-util"
# USB驱动
PACKAGES="$PACKAGES kmod-usb-core kmod-usb2 kmod-usb3 kmod-usb-ohci kmod-usb-storage kmod-scsi-generic"
PACKAGES="$PACKAGES kmod-nft-offload kmod-nft-fullcone kmod-nft-nat"
PACKAGES="$PACKAGES luci-i18n-package-manager-zh-cn"
PACKAGES="$PACKAGES luci-i18n-firewall-zh-cn"
PACKAGES="$PACKAGES luci-app-argon-config"
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
PACKAGES="$PACKAGES luci-i18n-cifs-mount-zh-cn"
# DDNS解析
PACKAGES="$PACKAGES luci-i18n-ddns-zh-cn ddns-scripts_aliyun ddns-scripts-cloudflare ddns-scripts-dnspod"
# 增加几个必备组件 方便用户安装iStore
PACKAGES="$PACKAGES fdisk"
PACKAGES="$PACKAGES script-utils"
# PACKAGES="$PACKAGES luci-i18n-samba4-zh-cn"
# 添加Docker插件
if $INCLUDE_DOCKER; then
    PACKAGES="$PACKAGES luci-i18n-dockerman-zh-cn"
    echo "ADD package: luci-i18n-dockerman-zh-cn"
fi
 
# 构建镜像
echo "==============================默认插件=============================="
echo "$(date '+%Y-%m-%d %H:%M:%S') - Default Packages："
echo "$(make info | grep "Default Packages:" | sed 's/Default Packages: //')"
echo "==============================添加插件=============================="
echo "$(date '+%Y-%m-%d %H:%M:%S') - Building image with the following packages:"
echo "$PACKAGES"
echo "==============================打包image=============================="
make image PROFILE=$PROFILE PACKAGES="$PACKAGES" FILES="/home/build/immortalwrt/files" ROOTFS_PARTSIZE=$ROOTFS_PARTSIZE

echo "=========================== 查看目录 ==========================="
ls $(pwd)/packages

# 构建结果
echo "==============================构建结果=============================="
if [ $? -ne 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: Build failed!"
    exit 1
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') - Build completed successfully."
