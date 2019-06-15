## v0.20.2 - XXXX-XX-XX


### Changes affecting backwards compatibility

- All `strutils.rfind` procs now take `start` and `last` like `strutils.find`
  with the same data slice/index meaning.  This is backwards compatible for
  calls *not* changing the `rfind` `start` parameter from its default.

  In the unlikely case that you were using `rfind X, start=N`, or `rfind X, N`,
  then you need to change that to `rfind X, last=N` or `rfind X, 0, N`. (This
  should minimize gotchas porting code from other languages like Python or C++.)

#### Breaking changes in the standard library


#### Breaking changes in the compiler


### Library additions


### Library changes

- Added `os.delEnv` and `nimscript.delEnv`.

### Language additions

### Language changes


### Tool changes



### Compiler changes



### Bugfixes
