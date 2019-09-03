
import ptrarith

var x = [2'i32, 5'i32, 8'i32, 4'i32, 12'i32]
var y = addr x[0]

doAssert((y +% 1)[] == 5'i32)
doAssert((y +% 2)[] == 8'i32)
doAssert((y +% 3)[] == 4'i32)
doAssert((y +% 4)[] == 12'i32)

y +%= 1

doAssert(y[] == 5'i32)
doAssert((y -% 1)[] == 2'i32)

y -%= 1

doAssert(y[] == 2'i32)

