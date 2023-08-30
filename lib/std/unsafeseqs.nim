#
#
#            Nim's Runtime Library
#        (c) Copyright 2023 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module provides some high performance sequence operations.

import typetraits

when not defined(js):
  template newSeqImpl(T, len) =
    result = newSeqOfCap[T](len)
    when defined(nimSeqsV2):
      cast[ptr int](addr result)[] = len
    else:
      var s = cast[PGenericSeq](result)
      s.len = len

  proc newSeqUnsafe*[T](len: Natural): seq[T] =
    ## Creates a new sequence of type `seq[T]` with length `len`.
    ##
    ## Note that the sequence will be uninitialized.
    ## After the creation of the sequence you should assign
    ## entries to the sequence instead of adding them.
    runnableExamples:
      # newSeqUnsafe can be safely used for types, which don't contain
      # managed memory or have destructors
      var x = newSeqUnsafe[int](3)
      assert len(x) == 3
      x[0] = 10

      # be cautious to use it with types with managed memory or destructors
      # and `{.nodestroy.}` can be handy in these cases
      proc initStringSeq(x: Natural): seq[string] {.nodestroy.} =
        result = newSeqUnsafe[string](x)
        for i in 0..<x: result[i] = "abc"

      let s = initStringSeq(10)
      assert len(s) == 10
      assert s[0] == "abc"
    newSeqImpl(T, len)

  proc newSeqUninit*[T](len: Natural): seq[T] =
    ## Creates a new sequence of type `seq[T]` with length `len`.
    ##
    ## Only available for types, which don't contain
    ## managed memory or have destructors.
    ## Note that the sequence will be uninitialized.
    ## After the creation of the sequence you should assign
    ## entries to the sequence instead of adding them.
    runnableExamples:
      var x = newSeqUninit[int](3)
      assert len(x) == 3
      x[0] = 10

    when supportsCopyMem(T):
      newSeqImpl(T, len)
    else:
      {.error: "The type T cannot contain managed memory or have destructors".}
