#!/bin/bash
# Test query token auth for OpenMausBot

set -e

# Generate a test token
TOKEN=$(openssl rand -base64 32 | tr -d '\n')
echo "Generated test token: $TOKEN"
echo ""

# Export env
export OMB_QUERY_TOKEN="$TOKEN"
export OMB_PORT=8799

echo "Starting server with OMB_QUERY_TOKEN set..."
echo "In another terminal, test with:"
echo ""
echo "  curl http://localhost:8799/api/health?token=$TOKEN"
echo "  curl http://localhost:8799/api/bots?token=$TOKEN"
echo ""
echo "Without token (should fail):"
echo "  curl http://localhost:8799/api/bots"
echo ""

# Start server (or just show commands)
echo "To start the server:"
echo "  OMB_QUERY_TOKEN=$TOKEN pnpm dev:server"
