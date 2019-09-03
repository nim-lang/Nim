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
## arithmetic is sometimes desirable for low-level ops/FFI with C. **Pointer
## arithmetic is a very sharp tool. This module is unsafe, comes without
## guarantees** and might cause you to spend *endless hours in a debugger, eat
## your cat or cause the heat death of the universe.*

template `+%`*[T](x: ptr[T]; offset: SomeInteger): ptr[T] =
  ## **Unsafe.** Adds `offset * sizeof(T)` bytes from the pointer `x`.
  cast[ptr[T]](cast[ByteAddress](x) + cast[ByteAddress](offset * sizeof(T)))

template `-%`*[T](x: ptr[T]; offset: SomeInteger): ptr[T] =
  ## **Unsafe.** Subtracts `offset * sizeof(T)` bytes from the pointer `x`.
  cast[ptr[T]](cast[ByteAddress](x) - cast[ByteAddress](offset * sizeof(T)))

template `+%=`*[T](x: var ptr[T]; offset: SomeInteger) =
  ## **Unsafe.** Incremeents `offset * sizeof(T)` bytes from the pointer `x`.
  x = x +% offset

template `-%=`*[T](x: var ptr[T]; offset: SomeInteger) =
  ## **Unsafe.** Decrements `offset * sizeof(T)` bytes from the pointer `x`.
  x = x -% offset
