#
#
#            Nim's Runtime Library
#        (c) Copyright 2018 Emery Hemingway
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

# Utility for in place C++ construction.

when not defined(genode):
  {.error: "Genode only module".}

type Constructible* {.
  importcpp: "Genode::Constructible",
  header: "<util/reconstructible.h>", final, pure.} [T] = object

proc construct*[T](x: var Constructible[T]) {.importcpp.}
  ## Construct a constructible C++ object.

proc destruct*[T](x: var Constructible[T]) {.importcpp.}
  ## Destruct a constructible C++ object.

proc `=destroy`*[T](x: var Constructible[T]) =
  destruct x
