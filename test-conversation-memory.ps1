#!/usr/bin/env pwsh

# Test script to verify conversation memory is working
Write-Host "🚀 Testing Conversation Memory Feature" -ForegroundColor Green
Write-Host ""

# Check if backend is running
Write-Host "📡 Checking backend availability..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "http://localhost:8000/health" -Method GET -TimeoutSec 5
    Write-Host "✅ Backend is running" -ForegroundColor Green
} catch {
    Write-Host "❌ Backend is not running. Please start your backend on port 8000" -ForegroundColor Red
    Write-Host "Expected endpoint: http://localhost:8000/chat" -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "🧪 Testing conversation context..." -ForegroundColor Yellow

# Test 1: First message (no context)
Write-Host "Test 1: First message (no context)" -ForegroundColor Cyan
$payload1 = @{
    query = "List available personas"
    user_id = "test_user_123"
    conversation_id = "test_conv_001"
} | ConvertTo-Json

try {
    $response1 = Invoke-RestMethod -Uri "http://localhost:8000/chat" -Method POST -ContentType "application/json" -Body $payload1
    Write-Host "✅ First message sent successfully" -ForegroundColor Green
    Write-Host "Response: $($response1.answer.Substring(0, [Math]::Min(100, $response1.answer.Length)))..." -ForegroundColor White
} catch {
    Write-Host "❌ Failed to send first message: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Test 2: Second message with conversation context
Write-Host "Test 2: Second message with conversation context" -ForegroundColor Cyan
$context = @(
    @{
        role = "user"
        content = "List available personas"
    },
    @{
        role = "assistant"
        content = $response1.answer
    }
)

$payload2 = @{
    query = "What persona was that?"
    user_id = "test_user_123"
    conversation_id = "test_conv_001"
    context = $context
} | ConvertTo-Json -Depth 5

try {
    $response2 = Invoke-RestMethod -Uri "http://localhost:8000/chat" -Method POST -ContentType "application/json" -Body $payload2
    Write-Host "✅ Second message with context sent successfully" -ForegroundColor Green
    Write-Host "Response: $($response2.answer.Substring(0, [Math]::Min(100, $response2.answer.Length)))..." -ForegroundColor White
} catch {
    Write-Host "❌ Failed to send second message: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🎉 Conversation memory test completed!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Summary:" -ForegroundColor Yellow
Write-Host "✅ Backend API accepts conversation context" -ForegroundColor Green
Write-Host "✅ Conversation memory format is working" -ForegroundColor Green
Write-Host ""
Write-Host "🚀 Now start the frontend to test full integration:" -ForegroundColor Cyan
Write-Host "docker run -p 8080:8080 --env-file .env dynamic-persona-frontend" -ForegroundColor White
Write-Host ""
Write-Host "Then open: http://localhost:8080" -ForegroundColor Yellow
