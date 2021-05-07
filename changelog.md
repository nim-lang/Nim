# v1.6.x - yyyy-mm-dd



## Standard library additions and changes
- Added support for parenthesized expressions in `strformat`

- Fixed buffer overflow bugs in `net`

- Added `sections` iterator in `parsecfg`.

- Make custom op in macros.quote work for all statements.

- On Windows the SSL library now checks for valid certificates.
  It uses the `cacert.pem` file for this purpose which was extracted
  from `https://curl.se/ca/cacert.pem`. Besides
  the OpenSSL DLLs (e.g. libssl-1_1-x64.dll, libcrypto-1_1-x64.dll) you
  now also need to ship `cacert.pem` with your `.exe` file.


- Make `{.requiresInit.}` pragma to work for `distinct` types.

- Added a macros `enumLen` for returning the number of items in an enum to the
  `typetraits.nim` module.

- `prelude` now works with the JavaScript target.

- Added `ioutils` module containing `duplicate` and `duplicateTo` to duplicate `FileHandle` using C function `dup` and `dup2`.

- The JSON module can now handle integer literals and floating point literals of arbitrary length and precision.
  Numbers that do not fit the underlying `BiggestInt` or `BiggestFloat` fields are kept as string literals and
  one can use external BigNum libraries to handle these. The `parseFloat` family of functions also has now optional
  `rawIntegers` and `rawFloats` parameters that can be used to enforce that all integer or float literals remain
  in the "raw" string form so that client code can easily treat small and large numbers uniformly.

- Added `randState` template that exposes the default random number generator. Useful for library authors.

- Added `asyncdispatch.activeDescriptors` that returns the number of currently
  active async event handles/file descriptors


## Language changes

- `nimscript` now handles `except Exception as e`

- The `cstring` doesn't support `[]=` operator in JS backend.



## Compiler changes



- Added `unsafeIsolate` and `extract` to `std/isolation`.

- `--hint:CC` now goes to stderr (like all other hints) instead of stdout.

- json build instructions are now generated in `$nimcache/outFileBasename.json`
  instead of `$nimcache/projectName.json`. This allows avoiding recompiling a given project
  compiled with different options if the output file differs.

- `--usenimcache` (implied by `nim r main`) now generates an output file that includes a hash of
  some of the compilation options, which allows caching generated binaries:
  nim r main # recompiles
  nim r -d:foo main # recompiles
  nim r main # uses cached binary
  nim r main arg1 arg2 # ditto (runtime arguments are irrelevant)

- The style checking of the compiler now supports a `--styleCheck:usages` switch. This switch
  enforces that every symbol is written as it was declared, not enforcing
  the official Nim style guide. To be enabled, this has to be combined either
  with `--styleCheck:error` or `--styleCheck:hint`.

## Tool changes

