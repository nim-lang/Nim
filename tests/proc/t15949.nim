# bug #15949 and RFC #480

proc procWarn(a, b = 1): (int, int) = (a, b) #[tt.Warning
              ^ a, b all have default value '1', this may be unintentional, either use ';' (semicolon) or explicitly write each default value [ImplicitDefaultValue]]#

proc procGood(a = 1, b = 1): (int, int) = (a, b)

doAssert procGood() == (1, 1)
doAssert procGood(b = 3) == (1, 3)
doAssert procGood(a = 2) == (2, 1)
doAssert procGood(a = 5, b = 6) == (5, 6)

# The type (and default value propagation breaks in the below example
# as semicolon is used instead of comma.
proc procBad(a; b = 1): (int, int) = (a, b) #[tt.Error
             ^ parameter 'a' requires a type]#
