# -----------------------------------------------------------------------------
# Script: Advanced05_2012.ps1
# Author: Jason Hofferle
# Date: 04/11/2012
# Comments:
#  This advanced function queries traditional logs on the specified computer
#  for errors. Impersonation is used, error handling is implemented, and no
#  changes are made to the user environment. By default, errors from the local
#  computer are shown, sorted by the count of errors in descending order.
# -----------------------------------------------------------------------------

Function Get-LoggedError
{
    [CmdletBinding()]

    Param
    (
        [string[]]
        $ComputerName = $Env:ComputerName
    )

    Process
    {
        foreach ($Computer in $ComputerName)
        {
            Write-Verbose "Computer: $Computer"
            $Events = @()
            try
            {
                $LogNames = Get-EventLog -ComputerName $Computer -List -ErrorAction Stop
            }
            catch
            {
                Write-Warning "$Computer : $_"
                continue
            }

            foreach ($Log in $LogNames)
            {
                Write-Verbose "Accessing $($Log.LogDisplayName)"
                try
                {
                    $Parameters = @{
                        LogName = $Log.Log
                        ComputerName = $Computer
                        EntryType = 'Error'
                        ErrorAction = 'Stop'}

                    $Events += @(Get-EventLog @Parameters)
                }
                catch
                {
                    Write-Warning "$($Log.Log) : $_"
                }
            }

            $Events |
                Sort-Object Source |
                Group-Object Source |
                Sort Count -Descending |
                Select-Object Count,Name,@{Name="ComputerName";Expression={$Computer}}
        }
    }

    <#

    .Synopsis
    Reports number of errors from events logs on a particular server.

    .Description
    Produces report that lists the number of errors from traditional logs
    on a particular server.

    .parameter ComputerName
    Specifies the computers on which the command runs. The default is
    the local computer.

    .Example
    Get-LoggedError

    Description
    -----------
    This command displays errors from the local computer.

    .Example
    Get-LoggedError -ComputerName Computer01 -Verbose

    Description
    -----------
    This command displays errors from Computer01 with verbose output.

    #>
}
