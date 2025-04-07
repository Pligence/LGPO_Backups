$LogFile = "C:\Pligence_setup_log.txt"
$ServiceName = "MDMAgent"
$InstallPath = "C:\ProgramData\PligencePortal"
$FilesRequired = @('ConfigData.enc', 'mdm-agent.exe')   
$DownloadUrl = "https://raw.githubusercontent.com/Pligence/LGPO_Backups/refs/heads/main/PligencePortal.zip" 
$DownloadPath = "C:\ProgramData\PligencePortal.zip"
$DataConfigPath = "$InstallPath\DataConfig.txt"

# Configuration parameters
$DataConfig = @{
    mdm_server_url = "wss://test.pligenceconnect.com:8090/ws"
    api_base_url = "https://test.pligenceconnect.com:8089"
    dump_api_url = "/api/devices/dump-device-connect-params/"
    api_key = "B_0hxujckw5E3Vae"
    is_signed_in = $true
    token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoiYWNjZXNzIiwiZXhwIjoxNzQxNjg2MTk1LCJpYXQiOjE3NDAzOTAxOTUsImp0aSI6IjVlZGI4ZTU4MDI1YjQ0NDZiZTgxNTIwYmFkMzdmODk0IiwidXNlcl9pZCI6MTg2fQ.6q_kpHOLTyNhOxWhPIvpY_wuN6Hd_5AWRsPR8ebXVFE"
    refresh_token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTc0MDQ3NjU5NSwiaWF0IjoxNzQwMzkwMTk1LCJqdGkiOiI1OWIzYzIwMjVkMDQ0NWQ5OTRiZjQxMjk1NmFmNjQ2NiIsInVzZXJfaWQiOjE4Nn0.Y8OZdIAqYTXszG_jDSksGCORDssevjbev-BiJTMj2EQ"
    agent_uuid = "E5E94933-F332-4183-B9F5-CCA717A8C887"
    is_registered = $true
} | ConvertTo-Json -Depth 10

Function Write-Log {
    param (
        [string]$Message
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$Timestamp - $Message" | Tee-Object -FilePath $LogFile -Append
}

# Check if service exists
if (Get-Service -Name $ServiceName -ErrorAction SilentlyContinue) {
    Write-Log "Service '$ServiceName' is already installed. Exiting."
    exit 0
}

# Check if directory exists
if (-Not (Test-Path $InstallPath)) {
    Write-Log "Directory $InstallPath does not exist. Downloading required files."
    $NeedDownload = $true
} else {
    # Check if all required files exist
    $MissingFiles = $FilesRequired | Where-Object { -Not (Test-Path "$InstallPath\$_") }
    if ($MissingFiles) {
        Write-Log "Missing files detected: $($MissingFiles -join ', '). Downloading required files."
        $NeedDownload = $true
    } else {
        Write-Log "All required files are present. Proceeding with service installation."
        $NeedDownload = $false
    }
}

# Download and extract if necessary
if ($NeedDownload) {
    if (Test-Path $InstallPath) {
        Write-Log "Removing existing directory: $InstallPath"
        Remove-Item -Path $InstallPath -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    Write-Log "Downloading PligencePortal.zip via BITS."
    Start-BitsTransfer -Source $DownloadUrl -Destination $DownloadPath -ErrorAction Stop
    
    Write-Log "Extracting downloaded archive."
    Expand-Archive -Path $DownloadPath -DestinationPath "C:\ProgramData" -Force
    Remove-Item $DownloadPath -Force
}

# # Create DataConfig.txt file
# Write-Log "Creating DataConfig.txt file."
# $DataConfig | Out-File -FilePath $DataConfigPath -Encoding utf8

# Install the service
Write-Log "Installing service using mdm-agent.exe."
$InstallResult = Start-Process -FilePath "$InstallPath\mdm-agent.exe" -ArgumentList "install" -Wait -NoNewWindow -PassThru
if ($InstallResult.ExitCode -eq 0) {
    Write-Log "Service installation successful."
} else {
    Write-Log "Service installation failed with exit code $($InstallResult.ExitCode)."
    exit 1
}

# Start the service
Write-Log "Starting service $ServiceName."
Start-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ((Get-Service -Name $ServiceName).Status -eq 'Running') {
    Write-Log "Service $ServiceName started successfully."
} else {
    Write-Log "Failed to start service $ServiceName."
    exit 1
}



# Note : remove LGPO....