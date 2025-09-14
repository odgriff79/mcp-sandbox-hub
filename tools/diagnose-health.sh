#!/bin/bash
# diagnose-health.sh - Run this INSIDE the Codespace to diagnose/fix health server issues
# Usage: bash diagnose-health.sh [--fix]

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log_info() { echo -e "${CYAN}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

FIX_MODE=false
if [ "$1" == "--fix" ]; then
    FIX_MODE=true
    log_info "Running in FIX mode"
fi

log_info "=== Health Server Diagnostic ==="

# 1. Check environment
log_info "Checking environment..."
echo "Hostname: $(hostname)"
echo "PWD: $(pwd)"
echo "User: $(whoami)"

# 2. Check Python
log_info "Checking Python installation..."
PYTHON_CMD=""
for cmd in /usr/bin/python3 python3 python; do
    if command -v $cmd &> /dev/null; then
        PYTHON_CMD=$cmd
        log_success "Found Python: $cmd"
        $cmd --version
        break
    fi
done

if [ -z "$PYTHON_CMD" ]; then
    log_error "Python not found!"
    exit 1
fi

# 3. Check if health_server.py exists
log_info "Checking health_server.py..."
HEALTH_SERVER="/workspaces/mcp-sandbox-hub/tools/health_server.py"
if [ -f "$HEALTH_SERVER" ]; then
    log_success "health_server.py exists"
    echo "Size: $(stat -c%s "$HEALTH_SERVER") bytes"
    echo "First line: $(head -1 "$HEALTH_SERVER")"
else
    log_error "health_server.py not found at $HEALTH_SERVER"
    exit 1
fi

# 4. Check current processes
log_info "Checking for existing processes..."
if pgrep -f health_server.py > /dev/null; then
    log_warning "Health server process found:"
    ps aux | grep -E "python.*health_server" | grep -v grep
    
    if [ "$FIX_MODE" == true ]; then
        log_info "Killing existing processes..."
        pkill -f health_server.py || true
        sleep 1
        log_success "Processes killed"
    fi
else
    log_info "No existing health server process"
fi

# 5. Check port 8765
log_info "Checking port 8765..."
if lsof -i:8765 2>/dev/null; then
    log_warning "Port 8765 is in use:"
    lsof -i:8765
    
    if [ "$FIX_MODE" == true ]; then
        log_info "Killing process on port 8765..."
        lsof -ti:8765 | xargs -r kill 2>/dev/null || true
        sleep 1
        log_success "Port freed"
    fi
else
    log_info "Port 8765 is free"
fi

# 6. Check log file
log_info "Checking log file..."
if [ -f /tmp/health.log ]; then
    echo "Log file exists. Last 10 lines:"
    tail -10 /tmp/health.log
else
    echo "No log file found"
fi

# 7. Test syntax
log_info "Testing Python syntax..."
if $PYTHON_CMD -m py_compile "$HEALTH_SERVER" 2>/dev/null; then
    log_success "Python syntax is valid"
else
    log_error "Python syntax error!"
    $PYTHON_CMD -m py_compile "$HEALTH_SERVER"
    exit 1
fi

# 8. Start server if in fix mode
if [ "$FIX_MODE" == true ]; then
    log_info "Starting health server..."
    cd /workspaces/mcp-sandbox-hub
    nohup $PYTHON_CMD -u tools/health_server.py > /tmp/health.log 2>&1 &
    SERVER_PID=$!
    echo $SERVER_PID > /tmp/health.pid
    log_success "Started with PID: $SERVER_PID"
    
    # Wait for startup
    log_info "Waiting for server to start..."
    for i in {1..10}; do
        if curl -fsS http://127.0.0.1:8765/health 2>/dev/null; then
            echo ""
            log_success "Server is responding!"
            break
        fi
        echo -n "."
        sleep 1
    done
    echo ""
    
    # Verify
    if ps -p $SERVER_PID > /dev/null; then
        log_success "Process is running"
    else
        log_error "Process died! Check /tmp/health.log"
        tail -20 /tmp/health.log
        exit 1
    fi
fi

# 9. Test health endpoint
log_info "Testing health endpoint..."
if curl -fsS http://127.0.0.1:8765/health > /dev/null 2>&1; then
    log_success "Health endpoint is responding!"
    echo "Response:"
    curl -sS http://127.0.0.1:8765/health | python3 -m json.tool
else
    log_warning "Health endpoint not responding"
    if [ "$FIX_MODE" == false ]; then
        echo "Run with --fix to start the server"
    fi
fi

# 10. Network info
log_info "Network information:"
echo "Listening ports:"
ss -ltn | grep -E "(:8765|State)" || netstat -tln | grep -E "(:8765|Proto)"

log_info "=== Diagnostic Complete ==="

if [ "$FIX_MODE" == false ]; then
    echo ""
    echo "To fix issues, run: bash diagnose-health.sh --fix"
fi
