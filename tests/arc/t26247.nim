discard """
  matrix: "--mm:arc; --mm:orc"
  output: '''
false
true
'''
"""

# bug #26247: the closure env was moved into the first closure while still live
type
  State = ref object
    selected: bool
  W = ref object
    a: proc()

proc build(s: State): W =
  result = W()
  if s.selected:
    result.a = proc() = discard s.selected
  else:
    result.a = proc() = discard s.selected
    echo s.selected

proc build2(s: State): W =
  result = W()
  if not s.selected:
    result.a = proc() = discard s.selected
  else:
    result.a = proc() = echo s.selected
  result.a()
  discard s.selected

discard build(State(selected: false))
discard build(State(selected: true))
discard build2(State(selected: true))
