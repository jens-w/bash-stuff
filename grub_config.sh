#!/bin/bash
now=$(date +"%Y-%m-%d_%H%M%S")
echo ".:: mount /boot just in case it wasn't already"
mount /boot
echo ".:: copying grub.cfg"
cp /boot/grub/grub.cfg /boot/grub/grub.cfg_$now
echo ".:: generating new grub.cfg"
grub-mkconfig -o /boot/grub/grub.cfg
echo ".:: unmounting /boot"
umount /boot