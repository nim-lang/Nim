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
##
## .. warning:: This module is experimental and its interface may change.
##

type
  Isolated*[T] = object ## Isolated data can only be moved, not copied.
    value: T

proc `=copy`*[T](dest: var Isolated[T]; src: Isolated[T]) {.error.}

proc `=sink`*[T](dest: var Isolated[T]; src: Isolated[T]) {.inline.} =
  # delegate to value's sink operation
  `=sink`(dest.value, src.value)

proc `=destroy`*[T](dest: var Isolated[T]) {.inline.} =
  # delegate to value's destroy operation
  `=destroy`(dest.value)

func isolate*[T](value: sink T): Isolated[T] {.magic: "Isolate".} =
  ## Creates an isolated subgraph from the expression `value`.
  ## Isolation is checked at compile time.
  ##
  ## Please read https://github.com/nim-lang/RFCs/issues/244
  ## for more details.
  Isolated[T](value: value)

func unsafeIsolate*[T](value: sink T): Isolated[T] =
  ## Creates an isolated subgraph from the expression `value`.
  ## 
  ## .. warning:: The proc doesn't check whether `value` is isolated.
  ## 
  Isolated[T](value: value)

func extract*[T](src: var Isolated[T]): T =
  ## Returns the internal value of `src`.
  ## The value is moved from `src`.
  result = move(src.value)
