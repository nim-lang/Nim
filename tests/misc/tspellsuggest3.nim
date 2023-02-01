discard """
  # pending bug #16521 (bug 12) use `matrix`
  cmd: "nim c --spellsuggest:4 --hints:off $file"
  action: "reject"
  nimout: '''
tspellsuggest3.nim(21, 1) Error: undeclared identifier: 'fooBar'
candidates (edit distance, scope distance); see '--spellSuggest':
 (1, 2): 'FooBar'
 (1, 2): 'fooBar4'
 (1, 2): 'fooBar9'
 (1, 2): 'fooCar'
'''
"""

import ./mspellsuggest
import ./mspellsuggest
import ./mspellsuggest
import ./mspellsuggest


fooBar
