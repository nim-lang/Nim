# v2.2.0 - yyyy-mm-dd


## Changes affecting backward compatibility


## Standard library additions and changes

[//]: # "Changes:"


[//]: # "Additions:"

- Added `newStringUninit` to system, which creates a new string of length `len` like `newString` but with uninitialized content.
- Added `hasDefaultValue` to `std/typetraits` to check if a type has a valid default value.

[//]: # "Deprecations:"


[//]: # "Removals:"


## Language changes



## Compiler changes


## Tool changes

- koch now allows bootstrapping with `-d:nimHasLibFFI`, replacing the older option of building the compiler directly w/ the `libffi` nimble package in tow.

