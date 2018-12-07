# -----------------------------------------------------------------------------
# Script: Advanced08_2012.ps1
# Author: Jason Hofferle
# Date: 04/16/2012
# Comments:
#  This script enables and disables network adapters. It checks to ensure it is
#  running with admin rights, and that it is running on a laptop. The default
#  condition is to toggle each adapter when only one is enabled or disabled.
#  When multiple enabled/disabled adapters are found, a menu is displayed and
#  the user is prompted for which one to enable or disable.
# -----------------------------------------------------------------------------

[CmdletBinding()]
Param()

Function Enable-NetworkAdapter
{
    Param($NetworkAdapter)
    try
    {
        Write-Verbose "Enabling $($NetworkAdapter.Name)"
        $ReturnValue = ($NetworkAdapter.Enable()).ReturnValue
    }
    catch
    {
        Write-Warning $_
    }

    if ($ReturnValue -eq 0)
    {
        # Short pause to give adapter a chance to enable, so that
        # menu re-display will reflect change.
        Start-Sleep -Seconds 5
        Write-Verbose "Successfully enabled $($NetworkAdapter.Name)"
    }
    else
    {
        Write-Warning "Enabling $($NetworkAdapter.Name) returned $ReturnValue"
    }

}

Function Disable-NetworkAdapter
{
    Param($NetworkAdapter)
    try
    {
        Write-Verbose "Disabling $($NetworkAdapter.Name)"
        $ReturnValue = ($NetworkAdapter.Disable()).ReturnValue
    }
    catch
    {
        Write-Warning $_
    }

    if ($ReturnValue -eq 0)
    {
        Write-Verbose "Successfully disabled $($NetworkAdapter.Name)"
    }
    else
    {
        Write-Warning "Disabling $($NetworkAdapter.Name) returned $ReturnValue"
    }
}

Function Test-Laptop
{
    $IsLaptop = $null
    try
    {
        if ( (Get-WmiObject -Class Win32_Battery) -eq $null)
        {
            $IsLaptop = $false
        }
        else
        {
            $IsLaptop = $true
        }
        return $IsLaptop
    }
    catch
    {
        Write-Warning "Unable to make WMI Query for Test-Laptop"
        Write-Debug ($_ | Out-String)
    }
}

# Test for admin credentials.
$Identity = [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
if (-not ($Identity.IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")))
{
    Write-Warning "You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator!"
    break
}

# Test for laptop.
if (-not (Test-Laptop))
{
    Write-Warning "This script can only be run on laptop computers."
    break
}

# Enable/disable methods require Vista or above.
if ([System.Environment]::OSVersion.Version.Major -lt 6)
{
    Write-Warning "This script can only be run on Vista or above."
    break
}

$EnabledAdapters = @(Get-WmiObject -Class Win32_NetworkAdapter -Filter "NetEnabled = 'True'")
$DisabledAdapters = @(Get-WmiObject -Class Win32_NetworkAdapter -Filter "NetEnabled = 'False'")
Write-Verbose "There are $($EnabledAdapters.Count) enabled and $($DisabledAdapters.Count) disabled adapters."

# Default condition of one enabled adapter and one disabled adapter.
if ( ($EnabledAdapters.Count -eq 1) -and ($DisabledAdapters.Count -eq 1) )
{
    $EnabledAdapters | ForEach-Object {Disable-NetworkAdapter $_}
    $DisabledAdapters | ForEach-Object {Enable-NetworkAdapter $_}
}
else
{
    # If more than one adapter is enabled or disabled, enter menu loop.
    Do {
        $Adapters = @(Get-WmiObject -Class Win32_NetworkAdapter | Where-Object {$_.NetEnabled -ne $Null})
        $Choices = @()

        foreach ($Adapter in $Adapters)
        {
            # Add a choice description for each adapter.
            $Choices += New-Object System.Management.Automation.Host.ChoiceDescription "$($Adapter.DeviceId)","$($Adapter.Name)"
        }

        # Add the quit option to the array of choices.
        $Choices += New-Object System.Management.Automation.Host.ChoiceDescription "&Quit","Quit"

        # The quit option will be the last index in the array, and will be the default.
        $Default = $Choices.Count - 1

        # Present a menu of adapters.
        $Adapters |
            Select-Object DeviceID, @{Name='Enabled';Expression={$_.NetEnabled}},Name |
            Format-Table -AutoSize

        # Prompt user for device to toggle.
        $Title = "Enable/Disable Network Interface"
        $Message = "Select Device Id of Interface to Toggle"
        $Options = [System.Management.Automation.Host.ChoiceDescription[]]($Choices)
        $Selection = $host.ui.PromptForChoice($Title, $Message, $Options, $Default)

        if ($Selection -ne $Default)
        {
            # Get the current condition of the selected adapter and enable/disable.
            if ($Adapters[$Selection].NetEnabled)
            {
                Disable-NetworkAdapter ($Adapters[$Selection])
            }
            else
            {
                Enable-NetworkAdapter ($Adapters[$Selection])
            }
        }
    }
    Until ($Selection -eq $Default)
}
