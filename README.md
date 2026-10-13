# Automated Project Bootstrapping & Process Management

## Overview

`deploy_agent.sh` is a Bash automation tool for deploying, running, and managing a Python-based Student Attendance Tracker.

The script automates project setup, roster generation, configuration management, file permissions, log archival, and deployment interruption handling.

## Project Structure

### Repository Structure

```text
.
├── deploy_agent.sh
├── README.md
├── attendance_checker.py
├── assets.csv
└── config.json
```

The source files are the original files supplied for the assignment and should remain unchanged.

### Deployed Application Structure

After deployment, the script creates a project directory named `attendance_tracker_<name>`.

```text
attendance_tracker_<name>/
├── attendance_checker.py
├── Helpers/
│   ├── assets.csv
│   └── config.json
├── reports/
└── archives/
    ├── attendance/
    └── absent/
```

The `archives/` directory is created when the archive feature runs. The application generates its report logs inside `reports/`.

## Prerequisites

Ensure the following tools are installed:

- Bash
- Python 3
- `zip`
- `sed`
- Standard Unix utilities, including `mkdir`, `cp`, `chmod`, and `date`

The script checks that Python 3 and `zip` are available before deployment.

## Installation and Execution

1. Clone or download this repository.
2. Ensure the three source files are present in the repository root.
3. Open a terminal in the repository root.
4. Make the script executable:

   ```bash
   chmod +x deploy_agent.sh
   ```

5. Start the script:

   ```bash
   ./deploy_agent.sh
   ```

6. Follow the interactive menu to select an operation.

## Features

### 1. Deploy the Application

The deployment feature:

- Checks the required dependencies and template files.
- Prompts the user for a project name.
- Creates the project directory and required subdirectories.
- Checks for an existing project and requests confirmation before overwriting it.
- Copies `attendance_checker.py` and `config.json` from the repository root.
- Allows the user to choose between copying an existing roster and generating a fresh roster.
- Sets the required file permissions.
- Offers an option to update the attendance alert thresholds.
- Starts the application after deployment to verify that it can run.

#### Roster Options

**Option A — Copy the template roster**

The user selects the number of student rows to copy from `assets.csv`. The header is retained.

The supplied roster contains ten students with four previously recorded sessions per student. The configuration should therefore use:

```json
"total_sessions": 5
```

**Option B — Generate a fresh roster**

The script generates student records using predefined sample names and email addresses. Attendance and absence counts start at zero.

The configuration should use:

```json
"total_sessions": 1
```

This keeps the configuration consistent with the number of sessions already recorded in the roster.

#### File Permissions

The deployment feature applies the following permissions:

- `attendance_checker.py`: executable.
- `Helpers/config.json`: owner read/write only, using `chmod 600`.

The configuration file contains attendance thresholds and should have restricted access.

#### Updating Alert Thresholds

During deployment, the user can choose to update the warning and failure thresholds.

The default values are:

- Warning threshold: 75%.
- Failure threshold: 50%.

Input validation should reject invalid percentages and ensure that the warning threshold is greater than the failure threshold. The deployed configuration is updated using `sed` without unnecessarily reformatting the JSON file.

### 2. Run the Application

The run feature executes an already deployed attendance tracker.

From the deployed project root, the application is started with:

```bash
python3 attendance_checker.py
```

The application interactively prompts the instructor to mark students present or absent, updates the roster, and generates report logs as applicable.

### 3. Archive the Log Files

The archive feature checks for the following files:

- `reports/attendance.log`
- `reports/absent.log`

Each existing log is copied into its own archive directory:

- Attendance logs: `archives/attendance/`
- Absence logs: `archives/absent/`

Archived filenames use the format:

```text
attendance_YYYYMMDD_HHMMSS.log
absent_YYYYMMDD_HHMMSS.log
```

For example:

```text
archives/
├── attendance/
│   └── attendance_20261013_115500.log
└── absent/
    └── absent_20261013_115500.log
```

The timestamp makes archived copies traceable. Original logs remain in `reports/`, and missing logs are reported without preventing the other log from being archived.

### 4. Signal Handling and Cleanup

During deployment, the script handles:

- `SIGINT`, normally triggered by Ctrl+C.
- `SIGTSTP`, normally triggered by Ctrl+Z.

When deployment is interrupted, the handler reports the interruption and attempts to create a ZIP archive named:

```text
attendance_tracker_<name>_archive.zip
```

The archive contains the incomplete project directory and the files created up to the interruption.

After successful archival, the incomplete project directory is removed to avoid leaving a partial deployment behind. If ZIP creation fails, the implementation should preserve the incomplete directory rather than delete the only remaining copy.

Signal handling applies during deployment, not during the Python attendance-marking session.

## Testing and Verification

The following tests should be performed before submission:

- Verify dependency checks when Python 3 or `zip` is unavailable.
- Deploy using both roster options.
- Verify CSV headers, student counts, and session configuration.
- Confirm that existing directories are handled safely.
- Test valid and invalid threshold inputs.
- Verify file permissions using `ls -l`.
- Run an attendance-marking session.
- Confirm that available logs are archived with timestamped filenames.
- Test behavior when either log is missing.
- Interrupt deployment with Ctrl+C and Ctrl+Z.
- Verify the ZIP archive contents, cleanup behavior, and exit status.

The deployed application should be checked against the required directory structure before it is considered successfully deployed.

## Technologies Used

- Bash and shell scripting
- Python 3
- `sed` for configuration updates
- `chmod` for file permissions
- `zip` for interrupted-deployment archives
- Standard Unix utilities for directory management and log archival

## Demonstration Video

**Video link:** [Insert your demonstration video URL here]

The demonstration should cover the implementation approach, deployment, both roster options, a live attendance-marking session, log archival, and testing of both interruption signals.

## Author

**Name:** Teninlanimi Taiwo  
**GitHub:** [Your GitHub Profile URL]  
**Repository:** `deploy_agent_teni-taiwo-alu`
