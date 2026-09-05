# Windows Server Health Monitor

A PowerShell script that checks basic Windows system health and exports the results to a CSV report.

## Why I built this

When supporting Windows systems, administrators often check the same areas repeatedly: CPU usage, memory usage, available disk space, uptime, and important services.

This project combines those checks into one script so potential issues can be identified more quickly and documented consistently.

## Current checks

- Computer name
- System uptime
- CPU utilization
- Memory utilization
- Available disk space
- Status of important Windows services
- Healthy and warning status for each result
- CSV report generation

## Repository structure

```text
windows-server-health-monitor/
├── scripts/
│   └── Get-ServerHealthReport.ps1
├── .gitignore
├── LICENSE
└── README.md
```

## Requirements

- Windows PowerShell 5.1 or later
- Windows Server or Windows 10/11
- Permission to query local system information and services

The current version performs read-only health checks and does not modify system configuration.

## Usage

Open PowerShell from the repository folder and run:

```powershell
.\scripts\Get-ServerHealthReport.ps1
```

The results are displayed in PowerShell and exported to:

```text
ServerHealthReport.csv
```

## Example output

```text
Category     Item           Value            Status
System       Computer Name  SERVER-01        Information
System       Uptime         4 days, 6 hours  Information
Performance  CPU Usage      12%              Healthy
Performance  Memory Used    61%              Healthy
Disk         C:             48% free         Healthy
Service      WinRM          Running          Healthy
```

## Default thresholds

- CPU usage of 85% or higher: `Warning`
- Memory usage of 85% or higher: `Warning`
- Free disk space below 20%: `Warning`
- Missing or stopped monitored service: `Warning`

The disk threshold and service list can be changed through script parameters.

## Example with custom settings

```powershell
.\scripts\Get-ServerHealthReport.ps1 `
    -DiskWarningPercent 25 `
    -ServicesToCheck "EventLog", "W32Time", "WinRM"
```

## Roadmap

- [x] Basic Windows health checks
- [x] CSV report export
- [ ] Recent Windows event-log errors
- [ ] Pending restart detection
- [ ] HTML health dashboard
- [ ] Remote server support

## Security note

Generated reports are excluded through `.gitignore` because they may contain computer names and operational information. Review all output before sharing it publicly.
