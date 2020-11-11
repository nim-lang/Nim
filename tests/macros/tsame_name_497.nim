
import macro_bug

type TObj = object

proc f(o: TObj) {.macro_bug.} = discard
