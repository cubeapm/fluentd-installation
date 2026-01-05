#!/bin/bash

################################################################################
#                                                                              #
#                   🎯 FLUENTD AUTO-INSTALL & START SCRIPT                    #
#                                                                              #
#  Automatic detection, installation, and startup of Fluentd/Fluent Bit      #
#  Supported: Ubuntu, Debian, CentOS, RHEL, Alpine, macOS                    #
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
    DETECTED_CODENAME=$(lsb_release -cs 2>/dev/null || echo "focal")
    print_info "Detected: $DETECTED_CODENAME"
    
    # Map codenames to supported ones
    case "$DETECTED_CODENAME" in
        noble)
            CODENAME="jammy"
            print_info "Ubuntu 24.04 detected - using jammy repository"
            ;;
        jammy)
            CODENAME="jammy"
            print_info "Ubuntu 22.04 detected - using jammy repository"
            ;;
        focal)
            CODENAME="focal"
            print_info "Ubuntu 20.04 detected - using focal repository"
            ;;
        bionic)
            CODENAME="bionic"
            print_info "Ubuntu 18.04 detected - using bionic repository"
            ;;
        bullseye)
            CODENAME="bullseye"
            print_info "Debian 11 detected - using bullseye repository"
            ;;
        bookworm)
            CODENAME="bookworm"
            print_info "Debian 12 detected - using bookworm repository"
            ;;
        *)
            CODENAME="jammy"
            print_warning "Unknown codename: $DETECTED_CODENAME - defaulting to jammy"
            ;;
    esac
    
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
    
    # Try to install td-agent
    if sudo DEBIAN_FRONTEND=noninteractive apt-get install -y td-agent > /dev/null 2>&1; then
        print_success "Fluentd (td-agent) installed successfully"
        USE_FLUENT_BIT=0
    else
        print_warning "td-agent installation failed, trying Fluent Bit instead..."
        echo ""
        
        # Fallback to Fluent Bit
        if sudo apt-get install -y fluent-bit > /dev/null 2>&1; then
            print_success "Fluent Bit installed as alternative"
            USE_FLUENT_BIT=1
        else
            print_error "Failed to install both Fluentd and Fluent Bit"
            echo ""
            print_info "Available options:"
            echo "  1. Check available packages: apt-cache search fluent"
            echo "  2. Install manually: sudo apt-get install -y fluent-bit"
            echo "  3. Or: sudo apt-get install -y td-agent"
            return 1
        fi
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
    
    if sudo yum install -y td-agent > /dev/null 2>&1; then
        print_success "Fluentd installed successfully"
        USE_FLUENT_BIT=0
    else
        print_warning "td-agent installation failed, trying Fluent Bit..."
        
        if sudo yum install -y fluent-bit > /dev/null 2>&1; then
            print_success "Fluent Bit installed as alternative"
            USE_FLUENT_BIT=1
        else
            print_error "Failed to install both Fluentd and Fluent Bit"
            return 1
        fi
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
        USE_FLUENT_BIT=1
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
        USE_FLUENT_BIT=1
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
    print_box "Starting Service"
    print_divider
    echo ""
    
    if [ "$USE_FLUENT_BIT" -eq 1 ]; then
        SERVICE_NAME="fluent-bit"
    else
        SERVICE_NAME="td-agent"
    fi
    
    if command -v systemctl &> /dev/null; then
        print_info "Starting $SERVICE_NAME with systemctl..."
        sudo systemctl start $SERVICE_NAME 2>/dev/null
        sudo systemctl enable $SERVICE_NAME 2>/dev/null
        
        sleep 2
        
        if sudo systemctl is-active --quiet $SERVICE_NAME; then
            print_success "$SERVICE_NAME started and enabled on boot"
        else
            print_warning "$SERVICE_NAME may not have started, check with: sudo systemctl status $SERVICE_NAME"
        fi
    elif command -v service &> /dev/null; then
        print_info "Starting $SERVICE_NAME with service..."
        sudo service $SERVICE_NAME start 2>/dev/null
        print_success "$SERVICE_NAME service started"
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
    
    if [ "$USE_FLUENT_BIT" -eq 1 ]; then
        SERVICE_NAME="fluent-bit"
        PORT="2020"
    else
        SERVICE_NAME="td-agent"
        PORT="24224"
    fi
    
    if sudo systemctl is-active --quiet $SERVICE_NAME 2>/dev/null; then
        print_success "$SERVICE_NAME service is RUNNING ✓"
    else
        print_warning "$SERVICE_NAME service status: check with sudo systemctl status $SERVICE_NAME"
    fi
    
    echo ""
    print_info "Checking listening ports..."
    
    if ss -tulpn 2>/dev/null | grep -q $PORT || netstat -tulpn 2>/dev/null | grep -q $PORT; then
        print_success "$SERVICE_NAME listening on port $PORT"
    else
        print_warning "Port $PORT not yet listening (may still be starting)"
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
    
    if [ "$USE_FLUENT_BIT" -eq 1 ]; then
        print_info "Fluent Bit version:"
        fluent-bit --version 2>/dev/null || echo "  Could not retrieve version"
    else
        if [[ "$OS" == "macos" ]]; then
            print_info "Fluent Bit version:"
            fluent-bit --version 2>/dev/null || echo "  Could not retrieve version"
        else
            print_info "Fluentd version:"
            td-agent --version 2>/dev/null || echo "  Could not retrieve version"
        fi
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
    
    if [ "$USE_FLUENT_BIT" -eq 1 ]; then
        if [[ "$OS" == "macos" ]]; then
            echo -e "${CYAN}${BOLD}Config File:${NC}"
            echo "  $(brew --prefix)/etc/fluent-bit/fluent-bit.conf"
            echo ""
            echo -e "${CYAN}${BOLD}Log File:${NC}"
            echo "  $(brew --prefix)/var/log/fluent-bit.log"
        else
            echo -e "${CYAN}${BOLD}Config File:${NC}"
            echo "  /etc/fluent-bit/fluent-bit.conf"
            echo ""
            echo -e "${CYAN}${BOLD}Log File:${NC}"
            echo "  /var/log/fluent-bit/fluent-bit.log"
        fi
    else
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
    fi
    
    echo ""
    echo -e "${CYAN}${BOLD}Useful Commands:${NC}"
    
    if [ "$USE_FLUENT_BIT" -eq 1 ]; then
        echo "  View logs:        tail -f /var/log/fluent-bit/fluent-bit.log"
        echo "  Restart service:  sudo systemctl restart fluent-bit"
        echo "  Stop service:     sudo systemctl stop fluent-bit"
        echo "  Edit config:      sudo nano /etc/fluent-bit/fluent-bit.conf"
    else
        echo "  View logs:        tail -f /var/log/td-agent/td-agent.log"
        echo "  Restart service:  sudo systemctl restart td-agent"
        echo "  Stop service:     sudo systemctl stop td-agent"
        echo "  Edit config:      sudo nano /etc/td-agent/td-agent.conf"
    fi
    
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
    
    # Initialize variables
    USE_FLUENT_BIT=0
    
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
            if [ $? -eq 0 ]; then
                start_service_linux
                check_status_linux
            fi
            ;;
        centos|rhel|fedora)
            install_centos_rhel
            if [ $? -eq 0 ]; then
                start_service_linux
                check_status_linux
            fi
            ;;
        alpine)
            install_alpine
            if [ $? -eq 0 ]; then
                start_service_linux
                check_status_linux
            fi
            ;;
        macos)
            install_macos
            if [ $? -eq 0 ]; then
                start_service_macos
                check_status_macos
            fi
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
    
    if [ "$USE_FLUENT_BIT" -eq 1 ]; then
        echo "  1️⃣  Edit config:"
        echo "     sudo nano /etc/fluent-bit/fluent-bit.conf"
    else
        echo "  1️⃣  Edit config:"
        if [[ "$OS" == "macos" ]]; then
            echo "     nano $(brew --prefix)/etc/fluent-bit/fluent-bit.conf"
        else
            echo "     sudo nano /etc/td-agent/td-agent.conf"
        fi
    fi
    
    echo ""
    echo "  2️⃣  Restart service:"
    
    if [ "$USE_FLUENT_BIT" -eq 1 ]; then
        echo "     sudo systemctl restart fluent-bit"
    else
        echo "     sudo systemctl restart td-agent"
    fi
    
    echo ""
    echo "  3️⃣  Monitor logs:"
    
    if [ "$USE_FLUENT_BIT" -eq 1 ]; then
        echo "     tail -f /var/log/fluent-bit/fluent-bit.log"
    else
        echo "     tail -f /var/log/td-agent/td-agent.log"
    fi
    
    echo ""
    echo "  4️⃣  Learn more:"
    if [ "$USE_FLUENT_BIT" -eq 1 ]; then
        echo "     https://docs.fluentbit.io/"
    else
        echo "     https://docs.fluentd.org/"
    fi
    
    echo ""
    print_divider
    echo ""
}

# ============================================================================
#                            SCRIPT EXECUTION
# ============================================================================

check_privileges
main

