$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$deps = Join-Path $root 'deps'
$downloads = Join-Path $deps 'downloads'
New-Item -ItemType Directory -Force -Path $downloads | Out-Null

$sources = @(
    @{
        File = 'love-11.5.tar.gz'
        Url = 'https://github.com/love2d/love/archive/refs/tags/11.5.tar.gz'
        Sha256 = '6f55c265be5e03696c4770150c4388f5cffbdb3727606724cf88332baab429f7'
        Dir = 'love-11.5'
    },
    @{
        File = 'megasource-11.5.tar.gz'
        Url = 'https://github.com/love2d/megasource/archive/refs/tags/11.5.tar.gz'
        Sha256 = '81f567d79d34a15554587cbc30a1f0be87fc8d9f8b41e46821c887cc600128b9'
        Dir = 'megasource-11.5'
    },
    @{
        File = 'SDL2-2.30.9.tar.gz'
        Url = 'https://github.com/libsdl-org/SDL/releases/download/release-2.30.9/SDL2-2.30.9.tar.gz'
        Sha256 = '24b574f71c87a763f50704bbb630cbe38298d544a1f890f099a4696b1d6beba4'
        Dir = 'SDL2-2.30.9'
    },
    @{
        File = 'openal-soft-1.24.3.tar.gz'
        Url = 'https://github.com/kcat/openal-soft/archive/refs/tags/1.24.3.tar.gz'
        Sha256 = '7e1fecdeb45e7f78722b776c5cf30bd33934b961d7fd2a11e0494e064cc631ce'
        Dir = 'openal-soft-1.24.3'
    },
    @{
        File = 'ANGLE.WindowsStore.2.1.13.zip'
        Url = 'https://www.nuget.org/api/v2/package/ANGLE.WindowsStore/2.1.13'
        Sha256 = 'd8f6c2bf2f6069bc2c1f77548140cf7c9dccd3aff79b15c5eb40c0e8f4032977'
        Dir = 'angle'
    }
)

foreach ($src in $sources) {
    $archive = Join-Path $downloads $src.File
    if (-not (Test-Path $archive)) {
        Write-Host "Downloading $($src.Url)"
        Invoke-WebRequest -Uri $src.Url -OutFile $archive -UseBasicParsing
    }
    $hash = (Get-FileHash -Algorithm SHA256 $archive).Hash.ToLower()
    if ($hash -ne $src.Sha256) {
        Remove-Item $archive
        throw "Checksum mismatch for $($src.File): $hash"
    }

    $target = Join-Path $deps $src.Dir
    if (Test-Path $target) {
        Remove-Item -Recurse -Force $target
    }
    if ($src.File.EndsWith('.zip')) {
        Expand-Archive -Path $archive -DestinationPath $target
    } else {
        & "$env:SystemRoot\System32\tar.exe" -xzf $archive -C $deps
        if ($LASTEXITCODE -ne 0) { throw "tar failed for $($src.File)" }
    }
}

$love = Join-Path $deps 'love-11.5'
git -C $love init -q
git -C $love apply --whitespace=nowarn (Join-Path $root 'patches/love-11.5-uwp.patch')
if ($LASTEXITCODE -ne 0) { throw 'Applying the LOVE patch failed' }
if (-not (Select-String -Path (Join-Path $love 'src/love.cpp') -Pattern 'love_uwp_setup_view' -Quiet)) {
    throw 'The LOVE patch did not apply'
}

Write-Host 'Sources ready in' $deps
