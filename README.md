# Soft delete

A simple shell script can move file to the trash directory, recover it to the origin path or remove it completely.

## usage

```
Usage: sd [FILE]
   or: sd [OPTION] [FILE]

  -d            delete file in the trash
  -D            empty the trash
  -h -? --help  show this message and exit
  -l            list files in the trash
  -r            recover file 
```