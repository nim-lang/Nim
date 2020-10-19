# v1.6.x - yyyy-mm-dd


## Standard library additions and changes
-  `json` now supports parsing uint64 values > int64.high (via a new JUInt kind),
   and values beyond the range of int64/uint64 are now parsed as a new JNumber kind.



## Language changes



## Compiler changes
add `--declaredlocs` to show symbol declaration location in messages


## Tool changes

