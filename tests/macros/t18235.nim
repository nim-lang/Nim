import m18235

# this must error out because it was never actually exported
doAssert(not declared(foo))
doAssert not compiles(foo())

doAssert(not declared(foooof))
doAssert not compiles(foooof())

# this should have been exported just fine

bar()
barrab()
