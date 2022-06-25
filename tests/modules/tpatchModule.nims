# See `tpatchModule`

# Patch a foreign and `stdlib` module:
patchModule("std/httpclient", "mpatchModule")

# Patch one of multiple modules with the same name and in the same package:
patchModule("b/module_name_clashes", "mpatchModule")

# Patch a module with an absolute target path given and a relative patch:
# (This is also tests that path substitution is performed)
patchModule("$lib/impure/db_postgres.nim", "$projectpath/mpatchModule.nim")

# Patch a target module that is imported using an absolute path:
patchModule("oids", "mpatchModule")
