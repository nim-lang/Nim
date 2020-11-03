discard """
   output: '''abcsuffix
xyzsuffix
destroy foo 2
destroy foo 1
'''
  cmd: '''nim c --gc:arc $file'''
"""

proc select(cond: bool; a, b: sink string): string =
  if cond:
    result = a # moves a into result
  else:
    result = b # moves b into result

proc test(param: string; cond: bool) =
  var x = "abc" & param
  var y = "xyz" & param

  # possible self-assignment:
  x = select(cond, x, y)

  echo x
  # 'select' must communicate what parameter has been
  # consumed. We cannot simply generate:
  # (select(...); wasMoved(x); wasMoved(y))

test("suffix", true)
test("suffix", false)



#--------------------------------------------------------------------
# issue #13659

type
  Foo = ref object
    data: int
    parent: Foo

proc `=destroy`(self: var type(Foo()[])) =
  echo "destroy foo ", self.data
  for i in self.fields: i.reset

proc getParent(self: Foo): Foo = self.parent

var foo1 = Foo(data: 1)
var foo2 = Foo(data: 2, parent: foo1)

foo2.getParent.data = 1