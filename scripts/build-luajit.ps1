$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot 'vsenv.ps1')

$deps = Join-Path $root 'deps'
$work = Join-Path $deps 'luajit-build'
$out = Join-Path $deps 'luajit-uwp'

if (Test-Path $work) { Remove-Item -Recurse -Force $work }
if (Test-Path $out) { Remove-Item -Recurse -Force $out }
Copy-Item -Recurse (Join-Path $deps 'megasource-11.5\libs\LuaJIT') $work
Set-Content -Path (Join-Path $work '.relver') -Value '1693350652' -NoNewline

$src = Join-Path $work 'src'
$bat = Join-Path $src 'msvcbuild.bat'
$text = [System.IO.File]::ReadAllText($bat)
$static = "%LJCOMPILE% lj_*.c lib_*.c"
if (-not $text.Contains($static)) { throw 'Unexpected msvcbuild.bat layout' }
$text = $text.Replace($static, "%LJCOMPILE% /MD /D_UWP /DWINAPI_FAMILY=WINAPI_FAMILY_APP lj_*.c lib_*.c")
$before = $text
$text = $text -replace '(%LJLIB% /OUT:%LJLIBNAME% lj_\*\.obj lib_\*\.obj\r?\n@if errorlevel 1 goto :BAD\r?\n)@goto :MTDLL', '$1@goto :END'
if ($text -eq $before) { throw 'Could not skip the luajit.exe step in msvcbuild.bat' }
[System.IO.File]::WriteAllText($bat, $text)

Push-Location $src
try {
    cmd /c 'msvcbuild.bat static'
    if ($LASTEXITCODE -ne 0) { throw 'msvcbuild.bat failed' }
    if (-not (Test-Path 'lua51.lib')) { throw 'lua51.lib was not built' }
}
finally {
    Pop-Location
}

$include = Join-Path $out 'include'
New-Item -ItemType Directory -Force -Path $include | Out-Null
Copy-Item (Join-Path $src 'lua51.lib') $out
foreach ($h in 'lua.h', 'luaconf.h', 'lualib.h', 'lauxlib.h', 'lua.hpp', 'luajit.h') {
    Copy-Item (Join-Path $src $h) $include
}
Write-Host 'LuaJIT for UWP ready in' $out
