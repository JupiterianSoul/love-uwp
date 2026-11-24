param(
    [string]$Version = '11.5.0.0',
    [string]$Config = 'Release'
)
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$deps = Join-Path $root 'deps'
$build = Join-Path $root 'build'
$out = Join-Path $root 'out'
$layout = Join-Path $out 'layout'

if (Test-Path $out) { Remove-Item -Recurse -Force $out }
New-Item -ItemType Directory -Force -Path $layout | Out-Null

$exe = Get-ChildItem -Path $build -Recurse -Filter 'love.exe' |
    Where-Object { $_.FullName -match "\\$Config\\" -and $_.FullName -notmatch '\\AppX\\' } |
    Select-Object -First 1
if (-not $exe) { throw 'love.exe not found in the build directory' }
$bin = $exe.DirectoryName
Write-Host 'Taking binaries from' $bin

Copy-Item $exe.FullName $layout
foreach ($dll in 'SDL2.dll', 'OpenAL32.dll') {
    $file = Join-Path $bin $dll
    if (-not (Test-Path $file)) {
        $found = Get-ChildItem -Path $build -Recurse -Filter $dll |
            Where-Object { $_.FullName -match "\\$Config\\" -and $_.FullName -notmatch '\\AppX\\' } |
            Select-Object -First 1
        if (-not $found) { throw "$dll not found" }
        $file = $found.FullName
    }
    Copy-Item $file $layout
}
Copy-Item (Join-Path $deps 'angle\bin\UAP\x64\libEGL.dll') $layout
Copy-Item (Join-Path $deps 'angle\bin\UAP\x64\libGLESv2.dll') $layout
Copy-Item -Recurse (Join-Path $root 'package\nogame') $layout
Copy-Item (Join-Path $root 'LICENSE') (Join-Path $layout 'license.txt')
Copy-Item -Recurse (Join-Path $root 'licenses') $layout

$manifest = Get-Content -Raw -Encoding UTF8 (Join-Path $root 'package\AppxManifest.xml')
$manifest = $manifest.Replace('@VERSION@', $Version)
[System.IO.File]::WriteAllText((Join-Path $layout 'AppxManifest.xml'), $manifest, (New-Object System.Text.UTF8Encoding $false))

Add-Type -AssemblyName System.Drawing
$assets = Join-Path $layout 'Assets'
New-Item -ItemType Directory -Force -Path $assets | Out-Null
$images = @(
    @{ Name = 'StoreLogo.png'; W = 50; H = 50 },
    @{ Name = 'Square44x44Logo.png'; W = 44; H = 44 },
    @{ Name = 'Square150x150Logo.png'; W = 150; H = 150 },
    @{ Name = 'Wide310x150Logo.png'; W = 310; H = 150 },
    @{ Name = 'SplashScreen.png'; W = 620; H = 300 }
)
foreach ($img in $images) {
    $bmp = New-Object System.Drawing.Bitmap $img.W, $img.H
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'
    $g.TextRenderingHint = 'AntiAliasGridFit'
    $g.Clear([System.Drawing.Color]::FromArgb(231, 74, 153))
    $size = [Math]::Max(6, [Math]::Min($img.W, $img.H) * 0.28)
    $font = New-Object System.Drawing.Font 'Segoe UI', $size, ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)
    $format = New-Object System.Drawing.StringFormat
    $format.Alignment = 'Center'
    $format.LineAlignment = 'Center'
    $rect = New-Object System.Drawing.RectangleF 0, 0, $img.W, $img.H
    $g.DrawString([string][char]0x4C + [char]0xD6 + 'VE', $font, [System.Drawing.Brushes]::White, $rect, $format)
    $g.Dispose()
    $bmp.Save((Join-Path $assets $img.Name), [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
}

$kits = Join-Path ${env:ProgramFiles(x86)} 'Windows Kits\10\bin'
$sdkbin = Get-ChildItem $kits -Directory | Where-Object { $_.Name -match '^10\.' -and (Test-Path (Join-Path $_.FullName 'x64\makeappx.exe')) } |
    Sort-Object { [version]$_.Name } -Descending | Select-Object -First 1
if (-not $sdkbin) { throw 'makeappx.exe not found' }
$makeappx = Join-Path $sdkbin.FullName 'x64\makeappx.exe'
$signtool = Join-Path $sdkbin.FullName 'x64\signtool.exe'

$appx = Join-Path $out "love-uwp_$($Version)_x64.appx"
& $makeappx pack /d $layout /p $appx /o
if ($LASTEXITCODE -ne 0) { throw 'makeappx failed' }

$password = [Guid]::NewGuid().ToString()
$secure = ConvertTo-SecureString -String $password -Force -AsPlainText
$cert = New-SelfSignedCertificate -Type Custom -Subject 'CN=love-uwp' -KeyUsage DigitalSignature `
    -FriendlyName 'love-uwp test signing' -CertStoreLocation 'Cert:\CurrentUser\My' `
    -TextExtension @('2.5.29.37={text}1.3.6.1.5.5.7.3.3', '2.5.29.19={text}') -NotAfter (Get-Date).AddYears(5)
$pfx = Join-Path $env:RUNNER_TEMP 'love-uwp.pfx'
if (-not $env:RUNNER_TEMP) { $pfx = Join-Path $out 'love-uwp.pfx' }
Export-PfxCertificate -Cert $cert -FilePath $pfx -Password $secure | Out-Null
Export-Certificate -Cert $cert -FilePath (Join-Path $out 'love-uwp.cer') | Out-Null

& $signtool sign /fd SHA256 /a /f $pfx /p $password $appx
if ($LASTEXITCODE -ne 0) { throw 'signtool failed' }
Remove-Item $pfx
Remove-Item "Cert:\CurrentUser\My\$($cert.Thumbprint)"

$vclibs = Get-ChildItem -Path (Join-Path ${env:ProgramFiles(x86)} 'Microsoft SDKs\Windows Kits\10\ExtensionSDKs\Microsoft.VCLibs') -Recurse -Filter 'Microsoft.VCLibs.x64.14.00.appx' -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -match '\\Retail\\' } | Select-Object -First 1
if ($vclibs) {
    $depdir = Join-Path $out 'Dependencies\x64'
    New-Item -ItemType Directory -Force -Path $depdir | Out-Null
    Copy-Item $vclibs.FullName $depdir
} else {
    Write-Warning 'Microsoft.VCLibs.x64.14.00.appx not found, the release will not include it'
}

Get-ChildItem -Recurse $out -File | Where-Object { $_.FullName -notmatch '\\layout\\' } | ForEach-Object { Write-Host $_.FullName $_.Length }
