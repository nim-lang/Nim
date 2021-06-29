discard """
  errormsg: "'edit' can have side effects"
  nimout: '''an object reachable from 'x' is potentially mutated
tfuncs_cannot_mutate_simple.nim(16, 4) the mutation is here'''
"""

{.experimental: "strictFuncs".}

# bug #15508

type
  MyType = ref object
    data: string

func edit(x: MyType) =
  x.data = "hello"

let x = MyType()
x.edit()
echo x.data
