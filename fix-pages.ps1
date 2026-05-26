$ErrorActionPreference = 'Continue'
$Host.UI.RawUI.WindowTitle = "ABC Franchise - Fix Pages"
$gh   = "C:\Program Files\GitHub CLI\gh.exe"
$root = "D:\Git\franchise-website"
$repo = "abc-franchise"

function Section($t) { Write-Host ""; Write-Host "=== $t ===" -ForegroundColor Cyan }
function OK($t)      { Write-Host "  $t" -ForegroundColor Green }
function Fail($t)    { Write-Host "  $t" -ForegroundColor Red; Read-Host "Press Enter to close"; exit 1 }

Section "Step 1 of 5 - Paste your PAT (same as before)"
$token = Read-Host "PAT"
if ([string]::IsNullOrWhiteSpace($token)) { Fail "No token entered." }
$env:GH_TOKEN = $token.Trim()
$user = & $gh api user --jq '.login' 2>$null
if (-not $user) { Fail "Token invalid." }
OK "Authenticated as $user"

Set-Location $root

Section "Step 2 of 5 - Convert prototype -> docs (GitHub Pages requirement)"
if (Test-Path "$root\prototype") {
    # Copy then remove approach — works even if files are locked by browser/editor
    Write-Host "  Copying prototype/ -> docs/ ..."
    Copy-Item -Path "$root\prototype" -Destination "$root\docs" -Recurse -Force -ErrorAction SilentlyContinue
    if (-not (Test-Path "$root\docs\index.html")) { Fail "Copy failed. Close browser tabs / Explorer windows pointing at prototype, then re-run." }
    OK "Copied to docs/"

    Write-Host "  Staging the swap in git..."
    & git add docs
    & git rm -r --cached prototype 2>$null | Out-Null
    # Try to delete the original prototype folder (may need to retry if locked)
    Remove-Item -Path "$root\prototype" -Recurse -Force -ErrorAction SilentlyContinue
    if (Test-Path "$root\prototype") {
        Write-Host "  Note: prototype/ folder still on disk (likely browser lock). Will leave it for now." -ForegroundColor Yellow
        # Add to .gitignore so it doesn't get re-committed
        Add-Content -Path "$root\.gitignore" -Value "`nprototype/" -Encoding utf8
    } else {
        OK "Old prototype/ removed"
    }
} elseif (Test-Path "$root\docs") {
    OK "Already named docs, skipping"
} else {
    Fail "Neither prototype nor docs folder found"
}

Section "Step 3 of 5 - Commit the rename"
$staged = & git diff --cached --name-only
if ($staged) {
    & git commit -m "Rename prototype to docs for GitHub Pages"
    OK "Commit created"
} else {
    OK "Nothing to commit (already done)"
}

Section "Step 4 of 5 - Push to GitHub"
& git push origin main
OK "Pushed"

Section "Step 5 of 5 - Enable Pages with /docs source"
# Delete any existing Pages config first
& $gh api -X DELETE "/repos/$user/$repo/pages" 2>$null | Out-Null
Start-Sleep -Seconds 2
$body = '{"source":{"branch":"main","path":"/docs"}}'
$response = ($body | & $gh api -X POST "/repos/$user/$repo/pages" --input - 2>&1 | Out-String)
Write-Host $response
if ($response -match '"status":"404"|"status":"422"') {
    Fail "Pages enable failed. Try manually: github.com/$user/$repo/settings/pages"
}
OK "Pages enabled"

Section "DONE"
$url = "https://$user.github.io/$repo/"
Write-Host ""
Write-Host "  Repo:  https://github.com/$user/$repo" -ForegroundColor Green
Write-Host "  Pages: $url" -ForegroundColor Green
Write-Host ""
Write-Host "  First build takes 30-90 seconds. Refresh in ~1 min." -ForegroundColor Yellow
Write-Host ""
Start-Process $url
Read-Host "Press Enter to close"
