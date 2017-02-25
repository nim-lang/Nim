discard """
  output: '''
02
'''
"""
import re

let regexp = re"^\/([0-9]{2})\.html$"
var matches: array[1, string]
discard "/02.html".find(regexp, matches)
echo matches[0]
