discard """
  # pending bug #16521 (bug 12) use `matrix`
  cmd: "nim c --spellsuggest:4 --hints:off $file"
  action: "reject"
  nimout: '''
tspellsuggest3.nim(21, 1) Error: undeclared identifier: 'fooBar'
candidates (edit distance, scope distance); see '--spellSuggest':
 (1, 2): 'FooBar' [type declared in mspellsuggest.nim(5, 6)]
 (1, 2): 'fooBar4' [proc declared in mspellsuggest.nim(1, 6)]
 (1, 2): 'fooBar9' [var declared in mspellsuggest.nim(2, 5)]
 (1, 2): 'fooCar' [var declared in mspellsuggest.nim(4, 5)]
'''
"""

import ./mspellsuggest
import ./mspellsuggest
import ./mspellsuggest
import ./mspellsuggest


fooBar
