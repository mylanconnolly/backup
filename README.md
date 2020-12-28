# Backup

This is a Ruby backup tool that mostly leverages tar to create backup archives.

Currently the main entrypoint would be something like:

```bash
./backup.rb backup_files /path/to/back/up -c '[bz2|xz|zstd]' -d /path/to/put/backup
```

The first positional argument is the path you would like to back up.

The `-c` argument determines the compressor type to use. You may choose one of the listed options (`bz2`, `xz`, or `zstd`; `xz` being the default).

Finally, the `-d` option specifies where the directory with the backups should be.

There are a few important things to note about what is not being backed up as part of this:

- We are ignoring files that are ignored by VCS (i.e., it is in a gitignore file).
- We are ignoring a lot of common patterns that aren't often backed up (i.e., cache files, tmp files, etc.).

If you'd like to change this behavior, the method `TarBackup#backup_cmd` is used to build the command we use to invoke tar. That could be changed to suit your purposes.
