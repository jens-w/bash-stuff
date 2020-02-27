#!/bin/bash

# colors. yea.
RED='\033[0;31m'
YELLOW='\033[93m'
NOCOLOR='\033[0m'

CHROOT_DIR="/mnt/meh/chroot"
ROOT_DEVICE="/dev/sdx1"
BOOT_DEVICE=""

# variables for tracking what we've mounted
ROOT_MNT=0
BOOT_MNT=0
DEV_MNT=0
PROC_MNT=0
SYS_MNT=0
TMP_MNT=0

# associative array (2D array; hash)
declare -A MOUNTS=(
    [dev]="${CHROOT_DIR}/dev"
    [proc]="${CHROOT_DIR}/proc"
    [sys]="${CHROOT_DIR}/sys"
    [tmp]="${CHROOT_DIR}/tmp"
)

function output {
    echo -e "${1}"
}

function output_error {
    output "${RED}ERROR${NOCOLOR}: ${1}"
}

function cleanup {
    # unmount boot and root at the end, so the others are umounted as cleanly
    # as possible; if seperate boot, unmount it before root
    if [ $TMP_MNT -eq 1 ]
    then
        C_MP="${MOUNTS[tmp]}"
        Y_MP="${YELLOW}/tmp${NOCOLOR}"
        
        output "Unmounting ${Y_MP}"
        umount $C_MP &>/dev/null
        
        if [ ! $? -eq 0 ]
        then
            output "Unmounting ${Y_MP} lazily"
            umount $C_MP -l
        fi
    fi
    
    if [ $SYS_MNT -eq 1 ]
    then
        C_MP="${MOUNTS[sys]}"
        Y_MP="${YELLOW}/sys${NOCOLOR}"
        
        output "Unmounting ${Y_MP}"
        umount $C_MP &>/dev/null
        
        if [ ! $? -eq 0 ]
        then
            output "Unmounting ${Y_MP} lazily"
            umount $C_MP -l
        fi
    fi
    
    if [ $PROC_MNT -eq 1 ]
    then
        C_MP="${MOUNTS[proc]}"
        Y_MP="${YELLOW}/proc${NOCOLOR}"
        
        output "Unmounting ${Y_MP}"
        umount $C_MP &>/dev/null
        
        if [ ! $? -eq 0 ]
        then
            output "Unmounting ${Y_MP} lazily"
            umount $C_MP -l
        fi
    fi
    
    if [ $DEV_MNT -eq 1 ]
    then
        C_MP="${MOUNTS[dev]}"
        Y_MP="${YELLOW}/dev${NOCOLOR}"
        
        output "Unmounting ${Y_MP}"
        umount $C_MP &>/dev/null
        
        if [ ! $? -eq 0 ]
        then
            output "Unmounting ${Y_MP} lazily"
            umount $C_MP -l
        fi
    fi
    
    if [ $BOOT_MNT -eq 1 ]
    then
        C_MP="${CHROOT_DIR}/boot"
        Y_MP="${YELLOW}/boot${NOCOLOR} (${YELLOW}${BOOT_DEVICE}${NOCOLOR})"
        
        output "Unmounting ${Y_MP}"
        umount $C_MP &>/dev/null
        
        if [ ! $? -eq 0 ]
        then
            output "Unmounting ${Y_MP} lazily"
            umount $C_MP -l
        fi
    fi
    
    if [ $ROOT_MNT -eq 1 ]
    then
        C_MP="${CHROOT_DIR}"
        Y_MP="${YELLOW}/${NOCOLOR} (${YELLOW}${ROOT_DEVICE}${NOCOLOR})"
        
        output "Unmounting ${Y_MP}"
        umount $C_MP &>/dev/null
        
        if [ ! $? -eq 0 ]
        then
            output "Unmounting ${Y_MP} lazily"
            umount $C_MP -l
        fi
    fi
}

function check_chroot_dir {
    if [ ! -d $CHROOT_DIR ]
    then
        # make the dir
        mkdir -p $CHROOT_DIR
    fi
    
    if [ "$(ls -A $CHROOT_DIR)" ]
    then
        output_error "${YELLOW}${CHROOT_DIR}${NOCOLOR} is not empty"
        exit 1
    fi
}

function mount_root {
    # check if valid block device
    lsblk $ROOT_DEVICE &> /dev/null
    
    if [ ! $? -eq 0 ]
    then
        output_error "not a valid block device: ${YELLOW}${ROOT_DEVICE}${NOCOLOR}"
        exit 1
    fi
    
    output "Mounting root device ${YELLOW}${ROOT_DEVICE}${NOCOLOR}."
    mount $ROOT_DEVICE $CHROOT_DIR &>/dev/null
    
    if [ $? -eq 0 ]
    then
        ROOT_MNT=1
    else
        output_error "could not mount ${YELLOW}${ROOT_DEVICE}${NOCOLOR}."
        exit 1
    fi
}

function mount_boot {
    if [ "$BOOT_DEVICE" == "" ]
    then
        output "No seperate boot device specified."
    else
        Y_BOOT="${YELLOW}${BOOT_DEVICE}${NOCOLOR}"
        output "Mounting boot device ${Y_BOOT}."
        mount $BOOT_DEVICE $CHROOT_DIR/boot &>/dev/null
        
        if [ $? -eq 0 ]
        then
            BOOT_MNT=1
        else
            output_error "could not mount ${Y_BOOT}."
            cleanup
            exit 1
        fi
    fi
}

function mount_dev {
    # $1: $MP
    # $2: $MP_DIR
    Y_M="${YELLOW}/${1}${NOCOLOR}"
    output "Binding ${Y_M}"
    
    mount --rbind /$1 $2 &>/dev/null
    
    if [ $? -eq 0 ]
    then
        DEV_MNT=1
        mount --make-rslave $2 &>/dev/null
    else
        output_error "could not mount ${Y_M}"
        cleanup
        exit 1
    fi
}

function mount_sys {
    # $1: $MP
    # $2: $MP_DIR
    Y_M="${YELLOW}/${1}${NOCOLOR}"
    output "Binding ${Y_M}"
    
    mount --rbind /$1 $2 &>/dev/null
    
    if [ $? -eq 0 ]
    then
        SYS_MNT=1
        mount --make-rslave $2 &>/dev/null
    else
        output_error "could not mount ${Y_M}"
        cleanup
        exit 1
    fi
}

function mount_tmp {
    # $1: $MP
    # $2: $MP_DIR
    Y_M="${YELLOW}/${1}${NOCOLOR}"
    output "Binding ${Y_M}"
    
    mount --rbind /$1 $2 &>/dev/null
    
    if [ $? -eq 0 ]
    then
        TMP_MNT=1
    else
        output_error "could not mount ${Y_M}"
        cleanup
        exit 1
    fi
}

function mount_proc {
    # $1: $MP
    # $2: $MP_DIR
    Y_M="${YELLOW}/${1}${NOCOLOR}"
    output "Binding ${Y_M}"
    
    mount -t proc /$1 $2 &>/dev/null
    
    if [ $? -eq 0 ]
    then
        PROC_MNT=1
    else
        output_error "could not mount ${Y_M}"
        cleanup
        exit 1
    fi
}

function mount_rest {
    for MP in "${!MOUNTS[@]}"
    do
        MP_DIR="${CHROOT_DIR}/${MP}"
        
        case $MP in
            "dev" )
                mount_dev $MP $MP_DIR
            ;;
            "sys" )
                mount_sys $MP $MP_DIR
            ;;
            "tmp" )
                mount_tmp $MP $MP_DIR
            ;;
            "proc" )
                mount_proc $MP $MP_DIR
            ;;
            * )
                output_error "unknown mountpoint ${YELLOW}${MP}${NOCOLOR}."
                cleanup
            ;;
        esac
    done
}

# check if root
if [ "$EUID" -ne 0 ]
then
    output_error "we're not ${YELLOW}root${NOCOLOR}!"
    exit 1
fi

check_chroot_dir
mount_root
mount_boot
mount_rest

output "Copying ${YELLOW}resolv.conf${NOCOLOR}"
cp /etc/resolv.conf $CHROOT_DIR/etc &>/dev/null

sleep 1s
clear

output "After chrooting ${YELLOW}optionally${NOCOLOR} execute these:"
output "  source /etc/profile"
output "  export PS1=\"(chroot) $PS1\""

chroot $CHROOT_DIR /bin/bash

sleep 1s
clear

cleanup
