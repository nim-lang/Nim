type Foo = object
proc foo(f: Foo) = discard

template works*() =
  var f: Foo
  foo(f)

template boom*() =
  var f: Foo
  f.foo() # Error: attempting to call undeclared routine: 'foo'
  f.foo # Error: undeclared field: 'foo' for type a.Foo
