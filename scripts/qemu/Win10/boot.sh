#!/bin/bash
qemu-system-x86_64 -enable-kvm -cpu host -smp 4 -m 6G -machine q35 \
  -drive file=win10.qcow2,if=none,id=d0,format=qcow2 \
  -device ich9-ahci,id=ahci -device ide-hd,drive=d0,bus=ahci.0 \
  -cdrom win10.iso -boot d \
  -netdev bridge,id=n0,br=br0 \
  -device e1000e,netdev=n0,mac=52:54:00:aa:00:20 \
  -device qxl-vga -display gtk -usb -device usb-tablet
