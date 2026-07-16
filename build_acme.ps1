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
$src   = Join-Path $root "src_acme"
$build = Join-Path $root "build"

foreach ($tool in @($acme, $emu, $rom)) {
    if (-not (Test-Path $tool)) { Fail "missing: $tool" }
}
if (-not (Test-Path $build)) { New-Item -ItemType Directory -Path $build | Out-Null }

# --- assemble --------------------------------------------------------
# ACME resolves !source against the CWD, so -I puts src/ on the path and
# lets every module include its siblings by a stable relative name.
function Build-Prg([string]$sourcePath) {
    $name = [IO.Path]::GetFileNameWithoutExtension($sourcePath).ToUpper()
    $out  = Join-Path $build "$name.PRG"
    Write-Host "acme  $sourcePath -> $out"
    & $acme -I $src -f cbm -o $out $sourcePath
    if ($LASTEXITCODE -ne 0) { Fail "assembly failed" }
    $size = (Get-Item $out).Length
    Write-Host "      $size bytes"
    # A PRG larger than $0801-$9EFF spills into I/O space when it loads
    # and crashes in ways that look nothing like the real cause. That is
    # why the test suite is split across runner PRGs.
    if ($size -gt 38399) { Fail "$out is $size bytes: past the `$9EFF load ceiling" }
    return $out
}

# --- test ------------------------------------------------------------
# One emulator pass over one PRG: returns @(passes, total, skips).
function Invoke-TestPrg([string]$out) {
    # x16emu -testbench only exits at stdin EOF, and it only reads stdin
    # once it has printed its own "RDY" prompt -- which it never does if
    # the guest program leaves BASIC in an odd state. So don't wait on the
    # process: watch its output for our DONE line, then stop it ourselves.
    $stdin  = Join-Path $env:TEMP "x16lib-empty.in"
    $stdout = Join-Path $build "test-output.txt"
    [IO.File]::WriteAllText($stdin, "")
    if (Test-Path $stdout) { Remove-Item $stdout -Force }

    # Point device 8 at a scratch directory so the load/save tests are
    # hermetic and never touch a real SD-card image.
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
            Fail "emulator timed out after 60s -- no DONE line; the test program never finished"
        }
    }
    if (-not $proc.HasExited) { $proc.Kill() }
    $proc.WaitForExit()

    # Names are [A-Z0-9_]. Don't use \S+: a result line ends without a CR,
    # so whatever the next test prints first (a CLS control byte, say)
    # lands on the same line and would be captured as part of the name.
    $passes = ([regex]::Matches($text, '(?m)^PASS ([A-Z0-9_]+)')).Count
    $fails  = [regex]::Matches($text, '(?m)^FAIL ([A-Z0-9_]+)')
    $skips  = [regex]::Matches($text, '(?m)^SKIP ([A-Z0-9_]+)')
    $done   = [regex]::Match($text, '(?m)^DONE ([0-9A-F]{2})/([0-9A-F]{2})')

    foreach ($f in $fails) { Write-Host ("  FAIL {0}" -f $f.Groups[1].Value) -ForegroundColor Red }
    foreach ($s in $skips) { Write-Host ("  SKIP {0}" -f $s.Groups[1].Value) -ForegroundColor Yellow }

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
    return @($reportedPass, $reportedTotal, $skips.Count)
}

if ($Test) {
    # The suite spans several PRGs (one grew past the load ceiling). An
    # explicit -Source still runs alone -- handy for running a mutated
    # runner to prove the harness can actually fail.
    $sources = @("test_acme\runner.asm", "test_acme\runner2.asm")
    if ($PSBoundParameters.ContainsKey('Source')) { $sources = @($Source) }

    $sumPass = 0
    $sumTotal = 0
    $sumSkip = 0
    foreach ($s in $sources) {
        $out = Build-Prg $s
        Write-Host "x16emu (headless testbench)"
        $r = Invoke-TestPrg $out
        $sumPass  += $r[0]
        $sumTotal += $r[1]
        $sumSkip  += $r[2]
    }

    $summary = "      $sumPass/$sumTotal tests passed"
    if ($sumSkip -gt 0) {
        # Skips are excluded from the pass/total, so they can never be
        # mistaken for passes. Surface them so they are not forgotten.
        $summary += ", $sumSkip skipped (not runnable headless)"
    }
    Write-Host $summary -ForegroundColor Green
    exit 0
}

$out = Build-Prg $Source

# --- run -------------------------------------------------------------
if ($Run) {
    Write-Host "x16emu $out"
    & $emu -rom $rom -prg $out -run -scale $Scale
}
