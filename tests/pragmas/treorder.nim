discard """
output:3
"""
{.reorder: on .}
{.experimental.} # for "using" feature


echo foo(sum)

    
const
    CA = 0
    CB = CC
var
    a = b
    c = 0
    aa : TA
    bb : TB
    vfoo = foo(b)


var
    b = c
    aaa = aa
    sum = vfoo + a + CD + CA

const
    CC = 1
    CD = CB

type
    TA = object
        x: TB
    TC = object

type
    TB = object
        x: TC

proc foo(x): int =
    if aaa.x.x == bb.x:
        result = bar(x)
    else:
        result = 0

proc bar(x): int =
    result = x+1

using
    x : int