[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
try {
    $url = 'https://raw.githubusercontent.com/sweetvata/Y-boSStools/main/boSS-Tools.ps1'
    $wc = New-Object Net.WebClient
    $wc.Headers.Add('User-Agent', 'Mozilla/5.0')
    $bytes = $wc.DownloadData($url)
    if ($bytes.Length -lt 3 -or $bytes[0] -ne 0xEF -or $bytes[1] -ne 0xBB -or $bytes[2] -ne 0xBF) {
        $bytes = [byte[]](0xEF, 0xBB, 0xBF) + $bytes
    }
    $path = Join-Path $env:TEMP 'boSS-Tools.ps1'
    [IO.File]::WriteAllBytes($path, $bytes)
    Start-Process powershell.exe -Verb RunAs -ArgumentList '-NoProfile', '-STA', '-ExecutionPolicy', 'Bypass', '-File', ('"' + $path + '"')
} catch {
    Write-Host ('Download failed: ' + $_.Exception.Message)
    exit 1
}
