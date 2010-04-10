#!/bin/bash
#
# (C) 2010 Stefan Brand <seiichiro@seiichiro0185.org>
#
# mpg2dvd.sh: create a DVD-Structure from a single MPEG-File
#             DVD-Folder will be named <name of mpg>_DVD
#             Status output via Zenity
#
# usage: mpg2dvd.sh somefile.mpg
#

MPEG="$1"

if [ -z "$MPEG" ]
then
	zenity --title 'MPG2DVD: Error' --error --text 'No input-file given!'
	exit 1
fi

DVD="${MPEG/.mpg/_DVD}"
if [ "$DVD" == "$MPEG" ]
then
	DVD="${MPEG/.mpeg/_DVD}"
	if [ "$DVD" == "$MPEG" ]
	then
		zenity --title 'MPG2DVD: Error' --error --text 'The file has to end in .mpg or .mpeg!'
		exit 2
	fi
fi

if [ -d "$DVD" ]
then
  zenity --title 'MPG2DVD: Error' --error --text "The folder $DVD already exists"
  exit 3
fi

mkdir -p "$DVD"

dvdauthor -t -o "$DVD" -c 0,15:00,30:00,45:00,01:00:00,01:15:00,01:30:00,01:45:00,02:00:00,02:15:00,02:30:00,02:45:00,03:00:00 "$MPEG" 2>&1 | zenity --title "MPG2DVD: Creating $DVD..." --progress --text 'Creating DVD-Structure...' --pulsate --auto-close
RET1=$?
dvdauthor -T -o "$DVD"
RET2=$?
if [ $RET1 -eq 0 ] && [ $RET2 -eq 0 ]
then
	zenity --title 'MPG2DVD: Success' --info --text "$DVD was created successfully"
	exit 0
else
	rm -Rf "$DVD"
	zenity --title 'MPG2DVD: Error' --error --text "An Error occured.\n$DVD wasn't created."
	exit 4
fi


