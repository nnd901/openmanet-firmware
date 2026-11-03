include $(TOPDIR)/rules.mk

PKG_NAME:=openmanet-usb-otg
PKG_RELEASE:=6
PKG_VERSION:=1.0

PKG_LICENSE:=GPL-2.0-only
PKG_MAINTAINER:=OpenMANET

include $(INCLUDE_DIR)/package.mk

define Package/openmanet-usb-otg
  SECTION:=net
  CATEGORY:=OpenMANET
  SUBMENU:=Network
  TITLE:=Raspberry Pi USB OTG LAN sharing
  DEPENDS:=@USB_GADGET_SUPPORT +usbgadget +usbgadget-rndis +usbgadget-rndis-ecm \
	+usbgadget-ncm +kmod-usb-dwc2 +kmod-usb-gadget-eth +kmod-usb-gadget-ncm \
	+kmod-fs-configfs
endef

define Package/openmanet-usb-otg/description
  Enable the Pi USB device controller as an RNDIS Ethernet gadget (NCM and
  RNDIS+ECM selectable) and share the device LAN with a connected USB host
  (default: bridge gadget ports into br-ahwlan or br-lan).
endef

define Package/openmanet-usb-otg/conffiles
/etc/config/openmanet_usb_otg
endef

define Build/Compile
endef

define Package/openmanet-usb-otg/install
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_CONF) ./files/openmanet_usb_otg.config $(1)/etc/config/openmanet_usb_otg

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/openmanet-usb-otg.init $(1)/etc/init.d/openmanet-usb-otg

	$(INSTALL_DIR) $(1)/etc/uci-defaults
	$(INSTALL_BIN) ./files/uci-defaults/40_openmanet_usb_otg $(1)/etc/uci-defaults/40_openmanet_usb_otg

	$(INSTALL_DIR) $(1)/etc/hotplug.d/net
	$(INSTALL_DATA) ./files/hotplug.d/net/40-openmanet-usb-otg $(1)/etc/hotplug.d/net/40-openmanet-usb-otg

	$(INSTALL_DIR) $(1)/lib/openmanet
	$(INSTALL_DATA) ./files/lib/openmanet-usb-otg.sh $(1)/lib/openmanet/usb-otg.sh
endef

$(eval $(call BuildPackage,openmanet-usb-otg))
