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

main()
