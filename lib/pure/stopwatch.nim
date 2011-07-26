#
#
#            Nimrod's Runtime Library
#        (c) Copyright 2011 Alex Mitchell
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## :Author: Alex Mitchell
##
## This module implements a stopwatch without the use of threads.



import times
import os
type
    TStopwatch* = object of TObject ##An object that measures the time from start to finish.
        Running : bool
        ElapsedTime* : int64 ##Returns the elapsed time between calling 'start' and 'stop' in seconds.
        StartTime : TTime
        EndTime : TTime
        NeedsReset* : bool ##Returns whether this stopwatch needs to be reset before futher use.
    EInvalidOperation* = object of E_Base ##An exception called when an object is in an invalid state for the called function.

proc initStopwatch*() : TStopwatch =
    ##Returns a new Stopwatch object.
    
    var sw : TStopwatch
    
    sw.Running = false
    sw.NeedsReset = false
    sw.reset()
    return sw
proc reset*(sw : var TStopwatch) =
    ##Resets the stopwatch to its default values.
    if sw.Running: raise newException(EInvalidOperation, "Cannot reset a running stopwatch.")
    sw.Running = false
    sw.ElapsedTime = 0
    sw.NeedsReset = false
proc start*(sw : var TStopwatch) =
    ##Starts the stopwatch.
     
    if sw.NeedsReset: raise newException(EInvalidOperation, "This stopwatch needs to be reset before you can be used again.")

    if sw.Running: raise newException(EInvalidOperation, "This stopwatch is already running. Cannot start it.")

    sw.NeedsReset = true
    sw.Running = true
    sw.StartTime = getTime()

proc stop*(sw : var TStopwatch) =
    ##Stops the stopwatch and updates the ElapsedTime value.
    if sw.Running:
        sw.EndTime = getTime()
        sw.Running = false
        sw.ElapsedTime = sw.EndTime - sw.StartTime

    else: raise newException(EInvalidOperation, "This stopwatch is already in the stopped state.")
