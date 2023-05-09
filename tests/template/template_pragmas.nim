proc output_x:string {.compileTime.} = "x"

template t =
  const x = output_x()
  let
    bar {.exportc:"bar" & x.} = 100

static:
  doAssert(compiles (t()))
