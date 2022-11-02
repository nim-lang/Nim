var b = "some string"

doAssert type(b[0..b.len-1]) is string
doAssert typeof(b[0..b.len-1]) is string

let a = $typeof(b[0..b.len-1])
doAssert a == "string"
