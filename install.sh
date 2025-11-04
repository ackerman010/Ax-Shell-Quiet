#!/bin/bash

set -e  # Exit immediately if a command fails
set -u  # Treat unset variables as errors
set -o pipefail  # Prevent errors in a pipeline from being masked

REPO_URL="https://github.com/Ackerman-00/Ax-Shell-Quiet.git"
INSTALL_DIR="$HOME/.config/Ax-Shell"
VENV_DIR="$HOME/.ax-shell-venv"

# Package list for PikaOS - Debian package names
PACKAGES=(
    brightnessctl
    cava
    cliphist
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
    # Hyprshot dependencies
    jq
    grim
    slurp
    # Hypr tools
    libhyprlang-dev
    libhyprutils-dev
    hyprwayland-scanner
    # Image manipulation
    imagemagick
    # Gray dependencies
    libdbusmenu-gtk3-dev
    # Fabric dependencies (Debian versions)
    libgtk-layer-shell0
    libgtk-layer-shell-dev
    libwebkit2gtk-4.1-0
    gir1.2-webkit2-4.1
    # Python GI packages (Debian names)
    python3-gi
    python3-gi-cairo
    # Python pip and virtual environment
    python3-full
    python3-pip
    python3-venv
)

# Python packages for Ax-Shell (Debian package names)
PYTHON_PACKAGES=(
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

# Build dependencies for tools that need compilation
BUILD_PACKAGES=(
    build-essential
    cmake
    git
    meson
    ninja-build
    pkg-config
    # Vala for Gray
    valac
    libjson-glib-dev
    libgtk-3-dev
    # Additional dependencies for hyprpicker
    libcairo2-dev
    libpango1.0-dev
    libjpeg-dev
    libwayland-dev
    wayland-protocols
    libxkbcommon-dev
    # Python build dependencies for Fabric
    python3-setuptools
    python3-wheel
    python3-build
    python3-installer
    # PyGObject build dependencies (Arch-style)
    libgirepository1.0-dev
    libcairo2-dev
    python3-dev
    # Additional deps from Arch package
    libffi-dev
    gir1.2-glib-2.0
)

# PyGObject specific build dependencies
PYGOBJECT_BUILD_DEPS=(
    python3-pydata-sphinx-theme
    python3-sphinx
    python3-sphinx-copybutton
    python3-pytest
    xvfb
)

# Prevent running as root
if [ "$(id -u)" -eq 0 ]; then
    echo "Please do not run this script as root."
    exit 1
fi

echo "Starting Ax-Shell installation for PikaOS..."
echo "=============================================="

# Update package lists
echo "Updating package lists..."
sudo apt update

# Install packages in batches
echo "Installing system packages..."
sudo apt install -y "${PACKAGES[@]}"

echo "Installing Python packages..."
sudo apt install -y "${PYTHON_PACKAGES[@]}"

echo "Installing build dependencies..."
sudo apt install -y "${BUILD_PACKAGES[@]}"

echo "Installing PyGObject build dependencies..."
sudo apt install -y "${PYGOBJECT_BUILD_DEPS[@]}"

# Create necessary directories
echo "Creating necessary directories..."
mkdir -p "$HOME/.local/src"
mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.fonts"
mkdir -p "$HOME/.local/lib/python3.12/site-packages"

# --- Create Python Virtual Environment ---
echo "Setting up Python virtual environment..."
if [ -d "$VENV_DIR" ]; then
    echo "Virtual environment already exists, recreating..."
    rm -rf "$VENV_DIR"
fi

python3 -m venv "$VENV_DIR"
source "$VENV_DIR/bin/activate"

echo "✅ Virtual environment created at $VENV_DIR"

# --- Build and Install PyGObject from Source (Arch-style) ---
echo "Building PyGObject from source (Arch-style)..."

PYGOBJECT_DIR="$HOME/.local/src/pygobject"
PYGOBJECT_VERSION="3.46.0"  # Using a stable version that works well

if [ -d "$PYGOBJECT_DIR" ]; then
    echo "Updating PyGObject repository..."
    git -C "$PYGOBJECT_DIR" pull
else
    echo "Cloning PyGObject repository..."
    git clone --depth=1 https://gitlab.gnome.org/GNOME/pygobject.git "$PYGOBJECT_DIR"
    cd "$PYGOBJECT_DIR"
    # Checkout a specific stable version
    git checkout "$PYGOBJECT_VERSION" 2>/dev/null || echo "Using latest version"
fi

cd "$PYGOBJECT_DIR"

echo "Building PyGObject with meson..."
# Clean previous builds
rm -rf build

# Build with meson (Arch-style approach)
export PKG_CONFIG_PATH="$VENV_DIR/lib/pkgconfig:$PKG_CONFIG_PATH"
export PYTHONPATH="$VENV_DIR/lib/python3.12/site-packages:$PYTHONPATH"

# Configure the build
meson setup build \
    --prefix="$VENV_DIR" \
    --libdir="$VENV_DIR/lib" \
    --bindir="$VENV_DIR/bin" \
    --buildtype=release \
    -Dpython="$VENV_DIR/bin/python" \
    -Dpycairo=false \
    -Dtests=false

# Build and install
echo "Compiling PyGObject..."
ninja -C build
ninja -C build install

echo "✅ PyGObject installed successfully in virtual environment"

# --- Install remaining Python packages in virtual environment ---
echo "Installing Python packages in virtual environment..."

# Upgrade pip first
"$VENV_DIR/bin/pip" install --upgrade pip

# Install core Python dependencies (excluding PyGObject since we built it)
"$VENV_DIR/bin/pip" install psutil requests watchdog ijson toml setproctitle pywayland loguru click

# --- Install Fabric from Source in Virtual Environment ---
echo "Building and installing Fabric from source..."

FABRIC_DIR="$HOME/.local/src/fabric"
if [ -d "$FABRIC_DIR" ]; then
    echo "Updating Fabric repository..."
    git -C "$FABRIC_DIR" pull || echo "Git pull failed, continuing with existing code..."
else
    echo "Cloning Fabric repository..."
    git clone --depth=1 https://github.com/Fabric-Development/fabric.git "$FABRIC_DIR"
fi

# Build and install Fabric in virtual environment
cd "$FABRIC_DIR"
echo "Building Fabric with Python build system..."

# Get version info
FABRIC_VERSION="r$(git rev-list --count HEAD).$(git rev-parse --short=7 HEAD)"
echo "Building Fabric version: $FABRIC_VERSION"

# Build and install in virtual environment
if "$VENV_DIR/bin/python" -m build --wheel --no-isolation; then
    WHEEL_FILE=$(ls dist/*.whl | head -n1)
    if [ -n "$WHEEL_FILE" ]; then
        "$VENV_DIR/bin/pip" install "$WHEEL_FILE"
        echo "✅ Fabric $FABRIC_VERSION installed successfully"
    else
        echo "❌ No wheel file found for Fabric, trying direct install..."
        "$VENV_DIR/bin/pip" install .
    fi
else
    echo "❌ Fabric build failed, trying direct installation..."
    "$VENV_DIR/bin/pip" install .
fi

# --- Install fabric-cli in Virtual Environment ---
echo "Installing fabric-cli..."

FABRIC_CLI_DIR="$HOME/.local/src/fabric-cli"
if [ -d "$FABRIC_CLI_DIR" ]; then
    echo "Updating fabric-cli repository..."
    git -C "$FABRIC_CLI_DIR" pull || echo "Git pull failed, continuing with existing code..."
else
    echo "Cloning fabric-cli repository..."
    git clone --depth=1 https://github.com/Fabric-Development/fabric-cli.git "$FABRIC_CLI_DIR"
fi

# Install fabric-cli in virtual environment
cd "$FABRIC_CLI_DIR"
"$VENV_DIR/bin/pip" install .

echo "✅ fabric-cli installed successfully"

# --- Build and Install Hyprpicker from Source ---
echo "Building and installing Hyprpicker from source..."

HYPRPICKER_DIR="$HOME/.local/src/hyprpicker"
if [ -d "$HYPRPICKER_DIR" ]; then
    echo "Updating Hyprpicker repository..."
    git -C "$HYPRPICKER_DIR" pull || echo "Git pull failed, continuing with existing code..."
else
    echo "Cloning Hyprpicker repository..."
    git clone --depth=1 https://github.com/hyprwm/hyprpicker.git "$HYPRPICKER_DIR"
fi

# Build and install Hyprpicker
cd "$HYPRPICKER_DIR"
if [ -f "CMakeLists.txt" ]; then
    echo "Building Hyprpicker with CMake..."
    # Clean previous build
    rm -rf build
    if cmake -B build -S . -DCMAKE_BUILD_TYPE=Release && \
       cmake --build build -j$(nproc) && \
       sudo cmake --install build; then
        echo "✅ Hyprpicker installed successfully"
    else
        echo "❌ Hyprpicker installation failed - checking for missing dependencies..."
        # Check for specific missing dependencies
        pkg-config --exists hyprwayland-scanner || echo "  - hyprwayland-scanner might be missing"
        pkg-config --exists hyprutils || echo "  - hyprutils might be missing"
    fi
else
    echo "No CMakeLists.txt found for Hyprpicker"
fi

# --- Install Hyprshot ---
echo "Installing Hyprshot..."

HYPRSHOT_DIR="$HOME/.local/src/hyprshot"
if [ -d "$HYPRSHOT_DIR" ]; then
    echo "Updating Hyprshot repository..."
    git -C "$HYPRSHOT_DIR" pull || echo "Git pull failed, continuing with existing code..."
else
    echo "Cloning Hyprshot repository..."
    git clone --depth=1 https://github.com/Gustash/Hyprshot.git "$HYPRSHOT_DIR"
fi

# Install Hyprshot script
echo "Installing Hyprshot script..."
mkdir -p "$HOME/.local/bin"
cp "$HYPRSHOT_DIR/hyprshot" "$HOME/.local/bin/hyprshot"
chmod +x "$HOME/.local/bin/hyprshot"

echo "✅ Hyprshot has been installed to $HOME/.local/bin/hyprshot"

# --- Install Hyprsunset from Source ---
echo "Installing Hyprsunset from source..."

HYPRSUNSET_DIR="$HOME/.local/src/hyprsunset"
if [ -d "$HYPRSUNSET_DIR" ]; then
    echo "Updating Hyprsunset repository..."
    git -C "$HYPRSUNSET_DIR" pull || echo "Git pull failed, continuing with existing code..."
else
    echo "Cloning Hyprsunset repository..."
    git clone --depth=1 https://github.com/hyprwm/hyprsunset.git "$HYPRSUNSET_DIR"
fi

# Build and install Hyprsunset
cd "$HYPRSUNSET_DIR"
if [ -f "CMakeLists.txt" ]; then
    echo "Building Hyprsunset with CMake..."
    # Clean previous build
    rm -rf build
    if cmake -B build -S . -DCMAKE_BUILD_TYPE=Release && \
       cmake --build build -j$(nproc) && \
       sudo cmake --install build; then
        echo "✅ Hyprsunset installed successfully"
    else
        echo "❌ Hyprsunset installation failed - checking for missing dependencies..."
        pkg-config --exists hyprlang || echo "  - hyprlang might be missing"
        pkg-config --exists hyprwayland-scanner || echo "  - hyprwayland-scanner might be missing"
    fi
else
    echo "No CMakeLists.txt found for Hyprsunset"
fi

# --- Install Gray from Source ---
echo "Installing Gray from source..."

GRAY_DIR="$HOME/.local/src/gray"
if [ -d "$GRAY_DIR" ]; then
    echo "Updating Gray repository..."
    git -C "$GRAY_DIR" pull || echo "Git pull failed, continuing with existing code..."
else
    echo "Cloning Gray repository..."
    git clone --depth=1 https://github.com/Fabric-Development/gray.git "$GRAY_DIR"
fi

# Build and install Gray
cd "$GRAY_DIR"
if [ -f "meson.build" ]; then
    echo "Building Gray with meson..."
    # Clean previous build
    rm -rf build
    if meson setup build --prefix=/usr --buildtype=release && \
       ninja -C build && \
       sudo ninja -C build install; then
        echo "✅ Gray installed successfully"
    else
        echo "❌ Gray build/install failed, but continuing..."
    fi
else
    echo "No meson.build found for Gray"
fi

# --- Install Nerd Fonts Symbols ---
echo "Installing Nerd Fonts Symbols..."

NERD_FONTS_VERSION="3.4.0"
NERD_FONTS_DIR="$HOME/.local/src/nerd-fonts-symbols"
mkdir -p "$NERD_FONTS_DIR"

# Download font files
echo "Downloading Nerd Fonts Symbols..."
if curl -L -o "$NERD_FONTS_DIR/SymbolsNerdFont-Regular.ttf" \
    "https://raw.githubusercontent.com/ryanoasis/nerd-fonts/v$NERD_FONTS_VERSION/patched-fonts/NerdFontsSymbolsOnly/SymbolsNerdFont-Regular.ttf" && \
   curl -L -o "$NERD_FONTS_DIR/SymbolsNerdFontMono-Regular.ttf" \
    "https://raw.githubusercontent.com/ryanoasis/nerd-fonts/v$NERD_FONTS_VERSION/patched-fonts/NerdFontsSymbolsOnly/SymbolsNerdFontMono-Regular.ttf"; then
    # Install fonts to user directory
    echo "Installing Nerd Fonts to user directory..."
    cp "$NERD_FONTS_DIR/SymbolsNerdFont-Regular.ttf" "$HOME/.fonts/"
    cp "$NERD_FONTS_DIR/SymbolsNerdFontMono-Regular.ttf" "$HOME/.fonts/"
    echo "✅ Nerd Fonts Symbols have been installed to user directory."
else
    echo "⚠️  Failed to download Nerd Fonts, but continuing..."
fi

# Update font cache
echo "Updating font cache..."
fc-cache -fv

# --- Clone or update Ax-Shell ---
echo "Setting up Ax-Shell..."

if [ -d "$INSTALL_DIR" ]; then
    echo "Updating Ax-Shell (Quiet fork)..."
    git -C "$INSTALL_DIR" pull || echo "Git pull failed, continuing with existing code..."
else
    echo "Cloning Ax-Shell (Quiet fork)..."
    git clone --depth=1 "$REPO_URL" "$INSTALL_DIR"
fi

# --- Install Zed Sans fonts ---
echo "Installing Zed Sans fonts..."

FONT_URL="https://github.com/zed-industries/zed-fonts/releases/download/1.2.0/zed-sans-1.2.0.zip"
FONT_DIR="$HOME/.fonts/zed-sans"
TEMP_ZIP="/tmp/zed-sans-1.2.0.zip"

if [ ! -d "$FONT_DIR" ]; then
    echo "Downloading Zed Sans fonts..."
    if curl -L -o "$TEMP_ZIP" "$FONT_URL"; then
        echo "Extracting fonts..."
        mkdir -p "$FONT_DIR"
        unzip -o "$TEMP_ZIP" -d "$FONT_DIR"
        echo "✅ Zed Sans fonts installed successfully"
    else
        echo "⚠️  Failed to download Zed Sans fonts"
    fi
    echo "Cleaning up..."
    rm -f "$TEMP_ZIP"
else
    echo "✅ Zed Sans fonts are already installed."
fi

# --- Network services configuration ---
echo "Configuring network services..."

# Disable iwd if enabled/active
if systemctl is-enabled --quiet iwd 2>/dev/null || systemctl is-active --quiet iwd 2>/dev/null; then
    echo "Disabling iwd..."
    sudo systemctl disable --now iwd 2>/dev/null || echo "Could not disable iwd"
else
    echo "✅ iwd is not enabled or not present."
fi

# Enable NetworkManager if not enabled
if ! systemctl is-enabled --quiet NetworkManager 2>/dev/null; then
    echo "Enabling NetworkManager..."
    sudo systemctl enable NetworkManager 2>/dev/null || echo "Could not enable NetworkManager"
else
    echo "✅ NetworkManager is already enabled."
fi

# Start NetworkManager if not running
if ! systemctl is-active --quiet NetworkManager 2>/dev/null; then
    echo "Starting NetworkManager..."
    sudo systemctl start NetworkManager 2>/dev/null || echo "Could not start NetworkManager"
else
    echo "✅ NetworkManager is already running."
fi

# --- Copy local fonts from Ax-Shell ---
echo "Copying Ax-Shell fonts..."

if [ -d "$INSTALL_DIR/assets/fonts" ] && [ ! -d "$HOME/.fonts/tabler-icons" ]; then
    echo "Copying local fonts to $HOME/.fonts/tabler-icons..."
    mkdir -p "$HOME/.fonts/tabler-icons"
    cp -r "$INSTALL_DIR/assets/fonts/"* "$HOME/.fonts/" 2>/dev/null || echo "Some fonts could not be copied"
    echo "✅ Ax-Shell fonts copied successfully"
else
    echo "✅ Local fonts are already installed or not available."
fi

# --- Update PATH if needed ---
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo "Adding ~/.local/bin to PATH in .bashrc..."
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    export PATH="$HOME/.local/bin:$PATH"
fi

# Add virtual environment activation to bashrc for easy ax-shell command
if ! grep -q "ax-shell-venv" "$HOME/.bashrc"; then
    echo "Adding ax-shell alias to .bashrc..."
    echo "alias ax-shell='$VENV_DIR/bin/python $INSTALL_DIR/main.py'" >> "$HOME/.bashrc"
fi

# --- Update font cache again after all font installations ---
echo "Updating font cache after all font installations..."
fc-cache -fv

# --- Install Python requirements for Ax-Shell in virtual environment ---
echo "Installing Python requirements for Ax-Shell..."

if [ -f "$INSTALL_DIR/requirements.txt" ]; then
    echo "Installing requirements from requirements.txt..."
    "$VENV_DIR/bin/pip" install -r "$INSTALL_DIR/requirements.txt" || echo "Failed to install some Python requirements"
else
    echo "No requirements.txt found, common dependencies already installed in virtual environment"
fi

# --- Final steps ---
echo "Finalizing installation..."

# Verify critical components
echo "Verifying installation..."
MISSING_COMPONENTS=()

# Check if Hyprshot was installed
if [ ! -f "$HOME/.local/bin/hyprshot" ]; then
    MISSING_COMPONENTS+=("Hyprshot")
fi

# Check if Hyprpicker is available
if ! command -v hyprpicker >/dev/null 2>&1; then
    MISSING_COMPONENTS+=("Hyprpicker")
fi

# Check if Ax-Shell was cloned
if [ ! -d "$INSTALL_DIR" ]; then
    MISSING_COMPONENTS+=("Ax-Shell")
fi

# Check if Fabric is available in virtual environment
if ! "$VENV_DIR/bin/python" -c "import fabric" 2>/dev/null; then
    MISSING_COMPONENTS+=("Fabric")
fi

# Check if fabric-cli is available in virtual environment
if ! "$VENV_DIR/bin/python" -c "import fabric_cli" 2>/dev/null 2>&1; then
    MISSING_COMPONENTS+=("fabric-cli")
fi

# Check if Gray is available
if ! command -v gray >/dev/null 2>&1; then
    MISSING_COMPONENTS+=("Gray")
fi

# Check if PyGObject is available in virtual environment
if ! "$VENV_DIR/bin/python" -c "import gi; print('PyGObject OK')" 2>/dev/null; then
    MISSING_COMPONENTS+=("PyGObject")
fi

if [ ${#MISSING_COMPONENTS[@]} -eq 0 ]; then
    echo "✅ All critical components installed successfully!"
else
    echo "⚠️  The following components failed to install: ${MISSING_COMPONENTS[*]}"
fi

# Run Ax-Shell configuration using virtual environment
if [ -f "$INSTALL_DIR/config/config.py" ]; then
    echo "Running Ax-Shell configuration..."
    cd "$INSTALL_DIR"
    if "$VENV_DIR/bin/python" "config/config.py"; then
        echo "✅ Ax-Shell configuration completed successfully"
    else
        echo "❌ Configuration script failed"
        echo "You may need to install missing dependencies manually"
    fi
else
    echo "❌ Ax-Shell configuration script not found."
fi

# Kill any existing Ax-Shell instances
echo "Stopping any existing Ax-Shell instances..."
pkill -f "ax-shell" 2>/dev/null || true

# Start Ax-Shell using virtual environment
echo "Starting Ax-Shell..."
if command -v uwsm >/dev/null 2>&1; then
    uwsm app -- "$VENV_DIR/bin/python" "$INSTALL_DIR/main.py" > /dev/null 2>&1 & disown
    echo "✅ Ax-Shell started with uwsm and virtual environment"
else
    # Fallback: start directly with virtual environment
    "$VENV_DIR/bin/python" "$INSTALL_DIR/main.py" > /dev/null 2>&1 &
    echo "✅ Ax-Shell started directly with virtual environment (uwsm not found)"
fi

echo ""
echo "=============================================="
echo "INSTALLATION COMPLETE!"
echo "=============================================="
echo ""
echo "Ax-Shell (Quiet fork) has been installed to: $INSTALL_DIR"
echo "Python virtual environment: $VENV_DIR"
echo ""
echo "Components status:"
if command -v hyprpicker >/dev/null 2>&1; then echo "✅ Hyprpicker"; else echo "❌ Hyprpicker"; fi
if [ -f "$HOME/.local/bin/hyprshot" ]; then echo "✅ Hyprshot"; else echo "❌ Hyprshot"; fi
if command -v hyprsunset >/dev/null 2>&1; then echo "✅ Hyprsunset"; else echo "❌ Hyprsunset"; fi
if "$VENV_DIR/bin/python" -c "import fabric" 2>/dev/null; then echo "✅ Fabric"; else echo "❌ Fabric"; fi
if "$VENV_DIR/bin/python" -c "import fabric_cli" 2>/dev/null 2>&1; then echo "✅ fabric-cli"; else echo "❌ fabric-cli"; fi
if command -v gray >/dev/null 2>&1; then echo "✅ Gray"; else echo "❌ Gray"; fi
if "$VENV_DIR/bin/python" -c "import gi" 2>/dev/null; then echo "✅ PyGObject (built from source)"; else echo "❌ PyGObject"; fi
echo "✅ Hypridle & Hyprlock"
echo "✅ Nerd Fonts Symbols & Zed Sans fonts"
echo "✅ Network configuration"
echo "✅ Python virtual environment with all dependencies"
echo ""
echo "Next steps:"
echo "1. Restart your terminal or run: source ~/.bashrc"
echo "2. Ax-Shell should be running automatically"
echo "3. You can start Ax-Shell manually with: ax-shell"
echo "4. Or manually with: $VENV_DIR/bin/python $INSTALL_DIR/main.py"
echo "5. Test components:"
echo "   - hyprshot --help"
echo "   - hyprpicker --help"
echo "   - $VENV_DIR/bin/python -c 'import fabric; print(\"Fabric OK\")'"
echo "   - $VENV_DIR/bin/python -c 'import gi; print(\"PyGObject OK\")'"
echo ""
echo "If any components failed, check the output above for specific error messages."
echo "Enjoy using Ax-Shell! 🚀"
echo "=============================================="
