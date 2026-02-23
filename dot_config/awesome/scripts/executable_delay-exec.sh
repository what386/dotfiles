#!/bin/bash

# Check if argument is provided
if [ -z "$1" ]; then
  echo "Usage: $0 \"command to execute\""
  exit 1
fi

# Wait for 1 second
sleep 1

# Execute the command
eval "$1"
