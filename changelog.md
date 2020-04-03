# v1.4.0 - yyyy-mm-dd



## Standard library additions and changes

- The default hash for `Ordinal` has changed to something more bit-scrambling.
  `import hashes; proc hash(x: myInt): Hash = hashIdentity(x)` recovers the old
  one in an instantiation context while `-d:nimV1hash` recovers it globally.

## Language changes


## Compiler changes


## Tool changes

