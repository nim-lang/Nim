#
#
#           The Nimrod Compiler
#        (c) Copyright 2011 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Utilities for the compiler. Aim is to reduce the coupling between 
## the compiler and the evolving stdlib.

proc c_sprintf(buf, frmt: cstring) {.importc: "sprintf", nodecl, varargs.}

proc ToStrMaxPrecision*(f: BiggestFloat): string = 
  if f != f:
    result = "NAN"
  elif f == 0.0:
    result = "0.0"
  elif f == 0.5 * f:
    if f > 0.0: result = "INF"
    else: result = "-INF"
  else:
    var buf: array [0..80, char]    
    c_sprintf(buf, "%#.16e", f) 
    result = $buf

