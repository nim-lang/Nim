# comment here
var x: int = 2

echo x

proc fun*() =
  echo "ok"
  ## doc comment
  # regular comment

proc funB() =
  echo "ok1"
  # echo "ok2"

fun()

#[
bug #9483
]#

proc funE() =
  echo "ok1"
