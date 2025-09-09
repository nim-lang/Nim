discard """
  output: '''
Deallocating OwnedString
HelloWorld
'''
  matrix: "--cursorinference:on; --cursorinference:off"
  target: "c"
"""

# bug #23837
{.
  emit: [
    """
#include <stdlib.h>
#include <string.h>
char *allocCString() {
    char *result = (char *) malloc(10 + 1);
    strcpy(result, "HelloWorld");
    return result;
}

"""
  ]
.}

proc rawWrapper(): cstring {.importc: "allocCString", cdecl.}
proc free(p: pointer) {.importc: "free", cdecl.}

# -------------------------

type OwnedString = distinct cstring

proc `=destroy`(s: OwnedString) =
  free(cstring s)
  echo "Deallocating OwnedString"

func `$`(s: OwnedString): string {.borrow.}

proc leakyWrapper(): string =
  let ostring = rawWrapper().OwnedString
  $ostring

# -------------------------

proc main() =
  # destructor not called - definitely lost: 11 bytes in 1 blocks
  # doesn't leak with --cursorInference:off
  let s = leakyWrapper()
  echo s

main()

block:
  proc foo =
    var x = "1234"
    var y = x
    when nimvm:
      discard
    else:
      var s = x
      doAssert s == "1234"
    doAssert y == "1234"

  static: foo()
  foo()
