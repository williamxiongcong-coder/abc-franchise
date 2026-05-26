$Host.UI.RawUI.WindowTitle = "Enable Pages"
Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " Enable GitHub Pages on main + /docs" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host " Paste your PAT (right-click to paste), then Enter" -ForegroundColor Yellow
Write-Host ""

$token = Read-Host "PAT"
if ([string]::IsNullOrWhiteSpace($token)) {
    Write-Host "  No token entered. Closing." -ForegroundColor Red
    Read-Host "Press Enter to close"; exit 1
}
$token = $token.Trim()
$user = "williamxiongcong-coder"
$repo = "abc-franchise"
$headers = @{
    Authorization = "Bearer $token"
    Accept        = "application/vnd.github+json"
    "X-GitHub-Api-Version" = "2022-11-28"
}

Write-Host ""
Write-Host "[1] Checking current Pages config..." -ForegroundColor Cyan
$exists = $false
try {
    $cur = Invoke-RestMethod -Uri "https://api.github.com/repos/$user/$repo/pages" -Headers $headers -ErrorAction Stop
    $exists = $true
    Write-Host "    Exists - branch=$($cur.source.branch) path=$($cur.source.path) build_type=$($cur.build_type)" -ForegroundColor Yellow
} catch { Write-Host "    Not yet configured" -ForegroundColor Gray }

Write-Host ""
$body = '{"build_type":"legacy","source":{"branch":"main","path":"/docs"}}'
if ($exists) {
    Write-Host "[2] Updating Pages source via PUT (main + /docs)..." -ForegroundColor Cyan
    try {
        Invoke-RestMethod -Uri "https://api.github.com/repos/$user/$repo/pages" -Method PUT -Headers $headers -Body $body -ContentType "application/json" | Out-Null
        Write-Host "    SUCCESS - source updated" -ForegroundColor Green
    } catch {
        Write-Host "    PUT failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "    Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
        Read-Host "Press Enter to close"; exit 1
    }
} else {
    Write-Host "[2] Creating Pages config via POST (main + /docs)..." -ForegroundColor Cyan
    try {
        $r = Invoke-RestMethod -Uri "https://api.github.com/repos/$user/$repo/pages" -Method POST -Headers $headers -Body $body -ContentType "application/json"
        Write-Host "    SUCCESS - URL: $($r.html_url)" -ForegroundColor Green
    } catch {
        Write-Host "    POST failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "    Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
        Read-Host "Press Enter to close"; exit 1
    }
}

Start-Sleep -Seconds 2
Write-Host ""
Write-Host "[2b] Triggering a fresh build..." -ForegroundColor Cyan
try {
    Invoke-RestMethod -Uri "https://api.github.com/repos/$user/$repo/pages/builds" -Method POST -Headers $headers | Out-Null
    Write-Host "    Build queued" -ForegroundColor Green
} catch { Write-Host "    Build trigger note: $($_.ErrorDetails.Message)" -ForegroundColor Yellow }

Write-Host ""
Write-Host "[3] Waiting 45 seconds for first build..." -ForegroundColor Cyan
for ($i = 45; $i -gt 0; $i -= 5) {
    Write-Host "    $i seconds remaining..." -NoNewline
    Start-Sleep -Seconds 5
    Write-Host "`r" -NoNewline
}

Write-Host ""
Write-Host "[4] Checking live status..." -ForegroundColor Cyan
$liveUrl = "https://$user.github.io/$repo/"
try {
    $resp = Invoke-WebRequest -Uri $liveUrl -Method Head -UseBasicParsing -TimeoutSec 10
    Write-Host "    LIVE at $liveUrl (HTTP $($resp.StatusCode))" -ForegroundColor Green
    Start-Process $liveUrl
} catch {
    $code = $_.Exception.Response.StatusCode.value__
    Write-Host "    Status: $code -- still building, refresh manually in 30s" -ForegroundColor Yellow
    Write-Host "    URL: $liveUrl" -ForegroundColor Yellow
    Start-Process $liveUrl
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host " Done. Tell Claude DEPLOYED." -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Read-Host "Press Enter to close"
