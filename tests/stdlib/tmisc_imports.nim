#[
catch regressions on modules for which we don't have tests yet; at least should
catch some compilation errors.
]#

{.push warning[UnusedImport]: off.}
import std/db_odbc
import std/posix_utils
{.pop.}
