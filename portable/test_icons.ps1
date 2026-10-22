param(
    [Parameter(Mandatory = $true)][string] $PetDirectory,
    [Parameter(Mandatory = $true)][ValidateSet('MOMO', 'MIMI')][string] $PetName
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$launcherPath = Join-Path $PetDirectory "Start $PetName.exe"
$iconPath = Join-Path $PetDirectory "app/assets/$($PetName.ToLowerInvariant()).ico"
$actualIcon = [Drawing.Icon]::ExtractAssociatedIcon($launcherPath)
if ($null -eq $actualIcon) { throw "The $PetName launcher has no icon." }
$expectedIcon = [Drawing.Icon]::ExtractAssociatedIcon($iconPath)
if ($null -eq $expectedIcon) { throw "The $PetName artwork icon could not be read." }
# DrawIcon supports PNG-compressed ICO entries on Windows PowerShell's .NET
# Framework, where Icon.ToBitmap can reject the same valid icon format.
$actualBitmap = [Drawing.Bitmap]::new($actualIcon.Width, $actualIcon.Height)
$expectedBitmap = [Drawing.Bitmap]::new($actualIcon.Width, $actualIcon.Height)
$actualGraphics = [Drawing.Graphics]::FromImage($actualBitmap)
$expectedGraphics = [Drawing.Graphics]::FromImage($expectedBitmap)
$bounds = [Drawing.Rectangle]::new(0, 0, $actualIcon.Width, $actualIcon.Height)
$actualGraphics.DrawIcon($actualIcon, $bounds)
$expectedGraphics.DrawIcon($expectedIcon, $bounds)
$actualGraphics.Dispose()
$expectedGraphics.Dispose()
try {
    $visiblePixels = 0
    for ($y = 0; $y -lt $actualBitmap.Height; $y++) {
        for ($x = 0; $x -lt $actualBitmap.Width; $x++) {
            $actualPixel = $actualBitmap.GetPixel($x, $y)
            $expectedPixel = $expectedBitmap.GetPixel($x, $y)
            if ($actualPixel.ToArgb() -ne $expectedPixel.ToArgb()) {
                throw "The embedded $PetName icon does not match its cat artwork."
            }
            if ($actualPixel.A -gt 0) { $visiblePixels++ }
        }
    }
    if ($visiblePixels -lt 100) { throw "The $PetName icon is empty." }
    Write-Output "PASS: the embedded $PetName launcher icon matches its cat artwork."
} finally {
    $actualBitmap.Dispose()
    $expectedBitmap.Dispose()
    $actualIcon.Dispose()
    $expectedIcon.Dispose()
}
