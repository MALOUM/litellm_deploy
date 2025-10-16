#!/bin/bash
# Test script for LiteLLM Bedrock Proxy
# Usage: ./test_litellm.sh [MASTER_KEY]

set -e

# Configuration
HOST="${LITELLM_HOST:-http://localhost:4002}"
MASTER_KEY="${1:-sk-1234}"

echo "=================================================="
echo "🧪 LiteLLM Bedrock Proxy - Test Suite"
echo "=================================================="
echo ""
echo "📍 Host: $HOST"
echo "🔑 Master Key: ${MASTER_KEY:0:10}..."
echo ""

# Test 1: Health Check
echo "=== Test 1: Health Check ==="
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$HOST/health")
if [[ "$HTTP_CODE" -eq 200 ]] || [[ "$HTTP_CODE" -eq 401 ]]; then
    echo "✅ Service is responding (HTTP $HTTP_CODE)"
else
    echo "❌ Service not responding (HTTP $HTTP_CODE)"
    exit 1
fi
echo ""

# Test 2: List Models
echo "=== Test 2: List Models ==="
MODELS=$(curl -s "$HOST/v1/models" \
    -H "Authorization: Bearer $MASTER_KEY" | jq -r '.data | length')
echo "✅ Found $MODELS model(s)"
echo ""

# Test 3: Chat Completion (Claude 3.7 Sonnet)
echo "=== Test 3: Chat Completion (Claude) ==="
CHAT_RESPONSE=$(curl -s -X POST "$HOST/v1/chat/completions" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $MASTER_KEY" \
    -d '{
        "model": "claude-3-7-sonnet",
        "messages": [{"role": "user", "content": "Say: TEST OK"}],
        "max_tokens": 20
    }')

CHAT_CONTENT=$(echo "$CHAT_RESPONSE" | jq -r '.choices[0].message.content // "ERROR"')
CHAT_TOKENS=$(echo "$CHAT_RESPONSE" | jq -r '.usage.total_tokens // 0')

if [[ "$CHAT_CONTENT" == "ERROR" ]]; then
    echo "❌ Chat completion failed"
    echo "$CHAT_RESPONSE" | jq .
    exit 1
fi

echo "✅ Response: $CHAT_CONTENT"
echo "📊 Tokens: $CHAT_TOKENS"
echo ""

# Test 4: Embedding (Titan)
echo "=== Test 4: Embedding (Titan) ==="
EMBED_RESPONSE=$(curl -s -X POST "$HOST/v1/embeddings" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $MASTER_KEY" \
    -d '{
        "model": "titan-embed-text-v2",
        "input": "Test embedding"
    }')

EMBED_DIM=$(echo "$EMBED_RESPONSE" | jq -r '.data[0].embedding | length // 0')
EMBED_TOKENS=$(echo "$EMBED_RESPONSE" | jq -r '.usage.total_tokens // 0')

if [[ "$EMBED_DIM" -eq 0 ]]; then
    echo "❌ Embedding failed"
    echo "$EMBED_RESPONSE" | jq .
    exit 1
fi

echo "✅ Dimensions: $EMBED_DIM"
echo "📊 Tokens: $EMBED_TOKENS"
echo ""

# Summary
echo "=================================================="
echo "✅ All tests passed successfully!"
echo "=================================================="
echo ""
echo "📋 Summary:"
echo "  - Health: OK"
echo "  - Models: $MODELS"
echo "  - Chat: OK ($CHAT_TOKENS tokens)"
echo "  - Embedding: OK ($EMBED_DIM dimensions, $EMBED_TOKENS tokens)"
echo ""
echo "🎉 LiteLLM Proxy is working correctly!"
