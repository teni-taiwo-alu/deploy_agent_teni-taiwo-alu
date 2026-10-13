#!/bin/bash

# Attendance Tracker Deployment Agent
# Deploys, runs and archives the attendance checker app.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/templates"

DEPLOYING=0
PROJECT_DIR=""

# --------------------------------------------------
# Check python3, zip and the source files exist
# --------------------------------------------------
check_dependencies() {
    command -v python3 >/dev/null 2>&1 || { echo "ERROR: python3 is not installed."; return 1; }
    command -v zip >/dev/null 2>&1 || { echo "ERROR: zip is not installed."; return 1; }

    for file in attendance_checker.py assets.csv config.json; do
        if [ ! -f "$TEMPLATE_DIR/$file" ]; then
            echo "ERROR: Missing file: $TEMPLATE_DIR/$file"
            return 1
        fi
    done
}

# --------------------------------------------------
# Main menu
# --------------------------------------------------
while true; do
    echo
    echo "===================================="
    echo " Student Attendance Deployment Agent"
    echo "===================================="
    echo "1. Deploy application"
    echo "2. Run existing application"
    echo "3. Archive logs"
    echo "4. Exit"

    read -r -p "Select an option: " choice

    case "$choice" in
        1) echo "Deploy feature not added yet." ;;
        2) echo "Run feature not added yet." ;;
        3) echo "Archive feature not added yet." ;;
        4)
            echo "Goodbye."
            exit 0
            ;;
        *)
            echo "Invalid option. Choose 1, 2, 3 or 4."
            ;;
    esac
done
