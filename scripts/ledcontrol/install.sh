#!/bin/sh

REPOSITORY="https://raw.githubusercontent.com/NikkyFreaky/OpenWRT/main/scripts/ledcontrol"
SCRIPT_DIR="/etc/scripts/ledcontrol"
CONTROL_SCRIPT="$SCRIPT_DIR/ledcontrol.sh"
CONFIG_FILE="$SCRIPT_DIR/ledcontrol.conf"
SETTINGS_FILE="/etc/config/ledcontrol"
GENERATOR_SCRIPT="/usr/libexec/ledcontrol/generate-led-config"
INIT_SCRIPT="/etc/init.d/ledcontrol"
LEGACY_SCRIPT="/etc/scripts/ledcontrol.sh"
LEGACY_PROFILE_DIR="$SCRIPT_DIR/profiles"
CRONTAB_FILE="/etc/crontabs/root"
RC_LOCAL="/etc/rc.local"
MODE_STATE_FILE="/tmp/ledcontrol.mode"
TEMP_DIR="/tmp/ledcontrol-install.$$"
CACHE_BUST="$(date +%s 2>/dev/null || printf '%s' "$$")"

msg() {
        printf '%s\n' "$*"
}

cleanup() {
        rm -rf "$TEMP_DIR"
}

download() {
        wget -q -O "$2" "$1?cachebust=$CACHE_BUST" && [ -s "$2" ]
}

remove_cron_entries() {
        [ -f "$CRONTAB_FILE" ] || return
        grep -Fv "$CONTROL_SCRIPT" "$CRONTAB_FILE" | \
                grep -Fv "$LEGACY_SCRIPT" > "$TEMP_DIR/crontab"
        mv "$TEMP_DIR/crontab" "$CRONTAB_FILE"
        [ -x /etc/init.d/cron ] && /etc/init.d/cron restart
}

install_luci() {
        [ -d /www/luci-static/resources ] || {
                msg "LuCI is not installed; skipped the web interface"
                return
        }

        mkdir -p /www/luci-static/resources/view/ledcontrol
        mkdir -p /usr/share/luci/menu.d
        mkdir -p /usr/share/rpcd/acl.d
        mkdir -p /usr/lib/lua/luci/i18n
        mv "$TEMP_DIR/overview.js" /www/luci-static/resources/view/ledcontrol/overview.js
        mv "$TEMP_DIR/luci-app-ledcontrol.json" /usr/share/luci/menu.d/luci-app-ledcontrol.json
        mv "$TEMP_DIR/luci-app-ledcontrol.acl.json" /usr/share/rpcd/acl.d/luci-app-ledcontrol.json
        mv "$TEMP_DIR/ledcontrol.ru.lmo" /usr/lib/lua/luci/i18n/ledcontrol.ru.lmo

        # LuCI caches the page tree under /tmp.  Drop every versioned cache
        # file so a newly installed menu entry is visible immediately.
        rm -f /tmp/luci-indexcache.*.json

        if [ -x /etc/init.d/rpcd ]; then
                /etc/init.d/rpcd restart
        fi

        msg "LuCI interface installed; sign out and sign in again, then refresh the page"
}

remove_startup_entries() {
        startup_line="(sleep 5 && $CONTROL_SCRIPT auto) &"
        legacy_startup_line="(sleep 5 && $LEGACY_SCRIPT auto) &"

        [ -f "$RC_LOCAL" ] || return
        grep -Fvx "$startup_line" "$RC_LOCAL" | \
                grep -Fvx "$legacy_startup_line" > "$TEMP_DIR/rc.local"
        mv "$TEMP_DIR/rc.local" "$RC_LOCAL"
}

uninstall() {
        remove_cron_entries
        remove_startup_entries

        [ -x "$INIT_SCRIPT" ] && "$INIT_SCRIPT" disable
        [ -x "$INIT_SCRIPT" ] && "$INIT_SCRIPT" stop

        if [ -x /etc/init.d/led ]; then
                /etc/init.d/led restart
        fi

        rm -f /www/luci-static/resources/view/ledcontrol/overview.js
        rm -f /usr/share/luci/menu.d/luci-app-ledcontrol.json
        rm -f /usr/share/rpcd/acl.d/luci-app-ledcontrol.json
        rm -f /usr/lib/lua/luci/i18n/ledcontrol.ru.lmo
        rm -f /tmp/luci-indexcache.*.json
        rm -f "$MODE_STATE_FILE"
        rm -f "$SETTINGS_FILE"
        rm -f "$INIT_SCRIPT"
        rm -f "$GENERATOR_SCRIPT"
        rm -f "$LEGACY_SCRIPT"
        rm -rf "$SCRIPT_DIR"

        if [ -x /etc/init.d/rpcd ]; then
                /etc/init.d/rpcd restart
        fi

        msg "ledcontrol has been removed"
}

main() {
        trap cleanup 0 INT TERM
        mkdir -p "$TEMP_DIR"

        case "$1" in
                uninstall)
                        uninstall
                        exit 0
                        ;;
                "")
                        ;;
                *)
                        msg "Usage: $0 [uninstall]"
                        exit 1
                        ;;
        esac

        download "$REPOSITORY/ledcontrol.sh" "$TEMP_DIR/ledcontrol.sh" || {
                msg "Unable to download ledcontrol.sh"
                exit 1
        }
        download "$REPOSITORY/defaults/ledcontrol" "$TEMP_DIR/ledcontrol.defaults" || {
                msg "Unable to download the default settings"
                exit 1
        }
        download "$REPOSITORY/lib/generate-led-config.sh" "$TEMP_DIR/generate-led-config" || {
                msg "Unable to download the LED detection helper"
                exit 1
        }
        download "$REPOSITORY/init.d/ledcontrol" "$TEMP_DIR/ledcontrol.init" || {
                msg "Unable to download the init service"
                exit 1
        }
        download "$REPOSITORY/luci/htdocs/luci-static/resources/view/ledcontrol/overview.js" "$TEMP_DIR/overview.js" || {
                msg "Unable to download the LuCI interface"
                exit 1
        }
        download "$REPOSITORY/luci/root/usr/share/luci/menu.d/luci-app-ledcontrol.json" "$TEMP_DIR/luci-app-ledcontrol.json" || {
                msg "Unable to download the LuCI menu"
                exit 1
        }
        download "$REPOSITORY/luci/root/usr/share/rpcd/acl.d/luci-app-ledcontrol.json" "$TEMP_DIR/luci-app-ledcontrol.acl.json" || {
                msg "Unable to download the LuCI access policy"
                exit 1
        }
        download "$REPOSITORY/luci/root/usr/lib/lua/luci/i18n/ledcontrol.ru.lmo" "$TEMP_DIR/ledcontrol.ru.lmo" || {
                msg "Unable to download the Russian LuCI translation"
                exit 1
        }
        chmod 755 "$TEMP_DIR/generate-led-config"
        "$TEMP_DIR/generate-led-config" --force "$TEMP_DIR/ledcontrol.conf" || {
                msg "No controllable LEDs found in /sys/class/leds"
                exit 1
        }
        . "$TEMP_DIR/ledcontrol.conf"
        DETECTED_LED_COUNT=0
        DETECTED_LED_NAMES=""
        DETECTED_STATIC_LED_NAMES=""
        for led in $LEDS; do
                DETECTED_LED_COUNT=$((DETECTED_LED_COUNT + 1))
                DETECTED_LED_NAMES="$DETECTED_LED_NAMES ${led##*/}"
        done
        for led in $STATIC_ON_LEDS; do
                DETECTED_STATIC_LED_NAMES="$DETECTED_STATIC_LED_NAMES ${led##*/}"
        done
        msg "Detected LEDs:${DETECTED_LED_NAMES:- none}"
        msg "Static LEDs:${DETECTED_STATIC_LED_NAMES:- none}"

        mkdir -p "$SCRIPT_DIR" /usr/libexec/ledcontrol /etc/init.d
        mv "$TEMP_DIR/ledcontrol.sh" "$CONTROL_SCRIPT"
        mv "$TEMP_DIR/ledcontrol.conf" "$CONFIG_FILE"
        mv "$TEMP_DIR/generate-led-config" "$GENERATOR_SCRIPT"
        mv "$TEMP_DIR/ledcontrol.init" "$INIT_SCRIPT"
        if [ ! -f "$SETTINGS_FILE" ]; then
                mkdir -p /etc/config
                mv "$TEMP_DIR/ledcontrol.defaults" "$SETTINGS_FILE"
        fi
        chmod 755 "$CONTROL_SCRIPT" "$GENERATOR_SCRIPT" "$INIT_SCRIPT"
        if [ -e "$LEGACY_SCRIPT" ]; then
                rm -f "$LEGACY_SCRIPT"
                msg "Removed legacy ledcontrol installation"
        fi
        if [ -d "$LEGACY_PROFILE_DIR" ]; then
                rm -rf "$LEGACY_PROFILE_DIR"
                msg "Removed legacy LED profiles"
        fi
        # Remove only LED Control's previous hooks.  New installations are
        # owned by the init service and never write to cron or rc.local.
        remove_cron_entries
        remove_startup_entries
        install_luci
        "$INIT_SCRIPT" enable
        "$INIT_SCRIPT" start
        "$CONTROL_SCRIPT" auto
        msg "ledcontrol installed for $DETECTED_LED_COUNT LED(s)"
}

main "$@"
