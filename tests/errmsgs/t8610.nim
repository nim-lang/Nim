discard """
  errormsg: "cannot have typedesc as const value, use 'type Foo = int' instead"
  line: 6
"""

const Foo=int
echo Foo is int # true
echo int is Foo # Error: type expected
