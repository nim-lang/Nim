discard """
  cmd: '''nim doc -d:nimTestsT18077b:4 --doccmd:"-d:nimTestsT18077 -d:nimTestsT18077b:3 --hints:off" $file'''
  action: compile
"""

# bug #18077

const nimTestsT18077b {.intdefine.} = 1

static:
  when defined(nimdoc):
    doAssert nimTestsT18077b == 4
    doAssert not defined(nimTestsT18077)
  else:
    doAssert defined(nimTestsT18077)
    doAssert nimTestsT18077b == 3

runnableExamples:
  const nimTestsT18077b {.intdefine.} = 2
  doAssert nimTestsT18077b == 3
  doAssert defined(nimTestsT18077)
