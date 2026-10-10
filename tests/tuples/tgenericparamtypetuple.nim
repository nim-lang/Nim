# issue #25312

import heapqueue

proc test1[T](test: (float, T)) = # Works
    discard

proc test2[T](test: seq[(float, T)]) = # Works
    discard

proc test3[T](test: HeapQueue[tuple[sqd: float, data: T]]) = # Works
    discard

proc test4(test: HeapQueue[(float, float)]) = # Works
    discard

type ExampleObj = object
    a: string
    b: seq[float]

proc test5(test: HeapQueue[(float, ExampleObj)]) = # Works
    discard

proc failingTest[T](test: HeapQueue[(float, T)]) = # (Compile) Error: Mixing types and values in tuples is not allowed.
    discard

proc failingTest2[T](test: HeapQueue[(T, float)]) = # (Compile) Error: Mixing types and values in tuples is not allowed.
    discard

proc test6[T](test: HeapQueue[(T, T)]) = # works
    discard

proc test7[T, U](test: HeapQueue[(T, U)]) = # works
    discard
