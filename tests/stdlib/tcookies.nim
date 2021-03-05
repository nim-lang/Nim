discard """
  targets: "c js"
"""


import std/[cookies, times, strtabs]

let expire = fromUnix(0) + 1.seconds

let theCookies = [
  setCookie("test", "value", expire),
  setCookie("test", "value", expire.local),
  setCookie("test", "value", expire.utc)
]
let expected = "Set-Cookie: test=value; Expires=Thu, 01 Jan 1970 00:00:01 GMT"
doAssert theCookies == [expected, expected, expected]

let table = parseCookies("uid=1; kp=2")
doAssert table["uid"] == "1"
doAssert table["kp"] == "2"
