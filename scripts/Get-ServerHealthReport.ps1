#requires -Version 5.1

<#
.SYNOPSIS
    Checks the basic health of a Windows Server.

.DESCRIPTION
    Collects CPU, memory, disk, uptime, and service information.
    Results are displayed in PowerShell and exported to a CSV file.
#>

[CmdletBinding()]
param(
    [string]$OutputPath = (
        Join-Path `
            (Split-Path -Parent $PSScriptRoot) `
            "ServerHealthReport.csv"
    ),

    [int]$DiskWarningPercent = 20,

    [string[]]$ServicesToCheck = @(
        "EventLog",
        "LanmanServer",
        "W32Time",
        "WinRM"
    )
)

$ErrorActionPreference = "Stop"
$results = @()
$checkedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

try {
    Write-Host "Checking server health..." -ForegroundColor Cyan

    # Basic system information
    $operatingSystem = Get-CimInstance Win32_OperatingSystem
    $processor = Get-CimInstance Win32_Processor

    $uptime = (Get-Date) - $operatingSystem.LastBootUpTime
    $cpuUsage = [math]::Round(
        ($processor | Measure-Object LoadPercentage -Average).Average,
        2
    )

    $memoryUsedPercent = [math]::Round(
        (
            ($operatingSystem.TotalVisibleMemorySize -
                $operatingSystem.FreePhysicalMemory) /
            $operatingSystem.TotalVisibleMemorySize
        ) * 100,
        2
    )

    $results += [PSCustomObject]@{
        Category = "System"
        Item = "Computer Name"
        Value = $env:COMPUTERNAME
        Status = "Information"
        CheckedAt = $checkedAt
    }

    $results += [PSCustomObject]@{
        Category = "System"
        Item = "Uptime"
        Value = "$($uptime.Days) days, $($uptime.Hours) hours"
        Status = "Information"
        CheckedAt = $checkedAt
    }

    $results += [PSCustomObject]@{
        Category = "Performance"
        Item = "CPU Usage"
        Value = "$cpuUsage%"
        Status = if ($cpuUsage -ge 85) { "Warning" } else { "Healthy" }
        CheckedAt = $checkedAt
    }

    $results += [PSCustomObject]@{
        Category = "Performance"
        Item = "Memory Used"
        Value = "$memoryUsedPercent%"
        Status = if ($memoryUsedPercent -ge 85) { "Warning" } else { "Healthy" }
        CheckedAt = $checkedAt
    }

    # Check local disk space
    $disks = Get-CimInstance Win32_LogicalDisk |
        Where-Object { $_.DriveType -eq 3 }

    foreach ($disk in $disks) {
        $freePercent = [math]::Round(
            ($disk.FreeSpace / $disk.Size) * 100,
            2
        )

        $results += [PSCustomObject]@{
            Category = "Disk"
            Item = $disk.DeviceID
            Value = "$freePercent% free"
            Status = if ($freePercent -lt $DiskWarningPercent) {
                "Warning"
            }
            else {
                "Healthy"
            }
            CheckedAt = $checkedAt
        }
    }

    # Check important Windows services
    foreach ($serviceName in $ServicesToCheck) {
        $service = Get-Service `
            -Name $serviceName `
            -ErrorAction SilentlyContinue

        $results += [PSCustomObject]@{
            Category = "Service"
            Item = $serviceName
            Value = if ($service) { $service.Status } else { "Not found" }
            Status = if ($service -and $service.Status -eq "Running") {
                "Healthy"
            }
            else {
                "Warning"
            }
            CheckedAt = $checkedAt
        }
    }

    $results |
        Format-Table Category, Item, Value, Status -AutoSize

    $results |
        Export-Csv `
            -LiteralPath $OutputPath `
            -NoTypeInformation `
            -Encoding UTF8

    Write-Host "`nReport saved to: $OutputPath" -ForegroundColor Green
}
catch {
    Write-Error "Server health check failed: $($_.Exception.Message)"
}
