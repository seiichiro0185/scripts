#!/bin/bash
#
# (C) 2010 Stefan Brand <seiichiro@seiichiro0185.org>
#
# scriptmenu.sh: generate a Openbox Pipemenu from a collection of scripts
# see http://www.seiichiro0185.org/doku.php/blog:openbox_generating_a_menu_from_your_self-written_scripts for more infos
#


_SCRIPTDIR="/home/seiichiro/.bin"

for i in ${_SCRIPTDIR}/*.msh
do
	echo -n "$(grep "MCATEGORY" < ${i} | cut -d'=' -f2);" >> /tmp/scriptmenu.$$
	echo -n "$(grep "MNAME" < ${i} | cut -d'=' -f2);" >> /tmp/scriptmenu.$$
	echo "${i}" >> /tmp/scriptmenu.$$
done

sort > /tmp/scriptmenu_s.$$ < /tmp/scriptmenu.$$

cut -d';' -f1 < /tmp/scriptmenu_s.$$ | uniq > /tmp/menucat.$$

echo '<?xml version="1.0" encoding="utf-8"?>'
echo '<openbox_pipe_menu>'
while read line
do
	echo "  <menu id=\"sm-${line}\" label=\"${line}\">"
	IFS=";"
	while read -a line2
	do
		if [ "${line}" == "${line2[0]}" ]
		then
			echo "  <item label=\"${line2[1]}\">"
			echo "    <action name=\"Execute\">"
			echo "      <execute>"
			echo "        ${line2[2]}"
			echo "      </execute>"
			echo "    </action>"
			echo "  </item>"
		fi
	done < /tmp/scriptmenu_s.$$
	echo "  </menu>"
done < /tmp/menucat.$$
echo '</openbox_pipe_menu>'

rm /tmp/*.$$
