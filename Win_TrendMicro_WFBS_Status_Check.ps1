<#
.SYNOPSIS
    Monitors Trend Micro Worry-Free Business Security Agent status for TRMM integration.
.DESCRIPTION
    This script checks the installation status, service health, signature age, and real-time protection
    status of Trend Micro WFBS Agent. It outputs TRMM-compatible custom variables for monitoring
    and reporting purposes. The script is designed to be non-invasive and safe for production use.
.PARAMETER Debug
    Enable debug output showing detailed service information.
.AUTHOR
    somnium78
.DATE
    July 28, 2025
.VERSION
    1.0
.EXAMPLE
    .\Win_TrendMicro_WFBS_Status_Check.ps1
    This command checks the Trend Micro WFBS status and outputs TRMM custom variables.
.EXAMPLE
    .\Win_TrendMicro_WFBS_Status_Check.ps1 -Debug
    This command runs the check with debug output enabled.
.NOTES
    - Requires administrative privileges for registry access
    - Compatible with Trend Micro WFBS Agent 20.0 and later
    - Outputs numerical values for TRMM custom fields (1/0 instead of true/false)
    - Handles German Windows localization issues with DateTime parsing
    - Safe for production use - read-only operations only
.OUTPUTS
    TRMM Custom Variables:
    - tm_installed: 1 if installed, 0 if not
    - tm_service_running: 1 if services running, 0 if not  
    - tm_version: WFBS version string
    - tm_signature_age: Age of signatures in days (decimal)
    - tm_last_update: Last signature update date
    - tm_realtime_protection: 1 if enabled, 0 if disabled
    - tm_health_status: OK/WARNING/CRITICAL/NOT_INSTALLED
#>

param(
    [switch]$Debug
)

# TRMM Community Script: Trend Micro WFBS Status Check
# Version: 1.0
# Author: somnium78
# License: GPL v3

$ErrorActionPreference = "SilentlyContinue"

# Initialize result object
$Result = @{
    Installed = $false
    ServiceRunning = $false
    Version = "Unknown"
    SignatureAge = -1
    LastUpdate = "Unknown"
    RealTimeProtection = "Unknown"
}

# 1. Check service status
$ServiceNames = @("TMBMServer", "TmListen", "ntrtscan", "tmlisten")
$RunningServices = @()

foreach ($ServiceName in $ServiceNames) {
    $Service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
    if ($Service) {
        $RunningServices += @{
            Name = $ServiceName
            Status = $Service.Status
        }
        if ($Service.Status -eq "Running") {
            $Result.ServiceRunning = $true
        }
    }
}

# 2. Check installation and version from registry
$RegPath = "HKLM:\SOFTWARE\WOW6432Node\TrendMicro\PC-cillinNTCorp\CurrentVersion"
if (Test-Path $RegPath) {
    $Result.Installed = $true
    $RegData = Get-ItemProperty -Path $RegPath -ErrorAction SilentlyContinue

    if ($RegData.WFBSAgentVersion) { 
        $Result.Version = $RegData.WFBSAgentVersion
    }
}

# 3. Get signature information from registry
$MiscRegPath = "HKLM:\SOFTWARE\WOW6432Node\TrendMicro\PC-cillinNTCorp\CurrentVersion\Misc."
if (Test-Path $MiscRegPath) {
    $MiscData = Get-ItemProperty -Path $MiscRegPath -ErrorAction SilentlyContinue

    # Process pattern date (YYYYMMDD format)
    if ($MiscData.PatternDate) {
        try {
            $PatternDateStr = $MiscData.PatternDate.ToString()
            if ($PatternDateStr.Length -eq 8 -and $PatternDateStr -match '^\d{8}$') {
                $Year = [int]$PatternDateStr.Substring(0,4)
                $Month = [int]$PatternDateStr.Substring(4,2)
                $Day = [int]$PatternDateStr.Substring(6,2)

                $PatternDate = New-Object DateTime($Year, $Month, $Day)
                $CurrentDate = [DateTime]::Now
                $TimeSpan = $CurrentDate - $PatternDate
                $Result.SignatureAge = [Math]::Round($TimeSpan.TotalDays, 1)
                $Result.LastUpdate = $PatternDate.ToString("yyyy-MM-dd")
            }
        } catch {
            # Fallback: Use Unix timestamp
            if ($MiscData.LastUpdateTime) {
                try {
                    $UnixTime = [int64]$MiscData.LastUpdateTime
                    $UnixEpoch = New-Object DateTime(1970, 1, 1, 0, 0, 0, [DateTimeKind]::Utc)
                    $UpdateDate = $UnixEpoch.AddSeconds($UnixTime).ToLocalTime()

                    $CurrentDate = [DateTime]::Now
                    $TimeSpan = $CurrentDate - $UpdateDate
                    $Result.SignatureAge = [Math]::Round($TimeSpan.TotalDays, 1)
                    $Result.LastUpdate = $UpdateDate.ToString("yyyy-MM-dd HH:mm:ss")
                } catch {
                    # Ignore parsing errors
                }
            }
        }
    }
}

# 4. Alternative: UpdateInfo registry (fallback)
if ($Result.SignatureAge -lt 0) {
    $UpdateInfoPath = "HKLM:\SOFTWARE\WOW6432Node\TrendMicro\PC-cillinNTCorp\CurrentVersion\UpdateInfo"
    if (Test-Path $UpdateInfoPath) {
        $UpdateData = Get-ItemProperty -Path $UpdateInfoPath -ErrorAction SilentlyContinue
        if ($UpdateData.LastUpdate) {
            try {
                $UnixTime = [int64]$UpdateData.LastUpdate
                $UnixEpoch = New-Object DateTime(1970, 1, 1, 0, 0, 0, [DateTimeKind]::Utc)
                $UpdateDate = $UnixEpoch.AddSeconds($UnixTime).ToLocalTime()

                $CurrentDate = [DateTime]::Now
                $TimeSpan = $CurrentDate - $UpdateDate
                $Result.SignatureAge = [Math]::Round($TimeSpan.TotalDays, 1)
                $Result.LastUpdate = $UpdateDate.ToString("yyyy-MM-dd HH:mm:ss")
            } catch {
                # Ignore parsing errors
            }
        }
    }
}

# 5. Check Real-Time Protection status
$RealTimeServices = @("ntrtscan", "tmlisten")
$RTRunning = $false
foreach ($RTService in $RealTimeServices) {
    $Service = Get-Service -Name $RTService -ErrorAction SilentlyContinue
    if ($Service -and $Service.Status -eq "Running") {
        $RTRunning = $true
        break
    }
}
$Result.RealTimeProtection = if ($RTRunning) { "Enabled" } else { "Disabled" }

# 6. Output TRMM-compatible results
Write-Output "=== Trend Micro WFBS Status ==="
Write-Output "Installed: $($Result.Installed)"
Write-Output "Service_Running: $($Result.ServiceRunning)"
Write-Output "Version: $($Result.Version)"
Write-Output "Signature_Age_Days: $($Result.SignatureAge)"
Write-Output "Last_Update: $($Result.LastUpdate)"
Write-Output "RealTime_Protection: $($Result.RealTimeProtection)"

# 7. TRMM Custom Variables
if ($Result.Installed) {
    Write-Output ""
    Write-Output "=== TRMM Custom Variables ==="
    Write-Output "tm_installed=1"
    Write-Output "tm_service_running=$(if($Result.ServiceRunning) { 1 } else { 0 })"
    Write-Output "tm_version=$($Result.Version)"
    Write-Output "tm_signature_age=$($Result.SignatureAge)"
    Write-Output "tm_last_update=$($Result.LastUpdate)"
    Write-Output "tm_realtime_protection=$(if($Result.RealTimeProtection -eq 'Enabled') { 1 } else { 0 })"

    # Evaluate health status
    $HealthStatus = "OK"
    if (-not $Result.ServiceRunning) { 
        $HealthStatus = "CRITICAL" 
    } elseif ($Result.SignatureAge -gt 7 -and $Result.SignatureAge -ge 0) { 
        $HealthStatus = "WARNING" 
    } elseif ($Result.RealTimeProtection -eq "Disabled") { 
        $HealthStatus = "WARNING" 
    }

    Write-Output "tm_health_status=$HealthStatus"
} else {
    Write-Output ""
    Write-Output "=== TRMM Custom Variables ==="
    Write-Output "tm_installed=0"
    Write-Output "tm_health_status=NOT_INSTALLED"
}

# 8. Debug output (optional)
if ($Debug) {
    Write-Output ""
    Write-Output "=== Debug Information ==="
    Write-Output "Registry Path Exists: $(Test-Path $RegPath)"
    Write-Output "Misc Registry Path Exists: $(Test-Path $MiscRegPath)"
    Write-Output "Running Services:"
    foreach ($Svc in $RunningServices) {
        Write-Output "  $($Svc.Name): $($Svc.Status)"
    }
}
