#!/bin/bash
set -euo pipefail

# EventFlow Production Smoke Tests
# Run after deployment to verify critical services are working
# Usage: ./smoke_test.sh [base_url]

BASE_URL="${1:-https://api.eventflow.com}"
FRONTEND_URL="${2:-https://app.eventflow.com}"
MEDIA_URL="${3:-https://media.eventflow.com}"
PASS=0
FAIL=0

pass() {
    echo "  PASS: $1"
    PASS=$((PASS + 1))
}

fail() {
    echo "  FAIL: $1"
    FAIL=$((FAIL + 1))
}

echo "=== EventFlow Production Smoke Tests ==="
echo "API: ${BASE_URL}"
echo "Frontend: ${FRONTEND_URL}"
echo "Media: ${MEDIA_URL}"
echo ""

# 1. Health endpoint
echo "1. Health Check"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${BASE_URL}/health/" 2>/dev/null || echo "000")
if [ "$STATUS" = "200" ]; then
    pass "health/ returns 200"
else
    fail "health/ returns ${STATUS} (expected 200)"
fi

# 2. Readiness endpoint
echo "2. Readiness Check"
BODY=$(curl -s "${BASE_URL}/ready/" 2>/dev/null || echo "{}")
if echo "$BODY" | grep -q '"database": true'; then
    pass "database check passes"
else
    fail "database check fails"
fi
if echo "$BODY" | grep -q '"redis": true'; then
    pass "redis check passes"
else
    fail "redis check fails"
fi

# 3. Liveness endpoint
echo "3. Liveness Check"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${BASE_URL}/live/" 2>/dev/null || echo "000")
if [ "$STATUS" = "200" ]; then
    pass "live/ returns 200"
else
    fail "live/ returns ${STATUS}"
fi

# 4. Frontend serves HTML
echo "4. Frontend"
CONTENT_TYPE=$(curl -s -o /dev/null -w "%{content_type}" "${FRONTEND_URL}/" 2>/dev/null || echo "")
if echo "$CONTENT_TYPE" | grep -qi "text/html"; then
    pass "Frontend returns HTML"
else
    fail "Frontend content-type: ${CONTENT_TYPE}"
fi

# 5. Static assets
echo "5. Static Assets"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${FRONTEND_URL}/_next/static/" 2>/dev/null || echo "000")
if [ "$STATUS" = "200" ] || [ "$STATUS" = "403" ] || [ "$STATUS" = "404" ]; then
    pass "Static assets accessible"
else
    fail "Static assets returns ${STATUS}"
fi

# 6. API requires auth
echo "6. API Authentication"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${BASE_URL}/api/v1/tenants/" 2>/dev/null || echo "000")
if [ "$STATUS" = "401" ]; then
    pass "Unauthenticated API returns 401"
else
    fail "Unauthenticated API returns ${STATUS} (expected 401)"
fi

# 7. Login endpoint accepts POST
echo "7. Auth Endpoints"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
    -H "Content-Type: application/json" \
    -d '{"email":"test","password":"test"}' \
    "${BASE_URL}/api/v1/auth/login/" 2>/dev/null || echo "000")
if [ "$STATUS" = "400" ] || [ "$STATUS" = "401" ]; then
    pass "Login endpoint responds (400/401 for invalid creds)"
else
    fail "Login endpoint returns ${STATUS}"
fi

# 8. Password reset throttling
echo "8. Throttling"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
    -H "Content-Type: application/json" \
    -d '{"email":"test@test.com"}' \
    "${BASE_URL}/api/v1/auth/forgot-password/" 2>/dev/null || echo "000")
if [ "$STATUS" = "200" ] || [ "$STATUS" = "429" ]; then
    pass "Forgot-password endpoint responds"
else
    fail "Forgot-password returns ${STATUS}"
fi

# 9. Admin is protected
echo "9. Admin Protection"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${BASE_URL}/admin/" 2>/dev/null || echo "000")
if [ "$STATUS" = "302" ] || [ "$STATUS" = "403" ]; then
    pass "Admin redirects/forbids"
else
    fail "Admin returns ${STATUS}"
fi

# 10. Security headers
echo "10. Security Headers"
HEADERS=$(curl -s -I "${BASE_URL}/health/" 2>/dev/null || echo "")
if echo "$HEADERS" | grep -qi "x-frame-options"; then
    pass "X-Frame-Options present"
else
    fail "X-Frame-Options missing"
fi
if echo "$HEADERS" | grep -qi "x-content-type-options"; then
    pass "X-Content-Type-Options present"
else
    fail "X-Content-Type-Options missing"
fi

# Summary
echo ""
echo "=== Results ==="
echo "Passed: ${PASS}"
echo "Failed: ${FAIL}"
echo ""
if [ "$FAIL" -gt 0 ]; then
    echo "STATUS: SOME TESTS FAILED"
    exit 1
else
    echo "STATUS: ALL TESTS PASSED"
    exit 0
fi
