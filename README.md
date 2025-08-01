# Trend Micro WFBS Status Monitor for Tactical RMM

A comprehensive monitoring solution for Trend Micro Security Agents in Tactical RMM environments. Supports both Worry-Free Business Security (WFBS) Agent and Client Server Security Agent with automatic detection.

# 🎯 Features

- Universal Detection - Automatically detects and monitors both WFBS and Client Server Security Agent
- Real-time Status Monitoring - Checks installation, service status, and real-time protection
- Signature Age Tracking - Monitors virus definition freshness with 2-day threshold
- Health Status Assessment - Provides overall system health evaluation
- Professional Reporting - Client-specific reports with visual status indicators
- TRMM Integration - Seamless integration with Tactical RMM custom fields and reporting
- Single JSON Output - Optimized for TRMM Collector Tasks
- PDF-Compatible Reports - Uses HTML entities for proper PDF rendering

# 📋 Requirements

- Tactical RMM - Latest version with custom fields support
- Windows Systems - Windows 10/11, Windows Server 2016+
- PowerShell - Version 5.1 or higher
- Trend Micro Products - WFBS Agent or Client Server Security Agent
- Administrative Privileges - Required for registry access

# 📁 Project Files

- Win_TrendMicro_Universal_Status_Check.ps1 - Main monitoring script
- TrendMicro_Universal_Status_Report_Template.json - TRMM report template
- trend_micro_data_query.json - Data query definition for reports

# 🚀 Installation
Step 1: Create Custom Field
- Navigate to Settings → Custom Fields in TRMM
- Create new custom field:
   - Name: trend_micro_status
   - Model: Agent
   - Type: Text

Step 2: Deploy Monitoring Script
- Go to Scripts → Script Manager
- Create new script:
   - Name: "Trend Micro Universal Status Monitor"
   - Shell: PowerShell
   - Script Type: Custom
   - Category: Monitoring
- Copy content from Win_TrendMicro_Universal_Status_Check.ps1
- Save script

Step 3: Create Collector Task
- Navigate to Automation Manager → Tasks
- Create new task:
   - Name: "Collect Trend Micro Status"
   - Type: Script Task
   - Script: Select the monitoring script
   - Custom Field: trend_micro_status
   - Timeout: 300 seconds
   - Run As: SYSTEM

Step 4: Deploy Report Template
- Go to Reporting → Report Templates
- Create new template:
    - Name: "Trend Micro Universal Status Report"
    - Template Type: Client Report
- Import or copy content from TrendMicro_Universal_Status_Report_Template.json
- Configure VARIABLES section with trend_micro_data_query.json content
- Save template

# 📊 Usage
## Running Collector Tasks

Manual Execution:
- Select agents in Agent Manager
- Run "Collect Trend Micro Status" task
- Wait for completion and verify custom field population

Automated Execution:
- Create Automation Policy
- Add Collector Task with desired schedule (recommended: daily)
- Apply policy to target agents or clients
- Generating Reports

- Navigate to Reporting → Generate Report
- Select "Trend Micro Universal Status Report"
- Choose target client from dropdown
- Click Generate Report
- Review results and export if needed

# 📈 Monitoring Data

The script monitors and reports the following information in JSON format:
| Field | Description | Values |
|-------|-------------|---------|
| health_status | Overall system health | OK, REALTIME_DISABLED, SERVICE_STOPPED, OUTDATED_SIGNATURES, WARNING, NOT_INSTALLED, ERROR |
| installed | Installation status | 1 (installed), 0 (not installed) |
| service_running | Service status | 1 (running), 0 (stopped) |
| realtime_protection | Real-time protection | 1 (enabled), 0 (disabled) |
| version | Trend Micro version | Version string or "Unknown" |
| signature_age | Days since last update | Number of days or -1 (unknown) |
| last_update | Last signature update | Date (YYYY-MM-DD) or "Unknown" |
| product_type | Detected product type | "WFBS", "Client_Server", or "Unknown" |


## Health Status Definitions

- OK - All systems operational, signatures current (≤2 days)
- REALTIME_DISABLED - Installed and running but real-time protection disabled
- SERVICE_STOPPED - Installed but critical services not running
- OUTDATED_SIGNATURES - Signatures older than 7 days
- WARNING - Minor issues detected
- NOT_INSTALLED - Trend Micro not found on system
- ERROR - Script execution error occurred

# 🎨 Report Features

- Color-coded Status Indicators - Visual health assessment at a glance
- Priority Sorting - Critical issues displayed first
- Summary Statistics - Overview with percentages
- Professional Layout - Clean, printable format optimized for landscape
- Client Filtering - Generate reports per client
- Last Seen Information - Agent connectivity status
- Responsive Design - Works well in TRMM interface and exports
- PDF-Compatible Symbols - Uses HTML entities instead of emojis
- Responsive Design - Works well in TRMM interface and exports

# 🛡️ Supported Products

## Trend Micro WFBS Agent

Installation Paths:
- C:\Program Files (x86)\Trend Micro\Security Agent
- C:\Program Files\Trend Micro\Security Agent

Registry Keys:
- Version: CurrentVersion
- Real-time: RealTimeScanOn
- Signatures: Internet Settings

## Trend Micro Client Server Security Agent

Installation Paths:
- C:\Program Files (x86)\Trend Micro\Client Server Security Agent
- C:\Program Files\Trend Micro\Client Server Security Agent

Registry Keys:
- Version: Misc. (ProgramVer) + HostedAgent (Version)
- Real-time: Enable
- Signatures: Misc. (PatternDate/LastUpdateTime)


# 🐛 Debug Mode

Execute the script with -Debug parameter for detailed logging:

.\Win_TrendMicro_Universal_Status_Check.ps1 -Debug

This provides verbose output including:

- Product type detection
- Installation path detection
- Service status details
- Registry access attempts
- Signature date parsing
- Final health status calculation


# 📄 Registry Locations

The script checks multiple registry paths for maximum compatibility:

Base Paths:
- HKLM:\SOFTWARE\WOW6432Node\TrendMicro\PC-cillinNTCorp\CurrentVersion
- HKLM:\SOFTWARE\TrendMicro\PC-cillinNTCorp\CurrentVersion

WFBS Specific:
- Version: \CurrentVersion
- Real-time: \Real Time Scan Configuration (RealTimeScanOn)
- Signatures: \Internet Settings

Client Server Specific:
- Version: \Misc. (ProgramVer) + \HostedAgent (Version)
- Real-time: \Real Time Scan Configuration (Enable)
- Signatures: \Misc. (PatternDate/LastUpdateTime)


# 📄 License

This project is licensed under the GPLv3 License - see the LICENSE file for details.

# 🆘 Support

- Issues: Report bugs and feature requests via GitHub Issues
- Documentation: Check TRMM documentation for platform-specific guidance
- Community: Join TRMM Discord for community support
- Security: Report security issues privately via email

# 🔄 Version History

- v2.0 - Universal version with automatic product detection
   - Added support for Client Server Security Agent
   - Automatic product type detection and appropriate registry handling
   - Enhanced version reporting with combined Program/Agent versions
   - PDF-compatible report template with HTML entities
   - Improved signature age threshold (2 days)
   - Added product_type field to JSON output
   - Special thanks to Jost for providing Client Server Security Agent data and script contributions

- v1.0 - Initial WFBS-only release
   - Single JSON output for TRMM compatibility
   - Professional report template with client filtering
   - Comprehensive health status assessment
   - German Windows localization support


# 🙏 Acknowledgments

Special thanks to Jost for his valuable contributions to this project. His provision of Client Server Security Agent registry data and script modifications made the universal detection capabilities possible, significantly expanding the project's compatibility and usefulness for diverse Trend Micro deployments.


# 📞 Author

somnium78
- GitHub: @somnium78
- Project: Trend Micro WFBS Status Monitor for TRMM
- Date: July 28, 2025

This project is not affiliated with or endorsed by Trend Micro Inc. or Amidaware (Tactical RMM). All trademarks are property of their respective owners.
