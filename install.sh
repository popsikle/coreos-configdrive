#!/bin/bash

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

if [ "$#" -ne 2 ]; then
  echo "Usage : $0 release datafs"
  exit 1
fi

RELEASE=$1
FSTYPE=$2
CDMP=/media/configdrive
OSMP=/mnt


OS_DISK=$(lsblk |grep disk | cut -f1 -d' ' | grep ".*da")
DATA_DISK=$(lsblk |grep disk | cut -f1 -d' ' | grep ".*db")

coreos-install -d /dev/${OS_DISK} -C ${RELEASE}

mount /dev/${OS_DISK}6 ${OSMP}
cp -dpr ${CDMP}/oem/* ${OSMP}/
chown root:root ${OSMP}/*
chmod 755 ${OSMP}/bin/*


if [ -n "$DATA_DISK" ]; then
  CHECK=`lsblk -o name,type -r -n /dev/$DATA_DISK | grep part`
  if [ $? -ne 0 ]; then
    echo "$DATA_DISK looks empty..."
    SIZE=`fdisk -l 2>/dev/null | grep $DATA_DISK | grep 'GB\|GiB' | cut -f2 -d":" | cut -f1 -d"G" | tr -d " " |cut -f1 -d"."`
    SIZE_IN="G"
    if [ -z "$SIZE" ]; then
      SIZE=`fdisk -l 2>/dev/null | grep $DATA_DISK | grep MB | cut -f2 -d":" | cut -f1 -d"M" | tr -d " " |cut -f1 -d"."`
      SIZE_IN="M"
    fi
    echo -e "Creating a $SIZE ${SIZE_IN}B partition on $DATA_DISK !!!"
    echo -e "n\np\n1\n\n\nw\n" | fdisk /dev/${DATA_DISK} > /dev/null 2>&1
    sleep 2
    partprobe
    sleep 2
    mkfs.${FSTYPE} -m0 /dev/${DATA_DISK}1
    tune2fs -o journal_data_writeback /dev/${DATA_DISK}1 > /dev/null 2>&1
    tune2fs -O dir_index /dev/${DATA_DISK}1 > /dev/null 2>&1
    e2fsck -D -f /dev/${DATA_DISK}1 > /dev/null 2>&1
  fi
fi