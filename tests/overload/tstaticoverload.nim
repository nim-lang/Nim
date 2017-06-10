discard """
output: '''
dynamic: let
dynamic: var
static: const
static: literal
static: constant folding
static: static string
'''
"""

proc foo(s: string) =
  echo "dynamic: ", s

proc foo(s: static[string]) =
  echo "static: ", s

let l = "let"
let v = "var"
const c = "const"

type staticString = static[string]

foo(l)
foo(v)
foo(c)
foo("literal")
foo("constant" & " " & "folding")
foo(staticString("static string"))

