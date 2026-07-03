#Requires -Version 5.1
<#
.SYNOPSIS
    End-to-end smoke test for the iep-node Windows installer package.

.DESCRIPTION
    Builds (if needed), installs, starts the node, polls a few APIs, stops, uninstalls.
    CI-friendly: exits non-zero on any failure; cleans up via finally block.
    Local-friendly: run `.\test\test-installer.ps1` from the project root or this dir.

.PARAMETER TestEnv
    Network environment to install (testnet|mainnet). Default: testnet.

.PARAMETER ApiPort
    API port to poll. Default: 9876 (testnet) or 23457 (mainnet).

.PARAMETER ReadyTimeoutSec
    Seconds to wait for the API to come up. Default: 90.

.PARAMETER AdminPassword
    Admin password for the install. Default: Smoketest123!.

.PARAMETER Rebuild
    Force a fresh installer build before testing.

.PARAMETER Keep
    Skip cleanup so the install can be inspected.
#>
param(
    [ValidateSet('testnet','mainnet')] [string]$TestEnv = 'mainnet',
    [int]$ApiPort = 0,
    [string]$ApiHost = '127.0.0.1',
    [int]$ReadyTimeoutSec = 90,
    [string]$AdminPassword = 'Smoketest123!',
    [switch]$Rebuild,
    [switch]$Keep
)

$ErrorActionPreference = 'Stop'

if ($ApiPort -eq 0) {
    $ApiPort = if ($TestEnv -eq 'testnet') { 9876 } else { 23457 }
}
$PeerPort = if ($TestEnv -eq 'testnet') { 8776 } else { 23456 }

function Test-PortInUse([int]$port) {
    try {
        $listeners = Get-NetTCPConnection -LocalPort $port -State Listen -ErrorAction Stop
        return $listeners.Count -gt 0
    } catch { return $false }
}

$ScriptDir    = Split-Path -Parent $MyInvocation.MyCommand.Path
$InstallerDir = Resolve-Path (Join-Path $ScriptDir '..')
$InstallerJar = Join-Path $InstallerDir 'build\distributions\iep-node-installer.jar'

$TestRoot    = Join-Path ([System.IO.Path]::GetTempPath()) ("iep-installer-test-" + [Guid]::NewGuid().ToString('N').Substring(0,8))
$InstallPath = Join-Path $TestRoot 'install'
$OptionsFile = Join-Path $TestRoot 'options.txt'
$NodeHomeDir = Join-Path $env:USERPROFILE '.iep'   # iep-node writes here (Java user.home, not redirectable cleanly)

# Safety: refuse to run if the user already has an iep-node data dir in their profile.
# The test would either fail on a stale DB or pollute a real wallet.
$AllowClobber = $env:CLOBBER_HOME -eq '1'
if ((Test-Path $NodeHomeDir) -and -not $AllowClobber) {
    Write-Error @"
$NodeHomeDir already exists.
iep-node always writes its data dir under %USERPROFILE%\.iep, so this test would
either crash on a stale DB or pollute a real wallet's data.

Either:
  - back it up + remove it, then re-run; or
  - re-run with `$env:CLOBBER_HOME='1'` to allow the test to delete it on cleanup.
"@
    exit 2
}

$nodeProc = $null

function Log    { param($m) Write-Host "[test-installer] $m" }
function Fail   { param($m) Write-Error "[test-installer][FAIL] $m"; exit 1 }

# Cleanup runs only on success OR if -Keep was set. On failure, install + node
# home are preserved so console.log + xin.log can be inspected.
function Cleanup {
    param([bool]$Success)
    if (-not $Success) {
        Write-Host @"

[test-installer] preserving artifacts for analysis:
  install root: $TestRoot
    install:    $InstallPath
    install.log $TestRoot\install.log
    start.out:  $TestRoot\start.out
  node home:    $NodeHomeDir
    console:    $NodeHomeDir\logs\console.log
    xin.log:    $NodeHomeDir\logs\xin.log

  node may still be running (pid=$($nodeProc.Id)).
  to clean up manually after analysis:
    & '$InstallPath\bin\stop.bat'
    & '$InstallPath\jre\bin\java.exe' -jar '$InstallPath\Uninstaller\uninstaller.jar' -c -f
    Remove-Item -Recurse -Force '$TestRoot','$NodeHomeDir'
"@
        return
    }
    if ($Keep) { Log "Keep set; leaving $TestRoot and $NodeHomeDir for inspection"; return }

    if ($nodeProc -and -not $nodeProc.HasExited) {
        Log "stopping node via bin\stop.bat (pid=$($nodeProc.Id))"
        $stopBat = Join-Path $InstallPath 'bin\stop.bat'
        if (Test-Path $stopBat) { & $stopBat | Out-Null }
        Start-Sleep -Seconds 2
        if (-not $nodeProc.HasExited) { Stop-Process -Id $nodeProc.Id -Force -ErrorAction SilentlyContinue }
    }
    Get-CimInstance Win32_Process -Filter "Name='java.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -and $_.CommandLine.Contains($InstallPath) } |
        ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }

    $uninstallerJar = Join-Path $InstallPath 'Uninstaller\uninstaller.jar'
    $bundledJava    = Join-Path $InstallPath 'jre\bin\java.exe'
    if ((Test-Path $uninstallerJar) -and (Test-Path $bundledJava)) {
        Log "running izpack uninstaller"
        & $bundledJava '-jar' $uninstallerJar '-c' '-f' | Out-Null
    }
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $TestRoot
    if (Test-Path $NodeHomeDir) {
        Log "removing test-created node home: $NodeHomeDir"
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue $NodeHomeDir
    }
    Log "cleaned $TestRoot"
}

$success = $false
try {
    # 0. Pre-flight: refuse on port collisions or stale iep-node.
    Log "preflight: checking ports $ApiPort (api) and $PeerPort (peer) free, no stale iep-node processes"
    if (Test-PortInUse $ApiPort)  { Fail "API port $ApiPort is already in use (Get-NetTCPConnection -LocalPort $ApiPort)" }
    if (Test-PortInUse $PeerPort) { Fail "peer port $PeerPort is already in use" }
    $existing = Get-CimInstance Win32_Process -Filter "Name='java.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -and $_.CommandLine.Contains('xin.Xin') }
    if ($existing) { Fail "iep-node process(es) already running: $($existing.ProcessId -join ', ')" }

    # 1. Build the windows installer via the wrapper. Always run it — gradle's
    #    UP-TO-DATE checks make it cheap if nothing changed, and this guarantees
    #    iep-node-installer.jar is the WINDOWS-flavoured one (build-docker.sh
    #    builds all three platforms and the last writer wins on the shared .jar).
    Log "ensuring installer is windows-flavoured (create-win-installer.bat / .sh)"
    Push-Location $InstallerDir
    try {
        $createWin = if (Test-Path '.\create-win-installer.bat') { '.\create-win-installer.bat' } else { '.\create-win-installer.sh' }
        & $createWin | Out-File -FilePath (Join-Path $TestRoot 'build.log')
        if ($LASTEXITCODE -ne 0) {
            Get-Content (Join-Path $TestRoot 'build.log') -Tail 30
            Fail "installer build failed"
        }
    } finally { Pop-Location }
    if (-not (Test-Path $InstallerJar)) { Fail "installer jar not found at $InstallerJar" }
    Log "using installer: $InstallerJar ($([math]::Round((Get-Item $InstallerJar).Length/1MB,1)) MB)"

    # 2. Generate options file.
    @"
INSTALL_PATH=$InstallPath
iep.installer.targetEnv=$TestEnv
xin.installer.startAfterInstallation=false
iep.installer.xin.adminPassword=$AdminPassword
"@ | Set-Content -Path $OptionsFile -Encoding ascii

    # 3. Install (unattended). Redirect stdin from $null so izpack 5's console mode
    #    doesn't prompt for language confirmation when run from an interactive shell.
    Log "installing to $InstallPath (env=$TestEnv)"
    $installLog = Join-Path $TestRoot 'install.log'
    $installProc = Start-Process -FilePath 'java' `
        -ArgumentList '-jar', $InstallerJar, '-options', $OptionsFile `
        -RedirectStandardInput 'NUL' `
        -RedirectStandardOutput $installLog `
        -RedirectStandardError  ($installLog + '.err') `
        -PassThru -Wait -NoNewWindow
    if ($installProc.ExitCode -ne 0) {
        Get-Content $installLog -Tail 30
        Fail "install failed"
    }
    if (-not (Select-String -Path (Join-Path $TestRoot 'install.log') -Pattern 'Console installation done' -Quiet)) {
        Get-Content (Join-Path $TestRoot 'install.log') -Tail 30
        Fail "install did not complete"
    }

    # 4. Verify install layout + bundled JRE.
    foreach ($d in 'bin','jre','lib','scripts','legacy_libs') {
        if (-not (Test-Path (Join-Path $InstallPath $d))) { Fail "missing $d in install" }
    }
    $bundledJava = Join-Path $InstallPath 'jre\bin\java.exe'
    if (-not (Test-Path $bundledJava)) { Fail "bundled JRE binary missing: $bundledJava" }
    $jreVersion = & $bundledJava '-version' 2>&1 | Select-Object -First 1
    if ($jreVersion -notmatch '21\.') { Fail "bundled JRE is not JDK 21: $jreVersion" }
    Log "bundled JRE: $jreVersion"
    if (-not (Test-Path (Join-Path $InstallPath 'legacy_libs\h2-1.4.191.jar'))) {
        Fail 'H2 1.4 legacy migrator jar missing'
    }

    # 5. Start node. `start.bat` launches `bin\iep-node` and exits; the daemon
    #    can be found via the running java process whose cmdline references
    #    our install path.
    Log "starting node via bin\start.bat"
    $startBat = Join-Path $InstallPath 'bin\start.bat'
    Start-Process -FilePath $startBat -WindowStyle Hidden `
        -RedirectStandardOutput (Join-Path $TestRoot 'start.out') `
        -RedirectStandardError  (Join-Path $TestRoot 'start.err') | Out-Null
    $nodeProc = $null
    for ($i = 0; $i -lt 15; $i++) {
        $found = Get-CimInstance Win32_Process -Filter "Name='java.exe'" -ErrorAction SilentlyContinue |
            Where-Object { $_.CommandLine -and $_.CommandLine.Contains($InstallPath) -and $_.CommandLine.Contains('xin.Xin') } |
            Select-Object -First 1
        if ($found) { $nodeProc = Get-Process -Id $found.ProcessId -ErrorAction SilentlyContinue; break }
        Start-Sleep -Seconds 1
    }
    if (-not $nodeProc) { Fail "iep-node java process not found within 15s of starting bin\start.bat" }
    Log "node daemon pid=$($nodeProc.Id); polling http://${ApiHost}:${ApiPort}"

    # 6. Wait for API. While waiting, scan logs for bind errors and fail fast.
    $deadline = (Get-Date).AddSeconds($ReadyTimeoutSec)
    $bcsUrl = "http://${ApiHost}:${ApiPort}/api?requestType=getBlockchainStatus"
    $consoleLog = Join-Path $NodeHomeDir 'logs\console.log'
    $xinLog     = Join-Path $NodeHomeDir 'logs\xin.log'
    $bcs = $null
    while ($true) {
        foreach ($f in @($consoleLog, $xinLog)) {
            if ((Test-Path $f) -and (Select-String -Path $f -Pattern 'BindException|Address already in use|Failed to start' -Quiet)) {
                Get-Content $f | Select-String -Pattern 'BindException|Address already in use|Failed to start' | Select-Object -First 5 | ForEach-Object { Write-Host $_.Line }
                Fail "node failed to bind ports — aborting (test root + node home preserved)"
            }
        }
        try {
            $bcs = Invoke-RestMethod -Uri $bcsUrl -TimeoutSec 5 -ErrorAction Stop
            if ($nodeProc -and -not $nodeProc.HasExited) { break }
            Fail "API responded but our node process has exited — somebody else is on port $ApiPort"
        } catch { }
        if ((Get-Date) -gt $deadline) {
            if (Test-Path $consoleLog) { Get-Content $consoleLog -Tail 40 }
            Fail "API never came up within ${ReadyTimeoutSec}s"
        }
        Start-Sleep -Seconds 2
    }
    Log "getBlockchainStatus.application=$($bcs.application), version=$($bcs.version), numberOfBlocks=$($bcs.numberOfBlocks)"

    # 7. Service checks.

    # 7a. Peer service — peer port must be in LISTEN state.
    if (-not (Test-PortInUse $PeerPort)) { Fail "peer service not listening on port $PeerPort" }
    Log "peer service listening on $PeerPort"

    # 7b. getBlockchainStatus content (the main blockchain subsystem).
    if ($bcs.application -ne 'XIN')          { Fail "getBlockchainStatus did not report application=XIN" }
    if ($null -eq $bcs.numberOfBlocks)       { Fail "getBlockchainStatus missing numberOfBlocks" }
    if ([string]::IsNullOrEmpty($bcs.version)) { Fail "getBlockchainStatus missing version" }

    # 7c. getTime — simplest API sanity check.
    $time = Invoke-RestMethod -Uri "http://${ApiHost}:${ApiPort}/api?requestType=getTime" -TimeoutSec 5
    if ($null -eq $time.time) { Fail "getTime did not return a numeric time field" }

    # 7d. getPeers — verifies the peer subsystem is initialised and queryable.
    $peersResp = Invoke-RestMethod -Uri "http://${ApiHost}:${ApiPort}/api?requestType=getPeers" -TimeoutSec 10
    if ($null -eq $peersResp.peers) { Fail "getPeers did not return a peers array" }

    # 7d.bis. /wallet/index.html — the desktop opens this URL on launch.
    #         iep-node serves /wallet/* from <install>\html\www\. Without the
    #         wallet UI bundled there, jetty returns 404 and the desktop shows
    #         "HTTP ERROR 404 Not Found". The Docker build of iep-node
    #         (Dockerfile lines 7-10) copies iep-wallet-ui.zip into html\www\wallet\;
    #         the installer build path needs an equivalent step.
    try {
        $walletResp = Invoke-WebRequest -Uri "http://${ApiHost}:${ApiPort}/wallet/index.html" -TimeoutSec 5 -UseBasicParsing
        if ($walletResp.StatusCode -ne 200) {
            Fail "/wallet/index.html returned HTTP $($walletResp.StatusCode) (expected 200) — wallet UI is not bundled."
        }
    } catch {
        Fail "/wallet/index.html unreachable or non-200 — wallet UI not bundled. Expected at: $InstallPath\html\www\wallet\index.html. Fix: bundle iep-wallet-ui.zip into iep-node's distZip (mirror Dockerfile lines 7-10)."
    }
    Log "/wallet/index.html responds 200 (desktop wallet UI bundled)"

    # 7e. getState — heavier (counts assets/orders/etc.); best-effort only.
    $stateUrl = "http://${ApiHost}:${ApiPort}/api?requestType=getState"
    try {
        $state = Invoke-RestMethod -Uri $stateUrl -TimeoutSec 15 -ErrorAction Stop
        if ($null -eq $state.numberOfPeers) { Fail "getState response missing numberOfPeers" }
        Log "getState.numberOfPeers=$($state.numberOfPeers), isDownloading=$($state.isDownloading)"
    } catch {
        Log "getState did not respond within 15s — non-fatal, continuing"
    }

    Log "all checks passed"
    $success = $true
    exit 0
}
finally {
    Cleanup -Success $success
}
