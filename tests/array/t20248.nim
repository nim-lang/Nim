discard """
cmd: "nim check --hints:off $file"
errormsg: "ordinal type expected"
nimout: '''
t20248.nim(10, 36) Error: ordinal type expected
t20248.nim(14, 20) Error: ordinal type expected
'''
"""

type Vec[N: static[int]] = array[0 ..< N, float]

var v: Vec[32]

var stuff: array[0 ..< 16, int]
