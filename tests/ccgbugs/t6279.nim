discard """
cmd: "nim c -r -d:fulldebug -d:smokeCycles --gc:refc $file"
output: '''@["a"]'''
"""

# bug #6279
var foo = newSeq[tuple[a: seq[string], b: seq[string]]]()
foo.add((@["a"], @["b"]))
echo foo[0].a # Crashes on this line
