discard """
action: compile
errormsg: "method1(c) has an illegal effect: IO"
line: 18
"""

type
  IO = object ## input/output effect
  CustomObject* = object of RootObj
    text: string

method method1(obj: var CustomObject): string {.tags: [IO].} = obj.text & "."
method method2(obj: var CustomObject): string = obj.text & ":"

proc noIO() {.forbids: [IO].} =
  var c = CustomObject(text: "a")
  echo c.method2()
  echo c.method1()
