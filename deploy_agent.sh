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
# Ask the user for a positive whole number
# --------------------------------------------------
ask_number() {
    local value
    while true; do
        read -r -p "$1" value
        if [[ "$value" =~ ^[1-9][0-9]*$ ]]; then
            echo "$value"
            return
        fi
        echo "Please enter a positive whole number."
    done
}

# --------------------------------------------------
# Change one number in config.json using sed
# --------------------------------------------------
update_config() {
    local config="$1" key="$2" value="$3"
    sed -E -i.bak "s/(\"$key\"[[:space:]]*:[[:space:]]*)[0-9]+/\1$value/" "$config"
    rm -f "$config.bak"
}

# --------------------------------------------------
# Option A: copy rows from the template roster
# --------------------------------------------------
copy_roster() {
    local destination="$1"
    local count

    count="$(ask_number "How many students should be copied? ")"

    # Line 1 is the header, so copy count + 1 lines.
    head -n $((count + 1)) "$TEMPLATE_DIR/assets.csv" > "$destination"

    if [ "$(wc -l < "$destination")" -lt $((count + 1)) ]; then
        echo "ERROR: The template roster does not have that many students."
        return 1
    fi

    echo "Copied $count students from the template roster."
}

# --------------------------------------------------
# Option B: generate a fresh roster from sample names
# --------------------------------------------------
generate_roster() {
    local destination="$1"
    local count i

    count="$(ask_number "How many students (1-10)? ")"

    if [ "$count" -gt 10 ]; then
        echo "ERROR: The generator supports at most 10 students."
        return 1
    fi

    local names=("Alice Johnson" "Bob Smith" "Carol Williams" "David Brown" "Esther Okafor" "Frank Adeyemi" "Grace Mensah" "Henry Bello" "Irene James" "John Ibrahim")
    local emails=("alice@example.com" "bob@example.com" "carol@example.com" "david@example.com" "esther@example.com" "frank@example.com" "grace@example.com" "henry@example.com" "irene@example.com" "john@example.com")

    echo "Email,Names,Attendance Count,Absence Count" > "$destination"
    for ((i = 0; i < count; i++)); do
        echo "${emails[$i]},${names[$i]},0,0" >> "$destination"
    done

    echo "Generated a fresh roster with $count students."
}

# --------------------------------------------------
# Optionally change the alert thresholds in config.json
# --------------------------------------------------
configure_thresholds() {
    local config="$1"
    local answer warning failure

    read -r -p "Update attendance alert thresholds? (y/n): " answer

    if [[ ! "$answer" =~ ^[Yy] ]]; then
        echo "Keeping the default thresholds."
        return
    fi

    while true; do
        read -r -p "Warning threshold [75]: " warning
        warning="${warning:-75}"
        if [[ "$warning" =~ ^[0-9]+$ ]] && [ "$warning" -le 100 ]; then
            break
        fi
        echo "Enter a whole number between 0 and 100."
    done

    while true; do
        read -r -p "Failure threshold [50]: " failure
        failure="${failure:-50}"
        if [[ "$failure" =~ ^[0-9]+$ ]] && [ "$failure" -le 100 ]; then
            if [ "$warning" -gt "$failure" ]; then
                break
            fi
            echo "Warning must be greater than failure."
        else
            echo "Enter a whole number between 0 and 100."
        fi
    done

    update_config "$config" warning "$warning"
    update_config "$config" failure "$failure"

    echo "Thresholds updated: warning=$warning%, failure=$failure%."
}

# --------------------------------------------------
# Run an already deployed project
# --------------------------------------------------
run_project() {
    local directory="$1"

    if [ ! -f "$directory/attendance_checker.py" ]; then
        echo "ERROR: No deployed project found at $directory"
        return 1
    fi

    echo "Starting attendance application..."
    ( cd "$directory" && python3 attendance_checker.py )
}

# --------------------------------------------------
# Deploy the application
# --------------------------------------------------
deploy_project() {
    local name choice roster config

    check_dependencies || return 1

    read -r -p "Enter a project name (letters, numbers, _ or -): " name

    if [[ ! "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo "ERROR: Invalid project name."
        return 1
    fi

    PROJECT_DIR="$PWD/attendance_tracker_$name"

    # Ask before deleting an existing project.
    if [ -d "$PROJECT_DIR" ]; then
        read -r -p "Project already exists. Overwrite it? (y/n): " choice
        if [[ ! "$choice" =~ ^[Yy] ]]; then
            echo "Deployment cancelled."
            return 1
        fi
        rm -rf "$PROJECT_DIR"
    fi

    echo "Creating $PROJECT_DIR..."
    mkdir -p "$PROJECT_DIR/Helpers" "$PROJECT_DIR/reports" || return 1

    cp "$TEMPLATE_DIR/attendance_checker.py" "$PROJECT_DIR/" || return 1
    cp "$TEMPLATE_DIR/config.json" "$PROJECT_DIR/Helpers/config.json" || return 1
    config="$PROJECT_DIR/Helpers/config.json"

    # Choose how the roster should be created.
    echo
    echo "Roster options:"
    echo "A. Copy rows from the template roster"
    echo "B. Generate a fresh roster"

    while true; do
        read -r -p "Choose A or B: " roster
        case "$roster" in
            A|a)
                copy_roster "$PROJECT_DIR/Helpers/assets.csv" || return 1
                # Template roster already has 4 recorded sessions.
                update_config "$config" total_sessions 5
                break
                ;;
            B|b)
                generate_roster "$PROJECT_DIR/Helpers/assets.csv" || return 1
                # A fresh roster has no previous sessions.
                update_config "$config" total_sessions 1
                break
                ;;
            *)
                echo "Please choose A or B."
                ;;
        esac
    done

    # Script must be executable, config should be private.
    chmod +x "$PROJECT_DIR/attendance_checker.py"
    chmod 600 "$config"
    echo "Permissions set: attendance_checker.py executable, config.json 600."

    configure_thresholds "$config" || return 1

    echo
    echo "Deployment completed. Starting the app to verify it works..."

    run_project "$PROJECT_DIR"
}

# --------------------------------------------------
# Copy the report logs into archives with a timestamp
# --------------------------------------------------
archive_logs() {
    local name="$1"
    local directory="$PWD/attendance_tracker_$name"
    local stamp

    if [ ! -d "$directory" ]; then
        echo "ERROR: No deployed project found at $directory"
        return 1
    fi

    stamp="$(date '+%Y%m%d_%H%M%S')"
    mkdir -p "$directory/archives/attendance" "$directory/archives/absent"

    # Archive each log if it exists.
    for log_type in attendance absent; do
        if [ -f "$directory/reports/$log_type.log" ]; then
            cp "$directory/reports/$log_type.log" \
               "$directory/archives/$log_type/${log_type}_${stamp}.log"
            echo "Archived: $directory/archives/$log_type/${log_type}_${stamp}.log"
        else
            echo "No $log_type.log found; skipping."
        fi
    done
}

# --------------------------------------------------
# If deployment is interrupted, zip what exists so far
# --------------------------------------------------
cleanup_interrupt() {
    if [ "$DEPLOYING" -ne 1 ]; then
        exit 130
    fi

    DEPLOYING=0
    echo
    echo "Deployment interrupted. Archiving the incomplete project..."

    if [ -d "$PROJECT_DIR" ]; then
        if ( cd "$(dirname "$PROJECT_DIR")" && zip -qr "$(basename "$PROJECT_DIR")_archive.zip" "$(basename "$PROJECT_DIR")" ); then
            echo "Incomplete project archived as $(basename "$PROJECT_DIR")_archive.zip"
            rm -rf "$PROJECT_DIR"
        else
            echo "ERROR: ZIP creation failed. Keeping the incomplete directory."
        fi
    fi

    exit 130
}

trap 'cleanup_interrupt' INT TSTP

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

    read -r -p "Select an option: " choice || exit 0

    case "$choice" in
        1)
            DEPLOYING=1
            deploy_project
            DEPLOYING=0
            ;;
        2)
            read -r -p "Enter deployed project name: " name
            run_project "$PWD/attendance_tracker_$name"
            ;;
        3)
            read -r -p "Enter deployed project name: " name
            archive_logs "$name"
            ;;
        4)
            echo "Goodbye."
            exit 0
            ;;
        *)
            echo "Invalid option. Choose 1, 2, 3 or 4."
            ;;
    esac
done
