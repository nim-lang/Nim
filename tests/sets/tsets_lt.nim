discard """
  output: '''true
true
true'''
"""

var s, s1: set[char]
s = {'a'..'d'}
s1 = {'a'..'c'}
echo s1 < s
echo s1 * s == {'a'..'c'}
echo s1 <= s
