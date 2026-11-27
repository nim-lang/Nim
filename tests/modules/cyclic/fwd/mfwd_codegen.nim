import ../tfwd_codegen {.cyclic.}

type Base* = ref object of RootObj
method name*(x: Base): string {.base.} = "base"
proc show*(x: Base): string = x.name

echo fb()
var xs: seq[Base] = @[Base(), mk()]
for x in xs: echo show(x)
