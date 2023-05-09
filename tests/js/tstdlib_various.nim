discard """
output: '''
abc
def
definition
prefix
xyz
def
definition
Hi Andreas! How do you feel, Rumpf?

@[0, 2, 1]
@[1, 0, 2]
@[1, 2, 0]
@[2, 0, 1]
@[2, 1, 0]
@[2, 0, 1]
@[1, 2, 0]
@[1, 0, 2]
@[0, 2, 1]
@[0, 1, 2]
[5]
[4, 5]
[3, 4, 5]
[2, 3, 4, 5]
[2, 3, 4, 5, 6]
[1, 2, 3, 4, 5, 6]
'''
"""

import
  critbits, sets, strutils, tables, random, algorithm, ropes,
  lists, htmlgen, xmltree, strtabs


block tcritbits:
  var r: CritBitTree[void]
  r.incl "abc"
  r.incl "xyz"
  r.incl "def"
  r.incl "definition"
  r.incl "prefix"
  doAssert r.contains"def"
  #r.del "def"

  for w in r.items:
    echo w
  for w in r.itemsWithPrefix("de"):
    echo w



block testequivalence:
  doAssert(toHashSet(@[1,2,3]) <= toHashSet(@[1,2,3,4]), "equivalent or subset")
  doAssert(toHashSet(@[1,2,3]) <= toHashSet(@[1,2,3]), "equivalent or subset")
  doAssert((not(toHashSet(@[1,2,3]) <= toHashSet(@[1,2]))), "equivalent or subset")
  doAssert(toHashSet(@[1,2,3]) <= toHashSet(@[1,2,3,4]), "strict subset")
  doAssert((not(toHashSet(@[1,2,3]) < toHashSet(@[1,2,3]))), "strict subset")
  doAssert((not(toHashSet(@[1,2,3]) < toHashSet(@[1,2]))), "strict subset")
  doAssert((not(toHashSet(@[1,2,3]) == toHashSet(@[1,2,3,4]))), "==")
  doAssert(toHashSet(@[1,2,3]) == toHashSet(@[1,2,3]), "==")
  doAssert((not(toHashSet(@[1,2,3]) == toHashSet(@[1,2]))), "==")



block tformat:
  echo("Hi $1! How do you feel, $2?\n" % ["Andreas", "Rumpf"])



block tnilecho:
  var x = @["1", "", "3"]
  doAssert $x == """@["1", "", "3"]"""



block torderedtable:
  var t = initOrderedTable[int,string]()

  # this tests issue #5917
  var data = newSeq[int]()
  for i in 0..<1000:
    var x = rand(1000)
    if x notin t: data.add(x)
    t[x] = "meh"

  # this checks that keys are re-inserted
  # in order when table is enlarged.
  var i = 0
  for k, v in t:
    doAssert(k == data[i])
    doAssert(v == "meh")
    inc(i)



block tpermutations:
  var v = @[0, 1, 2]
  while v.nextPermutation():
    echo v
  while v.prevPermutation():
    echo v


block tropes:
  var
    r1 = rope("")
    r2 = rope("123")
  doAssert r1.len == 0
  doAssert r2.len == 3
  doAssert $r1 == ""
  doAssert $r2 == "123"

  r1.add("123")
  r2.add("456")
  doAssert r1.len == 3
  doAssert r2.len == 6
  doAssert $r1 == "123"
  doAssert $r2 == "123456"
  doAssert $r1[1] == "2"
  doAssert $r2[2] == "3"


block tsinglylinkedring:
  var r = initSinglyLinkedRing[int]()
  r.prepend(5)
  echo r
  r.prepend(4)
  echo r
  r.prepend(3)
  echo r
  r.prepend(2)
  echo r
  r.append(6)
  echo r
  r.prepend(1)
  echo r

block tsplit:
  var s = ""
  for w in split("|abc|xy|z", {'|'}):
    s.add("#")
    s.add(w)

  doAssert s == "##abc#xy#z"

block tsplit2:
  var s = ""
  for w in split("|abc|xy|z", {'|'}):
    s.add("#")
    s.add(w)

  var errored = false
  try:
    discard "hello".split("")
  except AssertionDefect:
    errored = true
  doAssert errored

block txmlgen:
  var nim = "Nim"
  doAssert h1(a(href="http://force7.de/nim", nim)) ==
    "<h1><a href=\"http://force7.de/nim\">Nim</a></h1>"

block txmltree:
  var x = <>a(href="nim.de", newText("www.nim-test.de"))

  doAssert($x == "<a href=\"nim.de\">www.nim-test.de</a>")
  doAssert(newText("foo").innerText == "foo")
  doAssert(newEntity("bar").innerText == "bar")
  doAssert(newComment("baz").innerText == "")

  let y = newXmlTree("x", [
    newText("foo"),
    newXmlTree("y", [
      newText("bar")
    ])
  ])
  doAssert(y.innerText == "foobar")
