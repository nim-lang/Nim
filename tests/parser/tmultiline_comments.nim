discard """
  output: '''3'''
"""

proc main* =
  ##[Mutltie akdlsf comment with #[nesting].
  Yay, that is so cool.
  ]##
  echo "foo bar"

var foo #[ Test the new inline comments ]#: int = 3
##[ A
novel documentation comment
#[Nesting works to some extend]
##[ Nested doc comment! ]##
]#
]##
echo $foo
