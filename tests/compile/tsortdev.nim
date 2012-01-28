discard """
  disabled: false
"""

import math, algorithm

proc sorted[T](a: openArray[T], order: TSortOrder): bool = 
  result = true
  for i in 0 .. < a.high:
    if cmp(a[i], a[i+1]) * order > 0: 
      echo "Out of order: ", a[i], " ", a[i+1]
      result = false

proc bubbleSort[T](a: var openArray[T], 
                   cmp: proc (x, y: T): int,
                   order = TSortOrder.Ascending) =
  while true:
    var sorted = true
    for i in 0 .. a.len-2:
      if cmp(a[i], a[i+1]) * order > 0:
        swap(a[i], a[i+1])
        sorted = false
    if sorted: break

when isMainModule:
  proc main() =
    const order = Ascending
    var data: seq[string] = @[]
    
    var L = random(59)
    for i in 0..1: 
      echo "loop: ", i
      #newSeq(data, L)
      setLen(data, L)
      for j in 0 .. L-1:
        data[j] = $(math.random(90) - 10)
        assert getRefcount(data[j]) == 1
        {.watchpoint: data.}
      var copy = data
      for j in 0 .. L-1:
        assert getRefcount(copy[j]) == 1
        assert(cast[pointer](copy[j]) != cast[pointer](data[i]))
      
      bubblesort(data, system.cmp, order)
      if not sorted(data, order):
        quit "bubblesort failed"

      sort(copy, cmp, order)
      for j in 0 .. L-1:
        let rc = getRefcount(data[j])
        if rc != 1:
          echo "RC IST ", rc, " j: ", j
          assert getRefcount(data[j]) == 1
    when false:
      if copy.len != data.len: 
        quit "lengths differ!"
      for i in 0 .. copy.high:
        if copy[i] != data[i]:
          quit "algorithms differ!"
    when false:
      for i in 0..10_000:
        var data: seq[int]
        var L = random(59)
        newSeq(data, L)
        for j in 0 .. L-1: 
          data[j] = (math.random(90) - 10)
        var copy = data
        sort(data, cmp[int], order)
        if not sorted(data, order):
          quit "sort for seq[int] failed"
        bubblesort(copy, system.cmp[int], order)
        if copy.len != data.len: 
          quit "lengths differ!"
        for i in 0 .. copy.high:
          if copy[i] != data[i]:
            quit "algorithms differ!"

  main()

echo "done"

