#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2010 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

const
  isMultiThreaded* = true
  maxThreads = 256
  
type
  TThread* {.final, pure.} = object
    next: ptr TThread
  TThreadFunc* = proc (closure: pointer) {.cdecl.}
  
proc createThread*(t: var TThread, fn: TThreadFunc) = 
  nil
  
proc destroyThread*(t: var TThread) =
  nil




