FROM cm2network/steamcmd:steam

LABEL org.opencontainers.image.title="Avorion Dedicated Server"
LABEL org.opencontainers.image.description="Avorion dedicated server with startup SteamCMD updates and Workshop mod configuration"
LABEL org.opencontainers.image.url="https://www.avorion.net/"
LABEL org.opencontainers.image.source="https://github.com/KagurazakaNyaa/avorion-docker"

USER root

ARG DEBIAN_FRONTEND=noninteractive
ARG AVORION_BRANCH=

RUN apt-get update \
    && apt-get install -y --no-install-recommends --no-install-suggests \
        ca-certificates \
        libsdl2-2.0-0 \
    && rm -rf /var/lib/apt/lists/*

USER steam

ENV AVORION_APP_ID=565060
ENV AVORION_GAME_APP_ID=445220
ENV AVORION_SERVER_DIR=/home/steam/avorion-dedicated
ENV AVORION_DATA_PATH=/home/steam/.avorion/galaxies
ENV GALAXY_NAME=avorion_galaxy
ENV FORCE_UPDATE=false
ENV VALIDATE_SERVER=true
ENV UPDATE_WORKSHOP_MODS=true
ENV SERVER_NAME="Avorion Server"
ENV ADMIN_STEAM_IDS=
ENV MAX_PLAYERS=
ENV SERVER_PORT=27000
ENV SERVER_PUBLIC=
ENV SERVER_LISTED=
ENV USE_STEAM_NETWORKING=
ENV EXTRA_ARGS=
ENV LD_LIBRARY_PATH="/home/steam/avorion-dedicated:/home/steam/avorion-dedicated/linux64"

WORKDIR /home/steam/avorion-dedicated

RUN update_args="" \
    && if [ -n "${AVORION_BRANCH}" ]; then update_args="${update_args} -beta ${AVORION_BRANCH}"; fi \
    && /home/steam/steamcmd/steamcmd.sh \
        +force_install_dir "${AVORION_SERVER_DIR}" \
        +login anonymous \
        +app_update "${AVORION_APP_ID}" ${update_args} validate \
        +quit

COPY --chmod=0755 docker-entrypoint.sh /docker-entrypoint.sh

RUN mkdir -p "${AVORION_DATA_PATH}/${GALAXY_NAME}"

VOLUME ["/home/steam/.avorion/galaxies"]

EXPOSE 27000/tcp 27000/udp 27003/udp 27020/udp 27021/udp

ENTRYPOINT ["/docker-entrypoint.sh"]
