discard """
  output: '''begin A
elif
destroyed
end A
begin false
if
destroyed
end false
begin true
if
end true
7
##index 2 not in 0 .. 1##
true
'''
  cmd: "nim c --gc:arc -d:danger $file"
"""
# we use the -d:danger switch to detect uninitialized stack
# slots more reliably (there shouldn't be any, of course).

type
  Foo = object
    id: int

proc `=destroy`(x: var Foo) =
  if x.id != 0:
    echo "destroyed"
    x.id = 0

proc construct(): Foo = Foo(id: 3)

proc elifIsEasy(cond: bool) =
  echo "begin A"
  if cond:
    echo "if"
  elif construct().id == 3:
    echo "elif"
  else:
    echo "else"
  echo "end A"

elifIsEasy(false)


proc orIsHard(cond: bool) =
  echo "begin ", cond
  if cond or construct().id == 3:
    echo "if"
  else:
    echo "else"
  echo "end ", cond

orIsHard(false)
orIsHard(true)

type
  Control = ref object
    x: int

  MouseEvent = ref object
    control: Control
    button: int

proc run(data: Control) =
  var evt = MouseEvent(button: 1)
  evt.control = data
  if evt.button == 1:
    discard
  else:
    return

  echo data.x

var c = Control(x: 7)

run(c)

proc sysFatal(exceptn: typedesc, message: string) {.inline, noreturn.} =
  var buf = newStringOfCap(200)
  add(buf, "##")
  add(buf, message)
  add(buf, "##")
  echo buf

proc ifexpr(i, a, b: int) {.compilerproc, noinline.} =
  sysFatal(IndexDefect,
    if b < a: "index out of bounds, the container is empty"
    else: "index " & $i & " not in " & $a & " .. " & $b)

ifexpr(2, 0, 1)

# bug #14899
template toSeq(): untyped =
  block:
    var result = @[1]
    result

proc clItems(s: seq[int]) =
  assert s.len == 1

proc escapeCheck =
  clItems(toSeq())

escapeCheck()

# bug #14900
template sortedByIt(seq1): untyped =
  var result = seq1
  result

proc seqsEqual(seq1, seq2: seq[string]): bool =
  # works as a normal proc (if we would assign result inside)
  # doesn't work as an expression
  result =  if false: # needed
              false
            else:
              let a1 = seq1.sortedByIt()
              let a2 = seq2.sortedByIt()
              # echo a1 - works if you uncomment any of these
              # echo a2
              a1 == a2

echo seqsEqual(@["a", "b", "c"], @["a", "b", "c"])
