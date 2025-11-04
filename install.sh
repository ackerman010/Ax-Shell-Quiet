#!/bin/bash

set -e  # Exit immediately if a command fails
# Removed set -u to avoid unbound variable issues
set -o pipefail  # Prevent errors in a pipeline from being masked

REPO_URL="https://github.com/Ackerman-00/Ax-Shell-Quiet.git"
INSTALL_DIR="$HOME/.config/Ax-Shell"
VENV_DIR="$HOME/.ax-shell-venv"

echo "Starting Ax-Shell installation for PikaOS..."
echo "=============================================="

# Update package lists
echo "Updating package lists..."
sudo apt update

# Install essential packages in one go
echo "Installing all required packages..."
sudo apt install -y \
    brightnessctl cava cliphist libgnome-bluetooth-3.0-13 \
    gobject-introspection gpu-screen-recorder hypridle hyprlock \
    libnotify-bin matugen network-manager-applet nm-connection-editor \
    fonts-noto fonts-noto-core fonts-noto-extra fonts-noto-ui-core \
    fonts-noto-unhinted fonts-noto-color-emoji fonts-noto-mono \
    nvtop playerctl power-profiles-daemon swappy swww \
    tesseract-ocr tesseract-ocr-eng tesseract-ocr-spa \
    tmux unzip upower libvte-2.91-0 gir1.2-vte-2.91 \
    webp-pixbuf-loader wl-clipboard jq grim slurp \
    libhyprlang-dev libhyprutils-dev hyprwayland-scanner \
    imagemagick libdbusmenu-gtk3-dev libgtk-layer-shell0 \
    libgtk-layer-shell-dev libwebkit2gtk-4.1-0 gir1.2-webkit2-4.1 \
    python3-gi python3-gi-cairo python3-full python3-pip python3-venv \
    python3-ijson python3-numpy python3-pil python3-psutil \
    python3-pywayland python3-requests python3-setproctitle \
    python3-toml python3-watchdog build-essential cmake git \
    meson ninja-build pkg-config valac libjson-glib-dev \
    libgtk-3-dev libcairo2-dev libpango1.0-dev libjpeg-dev \
    libwayland-dev wayland-protocols libxkbcommon-dev \
    python3-setuptools python3-wheel python3-build python3-installer \
    libgirepository1.0-dev python3-dev libffi-dev gir1.2-glib-2.0

# Create necessary directories
echo "Creating necessary directories..."
mkdir -p "$HOME/.local/src" "$HOME/.local/bin" "$HOME/.fonts"

# --- Create Python Virtual Environment ---
echo "Setting up Python virtual environment..."
if [ -d "$VENV_DIR" ]; then
    echo "Virtual environment already exists, recreating..."
    rm -rf "$VENV_DIR"
fi

python3 -m venv "$VENV_DIR"
source "$VENV_DIR/bin/activate"

echo "✅ Virtual environment created at $VENV_DIR"

# --- Install Python packages in virtual environment ---
echo "Installing Python packages in virtual environment..."

# Upgrade pip first
"$VENV_DIR/bin/pip" install --upgrade pip

# Install all Python dependencies at once
"$VENV_DIR/bin/pip" install \
    pygobject \
    psutil \
    requests \
    watchdog \
    ijson \
    toml \
    setproctitle \
    pywayland \
    loguru \
    click

echo "✅ Python dependencies installed"

# --- Install Fabric from Source ---
echo "Installing Fabric..."

FABRIC_DIR="$HOME/.local/src/fabric"
if [ -d "$FABRIC_DIR" ]; then
    echo "Updating Fabric repository..."
    cd "$FABRIC_DIR" && git pull || true
else
    echo "Cloning Fabric repository..."
    git clone --depth=1 https://github.com/Fabric-Development/fabric.git "$FABRIC_DIR"
fi

cd "$FABRIC_DIR"
"$VENV_DIR/bin/pip" install .

echo "✅ Fabric installed"

# --- Install fabric-cli ---
echo "Installing fabric-cli..."

FABRIC_CLI_DIR="$HOME/.local/src/fabric-cli"
if [ -d "$FABRIC_CLI_DIR" ]; then
    echo "Updating fabric-cli repository..."
    cd "$FABRIC_CLI_DIR" && git pull || true
else
    echo "Cloning fabric-cli repository..."
    git clone --depth=1 https://github.com/Fabric-Development/fabric-cli.git "$FABRIC_CLI_DIR"
fi

cd "$FABRIC_CLI_DIR"
"$VENV_DIR/bin/pip" install .

echo "✅ fabric-cli installed"

# --- Install Hyprpicker ---
echo "Installing Hyprpicker..."

HYPRPICKER_DIR="$HOME/.local/src/hyprpicker"
if [ -d "$HYPRPICKER_DIR" ]; then
    echo "Updating Hyprpicker repository..."
    cd "$HYPRPICKER_DIR" && git pull || true
else
    echo "Cloning Hyprpicker repository..."
    git clone --depth=1 https://github.com/hyprwm/hyprpicker.git "$HYPRPICKER_DIR"
fi

cd "$HYPRPICKER_DIR"
if [ -f "CMakeLists.txt" ]; then
    echo "Building Hyprpicker..."
    rm -rf build
    cmake -B build -S . -DCMAKE_BUILD_TYPE=Release
    cmake --build build -j$(nproc)
    sudo cmake --install build
    echo "✅ Hyprpicker installed"
else
    echo "❌ Hyprpicker build failed"
fi

# --- Install Hyprshot ---
echo "Installing Hyprshot..."

HYPRSHOT_DIR="$HOME/.local/src/hyprshot"
if [ -d "$HYPRSHOT_DIR" ]; then
    cd "$HYPRSHOT_DIR" && git pull || true
else
    git clone --depth=1 https://github.com/Gustash/Hyprshot.git "$HYPRSHOT_DIR"
fi

cp "$HYPRSHOT_DIR/hyprshot" "$HOME/.local/bin/hyprshot"
chmod +x "$HOME/.local/bin/hyprshot"
echo "✅ Hyprshot installed"

# --- Install Hyprsunset ---
echo "Installing Hyprsunset..."

HYPRSUNSET_DIR="$HOME/.local/src/hyprsunset"
if [ -d "$HYPRSUNSET_DIR" ]; then
    cd "$HYPRSUNSET_DIR" && git pull || true
else
    git clone --depth=1 https://github.com/hyprwm/hyprsunset.git "$HYPRSUNSET_DIR"
fi

cd "$HYPRSUNSET_DIR"
if [ -f "CMakeLists.txt" ]; then
    echo "Building Hyprsunset..."
    rm -rf build
    cmake -B build -S . -DCMAKE_BUILD_TYPE=Release
    cmake --build build -j$(nproc)
    sudo cmake --install build
    echo "✅ Hyprsunset installed"
else
    echo "❌ Hyprsunset build failed"
fi

# --- Install Gray ---
echo "Installing Gray..."

GRAY_DIR="$HOME/.local/src/gray"
if [ -d "$GRAY_DIR" ]; then
    cd "$GRAY_DIR" && git pull || true
else
    git clone --depth=1 https://github.com/Fabric-Development/gray.git "$GRAY_DIR"
fi

cd "$GRAY_DIR"
if [ -f "meson.build" ]; then
    echo "Building Gray..."
    rm -rf build
    meson setup build --prefix=/usr --buildtype=release
    ninja -C build
    sudo ninja -C build install
    echo "✅ Gray installed"
else
    echo "❌ Gray build failed"
fi

# --- Install Fonts ---
echo "Installing fonts..."

# Nerd Fonts
mkdir -p "$HOME/.local/src/nerd-fonts"
curl -L -o "$HOME/.fonts/SymbolsNerdFont-Regular.ttf" \
    "https://raw.githubusercontent.com/ryanoasis/nerd-fonts/v3.4.0/patched-fonts/NerdFontsSymbolsOnly/SymbolsNerdFont-Regular.ttf" || true
curl -L -o "$HOME/.fonts/SymbolsNerdFontMono-Regular.ttf" \
    "https://raw.githubusercontent.com/ryanoasis/nerd-fonts/v3.4.0/patched-fonts/NerdFontsSymbolsOnly/SymbolsNerdFontMono-Regular.ttf" || true

# Zed Sans Fonts
if [ ! -d "$HOME/.fonts/zed-sans" ]; then
    mkdir -p "$HOME/.fonts/zed-sans"
    curl -L -o "/tmp/zed-sans.zip" \
        "https://github.com/zed-industries/zed-fonts/releases/download/1.2.0/zed-sans-1.2.0.zip" && \
    unzip -o "/tmp/zed-sans.zip" -d "$HOME/.fonts/zed-sans" || true
    rm -f "/tmp/zed-sans.zip"
fi

fc-cache -fv
echo "✅ Fonts installed"

# --- Clone Ax-Shell ---
echo "Setting up Ax-Shell..."

if [ -d "$INSTALL_DIR" ]; then
    cd "$INSTALL_DIR" && git pull || true
else
    git clone --depth=1 "$REPO_URL" "$INSTALL_DIR"
fi

# Copy Ax-Shell fonts if available
if [ -d "$INSTALL_DIR/assets/fonts" ]; then
    cp -r "$INSTALL_DIR/assets/fonts/"* "$HOME/.fonts/" 2>/dev/null || true
fi

# --- Network configuration ---
echo "Configuring network..."
sudo systemctl disable iwd 2>/dev/null || true
sudo systemctl enable NetworkManager 2>/dev/null || true
sudo systemctl start NetworkManager 2>/dev/null || true

# --- Update PATH ---
if ! grep -q ".local/bin" "$HOME/.bashrc"; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
fi

if ! grep -q "ax-shell-venv" "$HOME/.bashrc"; then
    echo "alias ax-shell='$VENV_DIR/bin/python $INSTALL_DIR/main.py'" >> "$HOME/.bashrc"
fi

export PATH="$HOME/.local/bin:$PATH"

# --- Final setup ---
echo "Finalizing installation..."

# Verify installation
echo "Checking installed components:"
command -v hyprpicker >/dev/null && echo "✅ Hyprpicker" || echo "❌ Hyprpicker"
[ -f "$HOME/.local/bin/hyprshot" ] && echo "✅ Hyprshot" || echo "❌ Hyprshot"
command -v hyprsunset >/dev/null && echo "✅ Hyprsunset" || echo "❌ Hyprsunset"
command -v gray >/dev/null && echo "✅ Gray" || echo "❌ Gray"
"$VENV_DIR/bin/python" -c "import fabric" 2>/dev/null && echo "✅ Fabric" || echo "❌ Fabric"
"$VENV_DIR/bin/python" -c "import fabric_cli" 2>/dev/null && echo "✅ fabric-cli" || echo "❌ fabric-cli"
"$VENV_DIR/bin/python" -c "import gi" 2>/dev/null && echo "✅ PyGObject" || echo "❌ PyGObject"

# Run configuration if available
if [ -f "$INSTALL_DIR/config/config.py" ]; then
    echo "Running Ax-Shell configuration..."
    cd "$INSTALL_DIR"
    "$VENV_DIR/bin/python" "config/config.py" || echo "Configuration had issues"
fi

# Start Ax-Shell
echo "Starting Ax-Shell..."
pkill -f "ax-shell" 2>/dev/null || true

if command -v uwsm >/dev/null; then
    uwsm app -- "$VENV_DIR/bin/python" "$INSTALL_DIR/main.py" > /dev/null 2>&1 & disown
else
    "$VENV_DIR/bin/python" "$INSTALL_DIR/main.py" > /dev/null 2>&1 &
fi

echo ""
echo "=============================================="
echo "INSTALLATION COMPLETE!"
echo "=============================================="
echo ""
echo "Ax-Shell is now running!"
echo "Manual start: ax-shell"
echo "Virtual env: $VENV_DIR"
echo ""
echo "Restart terminal or run: source ~/.bashrc"
echo "=============================================="
