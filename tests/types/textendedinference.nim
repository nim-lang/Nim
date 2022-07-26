var s: seq[string] = (discard; @[])

var x: set[char] = (s.add "a"; {})
doAssert x is set[char]
doAssert x == {}
doAssert s == @["a"]

x = {'a', 'b'}
doAssert x == {'a', 'b'}

x = (s.add "b"; {})
doAssert x == {}
doAssert s == @["a", "b"]
