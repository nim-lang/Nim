discard """
  cmd: "nim cpp $file"
  output: ''''''
"""

# bug #5140
{.emit:"""
#import <cassert>

template <typename X> class C {
  public:
    int d;

    C(): d(1) { }

    C<X>& operator=(const C<X> other) {
      assert(d == 1);
    }
};
""".}

type C{.importcpp, header: "<stdio.h>", nodecl.} [X] = object
proc mkC[X]: C[X] {.importcpp: "C<'*0>()", constructor, nodecl.}

proc foo(): C[int] =
  result = mkC[int]()

discard foo()
