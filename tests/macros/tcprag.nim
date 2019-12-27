discard """
  output: '''true
true
true
'''
"""

# issue #7615
import macros

template table(name: string) {.pragma.}

type
   User {.table("tuser").} = object
      id: int
      name: string
      age: int

echo User.hasCustomPragma(table)


## crash: Error: internal error: (filename: "sempass2.nim", line: 560, column: 19)
macro m1(T: typedesc): untyped =
  getAST hasCustomPragma(T, table)
echo m1(User) # Oops crash


## This works
macro m2(T: typedesc): untyped =
  result = quote do:
    `T`.hasCustomPragma(table)
echo m2(User)
