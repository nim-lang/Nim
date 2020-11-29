#
#
#            Nim's Runtime Library
#        (c) Copyright 2020 Nim contributors
#
#    See the file "copying.txt", included in this
#    distribution, for details about the copyright.
#

## This module implements the `Isolated[T]` type for
## safe construction of isolated subgraphs that can be
## passed efficiently to different channels and threads.

type
  Isolated*[T] = object ## Isolated data can only be moved, not copied.
    value: T

proc `=`*[T](dest: var Isolated[T]; src: Isolated[T]) {.error.}

proc `=sink`*[T](dest: var Isolated[T]; src: Isolated[T]) {.inline.} =
  # delegate to value's sink operation
  `=sink`(dest.value, src.value)

proc `=destroy`*[T](dest: var Isolated[T]) {.inline.} =
  # delegate to value's destroy operation
  `=destroy`(dest.value)

func isolate*[T](value: sink T): Isolated[T] {.magic: "Isolate".}
  ## Create an isolated subgraph from the expression `value`.
  ## Please read https://github.com/nim-lang/RFCs/issues/244
  ## for more details.
