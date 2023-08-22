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


proc write(a: auto, x: varargs[string, `$`]) =
  stdout.write ($a)
  for o in x:
    stdout.write(o)

proc writeln(a: auto, x: varargs[string, `$`]) =
  write a, x
  stdout.write "\n"

proc write() = write(stdout)
proc writeln() =
  stdout.write "\n"

#[  #[ Multiline comment in already
   commented out code. ]#
proc p[T](x: T) = discard
]#

var hello = #[(x in bar)^^ "Hello" # greetings
]#"Hello"
proc maino =
  write hello, " Test Me "
  writeln()
  write 3
  block:
    write()
    write " times more"
  #[ test ]#  writeln " Again"
