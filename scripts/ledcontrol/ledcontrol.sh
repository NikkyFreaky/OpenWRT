#!/bin/sh

CONFIG_FILE="/etc/scripts/ledcontrol/ledcontrol.conf"

if [ ! -r "$CONFIG_FILE" ]; then
        echo "ledcontrol: configuration not found; run the installer again" >&2
        exit 1
fi

# The installer writes the LED profile for the detected router here.
# shellcheck disable=SC1090
. "$CONFIG_FILE"

if [ -z "$LEDS" ]; then
        echo "ledcontrol: no LEDs configured" >&2
        exit 1
fi

# Time format HHMM
ON_TIME=700
OFF_TIME=2300

log() {
        logger -t ledcontrol "$1"
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

led_on() {
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
}

led_off() {
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
}

get_time_value() {
        time_value=$(date +%H%M | sed 's/^0*//')
        printf '%s\n' "${time_value:-0}"
}

case "$1" in
        on)
                led_on
                ;;
        off)
                led_off
                ;;
        auto)
                time_now=$(get_time_value)

                if [ "$time_now" -ge "$ON_TIME" ] && [ "$time_now" -lt "$OFF_TIME" ]; then
                        led_on
                else
                        led_off
                fi
                ;;
        *)
                echo "Usage: $0 {on|off|auto}"
                exit 1
                ;;
esac
