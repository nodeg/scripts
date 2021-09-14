#!/bin/bash
#
# Script to update the Jitsi-Meet stack
# Author: Leon Schroeder, Dominik Gedon
#--------------------------------------

BASENAME=jitsi
BASENAME_UP=Jitsi
NAME=$BASENAME-update
STACK=("meet" "videobridge" "jicofo" "jibri" "jigasi" )

# TODO:
# - only update changes and bump version if mkbuild and obsbuild are successful
# - rename directories to lowercase and simplify logic


### Functions ###

# Retrieves the source and packages it into an archive
get_source () {
    echo "Updating source file."
    # adjust the name
    if [ "$1" == "jitsi-meet" ] || [ "$1" == "jitsi-videobridge" ];then
        NAME=$1
    else
        NAME=$BASENAME-$1
    fi
    # there are no proper releases for those two so package the master branch instead
    if [ "$1" == "jibri" ] || [ "$1" == "jigasi" ];then
        BRANCH=master
    else
        BRANCH=$(curl --silent "https://api.github.com/repos/jitsi/$1/releases/latest" | jq -r .tag_name)
    fi
    curl --progress-bar -L https://github.com/jitsi/"$1"/tarball/"$BRANCH" > source.tar
    echo "Cloned $BRANCH."
    rm -rf /tmp/"$NAME" ||:
    mkdir /tmp/"$NAME"
    tar --strip-components=1 -xvf source.tar -C /tmp/"$NAME" &> /dev/null
    tar -cjvf "$NAME".tar.bz2 -C /tmp/ "$NAME" &> /dev/null
    rm -rf /tmp/"$NAME"  ||:
    rm source.tar
    echo "Repacked to $NAME.tar.bz2."
}

# bump the spec file version
bump_version () {
    echo "Bumping version in spec file."
    # adjust the name
    if [ "$1" == "jitsi-meet" ] || [ "$1" == "jitsi-videobridge" ];then
        NAME=$1
    else
        NAME=$BASENAME-$1
    fi
    # there are no proper releases for those two so take the jitsi-meet version number instead
    if [ "$1" == "jibri" ] || [ "$1" == "jigasi" ];then
        VERSION=$(curl --silent "https://api.github.com/repos/jitsi/jitsi-meet/releases/latest" | jq -r .name)
    else
        VERSION=$(curl --silent "https://api.github.com/repos/jitsi/$1/releases/latest" | jq -r .name)
    fi
    sed -i "0,/Version:/{s/Version:$PARTITION_COLUMN.*/Version:        $VERSION/}" "$NAME".spec
    echo "Updated spec file to version: $VERSION"
}

# update the .changes file
update_changes () {
    echo "Updating changelog."
    # adjust the name
    if [ "$1" == "jitsi-meet" ] || [ "$1" == "jitsi-videobridge" ];then
        NAME=$1
    else
        NAME=$BASENAME-$1
    fi
    # there are no proper releases with changelogs for those two
    if [ "$1" == "jibri" ] || [ "$1" == "jigasi" ];then
        echo "No automated changelog generation possible. Please do it manually!"
    else
        wget -q "$(curl --silent "https://api.github.com/repos/jitsi/$1/releases/latest" | jq -r '.assets[] | select(.name | contains("CHANGELOG.txt")).browser_download_url')" -O- > tmp.changes
        sed -i '/^$/d' tmp.changes
        sed -i 's/* /- /g' tmp.changes
        cat tmp.changes <(echo) | cat - "$NAME".changes > temp && mv temp "$NAME".changes
        rm tmp.changes
    fi
}

# move into the right directory.
# sadly we have uppercase directory names so we need more logic
change_dir () {
    # uppercase first letter
    NAME="${1^}"
    if [[ $(basename "$PWD") == "$BASENAME_UP-"* ]];then
        cd .. || exit 1
        # special case for meet and videobridge
        if [ "$1" == "jitsi-meet" ] || [ "$1" == "jitsi-videobridge" ];then
            # uppercase the m from meet and the v from videobridge
            NAME=${NAME^^[mv]}
            if [ -d "$NAME" ]; then
                cd "$NAME" || exit 1
            fi
        # normal case for the others
        else
            if [ -d "$BASENAME_UP-$NAME" ]; then
                cd "$BASENAME_UP-$NAME" || exit 1
            fi
        fi
    fi
}

# execute "build" or "version" for all packages
execute_all () {
    for item in ${STACK[*]};do
        if [ "$item" == "meet" ];then
            "$1" jitsi-meet
        elif [ "$item" == "videobridge" ];then
            "$1" jitsi-videobridge
        else
            "$1" "$item"
        fi
    done
}

# executes the Makefile
mkbuild () {
    echo "Executing Makefile."
    make || exit 1
}

# builds the package
obsbuild () {
    echo "Executing OBS build process."
    osc build --clean || exit 1
}

# retrieves the current version from the spec file
current_version () {
    change_dir "$1"
    # special case for meet and videobridge
    if [ "$1" == "jitsi-meet" ] || [ "$1" == "jitsi-videobridge" ];then
        TMP=$(grep 'Version:' "$1".spec)
    # normale case for the others
    else
        TMP=$(grep 'Version:' "$BASENAME"-"$1".spec)
    fi
    VERSION=${TMP:(16)}
    echo "OBS version:      $VERSION"
}

# retrieves the most current upstream version
upstream_version () {
    VERSION=$(curl --silent "https://api.github.com/repos/jitsi/$1/releases/latest" | jq -r .name)
    if [ "$VERSION" == "null" ];then
        # jigasi, jibri have no releases -> master
        echo "Upstream version: No proper release."
    else
        echo "Upstream version: $VERSION"
    fi
}

# install all build dependencies
dependencies () {
    if [ "$EUID" != 0 ];then
        echo "Error! Must be run as root."
        exit 1
    fi
    echo "Installing build dependencies."
    zypper in jq maven
    npm install -g yarn webpack webpack-cli jetifier cross-os patch-package
}

help () {
    echo "Usage: $NAME OPTION [STACK]"
    echo "Helper script to update the Jitsi Meet stack."
    echo ""
    echo "OPTION"
    echo "  build       Build the package provided by STACK. If STACK is empty builds all packages."
    echo "  deps        Install the build dependencies."
    echo "  help        Print this help message."
    echo "  version     Check version numbers of the package provided with STACK."
    echo "              If STACK is empty shows version for all packages."
    echo ""
    echo "STACK"
    echo "${STACK[*]}"
    echo ""
    echo "Examples:"
    echo "  $NAME deps"
    echo "  $NAME build"
    echo "  $NAME build meet"
    echo "  $NAME version"
    echo "  $NAME version meet"
    echo ""
    echo "Note:"
    echo "Jibri and Jigasi have no proper releases. There the master branch will be taken as source and the version"
    echo "from Jitsi-Meet will be written to the spec file. Furthermore the changelog has to be done manually."
    exit 1

}

# version routine
version () {
    echo "$1:"
    upstream_version "$1"
    current_version "$1"
    echo "--------------------------"
}

# build routine
build () {
    echo "Building $1:"
    change_dir "$1"
    get_source "$1"
    mkbuild
    obsbuild
    bump_version "$1"
    update_changes "$1"
    echo "#-------------------------------"
}

### Main routine ###
case $1 in
    build)
        ;;
    deps)
        dependencies
        ;;
    version)
        ;;
    help | -h)
        help
        ;;
    *)
        help
        ;;
esac

# build subroutine
if [ "$1" == "build" ];then
    if [ -z "$2" ];then
        # build all
        execute_all build
    else
        case $2 in
            jibri)
                build "$2"
                ;;
            jicofo)
                build "$2"
                ;;
            jigasi)
                build "$2"
                ;;
            meet)
                build jitsi-meet
                ;;
            videobridge)
                build jitsi-videobridge
                ;;
            *)
                echo "If using a stack, only the following are supported:"
                echo "${STACK[*]}"
                exit 1
                ;;
        esac
    fi
fi

# version subroutine
if [ "$1" == "version" ];then
    if [ -z "$2" ];then
        # show version of all
        execute_all version
    else
        case $2 in
            jibri)
                version "$2"
                ;;
            jicofo)
                version "$2"
                ;;
            jigasi)
                version "$2"
                ;;
            meet)
                version jitsi-meet
                ;;
            videobridge)
                version jitsi-videobridge
                ;;
            *)
                echo "If using a parameter, only the following are supported:"
                echo "${STACK[*]}"
                exit 1
                ;;
        esac
    fi
fi
