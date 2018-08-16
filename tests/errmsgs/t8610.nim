discard """
  errormsg: "invalid type for const: type int"
  line: 6
"""

const Foo=int
echo Foo is int # true
echo int is Foo # Error: type expected
