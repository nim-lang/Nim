#[
catch regressions on modules for which we don't have tests yet; at least should
catch some compilation errors.

Note: `koch docs` is also catching some regressions but compared to it, this
invokes a single compilation step (will fail fast if any error),
and can be used locally to test different platforms via:
`--compileOnly --os:windows` (say, from osx).

Note: we could use a glob as in `kochdocs`.
]#

{.push warning[UnusedImport]: off.}
import std/db_odbc
import std/posix_utils
{.pop.}
