param(
    [Parameter(Mandatory = $true, HelpMessage = "Path to the .aax audio file.")]
    [string]$filename,

    [Parameter(Mandatory = $false, HelpMessage = "Chapter Limit. Will combine all remaining chapters into the LAST output file")]
    [int]$CHAPTER_LIMIT = 100,

    [Parameter(Mandatory = $false, HelpMessage = "Audible activation bytes (8 characters).")]
    [ValidateScript({ if ($_) { $_.Length -eq 8 } else { $true } })] # Validate only if provided
    [string]$activation_bytes = "4dfd0d24" # Default value
)

# Extract filename without extension
$baseName = [System.IO.Path]::GetFileNameWithoutExtension($filename)
# Create new directory based on filename
$newDirectory = [System.IO.Path]::Combine([System.IO.Path]::GetDirectoryName($filename), $baseName)
New-Item -ItemType Directory -Path $newDirectory -Force | Out-Null

# Move the original file into the new directory
$newFileLocation = [System.IO.Path]::Combine($newDirectory, [System.IO.Path]::GetFileName($filename))
Move-Item -Path $filename -Destination $newFileLocation -Force

# Update $filename to reflect the new location
$filename = $newFileLocation

#initialize subfolder names relative to the new directory
$chapterFolder = Join-Path $newDirectory "Chapters"
$ArtworkFolder = Join-Path $newDirectory "Artwork"
$chapterData = Join-Path $newDirectory "chapters.json"

#execute ffprobe command to extract chapter data and output to a file
& ffprobe -i $filename -activation_bytes $activation_bytes -print_format json -show_chapters | Out-File $chapterData

#import chapterData json file and convert it to PowerShell list of objects
$chapters = Get-Content -Path $chapterData | ConvertFrom-Json

#Create chapter subfolder for storing new files
New-Item -ItemType Directory -Path $chapterFolder -Force | Out-Null

#iterate through chapters data
if ($chapters.chapters) {
    foreach ($chapter in $chapters.chapters) {
        Write-Host "Chapter Title: $($chapter.tags.title)"
        Write-Host "Start Time: $($chapter.start_time)"
        Write-Host "End Time: $($chapter.end_time)"
     
        #Define new file name
        $outfile = Join-Path $chapterFolder ($chapter.tags.title + ".flac")

        if ($chapter.id -eq $CHAPTER_LIMIT-1) {
            #run ffmpeg command to convert the aax audio into flac based on the chapter start and end times, writing to the correct filename and folder
            #consolodating all remaining chapters into the last one
            $chapterEndTime = $chapters.chapters[-1].end_time

            & ffmpeg -y -activation_bytes $activation_bytes -i $filename -v quiet -stats -codec:a flac -ss $chapter.start_time -to $chapterEndTime $outfile
            break
        }
        else {
            #run ffmpeg command to convert the aax audio into flac based on the chapter start and end times, writing to the correct filename and folder
            & ffmpeg -y -activation_bytes $activation_bytes -i $filename -v quiet -stats -codec:a flac -ss $chapter.start_time -to $chapter.end_time $outfile
        }
    }
}
else {
    Write-Warning "No chapters found in the file."
}

#Extract full size thumbnail and 16x16 for Yoto Player and store it into new folder
New-Item -ItemType Directory -Path $ArtworkFolder -Force | Out-Null
$outfile = Join-Path $ArtworkFolder "thumbnail%03d.jpeg"
& ffmpeg -y -activation_bytes $activation_bytes -i $filename -v quiet -stats -f image2 -frames:v 1  $outfile
$outfile = Join-Path $ArtworkFolder "pixel%03d.jpeg"
& ffmpeg -y -activation_bytes $activation_bytes -i $filename -v quiet -stats -s 16x16 -f image2 -frames:v 1  $outfile
