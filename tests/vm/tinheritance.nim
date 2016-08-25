discard """
  msg: '''Hello fred , managed by sally
Hello sally , managed by bob'''
"""
# bug #3973

type
  EmployeeCode = enum
    ecCode1,
    ecCode2

  Person* = object of RootObj
    name* : string
    last_name*: string

  Employee* = object of Person
    empl_code* : EmployeeCode
    mgr_name* : string

proc test() =
  var
    empl1 = Employee(name: "fred", last_name: "smith", mgr_name: "sally", empl_code: ecCode1)
    empl2 = Employee(name: "sally", last_name: "jones", mgr_name: "bob", empl_code: ecCode2)

  echo "Hello ", empl1.name, " , managed by ", empl1.mgr_name
  echo "Hello ", empl2.name, " , managed by ", empl2.mgr_name

static:
  test()
