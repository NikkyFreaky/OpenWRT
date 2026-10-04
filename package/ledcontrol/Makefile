include $(TOPDIR)/rules.mk

PKG_NAME:=ledcontrol
PKG_VERSION:=1.0.0
PKG_RELEASE:=1
PKG_LICENSE:=MIT
PKG_MAINTAINER:=NikkyFreaky
PKGARCH:=all

# The package is intentionally source-only.  Keeping the runtime scripts in
# scripts/ledcontrol also lets the standalone installer use the same sources.
LEDCONTROL_DIR:=$(dir $(lastword $(MAKEFILE_LIST)))
LEDCONTROL_SOURCE_DIR:=$(LEDCONTROL_DIR)/../../scripts/ledcontrol

include $(INCLUDE_DIR)/package.mk

define Package/ledcontrol
  SECTION:=utils
  CATEGORY:=Utilities
  TITLE:=Scheduled LED control service
  DEPENDS:=+uci
endef

define Package/ledcontrol/description
 Turns router LEDs on or off according to a UCI-configured daily schedule.
 The package detects controllable LEDs on first installation and runs as a
 procd-managed service.
endef

define Package/ledcontrol/conffiles
/etc/config/ledcontrol
endef

define Package/ledcontrol/install
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/etc/scripts/ledcontrol
	$(INSTALL_DIR) $(1)/usr/libexec/ledcontrol
	$(INSTALL_BIN) $(LEDCONTROL_SOURCE_DIR)/ledcontrol.sh $(1)/etc/scripts/ledcontrol/ledcontrol.sh
	$(INSTALL_BIN) $(LEDCONTROL_SOURCE_DIR)/lib/generate-led-config.sh $(1)/usr/libexec/ledcontrol/generate-led-config
	$(INSTALL_BIN) $(LEDCONTROL_SOURCE_DIR)/init.d/ledcontrol $(1)/etc/init.d/ledcontrol
	$(INSTALL_BIN) $(LEDCONTROL_DIR)/files/migrate-legacy $(1)/usr/libexec/ledcontrol/migrate-legacy
	$(INSTALL_CONF) $(LEDCONTROL_SOURCE_DIR)/defaults/ledcontrol $(1)/etc/config/ledcontrol
endef

define Package/ledcontrol/postinst
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] && exit 0

/usr/libexec/ledcontrol/migrate-legacy
if /usr/libexec/ledcontrol/generate-led-config /etc/scripts/ledcontrol/ledcontrol.conf; then
	/etc/scripts/ledcontrol/ledcontrol.sh auto
	/etc/init.d/ledcontrol enable
	/etc/init.d/ledcontrol start
else
	logger -t ledcontrol 'No controllable LEDs found; service was not enabled'
fi

exit 0
endef

define Package/ledcontrol/prerm
#!/bin/sh
[ -n "$${IPKG_INSTROOT}" ] && exit 0

/etc/init.d/ledcontrol stop
/etc/init.d/ledcontrol disable
[ -x /etc/init.d/led ] && /etc/init.d/led restart

exit 0
endef

define Package/luci-app-ledcontrol
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=3. Applications
  TITLE:=LuCI support for LED Control
  DEPENDS:=+ledcontrol +luci-base +rpcd-mod-file
  PKGARCH:=all
endef

define Package/luci-app-ledcontrol/description
 LuCI page for configuring and controlling the LED Control service.
endef

define Package/luci-app-ledcontrol/install
	$(INSTALL_DIR) $(1)/usr/share/luci/menu.d
	$(INSTALL_DIR) $(1)/usr/share/rpcd/acl.d
	$(INSTALL_DIR) $(1)/www/luci-static/resources/view/ledcontrol
	$(INSTALL_DATA) $(LEDCONTROL_SOURCE_DIR)/luci/root/usr/share/luci/menu.d/luci-app-ledcontrol.json $(1)/usr/share/luci/menu.d/luci-app-ledcontrol.json
	$(INSTALL_DATA) $(LEDCONTROL_SOURCE_DIR)/luci/root/usr/share/rpcd/acl.d/luci-app-ledcontrol.json $(1)/usr/share/rpcd/acl.d/luci-app-ledcontrol.json
	$(INSTALL_DATA) $(LEDCONTROL_SOURCE_DIR)/luci/htdocs/luci-static/resources/view/ledcontrol/overview.js $(1)/www/luci-static/resources/view/ledcontrol/overview.js
endef

define Package/luci-i18n-ledcontrol-ru
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=4. Translations
  TITLE:=Russian translations for LuCI LED Control
  DEPENDS:=+luci-app-ledcontrol
  PKGARCH:=all
endef

define Package/luci-i18n-ledcontrol-ru/description
 Russian LuCI translation for LED Control.
endef

define Package/luci-i18n-ledcontrol-ru/install
	$(INSTALL_DIR) $(1)/usr/lib/lua/luci/i18n
	$(INSTALL_DATA) $(LEDCONTROL_SOURCE_DIR)/luci/root/usr/lib/lua/luci/i18n/ledcontrol.ru.lmo $(1)/usr/lib/lua/luci/i18n/ledcontrol.ru.lmo
endef

$(eval $(call BuildPackage,ledcontrol))
$(eval $(call BuildPackage,luci-app-ledcontrol))
$(eval $(call BuildPackage,luci-i18n-ledcontrol-ru))
