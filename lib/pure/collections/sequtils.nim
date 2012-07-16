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
## This module implements operations for the built-in `seq`:idx: type
## which were inspired by functional programming languages.
##
## **Note**: This interface will change as soon as the compiler supports
## closures and proper coroutines.

proc concat*[T](seqs: openarray[seq[T]]): seq[T] =
  ## Takes several sequences' items and returns them inside of one sequence.
  var L = 0
  for seqitm in items(seqs): inc(L, len(seqitm))
  newSeq(result, L)
  var i = 0
  for s in items(seqs):
    for itm in items(s):
      result[i] = itm
      inc(i)

proc distnct*[T](seq1: seq[T]): seq[T] =
  ## Removes duplicates from a sequence and returns it.
  result = @[]
  for itm in items(seq1):
    if not result.contains(itm): result.add(itm)
    
proc zip*[S, T](seq1: seq[S], seq2: seq[T]): seq[tuple[a: S, b: T]] =
  ## Combines two sequences. If one sequence is too short,
  ## the remaining items in the longer sequence are discarded.
  var m = min(seq1.len, seq2.len)
  newSeq(result, m)
  for i in 0 .. m-1: result[i] = (seq1[i], seq2[i])

iterator filter*[T](seq1: seq[T], pred: proc(item: T): bool {.closure.}): T =
  ## Iterates through a sequence and yields every item that fulfills the
  ## predicate.
  for i in countup(0, len(seq1) -1):
    var item = seq1[i]
    if pred(item): yield seq1[i]

proc filter*[T](seq1: seq[T], pred: proc(item: T): bool {.closure.}): seq[T] =
  ## Returns all items in a sequence that fulfilled the predicate.
  accumulateResult(filter(seq1, pred))

template filterIt*(seq1, pred: expr): expr {.immediate.} =
  ## Finds a specific item in a sequence as long as the 
  ## predicate returns true. The predicate needs to be an expression
  ## containing ``it``: ``filterIt("abcxyz", it == 'x')``.
  block:
    var result: type(seq1) = @[]
    for it in items(seq1):
      if pred: result.add(it)
    result

