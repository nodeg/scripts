#!/bin/sh

cobbler menu add \
        --name packer \
        --display-name "Packer images"

cobbler distro add \
        --name packer-x86_64 \
        --arch x86_64 \
        --kernel /root/vmlinuz \
        --kernel-options 'debug pxe_shell=yes' \
        --initrd /root/pxeagent.gz \
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
        --kernel-options 'pxe_shell=yes pxe_script=http://${http_server}/cblr/svc/op/autoinstall/system/test' \
        --mac 52:54:00:aa:aa:22 \
        --autoinstall packer.sh \
        --autoinstall-meta 'disk=/dev/sda image=esxi-6.7.0-u3-x86_64-v1.gz' \
        --enable-ipxe 0 \
        --netboot 1
