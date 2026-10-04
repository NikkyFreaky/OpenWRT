#!/bin/sh

REPOSITORY="https://raw.githubusercontent.com/NikkyFreaky/OpenWRT/main/scripts/ledcontrol"
SCRIPT_DIR="/etc/scripts/ledcontrol"
CONTROL_SCRIPT="$SCRIPT_DIR/ledcontrol.sh"
CONFIG_FILE="$SCRIPT_DIR/ledcontrol.conf"
SETTINGS_FILE="/etc/config/ledcontrol"
LEGACY_SCRIPT="/etc/scripts/ledcontrol.sh"
CRONTAB_FILE="/etc/crontabs/root"
RC_LOCAL="/etc/rc.local"
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

get_model() {
        if [ -r /tmp/sysinfo/model ]; then
                cat /tmp/sysinfo/model
        elif command -v ubus >/dev/null 2>&1 && command -v jsonfilter >/dev/null 2>&1; then
                ubus call system board | jsonfilter -e '@.model'
        fi
}

select_profile() {
        case "$1" in
                *AX3000T*)
                        printf '%s\n' "ax3000t"
                        ;;
                *AX3200*|*AX6S*)
                        printf '%s\n' "ax3200-ax6s"
                        ;;
                *)
                        return 1
                        ;;
        esac
}

install_cron() {
        mkdir -p /etc/crontabs
        touch "$CRONTAB_FILE"
        grep -Fv "$CONTROL_SCRIPT" "$CRONTAB_FILE" | \
                grep -Fv "$LEGACY_SCRIPT" > "$TEMP_DIR/crontab"
        {
                cat "$TEMP_DIR/crontab"
                printf '%s\n' "*/5 * * * * $CONTROL_SCRIPT auto"
        } > "$TEMP_DIR/crontab.new"
        mv "$TEMP_DIR/crontab.new" "$CRONTAB_FILE"
        /etc/init.d/cron restart
}

install_luci() {
        [ -d /www/luci-static/resources ] || {
                msg "LuCI is not installed; skipped the web interface"
                return
        }

        mkdir -p /www/luci-static/resources/view/ledcontrol
        mkdir -p /usr/share/luci/menu.d
        mkdir -p /usr/share/rpcd/acl.d
        mv "$TEMP_DIR/overview.js" /www/luci-static/resources/view/ledcontrol/overview.js
        mv "$TEMP_DIR/luci-app-ledcontrol.json" /usr/share/luci/menu.d/luci-app-ledcontrol.json
        mv "$TEMP_DIR/luci-app-ledcontrol.acl.json" /usr/share/rpcd/acl.d/luci-app-ledcontrol.json

        # LuCI caches the page tree under /tmp.  Drop every versioned cache
        # file so a newly installed menu entry is visible immediately.
        rm -f /tmp/luci-indexcache.*.json

        if [ -x /etc/init.d/rpcd ]; then
                /etc/init.d/rpcd restart
        fi

        msg "LuCI interface installed; sign out and sign in again, then refresh the page"
}

install_startup() {
        startup_line="(sleep 5 && $CONTROL_SCRIPT auto) &"
        legacy_startup_line="(sleep 5 && $LEGACY_SCRIPT auto) &"

        if [ ! -f "$RC_LOCAL" ]; then
                printf '%s\n' '#!/bin/sh' '' 'exit 0' > "$RC_LOCAL"
        fi

        grep -Fvx "$startup_line" "$RC_LOCAL" | \
                grep -Fvx "$legacy_startup_line" > "$TEMP_DIR/rc.local"
        awk -v line="$startup_line" '
                $0 == "exit 0" && !inserted { print line; inserted = 1 }
                { print }
                END {
                        if (!inserted) {
                                print line
                                print "exit 0"
                        }
                }
        ' "$TEMP_DIR/rc.local" > "$TEMP_DIR/rc.local.new"
        mv "$TEMP_DIR/rc.local.new" "$RC_LOCAL"
        chmod +x "$RC_LOCAL"
}

main() {
        trap cleanup 0 INT TERM
        mkdir -p "$TEMP_DIR"

        model=$(get_model)
        if [ -z "$model" ]; then
                msg "Unable to determine the router model."
                exit 1
        fi
        msg "Router model: $model"

        profile=$(select_profile "$model") || {
                msg "This router is not supported by ledcontrol yet."
                msg "Detected model: $model"
                exit 1
        }

        download "$REPOSITORY/ledcontrol.sh" "$TEMP_DIR/ledcontrol.sh" || {
                msg "Unable to download ledcontrol.sh"
                exit 1
        }
        download "$REPOSITORY/profiles/$profile.conf" "$TEMP_DIR/ledcontrol.conf" || {
                msg "Unable to download the LED profile for $model"
                exit 1
        }
        download "$REPOSITORY/defaults/ledcontrol" "$TEMP_DIR/ledcontrol.defaults" || {
                msg "Unable to download the default settings"
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

        mkdir -p "$SCRIPT_DIR"
        mv "$TEMP_DIR/ledcontrol.sh" "$CONTROL_SCRIPT"
        mv "$TEMP_DIR/ledcontrol.conf" "$CONFIG_FILE"
        if [ ! -f "$SETTINGS_FILE" ]; then
                mkdir -p /etc/config
                mv "$TEMP_DIR/ledcontrol.defaults" "$SETTINGS_FILE"
        fi
        chmod 755 "$CONTROL_SCRIPT"
        if [ -e "$LEGACY_SCRIPT" ]; then
                rm -f "$LEGACY_SCRIPT"
                msg "Removed legacy ledcontrol installation"
        fi
        install_cron
        install_startup
        install_luci
        "$CONTROL_SCRIPT" auto
        msg "ledcontrol installed with profile: $profile"
}

main "$@"
