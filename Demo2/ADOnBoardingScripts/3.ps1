 
# ===============================
# Function: Structured JSON Logger
# ===============================
function Write-JsonLog {
    param (
        [string]$Level = "Info",
        [string]$Message,
        [hashtable]$AdditionalData = @{}
    )
 
    $logObject = @{
        timestamp = (Get-Date).ToString("o")
        level     = $Level
        message   = $Message
    }
 
    foreach ($key in $AdditionalData.Keys) {
        $logObject[$key] = $AdditionalData[$key]
    }
 
    Write-Host ($logObject | ConvertTo-Json -Compress)
}
 
function Write-ScriptOutput {
    param (
        [string]$Message,
        [hashtable]$Additional = @{},
        [bool]$IsError = $false
    )
    Write-Host "script_required_output_start"
    $output = @{ message = $Message }
    if ($IsError) {
        $output.status = $true
    } else {
        foreach ($k in $Additional.Keys) {
            $output[$k] = $Additional[$k]
        }
    }
    Write-Host ($output | ConvertTo-Json -Compress)
    Write-Host "script_required_output_end"
}
 
# ===============================
# Configurable Inputs
# ===============================
$downloadUrl = "https://github.com/Pligence/LGPO_Backups/raw/refs/heads/main/PligenceAgent.zip"
$tempZipPath = "$env:TEMP\PligenceAgent.zip"
$extractPath = "$env:TEMP\PligenceExtracted"
 
try {
    Write-JsonLog -Message "Starting download..." -Level "Info"
    Invoke-WebRequest -Uri $downloadUrl -OutFile $tempZipPath -UseBasicParsing
    Write-JsonLog -Message "Download complete." -Level "Info"
}
catch {
    Write-ScriptOutput -Message "Failed to download MSI zip: $_" -IsError $true
    exit 1
}
 
# ===============================
# Extract the Zip File
# ===============================
try {
    Expand-Archive -Path $tempZipPath -DestinationPath $extractPath -Force
    Write-JsonLog -Message "Extraction complete." -Level "Info"
}
catch {
    Write-ScriptOutput -Message "Failed to extract MSI zip: $_" -IsError $true
    exit 1
}
 
# ===============================
# Find the MSI and Install It
# ===============================
$msiPath = Get-ChildItem -Path $extractPath -Filter *.msi -Recurse | Select-Object -First 1
 
if (-not $msiPath) {
    Write-ScriptOutput -Message "No MSI found after extraction." -IsError $true
    exit 1
}
 
try {
    $arguments = "/i `"$($msiPath.FullName)`" ALLUSERS=1 /quiet /norestart"
    Write-JsonLog -Message "Starting MSI install with args: $arguments" -Level "Info"
    Start-Process -FilePath "msiexec.exe" -ArgumentList $arguments -Wait -NoNewWindow
    Write-ScriptOutput -Message "PligenceAgent installed successfully." -Additional @{ msi_path = $msiPath.FullName }
}
catch {
    Write-ScriptOutput -Message "MSI installation failed: $_" -IsError $true
    exit 1
}
 
 