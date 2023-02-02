#
#
#            Nim's Runtime Library
#        (c) Copyright 2022 Emery Hemingway
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

type Constructible*[T] {.
  importcpp: "Genode::Constructible",
  header: "<util/reconstructible.h>", byref, pure.} = object

proc construct*[T](x: Constructible[T]) {.importcpp.}
  ## Construct a constructible C++ object.

proc destruct*[T](x: Constructible[T]) {.importcpp.}
  ## Destruct a constructible C++ object.

proc constructed*[T](x: Constructible[T]): bool {.importcpp.}
  ## Test if an object is constructed.
