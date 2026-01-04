#!/bin/bash

# claude-rot: Open brainrot while Claude works (macOS)
# Usage: ./open-brainrot.sh [open|close]

ACTION="${1:-open}"

# URLs to open
URLS=(
    "https://www.tiktok.com"
    "https://www.instagram.com/reels"
    "https://www.youtube.com/shorts"
    "https://www.x.com"
)

# Get screen dimensions
SCREEN_WIDTH=$(osascript -e 'tell application "Finder" to get bounds of window of desktop' | cut -d',' -f3 | xargs)
SCREEN_HEIGHT=$(osascript -e 'tell application "Finder" to get bounds of window of desktop' | cut -d',' -f4 | xargs)

# Calculate window size (4 quarters)
HALF_WIDTH=$((SCREEN_WIDTH / 2))
HALF_HEIGHT=$((SCREEN_HEIGHT / 2))

# Window positions: [x, y] for each quadrant
POSITIONS=(
    "0,0"                           # Top-left
    "$HALF_WIDTH,0"                 # Top-right
    "0,$HALF_HEIGHT"                # Bottom-left
    "$HALF_WIDTH,$HALF_HEIGHT"      # Bottom-right
)

open_windows() {
    for i in "${!URLS[@]}"; do
        URL="${URLS[$i]}"
        POS="${POSITIONS[$i]}"
        X=$(echo "$POS" | cut -d',' -f1)
        Y=$(echo "$POS" | cut -d',' -f2)

        osascript <<EOF
tell application "Google Chrome"
    activate
    set newWindow to make new window
    set URL of active tab of newWindow to "$URL"
    set bounds of newWindow to {$X, $Y, $((X + HALF_WIDTH)), $((Y + HALF_HEIGHT))}
end tell
EOF
    done
}

close_windows() {
    for URL in "${URLS[@]}"; do
        # Extract domain for matching
        DOMAIN=$(echo "$URL" | sed 's|https://www\.||' | sed 's|/.*||')

        osascript <<EOF
tell application "Google Chrome"
    set windowList to every window
    repeat with w in windowList
        set tabList to every tab of w
        repeat with t in tabList
            if URL of t contains "$DOMAIN" then
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
