var b = "some string"

let a = $typeof(b[0..b.len-1])
doAssert a == "string"
