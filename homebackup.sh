#!/bin/bash
#
# (C) 2010 Stefan Brand <seiichiro0185.org>
#
# homebackup.sh: incremental homedir backup using rsync and hardlinks
#
# usage:
# local usage: homebackup.sh /backups/home
# remote usage: homebackup.sh user@someserver:/backups/home
# 
# more info is also here: http://www.seiichiro0185.org/doku.php/linux:backupscripts

_EXCLUDEFILE="$HOME/.hbexcludes"
_BASEDIR="$1"

if [ "${_BASEDIR}" == "" ]
then
  echo "The first argument has to be the base backup directory!"
  echo "exiting"
  exit 2
fi

if [ ! -e "${_EXCLUDEFILE}" ]
then
	touch "${_EXCLUDEFILE}"
fi

_SSH=$(echo "${_BASEDIR}" | grep -e '.*@.*:.*' | sed -e 's/:.*$//g')

if [ "${_SSH}" == "" ]
then
  # Local Backup

  DIRNAME="$(basename $HOME)-$(date +%Y%m%d-%H%M)"
  BACKUPDIR=$(echo "${_BASEDIR}/${DIRNAME}/" | sed -e "s#//#/#g")
  LAST=$(echo "${_BASEDIR}/last" | sed -e "s#//#/#g")

  mkdir -p "$BACKUPDIR"

  rsync -av --exclude-from="${_EXCLUDEFILE}"  --link-dest="../last" "$HOME/" "$BACKUPDIR"

  cd "$BACKUPDIR"
  ln -snf "${DIRNAME}" "$LAST"

else
  # Remote Backup

  DIRNAME="$(basename $HOME)-$(date +%Y%m%d-%H%M)"
  REMOTEDIR=$(echo "${_BASEDIR}" | sed -e 's/^.*://g')
  BACKUPDIR=$(echo "${REMOTEDIR}/${DIRNAME}/" | sed -e "s#//#/#g")

  ssh ${_SSH} mkdir -p "$BACKUPDIR"

  rsync -av --exclude-from="${_EXCLUDEFILE}" --link-dest="../last/" "$HOME/" "${_SSH}:${BACKUPDIR}"

  ssh ${_SSH} "cd \"${BACKUPDIR}\" && ln -sfn \"${DIRNAME}\" \"${REMOTEDIR}\"/last"

fi

