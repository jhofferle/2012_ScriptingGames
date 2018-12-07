# -----------------------------------------------------------------------------
# Script: Advanced04_2012.ps1
# Author: Jason Hofferle
# Date: 04/09/2012
# Comments:
#  This advanced function reports folder size information by recursively
#  calling itself. There is no check for administrative rights, but a warning
#  is displayed when encountering a permission issue. The function outputs
#  custom objects and displays folder size in a human-readable format.
#  It includes comment-based help, reusable functions, and parameters for
#  specifying a specific folder. It also implements a depth parameter for
#  controlling the level of subdirectories to display.
# -----------------------------------------------------------------------------

Function Get-DirectorySize
{
    [CmdletBinding()]

    Param
    (
        $Path = (Get-Location).Path,

        $Depth
    )

    Begin
    {
        Function Get-PrettySize
        {
            Param
            (
                $Bytes
            )

            switch ($Bytes)
            {
                {$Bytes -ge 1TB}
                {
                    return "{0:N2}" -f ($Bytes / 1TB) + " TeraBytes"
                }

                {$Bytes -ge 1GB}
                {
                    return "{0:N2}" -f ($Bytes / 1GB) + " GigaBytes"
                }

                {$Bytes -ge 1MB}
                {
                    return "{0:N2}" -f ($Bytes / 1MB) + " MegaBytes"
                }

                {$Bytes -ge 1KB}
                {
                    return "{0:N2}" -f ($Bytes / 1KB) + " KiloBytes"
                }

                Default
                {
                    return "{0:N2}" -f $Bytes + " Bytes"
                }
            }
        }
    }

    Process
    {
        $TotalSizeOfCurrentDirectory = 0
        $DirectoryObjects = @()

        try
        {
            $Contents = Get-ChildItem -Path $Path -Force -ErrorAction Stop
        }
        catch
        {
            Write-Warning $_
            continue
        }

        foreach ($Item in $Contents)
        {
            if ($Item.PSIsContainer)
            {
                Write-Verbose "Processing Directory: $($Item.FullName)"

                # Setup parameters for recursive call to Get-DirectorySize.
                # Depth is decreased by 1 on each recursive call.
                $Params = @{Path = $Item.FullName}
                if ($Depth)
                {
                    $Params.Add("Depth",($Depth - 1))
                }

                $SubDirectories = @(Get-DirectorySize @Params)
                $TotalSizeOfCurrentDirectory += $SubDirectories[-1].Size

                # Only add output of recursive Get-DirectorySize calls if
                # specified depth has not been reached.
                if (($Depth -gt 0) -or ($Depth -eq $Null))
                {
                    $DirectoryObjects += $SubDirectories
                }
            }
            else
            {
                $TotalSizeOfCurrentDirectory += $Item.Length
            }
        }

        $CurrentDirectory = New-Object PSObject -Property @{
            Folder = $Path
            Size = $TotalSizeOfCurrentDirectory
            "Size Of Folder" = Get-PrettySize $TotalSizeOfCurrentDirectory}

        # Add the current directory's object to the array of directory objects
        # and write the array to the output stream.
        $DirectoryObjects += $CurrentDirectory
        Write-Output $DirectoryObjects
    }

    <#

    .Synopsis
    Reports information on folder size.

    .Description
    Displays information about the size of the specified directory, and all
    subdirectories.

    .parameter Path
    Specifies a complete path to a location. The default location is the
    current directory.

    .parameter Depth
    Specifies how many levels of subdirectories should be displayed. The
    default is to display all subdirectories.

    .Example
    Get-DirectorySize

    Description
    -----------
    This command displays folder size information for the current directory.

    .Example
    Get-DirectorySize -Path C:\data\ScriptingGuys\2012

    Description
    -----------
    This command displays folder size information for the specified directory.

    .Example
    Get-DirectorySize -Path 'C:\Program Files' -Depth 1

    Description
    -----------
    This command displays folder size information for immediate subfolders of
    the specified directory.

    #>
}

