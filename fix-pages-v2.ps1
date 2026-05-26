$ErrorActionPreference = 'Continue'
$Host.UI.RawUI.WindowTitle = "ABC Franchise - Fix Pages v2 (gh-pages branch)"
$gh   = "C:\Program Files\GitHub CLI\gh.exe"
$root = "D:\Git\franchise-website"
$repo = "abc-franchise"

function Section($t) { Write-Host ""; Write-Host "=== $t ===" -ForegroundColor Cyan }
function OK($t)      { Write-Host "  $t" -ForegroundColor Green }
function Warn($t)    { Write-Host "  $t" -ForegroundColor Yellow }
function Fail($t)    { Write-Host "  $t" -ForegroundColor Red; Read-Host "Press Enter to close"; exit 1 }

Section "Step 1 of 4 - Paste your PAT"
$token = Read-Host "PAT"
if ([string]::IsNullOrWhiteSpace($token)) { Fail "No token entered." }
$env:GH_TOKEN = $token.Trim()
$user = & $gh api user --jq '.login' 2>$null
if (-not $user) { Fail "Token invalid." }
OK "Authenticated as $user"

Set-Location $root

Section "Step 2 of 4 - Push prototype subtree as 'gh-pages' branch"
Write-Host "  This takes the prototype/ subfolder and pushes it as the ROOT of a new gh-pages branch."
Write-Host "  Doing this via temporary worktree (bypasses any file locks)..."
Write-Host ""

# Use git worktree to avoid touching main checkout
$worktree = "$env:TEMP\abc-franchise-ghpages-$(Get-Random -Maximum 9999)"
Remove-Item $worktree -Recurse -Force -ErrorAction SilentlyContinue

# Create orphan gh-pages branch via worktree
& git worktree add --orphan -b gh-pages $worktree 2>&1 | Out-String | Write-Host

# Copy prototype contents into the worktree (the orphan branch starts empty)
Write-Host "  Copying prototype/* into worktree ..."
Get-ChildItem -Path "$root\prototype" -Force | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination $worktree -Recurse -Force
}

# Commit and push from worktree
Push-Location $worktree
& git add -A
& git commit -m "Deploy: ABC Franchise prototype to gh-pages"
& git push -u origin gh-pages --force
Pop-Location

# Clean up worktree
& git worktree remove $worktree --force 2>$null | Out-Null
& git branch -D gh-pages 2>$null | Out-Null
OK "gh-pages branch pushed"

Section "Step 3 of 4 - Enable GitHub Pages (source: gh-pages branch, /)"
& $gh api -X DELETE "/repos/$user/$repo/pages" 2>$null | Out-Null
Start-Sleep -Seconds 2
$body = '{"source":{"branch":"gh-pages","path":"/"}}'
$response = ($body | & $gh api -X POST "/repos/$user/$repo/pages" --input - 2>&1 | Out-String)
Write-Host $response
if ($response -match '"status":"422"|"status":"404"') {
    Fail "Pages enable failed — open https://github.com/$user/$repo/settings/pages manually"
}
OK "Pages enabled"

Section "Step 4 of 4 - Done"
$url = "https://$user.github.io/$repo/"
Write-Host ""
Write-Host "  Repo:    https://github.com/$user/$repo" -ForegroundColor Green
Write-Host "  Branch:  gh-pages (auto-deployed by GitHub Pages)" -ForegroundColor Green
Write-Host "  URL:     $url" -ForegroundColor Green
Write-Host ""
Write-Host "  First build: 30-90 seconds. If you see 404 at first, wait 1 min and refresh." -ForegroundColor Yellow
Write-Host ""
Start-Process $url
Read-Host "Press Enter to close"
