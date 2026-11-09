[CmdletBinding()]
param(
    [switch]$Build,
    [switch]$Stop,
    [string]$PostgresBin = 'C:\Program Files\PostgreSQL\18\bin',
    [string]$TomcatHome = '',
    [int]$DatabasePort = 55432,
    [int]$HttpPort = 8088
)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$runtime = Join-Path $root 'runtime'
$data = Join-Path $runtime 'postgres-data'
$base = Join-Path $runtime 'tomcat-local'
$passwordFile = Join-Path $runtime 'postgres.password'
$war = Join-Path $root 'build\supermarket.war'
$pgCtl = Join-Path $PostgresBin 'pg_ctl.exe'

if (-not $TomcatHome) {
    $tomcat = Get-ChildItem -LiteralPath $runtime -Directory -Filter 'apache-tomcat-10.1.*' -ErrorAction SilentlyContinue |
        Sort-Object Name -Descending | Select-Object -First 1
    if (-not $tomcat) { throw 'Extract the Apache Tomcat 10.1 Core ZIP into runtime, or pass -TomcatHome.' }
    $TomcatHome = $tomcat.FullName
}
$TomcatHome = (Resolve-Path -LiteralPath $TomcatHome).Path
$java = (Get-Command java.exe).Source
$bootstrap = Join-Path $TomcatHome 'bin\bootstrap.jar'
$juli = Join-Path $TomcatHome 'bin\tomcat-juli.jar'
$javaArgs = @("-Dcatalina.home=$TomcatHome", "-Dcatalina.base=$base", '-classpath',
    "$bootstrap;$juli", 'org.apache.catalina.startup.Bootstrap')

if ($Stop) {
    if (Test-Path -LiteralPath (Join-Path $base 'conf\server.xml')) {
        & $java @javaArgs stop
    }
    if (Test-Path -LiteralPath (Join-Path $data 'postmaster.pid')) {
        & $pgCtl -D $data -m fast -w stop
        if ($LASTEXITCODE -ne 0) { throw 'PostgreSQL did not stop.' }
    }
    return
}

if ($Build -or -not (Test-Path -LiteralPath $war)) {
    & (Join-Path $root 'build-local.ps1')
}

New-Item -Path $runtime -ItemType Directory -Force | Out-Null
if (-not (Test-Path -LiteralPath (Join-Path $data 'PG_VERSION'))) {
    if (-not (Test-Path -LiteralPath $passwordFile)) {
        $secret = [Guid]::NewGuid().ToString('N') + [Guid]::NewGuid().ToString('N')
        [IO.File]::WriteAllText($passwordFile, $secret, [Text.Encoding]::ASCII)
    }
    & (Join-Path $PostgresBin 'initdb.exe') -D $data -U supermarket_dev -A scram-sha-256 "--pwfile=$passwordFile" --encoding=UTF8 --locale=C
    if ($LASTEXITCODE -ne 0) { throw 'PostgreSQL initialization failed.' }
}

& $pgCtl -D $data status *> $null
if ($LASTEXITCODE -ne 0) {
    & $pgCtl -D $data -l (Join-Path $runtime 'postgres.log') -o "-p $DatabasePort -h 127.0.0.1" -w start
    if ($LASTEXITCODE -ne 0) { throw 'PostgreSQL did not start. See runtime\postgres.log.' }
}

$env:PGPASSWORD = [IO.File]::ReadAllText($passwordFile).Trim()
$env:PGCLIENTENCODING = 'UTF8'
$psql = Join-Path $PostgresBin 'psql.exe'
$connection = @('-X', '-w', '-h', '127.0.0.1', '-p', $DatabasePort, '-U', 'supermarket_dev', '-v', 'ON_ERROR_STOP=1')
$exists = & $psql @connection -d postgres -Atc "SELECT 1 FROM pg_database WHERE datname = 'supermarket_pttk'"
if ($LASTEXITCODE -ne 0) { throw 'Cannot connect to the project PostgreSQL cluster.' }
if ($exists -ne '1') {
    & $psql @connection -d postgres -c 'CREATE DATABASE supermarket_pttk'
    if ($LASTEXITCODE -ne 0) { throw 'Database creation failed.' }
}
$initialized = & $psql @connection -d supermarket_pttk -Atc "SELECT coalesce(to_regclass('public.items1'), to_regclass('public.items')) IS NOT NULL"
if ($LASTEXITCODE -ne 0) { throw 'Cannot check the schema version.' }
$sqlFiles = @('schema.sql')
if ($initialized -eq 'f') { $sqlFiles += 'seed.sql' }
foreach ($sqlFile in $sqlFiles) {
    & $psql @connection -d supermarket_pttk -f (Join-Path $root "database\$sqlFile")
    if ($LASTEXITCODE -ne 0) { throw "Could not apply $sqlFile." }
}

$managerNeedsPassword = & $psql @connection -d supermarket_pttk -Atc "SELECT password_hash IS NULL FROM employees1 WHERE employee_code = 'QL01' AND role = 'MANAGEMENT'"
if ($LASTEXITCODE -ne 0) { throw 'Cannot check the demo manager account.' }
if ($managerNeedsPassword -eq 't') {
    $managerPasswordFile = Join-Path $runtime 'manager.password'
    $rng = [Security.Cryptography.RandomNumberGenerator]::Create()
    try {
        if (-not (Test-Path -LiteralPath $managerPasswordFile)) {
            $secretBytes = New-Object byte[] 24
            $rng.GetBytes($secretBytes)
            $managerSecret = [BitConverter]::ToString($secretBytes).Replace('-', '').ToLowerInvariant()
            [IO.File]::WriteAllText($managerPasswordFile, $managerSecret, [Text.Encoding]::ASCII)
        }
        $salt = New-Object byte[] 16
        $rng.GetBytes($salt)
    } finally {
        $rng.Dispose()
    }
    $managerSecret = [IO.File]::ReadAllText($managerPasswordFile).Trim()
    if ($managerSecret.Length -lt 8 -or $managerSecret.Length -gt 128) { throw 'Invalid demo manager password file.' }
    $derive = [Security.Cryptography.Rfc2898DeriveBytes]::new($managerSecret, $salt, 600000, [Security.Cryptography.HashAlgorithmName]::SHA256)
    try {
        $env:SUPERMARKET_MANAGER_SETUP_HASH = 'pbkdf2-sha256$600000$' + [Convert]::ToBase64String($salt) + '$' + [Convert]::ToBase64String($derive.GetBytes(32))
        @'
\getenv manager_hash SUPERMARKET_MANAGER_SETUP_HASH
UPDATE employees1 SET password_hash = :'manager_hash'
WHERE employee_code = 'QL01' AND role = 'MANAGEMENT' AND password_hash IS NULL;
'@ | & $psql @connection -d supermarket_pttk -f -
        if ($LASTEXITCODE -ne 0) { throw 'Cannot provision the demo manager account.' }
    } finally {
        $derive.Dispose()
        Remove-Item Env:SUPERMARKET_MANAGER_SETUP_HASH -ErrorAction SilentlyContinue
    }
}

$env:SUPERMARKET_DB_URL = "jdbc:postgresql://127.0.0.1:$DatabasePort/supermarket_pttk"
$env:SUPERMARKET_DB_USER = 'supermarket_dev'
$env:SUPERMARKET_DB_PASSWORD = $env:PGPASSWORD
Remove-Item Env:PGPASSWORD

$url = "http://127.0.0.1:$HttpPort/supermarket/"
$existing = $null
try { $existing = Invoke-WebRequest -Uri $url -TimeoutSec 2 -UseBasicParsing } catch { }
if ($existing -and $existing.StatusCode -eq 200) {
    if ($Build) { throw 'Stop the running application before deploying the new WAR.' }
    Write-Host $url
    return
}

New-Item -Path $base, (Join-Path $base 'webapps'), (Join-Path $base 'logs'), (Join-Path $base 'temp') -ItemType Directory -Force | Out-Null
$serverPath = Join-Path $base 'conf\server.xml'
if (-not (Test-Path -LiteralPath $serverPath)) {
    Copy-Item -LiteralPath (Join-Path $TomcatHome 'conf') -Destination $base -Recurse
}
$server = [xml](Get-Content -LiteralPath $serverPath -Raw)
$server.Server.SetAttribute('address', '127.0.0.1')
$server.Server.SetAttribute('port', [string]($HttpPort + 1000))
$connector = $server.SelectSingleNode('/Server/Service/Connector[@protocol="HTTP/1.1"]')
$connector.SetAttribute('address', '127.0.0.1')
$connector.SetAttribute('port', [string]$HttpPort)
$server.Save($serverPath)

Copy-Item -LiteralPath $war -Destination (Join-Path $base 'webapps\supermarket.war') -Force
$launchArgs = ($javaArgs + 'start') | ForEach-Object { '"' + $_ + '"' }
$tomcatProcess = Start-Process -FilePath $java -ArgumentList $launchArgs -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $runtime 'tomcat.out.log') -RedirectStandardError (Join-Path $runtime 'tomcat.err.log')

for ($attempt = 0; $attempt -lt 30; $attempt++) {
    try {
        if ((Invoke-WebRequest -Uri $url -TimeoutSec 2 -UseBasicParsing).StatusCode -eq 200) {
            Write-Host "Application ready at $url"
            return
        }
    } catch {
        if ($tomcatProcess.HasExited) { break }
        Start-Sleep -Milliseconds 500
    }
}
throw 'Tomcat did not become ready. See runtime\tomcat.err.log.'
