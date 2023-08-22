discard """
  output: '''true
true
true
true
true'''
  cmd: "nim c --gc:arc $file"
"""
# bug #15361

type
  ErrorNodeKind = enum Branch, Leaf
  Error = ref object
    case kind: ErrorNodeKind
      of Branch:
        left: Error
        right: Error
      of Leaf:
        leafError: string
    input: string

proc ret(input: string, lefterr, righterr: Error): Error =
  result = Error(kind: Branch, left: lefterr, right: righterr, input: input)

proc parser() =
  var rerrors: Error
  let lerrors = Error(
    kind: Leaf,
    leafError: "first error",
    input: "123 ;"
  )
  # If you remove "block" - everything works
  block:
    let rresult = Error(
      kind: Leaf,
      leafError: "second error",
      input: ";"
    )
    # this assignment is needed too
    rerrors = rresult

  # Returns Error(kind: Branch, left: lerrors, right: rerrors, input: "some val")
  # needs to be a proc call for some reason, can't inline the result
  var data = ret(input = "some val", lefterr = lerrors, righterr = rerrors)

  echo data.left.leafError == "first error"
  echo data.left.input == "123 ;"
  # stacktrace shows this line
  echo data.right.leafError == "second error"
  echo data.right.input == ";"
  echo data.input == "some val"

parser()
