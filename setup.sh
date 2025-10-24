#!/bin/bash
# MessageAI Setup Script
# One-command setup for new developers
# Usage: npm run setup or ./setup.sh

set -e  # Exit on error

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

# Version requirements
MIN_NODE_VERSION="18.0.0"
MIN_XCODE_VERSION="15.0"
MIN_MACOS_VERSION="12.0"

echo ""
echo "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo "${BLUE}           MessageAI Development Environment Setup          ${NC}"
echo "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Function to compare versions
version_compare() {
    if [[ $1 == $2 ]]; then
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++)); do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++)); do
        if [[ -z ${ver2[i]} ]]; then
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]})); then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]})); then
            return 2
        fi
    done
    return 0
}

# Function to check command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Track errors and warnings
HAS_ERRORS=false
HAS_WARNINGS=false
ERROR_MESSAGES=()
WARNING_MESSAGES=()

echo "${BLUE}[1/5]${NC} Checking system requirements..."
echo ""

# Check macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "  ${RED}${ERROR}${NC} macOS required for iOS development"
    HAS_ERRORS=true
    ERROR_MESSAGES+=("macOS is required. This project cannot be built on Windows or Linux.")
else
    MACOS_VERSION=$(sw_vers -productVersion)
    echo "  ${GREEN}${CHECKMARK}${NC} macOS ${MACOS_VERSION}"
    
    # Check minimum macOS version
    version_compare $MACOS_VERSION $MIN_MACOS_VERSION
    result=$?
    if [ $result -eq 2 ]; then
        echo "  ${YELLOW}${WARNING}${NC} macOS ${MIN_MACOS_VERSION}+ recommended (you have ${MACOS_VERSION})"
        HAS_WARNINGS=true
        WARNING_MESSAGES+=("Your macOS version is older than recommended. Some features may not work.")
    fi
fi

# Detect architecture
ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]]; then
    echo "  ${GREEN}${CHECKMARK}${NC} Apple Silicon (M1/M2/M3)"
elif [[ "$ARCH" == "x86_64" ]]; then
    echo "  ${GREEN}${CHECKMARK}${NC} Intel (x86_64)"
else
    echo "  ${YELLOW}${WARNING}${NC} Unknown architecture: ${ARCH}"
fi

# Check Xcode
if command_exists xcodebuild; then
    XCODE_VERSION=$(xcodebuild -version | grep "Xcode" | awk '{print $2}')
    echo "  ${GREEN}${CHECKMARK}${NC} Xcode ${XCODE_VERSION}"
    
    # Check minimum Xcode version
    version_compare $XCODE_VERSION $MIN_XCODE_VERSION
    result=$?
    if [ $result -eq 2 ]; then
        echo "  ${YELLOW}${WARNING}${NC} Xcode ${MIN_XCODE_VERSION}+ required (you have ${XCODE_VERSION})"
        HAS_WARNINGS=true
        WARNING_MESSAGES+=("Your Xcode version is older than required. Please update from the App Store.")
    fi
elif command_exists xcode-select && xcode-select -p &>/dev/null; then
    echo "  ${YELLOW}${WARNING}${NC} Xcode Command Line Tools found, but full Xcode recommended"
    HAS_WARNINGS=true
    WARNING_MESSAGES+=("Install full Xcode from the App Store for iOS development")
else
    echo "  ${RED}${ERROR}${NC} Xcode not found"
    HAS_ERRORS=true
    ERROR_MESSAGES+=("Install Xcode from the App Store: https://apps.apple.com/app/xcode/id497799835")
fi

# Check Node.js
if command_exists node; then
    NODE_VERSION=$(node -v | sed 's/v//')
    echo "  ${GREEN}${CHECKMARK}${NC} Node.js ${NODE_VERSION}"
    
    # Check minimum Node version
    version_compare $NODE_VERSION $MIN_NODE_VERSION
    result=$?
    if [ $result -eq 2 ]; then
        echo "  ${RED}${ERROR}${NC} Node.js ${MIN_NODE_VERSION}+ required (you have ${NODE_VERSION})"
        HAS_ERRORS=true
        ERROR_MESSAGES+=("Update Node.js: https://nodejs.org/ or use nvm: https://github.com/nvm-sh/nvm")
    fi
else
    echo "  ${RED}${ERROR}${NC} Node.js not found"
    HAS_ERRORS=true
    ERROR_MESSAGES+=("Install Node.js ${MIN_NODE_VERSION}+: https://nodejs.org/")
fi

# Check npm
if command_exists npm; then
    NPM_VERSION=$(npm -v)
    echo "  ${GREEN}${CHECKMARK}${NC} npm ${NPM_VERSION}"
else
    echo "  ${RED}${ERROR}${NC} npm not found (should be installed with Node.js)"
    HAS_ERRORS=true
fi

# Check Git
if command_exists git; then
    GIT_VERSION=$(git --version | awk '{print $3}')
    echo "  ${GREEN}${CHECKMARK}${NC} Git ${GIT_VERSION}"
else
    echo "  ${YELLOW}${WARNING}${NC} Git not found (install with: xcode-select --install)"
    HAS_WARNINGS=true
    WARNING_MESSAGES+=("Git is required for version control")
fi

echo ""

# If critical errors, stop here
if [ "$HAS_ERRORS" = true ]; then
    echo "${RED}═══════════════════════════════════════════════════════════${NC}"
    echo "${RED}                    Setup Failed                            ${NC}"
    echo "${RED}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "${RED}Critical errors found:${NC}"
    for error in "${ERROR_MESSAGES[@]}"; do
        echo "  ${RED}•${NC} $error"
    done
    echo ""
    echo "Please fix the errors above and run setup again."
    echo ""
    exit 1
fi

echo "${BLUE}[2/5]${NC} Installing dependencies..."
echo ""

# Install root dependencies
echo "  ${INFO} Installing root npm packages..."
if npm install --silent; then
    echo "  ${GREEN}${CHECKMARK}${NC} Root dependencies installed"
else
    echo "  ${RED}${ERROR}${NC} Failed to install root dependencies"
    exit 1
fi

# Install Cloud Functions dependencies
echo "  ${INFO} Installing Cloud Functions packages..."
cd functions
if npm install --silent; then
    echo "  ${GREEN}${CHECKMARK}${NC} Cloud Functions dependencies installed"
else
    echo "  ${RED}${ERROR}${NC} Failed to install Cloud Functions dependencies"
    cd ..
    exit 1
fi
cd ..

# Check for Firebase CLI
if command_exists firebase; then
    FIREBASE_VERSION=$(firebase --version)
    echo "  ${GREEN}${CHECKMARK}${NC} Firebase CLI ${FIREBASE_VERSION} already installed"
else
    echo "  ${INFO} Installing Firebase CLI globally..."
    if npm install -g firebase-tools --silent; then
        echo "  ${GREEN}${CHECKMARK}${NC} Firebase CLI installed"
    else
        echo "  ${YELLOW}${WARNING}${NC} Failed to install Firebase CLI globally (try: sudo npm install -g firebase-tools)"
        HAS_WARNINGS=true
        WARNING_MESSAGES+=("Firebase CLI is needed for local development. Install manually: npm install -g firebase-tools")
    fi
fi

echo ""
echo "${BLUE}[3/5]${NC} Checking configuration files..."
echo ""

# Check GoogleService-Info.plist
GOOGLE_SERVICE_INFO="MessageAI/MessageAI/GoogleService-Info.plist"
GOOGLE_SERVICE_TEMPLATE="MessageAI/MessageAI/GoogleService-Info.template.plist"

if [ -f "$GOOGLE_SERVICE_INFO" ]; then
    # Check if it's still using placeholder values
    if grep -q "REPLACE_WITH_YOUR" "$GOOGLE_SERVICE_INFO"; then
        echo "  ${YELLOW}${WARNING}${NC} GoogleService-Info.plist has placeholder values"
        HAS_WARNINGS=true
        WARNING_MESSAGES+=("Replace placeholders in GoogleService-Info.plist with your Firebase credentials")
    else
        echo "  ${GREEN}${CHECKMARK}${NC} GoogleService-Info.plist configured"
    fi
else
    echo "  ${YELLOW}${WARNING}${NC} GoogleService-Info.plist not found"
    echo "      ${INFO} Copy template: cp ${GOOGLE_SERVICE_TEMPLATE} ${GOOGLE_SERVICE_INFO}"
    echo "      ${INFO} Then replace placeholders with your Firebase credentials"
    HAS_WARNINGS=true
    WARNING_MESSAGES+=("Create GoogleService-Info.plist from template and add your Firebase credentials")
fi

# Check functions/.env.local (optional for AI features)
FUNCTIONS_ENV="functions/.env.local"
FUNCTIONS_ENV_TEMPLATE="functions/.env.template"

if [ -f "$FUNCTIONS_ENV" ]; then
    if grep -q "REPLACE_WITH_YOUR" "$FUNCTIONS_ENV"; then
        echo "  ${YELLOW}${WARNING}${NC} functions/.env.local has placeholder values"
        HAS_WARNINGS=true
        WARNING_MESSAGES+=("Replace placeholders in functions/.env.local with your API keys (optional for AI features)")
    else
        echo "  ${GREEN}${CHECKMARK}${NC} functions/.env.local configured (AI features ready)"
    fi
else
    echo "  ${INFO} functions/.env.local not found (optional for AI features)"
    echo "      ${INFO} Copy template if you want AI features: cp ${FUNCTIONS_ENV_TEMPLATE} ${FUNCTIONS_ENV}"
fi

echo ""
echo "${BLUE}[4/5]${NC} Checking Xcode project..."
echo ""

# Check if Xcode project exists
XCODE_PROJECT="MessageAI/MessageAI.xcodeproj"
if [ -d "$XCODE_PROJECT" ]; then
    echo "  ${GREEN}${CHECKMARK}${NC} Xcode project found"
else
    echo "  ${RED}${ERROR}${NC} Xcode project not found at ${XCODE_PROJECT}"
    exit 1
fi

echo ""
echo "${BLUE}[5/5]${NC} Setup summary..."
echo ""

# Print summary
if [ "$HAS_WARNINGS" = true ]; then
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo "${YELLOW}              Setup Complete (with warnings)                ${NC}"
    echo "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "${YELLOW}Warnings (${#WARNING_MESSAGES[@]}):${NC}"
    for warning in "${WARNING_MESSAGES[@]}"; do
        echo "  ${YELLOW}•${NC} $warning"
    done
    echo ""
else
    echo "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo "${GREEN}                  Setup Complete!                           ${NC}"
    echo "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
fi

# Next steps
echo "${BLUE}Next Steps:${NC}"
echo ""

if [ "$HAS_WARNINGS" = true ]; then
    echo "  1. ${YELLOW}Fix warnings above${NC}"
    echo "  2. Validate configuration: ${BLUE}npm run validate:config${NC}"
    echo "  3. Open Xcode: ${BLUE}npm run open:xcode${NC}"
    echo "  4. Build and run (Cmd+R) in Xcode"
else
    echo "  1. Validate configuration: ${BLUE}npm run validate:config${NC}"
    echo "  2. Open Xcode: ${BLUE}npm run open:xcode${NC}"
    echo "  3. Build and run (Cmd+R) in Xcode"
fi

echo ""
echo "${BLUE}Optional:${NC}"
echo "  • Start Firebase emulators: ${BLUE}npm run dev${NC}"
echo "  • Run tests: ${BLUE}npm run test:all${NC}"
echo "  • View troubleshooting: ${BLUE}cat TROUBLESHOOTING.md${NC}"
echo ""

if [ "$HAS_WARNINGS" = true ]; then
    exit 0  # Exit with success but warnings
else
    echo "${GREEN}${CHECKMARK} Setup successful! Happy coding!${NC}"
    echo ""
    exit 0
fi

