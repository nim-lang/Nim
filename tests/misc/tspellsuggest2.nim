discard """
  matrix: "--spellsuggest:12 --hints:off"
  action: "reject"
  nimout: '''
tspellsuggest2.nim(45, 13) Error: undeclared identifier: 'fooBar'
candidates (edit distance, scope distance); see '--spellSuggest':
 (1, 0): 'fooBar8'
 (1, 1): 'fooBar7'
 (1, 3): 'fooBar1'
 (1, 3): 'fooBar2'
 (1, 3): 'fooBar3'
 (1, 3): 'fooBar4'
 (1, 3): 'fooBar5'
 (1, 3): 'fooBar6'
 (1, 5): 'FooBar'
 (1, 5): 'fooBar4'
 (1, 5): 'fooBar9'
 (1, 5): 'fooCar'
'''
"""

# tests `--spellsuggest`







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
