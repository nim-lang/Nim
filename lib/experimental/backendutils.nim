##[
## experimental API!

Utilities to interface with generated backend (for now C/C++, later js) code,
abstracting away platform differences and taking care of needy greedy details.
]##

import macros

static: doAssert defined(c) or defined(cpp) or defined(nimdoc)

macro c_astToStr*(T: typedesc): string =
  ## returns the backend analog of `astToStr`
  runnableExamples:
    doAssert cint.c_astToStr == "int"
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
  ## returns the generated backend file
  var s: cstring
  {.emit("here"): [s, "= __FILE__;"].}
  $s

template c_currentFunction*(): string =
  runnableExamples:
    proc fun(){.exportc.} = doAssert c_currentFunction == "fun"
    fun()
  var s: cstring
  # cast needed for C++
  {.emit("here"): [s, "= (char*) __FUNCTION__;"].}
  $s

template c_sizeof*(T: typedesc): int =
  runnableExamples:
    doAssert c_sizeof(cint) == cint.sizeof
  var s: int
  {.emit("here"): [s," = sizeof(", T, ");"].}
  s

template cstaticIf*(cond: string, body) =
  runnableExamples:
    cstaticIf "defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112L":
      {.emit("HERE"): """_Static_assert(sizeof(_Bool) == 1, "bad"); """.}
  {.emit("here"): ["""#if """, cond, "\n"].}
  body
  {.emit("here"): "#endif\n".}
