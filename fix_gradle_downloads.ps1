
function Cache-Artifact {
    param([string]$url)
    $filename = Split-Path $url -Leaf
    $tempFile = "$env:TEMP\gradle_dl_$filename"
    Write-Host "  Downloading $filename..." -ForegroundColor Cyan
    curl.exe -L -s $url -o $tempFile
    if (-not (Test-Path $tempFile) -or (Get-Item $tempFile).Length -eq 0) {
        Write-Host "  FAILED: $url" -ForegroundColor Red
        if (Test-Path $tempFile) { Remove-Item $tempFile -Force }
        return
    }
    $hash = (Get-FileHash $tempFile -Algorithm SHA1).Hash.ToLower()
    $repoPatterns = @(
        "https://repo.maven.apache.org/maven2/",
        "https://dl.google.com/dl/android/maven2/",
        "https://plugins.gradle.org/m2/",
        "https://storage.googleapis.com/download.flutter.io/",
        "https://repo1.maven.org/maven2/"
    )
    $artifactPath = $null
    foreach ($pattern in $repoPatterns) {
        if ($url.StartsWith($pattern)) {
            $artifactPath = $url.Substring($pattern.Length)
            break
        }
    }
    if (-not $artifactPath) { Remove-Item $tempFile -Force; return }
    $parts = $artifactPath -split "/"
    $fname    = $parts[-1]
    $version  = $parts[-2]
    $artifact = $parts[-3]
    $group    = ($parts[0..($parts.Length - 4)]) -join "."
    $cacheDir = "C:\Users\MSI\.gradle\caches\modules-2\files-2.1\$group\$artifact\$version\$hash"
    New-Item -ItemType Directory -Force -Path $cacheDir | Out-Null
    Copy-Item $tempFile -Destination "$cacheDir\$fname" -Force
    Remove-Item $tempFile -Force
    Write-Host "  Cached $group`:$artifact`:$version" -ForegroundColor Green
    $ext = [System.IO.Path]::GetExtension($url)
    $pomUrl = $url.Substring(0, $url.Length - $ext.Length) + ".pom"
    $pomFile = "$env:TEMP\gradle_pom_$filename.pom"
    curl.exe -L -s $pomUrl -o $pomFile 2>$null
    if ((Test-Path $pomFile) -and (Get-Item $pomFile).Length -gt 0) {
        $pomHash = (Get-FileHash $pomFile -Algorithm SHA1).Hash.ToLower()
        $pomDir = "C:\Users\MSI\.gradle\caches\modules-2\files-2.1\$group\$artifact\$version\$pomHash"
        New-Item -ItemType Directory -Force -Path $pomDir | Out-Null
        $pomName = [System.IO.Path]::GetFileNameWithoutExtension($fname) + ".pom"
        Copy-Item $pomFile -Destination "$pomDir\$pomName" -Force
        Remove-Item $pomFile -Force
    }
}

for ($i = 1; $i -le 20; $i++) {
    Write-Host "`n=== Round $i ===" -ForegroundColor Yellow
    $raw = & flutter build apk 2>&1 | Out-String
    $output = $raw -replace "[\r\n]", " "
    $urls = @()
    $matches_list = [regex]::Matches($output, "https://\S+\.(jar|aar)")
    foreach ($m in $matches_list) {
        $clean = $m.Value.TrimEnd(".,")
        if ($clean -notin $urls) { $urls += $clean }
    }
    if ($urls.Count -eq 0) {
        Write-Host "`nNo more failures!" -ForegroundColor Green
        break
    }
    Write-Host "Found $($urls.Count) failing download(s):" -ForegroundColor Yellow
    foreach ($url in $urls) { Cache-Artifact $url }
}
