proc output_x:string {.compileTime.} = "x"

template t =
  const x = output_x()
  let
    bar {.exportC:"bar" & x.} = 100

static:
  doAssert(compiles (t()))
