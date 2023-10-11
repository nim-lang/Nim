# v2.2.0 - yyyy-mm-dd


## Changes affecting backward compatibility


## Standard library additions and changes

[//]: # "Changes:"

- Changed `std/osfiles.copyFile` to allow to specify `bufferSize` instead of a hardcoded one.
- Changed `std/osfiles.copyFile` to use `POSIX_FADV_SEQUENTIAL` hints for kernel-level aggressive sequential read-aheads.

[//]: # "Additions:"

- Added `newStringUninit` to system, which creates a new string of length `len` like `newString` but with uninitialized content.
- Added `setLenUninit` to system, which doesn't initalize
slots when enlarging a sequence.
- Added `hasDefaultValue` to `std/typetraits` to check if a type has a valid default value.
- Added Viewport API for the JavaScript targets in the `dom` module.

[//]: # "Deprecations:"

- Deprecates `system.newSeqUninitialized`, which is replaced by `newSeqUninit`.

[//]: # "Removals:"


## Language changes

- `noInit` can be used in types and fields to disable member initializers in the C++ backend. 

## Compiler changes

- `--nimcache` using a relative path as the argument in a config file is now relative to the config file instead of the current directory.

## Tool changes

- koch now allows bootstrapping with `-d:nimHasLibFFI`, replacing the older option of building the compiler directly w/ the `libffi` nimble package in tow.

