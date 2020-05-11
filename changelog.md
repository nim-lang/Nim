# v1.0.8 - xxxx-xx-xx


## Changes affecting backwards compatibility



### Breaking changes in the standard library

- `CountTable.mget` has been removed from `tables.nim`. It didn't work, and it
  was an oversight to be included in v1.0.



### Breaking changes in the compiler



## Library additions

- Added `browsers.osOpen` const alias for the operating system specific *"open"* command.


## Library changes



## Language additions



- Fix a bug where calling `close` on io streams in osproc.startProcess was a noop and led to
  hangs if a process had both reads from stdin and writes (eg to stdout).

## Language changes



### Tool changes



### Compiler changes




## Bugfixes
