discard """
  joinable: false
  output:'''
onInject: 1
onInject: 2
ok0
ok1
onInject: 3
onInject: 4
0
onInject: 5
onInject: 6
1
onInject: 7
onInject: 8
2
ok2
onInject: 9
'''
"""

# test {.injectStmt.}

#[
{.injectStmt.} pragma can be used to inject a statement before every
other statement in the current module. It's now undocumented and may be removed
in the future and replaced with something more general and without its limitations.
e.g. (e.g. doesn't work in VM or js backends).
]#

from system/ansi_c import c_printf

var count = 0
proc onInject*() =
  count.inc
  # echo count # xxx would fail, probably infinite recursion
  c_printf("onInject: %d\n", cast[int](count))

{.injectStmt: onInject().}
echo "ok0"
proc main()=
  echo "ok1"
  for a in 0..<3:
    echo a
  echo "ok2"

static: main() # xxx injectStmt not honred in VM
main()
