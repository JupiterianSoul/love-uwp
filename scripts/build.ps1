param(
    [string]$Config = 'Release'
)
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'vsenv.ps1')

& (Join-Path $PSScriptRoot 'build-luajit.ps1')

$build = Join-Path $root 'build'
cmake -S $root -B $build -G 'Visual Studio 17 2022' -A x64 `
    -DCMAKE_SYSTEM_NAME=WindowsStore -DCMAKE_SYSTEM_VERSION=10.0 `
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5
if ($LASTEXITCODE -ne 0) { throw 'CMake configure failed' }

cmake --build $build --config $Config --target love --parallel -- /p:AppxPackage=false /nologo /verbosity:minimal
if ($LASTEXITCODE -ne 0) { throw 'Build failed' }
