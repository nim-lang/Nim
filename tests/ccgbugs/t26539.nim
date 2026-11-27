discard """
  matrix: "--mm:refc --passC:-fsanitize=undefined --passC:-fsanitize-undefined-trap-on-error --passL:-fsanitize=undefined --passL:-fsanitize-undefined-trap-on-error"
  disabled: "windows"
  output: "ok"
"""

# bug #26539: the refc marker must not read the discriminator of case objects
# that contain no GC'ed memory, it might be uninitialized
import std/deques

type
  Obj = object
    case b: bool
    of true, false: discard

  WithRef = object
    case b: bool
    of true: r: ref int
    of false: discard

for _ in 0 ..< 1000:
  discard @[0x55'u8, 0x55, 0x55, 0x55]

var q: Deque[Obj]
q.addLast(Obj())
var s = @[WithRef(b: true, r: new int)]
s[0].r[] = 42
GC_fullCollect()
doAssert s[0].r[] == 42
echo "ok"
