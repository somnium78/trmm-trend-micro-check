<#
.SYNOPSIS
    Monitors Trend Micro Worry-Free Business Security Agent status for TRMM integration.
.DESCRIPTION
    This script checks the installation status, service health, signature age, and real-time protection
    status of Trend Micro WFBS Agent. It outputs a single JSON string for TRMM custom field storage.
    The script is designed to be non-invasive and safe for production use.
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
    This command checks the Trend Micro WFBS status and outputs JSON for TRMM custom field.
.EXAMPLE
    .\Win_TrendMicro_WFBS_Status_Check.ps1 -Debug
    This command runs the check with debug output enabled.
.NOTES
    - Requires administrative privileges for registry access
    - Compatible with Trend Micro WFBS Agent 20.0 and later
    - Outputs single JSON string for TRMM Collector Task compatibility
    - Handles German Windows localization issues with DateTime parsing
    - Safe for production use - read-only operations only
.OUTPUTS
    Single JSON string containing:
    - health_status: OK/REALTIME_DISABLED/SERVICE_STOPPED/OUTDATED_SIGNATURES/WARNING/NOT_INSTALLED/ERROR
    - installed: 1 if installed, 0 if not
    - service_running: 1 if services running, 0 if not  
    - version: WFBS version string or "Unknown"
    - signature_age: Age of signatures in days (decimal) or -1 if unknown
    - last_update: Last signature update date (YYYY-MM-DD) or "Unknown"
    - realtime_protection: 1 if enabled, 0 if disabled
#>

param(
    [switch]$Debug
)

try {
    # Initialize status object
    $Status = @{
        health_status = "UNKNOWN"
        version = "Unknown"
        installed = 0
        service_running = 0
        last_update = "Unknown"
        signature_age = -1
        realtime_protection = 0
    }

    if ($Debug) {
        Write-Host "Starting Trend Micro WFBS status check..." -ForegroundColor Green
    }

    # Check if Trend Micro is installed
    $TrendMicroPath = "C:\Program Files (x86)\Trend Micro\Security Agent"
    $TrendMicroPath64 = "C:\Program Files\Trend Micro\Security Agent"

    $InstallPath = $null
    if (Test-Path $TrendMicroPath) {
        $InstallPath = $TrendMicroPath
        $Status.installed = 1
        if ($Debug) { Write-Host "Found Trend Micro at: $TrendMicroPath" -ForegroundColor Yellow }
    } elseif (Test-Path $TrendMicroPath64) {
        $InstallPath = $TrendMicroPath64
        $Status.installed = 1
        if ($Debug) { Write-Host "Found Trend Micro at: $TrendMicroPath64" -ForegroundColor Yellow }
    } else {
        if ($Debug) { Write-Host "Trend Micro not found in standard paths" -ForegroundColor Red }
    }

    if ($Status.installed -eq 1) {
        # Get version information
        try {
            $VersionReg = Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\TrendMicro\PC-cillinNTCorp\CurrentVersion" -ErrorAction SilentlyContinue
            if (!$VersionReg) {
                $VersionReg = Get-ItemProperty -Path "HKLM:\SOFTWARE\TrendMicro\PC-cillinNTCorp\CurrentVersion" -ErrorAction SilentlyContinue
            }

            if ($VersionReg -and $VersionReg.Version) {
                $Status.version = $VersionReg.Version
                if ($Debug) { Write-Host "Version: $($Status.version)" -ForegroundColor Yellow }
            }
        } catch {
            if ($Debug) { Write-Host "Version detection failed: $($_.Exception.Message)" -ForegroundColor Red }
        }

        # Check critical services
        $Services = @("TMBMServer", "TmListen", "ntrtscan", "tmlisten")
        $RunningServices = 0

        foreach ($ServiceName in $Services) {
            $Service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
            if ($Service -and $Service.Status -eq "Running") {
                $RunningServices++
                if ($Debug) { Write-Host "Service $ServiceName: Running" -ForegroundColor Green }
            } elseif ($Service) {
                if ($Debug) { Write-Host "Service $ServiceName: $($Service.Status)" -ForegroundColor Red }
            }
        }

        if ($RunningServices -gt 0) {
            $Status.service_running = 1
        }

        if ($Debug) { Write-Host "Running services: $RunningServices/$($Services.Count)" -ForegroundColor Yellow }

        # Check real-time protection status
        try {
            $RealtimeReg = Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\TrendMicro\PC-cillinNTCorp\CurrentVersion\Real Time Scan Configuration" -ErrorAction SilentlyContinue
            if (!$RealtimeReg) {
                $RealtimeReg = Get-ItemProperty -Path "HKLM:\SOFTWARE\TrendMicro\PC-cillinNTCorp\CurrentVersion\Real Time Scan Configuration" -ErrorAction SilentlyContinue
            }

            if ($RealtimeReg -and $RealtimeReg.RealTimeScanOn -eq 1) {
                $Status.realtime_protection = 1
                if ($Debug) { Write-Host "Real-time protection: Enabled" -ForegroundColor Green }
            } else {
                if ($Debug) { Write-Host "Real-time protection: Disabled" -ForegroundColor Red }
            }
        } catch {
            if ($Debug) { Write-Host "Real-time protection check failed: $($_.Exception.Message)" -ForegroundColor Red }
        }

        # Get signature information
        try {
            $PatternReg = Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\TrendMicro\PC-cillinNTCorp\CurrentVersion\Internet Settings" -ErrorAction SilentlyContinue
            if (!$PatternReg) {
                $PatternReg = Get-ItemProperty -Path "HKLM:\SOFTWARE\TrendMicro\PC-cillinNTCorp\CurrentVersion\Internet Settings" -ErrorAction SilentlyContinue
            }

            if ($PatternReg) {
                # Try to get pattern date
                if ($PatternReg.PatternDate) {
                    try {
                        $PatternDate = [DateTime]::ParseExact($PatternReg.PatternDate, "yyyyMMdd", $null)
                        $Status.last_update = $PatternDate.ToString("yyyy-MM-dd")
                        $Status.signature_age = [math]::Round(((Get-Date) - $PatternDate).TotalDays, 1)
                        if ($Debug) { Write-Host "Pattern date: $($Status.last_update) (Age: $($Status.signature_age) days)" -ForegroundColor Yellow }
                    } catch {
                        if ($Debug) { Write-Host "Pattern date parsing failed: $($_.Exception.Message)" -ForegroundColor Red }
                    }
                }

                # Alternative: Try LastUpdateTime
                if ($Status.last_update -eq "Unknown" -and $PatternReg.LastUpdateTime) {
                    try {
                        $UpdateTime = [DateTime]::FromFileTime($PatternReg.LastUpdateTime)
                        $Status.last_update = $UpdateTime.ToString("yyyy-MM-dd")
                        $Status.signature_age = [math]::Round(((Get-Date) - $UpdateTime).TotalDays, 1)
                        if ($Debug) { Write-Host "Last update time: $($Status.last_update) (Age: $($Status.signature_age) days)" -ForegroundColor Yellow }
                    } catch {
                        if ($Debug) { Write-Host "LastUpdateTime parsing failed: $($_.Exception.Message)" -ForegroundColor Red }
                    }
                }
            }
        } catch {
            if ($Debug) { Write-Host "Signature information check failed: $($_.Exception.Message)" -ForegroundColor Red }
        }

        # Determine overall health status
        if ($Status.service_running -eq 1 -and $Status.realtime_protection -eq 1 -and $Status.signature_age -le 7) {
            $Status.health_status = "OK"
        } elseif ($Status.service_running -eq 1 -and $Status.realtime_protection -eq 0) {
            $Status.health_status = "REALTIME_DISABLED"
        } elseif ($Status.service_running -eq 0) {
            $Status.health_status = "SERVICE_STOPPED"
        } elseif ($Status.signature_age -gt 7) {
            $Status.health_status = "OUTDATED_SIGNATURES"
        } else {
            $Status.health_status = "WARNING"
        }
    } else {
        # Trend Micro not installed
        $Status.health_status = "NOT_INSTALLED"
        if ($Debug) { Write-Host "Final status: NOT_INSTALLED" -ForegroundColor Red }
    }

    if ($Debug) {
        Write-Host "Final health status: $($Status.health_status)" -ForegroundColor Cyan
        Write-Host "Status object:" -ForegroundColor Cyan
        $Status | ConvertTo-Json | Write-Host
    }

    # Output JSON for TRMM custom field (single line)
    $JsonOutput = $Status | ConvertTo-Json -Compress
    Write-Output $JsonOutput

} catch {
    # Error occurred - output error status
    $ErrorStatus = @{
        health_status = "ERROR"
        version = "Unknown"
        installed = 0
        service_running = 0
        last_update = "Unknown"
        signature_age = -1
        realtime_protection = 0
        error = $_.Exception.Message
    }

    if ($Debug) {
        Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Stack Trace: $($_.ScriptStackTrace)" -ForegroundColor Red
    }

    $ErrorJson = $ErrorStatus | ConvertTo-Json -Compress
    Write-Output $ErrorJson
}
