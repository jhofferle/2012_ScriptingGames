# -----------------------------------------------------------------------------
# Script: Advanced02_2012.ps1
# Author: Jason Hofferle
# Date: 04/05/2012
# Comments:
#  This advanced function utilizes the Append parameter of Export-Csv in
#  PowerShell 3 to easily export collected information to a file that can be
#  displayed as a spreadsheet. It includes parameters for connecting to remote
#  computers and specifying alternate credentials. Comment-based help is
#  included. Administrative rights are not required for gathering service
#  information, but error handling displays the appropriate message when
#  permissions are insufficient for accessing a remote system or writing a
#  file to a restricted location.
# -----------------------------------------------------------------------------

Function Get-ServiceInformation
{
    [CmdletBinding()]

    Param
    (
        [Parameter(
        Position = 0,
        ValueFromPipeLine=$True,
        ValueFromPipeLineByPropertyName=$True)]
        [String[]]
        $ComputerName = $Env:ComputerName,

        $Credential,

        $Path = "$([System.IO.Path]::GetTempFileName()).csv",

        $LogFile,

        [Switch]
        $PassThru
    )

    Begin
    {
        if ($PSVersionTable.PSVersion.Major -lt 3)
        {
            Write-Warning "This script uses PowerShell 3.0 features."
            break
        }

        # Build a PsCredential object if username was specified for credential
        if ($Credential)
        {
            $Credential = Get-Credential $Credential

            # Exit if canceled at credential dialog
            if (-NOT ($Credential -IS "System.Management.Automation.PsCredential"))
            {
                break
            }
        }
    }

    Process
    {
        foreach ($Computer in $ComputerName)
        {
            Write-Verbose $Computer
            $Params = @{
                Class = 'Win32_Service'
                ComputerName = $Computer
                }

            # Add credential parameter if it was specified
            if ($Credential)
            {
                $Params.Add("Credential",$Credential)
            }

            try
            {
                $Result = Get-WmiObject @Params -ErrorAction Stop |
                    Select-Object __SERVER,Name,StartMode,State,StartName

                $Result | Export-Csv -Path $Path -Append -NoTypeInformation -ErrorAction Stop

                if ($PassThru)
                {
                    Write-Output $Result
                }
            }
            catch
            {
                Write-Warning "$Computer : $_"

                if ($LogFile)
                {
                    try
                    {
                        Add-Content -Path $LogFile -Value ("$Computer : $_") -ErrorAction Stop
                    }
                    catch
                    {
                        Write-Warning $_
                        # Stop script from attempting to write to the log file
                        $LogFile = $False
                    }
                }
                continue
            }
        }
    }

    End
    {
        if (Test-Path $Path)
        {
            try
            {
                Invoke-Item -Path $Path -ErrorAction Stop
            }
            catch
            {
                Write-Warning $_
            }
        }
    }

    <#

    .Synopsis
    Finds information about remote and local services.

    .Description
    Retrieves critical information about installed services on specified
    computers. The default operation is to query the local computer and
    present those results in a spreadsheet.

    .parameter ComputerName
    Specifies the computers on which the command runs. The default is
    the local computer.

    .parameter Credential
    Specifies a user account that has permission to perform this action.
    The default is the current user. Type a user name, such as "User01", or
    enter a PSCredential object, such as an object that is returned by the
    Get-Credential cmdlet. When you type a user name, you will be prompted
    for a password.

    .parameter Path
    Specifies the path to the output file. The default is to create a temporary
    file in the current user's temp directory.

    .parameter LogFile
    Specifies the path to a text file where errors are logged. This is useful
    for creating a list of computer names that could not be contacted. The
    default is to not create a log file.

    .parameter PassThru
    Returns an object for each service retrieved. By default, no output is
    generated.

    .Example
    Get-ServiceInformation

    Description
    -----------
    This command retrieves service information from the local computer and
    presents that information in a spreadsheet.

    .Example
    Get-ServiceInformation -ComputerName Computer01 -Credential Computer01\User

    Description
    -----------
    This command retrieves service information from Computer01 using the User
    acccount on Computer01.

    .Example
    Get-ServiceInformation -Path $Env:UserProfile\Desktop\services.csv

    Description
    -----------
    This command retrieves service information from the local computer, saves
    the information to the services.csv file on the current user's desktop, and
    displays the csv file.

    .Example
    "Comp01","Comp02","Comp03" | Get-ServiceInformation -LogFile $Env:UserProfile\Desktop\Errors.txt

    Description
    -----------
    This command retrieves service information from Comp01,Comp02, and Comp03.
    If any of these computers cannot be contacted, they are logged in Errors.txt
    on the current user's desktop.

    .Example
    Get-ServiceInformation -PassThru | Format-Table

    Description
    -----------
    This command retrieves service information from the local computer and
    displays the output on-screen in addition to presenting a spreadsheet.

    #>
}


