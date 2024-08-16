$logFile = "./RemovePathFromSystemVariable_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
# Read the list of servers from servers.txt
$servers = Get-Content -Path "./servers.txt"

# Read the paths to remove from the text file
$pathsToRemove = Get-Content -Path "./valuestoremovefrompath.txt"
# Define the path to the servers file
$serversFile = "C:\path\to\servers.txt"

# Check if the servers file exists and is not empty
if (Test-Path $serversFile -PathType Leaf) {
    $servers = Get-Content -Path $serversFile
}

if ($servers -and $servers.Count -gt 0) {
    foreach ($server in $servers) {
        Write-Host "Processing server: $server"
        try {
            # Get value from the current system Path on the remote server
            $currentPath = Invoke-Command -ComputerName $server -ScriptBlock {
                [Environment]::GetEnvironmentVariable("Path", "Machine")
            }

            # Split the current path into an array
            $pathArray = $currentPath -split ";"

            # Create a new array to store paths that will be kept
            $newPathArray = @()

            # Loop through each path in the current Path
            foreach ($path in $pathArray) {
                if ($path -notin $pathsToRemove) {
                    $newPathArray += $path
                }
            }

            # Join the new path array back into a string
            $newPath = $newPathArray -join ";"

            # Set the new system Path on the remote server
            Invoke-Command -ComputerName $server -ScriptBlock {
                param($newPath)
                [Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
            } -ArgumentList $newPath

            Write-Host "Paths have been removed from the system Path environment variable on $server."
        }
        catch {
            Write-Host "An error occurred while processing $server : $_"
        }
    }
}
else {
    # Ask user if they want to remove paths locally in case the servers file is empty or doesn't exist
    $removeLocally = Read-Host "The servers file is empty or doesn't exist. Do you want to remove the paths locally? (Y/N)"

    if ($removeLocally -eq "Y" -or $removeLocally -eq "y") {
        # Get the current system Path
        $currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")

        # Split the current path into an array
        $pathArray = $currentPath -split ";"

        # Create a new array to store paths that will be kept
        $newPathArray = $pathArray | Where-Object { $_ -notin $pathsToRemove }

        # Join the new path array back into a string
        $newPath = $newPathArray -join ";"

        # Set the new system Path
        [Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")

        Write-Host "Paths have been removed from the local system Path environment variable."
    }
    else {
        Write-Host "No changes were made to the system Path."
    }
}

Write-Host "Script execution completed."