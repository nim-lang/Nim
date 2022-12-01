doAssert true #[tt.Warning
^ 'doAssert' is about to move out of system; import it from `std/assertions` instead]#
doAssert not (compiles do: assertions.doAssert true) #[tt.Warning
^ 'doAssert' is about to move out of system; import it from `std/assertions` instead]#
import std/assertions
doAssert true
doAssert (compiles do: assertions.doAssert true)
