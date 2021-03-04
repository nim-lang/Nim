
import
  generic_library, helper_module

proc mixedIn: int = 100

proc makeUseOfLibrary*[T](x: T) =
  mixin mixedIn, indirectlyMixedIn
  libraryFunc(x)

when isMainModule:
  makeUseOfLibrary "test"
