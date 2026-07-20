#!/bin/bash
# Call a ClaudeCodeBrowser bridge tool: bt.sh <tool_name> ['<json-args>']
# Firefox automation via the local bridge (HTTP on localhost:8765).
# Token: ~/.claudecodebrowser/api_token. Tools: /mcp/tools on the bridge.
TOKEN=$(cat ~/.claudecodebrowser/api_token)
NAME=$1; ARGS=${2:-'{}'}
curl -s -m 45 -X POST -H "X-API-Key: $TOKEN" -H 'Content-Type: application/json' \
  http://localhost:8765/mcp/call -d "{\"name\":\"$NAME\",\"arguments\":$ARGS}"
