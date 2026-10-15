#!/bin/bash
qemu-system-x86_64 \
    -enable-kvm \
    -cpu host \
    -smp 8 \
    -m 8G \
    -drive file=disk.qcow2,if=virtio,format=qcow2 \
    -device virtio-vga-gl \
    -display gtk,gl=on \
    -netdev user,id=nat0 \
    -device virtio-net-pci,netdev=nat0 \
    -netdev bridge,id=lab0,br=br0 \
    -device virtio-net-pci,netdev=lab0,mac=52:54:00:aa:00:10
