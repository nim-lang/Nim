# issue #20073

type Foo = object
proc foo(f: Foo) = discard

template works*() =
  var f: Foo
  foo(f)

template boom*() =
  var f: Foo
  f.foo() # Error: attempting to call undeclared routine: 'foo'
  f.foo # Error: undeclared field: 'foo' for type a.Foo

# issue #7085

proc bar(a: string): string =
  return a & "bar"

template baz*(a: string): string =
  var b = a.bar()
  b
