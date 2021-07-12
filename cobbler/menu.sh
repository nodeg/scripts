#!/bin/bash

# create fake kernel and initrd
sudo touch /root/vmlinuz
sudo touch /root/initrd

cobbler menu add \
        --name mtest \
        --display-name "Test menu"

cobbler distro add \
        --name dtest \
        --arch x86_64 \
        --kernel /root/vmlinuz \
        --initrd /root/initrd \

cobbler profile add \
        --name ptest \
        --distro dtest \
        --enable-menu 1 \
        --menu mtest

cobbler profile add \
        --name ptest2 \
        --parent ptest \
        --enable-menu 1 \
        --menu mtest

cobbler system add \
        --name stest \
        --profile ptest \
