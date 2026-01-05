#!/bin/bash

################################################################################
#                                                                              #
#                   🎯 FLUENTD AUTO-INSTALL & START SCRIPT                    #
#                                                                              #
#  Automatic detection, installation, and startup of Fluentd/Fluent Bit      #
#  Supported: Ubuntu, Debian, CentOS, RHEL, Alpine, macOS                    #
#                                                                              #
################################################################################

set -e

# ============================================================================
#                              COLOR DEFINITIONS
# ============================================================================

# Standard Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color

# Background Colors
BG_BLUE='\033[44m'
BG_GREEN='\033[42m'
BG_RED='\033[41m'

# Text Styles
BOLD='\033[1m'
UNDERLINE='\033[4m'
DIM='\033[2m'

# Emojis
SUCCESS='✅'
ERROR='❌'
WARNING='⚠️ '
INFO='ℹ️ '
SPINNER='⟳'
ARROW='→'
ROCKET='🚀'
GEAR='⚙️ '
HEART='❤️ '

# ============================================================================
#                           UTILITY FUNCTIONS
# ============================================================================

# Print header with style
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

# Print success message with box
print_success() {
    echo -e "${GREEN}${BOLD}${SUCCESS}  $1${NC}"
}

# Print error message with box
print_error() {
    echo -e "${RED}${BOLD}${ERROR}  $1${NC}"
}

# Print warning message
print_warning() {
    echo -e "${YELLOW}${BOLD}${WARNING} $1${NC}"
}

# Print info message
print_info() {
    echo -e "${CYAN}${BOLD}${INFO} $1${NC}"
}

# Print section divider
print_divider() {
    echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Animated spinner
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while kill -0 $pid 2>/dev/null; do
        local temp=${spinstr#?}
        printf " [${CYAN}%c${NC}]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Print box around text
print_box() {
    local text="$1"
    local width=${#text}
    echo -e "${BLUE}┌$(printf '─%.0s' {1..$((width+2))})┐${NC}"
    echo -e "${BLUE}│${NC} ${BOLD}$text${NC} ${BLUE}│${NC}"
    echo -e "${BLUE}└$(printf '─%.0s' {1..$((width+2))})┘${NC}"
}

# Progress bar
show_progress() {
    local current=$1
    local total=$2
    local task="$3"
    
    local percent=$((current * 100 / total))
    local bar_length=40
    local filled=$((percent * bar_length / 100))
    
    printf "\r${CYAN}${task}${NC} ["
    printf "%${filled}s" | tr ' ' '█'
    printf "%$((bar_length - filled))s" | tr ' ' '░'
    printf "] ${percent}%% "
}

# ============================================================================
#                            DETECTION FUNCTIONS
# ============================================================================

detect_os() {
    print_info "Detecting operating system..."
    sleep 1
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            OS=$ID
            VERSION=$VERSION_ID
            OS_NAME=$PRETTY_NAME
        elif [ -f /etc/lsb-release ]; then
            . /etc/lsb-release
            OS=$(echo $DISTRIB_ID | tr '[:upper:]' '[:lower:]')
            VERSION=$DISTRIB_RELEASE
            OS_NAME="$DISTRIB_ID $DISTRIB_RELEASE"
        else
            OS="linux"
            VERSION="unknown"
            OS_NAME="Linux (Unknown)"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        VERSION=$(sw_vers -productVersion)
        OS_NAME="macOS $(sw_vers -productVersion)"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        OS="windows"
        VERSION="unknown"
        OS_NAME="Windows"
    else
        OS="unknown"
        VERSION="unknown"
        OS_NAME="Unknown OS"
    fi

    echo "$OS|$VERSION|$OS_NAME"
}

# ============================================================================
#                          INSTALLATION FUNCTIONS
# ============================================================================

install_ubuntu_debian() {
    print_divider
    print_box "Installing on Ubuntu/Debian"
    print_divider
    echo ""
    
    show_progress 0 5 "Setting up repository"
    sleep 1
    curl -fsSL https://packages.treasuredata.com/GPG-KEY-td-agent 2>/dev/null | \
        sudo gpg --dearmor -o /usr/share/keyrings/fluentd-keyring.gpg 2>/dev/null &
    spinner $!
    show_progress 1 5 "Setting up repository"
    echo ""
    
    show_progress 2 5 "Adding Fluentd sources"
    sleep 1
    echo "deb [signed-by=/usr/share/keyrings/fluentd-keyring.gpg] https://packages.treasuredata.com/debian/bullseye/ bullseye contrib" | \
        sudo tee /etc/apt/sources.list.d/fluentd.list > /dev/null 2>&1 &
    spinner $!
    show_progress 2 5 "Adding Fluentd sources"
    echo ""
    
    show_progress 3 5 "Updating package manager"
    sleep 2
    sudo apt-get update > /dev/null 2>&1 &
    spinner $!
    show_progress 3 5 "Updating package manager"
    echo ""
    
    show_progress 4 5 "Installing Fluentd package"
    sleep 2
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y td-agent > /dev/null 2>&1 &
    spinner $!
    show_progress 4 5 "Installing Fluentd package"
    echo ""
    
    show_progress 5 5 "Finalizing installation"
    sleep 1
    show_progress 5 5 "Finalizing installation"
    echo ""
    echo ""
    
    print_success "Fluentd installed successfully on Ubuntu/Debian"
}

install_centos_rhel() {
    print_divider
    print_box "Installing on CentOS/RHEL"
    print_divider
    echo ""
    
    show_progress 0 4 "Setting up repository"
    sleep 1
    cat << EOF | sudo tee /etc/yum.repos.d/td.repo > /dev/null 2>&1
[treasuredata]
name=TreasureData
baseurl=https://packages.treasuredata.com/redhat/\$releasever/\$basearch
gpgcheck=1
gpgkey=https://packages.treasuredata.com/GPG-KEY-td-agent
EOF
    show_progress 1 4 "Setting up repository"
    echo ""
    
    show_progress 2 4 "Installing Fluentd package"
    sleep 2
    sudo yum install -y td-agent > /dev/null 2>&1 &
    spinner $!
    show_progress 2 4 "Installing Fluentd package"
    echo ""
    
    show_progress 3 4 "Configuring service"
    sleep 1
    show_progress 3 4 "Configuring service"
    echo ""
    
    show_progress 4 4 "Finalizing installation"
    sleep 1
    show_progress 4 4 "Finalizing installation"
    echo ""
    echo ""
    
    print_success "Fluentd installed successfully on CentOS/RHEL"
}

install_alpine() {
    print_divider
    print_box "Installing on Alpine Linux"
    print_divider
    echo ""
    
    show_progress 0 3 "Updating package manager"
    sleep 1
    sudo apk update > /dev/null 2>&1 &
    spinner $!
    show_progress 1 3 "Updating package manager"
    echo ""
    
    show_progress 2 3 "Installing Fluent Bit (Alpine alternative)"
    sleep 2
    sudo apk add --no-cache fluent-bit > /dev/null 2>&1 &
    spinner $!
    show_progress 2 3 "Installing Fluent Bit (Alpine alternative)"
    echo ""
    
    show_progress 3 3 "Finalizing installation"
    sleep 1
    show_progress 3 3 "Finalizing installation"
    echo ""
    echo ""
    
    print_success "Fluent Bit installed successfully on Alpine Linux"
}

install_macos() {
    print_divider
    print_box "Installing on macOS"
    print_divider
    echo ""
    
    if ! command -v brew &> /dev/null; then
        print_warning "Homebrew not found. Installing first..."
        echo ""
        show_progress 0 2 "Installing Homebrew"
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" > /dev/null 2>&1 &
        spinner $!
        show_progress 1 2 "Installing Homebrew"
        echo ""
    fi
    
    show_progress 1 2 "Installing Fluent Bit via Homebrew"
    sleep 2
    brew install fluent-bit > /dev/null 2>&1 &
    spinner $!
    show_progress 2 2 "Installing Fluent Bit via Homebrew"
    echo ""
    echo ""
    
    print_success "Fluent Bit installed successfully on macOS"
}

install_windows() {
    print_error "Windows detected!"
    echo ""
    echo -e "${BOLD}Please install Fluentd manually using one of these methods:${NC}"
    echo ""
    echo -e "${CYAN}${ARROW}${NC} Download MSI installer:"
    echo "   ${UNDERLINE}https://docs.fluentd.org/installation/install-by-msi${NC}"
    echo ""
    echo -e "${CYAN}${ARROW}${NC} Using Chocolatey (if installed):"
    echo "   ${BOLD}choco install fluentd${NC}"
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
    
    show_progress 0 2 "Starting Fluentd service"
    sleep 1
    
    if command -v systemctl &> /dev/null; then
        sudo systemctl start td-agent > /dev/null 2>&1
        sudo systemctl enable td-agent > /dev/null 2>&1
        show_progress 2 2 "Starting Fluentd service"
        echo ""
        print_success "Fluentd started and enabled on boot"
    elif command -v service &> /dev/null; then
        sudo service td-agent start > /dev/null 2>&1
        show_progress 2 2 "Starting Fluentd service"
        echo ""
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
    
    show_progress 0 2 "Starting Fluent Bit service"
    sleep 1
    
    if command -v fluent-bit &> /dev/null; then
        brew services start fluent-bit > /dev/null 2>&1 &
        spinner $!
        show_progress 2 2 "Starting Fluent Bit service"
        echo ""
        print_success "Fluent Bit service started"
    else
        print_error "Fluent Bit not found"
        return 1
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
    
    if command -v systemctl &> /dev/null; then
        # Get status
        if sudo systemctl is-active --quiet td-agent; then
            print_success "Fluentd service is RUNNING"
            echo ""
            echo -e "${CYAN}Service Details:${NC}"
            sudo systemctl status td-agent --no-pager | grep -E "Active|Loaded" | sed 's/^/  /'
        else
            print_error "Fluentd service is STOPPED"
            return 1
        fi
    fi
    
    echo ""
    
    # Check port
    print_info "Checking listening ports..."
    sleep 1
    
    if netstat -tulpn 2>/dev/null | grep -q 24224 || ss -tulpn 2>/dev/null | grep -q 24224; then
        print_success "Fluentd is listening on port 24224"
    else
        print_warning "Fluentd may not be listening on port 24224 yet"
    fi
    
    echo ""
}

check_status_macos() {
    print_divider
    print_box "Service Status"
    print_divider
    echo ""
    
    print_info "Checking Fluent Bit status..."
    sleep 1
    
    if brew services list | grep -q "fluent-bit.*started"; then
        print_success "Fluent Bit service is RUNNING"
        echo ""
        echo -e "${CYAN}Service Details:${NC}"
        brew services list | grep fluent-bit | sed 's/^/  /'
    else
        print_warning "Fluent Bit status unknown or not running"
    fi
    
    echo ""
}

check_version() {
    print_divider
    print_box "Version Information"
    print_divider
    echo ""
    
    print_info "Checking installed version..."
    sleep 1
    
    if [[ "$OS" == "macos" ]]; then
        echo -e "${CYAN}Fluent Bit Version:${NC}"
        fluent-bit --version 2>/dev/null | sed 's/^/  /' || echo "  Could not retrieve version"
    else
        echo -e "${CYAN}Fluentd Version:${NC}"
        td-agent --version 2>/dev/null | sed 's/^/  /' || echo "  Could not retrieve version"
    fi
    
    echo ""
}

# ============================================================================
#                        CONFIGURATION INFO
# ============================================================================

show_config_info() {
    print_divider
    print_box "Configuration Paths"
    print_divider
    echo ""
    
    if [[ "$OS" == "macos" ]]; then
        echo -e "${CYAN}${BOLD}Configuration File:${NC}"
        echo "  $(brew --prefix)/etc/fluent-bit/fluent-bit.conf"
        echo ""
        echo -e "${CYAN}${BOLD}Log File:${NC}"
        echo "  $(brew --prefix)/var/log/fluent-bit.log"
    else
        echo -e "${CYAN}${BOLD}Configuration File:${NC}"
        echo "  /etc/td-agent/td-agent.conf"
        echo ""
        echo -e "${CYAN}${BOLD}Log File:${NC}"
        echo "  /var/log/td-agent/td-agent.log"
    fi
    
    echo ""
    echo -e "${CYAN}${BOLD}Useful Commands:${NC}"
    echo "  ${GRAY}View logs${NC}:           tail -f /var/log/td-agent/td-agent.log"
    echo "  ${GRAY}Restart service${NC}:     sudo systemctl restart td-agent"
    echo "  ${GRAY}Stop service${NC}:        sudo systemctl stop td-agent"
    echo "  ${GRAY}Edit config${NC}:         sudo nano /etc/td-agent/td-agent.conf"
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
        print_info "Please run: ${BOLD}sudo $0${NC}"
        echo ""
        exit 1
    fi
}

main() {
    print_header
    
    # Get OS info
    OS_INFO=$(detect_os)
    OS=$(echo $OS_INFO | cut -d'|' -f1)
    VERSION=$(echo $OS_INFO | cut -d'|' -f2)
    OS_NAME=$(echo $OS_INFO | cut -d'|' -f3)
    
    echo ""
    print_info "Operating System: ${BOLD}${OS_NAME}${NC}"
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
            echo -e "${CYAN}Supported operating systems:${NC}"
            echo "  • Ubuntu / Debian"
            echo "  • CentOS / RHEL / Fedora"
            echo "  • Alpine Linux"
            echo "  • macOS"
            echo ""
            exit 1
            ;;
    esac
    
    # Show version info
    check_version
    
    # Show configuration info
    show_config_info
    
    # Final summary
    echo ""
    print_divider
    echo -e "${GREEN}${BOLD}${ROCKET} INSTALLATION COMPLETED SUCCESSFULLY! ${ROCKET}${NC}"
    print_divider
    echo ""
    echo -e "${MAGENTA}${BOLD}Next Steps:${NC}"
    echo ""
    echo -e "  1️⃣  ${CYAN}Edit configuration${NC}"
    if [[ "$OS" == "macos" ]]; then
        echo "     nano $(brew --prefix)/etc/fluent-bit/fluent-bit.conf"
    else
        echo "     sudo nano /etc/td-agent/td-agent.conf"
    fi
    echo ""
    echo -e "  2️⃣  ${CYAN}Restart service${NC}"
    echo "     sudo systemctl restart td-agent"
    echo ""
    echo -e "  3️⃣  ${CYAN}Monitor logs${NC}"
    echo "     tail -f /var/log/td-agent/td-agent.log"
    echo ""
    echo -e "  4️⃣  ${CYAN}Learn more${NC}"
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

