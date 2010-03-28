#!/bin/bash
#
# (C) 2010 Stefan Brand <seiichiro@seiichiro0185.org>
#
# ZenBurn.sh: Use Zenity and growisofs to burn folders to DVD
# usage: zenburn.sh /folder/to/burn
#


_SOURCEDIR="$1"
_DEVICE="/dev/sr0"

[ -z ${_SOURCEDIR} ] && zenity --title ZenBurn --warning --text="Kein Verzeichnis angegeben!" && exit 1

_TYPE="$(zenity --title ZenBurn --list --text='DVD-Art Auswählen:' --radiolist --column=' ' --column='DVD-Art' TRUE 'Video-DVD' FALSE 'Daten-DVD')"
[ -z ${_TYPE} ] && exit 1

VOLOK=0

while [[ $VOLOK -eq 0 ]]
do
	_VOLNAME="$(zenity --title ZenBurn --entry --text='DVD-Titel eingeben:' --entry-text="ZenBurn")"
	[[ $? -ne 0 ]] && exit 1
	[[ ${#_VOLNAME} -lt 33 ]] && VOLOK=1
done

case ${_TYPE} in

  'Daten-DVD')
	  zenity --title ZenBurn --question --text='An Vorhandene DVD Anhängen?' --ok-label='Ja' --cancel-label='Nein'
		if [[ $? -eq 0 ]]
		then
			_CMD="growisofs -use-the-force-luke=tty -J -joliet-long -M ${_DEVICE}"
		else
			_CMD="growisofs -use-the-force-luke=tty -J -joliet-long -Z ${_DEVICE}"
		fi
		;;

	'Video-DVD')
		_CMD="growisofs -use-the-force-luke=tty-use-the-force-luke=tty  -dvd-compat -dvd-video -Z ${_DEVICE}"
    ;;
esac

[ ! -z ${_VOLNAME} ] && _CMD="${_CMD} -V ${_VOLNAME}"
echo "$_CMD \"${_SOURCEDIR}\""
touch /tmp/ZenBurn.$$.log
tail -f /tmp/ZenBurn.$$.log | zenity --title "ZenBurn: Log" --text-info --width 800 --height 450 &
LOGPID=$!
${_CMD} "${_SOURCEDIR}" 2>&1 | tee /tmp/ZenBurn.$$.log| awk '{print $1; fflush()}' | zenity --title "ZenBurn: Brenne..." --progress --text="Brenne DVD \"${_VOLNAME}\"..." --auto-close
if [[ ${PIPESTATUS[0]} -eq 0 ]]
then
	zenity --title ZenBurn --info --text='DVD wurde Erfolgreich erstellt!'
	kill $LOGPID
	eject ${_DEVICE}
else
	zenity --title ZenBurn --warning --text='Fehler beim erstellen der DVD!'
	kill $LOGPID
	zenity --title "ZenBurn: Fail Log" --text-info --filename="/tmp/ZenBurn.$$.log"
fi
rm /tmp/ZenBurn.$$.log
