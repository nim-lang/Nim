discard """
output: '''
bye
hi
hola
hola
'''
  
"""

#infers void auto
import std/[sugar, sequtils]

proc sup(fn: proc(a: string)) = fn("bye")
sup(proc(a:auto): auto = echo "bye")
sup(x => echo "hi")

let xs = toSeq(1..2)
proc tap[T](xs: seq[T], fn: (x: T)->void): seq[T] =
  for x in xs:
    fn(x)
  xs
discard xs.tap((x) => echo "hola")