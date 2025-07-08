reboot_loop() {
  if [[ -f /mnt/ramdisk/reboot-flag ]]; then
    umount -R /mnt/ramdisk
    reboot
  else
    sleep 1
    reboot_loop
  fi
}

reboot_loop
