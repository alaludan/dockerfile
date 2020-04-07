#!/bin/bash
useradd -d /home/$WS_USER -m $WS_USER -u $WS_UID
echo "$WS_USER:$WS_PASSWD" | chpasswd
chmod -R 755 /home/$WS_USER
echo | sed -i "s/wsuser/$WS_USER/g" /etc/sysconfig/vncservers
echo | sed -i "s/1280x1024/$VNC_RESOLUTION/g" /etc/sysconfig/vncservers
cp /u/.gvimrc /root/
cp /u/.vimrc /root/
cp /u/.gvimrc /home/$WS_USER/
cp /u/.vimrc /home/$WS_USER/
chown $WS_USER.$WS_USER /home/$WS_USER/.gvimrc
chown $WS_USER.$WS_USER /home/$WS_USER/.vimrc
su $WS_USER sh -c "yes $WS_PASSWD | vncpasswd"
/opt/rh/python27/root/usr/bin/supervisord
