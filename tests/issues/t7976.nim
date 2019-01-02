when defined(case1):
  import strformat, typetraits
  type Person = tuple[name: string, age: int]
  let
    person1: Person = ("Peter", 30)
    person2 = (name: "Peter", age: 30)
  echo fmt"Tuple person1 of type {$person1.type} = {person1}"
  echo fmt"Tuple person2 of type {$person2.type} = {person2}"

when defined(case2):
  import strformat, typetraits
  type Person = tuple[name: string, age: int]
  let
    person1 = (name: "Peter", age: 30)
    person2: Person = ("Peter", 30)
  echo fmt"Tuple person1 of type {$person1.type} = {person1}"
  echo fmt"Tuple person2 of type {$person2.type} = {person2}"

when defined(case3):
  import strformat, typetraits
  type Person = tuple[name: string, age: int]
  let
    person1: Person = ("Peter", 30)
    person2 = (name: "Peter", age: 30)
  echo fmt"Tuple person1 of type {$person1.type} = {person1}"
  echo fmt"Tuple person2 of type {$person2.type} = {person2}"

when defined(case4):
  import strformat, typetraits
  type Person = tuple[name: string, age: int]
  let
    person1: Person = ("Peter", 30)
    person2 = (name: "Peter", age: 30)
  echo fmt"Tuple person1 of type {$person2.type} = {person2}" # simply moved up
  echo fmt"Tuple person2 of type {$person1.type} = {person1}"

when defined(case5):
  import strformat, typetraits
  type Person = tuple[name: string, age: int]
  let
    person1: Person = ("Peter", 30)
    person2 = (name: "Peter", age: 30)
  echo fmt"Tuple person1 of type {name(person1.type)} = {person1}"
  echo fmt"Tuple person2 of type {name(person2.type)} = {person2}"

when not defined(case_any_testcase): # main driver
  import os, strutils, osproc, strformat
  from "../helper_testament" import assertEquals
  proc main() =
    const nim = getCurrentCompilerExe()
    const self = currentSourcePath
    let cases = "case1 case2 case3 case4 case5".split
    var output = ""
    for opt in cases:
      let cmd = fmt"{nim} c -r --verbosity:0 --colors:off --hints:off -d:case_any_testcase -d:{opt} {self}"
      output.add "test case: " & opt & "\n"
      let ret = execCmdEx(cmd, {poStdErrToStdOut, poEvalCommand})
      doAssert ret.exitCode == 0
      output.add ret.output
    let expected = """
test case: case1
Tuple person1 of type Person = (name: "Peter", age: 30)
Tuple person2 of type tuple[name: string, age: int] = (name: "Peter", age: 30)
test case: case2
Tuple person1 of type tuple[name: string, age: int] = (name: "Peter", age: 30)
Tuple person2 of type Person = (name: "Peter", age: 30)
test case: case3
Tuple person1 of type Person = (name: "Peter", age: 30)
Tuple person2 of type tuple[name: string, age: int] = (name: "Peter", age: 30)
test case: case4
Tuple person1 of type tuple[name: string, age: int] = (name: "Peter", age: 30)
Tuple person2 of type Person = (name: "Peter", age: 30)
test case: case5
Tuple person1 of type Person = (name: "Peter", age: 30)
Tuple person2 of type tuple[name: string, age: int] = (name: "Peter", age: 30)
"""
    assertEquals(output, expected)
  main()
