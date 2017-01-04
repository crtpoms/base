#!/bin/bash
set -e

# construct yesterdays date (cannot use todays as archive wont exist) and set url for archive
yesterdays_date=$(date -d "yesterday" +%Y/%m/%d)

# now set pacman to use snapshot for packages for yesterdays date
echo 'Server = https://archive.archlinux.org/repos/'"${yesterdays_date}"'/$repo/os/$arch' > /etc/pacman.d/mirrorlist
echo 'Server = https://ala.seblu.net/repos/'"${yesterdays_date}"'/$repo/os/$arch' >> /etc/pacman.d/mirrorlist

echo "[info] content of arch mirrorlist file"
cat /etc/pacman.d/mirrorlist

# update keyring and packages ignoring filesystem (docker limitation)
pacman -Sy archlinux-keyring && pacman -Syyuf --ignore filesystem --noconfirm

# set locale
echo en_US.UTF-8 UTF-8 > /etc/locale.gen
locale-gen
echo LANG="en_US.UTF-8" > /etc/locale.conf

# add user "nobody" to primary group "users" (will remove any other group membership)
usermod -g users nobody

# add user "nobody" to secondary group "nobody" (will retain primary membership)
usermod -a -G nobody nobody

# setup env for user nobody
mkdir -p /home/nobody
chown -R nobody:users /home/nobody
chmod -R 775 /home/nobody
chsh -s /bin/bash nobody

# upgrade pacman db
pacman-db-upgrade

# delete any local keys
rm -rf /root/.gnupg

# force re-creation of /root/.gnupg and start dirmgr
dirmngr </dev/null

# refresh keys for pacman
pacman-key --refresh-keys

# force re-install of ncurses 6.x with 5.x backwards compatibility (can be removed onced all apps have switched over to ncurses 6.x)
# curl -o /tmp/ncurses5-compat-libs-x86_64.pkg.tar.xz -L https://github.com/crtpoms/packages/raw/master/compiled/ncurses5-compat-libs-x86_64.pkg.tar.xz
# pacman -U /tmp/ncurses5-compat-libs-x86_64.pkg.tar.xz --noconfirm

# find latest tini release tag from github and install
release_tag=$(curl -s https://github.com/krallin/tini/releases | grep -P -o -m 1 '(?<=/krallin/tini/releases/tag/)[^"]+')
curl -o /usr/bin/tini -L https://github.com/krallin/tini/releases/download/"${release_tag}"/tini-amd64 && chmod +x /usr/bin/tini

# install additional packages
pacman -S supervisor vim ldns moreutils net-tools dos2unix unzip unrar htop jq lynx --noconfirm

# link vi to vim
(cd /usr/bin && ln -s vim vi )

# cleanup
yes|pacman -Scc
rm -rf /usr/share/locale/*
rm -rf /usr/share/man/*
rm -rf /root/*
rm -rf /tmp/*
