#
#
#            Nim's Runtime Library
#        (c) Copyright 2017 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Wrapper for HTML 5 local storage.

when not defined(js) and not defined(Nimdoc):
  {.error: "This module only works on the JavaScript platform".}

proc getItem*(key: cstring): cstring {.importc: "localStorage.getItem".}
proc setItem*(key, value: cstring) {.importc: "localStorage.setItem".}
proc hasItem*(key: cstring): bool {.importcpp: "(localStorage.getItem(#) !== null)".}
proc clear*() {.importc: "localStorage.clear".}
proc removeItem*(key: cstring) {.importc: "localStorage.removeItem".}
