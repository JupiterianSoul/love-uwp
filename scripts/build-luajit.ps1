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
Push-Location $src
try {
    cmd /c 'msvcbuild.bat static'
    if ($LASTEXITCODE -ne 0) { throw 'msvcbuild.bat failed' }

    Get-ChildItem -Filter 'lj_*.obj' | Where-Object { $_.Name -ne 'lj_vm.obj' } | Remove-Item
    Get-ChildItem -Filter 'lib_*.obj' | Remove-Item
    Remove-Item 'lua51.lib'

    $cfiles = @(Get-ChildItem -Filter 'lj_*.c') + @(Get-ChildItem -Filter 'lib_*.c') | ForEach-Object { $_.Name }
    & cl /nologo /c /O2 /W3 /MD /D_CRT_SECURE_NO_DEPRECATE /D_UWP /DWINAPI_FAMILY=WINAPI_FAMILY_APP $cfiles
    if ($LASTEXITCODE -ne 0) { throw 'Compiling LuaJIT for UWP failed' }

    $objs = @(Get-ChildItem -Filter 'lj_*.obj') + @(Get-ChildItem -Filter 'lib_*.obj') | ForEach-Object { $_.Name }
    & lib /nologo /nodefaultlib /OUT:lua51.lib $objs
    if ($LASTEXITCODE -ne 0) { throw 'Creating lua51.lib failed' }
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
