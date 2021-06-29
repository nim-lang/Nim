discard """
  output: '''a
long
list
of
words'''
  cmd: r"nim c --hints:on $options -d:release $file"
  ccodecheck: "! @'genericSeqAssign'"
  targets: "c"
"""

# bug #4354
import tables
import sets
import strutils

#const FRUITS = ["banana", "apple", "grapes"]
#let FRUITS = ["banana", "apple", "grapes"].toHashSet
const FRUITS = {"banana":0, "apple":0, "grapes":0}.toTable

proc main() =
    let L = "a long list of words".split()
    for word in L:
        if word notin FRUITS:
            echo(word)

main()
