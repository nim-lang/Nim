const a = "foo"
const b: cstring = a

# const b: cstring = "foo" # would work
var c = b
doAssert c == "foo"
