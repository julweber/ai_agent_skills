# Nextcloud Command Line Client Installation

Source: https://docs.nextcloud.com/server/stable/admin_manual/desktop/commandline.html

## Overview

The Nextcloud client packages contain a command line client, `nextcloudcmd`, that synchronizes Nextcloud files to client machines. It performs a single sync run and exits — it does not repeat synchronizations on its own or monitor for file system changes.

## Installation

### Ubuntu

```bash
sudo add-apt-repository ppa:nextcloud-devs/client
sudo apt update
sudo apt install nextcloud-client
```

### Debian

```bash
sudo apt install nextcloud-desktop-cmd
```

### CentOS

```bash
sudo yum -y install epel-release
sudo yum -y install nextcloud-client
```

### Additional References

- https://nextcloud.com/install/#install-clients
- https://launchpad.net/~nextcloud-devs/+archive/ubuntu/client
- https://pkgs.alpinelinux.org/packages?name=nextcloud-client
- https://help.nextcloud.com/t/linux-packages-status/10216

## Usage

```bash
nextcloudcmd [OPTIONS...] sourcedir nextcloudurl
```

### Credential Handling

Credentials can be embedded in the URL:

```bash
nextcloudcmd /home/user/my_sync_folder https://carla:secret@server/nextcloud
```

Or `nextcloudcmd` will prompt for username and password interactively.

### Common Options

| Option | Description |
|--------|-------------|
| `--path <path>` | Override default remote root folder (e.g. `/Documents`) |
| `--user`, `-u <user>` | Login name |
| `--password`, `-p <password>` | Password |
| `-n` | Use `netrc(5)` for login |
| `--non-interactive` | No prompts; reads `$NC_USER` and `$NC_PASSWORD` from environment |
| `--silent`, `-s` | Suppress verbose log output |
| `--trust` | Trust any SSL certificate, including invalid ones |
| `--httpproxy http://[user@pass:]<server>:<port>` | Use HTTP proxy |
| `--exclude <file>` | Exclude list file |
| `--unsyncedfolders <file>` | File containing list of unsynced folders (selective sync) |
| `--max-sync-retries <n>` | Max retries (default: 3) |
| `-h` | Sync hidden files, do not ignore them |

### Examples

Sync a local directory to a specific server subfolder via proxy:

```bash
nextcloudcmd --httpproxy http://192.168.178.1:8080 --path /Music \
             $HOME/media/music \
             https://server/nextcloud
```

Sync a local directory to a specific subfolder on the server:

```bash
nextcloudcmd --path /Documents /home/user/my_sync_folder \
             https://username:secret@server_address
```

## Exclude List

`nextcloudcmd` requires an exclude list file. It is either:
- Installed alongside the package (available in a system location), or
- Placed next to the binary as `sync-exclude.lst`, or
- Explicitly specified with `--exclude`

Example exclude list content (one pattern per line, wildcards allowed):

```
~*.tmp
._*
Thumbs.db
photothumb.db
System Volume Information
```
