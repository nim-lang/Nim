discard """
  output: '''
hola2
hola
3
3
'''
"""

# bug #13973: a gensym'ed proc does not implement a proc of the same name
import std/macros
proc hello() =
  echo "hola"
macro function(): untyped =
  let f = genSym(nskProc, ident="hello")
  result = quote do:
    proc `f`(): string
    proc `f`(): string = "hola2"
    echo `f`()
function()
hello()
template t() =
  proc g(): int {.gensym.}
  proc g(): int {.gensym.} = 3
  echo g()
t()
t()
