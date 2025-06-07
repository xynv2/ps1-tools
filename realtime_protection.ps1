Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Is-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p = New-Object Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Disable-RealTimeProtection {
    try {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Force | Out-Null
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -Value 1 -Type DWord

        $rtp = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection"
        New-Item -Path $rtp -Force | Out-Null
        Set-ItemProperty -Path $rtp -Name "DisableRealtimeMonitoring" -Value 1 -Type DWord
        Set-ItemProperty -Path $rtp -Name "DisableBehaviorMonitoring" -Value 1 -Type DWord
        Set-ItemProperty -Path $rtp -Name "DisableOnAccessProtection" -Value 1 -Type DWord

        return $true
    } catch {
        return $false
    }
}

function Enable-RealTimeProtection {
    try {
        Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -ErrorAction SilentlyContinue
        Remove-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Recurse -Force -ErrorAction SilentlyContinue
        return $true
    } catch {
        return $false
    }
}

function Is-ProtectionDisabled {
    try {
        $val = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -ErrorAction SilentlyContinue
        return ($val -eq 1)
    } catch {
        return $false
    }
}

# GUI setup
$form = New-Object Windows.Forms.Form
$form.Text = "Defender Real-Time Toggle"
$form.Size = New-Object Drawing.Size(420, 200)
$form.StartPosition = "CenterScreen"
$form.BackColor = [Drawing.Color]::FromArgb(25, 25, 25)
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.TopMost = $true

$label = New-Object Windows.Forms.Label
$label.ForeColor = [Drawing.Color]::White
$label.Font = New-Object Drawing.Font("Segoe UI", 10)
$label.AutoSize = $true
$label.Location = New-Object Drawing.Point(30, 30)
$form.Controls.Add($label)

$toggleButton = New-Object Windows.Forms.Button
$toggleButton.Size = New-Object Drawing.Size(340, 40)
$toggleButton.Location = New-Object Drawing.Point(35, 80)
$toggleButton.BackColor = [Drawing.Color]::FromArgb(50, 50, 50)
$toggleButton.FlatStyle = "Flat"
$toggleButton.Font = New-Object Drawing.Font("Segoe UI", 10)
$form.Controls.Add($toggleButton)

function RefreshGUI {
    if (Is-ProtectionDisabled) {
        $label.Text = "Real-Time Protection is OFF (Blocked)"
        $toggleButton.Text = "Enable Protection"
        $toggleButton.ForeColor = [Drawing.Color]::LimeGreen
    } else {
        $label.Text = "Real-Time Protection is ON"
        $toggleButton.Text = "Disable Protection"
        $toggleButton.ForeColor = [Drawing.Color]::OrangeRed
    }
}

$toggleButton.Add_Click({
    if (-not (Is-Admin)) {
        [System.Windows.Forms.MessageBox]::Show("Run as Administrator.","Permission Denied",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }

    if (Is-ProtectionDisabled) {
        if (Enable-RealTimeProtection) {
            [System.Windows.Forms.MessageBox]::Show("Protection has been re-enabled.","Enabled",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
        }
    } else {
        if (Disable-RealTimeProtection) {
            [System.Windows.Forms.MessageBox]::Show("Protection has been disabled and cannot be turned back on from Windows UI.","Disabled",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
        }
    }
    RefreshGUI
})

RefreshGUI
$form.ShowDialog()
