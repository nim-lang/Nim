
var orig = @[1,2,3]
var notDeepCopy: seq[int]
shallowCopy(notDeepCopy, orig)
orig[0] = 99
assert(notDeepCopy[0] == 99)
