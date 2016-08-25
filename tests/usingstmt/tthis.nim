
# bug #4177

type
  Parent = object of RootObj
    parentField: int
  Child = object of Parent
    childField: int

{.this: self.}
proc sumFields(self: Child): int =
  result = parentField + childField # Error: undeclared identifier: 'parentField'

proc sumFieldsWorks(self: Child): int =
  result = self.parentField + childField
