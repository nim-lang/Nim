discard """
  action: run
"""

import math, random, strutils
const consolePrefix = "jsCallbacks"

asm """
    var callback = []
    function regCallback (fn) { callback.push (fn); }
    function runCallbacks () {
        var result = "\n"
        var n = 0
        for (var fn in callback) {
            n += 1
            result += "("+String (n)+")"
            result += callback [fn] ()
            result += "\n"
        }
        return result
    }
    function print (text) { console.log (text); }
"""

proc consoleprint (str:cstring): void {.importc: "print", noDecl.}
proc print* (a: varargs[string, `$`]) = consoleprint "$1: $2" % [consolePrefix, join(a, " ")]

type CallbackProc {.importc.} = proc () : cstring

proc regCallback (fn:CallbackProc) {.importc.}
proc runCallbacks ():cstring {.importc.}

proc `*` (s:string, n:Natural) : string = s.repeat(n)

proc outer (i:Natural) : (string, int) =
    let c = $char(random(93) + 33)
    let n = random(40)
    let s = c * n
    proc inner(): cstring = ("[$1]" % $n) & s & " <--"
    regCallback(inner)
    return (s, n)

var expected = "\n"
for i in 1 .. 10:
    let (s, n) = outer(i)
    expected &= ("($1)[$2]" % [$i, $n]) & s & " <--"
    expected &= "\n"

let results = runCallbacks()

doAssert(expected == $results)
