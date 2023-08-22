discard """
  errormsg: "invalid type: 'lent Test' in this context: 'proc (self: lent Test)' for proc"
"""

# bug #17621
{.experimental: "views".}

type Test = ref object
  foo: int

proc modify(self: lent Test) =
  self.foo += 1

let test = Test(foo: 12)
modify(test)
