Clear-Host
Write-Host "Pika Mod Analyzer" -ForegroundColor Yellow 
Write-Host ""

Write-Host "Enter path to mods folder: " -ForegroundColor DarkYellow -NoNewline
Write-Host "(press enter for default)" -ForegroundColor DarkGray
$mods = Read-Host "Path"
Write-Host ""

if (-not $mods) {
    $mods = "$env:USERPROFILE\AppData\Roaming\.minecraft\mods"
    Write-Host "Press enter to continue with " -ForegroundColor DarkYellow -NoNewline
    Write-Host $mods -ForegroundColor DarkGray
    Read-Host
}

if (-not (Test-Path $mods -PathType Container)) {
    Write-Host "Invalid Path." -ForegroundColor Red
    exit 1
}

function Get-FileHashMD5 {
    param ([string]$filePath)
    $md5 = New-Object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
    $fileStream = [System.IO.File]::OpenRead($filePath)
    try {
        $hashBytes = $md5.ComputeHash($fileStream)
    } finally {
        $fileStream.Close()
    }
    return [BitConverter]::ToString($hashBytes).Replace("-", "")
}

$knownHashes = @{
    "e0690c67032465cf433d1a0d0ecb3bd4" = "AutoClicker"
    "0ca3e09759aba830c07d33b3a35b83aa" = "AutoClicker"
    "5f84b9e001dfa8af1dd104333266e74c" = "AutoClicker"
    "73e768e470cc361426c302ecdc3d1921" = "HitDelayFix"
    "b7b5ea8c77e924a2fc72bf8cce3b1c45" = "BetterPvP Mod"
    "1e2e33e5710394252abc4b014bc3dcbd" = "Inventory Tweaks"
    "e1888186be0600089055dd9b872cea57" = "Inventory Tweaks"
    "4a98252282f7af2c3042ade6fa1a999a" = "Xaero's Map Server Utils"
    "1ed5aaa756ddb88d983fca4b60be4906" = "Player Notifier"
    "d8c7bef321cd27acc13eb53e0bda9507" = "Marlow's Crystal Optimizer"
    "ee71b32c8039e82f1769a80e9e94e4cc" = "Crystal Optimizer"
    "828d047ad87de08523b2f13b0a2e1ce3" = "Marlow's Crystal Optimizer"
    "26dc9d69cbae20529c2fe2d2f76cf9a9" = "EZMapDL"
    "a19865b115ccb36d0a460a140c66c813" = "World Tools"
    "1c24291872f75c82c1876ae97eeacc78" = "Elytra Chestplate Swapper"
    "e11639412a6eee71465bd59de021a923" = "Elytra Chestplate Swapper"
    "29e050b50040892b118c096b9e620efb" = "Elytra Swapper"
    "0403d53f88bfe6e890c30cb72d33b7eb" = "Zyin's HUD"
    "099d9636f84c65400adfb306cdebf95d" = "FreeCam"
    "68c2ec7e09aadd5627ca7f92480eb256" = "FreeCam"
}

$suspiciousMods = @()

Get-ChildItem -Path $mods -Filter *.jar | ForEach-Object {
    $file = $_
    $hash = Get-FileHashMD5 -filePath $file.FullName
    
    if ($knownHashes.ContainsKey($hash)) {
        $modName = $knownHashes[$hash]
        Write-Host "Suspicious Mod Detected: $modName (File: $($file.Name))" -ForegroundColor Red
        $suspiciousMods += $modName
    }
}

if ($suspiciousMods.Count -gt 0) {
    Write-Host "Suspicious mods detected:" -ForegroundColor Yellow
    $suspiciousMods | ForEach-Object { Write-Host "- $_" -ForegroundColor Red }
} else {
    Write-Host "No suspicious mods detected." -ForegroundColor Green
}
