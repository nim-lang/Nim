# bug #15949

discard """
errormsg: "parameter 'a' requires a type"
nimout: '''
t15949.nim(20, 14) Error: parameter 'a' requires a type'''
"""


# line 10
proc procGood(a, b = 1): (int, int) = (a, b)

doAssert procGood() == (1, 1)
doAssert procGood(b = 3) == (1, 3)
doAssert procGood(a = 2) == (2, 1)
doAssert procGood(a = 5, b = 6) == (5, 6)

# The type (and default value propagation breaks in the below example
# as semicolon is used instead of comma.
proc procBad(a; b = 1): (int, int) = (a, b)
