discard """
  joinable: false
  action: compile
"""

# Test `nimscript.patchFile`
#
# The other components of this test are:
# * `tpatchFile.nims` is the config script to configure the patch.

# Test patching a `stdlib` module:
import std/httpclient # `mpatchFile` will be used instead of `httpclient`
doAssert id == "mpatchFile" # `id` symbol comes from `mpatchFile`, not `httpclient`

# Test how module symbol (`httpclient`) is handled:
doAssert declared httpclient.id

func cmdlineLinked: char {.importc.}
doAssert cmdlineLinked() == 'a'

func cmdlineCompiled: char {.importc.}
doAssert cmdlineCompiled() == 'a'

# Test how `link` pragma directives are handled:
{.link: "mpatchModule_pragma_linked_a.lib".}
func pragmaLinked: char {.importc.}
doAssert pragmaLinked() == 'b'

# func pragmaCompiled: char {.importc.}
# doAssert pragmaCompiled() == 'a'

# # Test how `compile` pragma directives are handled:
# {.compile: "tpatchModule_pragma_compiled_a.c".}
# proc pragmaCompiled: cchar {.importc, header: "tpatchModule_a.h".}
# doAssert pragmaCompiled() == 'b'

# Test non-module files get patched:
import std/[strutils]
const text = staticRead("mpatchFile.nim")
doAssert "const id* = \"mpatchFile\"" in text
