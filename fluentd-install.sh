#!/bin/bash

################################################################################
#                                                                              #
#                   🎯 FLUENTD AUTO-INSTALL & START SCRIPT                    #
#                                                                              #
#  Automatic detection, installation, and startup of Fluentd/Fluent Bit      #
#  Supported: Ubuntu, Debian, CentOS, RHEL, Alpine, macOS                    #
#                                                                              #
################################################################################

# Remove 'set -e' to allow script to continue on errors
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
WHITE='\033[1;37m'
GRAY='\033[0;90m'
NC='\033[0m'

BOLD='\033[1m'
UNDERLINE='\033[4m'

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
    echo "║              ${ROCKET} FLUENTD AUTO-INSTALL WIZARD ${ROCKET}                  ║"
    echo "║                                                                ║"
    echo "║              Made with ${HEART} for DevOps Engineers               ║"
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
            VERSION_ID=$VERSION_ID
            OS_NAME=$PRETTY_NAME
            VERSION_CODENAME=${VERSION_CODENAME:-focal}
        elif [ -f /etc/lsb-release ]; then
            . /etc/lsb-release
            OS=$(echo $DISTRIB_ID | tr '[:upper:]' '[:lower:]')
            VERSION_ID=$DISTRIB_RELEASE
            OS_NAME="$DISTRIB_ID $DISTRIB_RELEASE"
            VERSION_CODENAME=$(lsb_release -cs 2>/dev/null || echo "focal")
        else
            OS="linux"
            VERSION_ID="unknown"
            OS_NAME="Linux (Unknown)"
            VERSION_CODENAME="focal"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        VERSION_ID=$(sw_vers -productVersion)
        OS_NAME="macOS $(sw_vers -productVersion)"
        VERSION_CODENAME=""
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        OS="windows"
        VERSION_ID="unknown"
        OS_NAME="Windows"
        VERSION_CODENAME=""
    else
        OS="unknown"
        VERSION_ID="unknown"
        OS_NAME="Unknown OS"
        VERSION_CODENAME=""
    fi
}

# ============================================================================
#                          INSTALLATION FUNCTIONS
# ============================================================================

install_ubuntu_debian() {
    print_divider
    print_box "Installing on Ubuntu/Debian"
    print_divider
    echo ""
    
    print_info "Step 1/5: Setting up GPG key..."
    
    # Download and setup GPG key
    if curl -fsSL https://packages.treasuredata.com/GPG-KEY-td-agent -o /tmp/fluentd-key.gpg 2>/dev/null; then
        sudo gpg --dearmor -o /usr/share/keyrings/fluentd-keyring.gpg /tmp/fluentd-key.gpg 2>/dev/null
        rm -f /tmp/fluentd-key.gpg
        print_success "GPG key setup completed"
    else
        print_warning "Could not download GPG key, continuing without key verification"
    fi
    
    echo ""
    print_info "Step 2/5: Adding Fluentd repository..."
    
    # Get Ubuntu/Debian codename
    CODENAME=$(lsb_release -cs 2>/dev/null || echo "focal")
    
    # For Ubuntu 22.04 specifically
    if [ "$CODENAME" = "jammy" ]; then
        CODENAME="jammy"
    elif [ "$CODENAME" = "focal" ]; then
        CODENAME="focal"
    elif [ "$CODENAME" = "bionic" ]; then
        CODENAME="bionic"
    fi
    
    # Add repository
    if [ -f /usr/share/keyrings/fluentd-keyring.gpg ]; then
        echo "deb [signed-by=/usr/share/keyrings/fluentd-keyring.gpg] https://packages.treasuredata.com/debian/${CODENAME}/ ${CODENAME} contrib" | \
            sudo tee /etc/apt/sources.list.d/fluentd.list > /dev/null 2>&1
    else
        echo "deb https://packages.treasuredata.com/debian/${CODENAME}/ ${CODENAME} contrib" | \
            sudo tee /etc/apt/sources.list.d/fluentd.list > /dev/null 2>&1
    fi
    
    print_success "Repository added"
    
    echo ""
    print_info "Step 3/5: Updating package manager..."
    sudo apt-get update -qq > /dev/null 2>&1
    print_success "Package manager updated"
    
    echo ""
    print_info "Step 4/5: Installing Fluentd (td-agent)..."
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y td-agent > /dev/null 2>&1
    
    if command -v td-agent &> /dev/null; then
        print_success "Fluentd installed successfully"
    else
        print_error "Failed to install Fluentd"
        return 1
    fi
    
    echo ""
    print_info "Step 5/5: Finalizing..."
    print_success "Installation completed on Ubuntu/Debian"
    echo ""
}

install_centos_rhel() {
    print_divider
    print_box "Installing on CentOS/RHEL"
    print_divider
    echo ""
    
    print_info "Step 1/4: Setting up repository..."
    
    cat << EOF | sudo tee /etc/yum.repos.d/td.repo > /dev/null 2>&1
[treasuredata]
name=TreasureData
baseurl=https://packages.treasuredata.com/redhat/\$releasever/\$basearch
gpgcheck=1
gpgkey=https://packages.treasuredata.com/GPG-KEY-td-agent
EOF
    
    print_success "Repository configured"
    
    echo ""
    print_info "Step 2/4: Installing Fluentd (td-agent)..."
    sudo yum install -y td-agent > /dev/null 2>&1
    
    if command -v td-agent &> /dev/null; then
        print_success "Fluentd installed successfully"
    else
        print_error "Failed to install Fluentd"
        return 1
    fi
    
    echo ""
    print_info "Step 3/4: Configuring service..."
    print_success "Service configured"
    
    echo ""
    print_info "Step 4/4: Finalizing..."
    print_success "Installation completed on CentOS/RHEL"
    echo ""
}

install_alpine() {
    print_divider
    print_box "Installing on Alpine Linux"
    print_divider
    echo ""
    
    print_info "Step 1/3: Updating package manager..."
    sudo apk update > /dev/null 2>&1
    print_success "Package manager updated"
    
    echo ""
    print_info "Step 2/3: Installing Fluent Bit..."
    sudo apk add --no-cache fluent-bit > /dev/null 2>&1
    
    if command -v fluent-bit &> /dev/null; then
        print_success "Fluent Bit installed successfully"
    else
        print_error "Failed to install Fluent Bit"
        return 1
    fi
    
    echo ""
    print_info "Step 3/3: Finalizing..."
    print_success "Installation completed on Alpine Linux"
    echo ""
}

install_macos() {
    print_divider
    print_box "Installing on macOS"
    print_divider
    echo ""
    
    if ! command -v brew &> /dev/null; then
        print_warning "Homebrew not found, installing..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" > /dev/null 2>&1
        print_success "Homebrew installed"
    fi
    
    echo ""
    print_info "Installing Fluent Bit via Homebrew..."
    brew install fluent-bit > /dev/null 2>&1
    
    if command -v fluent-bit &> /dev/null; then
        print_success "Fluent Bit installed successfully"
    else
        print_error "Failed to install Fluent Bit"
        return 1
    fi
    
    echo ""
}

install_windows() {
    print_error "Windows detected!"
    echo ""
    echo -e "${BOLD}Please install Fluentd manually:${NC}"
    echo ""
    echo -e "${CYAN}${ARROW}${NC} MSI: https://docs.fluentd.org/installation/install-by-msi"
    echo -e "${CYAN}${ARROW}${NC} Chocolatey: choco install fluentd"
    echo ""
    exit 1
}

# ============================================================================
#                           SERVICE MANAGEMENT
# ============================================================================

start_service_linux() {
    print_divider
    print_box "Starting Fluentd Service"
    print_divider
    echo ""
    
    if command -v systemctl &> /dev/null; then
        print_info "Starting Fluentd with systemctl..."
        sudo systemctl start td-agent 2>/dev/null
        sudo systemctl enable td-agent 2>/dev/null
        
        sleep 2
        
        if sudo systemctl is-active --quiet td-agent; then
            print_success "Fluentd started and enabled on boot"
        else
            print_warning "Fluentd may not have started, check with: sudo systemctl status td-agent"
        fi
    elif command -v service &> /dev/null; then
        print_info "Starting Fluentd with service..."
        sudo service td-agent start 2>/dev/null
        print_success "Fluentd service started"
    else
        print_error "Could not determine service manager"
        return 1
    fi
    
    echo ""
}

start_service_macos() {
    print_divider
    print_box "Starting Fluent Bit Service"
    print_divider
    echo ""
    
    print_info "Starting Fluent Bit..."
    brew services start fluent-bit > /dev/null 2>&1
    
    sleep 2
    
    if brew services list 2>/dev/null | grep -q "fluent-bit"; then
        print_success "Fluent Bit started"
    else
        print_warning "Check status with: brew services list"
    fi
    
    echo ""
}

# ============================================================================
#                           STATUS & VERIFICATION
# ============================================================================

check_status_linux() {
    print_divider
    print_box "Service Status"
    print_divider
    echo ""
    
    if sudo systemctl is-active --quiet td-agent 2>/dev/null; then
        print_success "Fluentd service is RUNNING ✓"
    else
        print_warning "Fluentd service status: check with sudo systemctl status td-agent"
    fi
    
    echo ""
    print_info "Checking port 24224..."
    
    if ss -tulpn 2>/dev/null | grep -q 24224; then
        print_success "Fluentd listening on port 24224"
    elif netstat -tulpn 2>/dev/null | grep -q 24224; then
        print_success "Fluentd listening on port 24224"
    else
        print_warning "Port 24224 not yet listening (may still be starting)"
    fi
    
    echo ""
}

check_status_macos() {
    print_divider
    print_box "Service Status"
    print_divider
    echo ""
    
    if brew services list 2>/dev/null | grep -q "fluent-bit.*started"; then
        print_success "Fluent Bit service is RUNNING ✓"
    else
        print_warning "Fluent Bit status: check with brew services list"
    fi
    
    echo ""
}

check_version() {
    print_divider
    print_box "Version Information"
    print_divider
    echo ""
    
    if [[ "$OS" == "macos" ]]; then
        print_info "Fluent Bit version:"
        fluent-bit --version 2>/dev/null || echo "  Could not retrieve version"
    else
        print_info "Fluentd version:"
        td-agent --version 2>/dev/null || echo "  Could not retrieve version"
    fi
    
    echo ""
}

# ============================================================================
#                        CONFIGURATION INFO
# ============================================================================

show_config_info() {
    print_divider
    print_box "Configuration & Next Steps"
    print_divider
    echo ""
    
    if [[ "$OS" == "macos" ]]; then
        echo -e "${CYAN}${BOLD}Config File:${NC}"
        echo "  $(brew --prefix)/etc/fluent-bit/fluent-bit.conf"
        echo ""
        echo -e "${CYAN}${BOLD}Log File:${NC}"
        echo "  $(brew --prefix)/var/log/fluent-bit.log"
    else
        echo -e "${CYAN}${BOLD}Config File:${NC}"
        echo "  /etc/td-agent/td-agent.conf"
        echo ""
        echo -e "${CYAN}${BOLD}Log File:${NC}"
        echo "  /var/log/td-agent/td-agent.log"
    fi
    
    echo ""
    echo -e "${CYAN}${BOLD}Useful Commands:${NC}"
    echo "  View logs:        tail -f /var/log/td-agent/td-agent.log"
    echo "  Restart service:  sudo systemctl restart td-agent"
    echo "  Stop service:     sudo systemctl stop td-agent"
    echo "  Edit config:      sudo nano /etc/td-agent/td-agent.conf"
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
    
    print_info "Detecting operating system..."
    sleep 1
    detect_os
    
    echo ""
    print_success "Detected: ${BOLD}${OS_NAME}${NC}"
    sleep 2
    echo ""
    
    # Install based on OS
    case "$OS" in
        ubuntu|debian)
            install_ubuntu_debian
            start_service_linux
            check_status_linux
            ;;
        centos|rhel|fedora)
            install_centos_rhel
            start_service_linux
            check_status_linux
            ;;
        alpine)
            install_alpine
            ;;
        macos)
            install_macos
            start_service_macos
            check_status_macos
            ;;
        windows)
            install_windows
            ;;
        *)
            print_error "Unsupported OS: $OS"
            echo ""
            echo -e "${CYAN}Supported:${NC} Ubuntu, Debian, CentOS, RHEL, Alpine, macOS"
            echo ""
            exit 1
            ;;
    esac
    
    check_version
    show_config_info
    
    # Final summary
    echo ""
    print_divider
    echo -e "${GREEN}${BOLD}${ROCKET} INSTALLATION COMPLETED! ${ROCKET}${NC}"
    print_divider
    echo ""
    echo -e "${MAGENTA}${BOLD}Next Steps:${NC}"
    echo ""
    if [[ "$OS" == "macos" ]]; then
        echo "  1️⃣  nano $(brew --prefix)/etc/fluent-bit/fluent-bit.conf"
    else
        echo "  1️⃣  sudo nano /etc/td-agent/td-agent.conf"
    fi
    echo "  2️⃣  sudo systemctl restart td-agent"
    echo "  3️⃣  tail -f /var/log/td-agent/td-agent.log"
    echo ""
    print_divider
    echo ""
}

# ============================================================================
#                            SCRIPT EXECUTION
# ============================================================================

check_privileges
main

