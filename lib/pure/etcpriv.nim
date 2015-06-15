#
#
#            Nim's Runtime Library
#        (c) Copyright 2015 Nim Authors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module contains utils that are less then easy to categorize and
## don't really warrant a specific module. They are private to compiler
## and stdlib usage, and should not be used outside of that - they may
## change or disappear at any time.


# Used by pure/hashes.nim, and the compiler parsing
const magicIdentSeparatorRuneByteWidth* = 3

# Used by pure/hashes.nim, and the compiler parsing
proc isMagicIdentSeparatorRune*(cs: cstring, i: int): bool  {. inline } =
  result =  cs[i] == '\226' and 
            cs[i + 1] == '\128' and
            cs[i + 2] == '\147'     # en-dash  # 145 = nb-hyphen
