#!/bin/sh

LED_STATUS='/sys/class/leds/blue:status/trigger'

case "$1" in
    on)
        echo "default-on" > $LED_STATUS"
        ;;
    off)
        echo "none" > $LED_STATUS"
        ;;
    *)
        echo "Usage: $0 {on|off}"
        exit 1
        ;;
esac
