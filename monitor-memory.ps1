# ==========================================
# Configuration Settings
# Only for Windows and use PowerShell Scripts
# ==========================================
$ThresholdPercent = 80

# SMTP Configuration
$SMTPServer  = "smtp.gmail.com"
$SMTPPort    = 587
$FromAddress = "thinstreet.ms@gmail.com"
$ToAddress   = "martinussinaga@ymail.com"
$Username    = "thinstreet.ms@gmail.com"
$Password    = "Password :)" 

# ==========================================
# Memory Check
# ==========================================
$OS = Get-CimInstance -ClassName Win32_OperatingSystem
$TotalRAM = $OS.TotalVisibleMemorySize
$FreeRAM = $OS.FreePhysicalMemory
$UsedRAM = $TotalRAM - $FreeRAM

$UsedPercent = [math]::Round(($UsedRAM / $TotalRAM) * 100, 2)
$UsedGB      = [math]::Round($UsedRAM / 1MB, 2)
$TotalGB     = [math]::Round($TotalRAM / 1MB, 2)

if ($UsedPercent -ge $ThresholdPercent) {

    # Fetch Top 5 processes consuming memory
    $TopProcesses = Get-Process | 
        Sort-Object -Property WorkingSet64 -Descending | 
        Select-Object -First 5 -Property Name, @{Name="RAM_MB"; Expression={[math]::Round($_.WorkingSet64 / 1MB, 2)}} | 
        Out-String

    # Build Email Body
    $Subject = "⚠️ HIGH MEMORY ALERT: $env:COMPUTERNAME at $UsedPercent% Usage"
    $Body = @"
High Memory Usage Detected on Server: $env:COMPUTERNAME
Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

--------------------------------------------------
Memory Details:
--------------------------------------------------
Used RAM:  $UsedGB GB / $TotalGB GB ($UsedPercent%)
Threshold: $ThresholdPercent%

--------------------------------------------------
Top 5 Memory-Consuming Processes:
--------------------------------------------------
$TopProcesses
"@

    # Send Email via MailMessage / SmtpClient (.NET method)
    try {
        $SecPassword = ConvertTo-SecureString $Password -AsPlainText -Force
        $Credential  = New-Object System.Management.Automation.PSCredential ($Username, $SecPassword)

        $Mail = New-Object System.Net.Mail.MailMessage
        $Mail.From = $FromAddress
        $Mail.To.Add($ToAddress)
        $Mail.Subject = $Subject
        $Mail.Body = $Body

        $Smtp = New-Object System.Net.Mail.SmtpClient($SMTPServer, $SMTPPort)
        $Smtp.EnableSsl = $true
        $Smtp.Credentials = $Credential
        
        $Smtp.Send($Mail)
        Write-Output "Alert email sent successfully."
    }
    catch {
        Write-Error "Failed to send email: $_"
    }

} else {
    Write-Output "Memory usage normal: $UsedPercent%"
}
