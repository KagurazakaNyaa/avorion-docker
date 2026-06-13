# avorion-docker

Avorion dedicated server Docker image with SteamCMD server updates and Workshop mod configuration on startup.

## Features

- Installs Avorion dedicated server app `565060` during image build.
- Optionally updates and validates the server on container start.
- Keeps Workshop mod configuration inside the galaxy save, then uses SteamCMD to update configured Workshop mods on startup.
- Runs as the non-root `steam` user from `cm2network/steamcmd`.
- Provides a scheduled GitHub Actions update check that only triggers builds when Steam changes.

## Quick start

```bash
docker run -d --name avorion \
  -p 27000:27000/tcp \
  -p 27000:27000/udp \
  -p 27003:27003/udp \
  -p 27020:27020/udp \
  -p 27021:27021/udp \
  -v ./data/galaxies:/home/steam/.avorion/galaxies \
  kagurazakanyaa/avorion:latest
```

Or use Compose:

```bash
docker compose up -d
```

If you use a bind mount, make sure it is writable by UID/GID `1000:1000`:

```bash
mkdir -p ./data/galaxies
sudo chown -R 1000:1000 ./data
```

## Environment variables

| Variable | Description | Default |
| --- | --- | --- |
| `GALAXY_NAME` | Galaxy/save directory name. | `avorion_galaxy` |
| `SERVER_NAME` | Server name shown in browser/query output. | `Avorion Server` |
| `SERVER_PORT` | Main Avorion port. Expose matching TCP and UDP ports if changed. | `27000` |
| `ADMIN_STEAM_IDS` | Comma-separated 64-bit Steam IDs passed as repeated `--admin` flags. | empty |
| `MAX_PLAYERS` | Optional `--max-players` value. | empty |
| `SERVER_PUBLIC` | Optional `--public` value. | empty |
| `SERVER_LISTED` | Optional `--listed` value. | empty |
| `USE_STEAM_NETWORKING` | Optional `--use-steam-networking` value. | empty |
| `FORCE_UPDATE` | Run SteamCMD `app_update` on every container start. | `false` |
| `VALIDATE_SERVER` | Add `validate` when updating server files. | `true` |
| `UPDATE_WORKSHOP_MODS` | Parse `${GALAXY_NAME}/modconfig.lua` and update Workshop mods with SteamCMD on startup. | `true` |
| `AVORION_BRANCH` | Optional Steam beta branch, for example `beta`. | empty |
| `AVORION_BETA_PASSWORD` | Optional Steam beta password used by startup updates. | empty |
| `EXTRA_ARGS` | Extra arguments appended to `AvorionServer`. | empty |

## Workshop mods

Avorion manages Workshop mods through `modconfig.lua` in the galaxy directory. This file is part of the save data under `/home/steam/.avorion/galaxies/${GALAXY_NAME}`, so it should live in the mounted volume with the rest of the galaxy configuration.

When `modconfig.lua` contains Workshop IDs, the entrypoint parses `workshopid = "..."` entries and updates them with SteamCMD before Avorion starts. Avorion can still verify/load them from the galaxy `workshop` directory during startup.

Example:

```lua
modLocation = ""
forceEnabling = false

mods =
{
    {workshopid = "1691539727"},
    {workshopid = "1691591293"},
}

allowed =
{
    {id = "1691539727"},
}
```

Create or edit this file at `./data/galaxies/avorion_galaxy/modconfig.lua` when using the included Compose file.

## Volumes

| Path | Description |
| --- | --- |
| `/home/steam/.avorion/galaxies` | Galaxy saves, server configuration, logs, and `modconfig.lua`. |

## Ports

Avorion uses these ports by default:

| Port | Protocol |
| --- | --- |
| `27000` | TCP/UDP |
| `27003` | UDP |
| `27020` | UDP |
| `27021` | UDP |

## Build

```bash
docker build -t avorion .
```

Build a beta branch image:

```bash
docker build --build-arg AVORION_BRANCH=beta -t avorion:beta .
```

## Automatic builds

`.github/workflows/update.yml` checks Steam daily for Avorion dedicated server app `565060` updates with SteamCMD. When the Steam build ID changes, it updates `.github/steam-buildid.txt` and triggers `.github/workflows/build.yml`.

`.github/workflows/build.yml` builds the image on pushes, tags, pull requests, and manual dispatch. Pushes outside pull requests publish to both Docker Hub and GHCR.

Docker Hub publishing uses these repository secrets:

- `DOCKER_HUB_USERNAME`
- `DOCKER_HUB_ACCESS_TOKEN`

GHCR publishing uses the repository `GITHUB_TOKEN` with `packages: write` permission.
