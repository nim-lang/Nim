# v1.1 - XXXX-XX-XX


## Changes affecting backwards compatibility


### Breaking changes in the standard library


### Breaking changes in the compiler

- `typeDesc` handling is now stricter.

## Library additions


## Library changes

- Added `os.delEnv` and `nimscript.delEnv`. (#11466)

- Enable Oid usage in hashtables. (#11472)

- Added `unsafeColumnAt` procs, that return unsafe cstring from InstantRow. (#11647)

- Make public `Sha1Digest` and `Sha1State` types and `newSha1State`,
  `update` and `finalize` procedures from `sha1` module. (#11694)

- Added the `std/monotimes` module which implements monotonic timestamps.

- Consistent error handling of two `exec` overloads. (#10967)

## Language additions


## Language changes


### Tool changes

- The Nim compiler now does not recompile the Nim project via ``nim c -r`` if
  no dependent Nim file changed. This feature can be overridden by
  the ``--forceBuild`` command line option.

### Compiler changes

- VM can now cast integer type arbitrarily. (#11459)


## Bugfixes
