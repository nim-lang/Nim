template fooBar1() {.pragma.}
proc fooBar2() = discard
macro fooBar3(x: untyped) = discard

# Procs shouldn't be suggested.
# Not perfect, but cuts down on invalid suggestions
proc test1() {.fooBar#[!]#.} = discard

# We also want to suggest built in pragmas which
# wouldn't normally come up in suggestions
proc test2() {.stackTrac#[!]#.} = discard

discard """
$nimsuggest --tester $file
>sug $1
sug;;skMacro;;fooBar1;;LogLevel;;$file;;1;;9;;"";;100;;Prefix
"""

