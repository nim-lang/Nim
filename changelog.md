# v2.2.0 - yyyy-mm-dd


## Changes affecting backward compatibility


## Standard library additions and changes

[//]: # "Changes:"


[//]: # "Additions:"

- Adds a module `std/unsafeseqs`, which contains `newStringUninit` and `newSeqUnsafe` functions that create a new string of length `len` like `newString` but with uninitialized content.

[//]: # "Deprecations:"

- Deprecates `system.newSeqUninitialized`, which is replaced by `unsafeseqs.newSeqUninit`.

[//]: # "Removals:"


## Language changes



## Compiler changes


## Tool changes

- koch now allows bootstrapping with `-d:nimHasLibFFI`, replacing the older option of building the compiler directly w/ the `libffi` nimble package in tow.

