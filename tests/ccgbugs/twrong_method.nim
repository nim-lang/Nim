discard """
  cmd: "nim c -d:release $file"
  output: '''correct method'''
"""
# bug #5439
type
  Control* = ref object of RootObj

  ControlImpl* = ref object of Control

  Container* = ref object of ControlImpl

  ContainerImpl* = ref object of Container

method testProc*(control: Control) {.base.} = echo "wrong method"

method testProc*(container: Container) = echo "correct method"

proc main()

main() # wrong method called

proc main() =
  var container = new ContainerImpl
  container.testProc()

# main() # correct method called
