
proc libraryFunc*[T](x: T) =
  mixin mixedIn, indirectlyMixedIn
  echo mixedIn()
  echo indirectlyMixedIn()

