#!/bin/sh

CONFIG_FILE="/etc/scripts/ledcontrol/ledcontrol.conf"
SETTINGS_CONFIG="ledcontrol"
MODE_STATE_FILE="/tmp/ledcontrol.mode"

if [ ! -r "$CONFIG_FILE" ]; then
        echo "ledcontrol: configuration not found; run the installer again" >&2
        exit 1
fi

# The installer writes the detected LED configuration here.
# shellcheck disable=SC1090
. "$CONFIG_FILE"

if [ -z "$LEDS" ]; then
        echo "ledcontrol: no LEDs configured" >&2
        exit 1
fi

DEFAULT_ON_HOUR=7
DEFAULT_OFF_HOUR=23
DEFAULT_AUTO_ENABLED=1

log() {
        logger -t ledcontrol "$1"
}

load_schedule() {
        on_hour=$(uci -q get "$SETTINGS_CONFIG.settings.on_hour")
        off_hour=$(uci -q get "$SETTINGS_CONFIG.settings.off_hour")
        auto_enabled=$(uci -q get "$SETTINGS_CONFIG.settings.auto_enabled")

        case "$on_hour" in
                [0-9]|1[0-9]|2[0-3]) ON_HOUR="$on_hour" ;;
                *) ON_HOUR="$DEFAULT_ON_HOUR" ;;
        esac

        case "$off_hour" in
                [0-9]|1[0-9]|2[0-3]) OFF_HOUR="$off_hour" ;;
                *) OFF_HOUR="$DEFAULT_OFF_HOUR" ;;
        esac

        case "$auto_enabled" in
                0|1) AUTO_ENABLED="$auto_enabled" ;;
                *) AUTO_ENABLED="$DEFAULT_AUTO_ENABLED" ;;
        esac
}

set_automatic_enabled() {
        uci -q set "$SETTINGS_CONFIG.settings.auto_enabled=$1" && \
                uci -q commit "$SETTINGS_CONFIG"
}

reset_defaults() {
        uci -q set "$SETTINGS_CONFIG.settings.auto_enabled=$DEFAULT_AUTO_ENABLED" && \
                uci -q set "$SETTINGS_CONFIG.settings.on_hour=$DEFAULT_ON_HOUR" && \
                uci -q set "$SETTINGS_CONFIG.settings.off_hour=$DEFAULT_OFF_HOUR" && \
                uci -q commit "$SETTINGS_CONFIG" || return 1

        ON_HOUR="$DEFAULT_ON_HOUR"
        OFF_HOUR="$DEFAULT_OFF_HOUR"
        AUTO_ENABLED="$DEFAULT_AUTO_ENABLED"
}

set_mode_state() {
        printf '%s\n' "$1" > "$MODE_STATE_FILE"
}

configured_leds() {
        for led in $LEDS; do
                if [ -r "$led/trigger" ] && [ -r "$led/brightness" ]; then
                        printf '%s\n' "$led"
                else
                        log "Skip unavailable LED: ${led##*/}"
                fi
        done
}

set_trigger() {
        led="$1"
        trigger="$2"

        if ! grep -qw "$trigger" "$led/trigger"; then
                log "${led##*/} does not support trigger: $trigger"
                return 1
        fi

        if ! echo "$trigger" > "$led/trigger" 2>/dev/null; then
                log "Unable to set ${led##*/} trigger to $trigger"
                return 1
        fi
}

set_static_on() {
        led="$1"

        if [ ! -r "$led/trigger" ] || [ ! -w "$led/brightness" ]; then
                log "Skip unavailable LED: ${led##*/}"
                return 0
        fi

        if set_trigger "$led" none; then
                max_brightness=$(cat "$led/max_brightness" 2>/dev/null || printf '%s' 255)
                if echo "$max_brightness" > "$led/brightness" 2>/dev/null; then
                        log "Restored ${led##*/}: on"
                else
                        log "Unable to restore ${led##*/} brightness"
                fi
        fi
}

turn_leds_on() {
        if [ -x /etc/init.d/led ]; then
                if /etc/init.d/led restart; then
                        log "Restored LED settings from /etc/config/system"
                else
                        log "Unable to restore LED settings from /etc/config/system"
                fi
        else
                log "Unable to restore UCI LED settings: /etc/init.d/led is unavailable"
        fi

        for led in $STATIC_ON_LEDS; do
                set_static_on "$led"
        done

        set_mode_state on
}

turn_leds_off() {
        for led in $(configured_leds); do
                current_trigger=$(cat "$led/trigger")
                current_brightness=$(cat "$led/brightness")
                changed=0

                if ! echo "$current_trigger" | grep -q "\[none\]"; then
                        if set_trigger "$led" none; then
                                changed=1
                        fi
                fi

                if [ "$current_brightness" != "0" ]; then
                        if echo 0 > "$led/brightness" 2>/dev/null; then
                                changed=1
                        else
                                log "Unable to set ${led##*/} brightness to 0"
                        fi
                fi

                if [ "$changed" -eq 1 ]; then
                        log "Set ${led##*/}: none (brightness=$(cat "$led/brightness"))"
                else
                        log "${led##*/} already off"
                fi
        done

        set_mode_state off
}

get_time_value() {
        time_value=$(date +%H | sed 's/^0*//')
        printf '%s\n' "${time_value:-0}"
}

apply_auto_mode() {
        [ "$AUTO_ENABLED" = 1 ] || return

        time_now=$(get_time_value)

        if [ "$ON_HOUR" -lt "$OFF_HOUR" ]; then
                if [ "$time_now" -ge "$ON_HOUR" ] && [ "$time_now" -lt "$OFF_HOUR" ]; then
                        requested_mode=on
                else
                        requested_mode=off
                fi
        elif [ "$ON_HOUR" -gt "$OFF_HOUR" ]; then
                if [ "$time_now" -ge "$ON_HOUR" ] || [ "$time_now" -lt "$OFF_HOUR" ]; then
                        requested_mode=on
                else
                        requested_mode=off
                fi
        else
                requested_mode=off
        fi

        current_mode=$(cat "$MODE_STATE_FILE" 2>/dev/null)
        [ "$current_mode" = "$requested_mode" ] && return

        case "$requested_mode" in
                on)
                        turn_leds_on
                        ;;
                off)
                        turn_leds_off
                        ;;
        esac
}

load_schedule

case "$1" in
        on)
                set_automatic_enabled 0
                turn_leds_on
                ;;
        off)
                set_automatic_enabled 0
                turn_leds_off
                ;;
        auto)
                apply_auto_mode
                ;;
        auto-on)
                set_automatic_enabled 1 || exit 1
                AUTO_ENABLED=1
                apply_auto_mode
                ;;
        auto-off)
                set_automatic_enabled 0 || exit 1
                ;;
        reset)
                reset_defaults || exit 1
                apply_auto_mode
                ;;
        *)
                echo "Usage: $0 {on|off|auto|auto-on|auto-off|reset}"
                exit 1
                ;;
esac
