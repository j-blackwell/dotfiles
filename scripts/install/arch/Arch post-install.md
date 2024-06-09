# Arch post-install
This is a reference guide for post-install Arch.
Losely based off the [General recommendations](https://wiki.archlinux.org/title/General_recommendations).

## Terminal tools
``` sh
pacman -S vim foot man git
```


## Users

### Add
Add users and add them to the `wheel` group (which will then allow sudo commands)

``` sh
useradd -m james
passwd james
usermod -aG wheel james
```

### Sudoers

Edit the sudoers file using `visudo`. Uncomment the following line: `# %wheel ALL=(ALL:ALL) NOPASSWD: ALL`

``` sh
EDITOR=vim visudo
```

## Drives

### Updating `fstab`
If another drive has been mounted and you need to update `fstab`

``` sh
pacman -S arch-install-scripts
genfstab -U /mnt >> /etc/fstab
pacman -Rs arch-install-scripts
```

### Modify ownership
If a home directory has been copied from another drive, update the user permissions:

``` sh
chown james -R /home/james
```

## Packages 

### yay

Setup the cli for interfacing with the AUR, yay.

``` sh
pacman -Sy --needed git base-devel
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin
makepkg -si
cd ..
rm -rf ./yay-bin
```

### 32bit

Allow 32bit applications by uncommenting the `[multilib]` section of the pacman config.

``` sh
vim /etc/pacman.conf
```

### system upgrade

Then run a full system upgrade.
``` sh
pacman -Syu
```

## Graphics

Setup wayland, greetd, xwayland and sway.

``` sh
pacman -S --needed wayland
pacman -S greetd-tuigreet sway swaylock swayidle swaybg xorg-xwayland
systemctl enable greetd.service
```

## Monitors

desktop monitors follow the following configuration

``` sh
pacman -S wlr-randr
wlr-randr --output DP-1 --mode 1920x1080@165.003006 --pos 0,0 --rotate normal --output HDMI-A-1 --mode 1920x1080 --pos 1920,0
```

Create a `systemd` service to run the script every boot.

``` sh
sudo vim /etc/systemd/system/set_display.service
```

Setting the contents to be:

```
[Unit]
Description=Set display configuration with wlr-randr
After=graphical.target

[Service]
ExecStart=/home/james/code/dotfiles/scripts/install/set_display.sh
Restart=on-failure

[Install]
WantedBy=graphical.target
```

Then start and enable the service.

``` sh
sudo systemctl enable set_display.service && sudo systemctl start set_display.service
```

## SSH

Allow ssh over the network.

``` sh
sudo pacman -S openssh
systemctl start sshd.service && systemctl enable sshd.service
ip -br a | grep UP # grab the <ip_address> of form 192.168.x.x
```
