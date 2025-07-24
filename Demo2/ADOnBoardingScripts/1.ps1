$LogFile = "C:\setup_log.txt"
$ServiceName = "MDMAgent"
$InstallPath = "C:\ProgramData\PligencePortal"
$FilesRequired = @('ConfigData.enc', 'LGPO.exe', 'mdm-agent.exe')
$DownloadUrl = "https://github.com/Pligence/LGPO_Backups/raw/refs/heads/main/Demo2/PligencePortal.zip"  # Replace with actual URL
$DownloadPath = "C:\ProgramData\PligencePortal.zip"
 
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