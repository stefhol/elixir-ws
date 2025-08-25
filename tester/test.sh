#!/bin/bash

# --- Configuration ---
PHOENIX_HTTP_URL="http://localhost:4000/"
PHOENIX_WS_URL="ws://localhost:4000/socket/websocket"
ROOM_TOPIC="room:test_lobby" # Ensure this matches your Phoenix channel topic
PHOENIX_PROTOCOL_VERSION="2.0.0"

# --- Script Logic ---

echo "1. Performing HTTP GET to acquire _backend_key cookie..."

# Use mktemp to create a temporary file for httpie's headers output.
# --print-headers is specific to httpie, outputs only headers to stdout/file.
# We redirect stdout (1) to the file and stderr (2) to /dev/null
HTTP_HEADERS_FILE=$(mktemp)
http -h GET "$PHOENIX_HTTP_URL" 1>"$HTTP_HEADERS_FILE" 2>/dev/null
cat $HTTP_HEADERS_FILE

# Extract the _backend_key from the Set-Cookie header using sed
# This finds lines starting with 'Set-Cookie: _backend_key='
# Then captures everything until the first ';' and prints only that.
backend_key_cookie=$(cat $HTTP_HEADERS_FILE | grep set-cookie | sed 's/^.*backend_key=//' | awk {'print $1 ";"'} | sed 's/;//g')

# Clean up the temporary headers file
rm "$HTTP_HEADERS_FILE"

if [ -z "$backend_key_cookie" ]; then
    echo "Error: Could not extract _backend_key cookie. Is Phoenix running and setting it?"
    exit 1
fi

echo "   Extracted _backend_key: $backend_key_cookie"

echo "2. Opening WebSocket connection with the cookie and sending messages..."

# Create a temporary named pipe (FIFO) to feed messages to websocat
FIFO_PATH=$(mktemp -u --tmpdir ws_fifo_XXXXXX)
mkfifo "$FIFO_PATH"

# Start websocat in the background, reading from the FIFO.
# It uses the captured cookie in the "Cookie" header.
websocat --header "Cookie: _backend_key=$backend_key_cookie" --text  \
         "$PHOENIX_WS_URL?vsn=$PHOENIX_PROTOCOL_VERSION&guest_token=$backend_key_cookie" \
         < "$FIFO_PATH" &
WEBSOCAT_PID=$! # Store websocat's Process ID for later cleanup

# Give websocat a moment to establish the connection
sleep 2

# --- Send WebSocket Messages to the FIFO ---

# Send the JOIN message
echo "Sending JOIN message to topic '$ROOM_TOPIC'..."
echo "{\"topic\":\"$ROOM_TOPIC\", \"event\":\"phx_join\", \"payload\":{}, \"ref\":\"1\"}" > "$FIFO_PATH"

# Give Phoenix a
