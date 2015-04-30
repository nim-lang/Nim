discard """
  output: '''Hello
Hello'''
"""

# bug #2581

const someVars = [ "Hello" ]
var someVars2 = [ "Hello" ]

proc getSomeVar: string =
    for i in someVars:
        if i == "Hello":
            result = i
            break

proc getSomeVar2: string =
    for i in someVars2:
        if i == "Hello":
            result = i
            break

echo getSomeVar()
echo getSomeVar2()
