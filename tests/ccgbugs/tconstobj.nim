discard """
  file: "tconstobj.nim"
  output: '''(FirstName: James, LastName: Franco)'''
"""

# bug #1547
import tables

type Person* = object
    FirstName*: string
    LastName*: string

let people = {
    "001": Person(FirstName: "James", LastName: "Franco")
}.toTable()

echo people["001"]
