# v1.8.x - yyyy-mm-dd



## Changes affecting backward compatibility



## Standard library additions and changes



## Language changes



## Compiler changes

- Added `--declaredLocs` to show symbol declaration location in messages.

- You can now enable/disable VM tracing in user code via `vmutils.vmTrace`.

- Deprecated `TaintedString` and `--taintmode`.

- Deprecated `--nilseqs` which is now a noop.

- Added `--spellSuggest` to show spelling suggestions on typos.

- Added `--filenames:abs|canonical|legacyRelProj` which replaces --listFullPaths:on|off

- Added `--processing:dots|filenames|off` which customizes `hintProcessing`

- Added `--unitsep:on|off` to control whether to add ASCII unit separator `\31` before a newline
 for every generated message (potentially multiline), so tooling can tell when messages start and end.

- Source+Edit links now appear on top of every docgen'd page when
  `nim doc --git.url:url ...` is given.

- Added `nim --eval:cmd` to evaluate a command directly, see `nim --help`.

- VM now supports `addr(mystring[ind])` (index + index assignment)

- Added `--hintAsError` with similar semantics as `--warningAsError`.

- TLS: OSX now uses native TLS (`--tlsEmulation:off`), TLS now works with importcpp non-POD types,
  such types must use `.cppNonPod` and `--tlsEmulation:off`should be used.

- Now array literals(JS backend) uses JS typed arrays when the corresponding js typed array exists,
  for example `[byte(1), 2, 3]` generates `new Uint8Array([1, 2, 3])`.

- docgen: rst files can now use single backticks instead of double backticks and correctly render
  in both rst2html (as before) as well as common tools rendering rst directly (e.g. github), by
  adding: `default-role:: code` directive inside the rst file, which is now handled by rst2html.

- Added `-d:nimStrictMode` in CI in several places to ensure code doesn't have certain hints/warnings

- Added `then`, `catch` to `asyncjs`, for now hidden behind `-d:nimExperimentalAsyncjsThen`.

- `--newruntime` and `--refchecks` are deprecated.

- Added `unsafeIsolate` and `extract` to `std/isolation`.

- `--hint:CC` now goes to stderr (like all other hints) instead of stdout.

- `--hint:all:on|off` is now supported to select or deselect all hints; it
  differs from `--hints:on|off` which acts as a (reversible) gate.
  Likewise with `--warning:all:on|off`.

- json build instructions are now generated in `$nimcache/outFileBasename.json`
  instead of `$nimcache/projectName.json`. This allows avoiding recompiling a given project
  compiled with different options if the output file differs.

- `--usenimcache` (implied by `nim r main`) now generates an output file that includes a hash of
  some of the compilation options, which allows caching generated binaries:
  nim r main # recompiles
  nim r -d:foo main # recompiles
  nim r main # uses cached binary
  nim r main arg1 arg2 # ditto (runtime arguments are irrelevant)

- `nim r` now supports cross compilation from unix to windows when specifying `-d:mingw` by using wine,
  e.g.: `nim r --eval:'import os; echo "a" / "b"'` prints `a\b`

- `nim` can compile version 1.4.0 as follows: `nim c --lib:lib --stylecheck:off compiler/nim`.

- The style checking of the compiler now supports a `--styleCheck:usages` switch. This switch
  enforces that every symbol is written as it was declared, not enforcing
  the official Nim style guide. To be enabled, this has to be combined either
  with `--styleCheck:error` or `--styleCheck:hint`.


## Tool changes



