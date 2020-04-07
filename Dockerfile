FROM centos:6.10
MAINTAINER Yupeng Luo <yupeng.luo@nokia-sbell.com>

ENV WS_USER=wsuser \
    WS_UID=5000 \
    WS_PASSWD=vncpasswd \
    WS_VERSION=1.1 \
    VNC_RESOLUTION=1280x1024

# Install base( except "X Window System" "fonts" )
RUN yum update -y && yum groupinstall -y "Desktop" "Chinese Support" \
    && yum install -y epel-release sudo gedit firefox openssh-server openssh-clients dejavu-sans-* dejavu-serif-fonts gvim \
    && yum clean all && rm -rf /tmp/* \
    && echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/wheel \
    && chmod 0440 /etc/sudoers.d/wheel

# Install python2.7 and supervisor
RUN yum install -y centos-release-scl \
    && yum install -y \
        python27 \
        python27-python-setuptools \
    && yum clean all && rm -rf /tmp/* \
    && . /opt/rh/python27/enable \
    && echo $(python --version) \
    && easy_install supervisor \
	&& mkdir -p /var/log/supervisor \
	&& mkdir -p /etc/supervisord.d \
    && { \
        echo '[supervisord]'; \
        echo 'nodaemon=true'; \
        echo 'logfile=/var/log/supervisor/supervisord.log'; \
        echo 'logfile_maxbytes=1MB'; \
        echo 'logfile_backups=1'; \
        echo 'loglevel=warn'; \
        echo 'pidfile=/var/run/supervisord.pid'; \
        echo '[include]'; \
        echo 'files = /etc/supervisord.d/*.conf'; \
    } > /etc/supervisord.conf

# VNC & SSH Servers & Autostart services
# tigervnc, tigervnc-server, tigervnc-server-module
RUN yum update -y \
	&& yum install -y \
        tigervnc-server \
	&& yum clean all && rm -rf /tmp/* \
	&& chkconfig vncserver on 3456 \
    && { \
        echo 'VNCSERVERS="1:wsuser"'; \
        echo 'VNCSERVERARGS[1]="-geometry 1280x1024"'; \
    } >> /etc/sysconfig/vncservers \
	&& chkconfig sshd on 3456 \
	&& echo "gnome-session --session=gnome" > ~/.xsession \
    && { \
        echo '[program:sshd]'; \
        echo 'command=/etc/init.d/sshd restart'; \
        echo 'stderr_logfile=/var/log/supervisor/sshd-error.log'; \
        echo 'stdout_logfile=/var/log/supervisor/sshd.log'; \
    } > /etc/supervisord.d/ssh.conf \
    && { \
        echo '[program:vncserver]'; \
        echo 'command=/etc/init.d/vncserver restart'; \
        echo 'stderr_logfile=/var/log/supervisor/vncserver-error.log'; \
        echo 'stdout_logfile=/var/log/supervisor/vncserver.log'; \
    } > /etc/supervisord.d/vnc.conf

# Settings for Python27
RUn rm -f /usr/bin/python \
    && ln -s /opt/rh/python27/root/usr/bin/python /usr/bin/python \
    && ln -s /opt/rh/python27/root/usr/lib64/libpython2.7.so.1.0 /lib64/libpython2.7.so.1.0 \
    && sed -i -e 's/python/python2.6/' /usr/bin/yum


# Setting password for root and Time Zone 
RUN echo "root:123456" | chpasswd \
    && mv /etc/localtime /etc/localtime.bak && ln -s /usr/share/zoneinfo/Asia/Shanghai  /etc/localtime

# GNOME Settings for all users
RUN gconftool-2 --direct --config-source xml:readwrite:/etc/gconf/gconf.xml.mandatory \
	    --type bool  --set /apps/nautilus/preferences/always_use_browser true \
	&& gconftool-2 --direct --config-source xml:readwrite:/etc/gconf/gconf.xml.mandatory \
	    --type bool --set /apps/gnome-screensaver/idle_activation_enabled false \
	&& gconftool-2 --direct --config-source xml:readwrite:/etc/gconf/gconf.xml.mandatory \
	    --type bool --set /apps/gnome-screensaver/lock_enabled false \
	&& gconftool-2 --direct --config-source xml:readwrite:/etc/gconf/gconf.xml.mandatory \
	    --type int --set /apps/metacity/general/num_workspaces 1 \
	&& gconftool-2 --direct --config-source xml:readwrite:/etc/gconf/gconf.xml.mandatory \
	    --type=string --set /apps/gnome_settings_daemon/keybindings/screensaver ' ' \
	&& gconftool-2 --direct --config-source xml:readwrite:/etc/gconf/gconf.xml.mandatory \
	    --type=string --set /apps/gnome_settings_daemon/keybindings/power ' ' \
	&& gconftool-2 --direct --config-source xml:readwrite:/etc/gconf/gconf.xml.mandatory \
	    --type bool --set /apps/panel/global/disable_log_out true \
	&& gconftool-2 --direct --config-source xml:readwrite:/etc/gconf/gconf.xml.mandatory \
	    --type int --set /apps/gnome-power-manager/timeout/sleep_computer_ac '0' \
	&& gconftool-2 --direct --config-source xml:readwrite:/etc/gconf/gconf.xml.mandatory \
	    --type int --set /apps/gnome-power-manager/timeout/sleep_display_ac '0' \
	&& gconftool-2 --direct --config-source xml:readwrite:/etc/gconf/gconf.xml.mandatory \
	    --type int --set /apps/gnome-screensaver/power_management_delay '0' \
	&& gconftool-2 --direct --config-source xml:readwrite:/etc/gconf/gconf.xml.mandatory \
	    --type bool --set /desktop/gnome/remote_access/enabled true \
	&& gconftool-2 --direct --config-source xml:readwrite:/etc/gconf/gconf.xml.mandatory \
	    --type bool --set /desktop/gnome/remote_access/prompt_enabled false

ADD startup.sh /

EXPOSE 5901 22

CMD ["/startup.sh"]
