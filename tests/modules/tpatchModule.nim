discard """
  nimoutFull: false
  joinable: false
  varSub: true
  nimout: '''
tpatchModule.nims(24, 12) Warning: cannot open: missingTarget_uasdygf8a7fg8uq23vfquoevfqo8ef [CannotOpen]
tpatchModule.nims(27, 12) Warning: cannot open: missingPatch_uasdygf8a7fg8uq23vfquoevfqo8ef [CannotOpen]
tpatchModule.nims(30, 12) Warning: cannot open: missingTarget_uasdygf8a7fg8uq23vfquoevfqo8ef [CannotOpen]
tpatchModule.nims(33, 12) Warning: cannot open:  [CannotOpen]
tpatchModule.nims(36, 12) Warning: cannot open:  [CannotOpen]
tpatchModule.nims(39, 12) Warning: cannot open:  [CannotOpen]
a${/}module_name_clashes.nim(3, 12) Hint: tests/modules/b/module_name_clashes patched with tests/modules/mpatchModule [Patch]
'''
"""

# Test `nimscript.patchModule`
#
# The other components of this test are:
# * `tpatchModule.nims` is the config script to configure the patch.
# * `mpatchModule.nim` is the module that patches the target modules.

# Test patching foreign and `stdlib` modules:
import std/httpclient #[tt.Hint
          ^ std/httpclient patched with tests/modules/mpatchModule [Patch] ]#
var client = newHttpClient()
doAssert client.getContent("https://example.com") == "patched!"

# Test patching one of multiple modules with the same name in the same
# package doesn't patch all of them:
import a/module_name_clashes
doAssert typeof(A.b) is int

# Test patching absolute paths and patch paths that are relative to the configuring
# script given in `tpatchModule.nims`. This also tests that an alias symbol is created
# for the patching module (the `db_postgres.open` call would use the real module otherwise):
import std/db_postgres #[tt.Hint
          ^ std/db_postgres patched with tests/modules/mpatchModule [Patch] ]#
let db = db_postgres.open("/run/postgresql", "user", "password", "database")
doAssert db.getAllRows(sql"SELECT version();")[0][0] == "patched!"

# Test patching an absolute import:
import "$lib/pure/oids" #[tt.Hint
       ^ std/oids patched with tests/modules/mpatchModule [Patch] ]#
doAssert genOid() == genOid() # `genOid` is patched to always return the same value

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
