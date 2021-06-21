import macros

# Generate a proc with more then 255 registers. Should not generate an error at
# compile time

static:
  macro mkFoo() =
    let ss = newStmtList()
    for i in 1..256:
      ss.add parseStmt "var x" & $i & " = " & $i
      ss.add parseStmt "inc x" & $i
    quote do:
      proc foo() =
        `ss`
  mkFoo()
  foo()
