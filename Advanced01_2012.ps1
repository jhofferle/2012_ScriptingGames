# -----------------------------------------------------------------------------
# Script: Advanced01_2012.ps1
# Author: Jason Hofferle
# Date: 04/03/2012
# Comments:
#  The major issue with the script in the event scenario is that it fails to
#  update the status of the process being monitored. The output of Get-Process
#  is assigned to the $notepad variable outside of the "for" loop. Each time
#  through the loop, the contents of this variable are output, but Get-Process
#  is not called to update the status of the process. The resolution is to
#  move Get-Process inside the loop.
#
#  The original script name indicates the process will be monitored for
#  10 seconds, but the "for" loop monitors the process for 10 iterations,
#  irrespective of time. A "while" loop that tests for elapsed time allows the
#  monitoring time to be controlled separately from the polling interval.
# -----------------------------------------------------------------------------

$End = (Get-Date).AddSeconds(10)

while ( (Get-Date) -lt $End)

{

 start-sleep 1

 Get-Process notepad

}
