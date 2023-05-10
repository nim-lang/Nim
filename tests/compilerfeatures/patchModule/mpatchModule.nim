# See `tpatchModule`

# Patch a foreign and `stdlib` module:
import std/uri
import std/httpclient except getContent
export httpclient except getContent
proc getContent*(client: HttpClient, url: Uri or string): string =
  "patched!"

# Patch one of multiple modules with the same name and in the same package:
# In this case, the target module is completely replaced by this one.
# This replaces `B` object type with a `B` int type in `b/module_name_clashes`.
type B* = int

# Patch an absolute import:
import "$lib/pure/oids" except genOid
export oids except genOid
proc genOid*(): Oid = Oid()
