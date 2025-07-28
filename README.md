# Trend Micro WFBS Status Monitor for Tactical RMM

A comprehensive monitoring solution for Trend Micro Worry-Free Business Security (WFBS) Agent status in Tactical RMM environments.

🎯 Features

- Real-time Status Monitoring - Checks installation, service status, and real-time protection
- Signature Age Tracking - Monitors virus definition freshness
- Health Status Assessment - Provides overall system health evaluation
- Professional Reporting - Client-specific reports with visual status indicators
- TRMM Integration - Seamless integration with Tactical RMM custom fields and reporting
- Single JSON Output - Optimized for TRMM Collector Tasks

📋 Requirements

- Tactical RMM - Latest version with custom fields support
- Windows Systems - Windows 10/11, Windows Server 2016+
- PowerShell - Version 5.1 or higher
- Trend Micro WFBS - Any supported version (tested with 20.0)
- Administrative Privileges - Required for registry access

📁 Project Files

- Win_TrendMicro_WFBS_Status_Check.ps1 - Main monitoring script
- TrendMicro_WFBS_Status_Report_Template.json - TRMM report template
- trend_micro_data_query.json - Data query definition for reports

🚀 Installation
Step 1: Create Custom Field

Navigate to Settings → Custom Fields in TRMM
Create new custom field:
   Name: trend_micro_status
   Model: Agent
   Type: Text

Step 2: Deploy Monitoring Script

Go to Scripts → Script Manager
Create new script:
    Name: "Trend Micro WFBS Status Monitor"
    Shell: PowerShell
    Script Type: Custom
    Category: Monitoring
Copy content from Win_TrendMicro_WFBS_Status_Check.ps1
Save script

Step 3: Create Collector Task

Navigate to Automation Manager → Tasks
Create new task:
    Name: "Collect Trend Micro Status"
    Type: Script Task
    Script: Select the monitoring script
    Custom Field: trend_micro_status
    Timeout: 300 seconds
    Run As: SYSTEM

Step 4: Deploy Report Template

Go to Reporting → Report Templates
Create new template:
   Name: "Trend Micro WFBS Status Report"
   Template Type: Client Report
Import or copy content from TrendMicro_WFBS_Status_Report_Template.json
Configure VARIABLES section with trend_micro_data_query.json content
Save template

📊 Usage
Running Collector Tasks

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
- Select "Trend Micro WFBS Status Report"
- Choose target client from dropdown
- Click Generate Report
- Review results and export if needed

📈 Monitoring Data

The script monitors and reports the following information in JSON format:
Field 	Description 	Values
health_status 	Overall system health 	OK, REALTIME_DISABLED, SERVICE_STOPPED, OUTDATED_SIGNATURES, WARNING, NOT_INSTALLED, ERROR
installed 	Installation status 	1 (installed), 0 (not installed)
service_running 	Service status 	1 (running), 0 (stopped)
realtime_protection 	Real-time protection 	1 (enabled), 0 (disabled)
version 	Trend Micro version 	Version string or "Unknown"
signature_age 	Days since last update 	Number of days or -1 (unknown)
last_update 	Last signature update 	Date (YYYY-MM-DD) or "Unknown"

Health Status Definitions

    OK - All systems operational, signatures current (≤7 days)
    REALTIME_DISABLED - Installed and running but real-time protection disabled
    SERVICE_STOPPED - Installed but critical services not running
    OUTDATED_SIGNATURES - Signatures older than 7 days
    WARNING - Minor issues detected
    NOT_INSTALLED - Trend Micro not found on system
    ERROR - Script execution error occurred

🎨 Report Features

    Color-coded Status Indicators - Visual health assessment at a glance
    Priority Sorting - Critical issues displayed first
    Summary Statistics - Overview with percentages
    Professional Layout - Clean, printable format optimized for landscape
    Client Filtering - Generate reports per client
    Last Seen Information - Agent connectivity status
    Responsive Design - Works well in TRMM interface and exports

🔧 Troubleshooting
Common Issues

No Data in Reports:

    Verify custom field name matches exactly: trend_micro_status
    Ensure Collector Task has executed successfully
    Check script execution logs in TRMM
    Confirm agents have proper permissions

Script Execution Errors:

    Verify PowerShell execution policy allows script execution
    Check Windows version compatibility
    Review TRMM agent logs for detailed error messages
    Ensure administrative privileges for registry access

Installation Detection Issues:

    Script checks both 32-bit and 64-bit installation paths
    Registry access requires appropriate permissions
    Some Trend Micro versions may use different registry locations
    German Windows localization handled automatically

Report Template Issues:

    Verify VARIABLES section matches trend_micro_data_query.json
    Ensure client filter is properly configured
    Check Jinja2 template syntax for any modifications

Debug Mode

Execute the script with -Debug parameter for detailed logging:

.\Win_TrendMicro_WFBS_Status_Check.ps1 -Debug

This provides verbose output including:

    Installation path detection
    Service status details
    Registry access attempts
    Signature date parsing
    Final health status calculation

Registry Locations

The script checks multiple registry paths for maximum compatibility:

Version Information:

    HKLM:\SOFTWARE\WOW6432Node\TrendMicro\PC-cillinNTCorp\CurrentVersion
    HKLM:\SOFTWARE\TrendMicro\PC-cillinNTCorp\CurrentVersion

Real-time Protection:

    HKLM:\SOFTWARE\WOW6432Node\TrendMicro\PC-cillinNTCorp\CurrentVersion\Real Time Scan Configuration
    HKLM:\SOFTWARE\TrendMicro\PC-cillinNTCorp\CurrentVersion\Real Time Scan Configuration

Signature Information:

    HKLM:\SOFTWARE\WOW6432Node\TrendMicro\PC-cillinNTCorp\CurrentVersion\Internet Settings
    HKLM:\SOFTWARE\TrendMicro\PC-cillinNTCorp\CurrentVersion\Internet Settings

📝 Customization
Modifying Health Thresholds

Edit the health status logic in Win_TrendMicro_WFBS_Status_Check.ps1:

# Signature age threshold (default: 7 days)
if ($Status.signature_age -le 7) {
    # Considered current
}

Adding Custom Monitoring

Extend the script with additional checks:

# Add custom registry checks
$CustomReg = Get-ItemProperty -Path &quot;HKLM:\SOFTWARE\...&quot; -ErrorAction SilentlyContinue

# Add to status object
$Status.custom_field = $CustomValue

Report Customization

Modify the report template to:

    Change color schemes
    Add additional columns
    Modify sorting logic
    Customize summary statistics
    Add company branding

🤝 Contributing

    Fork the repository
    Create feature branch (git checkout -b feature/AmazingFeature)
    Make changes and test thoroughly
    Commit changes (git commit -m 'Add AmazingFeature')
    Push to branch (git push origin feature/AmazingFeature)
    Submit pull request

Development Guidelines

    Follow PowerShell best practices
    Maintain backward compatibility
    Add appropriate error handling
    Update documentation for new features
    Test on multiple Windows versions
    Verify TRMM integration compatibility

📄 License

This project is licensed under the GPLv3 License - see the LICENSE file for details.
🆘 Support

    Issues: Report bugs and feature requests via GitHub Issues
    Documentation: Check TRMM documentation for platform-specific guidance
    Community: Join TRMM Discord for community support
    Security: Report security issues privately via email

🔄 Version History

    v1.0 - Initial release with comprehensive monitoring and reporting
        Single JSON output for TRMM compatibility
        Professional report template with client filtering
        Comprehensive health status assessment
        German Windows localization support

🙏 Acknowledgments

    Tactical RMM Team - For the excellent RMM platform and community support
    Trend Micro - For comprehensive security solutions and documentation
    Community Contributors - For testing, feedback, and feature suggestions
    somnium78 - Original author and maintainer

📞 Author

somnium78

    GitHub: @somnium78
    Project: Trend Micro WFBS Status Monitor for TRMM
    Date: July 28, 2025

This project is not affiliated with or endorsed by Trend Micro Inc. or Amidaware (Tactical RMM). All trademarks are property of their respective owners.
