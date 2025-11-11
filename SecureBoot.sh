# Install Prerequisites
sudo pacman -S --needed -noconfirm efibootmgr sbsigntools mokutil sbctl grub

sudo sbctl create-keys
sudo sbctl enroll-keys --microsoft
sudo sbctl verify
# use sudo sbctl sign -s for every unsigned item
sudo sbctl sign -s /boot/EFI/BOOT/BOOTX64.EFI
sudo sbctl sign -s /boot/grub/x84_64-efi/core.efi
sudo sbctl sign -s /boot/grub/x86_64-efi/grub.efi
sudo sbctl sign -s /boot/vmlinuz-linux

sudo sbctl status
sudo sbctl verify
echo "Use sudo sbctl sign -s for every unsigned item"
