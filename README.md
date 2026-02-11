# proxmoxve-kiwix
A simple Proxmox [Kiwix](https://www.kiwix.org) LXC installer

Download kiwix.sh and run it:
```shell
wget -qLO - https://raw.githubusercontent.com/tewalds/proxmoxve-kiwix/refs/heads/main/kiwix.sh
bash kiwix.sh
```
or all at once:
```shell
ZIM_DIR=/mnt/kiwix-zims bash -c "$(wget -qLO - https://raw.githubusercontent.com/tewalds/proxmoxve-kiwix/refs/heads/main/kiwix.sh)"
```

You can get zims from https://library.kiwix.org
