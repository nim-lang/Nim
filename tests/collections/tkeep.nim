import sequtils

var candidates = @["foo", "bar", "baz", "foobar"]
keepItIf(candidates, it.len == 3 and it[0] == 'b')
doAssert candidates == @["bar", "baz"]
