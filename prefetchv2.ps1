$directory = "C:\Windows\Prefetch"

Clear-Host

Write-Host @"

░█░█░█▀▀░█░░░█▀▀░█▀█░█▄█░█▀▀░░░█▀▀░█░░░█▀█░█▀▄░▀█▀░█▀█░█░█░█▀█
░█▄█░█▀▀░█░░░█░░░█░█░█░█░█▀▀░░░█▀▀░█░░░█░█░█▀▄░░█░░█░█░░█░░█░█
░▀░▀░▀▀▀░▀▀▀░▀▀▀░▀▀▀░▀░▀░▀▀▀░░░▀░░░▀▀▀░▀▀▀░▀░▀░▀▀▀░▀░▀░░▀░░▀▀▀ 

"@ -ForegroundColor Red

Write-Host "`n  Prefetch Checker - Detecting Suspicious Prefetch Files`n" -ForegroundColor Red

function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if (!(Test-Admin)) {
    Write-Warning "Please run this script as Administrator."
    Start-Sleep 5
    Exit
}

Start-Sleep -Seconds 2

# Collect all .pf files including hidden ones
$files = Get-ChildItem -Path $directory -Filter *.pf -Force

$hashTable = @{}
$suspiciousFiles = @{}

foreach ($file in $files) {
    try {
        # Check if file is hidden
        if ($file.Attributes -match "Hidden") {
            $suspiciousFiles[$file.Name] = "$($file.Name) is hidden"
        }

        # Check if file is read-only
        if ($file.IsReadOnly) {
            $suspiciousFiles[$file.Name] = "$($file.Name) is read-only"
        }

        # Check first three characters for validity
        $reader = [System.IO.StreamReader]::new($file.FullName)
        $buffer = New-Object char[] 3
        $null = $reader.ReadBlock($buffer, 0, 3)
        $reader.Close()

        $firstThreeChars = -join $buffer
        if ($firstThreeChars -ne "MAM") {
            $suspiciousFiles[$file.Name] = "$($file.Name) is not a valid prefetch file"
        }

        # Compute file hash and check for duplicates
        $hash = Get-FileHash -Path $file.FullName -Algorithm SHA256
        if ($hashTable.ContainsKey($hash.Hash)) {
            $hashTable[$hash.Hash].Add($file.Name)
        } else {
            $hashTable[$hash.Hash] = [System.Collections.Generic.List[string]]::new()
            $hashTable[$hash.Hash].Add($file.Name)
        }
    } catch {
        Write-Host "Error reading file: $($file.FullName) - $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Identify duplicate hashes
$repeatedHashes = $hashTable.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }

if ($repeatedHashes) {
    foreach ($entry in $repeatedHashes) {
        foreach ($file in $entry.Value) {
            if (-not $suspiciousFiles.ContainsKey($file)) {
                $suspiciousFiles[$file] = "$file has a duplicate hash (possible tampering)"
            }
        }
    }
}

# Display results
Write-Host "`n=== Results ===`n" -ForegroundColor Cyan
if ($suspiciousFiles.Count -gt 0) {
    Write-Host "Suspicious Prefetch files found:" -ForegroundColor Yellow
    foreach ($key in $suspiciousFiles.Keys) {
        Write-Host "$key : $($suspiciousFiles[$key])"
    }
} else {
    Write-Host "✅ Prefetch folder is clean." -ForegroundColor Green
}

Write-Host ""

