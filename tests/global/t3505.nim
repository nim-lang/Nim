discard """
cmd: "nim check $options --hints:off $file"
action: "reject"
nimout: '''
t3505.nim(22, 22) Error: cannot assign local to global variable
t3505.nim(31, 28) Error: cannot assign local to global variable





'''
"""






proc foo =
  let a = 0
  var b {.global.} = a
foo()

# issue #5132
proc initX(it: float): int = 8
proc initX2(it: int): int = it

proc main() =
  var f: float
  var x {.global.} = initX2(initX(f))
  
main()
