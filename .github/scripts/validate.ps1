param([switch]$Quiet)

$ROOT = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSCommandPath))
$EXIT_CODE = 0
$TOTAL_FILES = 0
$TOTAL_MERMAID = 0

$GREEN = "Green"; $RED = "Red"; $YELLOW = "Yellow"; $CYAN = "Cyan"
function Pass  { if (-not $Quiet) { Write-Host "[PASS]" -ForegroundColor $GREEN -NoNewline; Write-Host " $args" } }
function Warn  { if (-not $Quiet) { Write-Host "[WARN]" -ForegroundColor $YELLOW -NoNewline; Write-Host " $args" } }
function Fail  { Write-Host "[FAIL]" -ForegroundColor $RED -NoNewline; Write-Host " $args"; $script:EXIT_CODE = 1 }
function Info  { if (-not $Quiet) { Write-Host "[INFO]" -ForegroundColor $CYAN -NoNewline; Write-Host " $args" } }
function Hdr   { if (-not $Quiet) { $line = "=" * $args[0].Length; Write-Host "`n$args[0]`n$line" -ForegroundColor White } }

$OldRefs = @(
    '01-Fundamentals', '03-Databases', '04-Caching', '05-Message-Queues',
    '07-Cloud-Architecture', '10-Open-Source', '11-Production-Incidents',
    '12-Hands-On', '13-System-Design-Interviews', '14-Staff-Engineer-Level'
)

$NameRegex = '^\d{2}-[A-Za-z0-9].+\.md$'

Hdr "1. File Naming Convention"
Get-ChildItem "$ROOT" -Recurse -Filter "*.md" -File | Where-Object {
    $_.FullName -notmatch '\\.git\\' -and $_.Directory.Name -match '^\d{2}'
} | ForEach-Object {
    if ($_.Name -ne "README.md") { $script:TOTAL_FILES++
        if ($_.Name -notmatch $NameRegex) { $rel = $_.FullName.Substring($ROOT.Length + 1)
            Fail "Bad filename: $rel (expected NN-description.md)" } }
}
Pass "All content files follow NN-description.md naming"

Hdr "2. Module Numbering Completeness"
$expected = 1..21 | ForEach-Object { "{0:D2}" -f $_ }
$actual = Get-ChildItem "$ROOT" -Directory | Where-Object { $_.Name -match '^\d{2}-' } | ForEach-Object { $_.Name.Substring(0,2) } | Sort-Object
foreach ($num in $expected) {
    if ($num -notin $actual) {
        Fail "Missing module directory: $num-*"
    }
}
Pass "All 21 modules (01-21) present"

Hdr "3. Module README Navigation"
$modules = Get-ChildItem "$ROOT" -Directory | Where-Object { $_.Name -match '^\d{2}-' } | Sort-Object Name
foreach ($m in $modules) {
    $readme = "$($m.FullName)\README.md"
    $name = $m.Name
    $num = $name.Substring(0,2)
    if (-not (Test-Path $readme)) {
        Fail "Missing README.md in $name"; continue
    }
    $content = Get-Content $readme -Raw
    if ($num -ne "01" -and $content -notmatch 'Previous:') {
        Fail "$name/README.md missing Previous: link"
    }
    if ($num -ne "21" -and $content -notmatch 'Next:') {
        Fail "$name/README.md missing Next: link"
    }
}
Pass "All module READMEs have correct navigation"

Hdr "4. Cross-Module Reference Integrity"
$violations = 0
Get-ChildItem "$ROOT" -Recurse -Filter "*.md" -File | Where-Object { $_.FullName -notmatch '\\.git\\' } | ForEach-Object {
    $rel = $_.FullName.Substring($ROOT.Length + 1)
    $content = Get-Content $_.FullName -Raw
    foreach ($old in $OldRefs) {
        if ($content -match $old) {
            Fail "$rel contains old reference: $old"
            $script:violations++
        }
    }
}
if ($violations -eq 0) { Pass "Zero old/broken cross-module references" }

$badLinks = 0
Get-ChildItem "$ROOT" -Recurse -Filter "README.md" -File | Where-Object { $_.FullName -notmatch '\\.git\\' -and $_.Directory.Name -match '^\d{2}' } | ForEach-Object {
    $readmeDir = $_.Directory.FullName
    $moduleName = $_.Directory.Name
    $content = Get-Content $_.FullName -Raw
    $links = [regex]::Matches($content, '\]\(([^)]+\.md)\)') | ForEach-Object { $_.Groups[1].Value }
    foreach ($link in $links) {
        if ($link -match '^https?://') { continue }
        $target = if ([System.IO.Path]::IsPathRooted($link)) { $link } else { Join-Path $readmeDir $link }
        $target = [System.IO.Path]::GetFullPath($target)
        if (-not (Test-Path $target)) {
            $linkDisplay = $link -replace '^\./', ''
            Fail "$moduleName/README.md links to non-existent: $linkDisplay"
            $script:badLinks++
        }
    }
}
if ($badLinks -eq 0) { Pass "All module READMEs have valid local links" }

Hdr "5. Mermaid Diagram Coverage"
$miss = 0; $mermaidCount = 0
Get-ChildItem "$ROOT" -Recurse -Filter "*.md" -File | Where-Object {
    $_.FullName -notmatch '\\.git\\' -and $_.Name -ne "README.md"
} | ForEach-Object {
    $rel = $_.FullName.Substring($ROOT.Length + 1)
    $content = Get-Content $_.FullName -Raw
    $diagrams = [regex]::Matches($content, '```mermaid\n([\s\S]*?)```') | Where-Object {
        ($_.Groups[1].Value -split "`n" | Where-Object { $_ -ne '' }).Count -ge 3
    }
    if ($diagrams.Count -eq 0) {
        $miss++
        Warn "No Mermaid diagram: $rel"
    } else {
        $script:TOTAL_MERMAID += $diagrams.Count
    }
}
if ($miss -gt 0) { Warn "$miss file(s) missing Mermaid diagrams" } else { Pass "All content files have Mermaid diagrams" }
Info "Total Mermaid diagrams: $TOTAL_MERMAID"

Hdr "6. File Count Summary"
$moduleCount = 0; $allCount = 0
foreach ($m in $modules) {
    $count = @(Get-ChildItem "$($m.FullName)" -Filter "*.md" -File | Where-Object { $_.Name -ne "README.md" }).Count
    $moduleCount++; $allCount += $count
    Info "  $($m.Name): $count content files"
}
$totalMd = @(Get-ChildItem "$ROOT" -Recurse -Filter "*.md" -File | Where-Object { $_.FullName -notmatch '\\.git\\' }).Count
Info "Total modules: $moduleCount"
Info "Total content files (non-README): $allCount"
Info "Total .md files (all): $totalMd"

Hdr "RESULT"
if ($EXIT_CODE -eq 0) {
    Write-Host "All validations passed!" -ForegroundColor $GREEN
} else {
    Write-Host "Some validations failed." -ForegroundColor $RED
}
exit $EXIT_CODE
