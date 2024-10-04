block:
  # don't consider inserted default values in overload disambiguation
  # https://github.com/status-im/nimbus-eth1/pull/2684#issuecomment-2392895327
  type Foo = ref object
  template foo(a: static[string], b: varargs[untyped]) = discard
  template foo(a: string, b: Foo = nil) = discard
  foo("abc")
