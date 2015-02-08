import strutils

let expected = @["this", "is", "an", "example"]
assert(split("  this is an  example  ") == expected)
assert(split(";;this;is;an;;example;;;", {';'}) == expected)
assert(split(";;this;is;an;;example;;;", ';') == expected)
assert(split("foo", '') == @["foo"])

let dateExpected = @["2012", "11", "20", "22", "08", "08.398990"]
let date = "2012-11-20T22:08:08.398990"
let separators = {' ', '-', ':', 'T'}
assert(split(date, separators) == dateExpected)
