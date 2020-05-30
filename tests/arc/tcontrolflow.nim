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
'''
  cmd: "nim c --gc:arc -d:danger $file"
  disabled: "true"
"""
# we use the -d:danger switch to detect uninitialized stack
# slots more reliably (there shouldn't be any, of course).

# XXX Enable once scope based destruction works!

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

