#!/usr/bin/env bash

# https://github.com/johnj/centos-to8-upgrade

# CentOS no longer provides a supported path for upgrading CentOS-7 systems to
# CentOS-8.
#
# So here is a HIGHLY EXPERIMENTAL and HIGHLY DANGEROUS script for doing an
# in-place/online upgrade to 8.
#
# Backups are your friend, it is entirely possible you will be left with a
# non-functioning and irrepairable system after this process finishes.

function info() {
  echo "[$(date)] [info] $1"
}

function preflight_check() {
  echo -n "[preflight] checking $1"
  if [[ $2 -eq 0 ]]; then
    echo " ... PASSED"
  else
    echo " ... FAILED ($3)"
    exit 1
  fi
}

STAGING_DIR=${STAGING_DIR:-/to8}
CONFIG_DIRS=${CONFIG_DIRS:-etc}

test "$(whoami)" == "root"
preflight_check "if you are running this as root" $? "you need to run me as root"

test "$(grep VERSION_ID /etc/os-release | awk -F'=' '{ print $2 }')" == '"7"'
preflight_check "if you are running this on a RHEL-like 7 system" $? "you need to run me from a RHEL-like 7 OS"

test -x "$(command -v rsync)" 
preflight_check "if rsync is installed" $? "you need to install rsync"

if [[ ! -d $STAGING_DIR ]]; then
  mkdir -p $STAGING_DIR
  for i in `echo dev proc run`; do
    mkdir $STAGING_DIR/$i
    mount -o bind /$i $STAGING_DIR/$i
  done
fi

available=$(df --total $STAGING_DIR | tail -n1 | awk '{ print $4 }')
test "$((available))" -ge 2000000
preflight_check "if you have at least 2GB in the staging directory (${STAGING_DIR}), you can override this by setting the env var STAGING_DIR (ie, STAGING_DIR='/var/to8' $0)" $? "you need at least 2GB of free space to run me"

echo
echo "Preflight checks PASSED"
echo

which selinuxenabled 2>/dev/null 1> /dev/null

if [[ $? -eq 0 ]]; then
  selinuxenabled 2>/dev/null 1> /dev/null
  if [[ $? -eq 0 ]]; then
    echo "SELinux is enabled, this process will temporarily set SELinux to Permissive mode, continue? [Y/n]"
    if [ -z "${NONINTERACTIVE}" ]; then
      read -n 1 yn
    else
      yn="y"
    fi
    echo
    if [[ "${yn}" == "n" ]]; then
      echo "Aborting $0"
      exit 4
    else
      echo "Continuing..."
      SELINUX_BEFORE="$(getenforce)"
      setenforce 0
    fi
  fi
fi

info "starting to make a copy of /${CONFIG_DIRS} into ${STAGING_DIR}"
rsync -avu /${CONFIG_DIRS} ${STAGING_DIR} 2>&1 | tee -a $STAGING_DIR/to8.log
info "finished making a copy of /${CONFIG_DIRS} into ${STAGING_DIR}"

info "setting up CentOS 8 repository in ${STAGING_DIR}"
mkdir -p $STAGING_DIR/etc/yum.repos.d $STAGING_DIR/etc/pki/rpm-gpg $STAGING_DIR/etc/yum/vars

echo "8" > $STAGING_DIR/etc/yum/vars/releasever

# these will be replaced by dnf symlinks
mkdir -p $STAGING_DIR/etc/yum/yum7
mv $STAGING_DIR/etc/yum/{pluginconf.d,protected.d,vars} $STAGING_DIR/etc/yum/yum7

# from https://www.centos.org/keys/RPM-GPG-KEY-CentOS-Official
# more info: https://www.centos.org/keys/

# pub  4096R/8483C65D 2019-05-03 CentOS (CentOS Official Signing Key) <security@centos.org>
#        Key fingerprint = 99DB 70FA E1D7 CE22 7FB6  4882 05B5 55B3 8483 C65D
cat >/etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial <<EOF
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v2.0.22 (GNU/Linux)

mQINBFzMWxkBEADHrskpBgN9OphmhRkc7P/YrsAGSvvl7kfu+e9KAaU6f5MeAVyn
rIoM43syyGkgFyWgjZM8/rur7EMPY2yt+2q/1ZfLVCRn9856JqTIq0XRpDUe4nKQ
8BlA7wDVZoSDxUZkSuTIyExbDf0cpw89Tcf62Mxmi8jh74vRlPy1PgjWL5494b3X
5fxDidH4bqPZyxTBqPrUFuo+EfUVEqiGF94Ppq6ZUvrBGOVo1V1+Ifm9CGEK597c
aevcGc1RFlgxIgN84UpuDjPR9/zSndwJ7XsXYvZ6HXcKGagRKsfYDWGPkA5cOL/e
f+yObOnC43yPUvpggQ4KaNJ6+SMTZOKikM8yciyBwLqwrjo8FlJgkv8Vfag/2UR7
JINbyqHHoLUhQ2m6HXSwK4YjtwidF9EUkaBZWrrskYR3IRZLXlWqeOi/+ezYOW0m
vufrkcvsh+TKlVVnuwmEPjJ8mwUSpsLdfPJo1DHsd8FS03SCKPaXFdD7ePfEjiYk
nHpQaKE01aWVSLUiygn7F7rYemGqV9Vt7tBw5pz0vqSC72a5E3zFzIIuHx6aANry
Gat3aqU3qtBXOrA/dPkX9cWE+UR5wo/A2UdKJZLlGhM2WRJ3ltmGT48V9CeS6N9Y
m4CKdzvg7EWjlTlFrd/8WJ2KoqOE9leDPeXRPncubJfJ6LLIHyG09h9kKQARAQAB
tDpDZW50T1MgKENlbnRPUyBPZmZpY2lhbCBTaWduaW5nIEtleSkgPHNlY3VyaXR5
QGNlbnRvcy5vcmc+iQI3BBMBAgAhBQJczFsZAhsDBgsJCAcDAgYVCAIJCgsDFgIB
Ah4BAheAAAoJEAW1VbOEg8ZdjOsP/2ygSxH9jqffOU9SKyJDlraL2gIutqZ3B8pl
Gy/Qnb9QD1EJVb4ZxOEhcY2W9VJfIpnf3yBuAto7zvKe/G1nxH4Bt6WTJQCkUjcs
N3qPWsx1VslsAEz7bXGiHym6Ay4xF28bQ9XYIokIQXd0T2rD3/lNGxNtORZ2bKjD
vOzYzvh2idUIY1DgGWJ11gtHFIA9CvHcW+SMPEhkcKZJAO51ayFBqTSSpiorVwTq
a0cB+cgmCQOI4/MY+kIvzoexfG7xhkUqe0wxmph9RQQxlTbNQDCdaxSgwbF2T+gw
byaDvkS4xtR6Soj7BKjKAmcnf5fn4C5Or0KLUqMzBtDMbfQQihn62iZJN6ZZ/4dg
q4HTqyVpyuzMXsFpJ9L/FqH2DJ4exGGpBv00ba/Zauy7GsqOc5PnNBsYaHCply0X
407DRx51t9YwYI/ttValuehq9+gRJpOTTKp6AjZn/a5Yt3h6jDgpNfM/EyLFIY9z
V6CXqQQ/8JRvaik/JsGCf+eeLZOw4koIjZGEAg04iuyNTjhx0e/QHEVcYAqNLhXG
rCTTbCn3NSUO9qxEXC+K/1m1kaXoCGA0UWlVGZ1JSifbbMx0yxq/brpEZPUYm+32
o8XfbocBWljFUJ+6aljTvZ3LQLKTSPW7TFO+GXycAOmCGhlXh2tlc6iTc41PACqy
yy+mHmSv
=kkH7
-----END PGP PUBLIC KEY BLOCK-----
EOF

cat >$STAGING_DIR/etc/yum.repos.d/CentOS-Base.repo <<EOF
[BaseOS]
name=CentOS-8 - Base
mirrorlist=http://mirrorlist.centos.org/?release=8&arch=\$basearch&repo=BaseOS&infra=\$infra
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF

cat >$STAGING_DIR/etc/yum.repos.d/CentOS-AppStream.repo <<EOF
[AppStream]
name=CentOS-8 - AppStream
mirrorlist=http://mirrorlist.centos.org/?release=8&arch=\$basearch&repo=AppStream&infra=\$infra
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF

cat >$STAGING_DIR/etc/yum.repos.d/CentOS-Extras.repo <<EOF
[Extras]
name=CentOS-8 - Extras
mirrorlist=http://mirrorlist.centos.org/?release=8&arch=\$basearch&repo=Extras&infra=\$infra
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF

info "starting CentOS-8 setup in ${STAGING_DIR}"
yum install -y --installroot=$STAGING_DIR hostname yum centos-release glibc-langpack-en $(rpmquery -a --queryformat '%{NAME} ') 2>&1 | tee -a $STAGING_DIR/to8.log
info "finished CentOS-8 setup in ${STAGING_DIR}"

info "beginning to sync ${STAGING_DIR} to /"
rsync -irazvAX --progress --backup --backup-dir=$STAGING_DIR/to8_backup_$(date +\%Y-\%m-\%d) $STAGING_DIR/* / --exclude="var/cache/yum/x86_64/8/BaseOS/packages" --exclude="tmp" --exclude="sys" --exclude="lost+found" --exclude="mnt" --exclude="proc" --exclude="dev" --exclude="media" --exclude="to8.yum.log"
info "finished syncing ${STAGING_DIR} to /"

info "refreshing grub config for /boot"
grub2-mkconfig -o /boot/grub2/grub.cfg
info "grub config reload for /boot finished"

info "setting up new repo files"
for f in `ls /etc/yum.repos.d/CentOS*.repo.rpmnew`; do
  n=$(echo $f | sed -e 's/\.rpmnew$//')
  mv -vf $f $n
done

if [ -e /etc/os-release.rpmnew ]; then
  mv /etc/os-release /etc/os-release.rpmold
  mv /etc/os-release.rpmnew /etc/os-release
fi

# this locale reference seems to have changed in 8
if [[ "$LANG" == "en_US.UTF-8" ]]; then
  localectl set-locale en_US.utf8
fi

if [ -n "$SELINUX_BEFORE" ]; then
  info "Almost done, since you had SELinux enabled, attempting to restore the contexts."
  restorecon -e $STAGING_DIR -Rv / 2>&1 | tee -a $STAGING_DIR/to8.log
  info "SELinux contexts restored."
fi

systemctl daemon-reload

echo "Packages which could not be migrated into CentOS 8 using the base repositories:"
grep -e 'No package .* available' $STAGING_DIR/to8.log | awk '{ print $3 }' | tr $'\n' ' '

echo

info "CentOS-8 has been setup, please reboot to load the CentOS-8 kernel and modules."

info "If you would like to move to CentOS-8-Stream, please install the centos-release-stream package from CentOS Extras by running:"
info 'yum install --enablerepo="extras" centos-release-stream'
