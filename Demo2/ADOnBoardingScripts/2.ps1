# Define variables
$LogFile = "C:\mdm_agent_autoupdater_log.txt"
$ServiceName = "MDMAgentUpdater"
$InstallPath = "C:\ProgramData\PligencePortal"
$ExeName = "mdm-agent-autoupdater.exe"
$DownloadUrl = "https://github.com/Pligence/LGPO_Backups/raw/refs/heads/main/windows-mdm-agent-autoupdate.exe"
$ExePath = Join-Path $InstallPath $ExeName

# Logging function
function Write-Log {
    param (
        [string]$Message
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$Timestamp - $Message" | Tee-Object -FilePath $LogFile -Append
}

# Ensure install directory exists
try {
    if (-not (Test-Path $InstallPath)) {
        Write-Log "Creating install directory: $InstallPath"
        New-Item -Path $InstallPath -ItemType Directory -Force | Out-Null
    }
} catch {
    Write-Log "ERROR: Failed to create directory $InstallPath - $_"
    exit 1
}

# Check if service is already installed
try {
    if (Get-Service -Name $ServiceName -ErrorAction SilentlyContinue) {
        Write-Log "Service '$ServiceName' is already installed. Exiting."
        exit 0
    }
} catch {
    Write-Log "ERROR: Failed to check existing services - $_"
    exit 1
}

# Check if the EXE exists
if (-not (Test-Path $ExePath)) {
    try {
        Write-Log "Executable not found. Downloading $ExeName from $DownloadUrl"
        Invoke-WebRequest -Uri $DownloadUrl -OutFile $ExePath -UseBasicParsing -ErrorAction Stop
        Write-Log "Downloaded successfully to $ExePath"
    } catch {
        Write-Log "ERROR: Failed to download the file - $_"
        exit 1
    }
} else {
    Write-Log "Executable already exists at $ExePath"
}

# Install the service using the EXE
try {
    Write-Log "Installing service using $ExeName"
    $InstallResult = Start-Process -FilePath $ExePath -ArgumentList "install" -Wait -NoNewWindow -PassThru

    if ($InstallResult.ExitCode -eq 0) {
        Write-Log "Service installation completed successfully."
    } else {
        Write-Log "ERROR: Service installation failed with exit code $($InstallResult.ExitCode)"
        exit 1
    }
} catch {
    Write-Log "ERROR: Exception occurred while installing the service - $_"
    exit 1
}

# Start the service
try {
    Write-Log "Starting service '$ServiceName'"
    Start-Service -Name $ServiceName -ErrorAction Stop
    Start-Sleep -Seconds 3  # Wait a bit for status to settle

    $ServiceStatus = (Get-Service -Name $ServiceName).Status
    if ($ServiceStatus -eq 'Running') {
        Write-Log "Service '$ServiceName' started successfully."
    } else {
        Write-Log "ERROR: Service '$ServiceName' failed to start. Status: $ServiceStatus"
        exit 1
    }
} catch {
    Write-Log "ERROR: Exception occurred while starting the service - $_"
    exit 1
}