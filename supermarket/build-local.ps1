[CmdletBinding()]
param([string]$JdkHome = $env:JAVA_HOME)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$web = Join-Path $root 'WebContent'
$lib = Join-Path $web 'WEB-INF\lib'
$source = Join-Path $root 'src'

if (!$JdkHome -or !(Test-Path -LiteralPath (Join-Path $JdkHome 'bin\jar.exe'))) {
    $java = (Get-Command java.exe).Source
    $settings = & {
        # Java prints version settings to stderr even when it succeeds.
        $ErrorActionPreference = 'Continue'
        & $java -XshowSettings:properties -version 2>&1 | Out-String
    }
    $match = [regex]::Match($settings, '(?m)^\s*java\.home = ([^\r\n]+)')
    if (!$match.Success) { throw 'Set JAVA_HOME to your JDK 21 installation.' }
    $JdkHome = $match.Groups[1].Value.Trim()
}
$javac = Join-Path $JdkHome 'bin\javac.exe'
$jar = Join-Path $JdkHome 'bin\jar.exe'
if (!(Test-Path -LiteralPath $javac) -or !(Test-Path -LiteralPath $jar)) { throw 'A full JDK 21 is required.' }
if (!(Test-Path -LiteralPath (Join-Path $lib 'postgresql-42.7.14.jar'))) {
    throw 'The PostgreSQL JDBC JAR must be in WebContent\WEB-INF\lib.'
}

$files = @(Get-ChildItem -LiteralPath $source -Recurse -File -Filter '*.java' |
    Sort-Object FullName | ForEach-Object FullName)
if ($files.Count -eq 0) { throw 'No Java source files were found.' }

$build = Join-Path $root 'build'
New-Item -ItemType Directory -Path $build -Force | Out-Null
if ((Get-Item -LiteralPath $build).Attributes -band [IO.FileAttributes]::ReparsePoint) {
    throw 'The build directory must be inside the project.'
}
$staging = Join-Path $build ('war-' + [Guid]::NewGuid().ToString('N'))
$classes = Join-Path $staging 'WEB-INF\classes'
$artifact = Join-Path $staging 'supermarket.war'
New-Item -ItemType Directory -Path $classes -Force | Out-Null
try {
    & $javac --release 21 -encoding UTF-8 -classpath (Join-Path $lib '*') -d $classes @files
    if ($LASTEXITCODE -ne 0) { throw 'Java compilation failed.' }
    & $jar --create --file $artifact -C $web . -C $staging 'WEB-INF/classes'
    if ($LASTEXITCODE -ne 0) { throw 'WAR packaging failed.' }
    $output = Join-Path $build 'supermarket.war'
    Move-Item -LiteralPath $artifact -Destination $output -Force
    Write-Host "Built $output"
} finally {
    $resolved = (Resolve-Path -LiteralPath $staging).Path
    if ((Split-Path $resolved -Parent) -ne (Resolve-Path -LiteralPath $build).Path -or
        ((Get-Item -LiteralPath $resolved).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
        throw 'Unexpected staging directory.'
    }
    Remove-Item -LiteralPath $resolved -Recurse -Force
}
