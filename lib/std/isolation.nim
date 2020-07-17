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
  Isolated*[T] = distinct T ## Isolated data can only be moved, not copied.

proc `=`*[T](dest: var Isolated[T]; src: Isolated[T]) {.error.}

proc `=sink`*[T](dest: var Isolated[T]; src: Isolated[T]) {.inline.} =
  # delegate to T's sink operation
  `=sink`(dest.T, src.T)

proc `=destroy`*[T](dest: var Isolated[T]) {.inline.} =
  # delegate to T's destroy operation
  `=destroy`(dest.T)

func recover*[T](x: sink T): Isolated[T] {.magic: "Recover".}
  ## Create an isolated subgraph from the expression `x`.
  ## Please read https://github.com/nim-lang/RFCs/issues/244
  ## for more details.
