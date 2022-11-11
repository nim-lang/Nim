discard """
cmd: "nim check $options --hints:off $file"
action: "reject"
nimout: '''
t3505.nim(22, 22) Error: cannot asign to global variable
t3505.nim(30, 27) Error: cannot asign to global variable





'''
"""






proc foo =
  let a = 0
  var b {.global.} = a
foo()

# issue #5132
proc initX(it: float): int = 8

proc main() =
  var f: float
  var x {.global.} = initX(f)
  
main()
