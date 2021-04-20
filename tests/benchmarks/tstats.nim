{.passC: "-march=native -O3 -fPIC".}
# nim c -d:release -d:danger -x -r tstats.nim
import algorithm, math, random, sequtils, stats, strformat, times

block:
  proc selectNaive[T](a: var seq[T], index: int): T =
    a.sort()
    a[index]

  
  const
    NT = 7
    Dim = 10^NT
    dimH = Dim div 2

  var
    A = newSeqWith(Dim+1,rand(100.0))
    B = A
    t0, t1 : float
  t0 = cpuTime()
  discard quickSelect(A,0,Dim,dimH)
  t0 = cpuTime()-t0
  t1 = cpuTime()
  discard selectNaive(B,dimH)
  t1 = cpuTime()-t1
  
  echo &"quickSelect is {100.0*(1.0-t0/t1):6.2f}% faster than sort-based method for a sequence of length {Dim}"
  # quickSelect is  93.13% faster than sort-based method for a sequence of length 10000000
  
  
  
#[
(we should also have in future work a sortN which returns sorted results for bottom N items; 
 easy to do at least with quicksort; and then in future work your API can be compared to:

proc selectNaive2[T](a: seq[T], index: int): T =
  a.sortN(index)[index]
]#
