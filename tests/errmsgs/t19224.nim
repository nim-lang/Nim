discard """
cmd: "nim check --hints:off $file"
errormsg: ""
nimout: '''
t19224.nim(9, 10) Error: cannot infer element type of items([])
t19224.nim(11, 10) Error: cannot infer element type of items(@[])
"""

for _ in []: discard

for _ in @[]: discard