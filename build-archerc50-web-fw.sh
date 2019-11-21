#!/bin/bash

# Description: Creates factory firmware images for TP-Link Archer C50 v3/v4
# License: GPLv3
# Requirements: /usr/bin/zip
# Initial version written by Collimas from Freifunk Lippe e.V.

ORIG_FW_LINK_V3="https://static.tp-link.com/2018/201804/20180420/Archer%20C50(EU)_V3_171227.zip"
ORIG_FW_LINK_V4="https://static.tp-link.com/2018/201805/20180528/Archer%20C50(EU)_V4_180313.zip"

GLUON_FW_LINK_V3="https://images.ffdo.de/ffdo_ng/domaenen/domaene07/releases/2.2.3/images/sysupgrade/gluon-ffdo-d07-2.2.3-tp-link-archer-c50-v3-sysupgrade.bin"
GLUON_FW_LINK_V4="https://images.ffdo.de/ffdo_ng/domaenen/domaene07/releases/2.2.3/images/sysupgrade/gluon-ffdo-d07-2.2.3-tp-link-archer-c50-v4-sysupgrade.bin"

OUTPUT_GLUON_WEB_NAME_V3="gluon-ffdo-d07-2.2.3-tp-link-archer-c50-v3-factory-web.bin"
OUTPUT_GLUON_WEB_NAME_V4="gluon-ffdo-d07-2.2.3-tp-link-archer-c50-v4-factory-web.bin"

build_v3() {
 rm -rf archerc50temp/v3
 mkdir -p archerc50temp/v3
 cd archerc50temp
 wget "$ORIG_FW_LINK_V3"
 unzip -j Archer*.zip -d v3
 rm Archer*.zip
 echo "Hersteller-Firmware erfolgreich heruntergeladen und entpackt"
 cd v3
 wget "$GLUON_FW_LINK_V3"
 echo "Freifunk-Firmware erfolgreich heruntergeladen"
 mkdir web
 echo "Verzeichnis web erfolgreich angelegt"
 cp Archer*.bin web/tpl.bin
 cp gluon*.bin web/owrt.bin
 mkdir tftp
 echo "Verzeichnis tftp erfolgreich angelegt"
 cp Archer*.bin tftp/tpl.bin
 cp gluon*.bin tftp/owrt.bin
 cd web
 dd if=tpl.bin of=boot.bin bs=131584 count=1
 cat owrt.bin >> boot.bin
 mv boot.bin "$OUTPUT_GLUON_WEB_NAME_V3"
 cd ../tftp
 dd if=/dev/zero of=tp_recovery.bin bs=196608 count=1
 dd if=tpl.bin of=tmp.bin bs=131584 count=1
 dd if=tmp.bin of=boot.bin bs=512 skip=1
 cat boot.bin >> tp_recovery.bin
 cat owrt.bin >> tp_recovery.bin
 cd ..
 rm web/owrt.bin
 rm web/tpl.bin
 rm tftp/owrt.bin
 rm tftp/tpl.bin
 rm tftp/boot.bin
 rm tftp/tmp.bin
 rm *.bin
 rm *.pdf
 echo
 echo "Webflash- und TFTP-Recovery-Images erfolgreich erzeugt"
 echo "Diese sind unter den Pfaden $HOME/archerc50temp/v3/tftp und"
 echo "$HOME/archerc50temp/v3/web zu finden."
 abfrage
}

build_v4() {
 rm -rf archerc50temp/v4
 mkdir -p archerc50temp/v4
 cd archerc50temp
 wget "$ORIG_FW_LINK_V4"
 unzip -j Archer*.zip -d v4
 rm Archer*.zip
 echo "Hersteller-Firmware erfolgreich heruntergeladen und entpackt"
 cd v4
 wget "$GLUON_FW_LINK_V4"
 echo "Freifunk-Firmware erfolgreich heruntergeladen"
 mkdir web
 echo "Verzeichnis web erfolgreich angelegt"
 cp Archer*.bin web/tpl.bin
 cp gluon*.bin web/owrt.bin
 mkdir tftp
 echo "Verzeichnis tftp erfolgreich angelegt"
 cp Archer*.bin tftp/tpl.bin
 cp gluon*.bin tftp/owrt.bin
 cd web
 dd if=tpl.bin of=boot.bin bs=131584 count=1
 cat owrt.bin >> boot.bin
 mv boot.bin "$OUTPUT_GLUON_WEB_NAME_V4"
 cd ../tftp
 dd if=/dev/zero of=tp_recovery.bin bs=196608 count=1
 dd if=tpl.bin of=tmp.bin bs=131584 count=1
 dd if=tmp.bin of=boot.bin bs=512 skip=1
 cat boot.bin >> tp_recovery.bin
 cat owrt.bin >> tp_recovery.bin
 cd ..
 rm web/owrt.bin
 rm web/tpl.bin
 rm tftp/owrt.bin
 rm tftp/tpl.bin
 rm tftp/boot.bin
 rm tftp/tmp.bin
 rm *.bin
 rm *.pdf
 echo
 echo "Webflash- und TFTP-Recovery-Images erfolgreich erzeugt"
 echo "Diese sind unter den Pfaden $HOME/archerc50temp/v4/tftp und"
 echo "$HOME/archerc50temp/v4/web zu finden."
 abfrage
}

abfrage() {
 cd
 echo
 echo "Mit diesem Script werden Web- und TFTP-Recovery-Images für den TP-Link Archer C50 v3/v4 erzeugt."
 echo "Diese Software unterliegt der GPLv3 Lizenz."
 echo
 PS3='Bitte Hardware-Revision des TP-Link Archer C50 auswählen: '
 options=("v3" "v4" "Quit")
 select opt in "${options[@]}"
 do
     case $opt in
         "v3")
             echo "Du hast Hardwarerevision 3 gewählt. Weiter gehts..."
             build_v3
             exit
             ;;
         "v4")
             echo "Du hast Hardwarerevision 4 gewählt. Weiter gehts..."
             build_v4
             exit
             ;;
         "Quit")
             break
             ;;
         *) echo "Ungültige Auswahl $REPLY";
     esac
 done
}

abfrage
