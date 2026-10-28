[CmdletBinding()]
param(
    [string]$GameRoot = $env:BEAT_SABER_DIR,
    [string]$BuildDirectory,
    [string]$OutputDirectory
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'build_local_paths.ps1')

if ((Get-Content -LiteralPath (Join-Path $GameRoot 'BeatSaberVersion.txt') -Raw).Trim() -ne '1.45.2_28848') {
    throw 'Unsupported Beat Saber build.'
}
if (!$BuildDirectory) { $BuildDirectory = Join-Path $RepoRoot '.tmp/build' }
if (!$OutputDirectory) { $OutputDirectory = Join-Path $RepoRoot '.tmp/package' }
$BuildDirectory = Resolve-RepoBuildPath $BuildDirectory
$OutputDirectory = Resolve-RepoBuildPath $OutputDirectory

$sharedRoot = Join-Path $RepoRoot 'vendor/LocalModUI'
$sharedBuild = Join-Path $sharedRoot 'scripts/build.ps1'
if (!(Test-Path -LiteralPath $sharedBuild -PathType Leaf)) {
    throw 'LocalModUI submodule is missing. Run git submodule update --init --recursive.'
}
& $sharedBuild -GameRoot $GameRoot -BuildDirectory (Join-Path $sharedRoot '.tmp/build') -OutputDirectory (Join-Path $sharedRoot '.tmp/package') | Out-Null

$sources = Join-Path $PSScriptRoot 'mod_ui_chinese'
& python (Join-Path $sources 'generate_catalog.py') --localization-dir (Join-Path $RepoRoot 'localization') --output-dir $BuildDirectory
if ($LASTEXITCODE -ne 0) { throw 'Translation catalog validation failed.' }

$compiler = Get-ChildItem -LiteralPath 'C:/Program Files/dotnet/sdk' -Directory | Sort-Object { [version]$_.Name } -Descending | Select-Object -First 1 | ForEach-Object { Join-Path $_.FullName 'Roslyn/bincore/csc.dll' }
if (!$compiler -or !(Test-Path -LiteralPath $compiler -PathType Leaf)) {
    throw 'A local .NET SDK with the Roslyn compiler is required.'
}
$plugins = Join-Path $OutputDirectory 'Plugins'
[IO.Directory]::CreateDirectory($plugins) | Out-Null
$output = Join-Path $plugins 'ModUiChinese.dll'
$managed = Join-Path $GameRoot 'Beat Saber_Data/Managed'
$refs = @('mscorlib.dll','System.dll','System.Core.dll','System.Xml.dll','System.Xml.Linq.dll','IPA.Loader.dll','UnityEngine.CoreModule.dll','Unity.TextMeshPro.dll','UnityEngine.UI.dll','UnityEngine.UIModule.dll','UnityEngine.TextRenderingModule.dll','UnityEngine.TextCoreFontEngineModule.dll','HMUI.dll','BeatSaber.ViewSystem.dll','BGLib.UnityExtension.dll','Zenject.dll','Zenject-usage.dll','netstandard.dll') | ForEach-Object { Join-Path $managed $_ }
$refs += Join-Path $sharedRoot '.tmp/local-mod-ui/build/LocalModUI.dll'
$refs += @('Plugins/BSML.dll','Plugins/SiraUtil.dll','Libs/0Harmony.dll','Libs/Newtonsoft.Json.dll','Beat Saber_Data/Managed/DataModels.dll','Beat Saber_Data/Managed/BeatmapCore.dll','Beat Saber_Data/Managed/Main.dll','Beat Saber_Data/Managed/BGLib.AppFlow.dll','Beat Saber_Data/Managed/BGLib.Polyglot.dll') | ForEach-Object { Join-Path $GameRoot $_ }
$arguments = @('/nologo','/noconfig','/nostdlib+','/target:library','/langversion:latest','/optimize+','/codepage:65001',('/out:'+$output),('/resource:'+(Join-Path $sources 'ModUiChinese.manifest.json')+',ModUiChinese.manifest.json'))
$arguments += @($refs | ForEach-Object { '/r:'+$_ })
$arguments += @((Join-Path $sources 'TranslationEngine.cs'),(Join-Path $sources 'Settings.cs'),(Join-Path $sources 'ModUiChinese.cs'),(Join-Path $sources 'SymbolFontFallback.cs'),(Join-Path $sources 'GameplayFeedback.cs'),(Join-Path $sharedRoot 'scripts/shared_profiles/ProfileStore.cs'),(Join-Path $BuildDirectory 'GeneratedCatalog.cs'))
$arguments += '/resource:'+(Join-Path $sources 'Settings.bsml')+',ModUiChinese.Settings.bsml'
& 'C:/Program Files/dotnet/dotnet.exe' $compiler @arguments
if ($LASTEXITCODE -ne 0) { throw 'Chinese UI plugin compilation failed.' }
Write-Output $OutputDirectory
