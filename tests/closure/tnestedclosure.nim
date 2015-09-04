discard """
  output: '''foo88
23 24foo 88
foo88
23 24foo 88
hohoho'''
"""

# test nested closure
proc main(param: int) =
  var foo = 23
  proc outer(outerParam: string) =
    var outerVar = 88
    echo outerParam, outerVar
    proc inner() =
      block Test:
        echo foo, " ", param, outerParam, " ", outerVar
    inner()
  outer("foo")

# test simple closure within dummy 'main':
proc dummy =
  proc main2(param: int) =
    var foo = 23
    proc outer(outerParam: string) =
      var outerVar = 88
      echo outerParam, outerVar
      proc inner() =
        block Test:
          echo foo, " ", param, outerParam, " ", outerVar
      inner()
    outer("foo")
  main2(24)

dummy()

main(24)

# Jester + async triggered this bug:
proc cbOuter() =
  var response = "hohoho"
  block:
    proc cbIter() =
      block:
        proc fooIter() =
          echo response
        fooIter()

    cbIter()

cbOuter()
