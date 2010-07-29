#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2010 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## Main file to generate a DLL from the standard library. 
## The default Nimrtl does not only contain the ``system`` module, but these 
## too:
##
## * strutils
## * parseutils
## * parseopt
## * parsecfg
## * strtabs
## * times
## * os
## * osproc
## * pegs
## * unicode
## * ropes
## * re
## 
## So the resulting dynamic library is quite big. However, it is very easy to
## strip modules out. Just modify the ``import`` statement in
## ``lib/nimrtl.nim`` and recompile. Note that simply *adding* a module
## here is not sufficient, though.

when system.appType != "lib":
  {.error: "This file has to be compiled as a library!".}

when not defined(createNimRtl): 
  {.error: "This file has to be compiled with '-d:createNimRtl'".}



