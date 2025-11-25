# issue #25312

import heapqueue

proc failingTest[T](test: HeapQueue[(float, T)]) = # (Compile) Error: Mixing types and values in tuples is not allowed.
    discard
