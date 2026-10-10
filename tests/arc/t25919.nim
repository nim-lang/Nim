discard """
  output: '''0'''
  matrix: "--mm:arc; --mm:orc"
"""

# bug #25919: a raising proc's partially built string/seq result leaked

proc foo(): string =
  result = ""
  for _ in 0 .. 1000:
    result.add 'x'
  if true:
    raise (ref ValueError)(msg: "err")

proc fooSeq(): seq[int] =
  for i in 0 .. 1000:
    result.add i
  if true:
    raise (ref ValueError)(msg: "err")

proc main() =
  try: discard foo()
  except ValueError: discard
  try:
    let x = foo()
    echo x.len
  except ValueError: discard
  var y = "a"
  try: y = foo()
  except ValueError: discard
  doAssert y == "a"
  try: echo foo().len
  except ValueError: discard
  try: discard fooSeq()
  except ValueError: discard
  var s = @[1]
  try: s = fooSeq()
  except ValueError: discard
  doAssert s == @[1]

main()
let m0 = getOccupiedMem()
for i in 0 .. 100: main()
echo getOccupiedMem() - m0
