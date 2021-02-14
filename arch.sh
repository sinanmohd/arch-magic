echo "
░█████╗░██████╗░░█████╗░██╗░░██╗  ░██████╗░█████╗░██████╗░██╗██████╗░████████╗
██╔══██╗██╔══██╗██╔══██╗██║░░██║  ██╔════╝██╔══██╗██╔══██╗██║██╔══██╗╚══██╔══╝
███████║██████╔╝██║░░╚═╝███████║  ╚█████╗░██║░░╚═╝██████╔╝██║██████╔╝░░░██║░░░
██╔══██║██╔══██╗██║░░██╗██╔══██║  ░╚═══██╗██║░░██╗██╔══██╗██║██╔═══╝░░░░██║░░░
██║░░██║██║░░██║╚█████╔╝██║░░██║  ██████╔╝╚█████╔╝██║░░██║██║██║░░░░░░░░██║░░░
╚═╝░░╚═╝╚═╝░░╚═╝░╚════╝░╚═╝░░╚═╝  ╚═════╝░░╚════╝░╚═╝░░╚═╝╚═╝╚═╝░░░░░░░░╚═╝░░░"
pacman --noconfirm -Sy archlinux-keyring
loadkeys us
timedatectl set-ntp true
fdisk -l
echo "Where do you like to install Arch:"
read drive
cfdisk /dev/$drive 
echo "Enter the root partition:"
read partition
mkfs.ext4 /dev/$partition 
mount /dev/$partition /mnt

read -p "Format efi partition? WARNING!!! [y,n]:" answer
if [[ $answer = y ]] ; then
	echo "Enter EFI partition: "
	read efipartition
	mkfs.vfat -F 32 /dev/$efipartition
fi

read -p "Did you create home partition? [y,n]:" answer2
if [[ $answer2 = y ]] ; then
	mkdir /mnt/home
	fdisk -l
	echo "Enter home partition: "
	read homepartition
	read -p "Format home partition WARNING!!! [y.n]:" answer3
	if [[ $answer3 = y ]] ; then
		mkfs.ext4 /dev/$homepartition
	fi
	mount /dev/$homepartition /mnt/home
fi

pacstrap /mnt base base-devel linux linux-firmware
genfstab -U /mnt >> /mnt/etc/fstab

sed '1,/^#part2$/d' arch.sh > /mnt/arch_part2.sh
chmod +x /mnt/arch_part2.sh
arch-chroot /mnt ./arch_part2.sh
exit 

#part2
ln -sf /usr/share/zoneinfo/Asia/Kolkata /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=us" > /etc/vconsole.conf
echo "Enter Hostname: "
read hostname
echo $hostname > /etc/hostname
echo "127.0.0.1       localhost" >> /etc/hosts
echo "::1             localhost" >> /etc/hosts
echo "127.0.1.1       $hostname.localdomain $hostname" >> /etc/hosts
mkinitcpio -P
passwd
pacman --noconfirm -S grub efibootmgr os-prober
fdisk -l
echo "Enter EFI partition:"
read efipartition
mkdir /boot/efi
mount /dev/$efipartition /boot/efi
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
pacman --noconfirm -S linux-headers doas pipewire pipewire-pulse alsa-utils pamixer vim wget git connman iwd
pacman --noconfirm -Rns sudo

cpu=$(cat /proc/cpuinfo | grep -m1 'vendor' | cut -d" " -f 2)
if [[ $cpu = GenuineIntel ]] ; then
	pacman --noconfirm -S intel-ucode
elif [[ $cpu = AuthenticAMD ]] ; then
	pacman --noconfirm -S amd-ucode
fi

systemctl enable connman.service
systemctl enable iwd
echo "permit :wheel" > /etc/doas.conf
echo "Enter Username:"
read username
useradd -m -g wheel $username
passwd $username
echo "alias sudo='doas'" >> /home/$username/.bashrc
echo "Pre-Installation Finish Reboot now"
