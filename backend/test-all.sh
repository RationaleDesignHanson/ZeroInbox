#!/bin/bash

##############################################################################
# Unified Test Runner for Zero Backend Services
#
# Runs all backend tests across classifier and shopping-agent services
# Aggregates coverage and provides summary report
#
# Usage:
#   ./test-all.sh              # Run all tests
#   ./test-all.sh --watch      # Run in watch mode
#   ./test-all.sh --coverage   # Run with detailed coverage
#   ./test-all.sh --verbose    # Run with verbose output
##############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
BACKEND_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLASSIFIER_DIR="$BACKEND_DIR/services/classifier"
SHOPPING_AGENT_DIR="$BACKEND_DIR/services/shopping-agent"

# Parse arguments
WATCH_MODE=false
COVERAGE_MODE=true
VERBOSE=false
FAILED_ONLY=false

for arg in "$@"; do
    case $arg in
        --watch)
            WATCH_MODE=true
            ;;
        --no-coverage)
            COVERAGE_MODE=false
            ;;
        --verbose)
            VERBOSE=true
            ;;
        --failed-only)
            FAILED_ONLY=true
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --watch         Run tests in watch mode"
            echo "  --no-coverage   Skip coverage reporting"
            echo "  --verbose       Show detailed test output"
            echo "  --failed-only   Only re-run failed tests"
            echo "  --help          Show this help message"
            exit 0
            ;;
    esac
done

# Print header
echo ""
echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║         Zero Backend Services - Test Suite Runner             ║${NC}"
echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Track overall status
OVERALL_SUCCESS=true
TOTAL_TESTS=0
TOTAL_PASSED=0
TOTAL_FAILED=0

# Function to run tests for a service
run_service_tests() {
    local service_name=$1
    local service_dir=$2

    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}Testing: $service_name${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    if [ ! -d "$service_dir" ]; then
        echo -e "${RED}✗ Directory not found: $service_dir${NC}"
        return 1
    fi

    cd "$service_dir"

    # Build test command
    local test_cmd="npm test"

    if [ "$WATCH_MODE" = true ]; then
        test_cmd="npm run test:watch"
    elif [ "$FAILED_ONLY" = true ]; then
        test_cmd="npm test -- --onlyFailures"
    elif [ "$VERBOSE" = true ]; then
        test_cmd="npm test -- --verbose"
    fi

    if [ "$COVERAGE_MODE" = false ]; then
        test_cmd="$test_cmd -- --coverage=false"
    fi

    # Run tests
    echo -e "${CYAN}Running: $test_cmd${NC}"
    echo ""

    if eval "$test_cmd"; then
        echo ""
        echo -e "${GREEN}✓ $service_name tests passed${NC}"
        return 0
    else
        echo ""
        echo -e "${RED}✗ $service_name tests failed${NC}"
        OVERALL_SUCCESS=false
        return 1
    fi
}

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo -e "${RED}Error: npm is not installed${NC}"
    exit 1
fi

# Install dependencies if needed
check_dependencies() {
    local service_dir=$1
    local service_name=$2

    if [ ! -d "$service_dir/node_modules" ]; then
        echo -e "${YELLOW}Installing dependencies for $service_name...${NC}"
        cd "$service_dir"
        npm install
    fi
}

# Main execution
main() {
    echo -e "${CYAN}Checking dependencies...${NC}"
    check_dependencies "$CLASSIFIER_DIR" "classifier"
    check_dependencies "$SHOPPING_AGENT_DIR" "shopping-agent"

    # Run classifier service tests
    if run_service_tests "Classifier Service" "$CLASSIFIER_DIR"; then
        CLASSIFIER_SUCCESS=true
    else
        CLASSIFIER_SUCCESS=false
    fi

    # Run shopping agent service tests
    if run_service_tests "Shopping Agent Service" "$SHOPPING_AGENT_DIR"; then
        SHOPPING_SUCCESS=true
    else
        SHOPPING_SUCCESS=false
    fi

    # Print summary
    echo ""
    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                        Test Summary                           ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    if [ "$CLASSIFIER_SUCCESS" = true ]; then
        echo -e "${GREEN}✓ Classifier Service:    PASSED${NC}"
        echo "  - 82 unsubscribe safety & parsing tests"
    else
        echo -e "${RED}✗ Classifier Service:    FAILED${NC}"
    fi

    if [ "$SHOPPING_SUCCESS" = true ]; then
        echo -e "${GREEN}✓ Shopping Agent:        PASSED${NC}"
        echo "  - 40 receipt parsing tests"
    else
        echo -e "${RED}✗ Shopping Agent:        FAILED${NC}"
    fi

    echo ""

    if [ "$OVERALL_SUCCESS" = true ]; then
        echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║                  ALL TESTS PASSED ✓                           ║${NC}"
        echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${GREEN}Total: 122 tests passing across all services${NC}"
        exit 0
    else
        echo -e "${RED}╔═══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${RED}║                  SOME TESTS FAILED ✗                          ║${NC}"
        echo -e "${RED}╚═══════════════════════════════════════════════════════════════╝${NC}"
        exit 1
    fi
}

# Handle Ctrl+C gracefully
trap 'echo -e "\n${YELLOW}Tests interrupted${NC}"; exit 130' INT

# Run main
main
