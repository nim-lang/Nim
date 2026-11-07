type Base* = ref object of RootObj

method send*(t: Base, x: int): int {.base.} = x

# calls a method from the module that declares it
method sendTwo*(t: Base, x, y: int): int {.base.} = t.send(x) + y

# only called from another module, never from the main module
method describe*(t: Base): string {.base.} = "base"
