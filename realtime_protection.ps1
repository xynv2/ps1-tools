Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Get-DefenderStatus {
    try {
        $status = Get-MpPreference
        return -not $status.DisableRealtimeMonitoring
    } catch {
        return $null
    }
}

function Set-DefenderStatus($enabled) {
    try {
        Set-MpPreference -DisableRealtimeMonitoring (!$enabled)
        return $true
    } catch {
        return $false
    }
}

# Form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Windows Defender Toggle"
$form.Size = New-Object System.Drawing.Size(360, 180)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.TopMost = $true

# Label
$label = New-Object System.Windows.Forms.Label
$label.Size = New-Object System.Drawing.Size(320, 30)
$label.Location = New-Object System.Drawing.Point(20, 20)
$label.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$label.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($label)

# Button
$toggleButton = New-Object System.Windows.Forms.Button
$toggleButton.Size = New-Object System.Drawing.Size(300, 40)
$toggleButton.Location = New-Object System.Drawing.Point(30, 80)
$toggleButton.BackColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
$toggleButton.ForeColor = [System.Drawing.Color]::Lime
$toggleButton.FlatStyle = "Flat"
$toggleButton.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
$form.Controls.Add($toggleButton)

function RefreshStatus {
    $status = Get-DefenderStatus
    if ($status -eq $true) {
        $label.Text = "Protection is ENABLED"
        $toggleButton.Text = "Disable Real-Time Protection"
        $toggleButton.ForeColor = [System.Drawing.Color]::OrangeRed
    } elseif ($status -eq $false) {
        $label.Text = "Protection is DISABLED"
        $toggleButton.Text = "Enable Real-Time Protection"
        $toggleButton.ForeColor = [System.Drawing.Color]::LimeGreen
    } else {
        $label.Text = "Failed to get status"
        $toggleButton.Text = "Try Again"
        $toggleButton.ForeColor = [System.Drawing.Color]::Gray
    }
}

$toggleButton.Add_Click({
    $cur = Get-DefenderStatus
    if ($cur -ne $null) {
        $success = Set-DefenderStatus(-not $cur)
        if ($success) {
            Start-Sleep -Milliseconds 600
            RefreshStatus
        } else {
            [System.Windows.Forms.MessageBox]::Show("Failed to change protection. Are you running as Administrator?","Error")
        }
    }
})

RefreshStatus
$form.ShowDialog()
