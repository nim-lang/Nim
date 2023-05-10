discard """
  nimout: '''
tpatchModule.nims(45, 12) Warning: cannot open: missingTarget_uasdygf8a7fg8uq23vfquoevfqo8ef [CannotOpen]
tpatchModule.nims(48, 12) Warning: cannot open: missingPatch_uasdygf8a7fg8uq23vfquoevfqo8ef [CannotOpen]
tpatchModule.nims(51, 12) Warning: cannot open: missingTarget_uasdygf8a7fg8uq23vfquoevfqo8ef [CannotOpen]
tpatchModule.nims(54, 12) Warning: cannot open:  [CannotOpen]
tpatchModule.nims(57, 12) Warning: cannot open:  [CannotOpen]
tpatchModule.nims(60, 12) Warning: cannot open:  [CannotOpen]
a${/}same_module_name.nim(3, 12) Hint: tests/compilerfeatures/patchModule/b/same_module_name patched with tests/compilerfeatures/patchModule/mpatchModule [Patch]
'''
"""

# Test `nimscript.patchModule`
#
# The other components of this test are:
# * `tpatchModule.nims` is the config script to configure the patch.
# * `mpatchModule.nim` is the module that patches the target modules.

# Test patching foreign and `stdlib` modules:
import std/httpclient #[tt.Hint
          ^ std/httpclient patched with tests/compilerfeatures/patchModule/mpatchModule [Patch] ]#
var client = httpclient.newHttpClient() #[
  Using this ^^^^^^^^^^ package symbol tests that an alias symbol is created
  for the patching module.]#
doAssert client.getContent("https://localhost") == "patched!"

# Tests:
#   - patching one of multiple modules with the same name and in the same package
#     ```
#     ├── a
#     │   └── same_module_name.nim
#     ├── b
#     │   └── same_module_name.nim
#     ```
#   - patching a module with an absolute target path given
import a/same_module_name
doAssert typeof(A.b) is int

# Test patching an absolute import:
import "$lib/pure/oids" #[tt.Hint
       ^ std/oids patched with tests/compilerfeatures/patchModule/mpatchModule [Patch] ]#
doAssert genOid() == genOid() # `genOid` is patched to always return the same value

# Test using a patch in a foreign package:
import mpatchModule_f #[tt.Hint
       ^ tests/compilerfeatures/patchModule/mpatchModule_f patched with mpatchModulePkg [Patch] ]#
doAssert mpatchModule_f.id == "mpatchModulePkg"

# Test using a patch that is also patched:
import mpatchModule_a #[tt.Hint
       ^ tests/compilerfeatures/patchModule/mpatchModule_a patched with tests/compilerfeatures/patchModule/mpatchModule_b [Patch] ]#
# `mpatchModule_b` is patched by `mpatchModule_c`, but that doesn't affect `mpatchModule_b`
# patching `mpatchModule_a` unless `mpatchModule_c` is assigned to patch `mpatchModule_a`
# after `mpatchModule_b` is assigned to patch `mpatchModule_a`.
doAssert mpatchModule_a.id == "mpatchModule_b"

# # Test how `link` pragma directives are handled:
# {.link: "mpatchModule_pragma_linked_a.lib".}
# proc pragmaLinked: char {.importc.}
# doAssert pragmaLinked() == 'b'

# # Test how `compile` pragma directives are handled:
# {.compile: "tpatchModule_pragma_compiled_a.c".}
# proc pragmaCompiled: cchar {.importc, header: "tpatchModule_a.h".}
# doAssert pragmaCompiled() == 'b'

# # Test non-module files don't get patched:
# import std/os
# const text = staticRead(".." / "dummy.txt")
# doAssert text == "Just a simple text for test"
