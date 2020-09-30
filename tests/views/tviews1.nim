discard """
  output: '''11
22
33
3
2
3
3'''
  targets: "c cpp"
"""

{.experimental: "views".}

proc take(a: openArray[int]) =
  echo a.len

proc main(s: seq[int]) =
  var x: openArray[int] = s
  for i in 0 .. high(x):
    echo x[i]
  take(x)

  take(x.toOpenArray(0, 1))
  let y = x
  take y
  take x

main(@[11, 22, 33])
