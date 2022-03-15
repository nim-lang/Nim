# new test for sets:
import std/assertions
const elem = ' '

var s: set[char] = {elem}
assert(elem in s and 'a' not_in s and 'c' not_in s )
