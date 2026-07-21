<#
.SYNOPSIS
    Assemble an x16lib (64tass edition) program and optionally run it.

    The ca65 tree mirrors src_acme/ file for file; the same on-target
    test suite proves the two behave identically.

.EXAMPLE
    .\build_64tass.ps1 -Test              # the regression suite, headless
    .\build_64tass.ps1 -Source myprog.s -Config myprog.cfg
#>
param(
    [string]$Source = "test_64tass\runner.asm",
    
    [switch]$Test,
    [switch]$Run,
    [int]$Scale = 2
)

$ErrorActionPreference = "Stop"

# The suite spans several PRGs (runner.asm grew to the $9EFF load
# ceiling; newer modules test in runner2.asm). A bare -Test runs every
# runner by re-invoking this script with an explicit -Source; an
# explicit -Source still runs alone (harness mutation checks).
if ($Test -and -not $PSBoundParameters.ContainsKey('Source')) {
    foreach ($s in @("test_64tass\runner.asm", "test_64tass\runner2.asm", "test_64tass\serial.asm")) {
        & $PSCommandPath -Source $s -Test
        if ($LASTEXITCODE -ne 0) { exit 1 }
    }
    exit 0
}

function Fail([string]$message) {
    Write-Host $message -ForegroundColor Red
    exit 1
}

$root  = $PSScriptRoot
$emu   = Join-Path $root "emulator\x16emu.exe"
$rom   = Join-Path $root "emulator\rom.bin"
$src   = Join-Path $root "src_64tass"
$build = Join-Path $root "build"

$tass = Join-Path $root "64tass\64tass.exe"
if (-not (Test-Path $tass)) { Fail "missing: $tass" }

foreach ($tool in @($emu, $rom)) {
    if (-not (Test-Path $tool)) { Fail "missing: $tool" }
}
if (-not (Test-Path $build)) { New-Item -ItemType Directory -Path $build | Out-Null }

$name = [IO.Path]::GetFileNameWithoutExtension($Source).ToUpper()
$obj  = Join-Path $build "$name-ca65.o"
$out  = Join-Path $build "$name-64TASS.PRG"

Write-Host "64tass $Source -> $out"
& $tass -C -a --cbm-prg -I $src -o $out $Source --quiet
if ($LASTEXITCODE -ne 0) { Fail "64tass assembly failed" }

$size = (Get-Item $out).Length
Write-Host "      $size bytes"

# --- test (identical harness to build_acme.ps1) ------------------------
if ($Test) {
    Write-Host "x16emu (headless testbench)"

    $stdin  = Join-Path $env:TEMP "x16lib-empty.in"
    $stdout = Join-Path $build "test-64tass-output.txt"
    [IO.File]::WriteAllText($stdin, "")
    if (Test-Path $stdout) { Remove-Item $stdout -Force }

    $fsroot = Join-Path $root "test_acme\fsroot"
    if (-not (Test-Path $fsroot)) { New-Item -ItemType Directory -Path $fsroot | Out-Null }
    Get-ChildItem $fsroot -File | Remove-Item -Force

    # The serial runner needs the emulator's 16C550 UARTs, mapped only
    # with -midicard plus an -sf2 font; a placeholder file is enough (the
    # registers respond even if the synth fails to init -- see
    # build_acme.ps1).
    $extra = @()
    if ($Source -like '*serial.asm') {
        $sf2 = Join-Path $build "dummy.sf2"
        [IO.File]::WriteAllText($sf2, "x16lib serial test placeholder")
        $extra = @('-sound', 'none', '-midicard', '-sf2', $sf2)
    }
    $emuArgs = @('-rom', $rom, '-fsroot', $fsroot, '-prg', $out,
                 '-run', '-warp', '-echo', '-testbench') + $extra

    # See build_acme.ps1: the -midicard cold start can stall before the
    # guest runs, so retry the run (up to 3 attempts) until a DONE line
    # appears. Runs without -midicard reach DONE first try and never retry.
    $text = ""
    $got  = $false
    for ($attempt = 1; ($attempt -le 3) -and (-not $got); $attempt++) {
        if (Test-Path $stdout) { Remove-Item $stdout -Force }
        $proc = Start-Process -FilePath $emu -ArgumentList $emuArgs -NoNewWindow -PassThru `
                              -RedirectStandardInput $stdin -RedirectStandardOutput $stdout
        $deadline = (Get-Date).AddSeconds(60)
        while ($true) {
            Start-Sleep -Milliseconds 200
            if (Test-Path $stdout) {
                $text = (Get-Content $stdout -Raw -ErrorAction SilentlyContinue) -replace "`r", ""
                if ($text -match '(?m)^DONE ') { $got = $true; break }
            }
            if ($proc.HasExited) { break }
            if ((Get-Date) -gt $deadline) { break }
        }
        if (-not $proc.HasExited) { $proc.Kill() }
        $proc.WaitForExit()
        if ((-not $got) -and ($attempt -lt 3)) {
            Write-Host "  no DONE line -- retrying the emulator run" -ForegroundColor Yellow
        }
    }

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
