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
## This module implements lazy (cached) binding to a value. 
## Its a memory efficient way to hold large values and such.
##
## .. code-block:: Nimrod
##    when isMainModule:
##        from os import sleep
##        proc eatALotOfMemory(): seq[int] =
##           var bigSeq: seq[int] = @[]
##           for i in countup(0,999999):
##             bigSeq.add(i)
##   
##           return bigSeq
##
##        var myLazyVal = initLazy(eatALotOfMemory)
##        # At this point, memory is about 500k
##        sleep(10000)
##        echo($len(myLazyVal.value)) # Function is computed so the 
##                                    # program allocates a large amount of memory
##
##        # Now, memory is about 11,000k
##        sleep(10000)
##        echo($len(myLazyVal.value)) # This returns quicker than the last time 
##                                    # because its cached.
##
##        var someSeq: seq[int] = @[]
##        echo($(myLazyVal.value == someSeq))



type
  TLazy[T] = object of TObject ## Implements lazy (cached) binding to a value.
    val: T
    func: proc(): T
    

proc initLazy*[T](value: proc(): T): TLazy[T] =
  ## Returns a TLazy binded to a function for producing a value.
  result.func = value

proc value*[T](laz: var TLazy[T]): T =
  ## Returns the value that the TLazy is holding.
  if laz.func == nil:
      result = laz.val
  else:
      laz.val = laz.func()
      laz.func = nil
      result = laz.val

proc `==`*[T](laz: TLazy[T], val: T): bool =
  ## Compares the lazy's value to the right-hand side value.
  return laz.value == val

when isMainModule:
  from os import sleep
  proc eatALotOfMemory(): seq[int] =
     var bigSeq: seq[int] = @[]
     for i in countup(0,999999):
       bigSeq.add(i)
     
     return bigSeq

  var myLazyVal = initLazy(eatALotOfMemory)
  # At this point, memory is about 500k
  sleep(10000)
  echo($len(myLazyVal.value))
  # Now, memory is about 11,000k
  sleep(10000)
  echo($len(myLazyVal.value))

  var someSeq: seq[int] = @[]
  echo($(myLazyVal.value == someSeq))