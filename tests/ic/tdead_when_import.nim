discard """
  description: '''IC: an import under an undecidable `when` must not be compiled'''
"""

#? metamorphic

# `when SomeStrdefineConst == "x": import y` is `cvUnknown` to the dependency
# scanner, which conservatively keeps the edge — right for an edge, but it also
# gave `y` its own `nim m` rule. `nim c` never looks at that file, so a build
# died on a package the user never installed because they never selected that
# backend. Selecting it must still produce the honest error.

#!FILE needsmissing.nim
import pkg/definitely_not_an_installed_package
proc unreachable*(): string = "never"

#!FILE guarded.nim
const Backend* {.strdefine.} = "plain"

when Backend == "fancy":
  import ./needsmissing

proc pick*(): string =
  when Backend == "fancy": unreachable()
  else: "plain"

#!FILE main.nim
import guarded
echo pick()
#!STEP expect: plain

# selecting the branch that really does need the missing package must report it
#!FLAGS -d:Backend=fancy
#!STEP fails: cannot open file

#!FLAGS
#!STEP expect: plain
