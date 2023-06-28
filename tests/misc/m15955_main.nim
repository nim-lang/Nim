import stdtest/specialpaths
import std/os

const buildLib = buildDir / "libD20220923T19380"

{.passL: buildLib.}
proc add*(a, b: int):int {.cdecl, importc.}
proc sub*(a, b: int):int {.cdecl, importc.}

echo add(10, 5)
echo sub(10, 5)
