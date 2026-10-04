#!/bin/sh

REPOSITORY="https://raw.githubusercontent.com/NikkyFreaky/OpenWRT/refs/heads/main/scripts/ledcontrol"
SCRIPT_DIR="/etc/scripts/ledcontrol"
CONTROL_SCRIPT="$SCRIPT_DIR/ledcontrol.sh"
CONFIG_FILE="$SCRIPT_DIR/ledcontrol.conf"
LEGACY_SCRIPT="/etc/scripts/ledcontrol.sh"
CRONTAB_FILE="/etc/crontabs/root"
RC_LOCAL="/etc/rc.local"
TEMP_DIR="/tmp/ledcontrol-install.$$"

msg() {
        printf '%s\n' "$*"
}

cleanup() {
        rm -rf "$TEMP_DIR"
}

download() {
        wget -q -O "$2" "$1" && [ -s "$2" ]
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
                printf '%s\n' "0 7 * * * $CONTROL_SCRIPT on"
                printf '%s\n' "0 23 * * * $CONTROL_SCRIPT off"
                printf '%s\n' "*/30 * * * * $CONTROL_SCRIPT auto"
        } > "$TEMP_DIR/crontab.new"
        mv "$TEMP_DIR/crontab.new" "$CRONTAB_FILE"
        /etc/init.d/cron restart
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

        mkdir -p "$SCRIPT_DIR"
        mv "$TEMP_DIR/ledcontrol.sh" "$CONTROL_SCRIPT"
        mv "$TEMP_DIR/ledcontrol.conf" "$CONFIG_FILE"
        chmod 755 "$CONTROL_SCRIPT"
        if [ -e "$LEGACY_SCRIPT" ]; then
                rm -f "$LEGACY_SCRIPT"
                msg "Removed legacy ledcontrol installation"
        fi
        install_cron
        install_startup
        "$CONTROL_SCRIPT" auto
        msg "ledcontrol installed with profile: $profile"
}

main "$@"
