# Arch Setup & Post-Install

This is a reference guide and automation suite for setting up an Arch Linux system with these dotfiles.

## Manual Steps (Prior to Setup)

### 1. Terminal Tools
```bash
pacman -S vim man git
```

### 2. User Management
Add your user and add them to the `wheel` group.
```bash
useradd -m james
passwd james
usermod -aG wheel james
```

### 3. Sudoers
Edit the sudoers file using `visudo` and uncomment: `%wheel ALL=(ALL:ALL) NOPASSWD: ALL`
```bash
EDITOR=vim visudo
```

### 4. GRUB
Change `GRUB_TIMEOUT_STYLE` to "hidden" in `/etc/default/grub`.
```bash
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

### 5. 32-bit & Pacman
Uncomment `[multilib]` in `/etc/pacman.conf` and add `ILoveCandy`.

---

## Automation

To set up the system, run:

```bash
./setup/bootstrap.sh
```

This will:
1. Install an AUR helper (`paru` or `yay`).
2. Install categorized packages (Core, GUI, Dev, Apps).
3. Enable essential system services.
4. Stow all modules in this repository.
