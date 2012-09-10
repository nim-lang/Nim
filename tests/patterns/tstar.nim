discard """
  output: "my awesome concat"
"""

var
  calls = 0
  
proc `&&`(s: varargs[string]): string =
  result = s[0]
  for i in 1..len(s)-1: result.add s[i]
  inc calls

template optConc{ `&&` * a }(a: string): expr = &&a

let space = " "
echo "my" && (space & "awe" && "some " ) && "concat"

# check that it's been optimized properly:
doAssert calls == 1
