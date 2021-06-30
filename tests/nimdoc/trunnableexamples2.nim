discard """
cmd: "nim doc --doccmd:-d:testFooExternal --hints:off $file"
action: "compile"
joinable: false
"""

# pending bug #18077, merge back inside trunnableexamples.nim
when true: # runnableExamples with rdoccmd
  runnableExamples "-d:testFoo -d:testBar":
    doAssert defined(testFoo) and defined(testBar)
    doAssert defined(testFooExternal)
