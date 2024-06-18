# v2.2.0 - 2023-mm-dd

## Changes affecting backward compatibility

## Standard library additions and changes

`nimPreviewHashFarm` has been added to `lib/pure/hashes.nim` to activate a
64-bit string Hash producer (based upon Google's Farm Hash) which is also
much faster than the present one.  At present, this is incompatible with
`--jsbigint=off` mode.

## Language changes

## Compiler changes

## Tool changes

