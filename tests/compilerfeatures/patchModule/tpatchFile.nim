# Test `nimscript.patchFile`
#
# The other components of this test are:
# * `patchFile.nims` is the config script to configure the patch.

import std/httpclient
doAssert id == "mpatchFile"

# # Test how `link` pragma directives are handled:
# {.link: "mpatchModule_pragma_linked_a.lib".}
# proc pragmaLinked: char {.importc.}
# doAssert pragmaLinked() == 'b'

# # Test how `compile` pragma directives are handled:
# {.compile: "tpatchModule_pragma_compiled_a.c".}
# proc pragmaCompiled: cchar {.importc, header: "tpatchModule_a.h".}
# doAssert pragmaCompiled() == 'b'

# Test non-module files don't get patched:
import std/os
const text = staticRead("tests"/"dummy.txt")
doAssert text == "Just a simple text for test"
