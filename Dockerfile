FROM --platform=linux/386 jlesage/baseimage-gui:alpine-3.18-v4

COPY ./assets/nolf1_icon.png /tmp/nolf1_icon.png

RUN \ 
	set-cont-env HOME "/container/.wine/drive_c/nolf" && \
	set-cont-env APP_NAME "NOLF Dedicated Server" && \
	set-cont-env APP_VERSION "1.3" && \
	set-cont-env DOCKER_IMAGE_VERSION "alpine-3.18-v4" && \
	set-cont-env DOCKER_IMAGE_PLATFORM "linux/386" && \
    	APP_ICON_URL=/tmp/nolf1_icon.png && \
    	install_app_icon.sh "$APP_ICON_URL"

ENV \
 	WINEDEBUG="-all" \
 	WINEARCH="win32" \
 	WINEPREFIX="/container/.wine" \
 	WINEDLLOVERRIDES="mscoree,mshtml=" \
	SERVER_NAME="A NOLF Docker Server" \
	SERVER_PASSWORD="" \
	SERVER_PORT="27888" \
	MAX_PLAYERS="8" \
	DISABLE_WIZARD="False" \
	CUSTOM_REZ="" \
	GAMETYPE="2" \
#	ASSAULT_MAPS="" \
#	DEATHMATCH_MAPS="" \
#	PERSIST_MAPLIST="False" \
	ADDITIONAL_ARGS=""

RUN \
	add-pkg wine && \
	add-pkg --virtual build xvfb-run cabextract wget && \
	wget -q -nc --show-progress --progress=bar:force:noscroll --no-hsts -O /tmp/winetricks --user-agent=Mozilla --content-disposition -E -c "https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks" && \
	chmod +x /tmp/winetricks && \
	mv /tmp/winetricks /usr/local/bin && \
	mkdir 760 /container && \
        xvfb-run /usr/local/bin/winetricks -q mfc42 msvcirt vb6run vcrun6 vcrun2019 && \
    	mv /container/.wine/drive_c/users/root /container/.wine/drive_c/users/app && \
    	sed-patch 's|\\root\\|\\app\\|g' /container/.wine/user.reg  && \
    	sed-patch 's|\\root\\|\\app\\|g' /container/.wine/userdef.reg && \
	wineboot -u && \
	echo 'disable' > $WINEPREFIX/.update-timestamp && \
	del-pkg build

COPY nolf_startup.sh /startapp.sh
COPY --chown=app:app ./gamefiles /container/.wine/drive_c/nolf
COPY ./rootfs/etc/cont-init.d/50-take-own.sh /etc/cont-init.d/50-take-own.sh
COPY ./rootfs/etc/cont-finish.d/51-copy-config.sh /etc/cont-finish.d/51-copy-config.sh

RUN \
	mkdir -p /config/nolf/ && \
      	mv /container/.wine/drive_c/nolf/NetHost.txt /config/nolf/ 
 
WORKDIR /container/.wine/drive_c/nolf

EXPOSE 27888-27889/udp
EXPOSE 5800

LABEL \
	org.opencontainers.image.authors="Kevin Moore" \
	org.opencontainers.image.title="NOLF Dedicated Server" \
	org.opencontainers.image.description="Docker container for running a NOLF Dedicated Server" \
	org.opencontainers.image.source=https://github.com/MisterCalvin/nolf-server \
	org.opencontainers.image.version="1.0" \
	org.opencontainers.image.licenses=MIT

