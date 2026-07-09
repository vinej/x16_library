<#
.SYNOPSIS
    Assemble an x16lib program with ACME and optionally run it.

.EXAMPLE
    .\build.ps1                                   # assemble examples\hello.asm
    .\build.ps1 -Run                              # ...and run it windowed
    .\build.ps1 -Source examples\hello.asm -Run
    .\build.ps1 -Test                             # headless regression suite
#>
param(
    [string]$Source = "examples\hello.asm",
    [switch]$Run,
    [switch]$Test,
    [int]$Scale = 2
)

$ErrorActionPreference = "Stop"

# Always leave a real process exit code behind: `throw` does not set one,
# so a CI step running this script would see success after a failed test.
function Fail([string]$message) {
    Write-Host $message -ForegroundColor Red
    exit 1
}

$root  = $PSScriptRoot
$acme  = Join-Path $root "acme\acme.exe"
$emu   = Join-Path $root "emulator\x16emu.exe"
$rom   = Join-Path $root "emulator\rom.bin"
$src   = Join-Path $root "src"
$build = Join-Path $root "build"

foreach ($tool in @($acme, $emu, $rom)) {
    if (-not (Test-Path $tool)) { Fail "missing: $tool" }
}
if (-not (Test-Path $build)) { New-Item -ItemType Directory -Path $build | Out-Null }

# -Test defaults to the suite, but an explicit -Source still wins (handy
# for running a mutated runner to prove the harness can actually fail).
if ($Test -and -not $PSBoundParameters.ContainsKey('Source')) {
    $Source = "test\runner.asm"
}

$name = [IO.Path]::GetFileNameWithoutExtension($Source).ToUpper()
$out  = Join-Path $build "$name.PRG"

# --- assemble --------------------------------------------------------
# ACME resolves !source against the CWD, so -I puts src/ on the path and
# lets every module include its siblings by a stable relative name.
Write-Host "acme  $Source -> $out"
& $acme -I $src -f cbm -o $out $Source
if ($LASTEXITCODE -ne 0) { Fail "assembly failed" }

$size = (Get-Item $out).Length
Write-Host "      $size bytes"

# --- test ------------------------------------------------------------
if ($Test) {
    Write-Host "x16emu (headless testbench)"

    # x16emu -testbench only exits at stdin EOF, and it only reads stdin
    # once it has printed its own "RDY" prompt -- which it never does if
    # the guest program leaves BASIC in an odd state. So don't wait on the
    # process: watch its output for our DONE line, then stop it ourselves.
    $stdin  = Join-Path $env:TEMP "x16lib-empty.in"
    $stdout = Join-Path $build "test-output.txt"
    [IO.File]::WriteAllText($stdin, "")
    if (Test-Path $stdout) { Remove-Item $stdout -Force }

    $emuArgs = @('-rom', $rom, '-prg', $out, '-run', '-warp', '-echo', '-testbench')
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
            Fail "emulator timed out after 60s -- no DONE line; the test program never finished"
        }
    }
    if (-not $proc.HasExited) { $proc.Kill() }
    $proc.WaitForExit()

    $passes = ([regex]::Matches($text, '(?m)^PASS (\S+)')).Count
    $fails  = [regex]::Matches($text, '(?m)^FAIL (\S+)')
    $done   = [regex]::Match($text, '(?m)^DONE ([0-9A-F]{2})/([0-9A-F]{2})')

    foreach ($f in $fails) { Write-Host ("  FAIL {0}" -f $f.Groups[1].Value) -ForegroundColor Red }

    if (-not $done.Success) {
        Fail "test run produced no DONE line -- the program never finished"
    }

    $reportedPass  = [Convert]::ToInt32($done.Groups[1].Value, 16)
    $reportedTotal = [Convert]::ToInt32($done.Groups[2].Value, 16)

    if ($reportedTotal -eq 0) { Fail "no tests ran" }
    if ($passes -ne $reportedPass) {
        Fail "output is inconsistent: $passes PASS lines but DONE says $reportedPass"
    }
    if ($fails.Count -gt 0 -or $reportedPass -ne $reportedTotal) {
        Fail "$($reportedTotal - $reportedPass) of $reportedTotal tests failed"
    }

    Write-Host "      $reportedPass/$reportedTotal tests passed" -ForegroundColor Green
    exit 0
}

# --- run -------------------------------------------------------------
if ($Run) {
    Write-Host "x16emu $out"
    & $emu -rom $rom -prg $out -run -scale $Scale
}
