# Trend Micro WFBS Status Check for TRMM

A PowerShell script for monitoring Trend Micro Worry-Free Business Security (WFBS) Agent status in Tactical RMM environments.

## Description

This script monitors the health and status of Trend Micro WFBS installations on Windows clients. It provides comprehensive monitoring including:

- Installation status detection
- Service health monitoring (TMBMServer, TmListen, ntrtscan, tmlisten)
- Signature age tracking with automatic date parsing
- Real-time protection status
- Version information extraction
- Health status evaluation with CRITICAL/WARNING/OK states

## Features

- **Non-invasive**: Read-only operations, safe for production use
- **TRMM Integration**: Outputs custom variables for TRMM reporting
- **Robust Parsing**: Handles German Windows localization and various date formats
- **Comprehensive Monitoring**: Tracks all critical WFBS components
- **Debug Support**: Optional detailed output for troubleshooting

## Requirements

- Windows operating system
- PowerShell 5.1 or later
- Administrative privileges (for registry access)
- Trend Micro Worry-Free Business Security Agent installed

## Supported Versions

- Trend Micro WFBS Agent 20.0 and later
- Tested on Windows 10/11 and Windows Server 2016/2019/2022

## Usage

### Basic Usage
```powershell
.\Win_TrendMicro_WFBS_Status_Check.ps1
```
### With Debug Output
```PowerShell
.\Win_TrendMicro_WFBS_Status_Check.ps1 -Debug
```

## TRMM Automated Task

1. Upload the script to your TRMM server
2. Create an Automated Task with the script
3. Schedule it to run on your desired interval (recommended: daily)
4. Configure custom fields to capture the output variables

### Output

The script outputs both human-readable status information and TRMM custom variables:

###Status Information
```
=== Trend Micro WFBS Status ===
Installed: True
Service_Running: True
Version: 20.0
Signature_Age_Days: 0.5
Last_Update: 2025-07-28
RealTime_Protection: Enabled
``` 
### TRMM Custom Variables
```
=== TRMM Custom Variables ===
tm_installed=1
tm_service_running=1
tm_version=20.0
tm_signature_age=0.5
tm_last_update=2025-07-28
tm_realtime_protection=1
tm_health_status=OK
```
### Custom Variables Reference

Variable 	Type 	Description
tm_installed 	Number 	1 if WFBS is installed, 0 if not
tm_service_running 	Number 	1 if all services are running, 0 if not
tm_version 	Text 	WFBS Agent version (e.g., "20.0")
tm_signature_age 	Number 	Age of virus signatures in days
tm_last_update 	Text 	Date of last signature update
tm_realtime_protection 	Number 	1 if real-time protection is enabled, 0 if not
tm_health_status 	Text 	Overall health: OK/WARNING/CRITICAL/NOT_INSTALLED

### Health Status Logic
- OK: All services running, signatures < 7 days old, real-time protection enabled
- WARNING: Signatures > 7 days old OR real-time protection disabled
- CRITICAL: Required services not running
- NOT_INSTALLED: WFBS Agent not detected
