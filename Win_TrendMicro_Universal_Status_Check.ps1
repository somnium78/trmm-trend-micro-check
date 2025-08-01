<#
.SYNOPSIS
    Universal Trend Micro Status Monitor for Tactical RMM

.DESCRIPTION
    Monitors Trend Micro WFBS Agent and Client Server Security Agent status.
    Automatically detects product type and reports comprehensive status information.

.PARAMETER Debug
    Enable detailed debug output for troubleshooting

.EXAMPLE
    .\Win_TrendMicro_Universal_Status_Check.ps1
    .\Win_TrendMicro_Universal_Status_Check.ps1 -Debug

.NOTES
    Author: somnium78
    Version: 2.0
    Date: August 01, 2025

    Special thanks to Jost for providing Client Server Security Agent data

    Compatible with:
    - Trend Micro WFBS Agent
    - Trend Micro Client Server Security Agent

    Requires: PowerShell 5.1+, Administrative privileges
#>

param(
    [switch]$Debug
)

# Initialize status object
$TrendMicroStatus = @{
    health_status = "ERROR"
    version = "Unknown"
    installed = 0
    service_running = 0
    realtime_protection = 0
    signature_age = -1
    last_update = "Unknown"
    product_type = "Unknown"
}

function Write-DebugInfo {
    param([string]$Message, [string]$Color = "White")
    if ($Debug) {
        Write-Host $Message -ForegroundColor $Color
    }
}

function Test-TrendMicroService {
    param([string]$ServiceName)

    try {
        $Service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        if ($Service) {
            if ($Service.Status -eq 'Running') {
                Write-DebugInfo "Service $($ServiceName) - Running" "Green"
                return $true
            } else {
                Write-DebugInfo "Service $($ServiceName) - $($Service.Status)" "Yellow"
                return $false
            }
        } else {
            Write-DebugInfo "Service $($ServiceName) - Not Found" "Red"
            return $false
        }
    } catch {
        Write-DebugInfo "Service $($ServiceName) - Error checking - $($_.Exception.Message)" "Red"
        return $false
    }
}

function Get-RegistryValue {
    param(
        [string]$Path,
        [string]$Name
    )

    try {
        if (Test-Path $Path) {
            $Value = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
            if ($Value) {
                Write-DebugInfo "Found registry value $Name = $($Value.$Name) at $Path" "Gray"
                return $Value.$Name
            }
        }
        Write-DebugInfo "Registry value $Name not found at $Path" "Yellow"
    } catch {
        Write-DebugInfo "Registry error at $Path\$Name - $($_.Exception.Message)" "Red"
    }
    return $null
}

function Test-InstallationPath {
    param([string[]]$Paths)

    foreach ($Path in $Paths) {
        if (Test-Path $Path) {
            Write-DebugInfo "Found installation at - $Path" "Green"
            return $Path
        }
    }
    Write-DebugInfo "No installation found in checked paths" "Yellow"
    return $null
}

function Get-WFBSInfo {
    Write-DebugInfo "Checking WFBS Agent configuration..." "Cyan"

    $RegistryPaths = @(
        "HKLM:\SOFTWARE\WOW6432Node\TrendMicro\PC-cillinNTCorp\CurrentVersion",
        "HKLM:\SOFTWARE\TrendMicro\PC-cillinNTCorp\CurrentVersion"
    )

    $WFBSInfo = @{
        Version = "Unknown"
        RealtimeProtection = 0
        SignatureAge = -1
        LastUpdate = "Unknown"
    }

    foreach ($RegPath in $RegistryPaths) {
        Write-DebugInfo "Checking registry path - $RegPath" "Gray"

        # Version information - WFBS specific
        $Version = Get-RegistryValue -Path $RegPath -Name "WFBSAgentVersion"
        if (-not $Version) {
            $Version = Get-RegistryValue -Path $RegPath -Name "Application Version"
        }
        if (-not $Version) {
            $Version = Get-RegistryValue -Path $RegPath -Name "Version"
        }
        if ($Version -and $WFBSInfo.Version -eq "Unknown") {
            $WFBSInfo.Version = $Version
            Write-DebugInfo "Found WFBS version - $Version" "Green"
        }

        # Real-time protection - check Enable first, then RealTimeScanOn
        $RTPath = "$RegPath\Real Time Scan Configuration"
        $RTEnabled = Get-RegistryValue -Path $RTPath -Name "Enable"
        if ($RTEnabled -eq $null) {
            $RTEnabled = Get-RegistryValue -Path $RTPath -Name "RealTimeScanOn"
        }
        if ($RTEnabled -ne $null -and $WFBSInfo.RealtimeProtection -eq 0) {
            $WFBSInfo.RealtimeProtection = [int]$RTEnabled
            Write-DebugInfo "WFBS Real-time protection - $RTEnabled" "Green"
        }

        # Signature information from Misc. path
        $MiscPath = "$RegPath\Misc."
        $PatternDate = Get-RegistryValue -Path $MiscPath -Name "PatternDate"
        if ($PatternDate -and $WFBSInfo.LastUpdate -eq "Unknown") {
            Write-DebugInfo "Found PatternDate in Misc - $PatternDate" "Green"
            try {
                if ($PatternDate -match '^\d{8}$') {
                    # Format: YYYYMMDD
                    $ParsedDate = [DateTime]::ParseExact($PatternDate, "yyyyMMdd", $null)
                    $WFBSInfo.LastUpdate = $ParsedDate.ToString("yyyy-MM-dd")
                    $WFBSInfo.SignatureAge = [math]::Round((Get-Date - $ParsedDate).TotalDays, 1)
                    Write-DebugInfo "WFBS signature date - $($WFBSInfo.LastUpdate) (Age: $($WFBSInfo.SignatureAge) days)" "Green"
                }
            } catch {
                Write-DebugInfo "Failed to parse WFBS pattern date - $PatternDate" "Yellow"
            }
        }

        # Fallback: Try Internet Settings path
        if ($WFBSInfo.LastUpdate -eq "Unknown") {
            $SigPath = "$RegPath\Internet Settings"
            $AltPatternDate = Get-RegistryValue -Path $SigPath -Name "PatternDate"
            if ($AltPatternDate) {
                Write-DebugInfo "Found PatternDate in Internet Settings - $AltPatternDate" "Gray"
                try {
                    if ($AltPatternDate -match '^\d{8}$') {
                        $ParsedDate = [DateTime]::ParseExact($AltPatternDate, "yyyyMMdd", $null)
                        $WFBSInfo.LastUpdate = $ParsedDate.ToString("yyyy-MM-dd")
                        $WFBSInfo.SignatureAge = [math]::Round((Get-Date - $ParsedDate).TotalDays, 1)
                        Write-DebugInfo "WFBS fallback signature date - $($WFBSInfo.LastUpdate) (Age: $($WFBSInfo.SignatureAge) days)" "Green"
                    }
                } catch {
                    Write-DebugInfo "Failed to parse fallback pattern date - $AltPatternDate" "Yellow"
                }
            }
        }
    }

    return $WFBSInfo
}

function Get-ClientServerInfo {
    Write-DebugInfo "Checking Client Server Security Agent configuration..." "Cyan"

    $RegistryPaths = @(
        "HKLM:\SOFTWARE\WOW6432Node\TrendMicro\PC-cillinNTCorp\CurrentVersion",
        "HKLM:\SOFTWARE\TrendMicro\PC-cillinNTCorp\CurrentVersion"
    )

    $CSInfo = @{
        Version = "Unknown"
        RealtimeProtection = 0
        SignatureAge = -1
        LastUpdate = "Unknown"
    }

    foreach ($RegPath in $RegistryPaths) {
        Write-DebugInfo "Checking registry path - $RegPath" "Gray"

        # Version information (combined from Misc and HostedAgent)
        $MiscPath = "$RegPath\Misc."
        $HostedPath = "$RegPath\HostedAgent"

        $ProgramVer = Get-RegistryValue -Path $MiscPath -Name "ProgramVer"
        $AgentVer = Get-RegistryValue -Path $HostedPath -Name "Version"

        if ($ProgramVer -or $AgentVer) {
            if ($ProgramVer -and $AgentVer) {
                $CSInfo.Version = "$ProgramVer (Agent: $AgentVer)"
            } elseif ($ProgramVer) {
                $CSInfo.Version = $ProgramVer
            } elseif ($AgentVer) {
                $CSInfo.Version = $AgentVer
            }
            Write-DebugInfo "Found Client Server version - $($CSInfo.Version)" "Green"
        }

        # Real-time protection
        $RTPath = "$RegPath\Real Time Scan Configuration"
        $RTEnabled = Get-RegistryValue -Path $RTPath -Name "Enable"
        if ($RTEnabled -ne $null -and $CSInfo.RealtimeProtection -eq 0) {
            $CSInfo.RealtimeProtection = [int]$RTEnabled
            Write-DebugInfo "Client Server Real-time protection - $RTEnabled" "Green"
        }

        # Signature information
        $PatternDate = Get-RegistryValue -Path $MiscPath -Name "PatternDate"
        $LastUpdateTime = Get-RegistryValue -Path $MiscPath -Name "LastUpdateTime"

        if ($PatternDate -and $CSInfo.LastUpdate -eq "Unknown") {
            try {
                $ParsedDate = [DateTime]::ParseExact($PatternDate, "yyyyMMdd", $null)
                $CSInfo.LastUpdate = $ParsedDate.ToString("yyyy-MM-dd")
                $CSInfo.SignatureAge = [math]::Round((Get-Date - $ParsedDate).TotalDays, 1)
                Write-DebugInfo "Client Server signature date - $($CSInfo.LastUpdate) (Age: $($CSInfo.SignatureAge) days)" "Green"
            } catch {
                Write-DebugInfo "Failed to parse Client Server pattern date - $PatternDate" "Yellow"
            }
        }

        if ($LastUpdateTime -and $CSInfo.LastUpdate -eq "Unknown") {
            try {
                $ParsedTime = [DateTime]::FromFileTime($LastUpdateTime)
                $CSInfo.LastUpdate = $ParsedTime.ToString("yyyy-MM-dd")
                $CSInfo.SignatureAge = [math]::Round((Get-Date - $ParsedTime).TotalDays, 1)
                Write-DebugInfo "Client Server last update time - $($CSInfo.LastUpdate) (Age: $($CSInfo.SignatureAge) days)" "Green"
            } catch {
                Write-DebugInfo "Failed to parse Client Server last update time - $LastUpdateTime" "Yellow"
            }
        }
    }

    return $CSInfo
}

function Determine-HealthStatus {
    param(
        [bool]$Installed,
        [bool]$ServiceRunning,
        [bool]$RealtimeProtection,
        [double]$SignatureAge
    )

    if (-not $Installed) {
        return "NOT_INSTALLED"
    }

    if (-not $ServiceRunning) {
        return "SERVICE_STOPPED"
    }

    if ($SignatureAge -gt 2 -and $SignatureAge -ne -1) {
        return "OUTDATED_SIGNATURES"
    }

    if (-not $RealtimeProtection) {
        return "REALTIME_DISABLED"
    }

    return "OK"
}

# Main execution
try {
    Write-DebugInfo "=== Trend Micro Universal Status Check Started ===" "Cyan"

    # Check installation paths
    $WFBSPaths = @(
        "C:\Program Files (x86)\Trend Micro\Security Agent",
        "C:\Program Files\Trend Micro\Security Agent"
    )

    $ClientServerPaths = @(
        "C:\Program Files (x86)\Trend Micro\Client Server Security Agent",
        "C:\Program Files\Trend Micro\Client Server Security Agent"
    )

    $WFBSInstalled = Test-InstallationPath -Paths $WFBSPaths
    $ClientServerInstalled = Test-InstallationPath -Paths $ClientServerPaths

    # Determine product type and get appropriate information
    if ($WFBSInstalled) {
        Write-DebugInfo "Detected product type - WFBS Agent" "Green"
        $TrendMicroStatus.product_type = "WFBS"
        $TrendMicroStatus.installed = 1

        $ProductInfo = Get-WFBSInfo
        $ServiceRunning = Test-TrendMicroService -ServiceName "ntrtscan"

    } elseif ($ClientServerInstalled) {
        Write-DebugInfo "Detected product type - Client Server Security Agent" "Green"
        $TrendMicroStatus.product_type = "Client_Server"
        $TrendMicroStatus.installed = 1

        $ProductInfo = Get-ClientServerInfo
        $ServiceRunning = Test-TrendMicroService -ServiceName "ntrtscan"

    } else {
        Write-DebugInfo "No Trend Micro installation detected" "Red"
        $TrendMicroStatus.health_status = "NOT_INSTALLED"
        $ProductInfo = @{
            Version = "Unknown"
            RealtimeProtection = 0
            SignatureAge = -1
            LastUpdate = "Unknown"
        }
        $ServiceRunning = $false
    }

    # Update status object
    $TrendMicroStatus.version = $ProductInfo.Version
    $TrendMicroStatus.service_running = if ($ServiceRunning) { 1 } else { 0 }
    $TrendMicroStatus.realtime_protection = $ProductInfo.RealtimeProtection
    $TrendMicroStatus.signature_age = $ProductInfo.SignatureAge
    $TrendMicroStatus.last_update = $ProductInfo.LastUpdate

    # Determine final health status
    if ($TrendMicroStatus.installed -eq 1) {
        $TrendMicroStatus.health_status = Determine-HealthStatus -Installed $true -ServiceRunning $ServiceRunning -RealtimeProtection ($ProductInfo.RealtimeProtection -eq 1) -SignatureAge $ProductInfo.SignatureAge
    }

    Write-DebugInfo "=== Final Status ===" "Cyan"
    Write-DebugInfo "Product Type: $($TrendMicroStatus.product_type)" "White"
    Write-DebugInfo "Health Status: $($TrendMicroStatus.health_status)" "White"
    Write-DebugInfo "Version: $($TrendMicroStatus.version)" "White"
    Write-DebugInfo "Installed: $($TrendMicroStatus.installed)" "White"
    Write-DebugInfo "Service Running: $($TrendMicroStatus.service_running)" "White"
    Write-DebugInfo "Realtime Protection: $($TrendMicroStatus.realtime_protection)" "White"
    Write-DebugInfo "Signature Age: $($TrendMicroStatus.signature_age)" "White"
    Write-DebugInfo "Last Update: $($TrendMicroStatus.last_update)" "White"

} catch {
    Write-DebugInfo "Critical error occurred: $($_.Exception.Message)" "Red"
    $TrendMicroStatus.health_status = "ERROR"
}

# Output JSON for TRMM
$JsonOutput = $TrendMicroStatus | ConvertTo-Json -Compress
Write-Output $JsonOutput

Write-DebugInfo "=== Trend Micro Universal Status Check Completed ===" "Cyan"
