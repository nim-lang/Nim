import strutils

# Verifies if the --suggestion switch differentiates types for dot notation.

type
  TDollar = distinct int
  TEuro = distinct int

proc echoRemainingDollars(amount: TDollar) =
  echo "You have $1 dollars" % [$int(amount)]

proc echoRemainingEuros(amount: TEuro) =
  echo "You have $1 euros" % [$int(amount)]

proc echoRemainingBugs() =
  echo "You still have bugs"

proc main =
  var
    d: TDollar
    e: TEuro
  d = TDollar(23)
  e = TEuro(32)
  d.echoRemainingDollars()
