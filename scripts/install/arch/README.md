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

Setup xorg, greetd and i3.

``` sh
pacman -S greetd-tuigreet i3 feh
systemctl enable greetd.service
```

Start i3 upon sign-in by modifying the `greetd` service.

``` sh
vim /etc/greetd/config.toml
```

``` toml
[default_session]
command = "tuigreet --cmd i3 --power-shutdown 'sudo systemctl poweroff' --asterisks --time --remember --user-menu"
user=james
```


## SSH

Allow ssh over the network.

``` sh
sudo pacman -S openssh
systemctl start sshd.service && systemctl enable sshd.service
ip -br a | grep UP # grab the <ip_address> of form 192.168.x.x
```
