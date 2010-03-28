#!/bin/bash
#
# (C) Stefan Brand <seiichiro@seiichiro0185.org> 2008          
#
# sysbackup-tar.sh: little script to backup your running system into a tar-file


## Configuration

# SYSMOUNTS - this array should include all system partitions. If your system for example has
# /, /boot, /usr and /opt on different partitions it should look like this:
# SYSMOUNTS=( "/" "/boot" "/usr" "/opt" )
# Please note: partitions need to be given in correct order, meaning / has always to be the first
# If you for example have /usr and /usr/local on seperate partitions you will have to give / first,
# then /usr and last /usr/local

SYSMOUNTS=( "/" "/boot" )

# DOMOUNT - this array should include all partitions that are not mountet by default, like /boot
# Syntax is the same as for SYSMOUNTS

DOMOUNTS=( "/boot" )

# EXCLUDES - this array contains patterns for files/directories that should not be included in 
# the backup. An example for this is tmp/*

EXCLUDES=( "tmp/*" "var/cache/pacman/*" )

## End Configuration

## Program -- NO CHANGES ARE NEEDED AFTER THIS LINE --

_BASEDIR="$1"
_OPTNAME="${2:-backup}"

## Checks

if [ $UID -ne 0 ]
then
  echo "You have to be root to run this!"
  echo "exiting..."
  exit 1
fi

if [[ "${_BASEDIR}" == "" || "${_BASEDIR}" == "--help" || "${_BASEDIR}" == "-h" || "${_BASEDIR}" == "-?" ]]
then
  echo "USAGE: $0 <backup dir> [<backup name>]"
  echo "exiting"
  exit 2
fi

if [ ! -d "${_BASEDIR}" ]
then
  echo "ERROR: No valid Backup directory given!"
  echo "USAGE: $0 <backup dir> [<backup name>]"
  echo "exiting"
  exit 3
fi

## Functions

function prepare()
{
  mkdir /tmp/backup$$
  
  for index in $(seq 0 $(( ${#DOMOUNTS[@]} - 1 )))
  do
    mount "${DOMOUNTS[$index]}"
  done
  
  for index in $(seq 0 $(( ${#SYSMOUNTS[@]} - 1 )))
  do
    mount -o ro,bind "${SYSMOUNTS[$index]}" "/tmp/backup$$${SYSMOUNTS[$index]}"
  done
  
  for index in $(seq 0 $(( ${#EXCLUDES[@]} - 1 )))
  do
    echo "${EXCLUDES[$index]}" >> /tmp/excludes$$
  done
  
  BACKUPFILE=$(echo "${_BASEDIR}/${_OPTNAME}-system-$(date +%Y%m%d).tar.gz" | sed -e "s#//#/#g")
}

function dobackup()
{
  cd /tmp/backup$$/
  tar -cvzpf "${BACKUPFILE}" -X /tmp/excludes$$ *
}

function cleanup()
{
  cd /
  for index in $(seq $(( ${#SYSMOUNTS[@]} - 1 )) -1 0)
  do
    UMOUNT=$(echo "/tmp/backup$$${SYSMOUNTS[$index]}" | sed -e 's#/$##')   
    umount "$UMOUNT"
  done
  
  
  for index in $(seq $(( ${#DOMOUNTS[@]} - 1 )) -1 0)
  do
    umount "${DOMOUNTS[$index]}"
  done
  
  rmdir /tmp/backup$$ 
  rm -f /tmp/excludes$$
}

## Main Program

trap cleanup TERM INT

prepare
dobackup
sleep 3
cleanup
exit 0
