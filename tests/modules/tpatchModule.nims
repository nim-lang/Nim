# See `tpatchModule`

# Patch a foreign and `stdlib` module:
patchModule("std/httpclient", "mpatchModule")

# Patch one of multiple modules with the same name and in the same package:
patchModule("b/module_name_clashes", "mpatchModule")

# Patch a module with an absolute target path given and a relative patch:
import std/[os, compilesettings]
const libPath = querySetting(SingleValueSetting.libPath)
patchModule(libPath / "impure" / "db_postgres.nim", "mpatchModule")
