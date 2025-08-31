#!/bin/bash
# test-lifecycle.sh - Comprehensive test for secure-agent container lifecycle

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_PROJECT="lifecycle-test-$$"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[TEST]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

cleanup() {
    log "Cleaning up test project..."
    echo "y" | ./secure-agent destroy "$TEST_PROJECT" >/dev/null 2>&1 || true
    rm -rf ~/Documents/Source/"$TEST_PROJECT" 2>/dev/null || true
}

trap cleanup EXIT

log "Starting container lifecycle tests..."

# Test 1: Create environment
log "Test 1: Creating environment '$TEST_PROJECT'"
./secure-agent create "$TEST_PROJECT"
if [ ! -d ~/Documents/Source/"$TEST_PROJECT" ]; then
    error "Project directory not created"
fi

# Test 2: Check container status
log "Test 2: Checking container status"
./secure-agent status "$TEST_PROJECT" | grep -q "running" || error "Container not running"

# Test 3: Test basic container functionality
log "Test 3: Testing basic container functionality"
docker exec "secure-ai-$TEST_PROJECT" bash -c "
    echo 'Testing basic commands...'
    python3 --version || exit 1
    q --version || exit 1
    which git || exit 1
" || error "Basic functionality test failed"

# Test 4: Test workspace mount
log "Test 4: Testing workspace mount"
echo "test-file-$$" > ~/Documents/Source/"$TEST_PROJECT"/test.txt
docker exec "secure-ai-$TEST_PROJECT" bash -c "
    [ -f ~/workspace/test.txt ] || exit 1
    grep -q 'test-file-$$' ~/workspace/test.txt || exit 1
" || error "Workspace mount test failed"

# Test 5: Test keyring functionality
log "Test 5: Testing keyring functionality"
./secure-agent register-key "test-key-$$" "test-value-123"
./secure-agent inject-key "test-key-$$" "$TEST_PROJECT"
docker exec "secure-ai-$TEST_PROJECT" python3 -c "
import keyring
from keyrings.alt.file import PlaintextKeyring
keyring.set_keyring(PlaintextKeyring())
val = keyring.get_password('test-key-$$-api', 'default')
assert val == 'test-value-123', f'Expected test-value-123, got {val}'
print('✓ Keyring test passed')
" || error "Keyring test failed"

# Test 6: Test AWS CLI setup (if credentials available)
if [ -f ~/.aws/credentials ]; then
    log "Test 6: Testing AWS CLI setup"
    ./secure-agent setup-aws "$TEST_PROJECT"
    docker exec "secure-ai-$TEST_PROJECT" bash -l -c "
        aws --version | grep -q 'aws-cli/2' || exit 1
        aws configure list | grep -q 'env' || exit 1
    " || error "AWS CLI test failed"
else
    warn "Test 6: Skipping AWS CLI test (no ~/.aws/credentials)"
fi

# Test 7: Test MCP configuration
log "Test 7: Testing MCP configuration"
docker exec "secure-ai-$TEST_PROJECT" bash -c "
    [ -f ~/.aws/amazonq/mcp.json ] || exit 1
    [ -f ~/workspace/.secure-agent/config/mcp.json ] || exit 1
" || error "MCP configuration test failed"

# Test 8: Test container suspend/resume
log "Test 8: Testing container suspend/resume"
./secure-agent suspend "$TEST_PROJECT"
sleep 2
if ./secure-agent status "$TEST_PROJECT" | grep -q "running"; then
    error "Container not suspended"
fi
./secure-agent activate "$TEST_PROJECT" &
ACTIVATE_PID=$!
sleep 3
kill $ACTIVATE_PID 2>/dev/null || true
sleep 1
./secure-agent status "$TEST_PROJECT" | grep -q "running" || error "Container not resumed"

# Test 9: Test direct container access (simulates terminal functionality)
log "Test 9: Testing container access"
docker exec "secure-ai-$TEST_PROJECT" bash -c "
    echo 'terminal-test-$$' > /tmp/terminal-test
    [ -f /tmp/terminal-test ] || exit 1
    grep -q 'terminal-test-$$' /tmp/terminal-test || exit 1
" || error "Container access test failed"

# Test 10: Test persistence across container recreation
log "Test 10: Testing persistence across recreation"
echo "persistent-data-$$" > ~/Documents/Source/"$TEST_PROJECT"/.secure-agent/test-persist.txt
log "Destroying container (preserving data)..."
echo "$TEST_PROJECT" | ./secure-agent destroy "$TEST_PROJECT" >/dev/null
log "Reattaching to existing project..."
echo "y" | ./secure-agent attach "$TEST_PROJECT" >/dev/null
log "Checking persistence..."
docker exec "secure-ai-$TEST_PROJECT" bash -c "
    [ -f ~/workspace/.secure-agent/test-persist.txt ] || exit 1
    grep -q 'persistent-data-$$' ~/workspace/.secure-agent/test-persist.txt || exit 1
" || error "Persistence test failed"

# Test 11: Test list functionality
log "Test 11: Testing list functionality"
./secure-agent list | grep -q "$TEST_PROJECT" || error "List test failed"

# Cleanup keyring
./secure-agent remove-key "test-key-$$" 2>/dev/null || true

log "All tests passed! ✅"
log "Container lifecycle functionality is working correctly."
