discard """
  output: '''a
[FATAL] dangling references exist
'''
  exitCode: 1
  cmd: "nim c --newruntime $file"
"""

# bug #11350

type
  Node = ref object
    data: int

proc use(x: Node) = discard

proc main =
  var x = Node(data: 3) # inferred to be an ``owned ref``
  var dangling = unown x
  assert dangling.data == 3
  #use x
  #dangling = nil
  # reassignment causes the memory of what ``x`` points to to be freed:
  echo "a"
  x = Node(data: 4)
  echo "b"
  # accessing 'dangling' here is invalid as it is nil.
  # at scope exit the memory of what ``x`` points to is freed
  if dangling != nil:
    echo dangling.data

main()
