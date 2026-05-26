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

DTS_FILE="target/linux/ramips/dts/mt7621_phicomm_k2p.dts"
MK_FILE="target/linux/ramips/mt7621/mt7621.mk"

# ==============================================
# 1. 使用你提供的 官方原版 DTS + 32M + 软重启
# ==============================================
cat > "$DTS_FILE" << 'EOF'
/dts-v1/;

#include "mt7621.dtsi"

#include <dt-bindings/gpio/gpio.h>
#include <dt-bindings/input/input.h>
#include <dt-bindings/leds/common.h>

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

	leds {
		compatible = "gpio-leds";

		stat_r {
			function = LED_FUNCTION_STATUS;
			color = <LED_COLOR_ID_RED>;
			gpios = <&gpio 13 GPIO_ACTIVE_HIGH>;
		};

		stat_y {
			function = LED_FUNCTION_STATUS;
			color = <LED_COLOR_ID_YELLOW>;
			gpios = <&gpio 14 GPIO_ACTIVE_LOW>;
		};

		led_blue: stat_b {
			function = LED_FUNCTION_STATUS;
			color = <LED_COLOR_ID_BLUE>;
			gpios = <&gpio 15 GPIO_ACTIVE_LOW>;
		};
	};

	keys {
		compatible = "gpio-keys";

		reset {
			label = "reset";
			gpios = <&gpio 3 GPIO_ACTIVE_LOW>;
			linux,code = <KEY_RESTART>;
			debounce-interval = <60>;
		};
	};
};

&spi0 {
	status = "okay";

	flash@0 {
		compatible = "jedec,spi-nor";
		reg = <0>;
		spi-max-frequency = <50000000>;
		broken-flash-reset;  // ← ① 只加这一行，修复软重启

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
				reg = <0x50000 0x1fb0000>;  // 32M SPI
			};
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
		ieee80211-freq-limit = <2400000 2500000>;
	};
};

&pcie1 {
	wifi@0,0 {
		compatible = "mediatek,mt76";
		reg = <0x0000 0 0 0 0>;
		mediatek,mtd-eeprom = <&factory 0x8000>;
		ieee80211-freq-limit = <5000000 6000000>;
	};
};

&gmac0 {
	nvmem-cells = <&macaddr_factory_4>;
	nvmem-cell-names = "mac-address";
};

&gmac1 {
	status = "okay";
	phy-handle = <&ethphy4>;
	phy-mode = "mii";
};

&mdio {
	ethphy4: ethernet-phy@4 {
		reg = <4>;
	};
};

&switch0 {
	ports {
		port@0 {
			status = "okay";
			label = "lan1";
		};

		port@1 {
			status = "okay";
			label = "lan2";
		};

		port@2 {
			status = "okay";
			label = "lan3";
		};

		port@3 {
			status = "okay";
			label = "lan4";
		};

		port@4 {
			status = "okay";
			label = "wan";
			nvmem-cells = <&macaddr_factory_6>;
			nvmem-cell-names = "mac-address";
		};
	};
};

&state_default {
	gpio {
		groups = "i2c", "jtag";
		function = "gpio";
	};
};

&factory {
	compatible = "nvmem-cells";
	#address-cells = <1>;
	#size-cells = <1>;

	macaddr_factory_4: macaddr@4 {
		reg = <0x4 0x6>;
	};

	macaddr_factory_6: macaddr@6 {
		reg = <0x6 0x6>;
	};
};
EOF

# ==============================================
# 2. 修改 32M 固件大小（你指定的命令）
# ==============================================
sed -i '/define Device\/phicomm_k2p/,/endef/ {
    s/IMAGE_SIZE := .*/IMAGE_SIZE := 32128k/
}' "$MK_FILE"

#!/bin/bash

DTS_FILE="target/linux/ramips/dts/mt7621_phicomm_k2p.dts"
MK_FILE="target/linux/ramips/mt7621/mt7621.mk"

# ==============================================
# 1. 使用你提供的 官方原版 DTS + 32M + 软重启
# ==============================================
cat > "$DTS_FILE" << 'EOF'
/dts-v1/;

#include "mt7621.dtsi"

#include <dt-bindings/gpio/gpio.h>
#include <dt-bindings/input/input.h>
#include <dt-bindings/leds/common.h>

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

	leds {
		compatible = "gpio-leds";

		stat_r {
			function = LED_FUNCTION_STATUS;
			color = <LED_COLOR_ID_RED>;
			gpios = <&gpio 13 GPIO_ACTIVE_HIGH>;
		};

		stat_y {
			function = LED_FUNCTION_STATUS;
			color = <LED_COLOR_ID_YELLOW>;
			gpios = <&gpio 14 GPIO_ACTIVE_LOW>;
		};

		led_blue: stat_b {
			function = LED_FUNCTION_STATUS;
			color = <LED_COLOR_ID_BLUE>;
			gpios = <&gpio 15 GPIO_ACTIVE_LOW>;
		};
	};

	keys {
		compatible = "gpio-keys";

		reset {
			label = "reset";
			gpios = <&gpio 3 GPIO_ACTIVE_LOW>;
			linux,code = <KEY_RESTART>;
			debounce-interval = <60>;
		};
	};
};

&spi0 {
	status = "okay";

	flash@0 {
		compatible = "jedec,spi-nor";
		reg = <0>;
		spi-max-frequency = <50000000>;
		broken-flash-reset;  /← ① 只加这一行，修复软重启/

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
				reg = <0x50000 0x1fb0000>;  / ← ② 32M SPI/
			};
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
		ieee80211-freq-limit = <2400000 2500000>;
	};
};

&pcie1 {
	wifi@0,0 {
		compatible = "mediatek,mt76";
		reg = <0x0000 0 0 0 0>;
		mediatek,mtd-eeprom = <&factory 0x8000>;
		ieee80211-freq-limit = <5000000 6000000>;
	};
};

&gmac0 {
	nvmem-cells = <&macaddr_factory_4>;
	nvmem-cell-names = "mac-address";
};

&gmac1 {
	status = "okay";
	phy-handle = <&ethphy4>;
	phy-mode = "mii";
};

&mdio {
	ethphy4: ethernet-phy@4 {
		reg = <4>;
	};
};

&switch0 {
	ports {
		port@0 {
			status = "okay";
			label = "lan1";
		};

		port@1 {
			status = "okay";
			label = "lan2";
		};

		port@2 {
			status = "okay";
			label = "lan3";
		};

		port@3 {
			status = "okay";
			label = "lan4";
		};

		port@4 {
			status = "okay";
			label = "wan";
			nvmem-cells = <&macaddr_factory_6>;
			nvmem-cell-names = "mac-address";
		};
	};
};

&state_default {
	gpio {
		groups = "i2c", "jtag";
		function = "gpio";
	};
};

&factory {
	compatible = "nvmem-cells";
	#address-cells = <1>;
	#size-cells = <1>;

	macaddr_factory_4: macaddr@4 {
		reg = <0x4 0x6>;
	};

	macaddr_factory_6: macaddr@6 {
		reg = <0x6 0x6>;
	};
};
EOF

# ==============================================
# 2. 修改 32M 固件大小（你指定的命令）
# ==============================================
sed -i '/define Device\/phicomm_k2p/,/endef/ {
    s/IMAGE_SIZE := .*/IMAGE_SIZE := 32128k/
}' "$MK_FILE"

