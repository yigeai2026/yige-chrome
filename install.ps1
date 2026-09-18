# One-user Windows installer. No administrator rights, global policy changes,
# process termination, browser profile edits, or automatic browser actions.
[CmdletBinding()]
param(
    [switch]$AcceptLicense,
    [switch]$ConfigureCodex,
    [string]$InstallRoot,
    [string]$CodexConfigDirectory,
    [string]$PackagePath
)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
if (-not $AcceptLicense) { throw 'Read LICENSE.txt first. Run with -AcceptLicense only after the user accepts the free trial license.' }
if ($env:OS -ne 'Windows_NT' -or [System.Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString() -ne 'X64') {
    throw 'This trial supports Windows x64 only.'
}
if (-not $env:LOCALAPPDATA) { throw 'LOCALAPPDATA is unavailable. Use a regular Windows user session.' }
$packageName = 'yige-0.5.7-windows-x64-trial.1'
$packageHash = '1b0508a9536ec92ded455b87d9111f208a6df717854dfd125b9b17d4956d8bab'
$packageBytes = 44328949
$packageUrl = "https://github.com/yigeai2026/yige-chrome/releases/download/v0.5.7-trial.1/$packageName.zip"
$utf8 = New-Object System.Text.UTF8Encoding($false)
if (-not $InstallRoot) { $InstallRoot = Join-Path $env:LOCALAPPDATA 'Yige\apps' }
$InstallRoot = [System.IO.Path]::GetFullPath($InstallRoot)
$destination = Join-Path $InstallRoot $packageName
$nodePath = Join-Path $destination 'node-runtime\node.exe'
$serverPath = Join-Path $destination 'server.mjs'
$dataDirectory = if ($env:YIGEAI_DATA_DIR) { [System.IO.Path]::GetFullPath($env:YIGEAI_DATA_DIR) } else { Join-Path $env:LOCALAPPDATA 'yigeai-chrome' }
if (-not $CodexConfigDirectory) { $CodexConfigDirectory = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path ([Environment]::GetFolderPath('UserProfile')) '.codex' } }
$CodexConfigDirectory = [System.IO.Path]::GetFullPath($CodexConfigDirectory)
$configPath = Join-Path $CodexConfigDirectory 'config.toml'
$skillPath = Join-Path $CodexConfigDirectory 'skills\yigeai-chrome'
function Quote-TomlPath([string]$Value) { return ConvertTo-Json -InputObject ($Value.Replace('\', '/')) -Compress }
function Get-Sha256([string]$Path) {
    $algorithm = [System.Security.Cryptography.SHA256]::Create()
    $stream = [System.IO.File]::OpenRead($Path)
    try { return [BitConverter]::ToString($algorithm.ComputeHash($stream)).Replace('-', '').ToLowerInvariant() }
    finally { $stream.Dispose(); $algorithm.Dispose() }
}
$mcpBlock = @(
    '# BEGIN YIGE INSTALLER MCP'
    '[mcp_servers.yigeai-chrome]'
    ('command = ' + (Quote-TomlPath $nodePath))
    ('args = [' + (Quote-TomlPath $serverPath) + ']')
    'startup_timeout_sec = 20'
    'tool_timeout_sec = 120'
    '[mcp_servers.yigeai-chrome.env]'
    ('YIGEAI_DATA_DIR = ' + (Quote-TomlPath $dataDirectory))
    '# END YIGE INSTALLER MCP'
) -join "`n"
function Read-CodexState {
    $text = if (Test-Path -LiteralPath $configPath) { [System.IO.File]::ReadAllText($configPath) } else { '' }
    $normalized = $text.Replace("`r`n", "`n")
    if ($normalized.Contains($mcpBlock)) { return @{ Text = $text; NeedsWrite = $false } }
    # Deliberately refuse ambiguous/manual/inline definitions instead of editing
    # arbitrary TOML or displaying other providers' credentials.
    if ($text -match 'yigeai-chrome' -or $text -match '(?im)^\s*["'']?mcp_servers["'']?\s*=') {
        throw 'CODEX_CONFIG_NEEDS_REVIEW: existing Yige or inline MCP configuration found. It was not changed. Merge only the Yige section after reviewing it.'
    }
    return @{ Text = $text; NeedsWrite = $true }
}
function Get-TreeSignature([string]$Directory) {
    return @((Get-ChildItem -LiteralPath $Directory -File -Recurse | ForEach-Object {
        $_.FullName.Substring($Directory.Length).Replace('\', '/') + ':' + (Get-Sha256 $_.FullName)
    } | Sort-Object)) -join "`n"
}
$mutex = New-Object System.Threading.Mutex($false, 'Local\YigeTrialInstaller')
$locked = $false
try {
    $locked = $mutex.WaitOne(0)
    if (-not $locked) { throw 'Another Yige installer is running. Wait for it to finish.' }
    $codexState = if ($ConfigureCodex) { Read-CodexState } else { $null }
    $receiptPath = Join-Path $destination 'INSTALL-RECEIPT.json'
    if (Test-Path -LiteralPath $destination) {
        if (-not (Test-Path -LiteralPath $receiptPath)) { throw 'INSTALL_DIRECTORY_EXISTS: choose a fresh InstallRoot or review the incomplete installation; no files were replaced.' }
        $receipt = Get-Content -LiteralPath $receiptPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($receipt.packageSha256 -ne $packageHash -or -not (Test-Path -LiteralPath $nodePath) -or -not (Test-Path -LiteralPath $serverPath)) {
            throw 'INSTALL_DIRECTORY_MISMATCH: existing files were not replaced.'
        }
        $packageState = 'existing_installation'
    } else {
        $temporary = Join-Path ([System.IO.Path]::GetTempPath()) ('yige-download-' + [guid]::NewGuid().ToString('N'))
        [void](New-Item -ItemType Directory -Path $temporary)
        $archive = Join-Path $temporary ($packageName + '.zip')
        if ($PackagePath) {
            Copy-Item -LiteralPath ([System.IO.Path]::GetFullPath($PackagePath)) -Destination $archive
        } else {
            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
            Invoke-WebRequest -Uri $packageUrl -OutFile $archive -UseBasicParsing
        }
        if ((Get-Item -LiteralPath $archive).Length -ne $packageBytes -or (Get-Sha256 $archive) -ne $packageHash) {
            throw 'PACKAGE_HASH_MISMATCH: download was not executed or extracted.'
        }
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $zip = [System.IO.Compression.ZipFile]::OpenRead($archive)
        try {
            foreach ($entry in $zip.Entries) {
                $name = $entry.FullName.Replace('\', '/')
                if (-not $name.StartsWith($packageName + '/') -or $name -match '(^|/)\.\.(/|$)|:|^/') {
                    throw 'UNEXPECTED_ARCHIVE_PATH: archive was not extracted.'
                }
            }
        } finally { $zip.Dispose() }
        $expanded = Join-Path $temporary 'expanded'
        [System.IO.Compression.ZipFile]::ExtractToDirectory($archive, $expanded)
        [void](New-Item -ItemType Directory -Path $InstallRoot -Force)
        Move-Item -LiteralPath (Join-Path $expanded $packageName) -Destination $destination
        [System.IO.File]::WriteAllText($receiptPath, (@{ packageSha256 = $packageHash; package = $packageName; configured = $false } | ConvertTo-Json), $utf8)
        $packageState = 'download_verified_and_installed'
    }
    $sourceSkill = Join-Path $destination 'skills\use-local-chrome'
    if ($ConfigureCodex -and (Test-Path -LiteralPath $skillPath) -and (Get-TreeSignature $skillPath) -ne (Get-TreeSignature $sourceSkill)) {
        throw 'CODEX_SKILL_NEEDS_REVIEW: existing Yige skill differs. It was not overwritten; MCP configuration is unchanged.'
    }
    # The verified bundled setup generates pairing locally. Do not log its token.
    & $nodePath (Join-Path $destination 'distribution\setup-trial.mjs')
    if ($LASTEXITCODE -ne 0) { throw 'LOCAL_SETUP_FAILED: review setup output; MCP configuration is unchanged.' }
    $jsonPath = Join-Path $destination 'client-config\mcp.json'
    $jsonConfig = Get-Content -LiteralPath $jsonPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $jsonConfig.mcpServers.'yigeai-chrome' | Add-Member -NotePropertyName env -NotePropertyValue @{ YIGEAI_DATA_DIR = $dataDirectory } -Force
    [System.IO.File]::WriteAllText($jsonPath, ($jsonConfig | ConvertTo-Json -Depth 8), $utf8)
    [System.IO.File]::WriteAllText((Join-Path $destination 'client-config\codex.toml'), $mcpBlock + "`n", $utf8)
    $configState = 'examples_only'
    $backup = $null
    if ($ConfigureCodex) {
        # Re-read immediately before writing to avoid overwriting a concurrent edit.
        $current = Read-CodexState
        if ($current.Text -cne $codexState.Text) { throw 'CODEX_CONFIG_CHANGED: another process changed the file. No config was written.' }
        [void](New-Item -ItemType Directory -Path $CodexConfigDirectory -Force)
        if ($current.NeedsWrite) {
            $suffix = [guid]::NewGuid().ToString('N')
            $temporaryConfig = $configPath + '.yige-' + $suffix + '.tmp'
            [System.IO.File]::WriteAllText($temporaryConfig, $current.Text + "`n`n" + $mcpBlock + "`n", $utf8)
            if (Test-Path -LiteralPath $configPath) {
                $backup = $configPath + '.before-yige-' + $suffix + '.bak'
                [System.IO.File]::Replace($temporaryConfig, $configPath, $backup)
            } else { Move-Item -LiteralPath $temporaryConfig -Destination $configPath }
            $configState = 'added_with_backup_if_existing'
        } else { $configState = 'already_configured' }
        if (-not (Test-Path -LiteralPath $skillPath)) {
            [void](New-Item -ItemType Directory -Path (Split-Path $skillPath -Parent) -Force)
            Copy-Item -LiteralPath $sourceSkill -Destination $skillPath -Recurse
        }
    }
    [System.IO.File]::WriteAllText($receiptPath, (@{ packageSha256 = $packageHash; package = $packageName; configured = $true; configuredAt = [DateTime]::UtcNow.ToString('o') } | ConvertTo-Json), $utf8)
    @{
        package = $packageName; packageState = $packageState; codex = $configState
        codexConfig = $(if ($ConfigureCodex) { $configPath } else { $null }); configBackup = $backup
        skill = $(if ($ConfigureCodex) { $skillPath } else { $null })
        extensionDirectory = (Join-Path $destination 'extension'); clientExamples = (Join-Path $destination 'client-config')
        browserConnection = 'not_tested'; next = 'Load the extension in Chrome, reconnect Codex, explicitly share a test tab, then run status/list/snapshot.'
    } | ConvertTo-Json -Depth 4
} finally {
    if ($locked) { $mutex.ReleaseMutex() }
    $mutex.Dispose()
}
