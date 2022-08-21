discard """
  output: '''x
[10, 11, 12, 13]'''
"""

# bug #14805

type Foo = object
  a: string

proc bar(f: var Foo): lent string =
  result = f.a

var foo = Foo(a: "x")
echo bar(foo)


# bug #14878

# proc byLentImpl[T](a: T): lent T = a
proc byLentVar[T](a: var T): lent T =
  result = a
  # result = a.byLentImpl # this doesn't help

var x = 3 # error: cannot take the address of an rvalue of type 'NI *'

var xs = [10,11,12,13] # SIGSEGV

let x2 = x.byLentVar

let xs2 = xs.byLentVar
echo xs2
