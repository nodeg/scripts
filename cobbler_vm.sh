#!/bin/bash
# shellcheck disable=SC2068,SC2086
# A simple shell script to improve testing Cobbler in e.g. a VM
# Tested with openSUSE Tumbleweed
# Author: Dominik Gedon (dgedon@suse.de)
# -------------------------------------------------------------

HOST_ISOS="$HOME/host_isos"
MOUNTPOINT="/mnt2"

mount_vm_dirs () {
    if [ ! -e $MOUNTPOINT ]; then
        mkdir $MOUNTPOINT
    fi

    if [ ! -e ~/host_isos ]; then
        mkdir ~/host_isos
    fi

    echo "$MOUNTPOINT already mounted. Unmounting"
    if mount | grep $MOUNTPOINT; then
        sudo umount $MOUNTPOINT
    fi

    echo "Mounting host ISO directory to $HOST_ISOS and distro ISO to $MOUNTPOINT"
    sudo mount -t 9p -o trans=virtio,version=9p2000.L /mnt $HOST_ISOS
    sudo mount -t iso9660 -o loop,ro $2 $MOUNTPOINT
}

mount_dirs () {
    if [ ! -e $MOUNTPOINT ]; then
        mkdir $MOUNTPOINT
    fi

    echo "$MOUNTPOINT already mounted. Unmounting"
    if mount | grep $MOUNTPOINT; then
        sudo umount $MOUNTPOINT
    fi

    echo "Mounting ISO $2 to $MOUNTPOINT"
    sudo mount -t iso9660 -o loop,ro $2 $MOUNTPOINT
}

clone_cobbler () {
    if [ ! -e ~/cobbler_test ]; then
        if ! which git > /dev/null; then
            echo "git not found. Installing it."
            sudo zypper install -y git
        fi
        git clone https://github.com/cobbler/cobbler.git ~/cobbler_test
    fi
}

install_deps () {
    echo "Installing dependencies"
    sudo zypper install -y python3 python3-cheetah python3-netaddr python3-simplejson python3-librepo python3-devel python3-pip python3-setuptools python3-wheel python3-distro python3-coverage python3-ldap python3-Sphinx apache2 apache2-devel apache2-mod_wsgi-python3 python3-dnspython rsync fence-agents genders xorriso tftp  supervisor ipmitool acl python3-PyYAML python3-schema

    sudo pip3 install -r ~/cobbler_test/docs/requirements.rtd.txt
    sudo pip3 install django file-magic ldap3 pymongo tornado dnspython mod_wsgi
}

build_cobbler () {
    echo "Building Cobbler"
    sudo make install -C ~/cobbler_test
    cobbler version
}

clean_cobbler () {
    echo "Clean up Cobbler"
    sudo rm /var/lib/cobbler/collections/distros/*
    sudo rm /var/lib/cobbler/collections/profiles/*
    sudo rm /var/lib/cobbler/collections/systems/*
    cobbler sync
    sudo rm /var/log/cobbler/cobbler.log
    restart_cobbler
}

import_distro () {
    echo "Importing distro"
    cobbler import --name=$2 --path=$MOUNTPOINT
}

create_system () {
    echo "Add system from distro"
    cobbler system add --name=$2 --profile=$3
    #cobbler system edit --name=dom --boot-loaders="grub"
}

restart_cobbler () {
    echo "Restarting cobblerd service"
    sudo systemctl restart cobblerd
    sudo systemctl status cobblerd
}

watch_log () {
    tail -f /var/log/cobbler/cobbler.log
}

open_log () {
    less /var/log/cobbler/cobbler.log
}

show_help () {
    echo "Usage: $0 COMMAND [PARAMETERS]"
    echo
    echo "  help        Print this help message"
    echo "  build       Build and install Cobbler in ~/cobbler_test"
    echo "  clean       Clean Cobbler files"
    echo "  clone       Clone the cobbler repo to ~/cobbler_test"
    echo "  deps        Install dependencies"
    echo "  import      Import a mounted distro into Cobbler ($0 import name)"
    echo "  mount       Mount ISO to $MOUNTPOINT ($0 mount isoname)"
    echo "  vmount      Mount host filesystem to /mnt in guest and mout ISO to $MOUNTPOINT. ($0 vmount isoname)"
    echo "  system      Create a new profile ($0 system name profilename)"
    echo "  log         Open the log file"
    echo "  wlog        Watch the log file"
    echo ""
    exit 1
}

# main routine
case $1 in

    mount)
        mount_dirs $@
        ;;

    vmount)
        mount_vm_dirs $@
        ;;

    clean)
        clean_cobbler
        ;;

    clone)
        clone_cobbler
        ;;

    deps)
        install_deps
        ;;

    build)
        build_cobbler
        ;;

    restart)
        restart_cobbler
        ;;

    import)
        import_distro $@
        ;;

    system)
        create_system $@ $@
        ;;

    log)
        open_log
        ;;

    wlog)
        watch_log
        ;;

    help | --help)
        show_help
        ;;

    *)
        show_help
        ;;
esac
