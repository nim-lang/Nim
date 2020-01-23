# v1.0.6 - 2020-01-24


## Bugfixes

### Fixed issues

- Fixed "Nim stdlib style issues with --styleCheck:error"
  ([#12687](https://github.com/nim-lang/Nim/issues/12687))
- Fixed "new(ref MyObject) doesn't work at compile time"
  ([#12488](https://github.com/nim-lang/Nim/issues/12488))
- Fixed "Accessing the wrong variant field in the VM does not trigger the appropriate error message"
  ([#11727](https://github.com/nim-lang/Nim/issues/11727))
- Fixed "orderedTable.del() crashes with unitialized table"
  ([#12798](https://github.com/nim-lang/Nim/issues/12798))
- Fixed "semfold bug with negative value * 0"
  ([#12783](https://github.com/nim-lang/Nim/issues/12783))
- Fixed "nimsuggest `use` command does not return all instances of symbol"
  ([#12832](https://github.com/nim-lang/Nim/issues/12832))
- Fixed "Codegen ICE in allPathsAsgnResult"
  ([#12827](https://github.com/nim-lang/Nim/issues/12827))
- Fixed "Static[T] + syntactic error in the for loop = compiler crash"
  ([#12148](https://github.com/nim-lang/Nim/issues/12148))
- Fixed "Incorrect unused import warning involving templates and tables"
  ([#12885](https://github.com/nim-lang/Nim/issues/12885))
- Fixed "regression(1.0.4): undeclared identifier: 'readLines'; plus another regression and bug"
  ([#13013](https://github.com/nim-lang/Nim/issues/13013))
- Fixed "`nim doc` treats `export localSymbol` incorrectly"
  ([#13100](https://github.com/nim-lang/Nim/issues/13100))
- Fixed "symbols not defined in the grammar"
  ([#10665](https://github.com/nim-lang/Nim/issues/10665))
- Fixed "nim-gdb is missing from all released packages"
  ([#13104](https://github.com/nim-lang/Nim/issues/13104))
- Fixed "[JS] Move is not defined"
  ([#9674](https://github.com/nim-lang/Nim/issues/9674))
- Fixed "Error: usage of 'isNil' is a user-defined error"
  ([#11440](https://github.com/nim-lang/Nim/issues/11440))


### Other bugfixes

- make addQuoted work on nimscript (#12717)
- fix db_mysql getRow() when column is null error raised (#12806)
- Fixed objects being erroneously zeroed out before object construction (#12814)
- added cstrutils (#12858): fixed for 'csuCmpIgnoreStyle' error on hotcodereloading
- Better clang_cl support (#12896)
- fix cmdline bugs affecting nimBetterRun correctness (#12933)
- fixes a bug that kept sugar.collect from working with for loop macros
- Path substitution for --out and --outdir (#12796)
- fix crash due to errant symbols in nim.cfg (#13073)
- Allow `-o` option for `buildIndex` (#13037)
- Deleted misplaced separator (#13085): Misplaced separator, which was constantly breaking compilation on Haiku OS, was deleted.
- fixes an asyncftpclient bug; refs #13096
- fix the ftp store function read the local file bug (#13108)
- fix rtti sizeof for varargs in global scope (#13125)
- Correctly remove a key from CountTable when it is set to zero.
- fixes the distros.nim regression
- fixes a critical times.nim bug reported on IRC
- c_fflush() the rawWrite() buffer


## Documentation improvements

- Fixed "Documentation, Testament missing from "Tools available with Nim""
  ([#12251](https://github.com/nim-lang/Nim/issues/12251))
- Manual update: custom exceptions (#12847)
- times/getClockStr(): fix mistake in doc
- Fix typo and improve in code-block of 'lib/pure/parseutils.nim'
