discard """
cmd: "nim check --hints:off $file"
errormsg: ""
nimout: '''
t19224.nim(10, 10) Error: cannot infer element type of items([])
t19224.nim(12, 10) Error: cannot infer element type of items(@[])
'''
"""

for _ in []: discard

for _ in @[]: discard
