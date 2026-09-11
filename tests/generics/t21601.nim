discard """
  errormsg: "'typedesc' is not a concrete type"
  line: 10
"""

# issue #21601
type Person = object

type Builder* = ref object of RootObj
  class*: typedesc

echo Builder(class: Person).repr
