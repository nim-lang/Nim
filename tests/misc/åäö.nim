discard """
    action: run
"""
import std/assertions
# Tests that module names can contain multi byte characters

let a = 1
doAssert åäö.a == 1

proc inlined() {.inline.} = discard
inlined()