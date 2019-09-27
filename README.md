# centos-to8-upgrade

Live/in-place/online upgrade to CentOS 8.

CentOS no longer provides a supported path for upgrading CentOS-7 systems to
CentOS-8 (Stream).

So here is a HIGHLY EXPERIMENTAL and HIGHLY DANGEROUS script for doing an
in-place/online upgrade to 8.

Backups are your friend, it is entirely possible you will be left with a
non-functioning and irrepairable system after this process finishes.

### Environment Variables

| EnvVar | Default Value | Description |
| ------ | ------ | ------ |
| STAGING_DIR | /to8 | set this to use an alternative staging directory |
| NO_PROMPTS | false | set this to a non-empty value to suppress prompts (currently the only prompt is for disabling SELinux enforcement) |
