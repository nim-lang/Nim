discard """
  nimoutFull: true
  joinable: false
  nimout: '''
tpatchModule.nims(22, 12) Warning: cannot open: missingTarget_uasdygf8a7fg8uq23vfquoevfqo8ef [CannotOpen]
tpatchModule.nims(25, 12) Warning: cannot open: missingPatch_uasdygf8a7fg8uq23vfquoevfqo8ef [CannotOpen]
tpatchModule.nim(21, 11) Hint: ../../lib/pure/httpclient.nim patched with mpatchModule.nim [Patch]
a/module_name_clashes.nim(3, 12) Hint: b/module_name_clashes.nim patched with mpatchModule.nim [Patch]
tpatchModule.nim(33, 11) Hint: ../../lib/impure/db_postgres.nim patched with mpatchModule.nim [Patch]
tpatchModule.nim(38, 8) Hint: ../../lib/pure/oids.nim patched with mpatchModule.nim [Patch]
'''
"""

# Test `nimscript.patchModule`
#
# The other components of this test are:
# * `tpatchModule.nims` is the config script to configure the patch.
# * `mpatchModule.nim` is the module that patches the target modules.

# Test patching foreign and `stdlib` modules:
import std/httpclient
var client = newHttpClient()
doAssert client.getContent("https://example.com") == "patched!"

# Test patching one of multiple modules with the same name in the same
# package doesn't patch all of them:
import a/module_name_clashes
doAssert typeof(A.b) is int

# Test patching absolute paths and patch paths that are relative to the configuring
# script given in `tpatchModule.nims`. This also tests that an alias symbol is created
# for the patching module (the `db_postgres.open` call would use the real module otherwise):
import std/db_postgres
let db = db_postgres.open("/run/postgresql", "user", "password", "database")
doAssert db.getAllRows(sql"SELECT version();")[0][0] == "patched!"

# Test patching an absolute import:
import "$lib/pure/oids"
doAssert genOid() == genOid() # `genOid` is patched to always return the same value
