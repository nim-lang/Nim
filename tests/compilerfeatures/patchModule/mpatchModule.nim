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

# Patch a module given as an absolute path in `tpatchModule.nims`:
import std/db_postgres except open, getAllRows
export db_postgres except open, getAllRows
proc open*(connection, user, password, database: string): DbConn {.tags: [DbEffect].} =
  discard
proc getAllRows*(db: DbConn, query: SqlQuery, args: varargs[string, `$`]): seq[Row] =
  @[@["patched!"]]

# Patch an absolute import:
import "$lib/pure/oids" except genOid
export oids except genOid
proc genOid*(): Oid = Oid()
