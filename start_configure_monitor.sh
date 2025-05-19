#!/bin/bash

SCRIPT_NAME="config_change_monitor.py"
LOG_FILE="config_monitor.log"

# Check if Python is installed
if ! command -v python3 &> /dev/null; then
    echo "Python is not installed. Exiting."
    exit 1
fi

# Check if the monitoring script exists
if [ ! -f "$SCRIPT_NAME" ]; then
    echo "$SCRIPT_NAME not found in the current directory."
    exit 1
fi

# Check and install required libraries
REQUIRED_LIBS=("watchdog" "python-dotenv")
for lib in "${REQUIRED_LIBS[@]}"; do
    if ! python3 -c "import $lib" &> /dev/null; then
        echo "Installing $lib..."
        pip install $lib
    fi
done

# Start the monitoring script in the background
nohup python3 "$SCRIPT_NAME" > "$LOG_FILE" 2>&1 &
echo "Config monitoring started. Check $LOG_FILE for output."
