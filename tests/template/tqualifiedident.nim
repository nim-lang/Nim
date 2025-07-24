block: # issue #19865
  template f() = discard default(system.int)
  f()

# issue #21221, same as above
type M = object
template r() = discard default(tqualifiedident.M)
r()
