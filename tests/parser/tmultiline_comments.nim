discard """
  output: '''3'''
"""

proc main* =
  ##[Mutltie akdlsf comment with #[nesting].
  Yay, that is so cool.
  ]##
  echo "foo bar"
  for s in ["one", "two", #["three",]# "four"]:
    echo s

var foo #[ Test the new inline comments ]#: int = 3
##[ A
novel documentation comment
#[Nesting works to some extend]
##[ Nested doc comment! ]##
]#
]##
echo $foo

  #[Comment here.
  Multiple lines
  are not a problem.]#

  #[  #[ Multiline comment in already
     commented out code. ]#
  proc p[T](x: T) = discard
  ]#

proc bar =
  ##[Long documentation comment
  here.
  ]##
