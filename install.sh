#!/bin/bash
# =============================================================
# frok — Arch Linux Dotfiles Installer
# Auto-detects hardware, installs everything, deploys configs
# Works on fresh minimal Arch (base + git + networkmanager + grub)
# =============================================================

DOTDIR="$(cd "$(dirname "$0")" && pwd)"

BLUE='\033[1;34m'
GREEN='\033[1;32m'
RED='\033[1;31m'
CYAN='\033[1;36m'
NC='\033[0m'

info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
ok()    { echo -e "${GREEN}[ OK ]${NC} $1"; }
warn()  { echo -e "${RED}[WARN]${NC} $1"; }
step()  { echo -e "\n${CYAN}=== $1 ===${NC}"; }

detect_hardware() {
    step "Detecting Hardware"

    if grep -q "AuthenticAMD" /proc/cpuinfo; then
        CPU="amd"; UCODE="amd-ucode"; PSTATE="amd_pstate=active"
    elif grep -q "GenuineIntel" /proc/cpuinfo; then
        CPU="intel"; UCODE="intel-ucode"; PSTATE="intel_pstate=active"
    else
        CPU="unknown"; UCODE=""; PSTATE=""
    fi
    info "CPU: $CPU — $(grep 'model name' /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)"

    GPU_INFO=$(lspci 2>/dev/null | grep -i "vga\|3d\|display")
    if echo "$GPU_INFO" | grep -qi "nvidia"; then
        GPU="nvidia"; GPU_MODULE="nvidia nvidia_modeset nvidia_uvm nvidia_drm"
        GPU_PACKAGES="nvidia nvidia-utils lib32-nvidia-utils nvidia-settings"
        GPU_GRUB="nvidia_drm.modeset=1"
        GPU_ENV="env = LIBVA_DRIVER_NAME,nvidia\nenv = __GLX_VENDOR_LIBRARY_NAME,nvidia"
    elif echo "$GPU_INFO" | grep -qi "amd\|ati\|radeon"; then
        GPU="amd"; GPU_MODULE="amdgpu"
        GPU_PACKAGES="vulkan-radeon lib32-vulkan-radeon lib32-mesa"
        GPU_GRUB="amdgpu.dc=1 amdgpu.ppfeaturemask=0xffffffff"
        GPU_ENV=""
    elif echo "$GPU_INFO" | grep -qi "intel"; then
        GPU="intel"; GPU_MODULE="i915"
        GPU_PACKAGES="vulkan-intel lib32-vulkan-intel lib32-mesa intel-media-driver"
        GPU_GRUB=""; GPU_ENV=""
    else
        GPU="unknown"; GPU_MODULE=""; GPU_PACKAGES=""; GPU_GRUB=""; GPU_ENV=""
    fi
    info "GPU: $GPU"

    [ -d /sys/block/nvme0n1 ] && STORAGE="nvme" || STORAGE="disk"
    info "Storage: $STORAGE"

    ls /sys/class/power_supply/BAT* &>/dev/null && IS_LAPTOP=true || IS_LAPTOP=false
    info "Laptop: $IS_LAPTOP"

    RAM_GB=$(free -g | awk '/Mem/{print $2}')
    info "RAM: ${RAM_GB}GB"

    ok "Hardware detection complete"
}

scan_drivers() {
    step "Scanning & Installing Drivers"

    if ! ping -c 1 -W 3 archlinux.org &>/dev/null; then
        warn "No internet — skipping"; return 0
    fi
    ok "Internet connected"

    info "Optimizing mirrors..."
    sudo reflector --latest 10 --protocol https --sort rate --save /etc/pacman.d/mirrorlist 2>/dev/null || true

    info "GPU drivers: $GPU_PACKAGES"
    [ -n "$GPU_PACKAGES" ] && sudo pacman -S --needed --noconfirm $GPU_PACKAGES 2>/dev/null || true

    WIFI=$(lspci 2>/dev/null | grep -i "network\|wireless\|wi-fi")
    if echo "$WIFI" | grep -qi "broadcom"; then
        info "Broadcom WiFi — installing driver"
        yay -S --needed --noconfirm broadcom-wl-dkms 2>/dev/null || true
    fi
    ok "WiFi: $(echo "$WIFI" | head -1 | cut -d: -f3 | xargs 2>/dev/null || echo 'None')"

    if lsusb 2>/dev/null | grep -qi "bluetooth" || lspci 2>/dev/null | grep -qi "bluetooth"; then
        sudo pacman -S --needed --noconfirm bluez bluez-utils blueman 2>/dev/null || true
        sudo systemctl enable --now bluetooth 2>/dev/null || true
        ok "Bluetooth configured"
    fi

    sudo pacman -S --needed --noconfirm pipewire pipewire-alsa pipewire-jack pipewire-pulse wireplumber alsa-utils pamixer 2>/dev/null || true
    ok "Audio configured"

    if [ "$IS_LAPTOP" = true ]; then
        sudo pacman -S --needed --noconfirm libinput tlp acpi brightnessctl wlsunset 2>/dev/null || true
        sudo systemctl enable tlp 2>/dev/null || true
        ok "Laptop power management configured"
    fi

    if lsusb 2>/dev/null | grep -qi "printer\|canon\|epson\|hp\|brother"; then
        sudo pacman -S --needed --noconfirm cups cups-pdf 2>/dev/null || true
        sudo systemctl enable cups 2>/dev/null || true
        ok "Printer support installed"
    fi

    if lspci | grep -qi "thunderbolt"; then
        sudo pacman -S --needed --noconfirm bolt 2>/dev/null || true
        ok "Thunderbolt support"
    fi

    if lsusb 2>/dev/null | grep -qi "fingerprint\|goodix\|elan.*finger"; then
        sudo pacman -S --needed --noconfirm fprintd 2>/dev/null || true
        ok "Fingerprint support"
    fi

    sudo pacman -S --needed --noconfirm linux-firmware fwupd 2>/dev/null || true
    sudo fwupdmgr refresh 2>/dev/null || true

    ok "Driver scan complete"
}

install_packages() {
    step "Installing Packages"

    sudo sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf

    # base-devel FIRST
    info "base-devel + fonts..."
    sudo pacman -S --needed --noconfirm base-devel noto-fonts ttf-jetbrains-mono-nerd otf-font-awesome ttf-nerd-fonts-symbols-common 2>/dev/null || true

    # yay
    if ! command -v yay &>/dev/null; then
        info "Installing yay..."
        rm -rf /tmp/yay-bin
        git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
        (cd /tmp/yay-bin && makepkg -si --noconfirm)
        rm -rf /tmp/yay-bin
    fi
    ok "yay ready"

    # Core packages — install in small groups so one failure doesn't skip all
    info "Shell + tools..."
    sudo pacman -S --needed --noconfirm git zsh starship neovim nano fastfetch htop pacman-contrib imagemagick openssh 2>/dev/null || true

    info "Hyprland + desktop..."
    sudo pacman -S --needed --noconfirm hyprland hyprpaper sddm kitty rofi mako brightnessctl 2>/dev/null || true

    info "File managers + apps..."
    sudo pacman -S --needed --noconfirm thunar thunar-archive-plugin file-roller gvfs imv nsxiv 2>/dev/null || true

    info "Network + bluetooth..."
    sudo pacman -S --needed --noconfirm network-manager-applet bluez bluez-utils blueman openresolv wireguard-tools 2>/dev/null || true

    info "Audio..."
    sudo pacman -S --needed --noconfirm pipewire pipewire-alsa pipewire-jack pipewire-pulse wireplumber alsa-utils pamixer 2>/dev/null || true

    info "Screenshots + clipboard..."
    sudo pacman -S --needed --noconfirm grim slurp wl-clipboard 2>/dev/null || true

    info "Themes + fonts..."
    sudo pacman -S --needed --noconfirm noto-fonts ttf-jetbrains-mono-nerd otf-font-awesome ttf-nerd-fonts-symbols-common catppuccin-gtk-theme-mocha papirus-icon-theme gnome-themes-extra 2>/dev/null || true

    info "Qt + display tools..."
    sudo pacman -S --needed --noconfirm nwg-look nwg-displays qt6ct qt6-svg qt6-declarative qt6-5compat 2>/dev/null || true

    info "Boot + system..."
    sudo pacman -S --needed --noconfirm grub efibootmgr zram-generator reflector $UCODE 2>/dev/null || true

    info "Dev tools..."
    sudo pacman -S --needed --noconfirm docker docker-compose kubectl nodejs rust python-pip jdk-openjdk 2>/dev/null || true

    info "Laptop power..."
    [ "$IS_LAPTOP" = true ] && sudo pacman -S --needed --noconfirm tlp acpi wlsunset libinput 2>/dev/null || true

    # AUR packages — one at a time
    info "AUR packages..."
    AUR_PKGS=(
        ironbar-bin
        eww-git
        grimblast-git
        zen-browser-bin
        visual-studio-code-bin
        networkmanager-dmenu-git
        sddm-astronaut-theme
        illogical-impulse-basic
        illogical-impulse-hyprland
        illogical-impulse-audio
        illogical-impulse-backlight
        illogical-impulse-fonts-themes
        illogical-impulse-portal
        illogical-impulse-python
        illogical-impulse-toolkit
        illogical-impulse-widgets
        illogical-impulse-screencapture
        illogical-impulse-bibata-modern-classic-bin
        illogical-impulse-quickshell-git
        aylurs-gtk-shell
        uwsm
        hyprpolkitagent
        minikube
        bun
    )

    for pkg in "${AUR_PKGS[@]}"; do
        if ! pacman -Q "$pkg" &>/dev/null; then
            info "  $pkg..."
            yay -S --needed --noconfirm --answerdiff None --answerclean None "$pkg" 2>/dev/null || warn "  Failed: $pkg"
        fi
    done

    ok "Packages installed"
}

configure_system() {
    step "Configuring System"

    # mkinitcpio
    info "mkinitcpio (GPU: $GPU_MODULE)..."
    sudo tee /etc/mkinitcpio.conf > /dev/null << MKINIT
MODULES=($GPU_MODULE)
BINARIES=()
FILES=()
HOOKS=(base systemd autodetect microcode modconf kms block filesystems fsck)
COMPRESSION="lz4"
MKINIT
    sudo mkinitcpio -P

    # GRUB
    info "GRUB..."
    GRUB_PARAMS="loglevel=3 quiet nowatchdog nmi_watchdog=0 processor.ignore_ppc=1 $PSTATE $GPU_GRUB"
    sudo sed -i "s/GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT=\"$GRUB_PARAMS\"/" /etc/default/grub
    sudo grub-mkconfig -o /boot/grub/grub.cfg

    # Sysctl
    info "sysctl..."
    sudo tee /etc/sysctl.d/99-performance.conf > /dev/null << 'SYSCTL'
vm.swappiness = 100
vm.vfs_cache_pressure = 50
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5
kernel.nmi_watchdog = 0
SYSCTL
    sudo sysctl --system 2>/dev/null

    # TLP
    if [ "$IS_LAPTOP" = true ] && [ -f "$DOTDIR/system/tlp.conf" ]; then
        info "TLP..."
        sudo cp "$DOTDIR/system/tlp.conf" /etc/tlp.conf
        sudo tlp start 2>/dev/null || true
    fi

    # Zram
    info "zram..."
    sudo tee /etc/systemd/zram-generator.conf > /dev/null << 'ZRAM'
[zram0]
zram-size = ram / 2
compression-algorithm = zstd
ZRAM

    # Journal size limit
    sudo mkdir -p /etc/systemd/journald.conf.d
    sudo tee /etc/systemd/journald.conf.d/size.conf > /dev/null << 'JRNL'
[Journal]
SystemMaxUse=8M
JRNL

    # SDDM
    info "SDDM theme..."
    sudo tee /etc/sddm.conf > /dev/null << 'SDDM'
[Theme]
Current=sddm-astronaut-theme
SDDM

    # Services
    info "Services..."
    sudo systemctl enable NetworkManager 2>/dev/null || true
    sudo systemctl enable bluetooth 2>/dev/null || true
    sudo systemctl enable sddm 2>/dev/null || true
    sudo systemctl enable fstrim.timer 2>/dev/null || true
    sudo systemctl enable systemd-timesyncd 2>/dev/null || true
    [ "$IS_LAPTOP" = true ] && sudo systemctl enable tlp 2>/dev/null || true
    sudo systemctl disable docker.service docker.socket 2>/dev/null || true

    # Battery sudoers — auto-detect hardware type
    if [ "$IS_LAPTOP" = true ]; then
        info "Battery sudoers..."
        BAT=$(ls /sys/class/power_supply/ 2>/dev/null | grep BAT | head -n 1)
        if [ -n "$BAT" ]; then
            SUDOERS_RULES=""
            # ThinkPad thresholds
            if [ -f "/sys/class/power_supply/$BAT/charge_control_end_threshold" ]; then
                SUDOERS_RULES="$USER ALL=(ALL) NOPASSWD: /usr/bin/tee /sys/class/power_supply/$BAT/charge_control_*"
            # IdeaPad conservation mode
            elif [ -f "/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode" ]; then
                SUDOERS_RULES="$USER ALL=(ALL) NOPASSWD: /usr/bin/tee /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode"
            fi
            if [ -n "$SUDOERS_RULES" ]; then
                echo "$SUDOERS_RULES" | sudo tee /etc/sudoers.d/battery > /dev/null
                sudo chmod 440 /etc/sudoers.d/battery
            fi
        fi
    fi

    # Pacman sudoers (no password for updates)
    echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/pacman, /usr/bin/paccache" | sudo tee /etc/sudoers.d/pacman > /dev/null
    sudo chmod 440 /etc/sudoers.d/pacman

    ok "System configured"
}

deploy_configs() {
    step "Deploying Configs"

    mkdir -p "$HOME/.config"

    info "Hyprland..."
    cp -r "$DOTDIR/config/hypr" "$HOME/.config/"
    [ -n "$GPU_ENV" ] && echo -e "\n$GPU_ENV" >> "$HOME/.config/hypr/custom/env.conf"
    find "$HOME/.config/hypr" -name "*.sh" -exec chmod +x {} \; 2>/dev/null

    # Fix env.conf duplicates
    sort -u "$HOME/.config/hypr/custom/env.conf" -o "$HOME/.config/hypr/custom/env.conf"

    info "Ironbar..."
    cp -r "$DOTDIR/config/ironbar" "$HOME/.config/"
    chmod +x "$HOME"/.config/ironbar/scripts/*.sh 2>/dev/null
    echo "" > "$HOME/.config/ironbar/dynamic.css"

    info "EWW..."
    cp -r "$DOTDIR/config/eww" "$HOME/.config/"
    chmod +x "$HOME"/.config/eww/scripts/*.sh 2>/dev/null

    info "Kitty..."
    mkdir -p "$HOME/.config/kitty"
    cp -r "$DOTDIR/config/kitty/"* "$HOME/.config/kitty/" 2>/dev/null

    info "GTK theme..."
    mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"
    cp "$DOTDIR/config/gtk-3.0/settings.ini" "$HOME/.config/gtk-3.0/" 2>/dev/null
    cp "$DOTDIR/config/gtk-4.0/settings.ini" "$HOME/.config/gtk-4.0/" 2>/dev/null
    ln -sf /usr/share/themes/catppuccin-mocha-blue-standard+default/gtk-4.0/assets "$HOME/.config/gtk-4.0/assets" 2>/dev/null
    ln -sf /usr/share/themes/catppuccin-mocha-blue-standard+default/gtk-4.0/gtk.css "$HOME/.config/gtk-4.0/gtk.css" 2>/dev/null
    ln -sf /usr/share/themes/catppuccin-mocha-blue-standard+default/gtk-4.0/gtk-dark.css "$HOME/.config/gtk-4.0/gtk-dark.css" 2>/dev/null
    gsettings set org.gnome.desktop.interface gtk-theme "catppuccin-mocha-blue-standard+default" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface cursor-theme "Bibata-Modern-Classic" 2>/dev/null || true

    info "Starship + Fastfetch..."
    cp "$DOTDIR/config/starship.toml" "$HOME/.config/" 2>/dev/null
    cp -r "$DOTDIR/config/fastfetch" "$HOME/.config/" 2>/dev/null

    info "Zshrc..."
    cp "$DOTDIR/config/zshrc" "$HOME/.zshrc" 2>/dev/null

    info "Wallpaper..."
    mkdir -p "$HOME/Pictures/Wallpapers"
    cp "$DOTDIR/wallpapers/"* "$HOME/Pictures/Wallpapers/" 2>/dev/null || true

    # Auto-dim wallpaper if imagemagick is available
    WALLPAPER=$(ls "$HOME/Pictures/Wallpapers/" 2>/dev/null | grep -v "\-dim" | head -1)
    if [ -n "$WALLPAPER" ] && command -v magick &>/dev/null; then
        BASENAME="${WALLPAPER%.*}"
        EXT="${WALLPAPER##*.}"
        if [ ! -f "$HOME/Pictures/Wallpapers/${BASENAME}-dim.${EXT}" ]; then
            info "Dimming wallpaper..."
            magick "$HOME/Pictures/Wallpapers/$WALLPAPER" -brightness-contrast -40x0 "$HOME/Pictures/Wallpapers/${BASENAME}-dim.${EXT}"
        fi
        WALLPAPER="${BASENAME}-dim.${EXT}"
    fi

    # Hyprpaper config — auto-detect monitor
    if [ -n "$WALLPAPER" ]; then
        cat > "$HOME/.config/hypr/hyprpaper.conf" << HPCONF
ipc = on
preload = $HOME/Pictures/Wallpapers/$WALLPAPER
wallpaper = ,$HOME/Pictures/Wallpapers/$WALLPAPER
splash = false
HPCONF
        cat > "$HOME/.config/hypr/scripts/wallpaper.sh" << 'WPSCRIPT'
#!/bin/bash
killall hyprpaper 2>/dev/null
sleep 0.5
hyprpaper &
sleep 2
MONITOR=$(hyprctl monitors | grep "Monitor" | head -1 | awk '{print $2}')
WALLPAPER=$(ls ~/Pictures/Wallpapers/ | grep "\-dim" | head -1)
[ -z "$WALLPAPER" ] && WALLPAPER=$(ls ~/Pictures/Wallpapers/ | head -1)
hyprctl hyprpaper preload ~/Pictures/Wallpapers/$WALLPAPER
hyprctl hyprpaper wallpaper $MONITOR,~/Pictures/Wallpapers/$WALLPAPER
WPSCRIPT
        chmod +x "$HOME/.config/hypr/scripts/wallpaper.sh"
    fi

    # Set zsh as default shell
    if command -v zsh &>/dev/null; then
        chsh -s "$(which zsh)" 2>/dev/null || true
    fi

    ok "All configs deployed"
}

show_summary() {
    step "frok Setup Complete!"
    echo ""
    echo -e "  ${CYAN}Hardware${NC}"
    echo -e "  CPU:     $CPU ($UCODE)"
    echo -e "  GPU:     $GPU ($GPU_MODULE)"
    echo -e "  Storage: $STORAGE"
    echo -e "  RAM:     ${RAM_GB}GB"
    echo -e "  Laptop:  $IS_LAPTOP"
    echo ""
    echo -e "  ${GREEN}Reboot now:${NC} sudo reboot"
    echo ""
    echo -e "  ${CYAN}After reboot:${NC}"
    echo -e "  Login via SDDM -> Hyprland"
    echo -e "  Docker:  ${BLUE}workon${NC} / ${BLUE}workoff${NC}"
    echo -e "  Updates: click the pill in the bar"
    echo -e "  System:  ${BLUE}maintain${NC} / ${BLUE}cleanup${NC}"
    echo -e "  Drivers: ${BLUE}./install.sh --drivers${NC}"
    echo ""
    echo -e "  ${CYAN}Optional:${NC}"
    echo -e "  WireGuard: sudo mkdir -p /etc/wireguard && sudo nano /etc/wireguard/wg0.conf"
    echo -e "             sudo chmod 600 /etc/wireguard/wg0.conf"
    echo -e "             sudo nmcli con import type wireguard file /etc/wireguard/wg0.conf"
    echo ""
}

# ========== MAIN ==========
if [ "$1" = "--drivers" ]; then
    detect_hardware
    scan_drivers
    ok "Driver scan complete"
    exit 0
fi

echo ""
echo -e "${CYAN}+--------------------------------------+${NC}"
echo -e "${CYAN}|  frok — Arch Linux Dotfiles          |${NC}"
echo -e "${CYAN}|  Catppuccin Mocha + Arch Blue        |${NC}"
echo -e "${CYAN}+--------------------------------------+${NC}"
echo ""

detect_hardware
scan_drivers
install_packages
configure_system
deploy_configs
show_summary

