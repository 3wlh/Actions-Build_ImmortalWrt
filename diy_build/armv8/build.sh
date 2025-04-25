#!/bin/bash
# 添加插件
function Download(){ # 下载函数

}

function Download(){ # 下载函数
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
            echo "Downloading ${Download_URL}"
            curl -# --fail "$Download_URL" -o "$(pwd)/packages/diy_packages/$(basename $Download_URL)"
            # #wget -qO "$(pwd)/packages/diy_packages/$(basename $Download_URL)" "${Download_URL}" --show-progress
        fi
    done
done
}
echo "==============================下载插件=============================="
[[ -d "$(pwd)/packages/diy_packages" ]] || mkdir -p "$(pwd)/packages/diy_packages"
echo "Download_Path: $(pwd)/packages/diy_packages"

Download "https://dl.openwrt.ai/releases/24.10/packages/aarch64_generic/kiddin9/" \
"luci-app-unishare unishare webdav2 luci-app-v2ray-server luci-app-sunpanel sunpanel"
Packages_url="https://github.com/3wlh/Actions-Build_Package/releases/download/2024.10.25_093404/aarch64_generic_luci-i18n-cifs-mount-zh-cn_24.299.05564.9328bd0.ipk"
curl -# --fail "$Packages_url" -o "$(pwd)/packages/diy_packages/$(basename $Packages_url)"
Packages_url="https://github.com/3wlh/Actions-Build_Package/releases/download/2024.10.25_093404/aarch64_generic_luci-i18n-cifs-mount-zh-cn_24.299.05564.9328bd0.ipk"

curl -# --fail "https://github.com/3wlh/Actions-Build_Package/releases/download/2024.10.25_093404/aarch64_generic_luci-app-cifs-mount_1-12.ipk" -o "$(pwd)/packages/diy_packages/$(basename $Download_URL)"
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
PACKAGES="$PACKAGES luci uhttpd curl openssl-util"
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
PACKAGES="$PACKAGES luci-app-sunpanel"
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

# 构建结果
echo "==============================构建结果=============================="
if [ $? -ne 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: Build failed!"
    exit 1
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') - Build completed successfully."
