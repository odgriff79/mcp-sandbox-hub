param(
  [string]$Repo = "odgriff79/mcp-sandbox-hub",
  [switch]$Open
)
$Name = gh codespace list --repo $Repo --json name,createdAt --jq "sort_by(.createdAt) | last | .name"
if (-not $Name) { throw "No codespace found for $Repo" }

# Wake & wait
gh codespace ssh -c $Name -- "echo awake" | Out-Null
do {
  $state = gh codespace view -c $Name --json state --jq .state
  Write-Host "State: $state"
  Start-Sleep 2
} while ($state -ne "Available")

# Start (idempotent)
gh codespace ssh -c $Name -- 'pgrep -f health_server.py >/dev/null || (cd /workspaces/mcp-sandbox-hub && nohup python tools/health_server.py >/tmp/health.log 2>&1 & echo $! > /tmp/health.pid)'

# Try to make port public & fetch URL (works on most gh versions)
try { gh codespace ports visibility -c $Name 8765:public | Out-Null } catch { }
$HealthUrl = $null
try { $HealthUrl = gh api "/user/codespaces/$Name/ports" --jq '.ports[] | select(.port==8765) | .web_url' } catch { }

if ($HealthUrl) {
  Write-Host "Health URL: $HealthUrl/health"
  Start-Process ($HealthUrl.TrimEnd('/') + '/health')
} else {
  Write-Warning "Forwarded URL not available via CLI. Open the Codespace and click the Port 8765 globe."
  if ($Open) { gh codespace code -c $Name -w }
}
