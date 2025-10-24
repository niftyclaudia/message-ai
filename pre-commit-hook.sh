#!/bin/bash
#
# Pre-commit hook to prevent committing sensitive files
# This prevents accidental commits of API keys, secrets, and Firebase config
#
# INSTALLATION:
# cp pre-commit-hook.sh .git/hooks/pre-commit
# chmod +x .git/hooks/pre-commit
#

# ANSI color codes
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Files that should never be committed
FORBIDDEN_FILES=(
    "GoogleService-Info\.plist$"
    "\.p8$"
    "\.pem$"
    "AuthKey_.*\.p8$"
    "APNs.*\.p8$"
    "firebase-adminsdk-.*\.json$"
    "service-account-key\.json$"
    "\.env$"
    "\.env\.local$"
    "\.env\.production$"
)

# Check if any forbidden files are staged
FOUND_FORBIDDEN=false

for pattern in "${FORBIDDEN_FILES[@]}"; do
    # Find files matching the pattern in the staging area
    # Exclude .template files as they are safe to commit
    files=$(git diff --cached --name-only --diff-filter=ACM | grep -v "\.template" | grep -E "$pattern" || true)
    
    if [ -n "$files" ]; then
        if [ "$FOUND_FORBIDDEN" = false ]; then
            echo ""
            echo -e "${RED}⚠️  COMMIT BLOCKED: Sensitive files detected!${NC}"
            echo ""
            echo "The following files contain secrets and should NOT be committed:"
            echo ""
            FOUND_FORBIDDEN=true
        fi
        
        echo -e "${YELLOW}  - $files${NC}"
    fi
done

# Check file contents for common secret patterns
SECRET_PATTERNS=(
    "API_KEY.*=.*[A-Za-z0-9]{20,}"
    "SECRET.*=.*[A-Za-z0-9]{20,}"
    "PASSWORD.*=.*[A-Za-z0-9]{8,}"
    "PRIVATE_KEY.*=.*[A-Za-z0-9]{20,}"
)

# Only check Swift, TypeScript, JavaScript, and config files
CONTENT_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(swift|ts|js|json|yaml|yml|sh)$' || true)

if [ -n "$CONTENT_FILES" ]; then
    for pattern in "${SECRET_PATTERNS[@]}"; do
        matches=$(git diff --cached $CONTENT_FILES | grep -E "$pattern" || true)
        
        if [ -n "$matches" ]; then
            if [ "$FOUND_FORBIDDEN" = false ]; then
                echo ""
                echo -e "${RED}⚠️  COMMIT BLOCKED: Potential secrets detected in file contents!${NC}"
                echo ""
                FOUND_FORBIDDEN=true
            fi
            
            echo -e "${YELLOW}Suspicious pattern found: $pattern${NC}"
        fi
    done
fi

if [ "$FOUND_FORBIDDEN" = true ]; then
    echo ""
    echo -e "${YELLOW}How to fix:${NC}"
    echo "  1. Remove the sensitive files from staging:"
    echo "     git reset HEAD <filename>"
    echo ""
    echo "  2. Use the template file instead:"
    echo "     Copy GoogleService-Info.template.plist → GoogleService-Info.plist"
    echo "     Add your real credentials to GoogleService-Info.plist (it's in .gitignore)"
    echo ""
    echo "  3. If you really need to commit (rare), use:"
    echo "     git commit --no-verify"
    echo ""
    exit 1
fi

# All checks passed
exit 0

