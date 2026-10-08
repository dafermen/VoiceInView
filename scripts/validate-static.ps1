param([string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot))
$ErrorActionPreference = 'Stop'
$projectRoot = [System.IO.Path]::GetFullPath($ProjectRoot)
$projectSource = Get-Content -Raw -LiteralPath (Join-Path $projectRoot 'vReader.xcodeproj\project.pbxproj')
$parserCode = @'
using System;
using System.Collections.Generic;
using System.Text.RegularExpressions;
public sealed class VReaderProjectParser {
 private string[] tokens;
 private int position;
 public VReaderProjectParser(string source) {
  var matches = Regex.Matches(source, @"//[^\r\n]*|/\*[\s\S]*?\*/|""(?:\\.|[^""\\])*""|[{}()=;,]|[^\s{}()=;,]+");
  var items = new List<string>();
  foreach (Match match in matches) {
   if (!match.Value.StartsWith("//") && !match.Value.StartsWith("/*")) items.Add(match.Value);
  }
  tokens = items.ToArray();
 }
 private string Take() {
  if (position >= tokens.Length) throw new Exception("Unexpected end of project");
  return tokens[position++];
 }
 private void Expect(string value) {
  string actual = Take();
  if (actual != value) throw new Exception("Expected " + value + ", got " + actual);
 }
 private object Value() {
  string item = Take();
  if (item == "{") {
   var map = new Dictionary<string,object>();
   while (position < tokens.Length && tokens[position] != "}") {
    string key = Take();
    Expect("=");
    map.Add(key, Value());
    Expect(";");
   }
   Expect("}");
   return map;
  }
  if (item == "(") {
   var list = new List<object>();
   while (position < tokens.Length && tokens[position] != ")") {
    list.Add(Value());
    if (tokens[position] != ")") Expect(",");
   }
   Expect(")");
   return list;
  }
  if (item == "}" || item == ")" || item == "=" || item == ";" || item == ",") throw new Exception("Unexpected token " + item);
  return item;
 }
 public Dictionary<string,object> Parse() {
  var result = Value() as Dictionary<string,object>;
  if (result == null || position != tokens.Length) throw new Exception("Invalid top-level project");
  return result;
 }
}
'@
Add-Type -TypeDefinition $parserCode
$parsedProject = ([VReaderProjectParser]::new($projectSource)).Parse()
$projectObjects = $parsedProject['objects']
if ($projectObjects.Count -ne 37) { throw 'Unexpected object count' }
foreach ($reference in [regex]::Matches($projectSource, '[AB][0-9A-F]{23}')) {
 if (-not $projectObjects.ContainsKey($reference.Value)) { throw "Unresolved object: $reference" }
}
$projectObject = $projectObjects[$parsedProject['rootObject']]
if ($projectObject['targets'].Count -ne 3) { throw 'Expected app, UI and unit-test targets' }
foreach ($targetId in $projectObject['targets']) {
 $target = $projectObjects[$targetId]
 $configurations = $projectObjects[$target['buildConfigurationList']]['buildConfigurations']
 foreach ($configurationId in $configurations) {
  $settings = $projectObjects[$configurationId]['buildSettings']
  if ($target['name'] -eq 'vReader' -and -not $settings.ContainsKey('INFOPLIST_KEY_NSMicrophoneUsageDescription')) { throw 'Missing microphone purpose' }
 }
 foreach ($groupId in $target['fileSystemSynchronizedGroups']) {
  if (-not (Test-Path -LiteralPath (Join-Path $projectRoot $projectObjects[$groupId]['path']))) { throw 'Missing source group' }
 }
}
[xml]$scheme = Get-Content -Raw -LiteralPath (Join-Path $projectRoot 'vReader.xcodeproj\xcshareddata\xcschemes\vReader.xcscheme')
if ($scheme.SelectNodes('//TestableReference').Count -ne 2) { throw 'Missing unit or UI test in scheme' }
foreach ($reference in $scheme.SelectNodes('//BuildableReference')) {
 if (-not $projectObjects.ContainsKey($reference.BlueprintIdentifier)) { throw 'Scheme references unknown target' }
}
$unitSource = Get-Content -Raw -LiteralPath (Join-Path $projectRoot 'vReaderUnitTests\ListeningViewModelTests.swift')
$unitCount = [regex]::Matches($unitSource, 'func test\w+\(').Count
if ($unitCount -ne 12) { throw 'Missing original microphone regressions' }
$allUnitCount = 0
foreach ($unitFile in Get-ChildItem -LiteralPath (Join-Path $projectRoot 'vReaderUnitTests') -Filter '*.swift') {
 $allUnitCount += [regex]::Matches((Get-Content -Raw -LiteralPath $unitFile.FullName), 'func test\w+\(').Count
}
$uiSource = Get-Content -Raw -LiteralPath (Join-Path $projectRoot 'vReaderTests\HomeScreenTests.swift')
if ([regex]::Matches($uiSource, 'func test\w+\(').Count -ne 3) { throw 'Expected three UI tests' }
$authoredFiles = Get-ChildItem -LiteralPath $projectRoot -Recurse -File | Where-Object { $_.FullName -notlike '*\.git\*' -and $_.Name -ne 'project-brief.txt' -and $_.Extension -ne '.png' }
foreach ($file in $authoredFiles) {
 $source = Get-Content -Raw -LiteralPath $file.FullName
 if ($source -match '(?m)[ \t]+$') { throw "Trailing whitespace: $($file.Name)" }
 if ($file.Extension -eq '.md') {
  foreach ($link in [regex]::Matches($source, '\]\(([^)]+)\)')) {
   $linkTarget = $link.Groups[1].Value
   if ($linkTarget -match '^https?://' -or $linkTarget.StartsWith('#')) { continue }
   if (-not (Test-Path -LiteralPath (Join-Path $file.DirectoryName $linkTarget))) { throw "Broken link: $linkTarget" }
  }
 }
}

[xml]$privacy = Get-Content -Raw -LiteralPath (Join-Path $projectRoot 'vReader\PrivacyInfo.xcprivacy')
$privacySource = Get-Content -Raw -LiteralPath (Join-Path $projectRoot 'vReader\PrivacyInfo.xcprivacy')
foreach ($reason in @('CA92.1','E174.1')) { if (-not $privacySource.Contains($reason)) { throw 'Missing privacy reason' } }
$metadata = Get-Content -Raw -LiteralPath (Join-Path $projectRoot 'docs\app-store-metadata.json') | ConvertFrom-Json
if ($metadata.name.Length -gt 30 -or $metadata.subtitle.Length -gt 30 -or [System.Text.Encoding]::UTF8.GetByteCount($metadata.keywords) -gt 100 -or $metadata.description.Length -gt 4000) { throw 'App Store draft exceeds field limits' }
foreach ($jsonFile in Get-ChildItem -LiteralPath (Join-Path $projectRoot 'vReader\Assets.xcassets') -Recurse -Filter '*.json') { Get-Content -Raw -LiteralPath $jsonFile.FullName | ConvertFrom-Json | Out-Null }
$iconBytes = [System.IO.File]::ReadAllBytes((Join-Path $projectRoot 'vReader\Assets.xcassets\AppIcon.appiconset\AppIcon.png'))
if ($iconBytes[25] -ne 2) { throw 'Expected opaque RGB PNG' }
Add-Type -AssemblyName System.Drawing
$icon = [System.Drawing.Image]::FromFile((Join-Path $projectRoot 'vReader\Assets.xcassets\AppIcon.appiconset\AppIcon.png'))
if ($icon.Width -ne 1024 -or $icon.Height -ne 1024) { $icon.Dispose(); throw 'Incorrect icon dimensions' }
$icon.Dispose()
foreach ($swiftFile in Get-ChildItem -LiteralPath (Join-Path $projectRoot 'vReader') -Recurse -Filter '*.swift') {
 $swiftText = Get-Content -Raw -LiteralPath $swiftFile.FullName
 if ($swiftText -match '\b(URLSession|SFSpeechRecognizer|AVAudioRecorder|AVAudioFile|Firebase)\b' -or $swiftText -match 'sk-[A-Za-z0-9]{20,}') { throw "Unexpected network/recording/secret surface: $($swiftFile.Name)" }
 $masked = [regex]::Replace($swiftText, '(?s)""".*?"""|"(?:\\.|[^"\\])*"|/\*.*?\*/|//[^\r\n]*', '')
 $stack = [System.Collections.Generic.Stack[char]]::new()
 foreach ($character in $masked.ToCharArray()) {
  if ('({['.Contains([string]$character)) { $stack.Push($character) }
  elseif (')}]'.Contains([string]$character)) {
   if ($stack.Count -eq 0) { throw "Unbalanced delimiters: $($swiftFile.Name)" }
   $opening = $stack.Pop()
   if (('({['.IndexOf($opening)) -ne (')}]'.IndexOf($character))) { throw "Mismatched delimiters: $($swiftFile.Name)" }
  }
 }
 if ($stack.Count -ne 0) { throw "Unclosed delimiters: $($swiftFile.Name)" }
}
$gitCommand = Get-Command git -ErrorAction SilentlyContinue
if ($gitCommand) {
 $bashExecutable = Join-Path (Split-Path -Parent (Split-Path -Parent $gitCommand.Source)) 'bin\bash.exe'
 if (Test-Path -LiteralPath $bashExecutable) {
  foreach ($shellFile in Get-ChildItem -LiteralPath (Join-Path $projectRoot 'scripts') -Filter '*.sh') {
   & $bashExecutable -n $shellFile.FullName.Replace('\','/')
   if ($LASTEXITCODE -ne 0) { throw "Shell syntax invalid: $($shellFile.Name)" }
  }
  Write-Output 'PASS: Mac shell-script syntax checked with bash -n.'
 }
}
Write-Output "PASS: Manifest XML/reasons, metadata field limits, asset JSON, opaque 1024 px icon and Swift delimiter/source surface checks; $allUnitCount unit tests and 3 UI tests are present (not executed)."

Write-Output 'PASS: OpenStep project syntax parsed; 37 project objects resolved; 3 targets; 2 scheme test targets; microphone purpose in both app configurations; source groups exist; local documentation links valid; authored files have no trailing whitespace.'
if (Get-Command xcodebuild -ErrorAction SilentlyContinue) {
 throw 'Xcode is unexpectedly available; execute build before closing validation'
} else {
 Write-Output 'BLOCKED: xcodebuild is unavailable on Windows. Build, XCTest and iPhone runtime validation not executed.'
}
