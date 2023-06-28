import std/[times, strformat]
import std/assertions

doAssert fmt"{getTime()}" == $getTime()
doAssert fmt"{now()}" == $now()
