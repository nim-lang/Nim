# v1.8.x - yyyy-mm-dd


## Changes affecting backward compatibility



## Standard library additions and changes

## `std/smtp`

- Sends `ehlo` first. If the mail server does not understand, it sends `helo` as a fallback.

## Language changes



## Compiler changes

- `nim` can now compile version 1.4.0 as follows: `nim c --lib:lib --stylecheck:off compiler/nim`,
  without requiring `-d:nimVersion140` which is now a noop.


## Tool changes



