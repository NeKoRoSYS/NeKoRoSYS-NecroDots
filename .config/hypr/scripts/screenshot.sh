#!/usr/bin/env bash

# Arguments: $1 = mode (output/window/region)
MODE=$1

if [ "$MODE" == "region" ]; then
    hyprshot -m region --clipboard-only --freeze -s
else
    hyprshot -m $MODE --clipboard-only -s
fi

# Send the notification
# This uses the Replace ID logic to prevent duplicates
notify-send -a "Hyprshot" \
            -h string:x-canonical-private-synchronous:shot \
            -i screenshot \
            "Hyprshot" \
            "Captured $MODE to clipboard"
