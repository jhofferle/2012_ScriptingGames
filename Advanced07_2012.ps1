# -----------------------------------------------------------------------------
# Script: Advanced07_2012.ps1
# Author: Jason Hofferle
# Date: 04/16/2012
# Comments:
#  This script displays crucial information for the most recent one-event log
#  entry from each event log and troubleshooting log that is enabled and has
#  at least one entry in it. The "MaxEvents" parameter of Get-WinEvent is a
#  very quick way to retrieve the most recent event from the majority of logs.
#  The Debug and Analytical logs cannot use this method because they require
#  the "Oldest" parameter, so their entries must be sorted in order to
#  retrieve the most recent event.
# -----------------------------------------------------------------------------

[CmdletBinding()]
Param()

$Identity = [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
if (-not ($Identity.IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")))
{
    Write-Warning "You do not have Administrator rights! Some events may not be displayed."
}

# Get a list of all logs that are enabled and have records. RecordCount is
# compared to 0 so that null RecordCount from Debug/Analytical logs are included.
$EnabledLogs = Get-WinEvent -ListLog * -Force -ErrorAction SilentlyContinue |
    Where-Object {($_.IsEnabled) -and ($_.RecordCount -ne 0)}

$Results = @()

foreach ($Log in $EnabledLogs)
{
    Write-Verbose $Log.LogName

    try
    {
        # Administrative and Operational logs can use the MaxEvents parameter
        # to get the most recent event. Debug and Analytical logs must use the
        # Oldest parameter and be sorted to get the most recent event.
        if ( ($Log.LogType -eq 'Administrative') -or ($Log.LogType -eq 'Operational') )
        {
            $Results += Get-WinEvent -LogName $Log.LogName -MaxEvents 1 -ErrorAction Stop |
                Select-Object TimeCreated,LogName,Id,Message
        }
        else
        {
            $Results += Get-WinEvent -LogName $Log.LogName -Oldest -ErrorAction Stop |
                Sort-Object TimeCreated -Descending |
                Select-Object TimeCreated,LogName,Id,Message -First 1
        }
    }
    catch
    {
        Write-Warning "$($Log.LogName) : $_"
    }
}

$Results | Sort-Object TimeCreated -Descending | Write-Output
