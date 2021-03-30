discard """
  # pending bug #16521 (bug 12) use `matrix`
  cmd: "nim c --spellsuggest:15 --hints:off $file"
  action: "reject"
  nimout: '''
tspellsuggest.nim(45, 13) Error: undeclared identifier: 'fooBar'
candidates (edit distance, scope distance); see '--spellSuggest':
 (1, 0): 'fooBar8' [var declared in tspellsuggest.nim(43, 9)]
 (1, 1): 'fooBar7' [var declared in tspellsuggest.nim(41, 7)]
 (1, 3): 'fooBar1' [var declared in tspellsuggest.nim(33, 5)]
 (1, 3): 'fooBar2' [let declared in tspellsuggest.nim(34, 5)]
 (1, 3): 'fooBar3' [const declared in tspellsuggest.nim(35, 7)]
 (1, 3): 'fooBar4' [proc declared in tspellsuggest.nim(36, 6)]
 (1, 3): 'fooBar5' [template declared in tspellsuggest.nim(37, 10)]
 (1, 3): 'fooBar6' [macro declared in tspellsuggest.nim(38, 7)]
 (1, 5): 'FooBar' [type declared in mspellsuggest.nim(5, 6)]
 (1, 5): 'fooBar4' [proc declared in mspellsuggest.nim(1, 6)]
 (1, 5): 'fooBar9' [var declared in mspellsuggest.nim(2, 5)]
 (1, 5): 'fooCar' [var declared in mspellsuggest.nim(4, 5)]
 (2, 5): 'FooCar' [type declared in mspellsuggest.nim(6, 6)]
 (2, 5): 'GooBa' [type declared in mspellsuggest.nim(7, 6)]
 (3, 0): 'fooBarBaz' [const declared in tspellsuggest.nim(44, 11)]
'''
"""

# tests `--spellsuggest:num`



# line 30
import ./mspellsuggest

var fooBar1 = 0
let fooBar2 = 0
const fooBar3 = 0
proc fooBar4() = discard
template fooBar5() = discard
macro fooBar6() = discard

proc main =
  var fooBar7 = 0
  block:
    var fooBar8 = 0
    const fooBarBaz = 0
    let x = fooBar
