#
#
#            Nim's Runtime Library
#        (c) Copyright 2016 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## ``system.addQuitProc`` is nice and very useful but due to its C-based
## implementation it doesn't support closures which limits its usefulness.
## This module fixes this. Later versions of this module will also
## support the JavaScript backend.

var
  gClosures: seq[proc () {.closure.}]

proc callClosures() {.noconv.} =
  for i in countdown(gClosures.len-1, 0):
    gClosures[i]()

proc addQuitClosure*(cl: proc () {.closure.}) =
  ## Like ``system.addQuitProc`` but it supports closures.
  if gClosures.len == 0:
    addQuitProc(callClosures)
    gClosures = @[cl]
  else:
    gClosures.add(cl)
