#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2008 Andreas Rumpf
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# Simple platform dependant lock implementation

type
  TSimpleLock = pointer

proc initLock(s: TSimpleLock)
proc deinitLock(s: TSimpleLock)
proc lock(s: TSimpleLock)
proc unlock(s: TSimpleLock)
