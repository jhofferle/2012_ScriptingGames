# -----------------------------------------------------------------------------
# Script: Advanced10_2012.ps1
# Author: Jason Hofferle
# Date: 04/18/2012
# Comments:
#  This command generates a CSV log file of all the counters in the Processor
#  counter set by piping the output of Get-Counter to Export-Counter.
# -----------------------------------------------------------------------------

Get-Counter -Counter (Get-Counter -ListSet Processor).Paths -SampleInterval 2 -MaxSamples 10 |
    Export-Counter -Path "$Env:UserProfile\Documents\$($Env:ComputerName)_processorCounters.csv" -FileFormat csv -Force
