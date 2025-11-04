#!/bin/bash

set -e  # Exit immediately if a command fails
set -u  # Treat unset variables as errors
set -o pipefail  # Prevent errors in a pipeline from being masked

REPO_URL="https://github.com/Ackerman-00/Ax-Shell-Quiet.git"
INSTALL_DIR="$HOME/.config/Ax-Shell"

# Package list for PikaOS - verified available packages
PACKAGES=(
    brightnessctl
    cava
    cliphist
    fabric
    libgnome-bluetooth-3.0-13
    gobject-introspection
    gpu-screen-recorder
    hypridle
    hyprlock
    libnotify-bin
    matugen
    network-manager-applet
    nm-connection-editor
    fonts-noto
    fonts-noto-core
    fonts-noto-extra
    fonts-noto-ui-core
    fonts-noto-unhinted
    fonts-noto-color-emoji
    fonts-noto-mono
    nvtop
    playerctl
    power-profiles-daemon
    swappy
    swww
    tesseract-ocr
    tesseract-ocr-eng
    tesseract-ocr-spa
    tmux
    unzip
    upower
    libvte-2.91-0
    gir1.2-vte-2.91
    webp-pixbuf-loader
    wl-clipboard
)

# Python packages for PikaOS
PYTHON_PACKAGES=(
    python3-gi
    python3-ijson
    python3-numpy
    python3-pil
    python3-psutil
    python3-pywayland
    python3-requests
    python3-setproctitle
    python3-toml
    python3-watchdog
)

# Build dependencies
BUILD_PACKAGES=(
    cmake
    gcc
    g++
    git
    meson
    ninja-build
    pkg-config
    wayland-protocols
    libwayland-dev
    libxkbcommon-dev
    libcairo2-dev
    libpango1.0-dev
    libjpeg-dev
)

# Prevent running as root
if [ "$(id -u)" -eq 0 ]; then
    echo "Please do not run this script as root."
    exit 1
fi

# Use pikman if available, otherwise use apt
if command -v pikman &>/dev/null; then
    PKG_MANAGER="pikman install"
    echo "Using pikman for package installation."
elif command -v apt &>/dev/null; then
    PKG_MANAGER="sudo apt install -y"
    echo "Using apt for package installation."
else
    echo "Error: Neither pikman nor apt found. Cannot install packages."
    exit 1
fi

# Update package lists
echo "Updating package lists..."
if command -v pikman &>/dev/null; then
    pikman update
else
    sudo apt update
fi

# Install required system packages
echo "Installing required system packages..."
$PKG_MANAGER "${PACKAGES[@]}" || { echo "Some packages failed to install. Continuing with script..."; }

# Install Python packages
echo "Installing Python packages..."
$PKG_MANAGER "${PYTHON_PACKAGES[@]}" || { echo "Some Python packages failed to install. Continuing with script..."; }

# Install build dependencies
echo "Installing build dependencies..."
$PKG_MANAGER "${BUILD_PACKAGES[@]}" || { echo "Some build packages failed to install. Continuing with script..."; }

# --- Install Nerd Fonts Symbols from Source ---
echo "Installing Nerd Fonts Symbols..."

NERD_FONTS_VERSION="3.4.0"
NERD_FONTS_DIR="$HOME/.local/src/nerd-fonts-symbols"
mkdir -p "$NERD_FONTS_DIR"

# Download font files and configuration
echo "Downloading Nerd Fonts Symbols..."
curl -L -o "$NERD_FONTS_DIR/SymbolsNerdFont-Regular.ttf" \
    "https://raw.githubusercontent.com/ryanoasis/nerd-fonts/v$NERD_FONTS_VERSION/patched-fonts/NerdFontsSymbolsOnly/SymbolsNerdFont-Regular.ttf"

curl -L -o "$NERD_FONTS_DIR/SymbolsNerdFontMono-Regular.ttf" \
    "https://raw.githubusercontent.com/ryanoasis/nerd-fonts/v$NERD_FONTS_VERSION/patched-fonts/NerdFontsSymbolsOnly/SymbolsNerdFontMono-Regular.ttf"

curl -L -o "$NERD_FONTS_DIR/10-nerd-font-symbols.conf" \
    "https://raw.githubusercontent.com/ryanoasis/nerd-fonts/v$NERD_FONTS_VERSION/10-nerd-font-symbols.conf"

curl -L -o "$NERD_FONTS_DIR/LICENSE" \
    "https://raw.githubusercontent.com/ryanoasis/nerd-fonts/v$NERD_FONTS_VERSION/LICENSE"

# Create font directories
echo "Installing Nerd Fonts to system..."
sudo mkdir -p /usr/share/fonts/TTF
sudo mkdir -p /usr/share/fontconfig/conf.avail
sudo mkdir -p /usr/share/licenses/ttf-nerd-fonts-symbols-common

# Install the fonts
sudo install -Dm644 "$NERD_FONTS_DIR/SymbolsNerdFont-Regular.ttf" \
    /usr/share/fonts/TTF/SymbolsNerdFont-Regular.ttf

sudo install -Dm644 "$NERD_FONTS_DIR/SymbolsNerdFontMono-Regular.ttf" \
    /usr/share/fonts/TTF/SymbolsNerdFontMono-Regular.ttf

# Install fontconfig configuration
sudo install -Dm644 "$NERD_FONTS_DIR/10-nerd-font-symbols.conf" \
    /usr/share/fontconfig/conf.avail/10-nerd-font-symbols.conf

# Install license
sudo install -Dm644 "$NERD_FONTS_DIR/LICENSE" \
    /usr/share/licenses/ttf-nerd-fonts-symbols-common/LICENSE

# Create symlink for fontconfig
if [ ! -f /etc/fonts/conf.d/10-nerd-font-symbols.conf ]; then
    sudo ln -sf /usr/share/fontconfig/conf.avail/10-nerd-font-symbols.conf \
        /etc/fonts/conf.d/10-nerd-font-symbols.conf
fi

# Update font cache
echo "Updating font cache..."
sudo fc-cache -fv

echo "Nerd Fonts Symbols have been installed successfully."

# --- Install missing Hyprland components from Source ---

# Install hyprpicker from source (not available in repos)
echo "Installing Hyprpicker from source..."

HYPRPICKER_DIR="$HOME/.local/src/hyprpicker"
mkdir -p "$(dirname "$HYPRPICKER_DIR")"
if [ -d "$HYPRPICKER_DIR" ]; then
    echo "Updating Hyprpicker repository..."
    git -C "$HYPRPICKER_DIR" pull
else
    echo "Cloning Hyprpicker repository..."
    git clone --depth=1 https://github.com/hyprwm/hyprpicker.git "$HYPRPICKER_DIR"
fi

# Build and install Hyprpicker
cd "$HYPRPICKER_DIR"
make all
sudo make install

echo "Hyprpicker has been installed from source."

# --- Install Hyprshot from Source ---
echo "Installing Hyprshot from source..."

HYPRSHOT_DIR="$HOME/.local/src/Hyprshot"
mkdir -p "$(dirname "$HYPRSHOT_DIR")"
if [ -d "$HYPRSHOT_DIR" ]; then
    echo "Updating Hyprshot repository..."
    git -C "$HYPRSHOT_DIR" pull
else
    echo "Cloning Hyprshot repository..."
    git clone --depth=1 https://github.com/Gustash/hyprshot.git "$HYPRSHOT_DIR"
fi

# Create symlink in local bin directory
mkdir -p "$HOME/.local/bin"
ln -sf "$HYPRSHOT_DIR/hyprshot" "$HOME/.local/bin/hyprshot"
chmod +x "$HYPRSHOT_DIR/hyprshot"

echo "Hyprshot has been installed to $HOME/.local/bin/hyprshot"

# --- Install Hyprsunset from Source ---
echo "Installing Hyprsunset from source..."

HYPRSUNSET_DIR="$HOME/.local/src/hyprsunset"
mkdir -p "$(dirname "$HYPRSUNSET_DIR")"
if [ -d "$HYPRSUNSET_DIR" ]; then
    echo "Updating Hyprsunset repository..."
    git -C "$HYPRSUNSET_DIR" pull
else
    echo "Cloning Hyprsunset repository..."
    git clone --depth=1 https://github.com/hyprwm/hyprsunset.git "$HYPRSUNSET_DIR"
fi

# Build and install Hyprsunset using CMake
cd "$HYPRSUNSET_DIR"
cmake -B build -S . -DCMAKE_BUILD_TYPE=Release
cmake --build build
sudo cmake --install build

echo "Hyprsunset has been installed from source."

# --- Install Gray from Source ---
echo "Installing Gray from source..."

GRAY_DIR="$HOME/.local/src/gray"
mkdir -p "$(dirname "$GRAY_DIR")"
if [ -d "$GRAY_DIR" ]; then
    echo "Updating Gray repository..."
    git -C "$GRAY_DIR" pull
else
    echo "Cloning Gray repository..."
    git clone --depth=1 https://github.com/Fabric-Development/gray.git "$GRAY_DIR"
fi

# Build and install Gray
cd "$GRAY_DIR"
meson setup --prefix=/usr build .
sudo ninja -C build install

echo "Gray has been installed from source."

# Clone or update the Ax-Shell repository (using user's fork)
if [ -d "$INSTALL_DIR" ]; then
    echo "Updating Ax-Shell (Quiet fork)..."
    git -C "$INSTALL_DIR" pull
else
    echo "Cloning Ax-Shell (Quiet fork)..."
    git clone --depth=1 "$REPO_URL" "$INSTALL_DIR"
fi

echo "Installing required fonts..."

FONT_URL="https://github.com/zed-industries/zed-fonts/releases/download/1.2.0/zed-sans-1.2.0.zip"
FONT_DIR="$HOME/.fonts/zed-sans"
TEMP_ZIP="/tmp/zed-sans-1.2.0.zip"

# Check if fonts are already installed
if [ ! -d "$FONT_DIR" ]; then
    echo "Downloading fonts from $FONT_URL..."
    curl -L -o "$TEMP_ZIP" "$FONT_URL"

    echo "Extracting fonts to $FONT_DIR..."
    mkdir -p "$FONT_DIR"
    unzip -o "$TEMP_ZIP" -d "$FONT_DIR"

    echo "Cleaning up..."
    rm "$TEMP_ZIP"
else
    echo "Fonts are already installed. Skipping download and extraction."
fi

# Network services handling
echo "Configuring network services..."

# Disable iwd if enabled/active
if systemctl is-enabled --quiet iwd 2>/dev/null || systemctl is-active --quiet iwd 2>/dev/null; then
    echo "Disabling iwd..."
    sudo systemctl disable --now iwd
else
    echo "iwd is already disabled."
fi

# Enable NetworkManager if not enabled
if ! systemctl is-enabled --quiet NetworkManager 2>/dev/null; then
    echo "Enabling NetworkManager..."
    sudo systemctl enable NetworkManager
else
    echo "NetworkManager is already enabled."
fi

# Start NetworkManager if not running
if ! systemctl is-active --quiet NetworkManager 2>/dev/null; then
    echo "Starting NetworkManager..."
    sudo systemctl start NetworkManager
else
    echo "NetworkManager is already running."
fi

# Copy local fonts if not already present
if [ ! -d "$HOME/.fonts/tabler-icons" ]; then
    echo "Copying local fonts to $HOME/.fonts/tabler-icons..."
    mkdir -p "$HOME/.fonts/tabler-icons"
    cp -r "$INSTALL_DIR/assets/fonts/"* "$HOME/.fonts"
else
    echo "Local fonts are already installed. Skipping copy."
fi

# Ensure ~/.local/bin is in PATH for hyprshot
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    echo "Added ~/.local/bin to PATH in .bashrc"
    export PATH="$HOME/.local/bin:$PATH"
fi

# Run configuration and start Ax-Shell
cd "$INSTALL_DIR"
python3 "$INSTALL_DIR/config/config.py"
echo "Starting Ax-Shell..."
killall ax-shell 2>/dev/null || true

# Since uwsm is not available, starting directly with Python
echo "Starting Ax-Shell directly with Python (uwsm not available)..."
python3 "$INSTALL_DIR/main.py" > /dev/null 2>&1 & disown

echo "Installation complete!"
echo "Ax-Shell (Quiet fork) has been successfully installed from $REPO_URL"
echo "Nerd Fonts Symbols have been installed system-wide"
echo "Note: Some components were installed in ~/.local/bin - make sure this is in your PATH."
