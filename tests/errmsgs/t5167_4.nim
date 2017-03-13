discard """
errormsg: "type mismatch: got (proc [*missing parameters*](x: int) | proc (x: string){.gcsafe, locks: 0.})"
line: 19
"""

type
  TGeneric[T] = object
    x: int

proc foo[B](x: int) =
  echo "foo1"

proc foo(x: string) =
  echo "foo2"

proc bar(x: proc (x: int)) =
  echo "bar"

bar foo

