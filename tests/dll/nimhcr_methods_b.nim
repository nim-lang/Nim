import nimhcr_methods_a

type Derived* = ref object of Base

method send*(t: Derived, x: int): int = 10 * x

# calls a method from a module that neither declares it nor is the main module
proc sendThrough*(t: Base, x: int): int = t.send(x)

proc describeThrough*(t: Base): string = t.describe()
