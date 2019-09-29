# centos-to8-upgrade

Live/in-place/online upgrade to CentOS 8.

CentOS no longer provides a supported path for upgrading CentOS-7 systems to
CentOS-8 (Stream).

So here is a HIGHLY EXPERIMENTAL and HIGHLY DANGEROUS script for doing an
in-place/online upgrade to 8.

Most of the testing has been done on 7-Server. For desktops, YMMV.

Backups are your friend, it is entirely possible you will be left with a
non-functioning and irrepairable system after this process finishes.

### Usage

```sh
$ curl https://raw.githubusercontent.com/johnj/centos-to8-upgrade/master/to8.sh | sudo bash
```

### Requirements

* CentOS-7
* 2GB of available disk space on the $STAGING_DIR location (default /to8).

### Important Files

This process will attempt to backup all changed files into $STAGING_DIR/to8_backup_timestamp (default /to8/to8_backup_%Y_%m_%d).

### Environment Variables

| EnvVar | Default Value | Description |
| ------ | ------ | ------ |
| STAGING_DIR | /to8 | set this to use an alternative staging directory |
| CONFIG_DIRS | /etc | possible configuration directories, usually /etc is sufficient. For multiple directories set to something like "/{etc,/usr/share}" |
| NONINTERACTIVE | false | set this to a non-empty value to suppress interactive prompts (currently the only prompt is for temporarily SELinux enforcement to "Permissive") |

### CentOS-8-Stream

This process installs CentOS-8. After this process is finished, if you would like to move to CentOS-8-Stream, simply run:

```sh
# yum install --enablerepo="extras" centos-release-stream
```
