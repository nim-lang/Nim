discard """
  matrix: "--gc:refc; --gc:arc"
"""

# bug #14160

type
  TPassContext = object of RootObj
  PPassContext = ref TPassContext

  PCtx = ref object of TPassContext
    a: int

  ModuleGraph = object
    vm: RootRef

proc main() =
  var g = ModuleGraph(vm: new(Pctx))
  PCtx(g.vm) = nil #This generates invalid C code
  doAssert g.vm == nil

main()

# bug #14325

proc main2() =
  var g = ModuleGraph(vm: new(Pctx))
  PPassContext(PCtx(g.vm)) = nil #This compiles, but crashes at runtime with gc:arc
  doAssert g.vm == nil

main2()

