import mdotcall

# issue #20073
works()
boom()

# issue #7085
doAssert baz("hello") == "hellobar"
doAssert baz"hello" == "hellobar"
doAssert "hello".baz == "hellobar"
