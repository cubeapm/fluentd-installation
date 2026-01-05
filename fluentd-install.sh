#!/bin/bash

################################################################################
#                                                                              #
#         🎯 FLUENT-PACKAGE v6 LTS OFFICIAL INSTALLER SCRIPT 🎯               #
#                                                                              #
#  Automatic detection, installation, and startup of fluent-package v6 LTS    #
#  Based on official Fluentd documentation                                    #
#  Latest: v6.0.1 (Nov 2025) - Bundled Fluentd v1.19.1                        #
#  Supported: Ubuntu, Debian, CentOS/RHEL, Alpine, macOS                      #
#                                                                              #
################################################################################

set +e

# ============================================================================
#                              COLOR DEFINITIONS
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

BOLD='\033[1m'
SUCCESS='✅'
ERROR='❌'
WARNING='⚠️ '
INFO='ℹ️ '
ARROW='→'
ROCKET='🚀'
HEART='❤️ '

# ============================================================================
#                           UTILITY FUNCTIONS
# ============================================================================

print_header() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                                                                ║"
    echo "║    ${ROCKET} FLUENT-PACKAGE v6.0.1 LTS INSTALLER ${ROCKET}              ║"
    echo "║                                                                ║"
    echo "║    Latest: Fluentd v1.19.1 | Support until Dec 2027            ║"
    echo "║                                                                ║"
    echo "║           Made with ${HEART} for DevOps Engineers                ║"
    echo "║                                                                ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}\n"
}

print_success() {
    echo -e "${GREEN}${BOLD}${SUCCESS}  $1${NC}"
}

print_error() {
    echo -e "${RED}${BOLD}${ERROR}  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}${BOLD}${WARNING} $1${NC}"
}

print_info() {
    echo -e "${CYAN}${BOLD}${INFO} $1${NC}"
}

print_divider() {
    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_box() {
    local text="$1"
    local width=${#text}
    echo -e "${BLUE}┌$(printf '─%.0s' {1..$((width+2))})┐${NC}"
    echo -e "${BLUE}│${NC} ${BOLD}$text${NC} ${BLUE}│${NC}"
    echo -e "${BLUE}└$(printf '─%.0s' {1..$((width+2))})┘${NC}"
}

# ============================================================================
#                            DETECTION FUNCTIONS
# ============================================================================

detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            OS=$ID
            OS_VERSION=$VERSION_ID
            OS_NAME=$PRETTY_NAME
            VERSION_CODENAME=${VERSION_CODENAME:-unknown}
        elif [ -f /etc/lsb-release ]; then
            . /etc/lsb-release
            OS=$(echo $DISTRIB_ID | tr '[:upper:]' '[:lower:]')
            OS_VERSION=$DISTRIB_RELEASE
            OS_NAME="$DISTRIB_ID $DISTRIB_RELEASE"
            VERSION_CODENAME=$(lsb_release -cs 2>/dev/null)
        else
            OS="linux"
            OS_VERSION="unknown"
            OS_NAME="Linux (Unknown)"
            VERSION_CODENAME="unknown"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        OS_VERSION=$(sw_vers -productVersion)
        OS_NAME="macOS $(sw_vers -productVersion)"
        ARCH=$(uname -m)
        VERSION_CODENAME=""
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        OS="windows"
        OS_VERSION="unknown"
        OS_NAME="Windows"
        VERSION_CODENAME=""
    else
        OS="unknown"
        OS_VERSION="unknown"
        OS_NAME="Unknown OS"
        VERSION_CODENAME=""
    fi
}

# ============================================================================
#                          INSTALLATION FUNCTIONS
# ============================================================================

install_ubuntu_debian() {
    print_divider
    print_box "Installing fluent-package v6.0.1 LTS on Ubuntu/Debian"
    print_divider
    echo ""
    
    CODENAME=$(lsb_release -cs 2>/dev/null)
    
    if [ -z "$CODENAME" ]; then
        if [ -f /etc/os-release ]; then
            CODENAME=$(grep "VERSION_CODENAME=" /etc/os-release | cut -d= -f2)
        fi
    fi
    
    print_info "Detected: $OS $OS_VERSION ($CODENAME)"
    echo ""
    
    # Map to v6 LTS official installation scripts
    case "$CODENAME" in
        noble)
            INSTALL_SCRIPT="https://toolbelt.treasuredata.com/sh/install-ubuntu-noble-fluent-package6-lts.sh"
            print_info "Ubuntu 24.04 LTS (Noble) detected"
            ;;
        jammy)
            INSTALL_SCRIPT="https://toolbelt.treasuredata.com/sh/install-ubuntu-jammy-fluent-package6-lts.sh"
            print_info "Ubuntu 22.04 LTS (Jammy) detected"
            ;;
        focal)
            INSTALL_SCRIPT="https://toolbelt.treasuredata.com/sh/install-ubuntu-focal-fluent-package6-lts.sh"
            print_info "Ubuntu 20.04 LTS (Focal) detected"
            ;;
        bookworm)
            INSTALL_SCRIPT="https://toolbelt.treasuredata.com/sh/install-debian-bookworm-fluent-package6-lts.sh"
            print_info "Debian 12 (Bookworm) detected"
            ;;
        bullseye)
            INSTALL_SCRIPT="https://toolbelt.treasuredata.com/sh/install-debian-bullseye-fluent-package6-lts.sh"
            print_info "Debian 11 (Bullseye) detected"
            ;;
        *)
            print_error "Unsupported version: $CODENAME"
            print_info "Supported versions:"
            echo "  • Ubuntu: Noble (24.04), Jammy (22.04), Focal (20.04)"
            echo "  • Debian: Bookworm (12), Bullseye (11)"
            return 1
            ;;
    esac
    
    echo ""
    print_info "Step 1/3: Downloading official installation script for v6.0.1 LTS..."
    print_info "URL: $INSTALL_SCRIPT"
    echo ""
    
    if curl -fsSL "$INSTALL_SCRIPT" | sh; then
        print_success "fluent-package v6.0.1 LTS installed successfully"
    else
        print_error "Failed to install fluent-package v6.0.1"
        return 1
    fi
    
    echo ""
}

install_centos_rhel() {
    print_divider
    print_box "Installing fluent-package v6.0.1 LTS on CentOS/RHEL"
    print_divider
    echo ""
    
    MAJOR_VERSION=$(echo $OS_VERSION | cut -d. -f1)
    
    print_info "Detected: $OS $MAJOR_VERSION"
    echo ""
    
    # Map to v6 LTS official installation scripts
    case "$MAJOR_VERSION" in
        9)
            INSTALL_SCRIPT="https://toolbelt.treasuredata.com/sh/install-redhat9-fluent-package6-lts.sh"
            print_info "RHEL 9 / CentOS Stream 9 detected"
            ;;
        8)
            INSTALL_SCRIPT="https://toolbelt.treasuredata.com/sh/install-redhat8-fluent-package6-lts.sh"
            print_info "RHEL 8 / CentOS Stream 8 detected"
            ;;
        *)
            print_error "Unsupported RHEL/CentOS version: $MAJOR_VERSION"
            print_info "Supported versions: 8, 9 (RHEL 7 EOL - migrate to v8/v9)"
            return 1
            ;;
    esac
    
    echo ""
    print_info "Step 1/3: Downloading official installation script for v6.0.1 LTS..."
    print_info "URL: $INSTALL_SCRIPT"
    echo ""
    
    if curl -fsSL "$INSTALL_SCRIPT" | sh; then
        print_success "fluent-package v6.0.1 LTS installed successfully"
    else
        print_error "Failed to install fluent-package v6.0.1"
        return 1
    fi
    
    echo ""
}

install_unsupported() {
    print_divider
    print_box "Manual Installation Required"
    print_divider
    echo ""
    
    print_error "$1 requires manual installation"
    echo ""
    echo -e "${CYAN}${BOLD}Download v6.0.1 LTS packages:${NC}"
    echo "  https://www.fluentd.org/download/fluent_package"
    echo ""
    echo -e "${CYAN}${BOLD}Or check release notes:${NC}"
    echo "  https://github.com/fluent/fluent-package-builder/releases"
    echo ""
    return 1
}

# ============================================================================
#                           SERVICE MANAGEMENT
# ============================================================================

start_service() {
    print_divider
    print_box "Starting fluent-package Service"
    print_divider
    echo ""
    
    if command -v systemctl &> /dev/null; then
        print_info "Step 2/3: Starting fluentd service..."
        echo ""
        
        if sudo systemctl start fluentd.service 2>/dev/null; then
            print_success "fluentd service started"
        else
            print_warning "Could not start fluentd service"
            return 1
        fi
        
        if sudo systemctl enable fluentd.service 2>/dev/null; then
            print_success "fluentd enabled on boot"
        fi
        
        sleep 2
        
    elif command -v service &> /dev/null; then
        print_info "Step 2/3: Starting fluentd service..."
        sudo service fluentd start 2>/dev/null
        print_success "fluentd service started"
    else
        print_error "Could not determine service manager"
        return 1
    fi
    
    echo ""
}

# ============================================================================
#                           STATUS & VERIFICATION
# ============================================================================

check_status() {
    print_divider
    print_box "Service Status & Version"
    print_divider
    echo ""
    
    print_info "Step 3/3: Checking service status..."
    echo ""
    
    if command -v systemctl &> /dev/null; then
        if sudo systemctl is-active --quiet fluentd.service 2>/dev/null; then
            print_success "fluentd service is RUNNING ✓"
            echo ""
            echo -e "${CYAN}${BOLD}Service Details:${NC}"
            sudo systemctl status fluentd.service --no-pager 2>/dev/null | grep -E "Loaded|Active|Main PID" | sed 's/^/  /'
        else
            print_error "fluentd service is NOT RUNNING"
            echo ""
            print_info "Check manually:"
            echo "  sudo systemctl status fluentd.service"
            return 1
        fi
    fi
    
    echo ""
    print_info "Checking listening ports..."
    echo ""
    
    if ss -tulpn 2>/dev/null | grep -q 24224 || netstat -tulpn 2>/dev/null | grep -q 24224; then
        print_success "fluentd listening on port 24224"
    else
        print_warning "Port 24224 not yet listening (may still be starting)"
    fi
    
    echo ""
    print_info "Checking version..."
    echo ""
    
    if command -v fluentd &> /dev/null; then
        echo -e "${CYAN}Version:${NC}"
        fluentd --version 2>/dev/null | sed 's/^/  /'
    else
        print_warning "fluentd command not found"
    fi
    
    echo ""
}

# ============================================================================
#                        CONFIGURATION INFO
# ============================================================================

show_config_info() {
    print_divider
    print_box "Configuration & Version Info"
    print_divider
    echo ""
    
    echo -e "${CYAN}${BOLD}Installed Version:${NC}"
    echo "  fluent-package v6.0.1 LTS (Released: Nov 11, 2025)"
    echo "  Bundled Fluentd v1.19.1"
    echo "  Support until: Dec 2027"
    echo ""
    
    echo -e "${CYAN}${BOLD}Configuration Files:${NC}"
    echo "  /etc/fluent/fluentd.conf"
    echo "  /etc/fluent/config.d/"
    echo ""
    
    echo -e "${CYAN}${BOLD}Log File:${NC}"
    echo "  /var/log/fluent/fluentd.log"
    echo ""
    
    echo -e "${CYAN}${BOLD}Binary Path:${NC}"
    echo "  /opt/fluent/bin/fluentd"
    echo ""
    
    echo -e "${CYAN}${BOLD}Useful Commands:${NC}"
    echo "  View logs:        sudo tail -f /var/log/fluent/fluentd.log"
    echo "  Restart service:  sudo systemctl restart fluentd.service"
    echo "  Stop service:     sudo systemctl stop fluentd.service"
    echo "  Edit config:      sudo nano /etc/fluent/fluentd.conf"
    echo "  Check config:     sudo /opt/fluent/bin/fluentd -c /etc/fluent/fluentd.conf --dry-run"
    echo "  Service status:   sudo systemctl status fluentd.service"
    echo ""
}

# ============================================================================
#                              MAIN LOGIC
# ============================================================================

check_privileges() {
    if [[ $EUID -ne 0 ]]; then
        print_header
        print_error "This script requires elevated privileges (sudo)"
        echo ""
        print_info "Run: ${BOLD}sudo $0${NC}"
        echo ""
        exit 1
    fi
}

main() {
    print_header
    
    print_info "Detecting OS and version..."
    sleep 1
    detect_os
    
    echo ""
    print_success "Detected: ${BOLD}${OS_NAME}${NC}"
    print_info "Architecture: ${ARCH:-x86_64}"
    sleep 2
    echo ""
    
    case "$OS" in
        ubuntu|debian)
            install_ubuntu_debian
            if [ $? -eq 0 ]; then
                start_service
                check_status
            fi
            ;;
        centos|rhel|fedora)
            install_centos_rhel
            if [ $? -eq 0 ]; then
                start_service
                check_status
            fi
            ;;
        alpine)
            install_unsupported "Alpine Linux"
            ;;
        macos)
            install_unsupported "macOS"
            ;;
        windows)
            install_unsupported "Windows"
            ;;
        *)
            print_error "Unsupported OS: $OS"
            echo ""
            echo -e "${CYAN}Supported:${NC}"
            echo "  • Ubuntu (24.04, 22.04, 20.04)"
            echo "  • Debian (12, 11)"
            echo "  • CentOS / RHEL (8, 9)"
            exit 1
            ;;
    esac
    
    show_config_info
    
    echo ""
    print_divider
    echo -e "${GREEN}${BOLD}${ROCKET} INSTALLATION COMPLETED! ${ROCKET}${NC}"
    print_divider
    echo ""
    echo -e "${MAGENTA}${BOLD}Next Steps:${NC}"
    echo ""
    echo "  1️⃣  Review configuration:"
    echo "     sudo nano /etc/fluent/fluentd.conf"
    echo ""
    echo "  2️⃣  Validate configuration:"
    echo "     sudo /opt/fluent/bin/fluentd -c /etc/fluent/fluentd.conf --dry-run"
    echo ""
    echo "  3️⃣  Restart service:"
    echo "     sudo systemctl restart fluentd.service"
    echo ""
    echo "  4️⃣  Monitor logs:"
    echo "     sudo tail -f /var/log/fluent/fluentd.log"
    echo ""
    echo "  5️⃣  Documentation:"
    echo "     https://docs.fluentd.org/"
    echo ""
    print_divider
    echo ""
}

# ============================================================================
#                            SCRIPT EXECUTION
# ============================================================================

check_privileges
main

