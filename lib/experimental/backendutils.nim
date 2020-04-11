##[
## experimental API!

Utilities to interface with generated backend (for now C/C++, later js) code
]##

import macros

static: doAssert defined(c) or defined(cpp)

macro c_astToStr*(T: typedesc): string =
  ## returns the backend
  result = newStmtList()
  var done {.global.}: bool
  if not done:
    done = true
    result.add quote do:
      {.emit("typeSection"): "#define c_astToStrImpl(T) #T".}

  result.add quote do:
    var s: cstring
    {.emit("here"): [s, " = c_astToStrImpl(", `T`, ");"].}
    $s

template c_currentSourcePath*(): string =
  var s: cstring
  {.emit("here"): [s, "= __FILE__;"].}
  $s

template c_currentFunction*(): string =
  var s: cstring
  {.emit("here"): [s, "= __FUNCTION__;"].}
  $s

template c_sizeof*(T: typedesc): int =
  var s: int
  {.emit("here"): [s," = sizeof(", T, ");"].}
  s
