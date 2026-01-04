#!/bin/bash

# claude-rot: Open brainrot while Claude works (macOS)
# Usage: ./open-brainrot.sh [open|close]

ACTION="${1:-open}"

# URLs to open
URLS=(
    "https://www.tiktok.com/foryou"
    "https://www.instagram.com/reels/"
    "https://www.youtube.com/shorts"
    "https://x.com/"
)

# Domains to match when closing
DOMAINS=("tiktok" "instagram" "youtube" "x.com")

# Lock file to track if windows are open
LOCK_FILE="/tmp/claude-rot.lock"

# Get screen dimensions
SCREEN_WIDTH=$(osascript -e 'tell application "Finder" to get bounds of window of desktop' | cut -d',' -f3 | tr -d ' ')
SCREEN_HEIGHT=$(osascript -e 'tell application "Finder" to get bounds of window of desktop' | cut -d',' -f4 | tr -d ' ')

# Calculate column width based on number of URLs
URL_COUNT=${#URLS[@]}
COLUMN_WIDTH=$((SCREEN_WIDTH / URL_COUNT))

open_windows() {
    # Skip if windows are already open
    if [ -f "$LOCK_FILE" ]; then
        # Check if Chrome still has our windows open
        for domain in "${DOMAINS[@]}"; do
            if osascript -e "tell application \"Google Chrome\" to get URL of active tab of every window" 2>/dev/null | grep -q "$domain"; then
                # Windows still open, skip
                return
            fi
        done
        # Windows are gone, remove stale lock
        rm -f "$LOCK_FILE"
    fi

    # Create windows
    for i in "${!URLS[@]}"; do
        url="${URLS[$i]}"
        x_pos=$((COLUMN_WIDTH * i))

        osascript <<EOF
tell application "Google Chrome"
    make new window with properties {bounds:{$x_pos, 0, $((x_pos + COLUMN_WIDTH)), $SCREEN_HEIGHT}}
    set URL of active tab of front window to "$url"
    activate
end tell
EOF
    done

    # Create lock file
    touch "$LOCK_FILE"
}

close_windows() {
    # Remove lock file
    rm -f "$LOCK_FILE"

    # Close windows matching our domains
    for domain in "${DOMAINS[@]}"; do
        osascript <<EOF
tell application "Google Chrome"
    set windowList to every window
    repeat with w in windowList
        set tabList to every tab of w
        repeat with t in tabList
            if URL of t contains "$domain" then
                close w
                exit repeat
            end if
        end repeat
    end repeat
end tell
EOF
    done
}

case "$ACTION" in
    open)
        open_windows
        ;;
    close)
        close_windows
        ;;
    *)
        echo "Usage: $0 [open|close]"
        exit 1
        ;;
esac
