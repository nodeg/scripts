#!/bin/bash

# create fake kernel and initrd
sudo touch /root/vmlinuz
sudo touch /root/initrd

cobbler menu add \
        --name test \
        --display-name "Test menu"

cobbler distro add \
        --name test-x86_64 \
        --arch x86_64 \
        --kernel /root/vmlinuz \
        --initrd /root/initrd \

cobbler profile add \
        --name test-x86_64 \
        --distro test-x86_64 \
        --enable-menu 1 \
        --menu test

cobbler system add \
        --name test \
        --profile test-x86_64 \
