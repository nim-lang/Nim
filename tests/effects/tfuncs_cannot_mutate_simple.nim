discard """
  errormsg: '''cannot mutate location x.data within a strict func'''
  line: 15
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
