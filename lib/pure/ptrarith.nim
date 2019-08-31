#
#
#            Nim's Runtime Library
#        (c) Copyright 2019 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module offers operators for performing arithmetic on raw pointer types
## in Nim. Nim is *not* C: using pointer arithmetic in Nim should be avoided (if
## possible, use `array[T]`, `ptr UncheckedArray[T]`, etc.), however, pointer
## arithmetic is sometimes desirable for low-level ops/FFI with C.

func `+`*[T](x: ptr[T]; offset: SomeInteger): ptr[T] =
  cast[ptr[T]](cast[ByteAddress](x) + cast[ByteAddress](offset * sizeof(T)))

func `-`*[T](x: ptr[T]; offset: SomeInteger): ptr[T] =
  cast[ptr[T]](cast[ByteAddress](x) - cast[ByteAddress](offset * sizeof(T)))

func `+=`*[T](x: var ptr[T]; offset: SomeInteger) =
  x = x + offset

func `-=`*[T](x: var ptr[T]; offset: SomeInteger) =
  x = x - offset
