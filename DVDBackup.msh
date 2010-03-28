#!/bin/bash
#MCATEGORY=Multimedia
#MNAME=DVDBackup
#
# (C) 2010 Stefan Brand <seiichiro@seiichiro0185.org>
#
# DVDBackup script: use Zenity and dvdbackup to mirror a DVD to HDD
#

OUTDIR="$(zenity --title DVDBackup --file-selection --directory --save)"
if [ ! -z ${OUTDIR} ]
then
	(dvdbackup -i /dev/sr0 -M -o "${OUTDIR}") &
	(echo 1; while [ ! -z "$(pgrep dvdbackup)" ]
	do
		sleep 2
	done) | zenity --title DVDBackup --progress --text='DVD wird kopiert...' --pulsate
	killall dvdbackup
fi
