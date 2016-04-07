#!/bin/sh
set -x 
SOURCE=/mnt/usb
cp $SOURCE/usr/lib/libstdc++.so.6.0.20 /lib/libstdc++.so.6.0.14
ln -sfn $SOURCE/etc/webbridge /etc/webbridge
#ln -sfn $SOURCE/NDS/webbridge /NDS/bin/webbridge
ln -sfn $SOURCE/NDS/webbridge-stub /NDS/bin/webbridge
ln -sfn $SOURCE/etc/playready /etc/playready
ln -sfn $SOURCE/etc/ssl /etc/ssl
ln -sfn $SOURCE/etc/fonts /etc/fonts
mkdir -p /usr/share/fonts
ln -sfn $SOURCE/usr/share/X11 /usr/share/X11
ln -sfn $SOURCE/usr/share/fonts/ttf-bitstream-vera /usr/share/fonts/ttf-bitstream-vera
ln -sfn $SOURCE/usr/share/fonts/netflix /usr/share/fonts/netflix
