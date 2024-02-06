import std/[times, strformat]
import std/assertions

let aTime = getTime()
doAssert fmt"{aTime}" == $aTime
let aNow = now()
doAssert fmt"{aNow}" == $aNow
