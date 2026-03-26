#!/bin/bash

# Check argument
if [ -z "$1" ]; then
  echo "Usage: $0 <CTID>"
  exit 1
fi

CTID="$1"

# Check if container exists
if ! pct status "$CTID" >/dev/null 2>&1; then
  echo "Error: Container $CTID does not exist."
  exit 1
fi

# Get container name from config
NAME=$(pct config "$CTID" | tr -d '\000' | sed -n 's/^hostname:[[:space:]]*//p')

# Fallback if no hostname
if [ -z "$NAME" ]; then
  NAME="unknown"
fi

# Check if name contains "claw"
if [[ "$NAME" != *claw* ]]; then
  echo "Error: Container name does not contain 'claw'."
  exit 1
fi

echo "Container found: $NAME (ID: $CTID)"

# Stop container if running
STATUS=$(pct status "$CTID" | awk '{print $2}')
if [ "$STATUS" = "running" ]; then
  echo "Stopping container..."
  pct stop "$CTID"
fi

# Countdown with cancel option
echo "CONTAINER: $NAME WILL BE DELETED!"
echo "Press any key to cancel..."

for i in 5 4 3 2 1; do
  echo -n "$i... "
  read -t 1 -n 1 key
  if [ $? = 0 ]; then
    echo
    echo "Cancelled."
    exit 0
  fi
done

echo
echo "Deleting container..."
pct destroy "$CTID"
