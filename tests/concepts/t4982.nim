discard """
errormsg: "undeclared identifier: 'x'"
line: 10
"""

import typetraits # without this import the program compiles (and echos false)

type
  SomeTestConcept = concept t
    x.name is string # typo: t.name was intended (which would result in echo true)

type
  TestClass = ref object of RootObj
    name: string

var test = TestClass(name: "mytest")
echo $(test is SomeTestConcept)

