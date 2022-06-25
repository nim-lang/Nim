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
