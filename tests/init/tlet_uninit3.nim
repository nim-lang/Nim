discard """
  cmd: "nim check $file"
  action: "reject"
  nimout: '''
tlet_uninit3.nim(16, 5) Error: 'x' cannot be assigned to
tlet_uninit3.nim(20, 11) Error: 'let' symbol requires an initialization
'''
"""

{.experimental: "strictDefs".}

proc foo() =
  block:
    let x: int
    x = 13
    x = 14

  block:
    let x: int
    doAssert x == 0
foo()
