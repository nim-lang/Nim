# issue #15650

{.warningAsError[Deprecated]: on.}

proc bar() {.deprecated.} = discard

template foo() =
  when false:
    bar()
  else:
    discard

foo()
