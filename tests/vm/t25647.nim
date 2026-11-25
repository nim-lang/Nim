discard """
  errormsg: "cannot produce a compile-time value of type 'ptr Table' that is not nil"
  line: 17
"""

# bug #25647: a pointer to compile-time memory cannot be part of a constant
type
  Entry = object
    value: int
    next: ptr Table

  Table = object
    entries: seq[Entry]

func gen(T: type): Table
func get(T: type): ptr Table =
  const table = gen(T)
  addr table

func gen(T: type): Table =
  when T is int:
    Table()
  else:
    Table(entries: @[Entry(value: 1, next: get(int))])

type Foo = object
  x: int

discard get(Foo)
