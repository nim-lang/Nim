discard """
  output: '''48
hel
lo'''
"""

template optZero{x+x}(x: int): int = x*3
template andthen{`*`(x,3)}(x: int): int = x*4
template optSubstr1{x = substr(x, a, b)}(x: string, a, b: int) = setlen(x, b+1)

var y = 12
echo y+y

var s: array[0..2, string]
s[0] = "hello"
s[0] = substr(s[0], 0, 2)

echo s[0]

# Test varargs matching
proc someVarargProc(k: varargs[string]) = doAssert(false) # this should not get called
template someVarargProcSingleArg{someVarargProc([a])}(a: string) = echo a
someVarargProc("lo")
