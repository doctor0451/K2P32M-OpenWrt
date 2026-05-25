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






#以下   是我的代码

#!/bin/bash
# ==============================
# K2P 硬改最终版
# 32M闪存 + USB + 软重启
# DTS 使用 cat 一次性写入
# 无多余脚本、原生自动挂载
# ==============================

DTS_FILE="target/linux/ramips/dts/mt7621_phicomm_k2p.dts"
MK_FILE="target/linux/ramips/mt7621/mt7621.mk"

# ==============================================================================
# 1. 一次性重写 DTS：基于你提供的原版 + 32M闪存 + 软重启 (无USB3、无u3phy)
# ==============================================================================
cat > "$DTS_FILE" << 'EOF'
#include "mt7621.dtsi"

#include <dt-bindings/gpio/gpio.h>
#include <dt-bindings/input/input.h>

/ {
	compatible = "phicomm,k2p", "mediatek,mt7621-soc";
	model = "Phicomm K2P";

	aliases {
		led-boot = &led_blue;
		led-failsafe = &led_blue;
		led-running = &led_blue;
		led-upgrade = &led_blue;
		label-mac-device = &gmac0;
	};

	keys {
		compatible = "gpio-keys";

		reset {
			label = "reset";
			gpios = <&gpio 3 GPIO_ACTIVE_LOW>;
			linux,code = <KEY_RESTART>;
		};
	};

	leds {
		compatible = "gpio-leds";

		led_blue: blue {
			label = "blue:power";
			gpios = <&gpio 12 GPIO_ACTIVE_LOW>;
		};

		yellow {
			label = "yellow:phone";
			gpios = <&gpio 14 GPIO_ACTIVE_LOW>;
		};
	};
};

&spi0 {
	status = "okay";

	flash@0 {
		compatible = "jedec,spi-nor";
		reg = <0>;
		spi-max-frequency = <10000000>;
		broken-flash-reset;

		partitions {
			compatible = "fixed-partitions";
			#address-cells = <1>;
			#size-cells = <1>;

			partition@0 {
				label = "u-boot";
				reg = <0x0 0x30000>;
				read-only;
			};

			partition@30000 {
				label = "u-boot-env";
				reg = <0x30000 0x10000>;
				read-only;
			};

			factory: partition@40000 {
				label = "factory";
				reg = <0x40000 0x10000>;
				read-only;
			};

			partition@50000 {
				compatible = "denx,uimage";
				label = "firmware";
				reg = <0x50000 0x1fb0000>;
			};
		};
	};
};

&gmac0 {
	nvmem-cells = <&macaddr_factory_4>;
	nvmem-cell-names = "mac-address";
};

&gmac1 {
	status = "okay";
	phy-handle = <&ethphy0>;
	phy-mode = "rgmii";

	nvmem-cells = <&macaddr_factory_2>;
	nvmem-cell-names = "mac-address";
};

&mdio {
	ethphy0: ethernet-phy@0 {
		reg = <0>;
	};
};

&switch0 {
	ports {
		port@1 {
			status = "okay";
			label = "lan1";
		};

		port@2 {
			status = "okay";
			label = "lan2";
		};

		port@3 {
			status = "okay";
			label = "lan3";
		};

		port@4 {
			status = "okay";
			label = "wan";
			nvmem-cells = <&macaddr_factory_0>;
			nvmem-cell-names = "mac-address";
		};
	};
};

&pcie {
	status = "okay";
};

&pcie0 {
	wifi@0,0 {
		compatible = "mediatek,mt76";
		reg = <0x0000 0 0 0 0>;
		mediatek,mtd-eeprom = <&factory 0x0000>;
		ieee80211-freq-limit = <5000000 6000000>;
	};
};

&pcie1 {
	wifi@0,0 {
		compatible = "mediatek,mt76";
		reg = <0x0000 0 0 0 0>;
		mediatek,mtd-eeprom = <&factory 0x8000>;
		ieee80211-freq-limit = <2400000 2500000>;
	};
};

&factory {
	compatible = "nvmem-cells";
	#address-cells = <1>;
	#size-cells = <1>;

	macaddr_factory_0: macaddr@0 {
		reg = <0x0 0x6>;
	};

	macaddr_factory_2: macaddr@2 {
		reg = <0x2 0x6>;
	};

	macaddr_factory_4: macaddr@4 {
		reg = <0x4 0x6>;
	};
};
EOF

# ==============================================================================
# 2. 修改 mt7621.mk：IMAGE_SIZE 改为 32768k (按你指定命令)
# ==============================================================================
sed -i '/define Device\/phicomm_k2p/,/endef/ {
    s/IMAGE_SIZE := .*/IMAGE_SIZE := 32768k/
}' "$MK_FILE"

# ==============================================================================
# 3. 安装分区扩容工具
# ==============================================================================
git clone https://github.com/sirpdboy/luci-app-partexp.git package/luci-app-partexp

# ==============================================================================
# 4. 清理 USB3 相关驱动，防止编译报错
# ==============================================================================
sed -i '/kmod-usb3/d' .config
sed -i '/kmod-usb-xhci/d' .config
sed -i '/kmod-usb-xhci-mtk/d' .config


