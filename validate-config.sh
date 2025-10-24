#!/bin/bash
# MessageAI Configuration Validation Script
# Validates all configuration files before running the app
# Usage: npm run validate:config or ./validate-config.sh

set +e  # Don't exit on error - we want to report all issues

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Icons
CHECKMARK="✓"
WARNING="⚠️ "
ERROR="✗"
INFO="ℹ️ "

echo ""
echo "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo "${BLUE}         MessageAI Configuration Validation                 ${NC}"
echo "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

ERROR_COUNT=0
WARNING_COUNT=0
SUCCESS_COUNT=0

# Array to store error messages
declare -a ERRORS
declare -a WARNINGS

# ============================================================================
# 1. Validate GoogleService-Info.plist (REQUIRED)
# ============================================================================

echo "${BLUE}[1/3]${NC} Validating Firebase Configuration (iOS)..."
echo ""

GOOGLE_SERVICE_INFO="MessageAI/MessageAI/GoogleService-Info.plist"
GOOGLE_SERVICE_TEMPLATE="MessageAI/MessageAI/GoogleService-Info.template.plist"

if [ ! -f "$GOOGLE_SERVICE_INFO" ]; then
    echo "  ${RED}${ERROR}${NC} GoogleService-Info.plist not found"
    ERRORS+=("GoogleService-Info.plist is missing. Copy from template: cp ${GOOGLE_SERVICE_TEMPLATE} ${GOOGLE_SERVICE_INFO}")
    ERROR_COUNT=$((ERROR_COUNT + 1))
else
    echo "  ${GREEN}${CHECKMARK}${NC} File exists: ${GOOGLE_SERVICE_INFO}"
    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    
    # Check for placeholder values
    PLACEHOLDERS_FOUND=0
    
    # Required fields to check
    declare -a REQUIRED_FIELDS=("PROJECT_ID" "API_KEY" "GCM_SENDER_ID" "STORAGE_BUCKET" "CLIENT_ID" "GOOGLE_APP_ID")
    
    for FIELD in "${REQUIRED_FIELDS[@]}"; do
        if grep -q "REPLACE_WITH_YOUR_${FIELD}" "$GOOGLE_SERVICE_INFO"; then
            LINE_NUM=$(grep -n "REPLACE_WITH_YOUR_${FIELD}" "$GOOGLE_SERVICE_INFO" | cut -d: -f1 | head -1)
            echo "  ${RED}${ERROR}${NC} Placeholder found: ${FIELD} (line ${LINE_NUM})"
            ERRORS+=("Replace placeholder ${FIELD} in GoogleService-Info.plist (line ${LINE_NUM})")
            ERROR_COUNT=$((ERROR_COUNT + 1))
            PLACEHOLDERS_FOUND=$((PLACEHOLDERS_FOUND + 1))
        fi
    done
    
    # Check for generic REPLACE_WITH_YOUR pattern (catch-all)
    if grep -q "REPLACE_WITH_YOUR" "$GOOGLE_SERVICE_INFO"; then
        if [ $PLACEHOLDERS_FOUND -eq 0 ]; then
            echo "  ${RED}${ERROR}${NC} Placeholder values detected"
            ERRORS+=("Replace all REPLACE_WITH_YOUR placeholders in GoogleService-Info.plist")
            ERROR_COUNT=$((ERROR_COUNT + 1))
        fi
    else
        if [ $PLACEHOLDERS_FOUND -eq 0 ]; then
            echo "  ${GREEN}${CHECKMARK}${NC} No placeholders found - configuration looks valid"
            SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        fi
    fi
    
    # Validate XML structure (basic check)
    if ! grep -q "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" "$GOOGLE_SERVICE_INFO"; then
        echo "  ${YELLOW}${WARNING}${NC} Invalid XML header"
        WARNINGS+=("GoogleService-Info.plist may have invalid XML structure")
        WARNING_COUNT=$((WARNING_COUNT + 1))
    fi
fi

echo ""

# ============================================================================
# 2. Validate Cloud Functions Environment (OPTIONAL but recommended)
# ============================================================================

echo "${BLUE}[2/3]${NC} Validating Cloud Functions Configuration (optional)..."
echo ""

FUNCTIONS_ENV="functions/.env.local"
FUNCTIONS_ENV_TEMPLATE="functions/.env.template"

if [ ! -f "$FUNCTIONS_ENV" ]; then
    echo "  ${INFO} functions/.env.local not found (optional for AI features)"
    echo "  ${INFO} Copy template if needed: cp ${FUNCTIONS_ENV_TEMPLATE} ${FUNCTIONS_ENV}"
    echo "  ${INFO} Skipping Cloud Functions validation..."
else
    echo "  ${GREEN}${CHECKMARK}${NC} File exists: ${FUNCTIONS_ENV}"
    
    # Check for placeholder values
    ENV_PLACEHOLDERS=0
    
    # Check OpenAI key
    if grep -q "REPLACE_WITH_YOUR_OPENAI_API_KEY" "$FUNCTIONS_ENV"; then
        echo "  ${YELLOW}${WARNING}${NC} OPENAI_API_KEY has placeholder value"
        WARNINGS+=("Set OPENAI_API_KEY in functions/.env.local (required for AI features)")
        WARNING_COUNT=$((WARNING_COUNT + 1))
        ENV_PLACEHOLDERS=$((ENV_PLACEHOLDERS + 1))
    elif grep -q "^OPENAI_API_KEY=sk-" "$FUNCTIONS_ENV"; then
        echo "  ${GREEN}${CHECKMARK}${NC} OPENAI_API_KEY configured"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        echo "  ${YELLOW}${WARNING}${NC} OPENAI_API_KEY not set"
        WARNINGS+=("Set OPENAI_API_KEY in functions/.env.local (format: sk-proj-...)")
        WARNING_COUNT=$((WARNING_COUNT + 1))
    fi
    
    # Check Pinecone key
    if grep -q "REPLACE_WITH_YOUR_PINECONE_API_KEY" "$FUNCTIONS_ENV"; then
        echo "  ${YELLOW}${WARNING}${NC} PINECONE_API_KEY has placeholder value"
        WARNINGS+=("Set PINECONE_API_KEY in functions/.env.local (required for semantic search)")
        WARNING_COUNT=$((WARNING_COUNT + 1))
        ENV_PLACEHOLDERS=$((ENV_PLACEHOLDERS + 1))
    elif grep -q "^PINECONE_API_KEY=pcsk-" "$FUNCTIONS_ENV" || grep -q "^PINECONE_API_KEY=pc-" "$FUNCTIONS_ENV"; then
        echo "  ${GREEN}${CHECKMARK}${NC} PINECONE_API_KEY configured"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        echo "  ${YELLOW}${WARNING}${NC} PINECONE_API_KEY not set"
        WARNINGS+=("Set PINECONE_API_KEY in functions/.env.local (format: pcsk-... or pc-...)")
        WARNING_COUNT=$((WARNING_COUNT + 1))
    fi
    
    # Check Pinecone environment
    if grep -q "^PINECONE_ENVIRONMENT=" "$FUNCTIONS_ENV" && ! grep -q "REPLACE_WITH_YOUR" "$FUNCTIONS_ENV"; then
        echo "  ${GREEN}${CHECKMARK}${NC} PINECONE_ENVIRONMENT configured"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        echo "  ${YELLOW}${WARNING}${NC} PINECONE_ENVIRONMENT not set"
        WARNINGS+=("Set PINECONE_ENVIRONMENT in functions/.env.local (e.g., us-east-1-aws)")
        WARNING_COUNT=$((WARNING_COUNT + 1))
    fi
    
    # Check Pinecone index
    if grep -q "^PINECONE_INDEX=" "$FUNCTIONS_ENV" && ! grep -q "REPLACE_WITH_YOUR" "$FUNCTIONS_ENV"; then
        echo "  ${GREEN}${CHECKMARK}${NC} PINECONE_INDEX configured"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    else
        echo "  ${YELLOW}${WARNING}${NC} PINECONE_INDEX not set"
        WARNINGS+=("Set PINECONE_INDEX in functions/.env.local (e.g., messageai-prod)")
        WARNING_COUNT=$((WARNING_COUNT + 1))
    fi
fi

echo ""

# ============================================================================
# 3. Validate Xcode Project Configuration
# ============================================================================

echo "${BLUE}[3/3]${NC} Validating Xcode Project..."
echo ""

XCODE_PROJECT="MessageAI/MessageAI.xcodeproj"

if [ ! -d "$XCODE_PROJECT" ]; then
    echo "  ${RED}${ERROR}${NC} Xcode project not found: ${XCODE_PROJECT}"
    ERRORS+=("Xcode project is missing. Ensure you're in the correct directory.")
    ERROR_COUNT=$((ERROR_COUNT + 1))
else
    echo "  ${GREEN}${CHECKMARK}${NC} Xcode project exists"
    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
fi

# Check if package.json exists (for npm scripts)
if [ ! -f "package.json" ]; then
    echo "  ${RED}${ERROR}${NC} package.json not found"
    ERRORS+=("package.json is missing. Ensure you're in the project root directory.")
    ERROR_COUNT=$((ERROR_COUNT + 1))
else
    echo "  ${GREEN}${CHECKMARK}${NC} package.json exists"
    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
fi

echo ""
echo "${BLUE}═══════════════════════════════════════════════════════════${NC}"

# ============================================================================
# Print Summary
# ============================================================================

if [ $ERROR_COUNT -gt 0 ]; then
    echo "${RED}                    Validation Failed                       ${NC}"
    echo "${RED}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "${RED}${ERROR_COUNT} error(s) found:${NC}"
    for error in "${ERRORS[@]}"; do
        echo "  ${RED}•${NC} $error"
    done
    echo ""
    
    if [ $WARNING_COUNT -gt 0 ]; then
        echo "${YELLOW}${WARNING_COUNT} warning(s):${NC}"
        for warning in "${WARNINGS[@]}"; do
            echo "  ${YELLOW}•${NC} $warning"
        done
        echo ""
    fi
    
    echo "${RED}Fix the errors above before running the app.${NC}"
    echo ""
    echo "${BLUE}Need help?${NC} See TROUBLESHOOTING.md or run: ${BLUE}cat TROUBLESHOOTING.md${NC}"
    echo ""
    exit 1

elif [ $WARNING_COUNT -gt 0 ]; then
    echo "${YELLOW}              Validation Passed (with warnings)             ${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "${GREEN}${SUCCESS_COUNT} checks passed ✓${NC}"
    echo ""
    echo "${YELLOW}${WARNING_COUNT} warning(s):${NC}"
    for warning in "${WARNINGS[@]}"; do
        echo "  ${YELLOW}•${NC} $warning"
    done
    echo ""
    echo "${INFO} Core messaging features will work, but AI features require additional configuration."
    echo ""
    echo "${BLUE}Next steps:${NC}"
    echo "  1. Fix warnings above (optional for AI features)"
    echo "  2. Open Xcode: ${BLUE}npm run open:xcode${NC}"
    echo "  3. Build and run (Cmd+R)"
    echo ""
    exit 0

else
    echo "${GREEN}                  Validation Passed!                        ${NC}"
    echo "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "${GREEN}${CHECKMARK} All checks passed! (${SUCCESS_COUNT}/${SUCCESS_COUNT})${NC}"
    echo ""
    echo "${BLUE}Next steps:${NC}"
    echo "  1. Open Xcode: ${BLUE}npm run open:xcode${NC}"
    echo "  2. Build and run (Cmd+R)"
    echo "  3. Start Firebase emulators (optional): ${BLUE}npm run dev${NC}"
    echo ""
    echo "${GREEN}Your environment is ready to go! 🎉${NC}"
    echo ""
    exit 0
fi

