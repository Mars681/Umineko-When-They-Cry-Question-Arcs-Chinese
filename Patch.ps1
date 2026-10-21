param(
    [ValidateSet('Install','Restore','Verify')][string]$Mode = 'Install',
    [string]$GameDirectory
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 2

function Get-Hash([string]$Path) {
    if (-not [IO.File]::Exists($Path)) { return $null }
    $algorithm = [Security.Cryptography.SHA256]::Create()
    $stream = [IO.File]::OpenRead($Path)
    try { return ([BitConverter]::ToString($algorithm.ComputeHash($stream))).Replace('-','').ToLowerInvariant() }
    finally { $stream.Dispose(); $algorithm.Dispose() }
}
function Write-Atomic([string]$Path, [byte[]]$Bytes) {
    $temp = Join-Path ([IO.Path]::GetDirectoryName($Path)) ('.cn-' + [guid]::NewGuid().ToString('N').Substring(0,12) + '.tmp')
    try {
        [IO.File]::WriteAllBytes($temp, $Bytes)
        if ([IO.File]::Exists($Path)) { [IO.File]::Replace($temp, $Path, [NullString]::Value) }
        else { [IO.File]::Move($temp, $Path) }
    } finally {
        if ([IO.File]::Exists($temp)) { [IO.File]::Delete($temp) }
    }
}
function Assert-PlainPath([string]$Path) {
    if (Test-Path -LiteralPath $Path) {
        if ((Get-Item -Force -LiteralPath $Path).Attributes -band [IO.FileAttributes]::ReparsePoint) {
            throw "请使用普通游戏目录；检测到链接或重定向路径：$Path"
        }
    }
}
function Get-Target([string]$Name) {
    if ($Name -notin @('0.utf','fonts/face0.otf','fonts/face1.otf','fonts/face2.otf','fonts/face3.otf')) {
        throw "安装记录包含不支持的文件名：$Name"
    }
    $path = Join-Path $script:GameRoot $Name
    Assert-PlainPath $path
    return $path
}
function Read-Json([string]$Path) {
    return [IO.File]::ReadAllText($Path, [Text.Encoding]::UTF8) | ConvertFrom-Json
}
function Write-Json([string]$Path, $Value) {
    Write-Atomic $Path ([Text.Encoding]::UTF8.GetBytes(($Value | ConvertTo-Json -Depth 8)))
}
function Build-Script([byte[]]$Base, [string]$DeltaFile, [int]$ExpectedLength, [int]$ExpectedCount) {
    $inputStream = [IO.File]::OpenRead($DeltaFile)
    $gzip = New-Object IO.Compression.GZipStream($inputStream, [IO.Compression.CompressionMode]::Decompress)
    $reader = New-Object IO.BinaryReader($gzip)
    $outputStream = New-Object IO.MemoryStream
    try {
        if ([Text.Encoding]::ASCII.GetString($reader.ReadBytes(8)) -ne 'UMICN001') { throw '补丁格式不正确。' }
        $length = $reader.ReadUInt32(); $count = $reader.ReadUInt32()
        if ($length -ne $ExpectedLength -or $count -ne $ExpectedCount) { throw '补丁头校验失败。' }
        [int]$cursor = 0
        for ($i=0; $i -lt $count; $i++) {
            [long]$position = $reader.ReadUInt32()
            [long]$remove = $reader.ReadUInt32()
            [long]$insert = $reader.ReadUInt32()
            if ($position -lt $cursor -or $position+$remove -gt $Base.Length -or $insert -gt $length) {
                throw '补丁偏移校验失败。'
            }
            if ($outputStream.Length+$position-$cursor+$insert -gt $length) { throw '补丁输出长度异常。' }
            $bytes = $reader.ReadBytes([int]$insert)
            if ($bytes.Length -ne $insert) { throw '补丁数据不完整。' }
            $outputStream.Write($Base, $cursor, [int]($position-$cursor))
            $outputStream.Write($bytes, 0, $bytes.Length)
            $cursor = [int]($position+$remove)
        }
        $outputStream.Write($Base, $cursor, $Base.Length-$cursor)
        if ($outputStream.Length -ne $length -or $reader.BaseStream.ReadByte() -ne -1) { throw '补丁长度校验失败。' }
        return ,$outputStream.ToArray()
    } finally {
        $outputStream.Dispose(); $reader.Dispose(); $gzip.Dispose(); $inputStream.Dispose()
    }
}
function Get-BytesHash([byte[]]$Bytes) {
    $algorithm = [Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($algorithm.ComputeHash($Bytes))).Replace('-','').ToLowerInvariant() }
    finally { $algorithm.Dispose() }
}
function Restore-Originals($State, [string]$Backup) {
    foreach ($record in $State.files) {
        $destination = Get-Target $record.path
        if ((Get-Hash $destination) -eq $record.originalSha256) { continue }
        if ($record.existed) {
            Write-Atomic $destination ([IO.File]::ReadAllBytes((Join-Path $Backup $record.path)))
        } elseif ([IO.File]::Exists($destination)) {
            # Only exact allow-listed files originally created by this installer are removed.
            [IO.File]::Delete($destination)
        }
    }
}

try {
    $manifest = Read-Json (Join-Path $PSScriptRoot 'manifest.json')
    if ([string]::IsNullOrWhiteSpace($GameDirectory)) {
        Add-Type -AssemblyName System.Windows.Forms
        $picker = New-Object Windows.Forms.FolderBrowserDialog
        $picker.Description = '选择 Steam 提问篇游戏目录（包含 Umineko1to4.exe 和 0.utf）'
        $picker.ShowNewFolderButton = $false
        try {
            if ($picker.ShowDialog() -ne [Windows.Forms.DialogResult]::OK) { throw '已取消，未修改游戏文件。' }
            $GameDirectory = $picker.SelectedPath
        } finally { $picker.Dispose() }
    }
    $script:GameRoot = (Resolve-Path -LiteralPath $GameDirectory).ProviderPath
    if (-not [IO.Directory]::Exists($script:GameRoot)) { throw '请选择游戏文件夹。' }
    Assert-PlainPath $script:GameRoot
    Assert-PlainPath (Join-Path $script:GameRoot 'fonts')
    $statePath = Join-Path $script:GameRoot '.umineko-cn-install.json'
    Assert-PlainPath $statePath
    $scriptPath = Get-Target '0.utf'
    if (-not [IO.File]::Exists((Join-Path $script:GameRoot 'Umineko1to4.exe')) -or -not [IO.File]::Exists($scriptPath)) {
        throw '这个文件夹不是 Steam 提问篇游戏根目录。请在 Steam 中选择“管理 → 浏览本地文件”找到正确目录。'
    }
    if (Get-Process -Name 'Umineko1to4' -ErrorAction SilentlyContinue) { throw '请先关闭正在运行的海猫提问篇，再操作补丁。' }
    $targets = @('0.utf','fonts/face0.otf','fonts/face1.otf','fonts/face2.otf','fonts/face3.otf')
    $installedHashes = @($manifest.patchedScriptSha256, $manifest.fonts[0].sha256,
                        $manifest.fonts[1].sha256, $manifest.fonts[1].sha256, $manifest.fonts[1].sha256)
    $currentHash = Get-Hash $scriptPath

    if ($Mode -eq 'Verify') {
        if ($currentHash -ne $manifest.patchedScriptSha256) { throw '当前 0.utf 不是本补丁的已安装版本。' }
        for ($i=0; $i -lt $targets.Count; $i++) {
            if ((Get-Hash (Get-Target $targets[$i])) -ne $installedHashes[$i]) { throw "文件校验失败：$($targets[$i])" }
        }
        Write-Host '校验成功：中文正文和四个字体文件完整。' -ForegroundColor Green
        exit 0
    }
    if ($Mode -eq 'Restore') {
        if (-not [IO.File]::Exists($statePath)) { throw '没有找到本安装工具创建的备份记录，无法自动恢复。请不要手动覆盖原文件后再运行恢复。' }
        $state = Read-Json $statePath
        if ($state.version -ne $manifest.version -or $state.backup -notmatch '^umineko-cn-backup-[0-9a-f]{32}$') { throw '备份记录格式不正确。' }
        if (@($state.files).Count -ne 5 -or (($state.files.path | Sort-Object) -join '|') -ne (($targets | Sort-Object) -join '|')) { throw '备份记录文件列表不正确。' }
        $backup = Join-Path $script:GameRoot $state.backup
        Assert-PlainPath $backup
        Assert-PlainPath (Join-Path $backup 'fonts')
        # Validate every original and current file before touching any game file.
        foreach ($record in $state.files) {
            $destination = Get-Target $record.path
            $original = Join-Path $backup $record.path
            Assert-PlainPath $original
            if ($record.existed -and (Get-Hash $original) -ne $record.originalSha256) { throw "备份已变动或丢失：$($record.path)" }
            $actual = Get-Hash $destination
            $index = [array]::IndexOf($targets, [string]$record.path)
            if ($actual -ne $installedHashes[$index] -and -not ($record.existed -and $actual -eq $record.originalSha256) -and -not (-not $record.existed -and $null -eq $actual)) {
                throw "安装后文件已被其他操作改变，停止恢复以保护文件：$($record.path)"
            }
        }
        Restore-Originals $state $backup
        foreach ($record in $state.files) {
            if ((Get-Hash (Get-Target $record.path)) -ne $record.originalSha256) { throw '恢复后校验失败；请保留备份目录。' }
        }
        [IO.File]::Delete($statePath)
        Write-Host '恢复完成。安装前的脚本和字体已还原，存档未改动。备份目录仍保留。' -ForegroundColor Green
        exit 0
    }

    if ($currentHash -eq $manifest.patchedScriptSha256) {
        for ($i=0; $i -lt $targets.Count; $i++) {
            if ((Get-Hash (Get-Target $targets[$i])) -ne $installedHashes[$i]) { throw '正文已经是中文版，但字体不完整。请先恢复后重新安装，或按说明补齐字体。' }
        }
        Write-Host '已经安装此版本，所有文件校验通过，无需重复安装。' -ForegroundColor Green
        exit 0
    }
    if ($currentHash -ne $manifest.baseScriptSha256) { throw '0.utf 与支持的 Steam 原版不同，未作任何修改。请先备份自己的模组，再通过 Steam 验证游戏文件完整性。不要将本补丁叠加到 07th-Mod 或其他汉化上。' }
    if ((Get-Hash (Join-Path $script:GameRoot 'Umineko1to4.exe')) -ne $manifest.executableSha256) { throw '游戏程序与已验证版本不同，未安装。请使用 Steam Windows 提问篇原版。' }
    if ([IO.File]::Exists($statePath)) { throw '发现此前安装记录。请先运行 Restore.bat 完成恢复，再重新安装。' }
    $deltaPath = Join-Path $PSScriptRoot 'payload/dialogue.delta.gz'
    if ((Get-Hash $deltaPath) -ne $manifest.deltaSha256) { throw '补丁数据校验失败，请重新下载完整补丁包。' }
    foreach ($font in $manifest.fonts) {
        if ((Get-Hash (Join-Path $PSScriptRoot ('payload/'+$font.file))) -ne $font.sha256) { throw "字体校验失败：$($font.file)。请重新下载完整补丁包。" }
    }
    Write-Host '正在生成中文脚本并校验……'
    $patched = Build-Script ([IO.File]::ReadAllBytes($scriptPath)) $deltaPath $manifest.patchedScriptBytes $manifest.deltaOperations
    if ((Get-BytesHash $patched) -ne $manifest.patchedScriptSha256) { throw '生成的中文脚本校验失败，原游戏未修改。' }
    $backupName = 'umineko-cn-backup-' + [guid]::NewGuid().ToString('N')
    $backup = Join-Path $script:GameRoot $backupName
    [void][IO.Directory]::CreateDirectory((Join-Path $backup 'fonts'))
    $records = @()
    foreach ($name in $targets) {
        $path = Get-Target $name
        if ([IO.Directory]::Exists($path)) { throw "目标文件名被目录占用：$name" }
        $exists = [IO.File]::Exists($path)
        $hash = Get-Hash $path
        if ($exists) {
            [IO.File]::Copy($path, (Join-Path $backup $name), $false)
            if ((Get-Hash (Join-Path $backup $name)) -ne $hash) { throw '备份校验失败，原游戏未修改。' }
        }
        $records += [pscustomobject]@{path=$name; existed=$exists; originalSha256=$hash}
    }
    $state = [pscustomobject]@{version=$manifest.version; backup=$backupName; files=$records}
    Write-Json (Join-Path $backup 'backup.json') $state
    Write-Json $statePath $state
    try {
        [void][IO.Directory]::CreateDirectory((Join-Path $script:GameRoot 'fonts'))
        for ($i=1; $i -lt 5; $i++) {
            $font = if ($i -eq 1) { $manifest.fonts[0] } else { $manifest.fonts[1] }
            Write-Atomic (Get-Target $targets[$i]) ([IO.File]::ReadAllBytes((Join-Path $PSScriptRoot ('payload/'+$font.file))))
        }
        Write-Atomic $scriptPath $patched
        for ($i=0; $i -lt $targets.Count; $i++) {
            if ((Get-Hash (Get-Target $targets[$i])) -ne $installedHashes[$i]) { throw "安装后校验失败：$($targets[$i])" }
        }
    } catch {
        $failure = $_.Exception.Message
        try {
            Restore-Originals $state $backup
            [IO.File]::Delete($statePath)
        } catch { throw "安装失败：$failure。自动回退未完成；请保留 $backup 并运行 Restore.bat。" }
        throw "安装失败，已恢复安装前文件：$failure"
    }
    Write-Host '安装完成！从 Steam 正常启动游戏，选择 English 即可阅读中文正文。' -ForegroundColor Green
    Write-Host 'EP1–4 正文、茶会与隐藏茶会已适配；菜单、人物资料和图片文字仍有原文。'
    Write-Host "原文件备份：$backup"
} catch {
    Write-Host ('操作未完成：' + $_.Exception.Message) -ForegroundColor Red
    exit 1
}
