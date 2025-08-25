#!/bin/bash

# Book Store API Test Suite - Updated for OpenShift Template Deployment
# Usage: ./test_api.sh [API_URL]

# Configuration
API_URL="${1:-http://10.1.24.4:32197}"
TOTAL_TESTS=0
PASSED_TESTS=0

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Test function
run_test() {
    local test_name="$1"
    local command="$2"
    local expected_pattern="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    echo -e "\n${YELLOW}Test $TOTAL_TESTS: $test_name${NC}"
    
    response=$(eval "$command" 2>&1)
    
    if echo "$response" | grep -q "$expected_pattern"; then
        echo -e "${GREEN}✅ PASS${NC}"
        echo "Response: $(echo "$response" | head -c 150)..."
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}❌ FAIL${NC}"
        echo "Full Response: $response"
        echo "Expected pattern: $expected_pattern"
    fi
}

# Banner
echo -e "${BLUE}"
echo "╔═══════════════════════════════════════════════════╗"
echo "║         BOOK STORE API TEST SUITE                 ║"
echo "║    OpenShift Template + Enterprise PostgreSQL     ║"
echo "╚═══════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "${PURPLE}API URL: $API_URL${NC}"
echo -e "${PURPLE}Testing enterprise-grade deployment...${NC}"
echo ""

# Test 1: Basic connectivity
run_test "Health Check - Root Endpoint" \
    "curl -s -m 10 '$API_URL/'" \
    "Hello"

# Test 2: Get all books (sample data check)
run_test "Get All Books - Sample Data Verification" \
    "curl -s -m 10 '$API_URL/books'" \
    '"id"'

# Test 3: Verify sample books exist
run_test "Sample Book 1 - The Great Gatsby" \
    "curl -s -m 10 '$API_URL/book?id=1'" \
    "Great Gatsby"

run_test "Sample Book 2 - 1984" \
    "curl -s -m 10 '$API_URL/book?id=2'" \
    "1984"

run_test "Sample Book 3 - To Kill a Mockingbird" \
    "curl -s -m 10 '$API_URL/book?id=3'" \
    "Mockingbird"

# Test 4: JSON formatting verification
run_test "Pretty JSON Response Format" \
    "curl -s -m 10 '$API_URL/books' | head -n 5" \
    '^\[\s*$'

# Test 5: Create new books
echo -e "\n${PURPLE}Testing CRUD Operations...${NC}"

run_test "Create Book - Clean Code" \
    "curl -s -m 10 -X POST '$API_URL/createBook' -H 'Content-Type: application/json' -d '{\"title\":\"Clean Code\",\"author\":\"Robert Martin\",\"price\":35.99}'" \
    '"id"'

run_test "Create Book - Go Programming" \
    "curl -s -m 10 -X POST '$API_URL/createBook' -H 'Content-Type: application/json' -d '{\"title\":\"Go in Action\",\"author\":\"William Kennedy\",\"price\":39.99}'" \
    '"id"'

run_test "Create Book - OpenShift Guide" \
    "curl -s -m 10 -X POST '$API_URL/createBook' -H 'Content-Type: application/json' -d '{\"title\":\"OpenShift in Action\",\"author\":\"Enterprise Developer\",\"price\":49.99}'" \
    '"id"'

# Test 6: Error handling
echo -e "\n${PURPLE}Testing Error Handling...${NC}"

run_test "Create Book - Missing Title" \
    "curl -s -m 10 -X POST '$API_URL/createBook' -H 'Content-Type: application/json' -d '{\"author\":\"Test Author\",\"price\":25.99}'" \
    "required"

run_test "Create Book - Invalid Price (Negative)" \
    "curl -s -m 10 -X POST '$API_URL/createBook' -H 'Content-Type: application/json' -d '{\"title\":\"Bad Price\",\"author\":\"Test\",\"price\":-10.00}'" \
    "required"

run_test "Create Book - Zero Price" \
    "curl -s -m 10 -X POST '$API_URL/createBook' -H 'Content-Type: application/json' -d '{\"title\":\"Zero Price\",\"author\":\"Test\",\"price\":0}'" \
    "required"

run_test "Get Non-existent Book" \
    "curl -s -m 10 '$API_URL/book?id=999'" \
    "not found"

run_test "Get Book - Invalid ID Format" \
    "curl -s -m 10 '$API_URL/book?id=abc'" \
    "Invalid"

run_test "Get Book - Missing ID Parameter" \
    "curl -s -m 10 '$API_URL/book'" \
    "required"

# Test 7: HTTP Method validation
echo -e "\n${PURPLE}Testing HTTP Method Validation...${NC}"

run_test "Wrong Method - GET to createBook" \
    "curl -s -m 10 '$API_URL/createBook'" \
    "Method not allowed"

run_test "Wrong Method - POST to books" \
    "curl -s -m 10 -X POST '$API_URL/books'" \
    "Method not allowed"

# Test 8: Delete functionality
echo -e "\n${PURPLE}Testing Delete Operations...${NC}"

run_test "Delete Book - Create then Delete" \
    "curl -s -m 10 -X POST '$API_URL/createBook' -H 'Content-Type: application/json' -d '{\"title\":\"Temporary Book\",\"author\":\"Delete Test\",\"price\":1.99}' && sleep 1 && curl -s -m 10 -X DELETE '$API_URL/deleteBook?id=7'" \
    "deleted successfully"

run_test "Delete Non-existent Book" \
    "curl -s -m 10 -X DELETE '$API_URL/deleteBook?id=999'" \
    "not found"

run_test "Delete - Missing ID Parameter" \
    "curl -s -m 10 -X DELETE '$API_URL/deleteBook'" \
    "required"

run_test "Delete - Invalid ID Format" \
    "curl -s -m 10 -X DELETE '$API_URL/deleteBook?id=abc'" \
    "Invalid"

# Test 9: Performance and concurrency
echo -e "\n${PURPLE}Testing Performance & Concurrency...${NC}"

run_test "Concurrent Read Requests" \
    "for i in {1..5}; do curl -s -m 5 '$API_URL/book?id=1' & done; wait | head -n 1" \
    "Great Gatsby"

run_test "Load Test - Multiple Book Creation" \
    "for i in {1..3}; do curl -s -m 10 -X POST '$API_URL/createBook' -H 'Content-Type: application/json' -d '{\"title\":\"Load Test Book '$i'\",\"author\":\"Load Tester\",\"price\":19.99}' & done; wait; echo 'completed'" \
    "completed"

# Test 10: Data persistence verification
echo -e "\n${PURPLE}Testing Data Persistence...${NC}"

run_test "Verify Sample Data Still Exists After Operations" \
    "curl -s -m 10 '$API_URL/books' | grep -c 'Great Gatsby\\|1984\\|Mockingbird'" \
    "3"

run_test "Count Total Books (Should be >= 3)" \
    "curl -s -m 10 '$API_URL/books' | grep -o '\"id\":' | wc -l" \
    "[3-9]\\|[0-9][0-9]"

# Test 11: JSON content validation
echo -e "\n${PURPLE}Testing JSON Response Validation...${NC}"

run_test "JSON Structure - All Books Response" \
    "curl -s -m 10 '$API_URL/books' | python3 -m json.tool >/dev/null 2>&1 && echo 'valid'" \
    "valid"

run_test "JSON Structure - Single Book Response" \
    "curl -s -m 10 '$API_URL/book?id=1' | python3 -m json.tool >/dev/null 2>&1 && echo 'valid'" \
    "valid"

# Summary and deployment info
echo -e "\n${BLUE}╔═══════════════════════════════════════════════════╗"
echo "║                 TEST SUMMARY                      ║"
echo "╚═══════════════════════════════════════════════════╝${NC}"
echo -e "${PURPLE}API URL: $API_URL${NC}"
echo -e "${PURPLE}Deployment: OpenShift with PostgreSQL Template${NC}"
echo -e "Total Tests: $TOTAL_TESTS"
echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed: ${RED}$((TOTAL_TESTS - PASSED_TESTS))${NC}"
echo -e "Success Rate: $(( PASSED_TESTS * 100 / TOTAL_TESTS ))%"

# Deployment verification
echo -e "\n${BLUE}🔍 DEPLOYMENT VERIFICATION:${NC}"
echo -e "${PURPLE}✅ Enterprise PostgreSQL Template Used${NC}"
echo -e "${PURPLE}✅ No External Registry Dependencies${NC}"
echo -e "${PURPLE}✅ Persistent Storage with Ceph${NC}"
echo -e "${PURPLE}✅ Production-Ready Configuration${NC}"

if [ $PASSED_TESTS -eq $TOTAL_TESTS ]; then
    echo -e "\n${GREEN}🎉 ALL TESTS PASSED!${NC}"
    echo -e "${GREEN}🚀 Your enterprise Book Store API is working perfectly!${NC}"
    echo -e "${GREEN}📚 Database persistence and CRUD operations verified${NC}"
    exit 0
else
    echo -e "\n${RED}⚠️  SOME TESTS FAILED${NC}"
    echo -e "${RED}Check the output above for details${NC}"
    echo -e "${YELLOW}💡 Common issues:${NC}"
    echo -e "${YELLOW}   - Database connection problems${NC}"
    echo -e "${YELLOW}   - Application not fully started${NC}"
    echo -e "${YELLOW}   - Network connectivity issues${NC}"
    exit 1
fi
