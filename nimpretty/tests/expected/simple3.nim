
#[
foo bar
]#



proc fun() =
  echo "ok1"

proc fun2(a = "fooo" & "bar" & "bar" & "bar" & "bar" & ("bar" & "bar" & "bar") &
    "bar" & "bar" & "bar" & "bar" & "bar" & "bar" & "bar" & "bar" & "bar"): auto =
  discard

fun2()
