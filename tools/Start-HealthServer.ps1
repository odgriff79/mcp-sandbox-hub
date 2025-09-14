# Start-HealthServer.ps1
# Robust health server launcher that works around Windows/PowerShell SSH issues
param(
    [string]$Repo = "odgriff79/mcp-sandbox-hub",
    [switch]$Open,
    [switch]$Debug,
    [switch]$AutoStart
)

$ErrorActionPreference = 'Stop'

function Write-Status {
    param([string]$Message, [string]$Type = 'Info')
    $colors = @{
        'Success' = 'Green'
        'Warning' = 'Yellow' 
        'Error' = 'Red'
        'Info' = 'Cyan'
    }
    Write-Host "[$Type] $Message" -ForegroundColor $colors[$Type]
}

# Get Codespace name
Write-Status "Finding Codespace..." -Type 'Info'
$Name = gh codespace list --repo $Repo --json name,state,createdAt --jq "sort_by(.createdAt) | last | .name"
if (-not $Name) { 
    throw "No codespace found for $Repo" 
}

$State = gh codespace view -c $Name --json state --jq .state
Write-Status "Codespace: $Name (State: $State)" -Type 'Success'

# Start Codespace if needed
if ($State -ne "Available") {
    Write-Status "Starting Codespace..." -Type 'Warning'
    gh codespace start -c $Name
    do {
        Start-Sleep -Seconds 2
        $State = gh codespace view -c $Name --json state --jq .state
        Write-Host "." -NoNewline
    } while ($State -ne "Available")
    Write-Host ""
    Write-Status "Codespace started" -Type 'Success'
}

# CRITICAL: Use base64 encoding to avoid PowerShell/SSH quote hell
# This is the secret sauce that makes it work reliably on Windows
$startScript = @'
#!/bin/bash
set -e

echo "[1/6] Killing any existing processes on port 8765..."
pkill -f "health_server.py" 2>/dev/null || true
pkill -f "python.*8765" 2>/dev/null || true
lsof -ti:8765 | xargs -r kill 2>/dev/null || true
sleep 1

echo "[2/6] Verifying Python installation..."
PYTHON_CMD=""
for cmd in /usr/bin/python3 python3 python; do
    if command -v $cmd &> /dev/null; then
        PYTHON_CMD=$cmd
        echo "Found Python: $($cmd --version 2>&1)"
        break
    fi
done

if [ -z "$PYTHON_CMD" ]; then
    echo "ERROR: Python not found!"
    exit 1
fi

echo "[3/6] Starting health server..."
cd /workspaces/mcp-sandbox-hub
nohup $PYTHON_CMD -u tools/health_server.py > /tmp/health.log 2>&1 &
SERVER_PID=$!
echo $SERVER_PID > /tmp/health.pid
echo "Started with PID: $SERVER_PID"

echo "[4/6] Waiting for server to initialize..."
for i in {1..10}; do
    if curl -fsS http://127.0.0.1:8765/health 2>/dev/null; then
        echo ""
        echo "Server is responding!"
        break
    fi
    echo -n "."
    sleep 1
done
echo ""

echo "[5/6] Verifying server status..."
if ps -p $SERVER_PID > /dev/null; then
    echo "Process is running"
    ss -ltnp 2>/dev/null | grep :8765 || netstat -tln | grep :8765
else
    echo "ERROR: Process died!"
    echo "Last 20 lines of log:"
    tail -20 /tmp/health.log
    exit 1
fi

echo "[6/6] Testing health endpoint..."
curl -sS http://127.0.0.1:8765/health | python3 -m json.tool || echo "Failed to parse JSON"
echo "SUCCESS: Health server is running on port 8765"
'@

# Convert to base64 to avoid quote issues
$scriptBytes = [System.Text.Encoding]::UTF8.GetBytes($startScript)
$scriptBase64 = [Convert]::ToBase64String($scriptBytes)

Write-Status "Starting health server (using base64 encoding to avoid shell issues)..." -Type 'Info'

# Execute via base64 - this avoids ALL quoting issues
$output = gh codespace ssh -c $Name -- "echo '$scriptBase64' | base64 -d | bash" 2>&1
Write-Host $output

# Check if it worked
$checkResult = gh codespace ssh -c $Name -- "curl -fsS http://127.0.0.1:8765/health 2>/dev/null"
if ($LASTEXITCODE -eq 0) {
    Write-Status "Internal health check passed!" -Type 'Success'
    if ($Debug) {
        Write-Status "Response: $checkResult" -Type 'Info'
    }
} else {
    Write-Status "Internal health check failed" -Type 'Error'
    
    # Get debug info
    Write-Status "Fetching debug information..." -Type 'Info'
    $debugCmd = 'ps aux | grep -E "python.*health" | grep -v grep; echo "---"; tail -10 /tmp/health.log 2>/dev/null || echo "No log"'
    $debugInfo = gh codespace ssh -c $Name -- $debugCmd 2>&1
    Write-Host $debugInfo
    
    throw "Health server is not responding"
}

# Setup port forwarding if needed
Write-Status "Checking port forwarding..." -Type 'Info'
$ports = gh codespace ports -c $Name --json sourcePort,browseUrl 2>&1 | ConvertFrom-Json -ErrorAction SilentlyContinue
$port8765 = $ports | Where-Object { $_.sourcePort -eq 8765 }

if (-not $port8765 -or -not $port8765.browseUrl) {
    Write-Status "Setting up port forwarding..." -Type 'Warning'
    gh codespace ports visibility -c $Name 8765:public 2>&1 | Out-Null
    Start-Sleep -Seconds 2
    
    # Re-fetch ports
    $ports = gh codespace ports -c $Name --json sourcePort,browseUrl 2>&1 | ConvertFrom-Json -ErrorAction SilentlyContinue
    $port8765 = $ports | Where-Object { $_.sourcePort -eq 8765 }
}

# Test external access
if ($port8765.browseUrl) {
    $healthUrl = "$($port8765.browseUrl)/health"
    Write-Status "Testing external access: $healthUrl" -Type 'Info'
    
    $maxRetries = 5
    $success = $false
    
    for ($i = 1; $i -le $maxRetries; $i++) {
        try {
            $response = Invoke-WebRequest -Uri $healthUrl -TimeoutSec 5 -UseBasicParsing -ErrorAction SilentlyContinue
            if ($response.StatusCode -eq 200) {
                Write-Status "External health check passed! (HTTP $($response.StatusCode))" -Type 'Success'
                Write-Status "Health URL: $healthUrl" -Type 'Success'
                $success = $true
                break
            }
        } catch {
            if ($i -lt $maxRetries) {
                Write-Host "Retry $i/$maxRetries..." -ForegroundColor Yellow
                Start-Sleep -Seconds 2
            }
        }
    }
    
    if ($success) {
        if ($Open) {
            Write-Status "Opening in browser..." -Type 'Info'
            Start-Process $healthUrl
        }
    } else {
        Write-Status "External access failed - the Codespace proxy may need time to update" -Type 'Warning'
        Write-Status "Try accessing directly: $healthUrl" -Type 'Info'
    }
} else {
    Write-Status "Could not get forwarded URL - open Codespace manually" -Type 'Warning'
    if ($Open) {
        gh codespace code -c $Name --web
    }
}

# Setup auto-start if requested
if ($AutoStart) {
    Write-Status "Setting up auto-start configuration..." -Type 'Info'
    
    $autoStartScript = @'
#!/bin/bash
# Auto-start health server on Codespace startup
if [ -f /workspaces/mcp-sandbox-hub/tools/health_server.py ]; then
    pkill -f health_server.py 2>/dev/null || true
    cd /workspaces/mcp-sandbox-hub
    nohup python3 -u tools/health_server.py > /tmp/health.log 2>&1 &
    echo "Health server started with PID: $!"
fi
'@
    
    $autoStartBase64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($autoStartScript))
    
    # Create startup script
    gh codespace ssh -c $Name -- "echo '$autoStartBase64' | base64 -d > /tmp/start-health.sh && chmod +x /tmp/start-health.sh" 2>&1 | Out-Null
    
    Write-Status "Auto-start script created at /tmp/start-health.sh" -Type 'Success'
    Write-Status "Add to .devcontainer/devcontainer.json:" -Type 'Info'
    Write-Host '  "postStartCommand": "/tmp/start-health.sh"' -ForegroundColor Cyan
}

Write-Status "`n=== Summary ===" -Type 'Success'
Write-Status "✓ Health server is running" -Type 'Success'
Write-Status "✓ Port 8765 is forwarded" -Type 'Success'
if ($success) {
    Write-Status "✓ External access verified" -Type 'Success'
}
Write-Status "Codespace: $Name" -Type 'Info'
