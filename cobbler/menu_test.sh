#!/bin/bash

# create fake kernel and initrd
sudo touch /root/vmlinuz
sudo touch /root/initrd


cobbler menu add \
        --name packer \
        --display-name "Packer images"

cobbler distro add \
        --name packer-x86_64 \
        --arch x86_64 \
        --kernel /root/vmlinuz \
        --kernel-options 'debug pxe_shell=yes' \
        --initrd /root/initrd \
        --boot-loaders 'grub ipxe' \

cobbler profile add \
        --name packer-x86_64 \
        --distro packer-x86_64 \
        --server '<<inherit>>' \
        --boot-loaders 'grub ipxe' \
        --enable-menu 1 \
        --menu packer

cobbler profile add \
        --name packer-centos-8.4-x86_64 \
        --parent packer-x86_64 \
        --server '<<inherit>>' \
        --boot-loaders 'grub ipxe' \
        --enable-menu 1 \
        --menu packer

cobbler system add \
        --name test \
        --profile packer-centos-8.4-x86_64 \
        --server '<<inherit>>' \
        --boot-loaders 'grub ipxe' \
        --enable-ipxe 0 \
        --netboot 1
