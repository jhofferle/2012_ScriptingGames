# -----------------------------------------------------------------------------
# Script: Advanced09_2012.ps1
# Author: Jason Hofferle
# Date: 04/18/2012
# Comments:
#  This function collects information about the local computer and writes that
#  information to the MyComputer.MyDomain.yyyyMMdd.XML file in the current
#  user's Documents special folder. Missing properties will have null values.
# -----------------------------------------------------------------------------

Function Get-HardwareInventory
{
    [CmdletBinding()]
    Param
    (
        $Path,

        [switch]
        $PassThru
    )

    Begin
    {
        Function Get-ProcessorInfo
        {
            Param
            (
                [System.Management.ManagementObject[]]
                $Processor
            )

            $CpuArray = @()

            foreach ($Cpu in $Processor)
            {
                $CpuObject = New-Object PSObject -Property @{
                    NumberOfCores = $Cpu.NumberOfCores
                    MaxClockSpeed = $Cpu.MaxClockSpeed
                    DeviceID = $Cpu.DeviceID
                    }
                $CpuArray += $CpuObject
            }
            return $CpuArray
        }
    }

    Process
    {
        try
        {
            $ComputerSystem = Get-WmiObject -Class Win32_ComputerSystem
            $Processor = @(Get-WmiObject -Class Win32_Processor)
            $OperatingSystem = Get-WmiObject -Class Win32_OperatingSystem
            $PhysicalMemory = Get-WmiObject -Class Win32_PhysicalMemory
            $NetworkAdapter = @(Get-WmiObject -Class Win32_NetworkAdapter -Filter "NetEnabled = 'True'")
        }
        catch
        {
            Write-Warning $_
            break
        }

        $TotalMemory = 0
        foreach ($Slot in $PhysicalMemory)
        {
            $TotalMemory += $Slot.Capacity
        }

        $Object = New-Object PSObject -Property @{
            DNSHostName = $ComputerSystem.DNSHostName
            Domain = $ComputerSystem.Domain
            Manufacturer = $ComputerSystem.Manufacturer
            Model = $ComputerSystem.Model
            Version = $OperatingSystem.Version
            'Memory (GB)' = "{0:N2}" -f ($TotalMemory / 1GB)
            NumProcessors = $Processor.Count
            Processors = Get-ProcessorInfo $Processor
            MACAddress = $NetworkAdapter[0].MACAddress
        }

        if (-not $Path)
        {
            $Folder = [System.Environment]::GetFolderPath("MyDocuments")
            $FileName = "$($Object.DNSHostName).$($Object.Domain).$(Get-Date -f yyyyMMdd).XML"
            $Path = "$Folder\$FileName"
        }

        try
        {
            $Object | Export-Clixml -Path $Path
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

    <#

    .Synopsis
    Peforms a computer hardware inventory.

    .Description
    Collects computer name, domain, manufacturer, model, number of processors,
    processor cores, processor speed, processor ID, MAC Address, OS Version,
    physical memory, and exports the information to an xml file.

    .parameter Path
    Specifies the path to the output file. The default is to create a file in
    the current user's documents folder named computer.domain.date.XML.

    .parameter PassThru
    Returns an object to the pipeline. By default, no output is
    generated.

    .Example
    Get-HardwareInventory

    Description
    -----------
    This command gets inventory information from the local computer and
    saves the results to a computer.domain.date.XML file in the current user's
    Documents folder.

    .Example
    Get-HardwareInventory -Path $Env:UserProfile\Desktop\HardwareReport.xml

    Description
    -----------
    This command gets inventory information from the local computer and
    saves the results to a HardwareReport.xml file on the current user's
    Desktop.

    .Example
    Get-HardwareInventory -PassThru

    Description
    -----------
    This command gets inventory information from the local computer, saves the
    results to the default file location, and displays output.

    #>
}
