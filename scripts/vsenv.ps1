$ErrorActionPreference = 'Stop'

if ($env:VSCMD_ARG_TGT_ARCH -eq 'x64') {
    return
}

$vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio\Installer\vswhere.exe'
$vs = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if (-not $vs) { throw 'Visual Studio with C++ tools not found' }

$vcvars = Join-Path $vs 'VC\Auxiliary\Build\vcvars64.bat'
$lines = cmd /c "`"$vcvars`" >nul && set"
foreach ($line in $lines) {
    if ($line -match '^([^=]+)=(.*)$') {
        Set-Item -Path "env:$($Matches[1])" -Value $Matches[2]
    }
}
