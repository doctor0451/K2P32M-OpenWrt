#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

# Modify default IP
#sed -i 's/192.168.1.1/192.168.50.5/g' package/base-files/files/bin/config_generate

# Modify default theme
#sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# Modify hostname
#sed -i 's/OpenWrt/P3TERX-Router/g' package/base-files/files/bin/config_generate
# 修改 K2P 设备树：添加 broken-flash-reset
sed -i '/spi-max-frequency/a\\t\tbroken-flash-reset;' target/linux/ramips/dts/mt7621_phicomm_k2p.dts

# 修改 mt7621.mk：将 K2P 的 IMAGE_SIZE 改为 32M (32128k)
sed -i '/define Device\/phicomm_k2p/,/endef/ s/IMAGE_SIZE := [0-9]*k/IMAGE_SIZE := 32128k/' target/linux/ramips/mt7621/mt7621.mk

# 添加 USB 自动挂载脚本
mkdir -p package/base-files/files/etc/uci-defaults
cat > package/base-files/files/etc/uci-defaults/99-usb-automount << 'EOF'
#!/bin/sh
mkdir -p /mnt/usb
uci del_list fstab.@mount[0] >/dev/null 2>&1
uci batch <<CONF
set automount.@global[0]='global'
set automount.@global[0].enabled='1'
set automount.@global[0].timeout='3'
set automount.@global[0].mount_prefix='/mnt'
set automount.@global[0].usbfs='1'
set automount.@global[0].options='rw,sync'
set fstab.@mount[-1]='mount'
set fstab.@mount[-1].enabled='1'
set fstab.@mount[-1].device='*'
set fstab.@mount[-1].target='/mnt/usb'
set fstab.@mount[-1].fstype='auto'
set fstab.@mount[-1].options='defaults'
set fstab.@mount[-1].enabled_fsck='0'
CONF
uci commit automount
uci commit fstab
/etc/init.d/fstab enable
/etc/init.d/automount enable
exit 0
EOF
chmod +x package/base-files/files/etc/uci-defaults/99-usb-automount

# 确保内核开启 USB3 支持（你的 .config 已包含，这行是保险）
# kmod-usb3 已经在 .config 中选上了
# 以下是添加分区扩容插件（luci-app-partexp）
git clone https://github.com/sirpdboy/luci-app-partexp.git package/luci-app-partexp
# 为 A3004NS 适配 32M 闪存（如果硬改了32M）
sed -i '/define Device\/iptime_a3004ns-dual/,/endef/ s/IMAGE_SIZE := [0-9]*k/IMAGE_SIZE := 32128k/' target/linux/ramips/mt7621/mt7621.mk

# 添加 A3004NS 设备树的 broken-flash-reset（可选，防止软重启异常）
sed -i '/spi-max-frequency/a\\t\tbroken-flash-reset;' target/linux/ramips/dts/mt7621_iptime_a3004ns-dual.dts
