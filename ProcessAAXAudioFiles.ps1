# Set the path to the directory containing the .aax files
$aaxDirectory = "e:\YotoBooks\" # Replace with the actual path

# Set the path to the ExtractAAXChapters.ps1 script
$scriptPath = "e:\YotoBooks\ps\ExtractAAXChapters.ps1"

# Find all .aax files in the specified directory and store them in a list
$aaxFiles = Get-ChildItem -Path $aaxDirectory -Filter "*.aax" | Where-Object {$_.Extension -eq ".aax"}

# Check if any .aax files were found
if ($aaxFiles) {
    # Iterate over the list of .aax files
    foreach ($file in $aaxFiles) {
        Write-Host "Processing file: $($file.FullName)"

        # Call the ExtractAAXChapters.ps1 script with the filename as a parameter
        # You can add other parameters like -activation_bytes if needed
        & $scriptPath -filename $file.FullName 
    }
}
else {
    Write-Warning "No .aax files found in the specified directory."
}
