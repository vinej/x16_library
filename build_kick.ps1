<#
.SYNOPSIS
    Assemble an x16lib (KickAssembler edition) program and optionally run it.

    The KickAssembler tree mirrors src_acme/ file for file; the same
    on-target test suite proves the two behave identically.

    Needs Java on the PATH (KickAssembler is a jar).

.EXAMPLE
    .\build_kick.ps1 -Test                # the regression suite, headless
    .\build_kick.ps1 -Source myprog.asm -Run
#>
param(
    [string]$Source = "test_kick\runner.asm",

    [switch]$Test,
    [switch]$Run,
    [int]$Scale = 2
)

$ErrorActionPreference = "Stop"

function Fail([string]$message) {
    Write-Host $message -ForegroundColor Red
    exit 1
}

$root  = $PSScriptRoot
$emu   = Join-Path $root "emulator\x16emu.exe"
$rom   = Join-Path $root "emulator\rom.bin"
$src   = Join-Path $root "src_kick"
$build = Join-Path $root "build"

$jar = Join-Path $root "kickass\KickAss.jar"
if (-not (Test-Path $jar)) { Fail "missing: $jar" }
$java = Get-Command java -ErrorAction SilentlyContinue
if ($null -eq $java) { Fail "KickAssembler needs Java on the PATH" }

foreach ($tool in @($emu, $rom)) {
    if (-not (Test-Path $tool)) { Fail "missing: $tool" }
}
if (-not (Test-Path $build)) { New-Item -ItemType Directory -Path $build | Out-Null }

$name = [IO.Path]::GetFileNameWithoutExtension($Source).ToUpper()
$out  = Join-Path $build "$name-KICK.PRG"

Write-Host "KickAssembler $Source -> $out"
& java -jar $jar $Source -libdir $src -o $out -symbolfiledir $build
if ($LASTEXITCODE -ne 0) { Fail "KickAssembler assembly failed" }

$size = (Get-Item $out).Length
Write-Host "      $size bytes"

# --- test (identical harness to build_acme.ps1) ------------------------
if ($Test) {
    Write-Host "x16emu (headless testbench)"

    $stdin  = Join-Path $env:TEMP "x16lib-empty.in"
    $stdout = Join-Path $build "test-kick-output.txt"
    [IO.File]::WriteAllText($stdin, "")
    if (Test-Path $stdout) { Remove-Item $stdout -Force }

    $fsroot = Join-Path $root "test_acme\fsroot"
    if (-not (Test-Path $fsroot)) { New-Item -ItemType Directory -Path $fsroot | Out-Null }
    Get-ChildItem $fsroot -File | Remove-Item -Force

    $emuArgs = @('-rom', $rom, '-fsroot', $fsroot, '-prg', $out,
                 '-run', '-warp', '-echo', '-testbench')
    $proc = Start-Process -FilePath $emu -ArgumentList $emuArgs -NoNewWindow -PassThru `
                          -RedirectStandardInput $stdin -RedirectStandardOutput $stdout

    $deadline = (Get-Date).AddSeconds(60)
    $text = ""
    while ($true) {
        Start-Sleep -Milliseconds 200
        if (Test-Path $stdout) {
            $text = (Get-Content $stdout -Raw -ErrorAction SilentlyContinue) -replace "`r", ""
            if ($text -match '(?m)^DONE ') { break }
        }
        if ($proc.HasExited) { break }
        if ((Get-Date) -gt $deadline) {
            if (-not $proc.HasExited) { $proc.Kill() }
            Fail "emulator timed out after 60s -- no DONE line"
        }
    }
    if (-not $proc.HasExited) { $proc.Kill() }
    $proc.WaitForExit()

    $passes = ([regex]::Matches($text, '(?m)^PASS ([A-Z0-9_]+)')).Count
    $fails  = [regex]::Matches($text, '(?m)^FAIL ([A-Z0-9_]+)')
    $skips  = [regex]::Matches($text, '(?m)^SKIP ([A-Z0-9_]+)')
    $done   = [regex]::Match($text, '(?m)^DONE ([0-9A-F]{2})/([0-9A-F]{2})')

    foreach ($f in $fails) { Write-Host ("  FAIL {0}" -f $f.Groups[1].Value) -ForegroundColor Red }
    foreach ($s in $skips) { Write-Host ("  SKIP {0}" -f $s.Groups[1].Value) -ForegroundColor Yellow }

    if (-not $done.Success) { Fail "test run produced no DONE line" }

    $reportedPass  = [Convert]::ToInt32($done.Groups[1].Value, 16)
    $reportedTotal = [Convert]::ToInt32($done.Groups[2].Value, 16)

    if ($reportedTotal -eq 0) { Fail "no tests ran" }
    if ($passes -ne $reportedPass) {
        Fail "output is inconsistent: $passes PASS lines but DONE says $reportedPass"
    }
    if ($fails.Count -gt 0 -or $reportedPass -ne $reportedTotal) {
        Fail "$($reportedTotal - $reportedPass) of $reportedTotal tests failed"
    }

    $summary = "      $reportedPass/$reportedTotal tests passed"
    if ($skips.Count -gt 0) { $summary += ", $($skips.Count) skipped (not runnable headless)" }
    Write-Host $summary -ForegroundColor Green
    exit 0
}

if ($Run) {
    Write-Host "x16emu $out"
    & $emu -rom $rom -prg $out -run -scale $Scale
}
