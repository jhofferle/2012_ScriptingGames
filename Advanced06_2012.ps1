# -----------------------------------------------------------------------------
# Script: Advanced06_2012.ps1
# Author: Jason Hofferle
# Date: 04/12/2012
# Comments:
#  This advanced function uses features in PowerShell 3.0 to compute the
#  uptime for multiple computers. It generates a csv report in the current
#  user's Documents folder with the date and "_Uptime" as the file name.
#  When run multiple times in a single day, additional output is
#  appended to the file.
# -----------------------------------------------------------------------------

Function Get-ServerUptime
{
    [CmdletBinding()]

    Param
    (
        [Parameter(
        ValueFromPipeLine = $True,
        ValueFromPipeLineByPropertyName = $True)]
        [string[]]
        $ComputerName = $Env:ComputerName,

        $Path = "$([System.Environment]::GetFolderPath("MyDocuments"))\$(get-date -Format yyyyMMdd)_Uptime.csv",

        [switch]
        $PassThru
    )

    Begin
    {
        if ($PSVersionTable.PSVersion.Major -lt 3)
        {
            Write-Warning "This script uses PowerShell 3.0 features."
            break
        }

        $MorningCutOff = Get-Date -Hour 08 -Minute 00 -Second 00 -Millisecond 00
    }

    Process
    {
        foreach ($Computer in $ComputerName)
        {
            Write-Verbose "Computer: $Computer"
            try
            {
                $OS = Get-WmiObject -ComputerName $Computer -Class Win32_OperatingSystem -ErrorAction Stop
            }
            catch
            {
                Write-Warning "$Computer : $_"
                continue
            }
            $LastBoot = $OS.ConvertToDateTime($OS.LastBootUpTime)
            Write-Verbose "Last Boot Time: $LastBoot"

            $Uptime = $MorningCutOff - $LastBoot
            Write-Verbose "Uptime: $Uptime"

            # Check for negative uptime, indicating server was rebooted after
            # the cutoff time, but before the script ran.
            if ($Uptime.Ticks -lt 0)
            {
                $Uptime = $LastBoot - $LastBoot
            }

            # Using PSCustomObject for speed and to preserve insertion order.
            $Object = [PSCustomObject]@{
                ComputerName = $Computer
                Days = $Uptime.Days
                Hours = $Uptime.Hours
                Minutes = $Uptime.Minutes
                Seconds = $Uptime.Seconds
                Date = $LastBoot.ToShortDateString()
            }

            try
            {
                $Object | Export-Csv -Path $Path -Append -NoTypeInformation
                Write-Verbose "Results written to $Path"
            }
            catch
            {
                Write-Warning $_
            }

            if ($PassThru)
            {
                Write-Output $Object
            }
        }
    }

    End
    {
    }

    <#

    .Synopsis
    Computes uptime for one or more servers.

    .Description
    Retrieves the last boot time from specified computers and computes
    the uptime as of 8:00 AM local time, saving the results to a csv file.

    .parameter ComputerName
    Specifies the computers on which the command runs. The default is
    the local computer.

    .parameter Path
    Specifies the path to the output file. The default is to create a temporary
    file with the date in the current user's Documents folder.

    .parameter PassThru
    Returns an object for each computer. By default, no output is
    generated.

    .Example
    Get-ServerUptime

    Description
    -----------
    This command computes uptime for the local computer and saves the results
    to a yyyyMMdd_Uptime.csv file in the current user's Documents folder.

    .Example
    Get-ServerUptime -Path $Env:UserProfile\Desktop\report.csv

    Description
    -----------
    This command computes uptime for the local computer and saves the results
    to report.csv on the current user's desktop.

    .Example
    "Comp01","Comp02","Comp03" | Get-ServerUptime -PassThru

    Description
    -----------
    This command computers uptime for the computer names specified, saves the
    results to the default file location, and displays output.

    #>
}
