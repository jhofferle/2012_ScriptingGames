# -----------------------------------------------------------------------------
# Script: Advanced03_2012.ps1
# Author: Jason Hofferle
# Date: 04/08/2012
# Comments:
#  This entry was implemented as a function to assist with judging. The default
#  operation is to append the required information to the logonstatus.txt file
#  in the SystemRoot\logonlog directory. The path and file are created if they
#  do not exist. The function implements parameters for specifying an
#  alternative log location, and generating output. The event scenario
#  specified a mix of 32-bit and 64-bit operating systems, so the
#  OS Architecture and OS Caption were included in the log as information that
#  may be useful to a help desk.
# -----------------------------------------------------------------------------

Function Write-LogonLog
{
    [CmdletBinding()]

    Param
    (
        $FileName = "$Env:SystemDrive\logonlog\logonstatus.txt",

        [switch]
        $PassThru
    )

    if (-not (Test-Path (Split-Path $FileName)) )
    {
        try
        {
            New-Item -ItemType Directory -Path (Split-Path $FileName) -ErrorAction Stop | Out-Null
        }
        catch
        {
            Write-Debug ( $_ | Out-String )
            break
        }
    }

    $CS = Get-WmiObject -Class Win32_ComputerSystem
    $OS = Get-WmiObject -Class Win32_OperatingSystem
    $Printer = Get-WmiObject -Class Win32_Printer
    $MappedLogicalDisk = Get-WmiObject -Class Win32_MappedLogicalDisk

    $Result = New-Object PSObject -Property @{
        CurrentLog = (Get-Date).ToString()
        UserName = $CS.UserName
        ComputerName = "$($CS.DNSHostName).$($CS.Domain)"
        OSArchitecture = $OS.OSArchitecture
        OSName = $OS.Caption
        OperatingSystemVersion = $OS.Version
        OperatingSystemServicePack = "$($OS.ServicePackMajorVersion).$($OS.ServicePackMinorVersion)"
        DefaultPrinter = ($Printer | Where-Object {$_.Default}).Name
        TypeOfBoot = $CS.BootupState
        LastReboot = $OS.ConvertToDateTime($OS.LastBootUpTime).ToString()
        Drive = $MappedLogicalDisk |
            Select-Object @{Name='Drive Letter';Expression={$_.DeviceID}},
            @{Name='Resource Path';Expression={$_.ProviderName}}
    }

    if ($PassThru)
    {
        $Result | Write-Output
    }

    $Result | Out-File $FileName -Append -Encoding ascii
}

