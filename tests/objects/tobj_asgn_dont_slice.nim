discard """
  outputsub: '''ObjectAssignmentDefect'''
  exitcode: "1"
"""

# bug #7637
type
  Fruit = object of RootObj
    name*: string
  Apple = object of Fruit
  Pear = object of Fruit

method eat(f: Fruit) {.base.} =
  raise newException(Exception, "PURE VIRTUAL CALL")

method eat(f: Apple) =
  echo "fruity"

method eat(f: Pear) =
  echo "juicy"

let basket = [Apple(name:"a"), Pear(name:"b")]

eat(basket[0])
