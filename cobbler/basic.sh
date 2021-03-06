#!/bin/bash

# create fake kernel and initrd
sudo touch /root/vmlinuz
sudo touch /root/initrd

cobbler distro add \
        --name dtest \
        --arch x86_64 \
        --kernel /root/vmlinuz \
        --initrd /root/initrd \

cobbler profile add \
        --name ptest \
        --distro dtest \

cobbler profile add \
        --name ptes2 \
        --parent ptest \

cobbler system add \
        --name stest \
        --profile ptest \
